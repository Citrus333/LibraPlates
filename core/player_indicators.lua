local textureLoader = require('core.texture_loader');
local state = require('core.state');

local indicators = {};
local textureCache = {};
local SafeCall = nil;
local GetParty = nil;
local GetPartySlotByTargetIndex = nil;
local anonNameColor = { 0x1A / 255, 0x4C / 255, 0x97 / 255, 1.0 };
local campaignNameColor = { 0xFF / 255, 0x9A / 255, 0x45 / 255, 1.0 };
local gameMasterNameColor = { 0xC8 / 255, 0x3A / 255, 0x3A / 255, 1.0 };

local function CopyColor(color)
    return {
        color[1],
        color[2],
        color[3],
        color[4],
    };
end

local function Band(left, right)
    if (bit ~= nil and bit.band ~= nil) then
        return bit.band(left, right);
    end

    return 0;
end

local function RShift(value, count)
    if (bit ~= nil and bit.rshift ~= nil) then
        return bit.rshift(value, count);
    end

    return math.floor((tonumber(value) or 0) / (2 ^ (tonumber(count) or 0)));
end

local function ExpandLinkshellChannel(value)
    return math.max(0, math.min(255, ((tonumber(value) or 0) * 0x0D) + 0x38));
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

local function GetServerId(targetIndex)
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();

    if (entityManager == nil or targetIndex == nil) then
        return nil;
    end

    local ok, value = pcall(function()
        return entityManager:GetServerId(targetIndex);
    end);

    if (ok == true and tonumber(value) ~= nil and tonumber(value) > 0) then
        return value;
    end

    local party, slot = GetPartySlotByTargetIndex(targetIndex);

    if (party ~= nil and slot ~= nil) then
        return SafeCall(nil, function()
            return party:GetMemberServerId(slot);
        end);
    end

    return nil;
end

local function GetSelfServerId()
    local party = GetParty();

    if (party == nil) then
        return nil;
    end

    return SafeCall(nil, function()
        return party:GetMemberServerId(0);
    end);
end

local function LoadIcon(name)
    local key = tostring(name or ''):lower();

    if (key == '') then
        return nil;
    end

    if (textureCache[key] ~= nil) then
        return textureCache[key];
    end

    local filePath = 'assets\\images\\widget-icons\\' .. key .. '.png';
    local path = AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\' .. filePath;
    textureCache[key] = textureLoader.ToTextureId(textureLoader.Load(path));

    return textureCache[key];
end

GetParty = function()
    local ok, party = pcall(function()
        return AshitaCore:GetMemoryManager():GetParty();
    end);

    if (ok == true) then
        return party;
    end

    return nil;
end

SafeCall = function(fallback, fn)
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

GetPartySlotByTargetIndex = function(targetIndex)
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

function indicators.GetLinkshellIconTint(targetIndex)
    local entity = GetEntity(targetIndex);
    local bgr = tonumber(entity ~= nil and entity.LinkshellColor) or 0;

    if (bgr == 0) then
        return nil;
    end

    local r = Band(bgr, 0xFF);
    local g = Band(RShift(bgr, 8), 0xFF);
    local b = Band(RShift(bgr, 16), 0xFF);

    if (math.max(r, g, b) <= 0x0F) then
        r = ExpandLinkshellChannel(r);
        g = ExpandLinkshellChannel(g);
        b = ExpandLinkshellChannel(b);
    end

    return {
        r / 255,
        g / 255,
        b / 255,
        0.80,
    };
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

function indicators.HasAnonNameColor(targetIndex)
    local serverId = tonumber(GetServerId(targetIndex)) or 0;

    if (serverId == 0) then
        return false;
    end

    local anonymousByServerId = state.GetAnonymousByServerId();
    local selfServerId = tonumber(GetSelfServerId()) or 0;

    if (serverId == selfServerId) then
        return Band(ReadRenderFlag(targetIndex, 1), 0x00800000) ~= 0;
    end

    if (
        serverId ~= selfServerId and
        (anonymousByServerId[tostring(serverId)] == true or anonymousByServerId[serverId] == true)
    ) then
        return true;
    end

    local entity = GetEntity(targetIndex);

    if (tonumber(entity ~= nil and entity.Type or nil) ~= 0) then
        return false;
    end

    return Band(ReadRenderFlag(targetIndex, 0), 0x80000000) ~= 0
        and Band(ReadRenderFlag(targetIndex, 1), 0x00800000) ~= 0
        and Band(ReadRenderFlag(targetIndex, 1), 0x00000800) ~= 0;
end

function indicators.GetAnonNameColor()
    return CopyColor(anonNameColor);
end

function indicators.GetCampaignNameColor()
    return CopyColor(campaignNameColor);
end

function indicators.GetGameMasterNameColor()
    return CopyColor(gameMasterNameColor);
end

function indicators.GetCampaignNameColorHex()
    return 'FF9A45';
end

function indicators.GetAnonIconTextureId(targetIndex)
    if (indicators.HasAnonNameColor(targetIndex) ~= true) then
        return nil;
    end

    return LoadIcon('anon');
end

function indicators.IsGameMaster(targetIndex)
    local r2 = ReadRenderFlag(targetIndex, 2);

    return Band(r2, 0x00003000) == 0x00003000;
end

function indicators.GetGameMasterDebugText(targetIndex)
    local r0 = ReadRenderFlag(targetIndex, 0);
    local r1 = ReadRenderFlag(targetIndex, 1);
    local r2 = ReadRenderFlag(targetIndex, 2);
    local actorMarker = 0;
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();

    if (entityManager ~= nil and entityManager.GetActorPointer ~= nil and targetIndex ~= nil) then
        local ok, actorPointer = pcall(function()
            return entityManager:GetActorPointer(targetIndex);
        end);

        if (ok == true and actorPointer ~= nil and tonumber(actorPointer) ~= nil and tonumber(actorPointer) ~= 0) then
            ok, actorMarker = pcall(function()
                return ashita.memory.read_uint32(actorPointer + 0x20);
            end);

            if (ok ~= true) then
                actorMarker = 0;
            end
        end
    end

    return 'gmIcon=' .. tostring(indicators.IsGameMaster(targetIndex) == true) ..
        ' r0=0x' .. string.format('%X', tonumber(r0) or 0) ..
        ' r1=0x' .. string.format('%X', tonumber(r1) or 0) ..
        ' r2=0x' .. string.format('%X', tonumber(r2) or 0) ..
        ' actor20=0x' .. string.format('%X', tonumber(actorMarker) or 0);
end

function indicators.GetGameMasterIconTextureId(targetIndex)
    if (indicators.IsGameMaster(targetIndex) ~= true) then
        return nil;
    end

    return LoadIcon('gm');
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
