local trustNames = {};
local curatedTrustNames = require('data.trust_names');
local zoneManifest = require('data.npc_object_zone_manifest');
local currentZoneId = nil;
local currentZoneName = nil;
local currentZoneFile = nil;
local globalZoneData = nil;

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

local function GetCurrentZoneId()
    local zoneId = nil;

    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    return tonumber(zoneId) or 0;
end

local function CleanName(name)
    return tostring(name or ''):gsub('\170', ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local function LoadTable(moduleName)
    local ok, data = pcall(require, moduleName);

    if (ok == true and type(data) == 'table') then
        return data;
    end

    return {};
end

local function LoadZoneFile(fileName)
    local moduleName = tostring(fileName or ''):gsub('%.lua$', '');

    if (moduleName == '') then
        return {};
    end

    return LoadTable('data.npc_object_zones.' .. moduleName);
end

local function GetGlobalZoneData()
    if (globalZoneData == nil) then
        globalZoneData = LoadZoneFile(zoneManifest.global);
    end

    return globalZoneData or {};
end

local function GetCurrentZoneData()
    local zoneId = GetCurrentZoneId();
    local zoneName = GetCurrentZoneName();
    local zoneIdFile = nil;
    local zoneNameFile = nil;

    if (type(zoneManifest.zoneIds) == 'table') then
        zoneIdFile = zoneManifest.zoneIds[zoneId] or zoneManifest.zoneIds[tostring(zoneId)];
    end

    if (type(zoneManifest.zoneNames) == 'table' and zoneName ~= nil) then
        zoneNameFile = zoneManifest.zoneNames[zoneName:lower()];
    end

    local zoneFile = zoneNameFile or zoneIdFile or '';

    if (zoneFile == '') then
        currentZoneFile = nil;
        return {};
    end

    if (currentZoneFile == zoneFile) then
        return LoadZoneFile(zoneFile);
    end

    currentZoneFile = zoneFile;
    return LoadZoneFile(zoneFile);
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

for key, entry in pairs((GetGlobalZoneData().npcs or {})) do
    local trustName = tostring(key or ''):match('^Trust:%s*(.+)$');

    if trustName ~= nil and trustName ~= '' then
        knownTrustNames[CleanName(trustName)] = true;

        if type(entry) == 'table' and type(entry.aliases) == 'table' then
            for _, alias in pairs(entry.aliases) do
                local cleanAlias = CleanName(alias);

                if cleanAlias ~= '' then
                    knownTrustNames[cleanAlias] = true;
                end
            end
        end
    end
end

local function HasCurrentZoneNpcEntry(name)
    local cleanName = CleanName(name);
    local zoneEntry = ((GetCurrentZoneData().npcs or {})[cleanName]);

    return type(zoneEntry) == 'table';
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
    if (HasCurrentZoneNpcEntry(cleanName) == true) then
        return false;
    end

    return true;
end

return trustNames;
