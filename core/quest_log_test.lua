require('common');

local bit = require('bit');
local log = require('core.log');

local questLogTest = {};

local QUEST_PACKET_ID = 0x056;
local QUEST_FLAGS_OFFSET = 0x04;
local QUEST_TYPE_OFFSET = 0x24;

local categories = {
    { name = "San d'Oria", current = 0x0050, completed = 0x0090, bytes = 32 },
    { name = 'Bastok', current = 0x0058, completed = 0x0098, bytes = 32 },
    { name = 'Windurst', current = 0x0060, completed = 0x00A0, bytes = 32 },
    { name = 'Jeuno', current = 0x0068, completed = 0x00A8, bytes = 32 },
    { name = 'Other', current = 0x0070, completed = 0x00B0, bytes = 32 },
    { name = 'Outlands', current = 0x0078, completed = 0x00B8, bytes = 32 },
    { name = 'Aht Urhgan', current = 0x0080, completed = 0x00C0, bytes = 16 },
    { name = 'Wings of the Goddess', current = 0x0088, completed = 0x00C8, bytes = 32 },
    { name = 'Abyssea', current = 0x00E0, completed = 0x00E8, bytes = 32 },
    { name = 'Adoulin', current = 0x00F0, completed = 0x00F8, bytes = 32 },
    { name = 'Coalition assignments', current = 0x0100, completed = 0x0108, bytes = 32 },
};

local categoryByType = {};
for _, category in ipairs(categories) do
    categoryByType[category.current] = category;
    categoryByType[category.completed] = category;
end

local captured = {};

local function ReadByte(data, offset)
    local ok, value = pcall(struct.unpack, 'B', data, offset + 1);
    return ok == true and tonumber(value) or nil;
end

local function ReadUInt16(data, offset)
    local low = ReadByte(data, offset);
    local high = ReadByte(data, offset + 1);
    if (low == nil or high == nil) then
        return nil;
    end

    return low + bit.lshift(high, 8);
end

local function ReadFlags(data, byteCount)
    local flags = {};

    for byteIndex = 0, byteCount - 1 do
        flags[byteIndex + 1] = ReadByte(data, QUEST_FLAGS_OFFSET + byteIndex) or 0;
    end

    return flags;
end

local function HasQuest(flags, questId)
    if (flags == nil) then
        return false;
    end

    local byteIndex = math.floor(questId / 8) + 1;
    local mask = bit.lshift(1, questId % 8);
    return bit.band(flags[byteIndex] or 0, mask) ~= 0;
end

local function GetQuestIds(flags, byteCount)
    local ids = {};

    for questId = 0, (byteCount * 8) - 1 do
        if (HasQuest(flags, questId) == true) then
            ids[#ids + 1] = questId;
        end
    end

    return ids;
end

local function JoinIds(ids)
    local values = {};
    for _, value in ipairs(ids) do
        values[#values + 1] = tostring(value);
    end
    return table.concat(values, ', ');
end

function questLogTest.HandlePacketIn(e)
    if (e == nil or tonumber(e.id) ~= QUEST_PACKET_ID) then
        return;
    end

    local data = e.data_modified or e.data;
    if (data == nil) then
        return;
    end

    local packetType = ReadUInt16(data, QUEST_TYPE_OFFSET);
    local category = categoryByType[packetType];
    if (category == nil) then
        return;
    end

    captured[packetType] = ReadFlags(data, category.bytes);
end

function questLogTest.Request()
    local capturedCount = 0;
    for _, category in ipairs(categories) do
        if (captured[category.current] ~= nil) then
            capturedCount = capturedCount + 1;
        end
        if (captured[category.completed] ~= nil) then
            capturedCount = capturedCount + 1;
        end
    end

    if (capturedCount == 0) then
        log.Info('Normal quest test: no quest-log packets captured yet. Change zones once, then use /lp questtest again.');
        return;
    end

    log.Info(string.format('Normal quest test: captured %d/%d quest-log sections.', capturedCount, #categories * 2));

    local inProgressTotal = 0;
    for _, category in ipairs(categories) do
        local currentFlags = captured[category.current];
        local completedFlags = captured[category.completed];

        if (currentFlags ~= nil and completedFlags ~= nil) then
            local inProgress = {};
            for _, questId in ipairs(GetQuestIds(currentFlags, category.bytes)) do
                if (HasQuest(completedFlags, questId) ~= true) then
                    inProgress[#inProgress + 1] = questId;
                end
            end

            if (#inProgress > 0) then
                inProgressTotal = inProgressTotal + #inProgress;
                log.Info(string.format('[In progress] %s quest IDs: %s', category.name, JoinIds(inProgress)));
            end
        end
    end

    log.Info('Normal quest test: ' .. tostring(inProgressTotal) .. ' in-progress quest flags found.');
    log.Info('This first test prints DAT quest IDs; adding names requires a bundled quest-name database.');
end

return questLogTest;
