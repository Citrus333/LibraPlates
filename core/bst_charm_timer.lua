require('common');

local bit = require('bit');

local bstCharmTimer = {};

local packetId = {
    outAction = 0x01A,
    outCheck = 0x0DD,
    inCheck = 0x029,
    inAction = 0x028,
};

local charmActionId = 0x34;
local familiarActionInfo = 0x618;

local charmState = {
    none = 0,
    sendingCheck = 1,
    waitingCheck = 2,
};

local charmGear = {
    [17936] = 1,
    [17950] = 2,
    [12517] = 4,
    [15157] = 5,
    [15158] = 6,
    [16104] = 5,
    [16105] = 6,
    [15080] = 5,
    [15233] = 4,
    [15253] = 5,
    [12646] = 5,
    [14418] = 5,
    [14419] = 6,
    [14566] = 5,
    [14567] = 6,
    [15095] = 6,
    [14481] = 6,
    [14508] = 7,
    [13969] = 3,
    [14850] = 5,
    [14851] = 6,
    [14981] = 5,
    [14982] = 6,
    [14898] = 3,
    [15110] = 4,
    [14917] = 4,
    [14222] = 6,
    [14319] = 5,
    [14320] = 6,
    [15645] = 5,
    [15646] = 6,
    [15125] = 2,
    [15569] = 6,
    [15588] = 2,
    [14097] = 2,
    [15307] = 5,
    [15308] = 6,
    [15731] = 5,
    [15732] = 6,
    [15360] = 2,
    [15140] = 3,
    [15673] = 3,
    [14658] = 4,
    [13667] = 5,
};

local levelModifiers = {
    [-6] = 0.04,
    [-5] = 0.08,
    [-4] = 0.12,
    [-3] = 0.16,
    [-2] = 0.33,
    [-1] = 0.66,
    [0] = 1.00,
    [1] = 1.40,
    [2] = 1.80,
    [3] = 2.20,
    [4] = 2.60,
    [5] = 3.00,
    [6] = 3.40,
    [7] = 4.00,
    [8] = 5.00,
    [9] = 6.00,
};

local state = {
    packetState = charmState.none,
    targetId = nil,
    targetIndex = nil,
    petIndex = nil,
    petServerId = nil,
    petName = nil,
    petType = nil,
    startTime = nil,
    expireTime = nil,
    recoverRequestedAt = nil,
    recoverPetServerId = nil,
};

local function GetPacketData(e)
    return (e ~= nil and (e.data_modified or e.data)) or nil;
end

local function Read(data, format, offset)
    local ok, value = pcall(function()
        return struct.unpack(format, data, offset + 1);
    end);

    if (ok ~= true) then
        return nil;
    end

    return tonumber(value);
end

local function ClearPet()
    state.petIndex = nil;
    state.petServerId = nil;
    state.petName = nil;
    state.petType = nil;
    state.startTime = nil;
    state.expireTime = nil;
end

local function GetCharmEquipValue()
    local inventory = AshitaCore:GetMemoryManager():GetInventory();
    local charmValue = 0;

    if (inventory == nil) then
        return 0;
    end

    for i = 0, 15 do
        local equippedItem = nil;
        pcall(function()
            equippedItem = inventory:GetEquippedItem(i);
        end);

        if (equippedItem ~= nil and equippedItem.Index ~= nil) then
            local index = bit.band(equippedItem.Index, 0x00FF);

            if (index > 0) then
                local container = bit.rshift(bit.band(equippedItem.Index, 0xFF00), 8);
                local item = nil;
                pcall(function()
                    item = inventory:GetContainerItem(container, index);
                end);

                if (item ~= nil and charmGear[item.Id] ~= nil) then
                    charmValue = charmValue + charmGear[item.Id];
                end
            end
        end
    end

    return charmValue;
end

local function CalculateCharmExpireTime(mobLevel)
    local player = AshitaCore:GetMemoryManager():GetPlayer();

    if (player == nil or mobLevel == nil) then
        return nil;
    end

    local playerLevel = nil;
    local charisma = nil;

    pcall(function()
        playerLevel = player:GetMainJobLevel();
    end);

    pcall(function()
        charisma = player:GetStat(6);
    end);

    playerLevel = tonumber(playerLevel);
    charisma = tonumber(charisma);

    if (playerLevel == nil or charisma == nil) then
        return nil;
    end

    local levelDifference = math.max(-6, math.min(9, playerLevel - mobLevel));
    local modifier = levelModifiers[levelDifference] or 0;
    local baseDuration = math.floor((1.25 * charisma) + 150);
    local duration = (baseDuration * modifier) * (1 + (0.05 * GetCharmEquipValue()));

    return os.time() + duration;
