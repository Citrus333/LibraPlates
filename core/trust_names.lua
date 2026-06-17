local trustNames = {};
local curatedTrustNames = require('data.trust_names');
local npcIcons = require('data.npc_icons');
local catseyeNpcIcons = require('data.catseye_npc_icons');
local currentZoneId = nil;
local currentZoneName = nil;

local function NormalizeZoneName(zoneName)
    local text = tostring(zoneName or '');

    text = text:gsub('[\226\128\153`]', "'");
    text = text:gsub('%s+', ' ');
    text = text:gsub('^%s+', ''):gsub('%s+$', '');

    return text;
end

local function GetCurrentZoneName()
    local zoneId = nil;

    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    zoneId = tonumber(zoneId) or 0;

    if (zoneId == 0) then
        return nil;
    end

    if (zoneId == currentZoneId) then
        return currentZoneName;
    end

    local zoneName = nil;

    pcall(function()
        zoneName = AshitaCore:GetResourceManager():GetString('zones.names', zoneId);
    end);

    currentZoneId = zoneId;
    currentZoneName = NormalizeZoneName(zoneName);

    return currentZoneName;
end

local function CleanName(name)
    return tostring(name or ''):gsub('\170', ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local knownTrustNames = {};

for name, value in pairs(curatedTrustNames or {}) do
    local trustName = type(name) == 'number' and value or name;

    if (trustName ~= nil and tostring(trustName) ~= '') then
        local cleanTrustName = CleanName(trustName);
        knownTrustNames[cleanTrustName] = true;

        local alias = cleanTrustName:match('^(.+)%s+%([^%)]+%)$');

        if (alias ~= nil and alias ~= '') then
            knownTrustNames[CleanName(alias)] = true;
        end
    end
end

local function GetCuratedNpcEntry(name)
    return catseyeNpcIcons[CleanName(name)] or npcIcons[CleanName(name)];
end

local function EntryHasCurrentZone(entry)
    if (type(entry) ~= 'table' or type(entry.zones) ~= 'table') then
        return false;
    end

    local zoneName = GetCurrentZoneName();

    if (zoneName == nil or zoneName == '') then
        return false;
    end

    for _, zone in pairs(entry.zones) do
        if (NormalizeZoneName(zone) == zoneName) then
            return true;
        end
    end

    return false;
end

function trustNames.IsKnownTrustName(name)
    local cleanName = CleanName(name);

    if (knownTrustNames[cleanName] ~= true) then
        return false;
    end

    local zoneName = GetCurrentZoneName();

    if (
        cleanName == 'Moogle' and
        (
            zoneName == 'Mog House' or
            tostring(zoneName or ''):find('Rent%-a%-Room') ~= nil
        )
    ) then
        return false;
    end

    -- Some trust names are also normal NPCs. When the current zone has a
    -- concrete NPC entry with the same name, keep it in the NPC data path.
    if (EntryHasCurrentZone(GetCuratedNpcEntry(cleanName)) == true) then
        return false;
    end

    return true;
end

return trustNames;
