local textureLoader = require('core.texture_loader');

local indicators = {};
local textureCache = {};

local function Band(left, right)
    if (bit ~= nil and bit.band ~= nil) then
        return bit.band(left, right);
    end

    return 0;
end

local function ReadRenderFlag(targetIndex, flagIndex)
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();

    if (entityManager == nil or targetIndex == nil) then
        return 0;
    end

    local methodName = 'GetRenderFlags' .. tostring(flagIndex);

    if (entityManager[methodName] == nil) then
        return 0;
    end

    local ok, value = pcall(function()
        return entityManager[methodName](entityManager, targetIndex);
    end);

    if (ok ~= true) then
        return 0;
    end

    return tonumber(value) or 0;
end

local function LoadIcon(name)
    local key = tostring(name or ''):lower();

    if (key == '') then
        return nil;
    end

    if (textureCache[key] ~= nil) then
        return textureCache[key];
    end

    local path = AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\assets\\images\\widget-icons\\' .. key .. '.png';
    textureCache[key] = textureLoader.ToTextureId(textureLoader.Load(path));

    return textureCache[key];
end

local function GetParty()
    local ok, party = pcall(function()
        return AshitaCore:GetMemoryManager():GetParty();
    end);

    if (ok == true) then
        return party;
    end

    return nil;
end

local function SafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function IsTruthy(value)
    if (value == true) then
        return true;
    end

    local number = tonumber(value);

    return number ~= nil and number ~= 0;
end

local function GetPartySlotByTargetIndex(targetIndex)
    local party = GetParty();
    local index = tonumber(targetIndex) or 0;

    if (party == nil or index == 0) then
        return nil, nil;
    end

    for slot = 0, 17 do
        local active = SafeCall(0, function()
            return party:GetMemberIsActive(slot);
        end);

        if (IsTruthy(active) == true) then
            local memberIndex = SafeCall(0, function()
                return party:GetMemberTargetIndex(slot);
            end);

            if (tonumber(memberIndex) == index) then
                return party, slot;
            end
        end
    end

    return party, nil;
end

local function GetPartyMemberCount(party, partyIndex)
    local firstSlot = ((tonumber(partyIndex) or 1) - 1) * 6;
    local count = 0;

    for slot = firstSlot, firstSlot + 5 do
        local active = SafeCall(0, function()
            return party:GetMemberIsActive(slot);
        end);

        if (IsTruthy(active) == true) then
            count = count + 1;
        end
    end

    return count;
end

local function GetActiveAlliancePartyCount(party)
    local count = 0;

    for partyIndex = 1, 3 do
        if (GetPartyMemberCount(party, partyIndex) > 0) then
            count = count + 1;
        end
    end

    return count;
end

local function GetPartyLeaderServerId(party, partyIndex)
    if (party == nil) then
        return nil;
    end

    if (partyIndex == 3 and party.GetAlliancePartyLeaderServerId3 ~= nil) then
        return SafeCall(nil, function()
            return party:GetAlliancePartyLeaderServerId3();
        end);
    end

    if (partyIndex == 2 and party.GetAlliancePartyLeaderServerId2 ~= nil) then
        return SafeCall(nil, function()
            return party:GetAlliancePartyLeaderServerId2();
        end);
    end

    if (party.GetAlliancePartyLeaderServerId1 ~= nil) then
        return SafeCall(nil, function()
            return party:GetAlliancePartyLeaderServerId1();
        end);
    end

    if (party.GetAlliancePartyLeaderServerId ~= nil) then
        return SafeCall(nil, function()
            return party:GetAlliancePartyLeaderServerId((tonumber(partyIndex) or 1) - 1);
        end);
    end

    return nil;
end

local function GetPartyLeaderInfo(targetIndex)
    local party, slot = GetPartySlotByTargetIndex(targetIndex);

    if (party == nil or slot == nil) then
        return { partyLeader = false, allianceLeader = false };
    end

    local partyIndex = math.floor(slot / 6) + 1;
    local memberServerId = tonumber(SafeCall(nil, function()
        return party:GetMemberServerId(slot);
    end)) or 0;
    local leaderServerId = tonumber(GetPartyLeaderServerId(party, partyIndex)) or 0;
    local isLeader = false;

    if (leaderServerId ~= 0 and memberServerId ~= 0) then
        isLeader = leaderServerId == memberServerId;
    elseif (GetPartyMemberCount(party, partyIndex) > 1) then
        isLeader = slot == ((partyIndex - 1) * 6);
    end

    local allianceLeader = isLeader == true and partyIndex == 1 and GetActiveAlliancePartyCount(party) > 1;

    return {
        partyLeader = isLeader == true and allianceLeader ~= true,
        allianceLeader = allianceLeader == true,
    };
end

function indicators.GetBazaarIconTextureId(targetIndex)
    if (Band(ReadRenderFlag(targetIndex, 2), 0x00000200) == 0) then
        return nil;
    end

    return LoadIcon('bazaar');
end

function indicators.GetLinkshellIconTextureId(targetIndex)
    local entity = GetEntity(targetIndex);
    local linkshellColor = tonumber(entity ~= nil and entity.LinkshellColor) or 0;

    if (linkshellColor == 0) then
        return nil;
    end

    return LoadIcon('linkshell');
end

function indicators.GetAwayIconTextureId(targetIndex)
    if (Band(ReadRenderFlag(targetIndex, 1), 0x00400000) == 0) then
        return nil;
    end

    return LoadIcon('away');
end

function indicators.GetDisconnectIconTextureId(targetIndex)
    if (Band(ReadRenderFlag(targetIndex, 1), 0x10000000) == 0) then
        return nil;
    end

    return LoadIcon('dc');
end

function indicators.GetStarsIconTextureId(targetIndex)
    if (Band(ReadRenderFlag(targetIndex, 7), 0x10000080) ~= 0x10000080) then
        return nil;
    end

    return LoadIcon('stars');
end

function indicators.GetNewAdventurerIconTextureId(targetIndex)
    if (Band(ReadRenderFlag(targetIndex, 4), 0x00002000) == 0) then
        return nil;
    end

    return LoadIcon('new_adventurer');
end

function indicators.IsGameMaster(targetIndex)
    return false;
end

function indicators.GetPartyLeaderIconTextureId(targetIndex)
    if (GetPartyLeaderInfo(targetIndex).partyLeader ~= true) then
        return nil;
    end

    return LoadIcon('party_leader');
end

function indicators.GetAllianceLeaderIconTextureId(targetIndex)
    if (GetPartyLeaderInfo(targetIndex).allianceLeader ~= true) then
        return nil;
    end

    return LoadIcon('alliance_leader');
end

function indicators.GetStaticIconTextureId(name)
    return LoadIcon(name);
end

return indicators;