end

local function QueueHiddenCheck(targetId, targetIndex)
    if (targetId == nil or targetIndex == nil) then
        return false;
    end

    state.packetState = charmState.sendingCheck;
    state.targetId = targetId;
    state.targetIndex = targetIndex;
    AshitaCore:GetChatManager():QueueCommand(1, '/check');
    return true;
end

function bstCharmTimer.SyncPet(pet, isCharmedPet)
    if (pet == nil) then
        if (state.packetState == charmState.none) then
            ClearPet();
        end
        return;
    end

    if (isCharmedPet ~= true) then
        ClearPet();
        return;
    end

    if (
        state.petIndex ~= pet.index or
        state.petServerId ~= pet.serverId or
        state.petName ~= pet.name
    ) then
        state.petIndex = pet.index;
        state.petServerId = pet.serverId;
        state.petName = pet.name;
        state.petType = 'charm';
        state.startTime = state.startTime or os.time();
    end

    if (state.expireTime == nil and state.packetState == charmState.none) then
        local now = os.time();

        if (
            state.recoverPetServerId ~= pet.serverId or
            state.recoverRequestedAt == nil or
            (now - state.recoverRequestedAt) >= 15
        ) then
            local targetId = tonumber(pet.serverId) ~= nil and bit.band(tonumber(pet.serverId), 0xFFFF) or nil;

            if (QueueHiddenCheck(targetId, tonumber(pet.index)) == true) then
                state.recoverRequestedAt = now;
                state.recoverPetServerId = pet.serverId;
            end
        end
    end
end

function bstCharmTimer.HandlePacketOut(e)
    if (e == nil or e.data == nil) then
        return;
    end

    if (e.id == packetId.outCheck and state.packetState == charmState.sendingCheck) then
        local sourceData = GetPacketData(e);
        local packetData = nil;
        local ok = pcall(function()
            packetData = sourceData:totable();
        end);

        if (ok ~= true or packetData == nil or state.targetId == nil or state.targetIndex == nil) then
            state.packetState = charmState.none;
            return;
        end

        e.data_modified = struct.pack('BBBBHBBHBBBBBB',
            packetData[1], packetData[2], packetData[3], packetData[4],
            state.targetId, packetData[7], packetData[8], state.targetIndex,
            packetData[11], packetData[12], packetData[13], packetData[14],
            packetData[15], packetData[16]);
        state.packetState = charmState.waitingCheck;
        return;
    end

    if (e.id ~= packetId.outAction) then
        return;
    end

    local data = GetPacketData(e);
    local category = Read(data, 'H', 0x0A);
    local actionId = Read(data, 'H', 0x0C);

    if (category ~= 0x09 or actionId ~= charmActionId) then
        return;
    end

    QueueHiddenCheck(Read(data, 'H', 0x04), Read(data, 'H', 0x08));
end

function bstCharmTimer.HandlePacketIn(e)
    if (e == nil or e.data == nil) then
        return;
    end

    if (e.id == packetId.inAction) then
        local playerEntity = GetPlayerEntity();

        if (playerEntity ~= nil and state.petType == 'charm') then
            local actorId = Read(e.data_modified or e.data, 'I', 0x05);
            local rawActionInfo = Read(e.data_modified or e.data, 'H', 0x0A);

            if (actorId == playerEntity.ServerId and rawActionInfo == familiarActionInfo and state.expireTime ~= nil) then
                state.expireTime = state.expireTime + 1500;
            end
        end

        return;
    end

    if (e.id ~= packetId.inCheck or state.packetState ~= charmState.waitingCheck) then
        return;
    end

    e.blocked = true;
    local data = GetPacketData(e);
    local param1 = Read(data, 'l', 0x0C);
    local param2 = Read(data, 'L', 0x10);
    local message = Read(data, 'H', 0x18);

    if (
        param1 ~= nil and
        (
            (message ~= nil and message >= 0xAA and message <= 0xB2) or
            (param2 ~= nil and param2 >= 0x40 and param2 <= 0x47)
        )
    ) then
        local expireTime = CalculateCharmExpireTime(param1);

        if (expireTime ~= nil) then
            state.startTime = os.time();
            state.expireTime = expireTime;
            state.petType = 'charm';
        end
    end

    state.packetState = charmState.none;
end

function bstCharmTimer.GetRemainingSeconds()
    if (state.petType ~= 'charm' or state.expireTime == nil) then
        return nil;
    end

    return math.max(0, state.expireTime - os.time());
end

return bstCharmTimer;
