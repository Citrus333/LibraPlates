require('common');

local ffi = require('ffi');
local pupEquipment = {};
local equipmentOffsetPointer = nil;
local equipmentOffsetResolved = false;
local EQUIPMENT_ITEM_OFFSET = 0x2000;

local function ResolveEquipmentOffset()
    if (equipmentOffsetResolved == true) then
        return equipmentOffsetPointer;
    end

    equipmentOffsetResolved = true;
    local ok, address = pcall(function()
        return ashita.memory.find(
            'FFXiMain.dll',
            0,
            'C1E1032BC8B0018D????????????B9????????F3A55F5E5B',
            10,
            0
        );
    end);

    if (ok ~= true or tonumber(address) == nil or tonumber(address) == 0) then
        return nil;
    end

    equipmentOffsetPointer = ffi.cast('uint32_t*', address);
    return equipmentOffsetPointer;
end

local function GetItemName(rawId, fallbackLabel)
    local id = tonumber(rawId) or 0;
    local item = nil;

    pcall(function()
        item = AshitaCore:GetResourceManager():GetItemById(id + EQUIPMENT_ITEM_OFFSET);
    end);

    if (
        item ~= nil and
        item.Name ~= nil and
        tostring(item.Name[1] or '') ~= '' and
        tostring(item.Name[1] or '') ~= '.'
    ) then
        return tostring(item.Name[1]);
    end

    return tostring(fallbackLabel or 'Unknown') .. ' (' .. tostring(id) .. ')';
end

function pupEquipment.Read()
    local offsetPointer = ResolveEquipmentOffset();
    if (offsetPointer == nil) then
        return {
            head = 'Head unavailable',
            frame = 'Frame unavailable',
            available = false,
        };
    end

    local ok, headId, frameId = pcall(function()
        local inventoryPointer = ashita.memory.read_uint32(
            AshitaCore:GetPointerManager():Get('inventory')
        );
        if (inventoryPointer == nil or inventoryPointer == 0) then
            return nil, nil;
        end

        inventoryPointer = ashita.memory.read_uint32(inventoryPointer);
        if (inventoryPointer == nil or inventoryPointer == 0) then
            return nil, nil;
        end

        local equipment = ashita.memory.read_array(
            inventoryPointer + offsetPointer[0] + 0x04,
            2
        );
        return equipment ~= nil and equipment[1] or nil,
            equipment ~= nil and equipment[2] or nil;
    end);

    if (ok ~= true or headId == nil or frameId == nil) then
        return {
            head = 'Head unavailable',
            frame = 'Frame unavailable',
            available = false,
        };
    end

    return {
        head = GetItemName(headId, 'Head'),
        frame = GetItemName(frameId, 'Frame'),
        headId = tonumber(headId),
        frameId = tonumber(frameId),
        available = true,
    };
end

return pupEquipment;
