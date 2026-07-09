require('common');

local log = require('core.log');
local expGuideData = require('data.warp.exp_guides');

local expGuideTeleport = {};

local pending = nil;
local queue = {};
local debugEnabled = false;

local function Now()
    return os.clock();
end

local function FormatBytes(bytes, maxBytes)
    local output = {};
    local count = math.min(#(bytes or {}), math.max(1, tonumber(maxBytes) or 32));

    for index = 1, count do
        output[#output + 1] = string.format('%02X', tonumber(bytes[index]) or 0);
    end

    if (#(bytes or {}) > count) then
        output[#output + 1] = '...';
    end

    return table.concat(output, ' ');
end

local function PacketText(data)
    if (type(data) ~= 'string') then
        return '';
    end

    local out = {};
    for index = 1, #data do
        local byte = string.byte(data, index);
        if (byte ~= nil and byte >= 32 and byte <= 126) then
            out[#out + 1] = string.char(byte);
        else
            out[#out + 1] = ' ';
        end
    end

    return table.concat(out):gsub('%s+', ' ');
end

local function PacketStrings(data)
    local strings = {};
    local current = {};

    if (type(data) ~= 'string') then
        return strings;
    end

    for index = 1, #data do
        local byte = string.byte(data, index);
        if (byte ~= nil and byte >= 32 and byte <= 126) then
            current[#current + 1] = string.char(byte);
        elseif (#current > 0) then
            strings[#strings + 1] = table.concat(current);
            current = {};
        end
    end

    if (#current > 0) then
        strings[#strings + 1] = table.concat(current);
    end

    return strings;
end

local function GetCustomQuestion(data, prefix)
    local expected = tostring(prefix or '');
    if (expected == '') then
        return nil;
    end

    for _, value in ipairs(PacketStrings(data)) do
        if (tostring(value):find(expected, 1, true) ~= nil) then
            return tostring(value);
        end
    end

    return nil;
end

local function GetPlayerName()
    local name = nil;

    pcall(function()
        local party = AshitaCore:GetMemoryManager():GetParty();
        name = party ~= nil and party:GetMemberName(0) or nil;
    end);

    return tostring(name or '');
end

local function GetServerId(targetIndex)
    local serverId = nil;

    pcall(function()
        serverId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(tonumber(targetIndex) or 0);
    end);

    return tonumber(serverId) or 0;
end

local function BuildNpcPokePacket(serverId, targetIndex)
    return struct.pack(
        'bbbbihhhhfff',
        0x1A,
        0x07,
        0x00,
        0x00,
        tonumber(serverId) or 0,
        tonumber(targetIndex) or 0,
        0x00,
        0x00,
        0x00,
        0.0,
        0.0,
        0.0
    ):totable();
end

local function BuildCustomMenuPacket(question, result)
    local menuName = '_CUSTOM_MENU';
    local message = menuName .. string.char(0x00, 0x00, 0x00) .. 'GMTELL(' .. GetPlayerName() .. '): Question(' .. tostring(question or '') .. '): Result (' .. tostring(result or '') .. ')';
    local packetSize = 6 + #message + 1;
    if ((packetSize % 2) ~= 0) then
        packetSize = packetSize + 1;
    end

    local bytes = {
        0xB6,
        math.floor(packetSize / 2),
        0x00,
        0x00,
        0x03,
        0x00,
    };

    for index = 1, #message do
        bytes[#bytes + 1] = string.byte(message, index);
    end

    bytes[#bytes + 1] = 0x00;
    while (#bytes < packetSize) do
        bytes[#bytes + 1] = 0x00;
    end

    return bytes;
end

local function SendOutgoingPacket(id, packedData, description)
    if (packedData == nil) then
        return false;
    end

    local ok, err = pcall(function()
        AshitaCore:GetPacketManager():AddOutgoingPacket(id, packedData);
    end);

    if (ok ~= true) then
        log.Warn('EXP Guide teleport packet failed ' .. tostring(description or '') .. ' id=0x' .. string.format('%03X', tonumber(id) or 0) .. ' err=' .. tostring(err));
        return false;
    end

    if (debugEnabled == true) then
        log.Info('EXP Guide teleport sent packet ' .. tostring(description or '') .. ' id=0x' .. string.format('%03X', tonumber(id) or 0) .. ' bytes=' .. FormatBytes(packedData, 48));
    end

    return true;
end

local function QueueAction(delay, fn)
    queue[#queue + 1] = {
        at = Now() + math.max(0, tonumber(delay) or 0),
        fn = fn,
    };
end

local function SendCustomAnswer(question, result, description)
    return SendOutgoingPacket(0x0B6, BuildCustomMenuPacket(question, result), description);
end

function expGuideTeleport.Request(destination, context, option)
    context = context or {};

    local targetIndex = tonumber(context.targetIndex) or 0;
    local targetId = tonumber(context.targetId) or GetServerId(targetIndex);
    local mode = expGuideData.modes[tostring(destination.mode or context.mode or 'past')];
    local optionType = type(option);
    local withBuff = optionType == 'boolean' and option == true;
    local paymentResult = optionType == 'table' and option.result or nil;

    if (mode == nil) then
        log.Warn('EXP Guide teleport failed: unknown guide mode.');
        return false;
    end

    if (targetIndex <= 0 or targetId <= 0) then
        log.Warn('EXP Guide teleport failed: no valid EXP Guide target.');
        return false;
    end

    pending = {
        destination = destination,
        mode = mode,
        withBuff = withBuff == true,
        paymentResult = paymentResult,
        targetIndex = targetIndex,
        targetId = targetId,
        currentPage = 1,
        targetPage = math.max(1, tonumber(destination.page) or 1),
        startedAt = Now(),
        state = (mode.initialQuestion ~= nil and tostring(mode.initialQuestion or '') ~= '') and 'waitingInitial' or 'waitingDestination',
    };
    queue = {};

    log.Info('EXP Guide teleport request targetIndex=' .. tostring(targetIndex) .. ' targetId=' .. tostring(targetId) .. ' destination=' .. tostring(destination.result or destination.label or '') .. ' page=' .. tostring(pending.targetPage) .. ' sigil=' .. tostring(withBuff == true) .. ' payment=' .. tostring(paymentResult or ''));

    return SendOutgoingPacket(0x01A, BuildNpcPokePacket(targetId, targetIndex), 'poke exp guide');
end

function expGuideTeleport.HandlePacketIn(e)
    if (pending == nil or e == nil or e.id ~= 0x017 or type(e.data) ~= 'string') then
        return;
    end

    local text = PacketText(e.data_modified or e.data);
    local active = pending;

    local question = GetCustomQuestion(e.data_modified or e.data, active.mode.question) or active.mode.question;

    if (active.state == 'waitingInitial' and active.mode.initialQuestion ~= nil and text:find(active.mode.initialQuestion, 1, true) ~= nil) then
        e.blocked = true;
        active.state = 'waitingDestination';
        local initialQuestion = GetCustomQuestion(e.data_modified or e.data, active.mode.initialQuestion) or active.mode.initialQuestion;

        QueueAction(0.08, function()
            SendCustomAnswer(initialQuestion, tostring(active.mode.initialResult or ''), 'select initial service');
        end);
        return;
    end

    if ((active.state == 'waitingDestination' or active.state == 'waitingNextPage') and text:find(active.mode.question, 1, true) ~= nil) then
        e.blocked = true;
        active.currentQuestion = question;

        if ((tonumber(active.currentPage) or 1) < (tonumber(active.targetPage) or 1)) then
            active.state = 'waitingNextPage';
            active.currentPage = (tonumber(active.currentPage) or 1) + 1;
            QueueAction(0.06, function()
                SendCustomAnswer(active.currentQuestion or active.mode.question, tostring(active.mode.nextResult or 'Next'), 'next destination page');
            end);
            return;
        end

        active.state = 'sentDestination';
        QueueAction(0.10, function()
            SendCustomAnswer(active.currentQuestion or active.mode.question, active.destination.result, 'select destination');
            if (active.destination.noPayment == true or ((active.mode.buffQuestion == nil or tostring(active.mode.buffQuestion) == '') and (active.mode.paymentQuestion == nil or tostring(active.mode.paymentQuestion) == '') and (active.mode.confirmQuestionPrefix == nil or tostring(active.mode.confirmQuestionPrefix) == ''))) then
                pending = nil;
            end
        end);
        return;
    end

    if (active.state == 'sentDestination' and active.mode.paymentQuestion ~= nil and text:find(active.mode.paymentQuestion, 1, true) ~= nil) then
        e.blocked = true;
        active.state = 'sentPayment';
        local answer = tostring(active.paymentResult or '');
        QueueAction(0.18, function()
            SendCustomAnswer(active.mode.paymentQuestion, answer, 'select payment');
            pending = nil;
        end);
        return;
    end;

    if (active.state == 'sentDestination' and active.mode.confirmQuestionPrefix ~= nil and text:find(active.mode.confirmQuestionPrefix, 1, true) ~= nil) then
        e.blocked = true;
        active.state = 'sentConfirm';
        local confirmQuestion = GetCustomQuestion(e.data_modified or e.data, active.mode.confirmQuestionPrefix) or text:match('([^%z]+)') or active.mode.confirmQuestionPrefix;
        QueueAction(0.18, function()
            SendCustomAnswer(confirmQuestion, tostring(active.mode.confirmResult or "Let's go!"), 'confirm destination');
            pending = nil;
        end);
        return;
    end

    if (active.state == 'sentDestination' and active.mode.buffQuestion ~= nil and text:find(active.mode.buffQuestion, 1, true) ~= nil) then
        e.blocked = true;
        active.state = 'sentBuff';
        local answer = active.withBuff == true and 'Yes' or 'No';
        QueueAction(0.18, function()
            SendCustomAnswer(active.mode.buffQuestion, answer, 'select buff');
            pending = nil;
        end);
    end
end

function expGuideTeleport.HandlePacketOut(e)
    -- Reserved for future debug filtering.
end

function expGuideTeleport.Update()
    if (pending ~= nil and (Now() - (tonumber(pending.startedAt) or 0)) > 14.0) then
        log.Warn('EXP Guide teleport timed out waiting for custom menu.');
        pending = nil;
        queue = {};
        return;
    end

    local now = Now();
    local index = 1;

    while index <= #queue do
        local action = queue[index];
        if (action ~= nil and now >= (tonumber(action.at) or 0)) then
            table.remove(queue, index);
            pcall(action.fn);
        else
            index = index + 1;
        end
    end
end

function expGuideTeleport.SetDebugEnabled(value)
    debugEnabled = value == true;
end

return expGuideTeleport;
