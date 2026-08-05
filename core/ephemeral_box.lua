require('common');

local imgui = require('imgui');
local log = require('core.log');
local state = require('core.state');
local globalDefaults = require('config.global');
local fonts = require('core.fonts');
local gdiTextTexture = require('ui.gdi_text_texture');

local ephemeralBox = {};

local debugEnabled = false;
local lastStatus = '';
local captureMode = nil;
local captureUntil = 0;
local notifications = {};
local nextNotificationId = 0;
local commandQueue = {};
local itemNameCache = nil;
local itemIdByNameCache = nil;
local pendingPullToastUntil = 0;
local pendingPullToastCount = 0;
local pendingWithdrawToasts = {};
local Now = nil;
local StartCapture = nil;
local SendWithdrawPacket = nil;

local DISPLAY_SECONDS = 4.0;
local FADE_SECONDS = 0.75;
local CAPTURE_SECONDS = 12.0;
local MAX_NOTIFICATIONS = 8;
local TOAST_WIDTH = 340;
local TOAST_ROW_HEIGHT = 42;
local FAVORITE_PULL_DELAY = 2.0;
local TOAST_ACCENT_COLOR = { 0.17, 0.84, 0.87, 1.0 };
local TROVE_PACKET_ID = 0x1A4;
local TROVE_C2S_WITHDRAW = 2;
local TROVE_S2C_ACK = 3;

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or 0;
    if (value < minValue) then return minValue; end
    if (value > maxValue) then return maxValue; end
    return value;
end

local function ColorToU32(color)
    local a = math.floor(Clamp(color[4], 0, 1) * 255 + 0.5);
    local r = math.floor(Clamp(color[1], 0, 1) * 255 + 0.5);
    local g = math.floor(Clamp(color[2], 0, 1) * 255 + 0.5);
    local b = math.floor(Clamp(color[3], 0, 1) * 255 + 0.5);
    return bit.bor(bit.lshift(a, 24), bit.lshift(b, 16), bit.lshift(g, 8), r);
end

local function SetStatus(message)
    lastStatus = tostring(message or '');
end

local function QueueCommand(command, mode)
    if (AshitaCore == nil or AshitaCore.GetChatManager == nil) then
        return false;
    end

    AshitaCore:GetChatManager():QueueCommand(tonumber(mode) or 1, tostring(command or ''));
    return true;
end

local function QueueCommandAt(command, delay)
    commandQueue[#commandQueue + 1] = {
        command = tostring(command or ''),
        at = Now() + math.max(0, tonumber(delay) or 0),
    };
end

local function ProcessCommandQueue()
    local now = Now();
    local index = 1;

    while (index <= #commandQueue) do
        local row = commandQueue[index];
        if ((tonumber(row.at) or 0) <= now) then
            if (row.withdraw == true) then
                if (SendWithdrawPacket(row.itemId, row.amount) == true) then
                    pendingWithdrawToasts[#pendingWithdrawToasts + 1] = {
                        itemName = row.itemName,
                        amount = row.amount,
                        createdAt = now,
                    };
                end
            elseif (QueueCommand(row.command, 1) == true) then
                StartCapture('pull');
            end
            table.remove(commandQueue, index);
        else
            index = index + 1;
        end
    end
end

local function MakePacket()
    local packet = {};
    for index = 1, 64 do
        packet[index] = 0;
    end
    return packet;
end

local function WriteU16(packet, offset, value)
    value = tonumber(value) or 0;
    packet[offset + 1] = bit.band(value, 0xFF);
    packet[offset + 2] = bit.band(bit.rshift(value, 8), 0xFF);
end

local function WriteU32(packet, offset, value)
    value = tonumber(value) or 0;
    packet[offset + 1] = bit.band(value, 0xFF);
    packet[offset + 2] = bit.band(bit.rshift(value, 8), 0xFF);
    packet[offset + 3] = bit.band(bit.rshift(value, 16), 0xFF);
    packet[offset + 4] = bit.band(bit.rshift(value, 24), 0xFF);
end

SendWithdrawPacket = function(itemId, amount)
    if (AshitaCore == nil or AshitaCore.GetPacketManager == nil) then
        return false;
    end

    local packet = MakePacket();
    packet[5] = TROVE_C2S_WITHDRAW;
    WriteU16(packet, 0x08, itemId);
    WriteU32(packet, 0x0C, amount);

    AshitaCore:GetPacketManager():AddOutgoingPacket(TROVE_PACKET_ID, packet);
    return true;
end

Now = function()
    return os.clock();
end

local function StripChatCodes(value)
    return tostring(value or ''):gsub(string.char(0x1E) .. '.', ''):gsub('[%z\1-\31]', '');
end

local function CleanText(value)
    return StripChatCodes(value):gsub('^%s+', ''):gsub('%s+$', '');
end

local function GetTextCandidates(e)
    local results = {};
    local seen = {};
    local keys = { 'message_modified', 'modified', 'text', 'original', 'injected', 'message' };

    for _, key in ipairs(keys) do
        local value = e ~= nil and e[key] or nil;
        if (type(value) == 'string') then
            local text = CleanText(value);
            if (text ~= '' and seen[text] ~= true) then
                seen[text] = true;
                results[#results + 1] = text;
            end
        end
    end

    return results;
end

local function GetFavoriteSettings()
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    globalSettings.quickMenu = globalSettings.quickMenu or {};
    globalSettings.quickMenu.ephemeralBox = globalSettings.quickMenu.ephemeralBox or {};
    globalSettings.quickMenu.ephemeralBox.favorites = globalSettings.quickMenu.ephemeralBox.favorites or {};
    return globalSettings.quickMenu.ephemeralBox;
end

local function ReadResourceName(resource)
    if (resource == nil) then
        return '';
    end

    local candidates = {
        function() return resource.Name[1]; end,
        function() return resource.Name[0]; end,
        function() return resource.Name; end,
        function() return resource.NameSingular[1]; end,
        function() return resource.NameSingular[0]; end,
        function() return resource.NameSingular; end,
        function() return resource.LogNameSingular[1]; end,
        function() return resource.LogNameSingular[0]; end,
        function() return resource.LogNameSingular; end,
        function() return resource.En; end,
        function() return resource.en; end,
        function() return resource.English; end,
        function() return resource.english; end,
    };

    for _, getter in ipairs(candidates) do
        local ok, value = pcall(getter);
        if (ok == true and value ~= nil) then
            local text = CleanText(value);
            if (text ~= '' and text:find('userdata:', 1, true) == nil) then
                return text;
            end
        end
    end

    return '';
end

local function BuildItemNameCache()
    itemNameCache = {};
    itemIdByNameCache = {};

    if (AshitaCore == nil or AshitaCore.GetResourceManager == nil) then
        return;
    end

    local resourceManager = nil;
    pcall(function()
        resourceManager = AshitaCore:GetResourceManager();
    end);

    if (resourceManager == nil or resourceManager.GetItemById == nil) then
        return;
    end

    local seen = {};
    for itemId = 1, 65535 do
        local resource = nil;
        pcall(function()
            resource = resourceManager:GetItemById(itemId);
        end);

        local name = ReadResourceName(resource);
        local key = name:lower();
        if (name ~= '' and seen[key] ~= true) then
            seen[key] = true;
            itemNameCache[#itemNameCache + 1] = name;
            itemIdByNameCache[key] = itemId;
        end
    end

    table.sort(itemNameCache, function(left, right)
        return tostring(left):lower() < tostring(right):lower();
    end);
end

local function ResolveItemId(itemName)
    local key = CleanText(itemName):lower();
    if (key == '') then
        return nil;
    end

    if (itemNameCache == nil or itemIdByNameCache == nil) then
        BuildItemNameCache();
    end

    return itemIdByNameCache ~= nil and tonumber(itemIdByNameCache[key]) or nil;
end

StartCapture = function(mode)
    captureMode = mode;
    captureUntil = Now() + CAPTURE_SECONDS;
end

local function AddNotification(action, itemName, amount)
    itemName = CleanText(itemName);
    amount = math.max(1, math.floor(tonumber(amount) or 1));

    if (itemName == '') then
        return;
    end

    nextNotificationId = nextNotificationId + 1;
    notifications[#notifications + 1] = {
        id = nextNotificationId,
        action = tostring(action or 'Box'),
        itemName = itemName,
        amount = amount,
        createdAt = Now(),
    };

    while (#notifications > MAX_NOTIFICATIONS) do
        table.remove(notifications, 1);
    end
end

local function ParseStoreLine(text)
    local itemName, amount = text:match('^You store%s+(.+)%s+x(%d+)%s+%([Tt]otal:%s*%d+%)');
    return itemName, amount;
end

local function IsBoxHaveLine(text)
    return tostring(text or ''):match('^Ephemeral Box%s*:%s*I have%s+%d+%s+.+%.%s+%(.+%)%.?$') ~= nil;
end

local function ParsePullLine(text)
    local amount, itemName = text:match('[Yy]ou obtain%s+(%d+)%s+(.+)[!%.]$');
    return itemName, amount;
end

local function GetDisplaySize()
    if (imgui.GetIO ~= nil) then
        local ok, io = pcall(function()
            return imgui.GetIO();
        end);
        if (ok == true and io ~= nil and io.DisplaySize ~= nil) then
            return tonumber(io.DisplaySize.x or io.DisplaySize.X or io.DisplaySize[1]) or 1280,
                tonumber(io.DisplaySize.y or io.DisplaySize.Y or io.DisplaySize[2]) or 720;
        end
    end

    return 1280, 720;
end

local function AddTextTexture(drawList, text, x, y, options)
    if (drawList == nil or drawList.AddImage == nil or text == nil or text == '') then
        return 0, 0;
    end

    options = options or {};
    local alpha = Clamp(options.alpha or 1.0, 0, 1);
    local textureId, width, height = gdiTextTexture.GetTexture(tostring(text or ''), {
        fontFamily = options.fontFamily,
        fontFlags = tonumber(options.fontFlags) or 0,
        fontSize = math.max(8, math.floor(tonumber(options.fontSize) or 14)),
        color = options.color or { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = options.outlineEnabled ~= false,
        outlineColor = options.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = tonumber(options.outlineSize) or 2,
    });

    width = tonumber(width) or 0;
    height = tonumber(height) or 0;

    if (textureId == nil or width <= 0 or height <= 0) then
        return 0, 0;
    end

    drawList:AddImage(textureId, { x, y }, { x + width, y + height }, { 0, 0 }, { 1, 1 }, ColorToU32({ 1.0, 1.0, 1.0, alpha }));
    return width, height;
end

function ephemeralBox.IsTarget(name, info)
    local text = tostring(name or ''):gsub('_', ' '):lower();
    if (text == 'ephemeral box') then
        return true;
    end

    if (info ~= nil) then
        return ephemeralBox.IsTarget(info.name) == true
            or ephemeralBox.IsTarget(info.displayName) == true
            or ephemeralBox.IsTarget(info.type) == true;
    end

    return false;
end

function ephemeralBox.StoreAll()
    if (QueueCommand('!box store', 1) == true) then
        SetStatus('Store all sent.');
        StartCapture('store');
        if (debugEnabled == true) then
            log.Info('Ephemeral Box store-all command queued.');
        end
        return true;
    end

    SetStatus('Store all failed: chat manager unavailable.');
    log.Warn('Ephemeral Box store-all failed: chat manager unavailable.');
    return false;
end

function ephemeralBox.OpenNative()
    SetStatus('Native E.Box browsing is handled by another addon.');
    return false;
end

function ephemeralBox.ScanCategories()
    SetStatus('E.Box scanning has been removed.');
    return false;
end

function ephemeralBox.ScanAll()
    SetStatus('E.Box scanning has been removed.');
    return false;
end

function ephemeralBox.ScanCategoryItems()
    SetStatus('E.Box scanning has been removed.');
    return false;
end

function ephemeralBox.RequestExtract()
    return ephemeralBox.PullFavorites();
end

function ephemeralBox.GetFavorites()
    return GetFavoriteSettings().favorites;
end

function ephemeralBox.PullItem(itemName, amount, delay)
    itemName = CleanText(itemName);
    amount = math.max(1, math.floor(tonumber(amount) or 1));

    if (itemName == '') then
        SetStatus('E.Box pull failed: missing item name.');
        return false;
    end

    local itemId = ResolveItemId(itemName);
    if (itemId == nil or itemId <= 0) then
        QueueCommandAt('!box ' .. tostring(amount) .. ' ' .. itemName, delay or 0);
        pendingPullToastUntil = math.max(pendingPullToastUntil, Now() + CAPTURE_SECONDS + math.max(0, tonumber(delay) or 0));
        pendingPullToastCount = pendingPullToastCount + 1;
        StartCapture('pull');
        SetStatus('Pull queued: ' .. itemName .. ' x' .. tostring(amount) .. '.');
        return true;
    end

    commandQueue[#commandQueue + 1] = {
        at = Now() + math.max(0, tonumber(delay) or 0),
        withdraw = true,
        itemId = itemId,
        itemName = itemName,
        amount = amount,
    };
    pendingPullToastUntil = math.max(pendingPullToastUntil, Now() + CAPTURE_SECONDS + math.max(0, tonumber(delay) or 0));
    pendingPullToastCount = pendingPullToastCount + 1;
    SetStatus('Pull queued: ' .. itemName .. ' x' .. tostring(amount) .. '.');
    return true;
end

function ephemeralBox.PullFavorite(index)
    local favorite = GetFavoriteSettings().favorites[tonumber(index) or 0];
    if (favorite == nil) then
        SetStatus('E.Box favorite not found.');
        return false;
    end

    return ephemeralBox.PullItem(favorite.itemName or favorite.name, favorite.amount, 0);
end

function ephemeralBox.PullFavorites()
    local favorites = GetFavoriteSettings().favorites;
    if (#favorites <= 0) then
        SetStatus('No E.Box favorites configured.');
        return false;
    end

    local queued = 0;
    for _, favorite in ipairs(favorites) do
        local itemName = CleanText(favorite.itemName or favorite.name);
        if (itemName ~= '') then
            queued = queued + 1;
            ephemeralBox.PullItem(itemName, favorite.amount, (queued - 1) * FAVORITE_PULL_DELAY);
        end
    end

    if (queued <= 0) then
        SetStatus('No valid E.Box favorites configured.');
        return false;
    end

    SetStatus('Pull favorites queued: ' .. tostring(queued) .. ' item' .. (queued == 1 and '.' or 's.'));
    return true;
end

function ephemeralBox.GetItemNameSuggestions(query, limit)
    query = CleanText(query):lower();
    limit = math.max(1, math.floor(tonumber(limit) or 8));

    if (query == '' or #query < 2) then
        return {};
    end

    if (itemNameCache == nil) then
        BuildItemNameCache();
    end

    local prefixMatches = {};
    local containsMatches = {};
    for _, name in ipairs(itemNameCache or {}) do
        local lowerName = tostring(name):lower();
        if (lowerName:sub(1, #query) == query) then
            prefixMatches[#prefixMatches + 1] = name;
        elseif (lowerName:find(query, 1, true) ~= nil) then
            containsMatches[#containsMatches + 1] = name;
        end

        if ((#prefixMatches + #containsMatches) >= limit) then
            break;
        end
    end

    local results = {};
    for _, name in ipairs(prefixMatches) do
        if (#results >= limit) then break; end
        results[#results + 1] = name;
    end
    for _, name in ipairs(containsMatches) do
        if (#results >= limit) then break; end
        results[#results + 1] = name;
    end

    return results;
end

function ephemeralBox.HandlePacketIn(e)
    if (e == nil or e.id ~= TROVE_PACKET_ID) then
        return;
    end

    local data = e.data_modified or e.data;
    if (type(data) ~= 'string' or struct == nil or struct.unpack == nil) then
        return;
    end

    local action = nil;
    pcall(function()
        action = struct.unpack('B', data, 0x04 + 1);
    end);

    if (tonumber(action) ~= TROVE_S2C_ACK) then
        return;
    end

    local requestAction = nil;
    local success = nil;
    pcall(function()
        requestAction = struct.unpack('B', data, 0x05 + 1);
        success = struct.unpack('B', data, 0x06 + 1);
    end);

    if (tonumber(requestAction) ~= TROVE_C2S_WITHDRAW or #pendingWithdrawToasts <= 0) then
        return;
    end

    local pending = table.remove(pendingWithdrawToasts, 1);
    if (tonumber(success) == 1 and pending ~= nil) then
        AddNotification('Pulled', pending.itemName, pending.amount);
        pendingPullToastCount = math.max(0, pendingPullToastCount - 1);
        if (pendingPullToastCount <= 0) then
            pendingPullToastUntil = 0;
        end
    end
end

function ephemeralBox.HandlePacketOut()
end

function ephemeralBox.HandleTextIn(e)
    local texts = GetTextCandidates(e);
    if (#texts <= 0) then
        return false;
    end

    for _, text in ipairs(texts) do
        local lower = text:lower();
        if (lower:find('!box store', 1, true) ~= nil) then
            StartCapture('store');
            return false;
        end

        if (lower:match('!box%s+%d+%s+') ~= nil) then
            StartCapture('pull');
            pendingPullToastUntil = math.max(pendingPullToastUntil, Now() + CAPTURE_SECONDS);
            if (pendingPullToastCount <= 0) then
                pendingPullToastCount = 1;
            end
            return false;
        end

        if (IsBoxHaveLine(text) == true) then
            StartCapture('pull');
            pendingPullToastUntil = math.max(pendingPullToastUntil, Now() + CAPTURE_SECONDS);
            if (pendingPullToastCount <= 0) then
                pendingPullToastCount = 1;
            end
        end
    end

    if (captureMode == nil or Now() > captureUntil) then
        return false;
    end

    if (captureMode == 'store') then
        for _, text in ipairs(texts) do
            local itemName, amount = ParseStoreLine(text);
            if (itemName ~= nil) then
                AddNotification('Stored', itemName, amount);
                break;
            end
        end
    elseif (captureMode == 'pull') then
        if (Now() > pendingPullToastUntil or pendingPullToastCount <= 0) then
            return false;
        end

        for _, text in ipairs(texts) do
            local itemName, amount = ParsePullLine(text);
            if (itemName ~= nil) then
                AddNotification('Pulled', itemName, amount);
                pendingPullToastCount = math.max(0, pendingPullToastCount - 1);
                if (pendingPullToastCount <= 0) then
                    pendingPullToastUntil = 0;
                end
                break;
            end
        end
    end

    return false;
end

function ephemeralBox.Update()
end

function ephemeralBox.HandlePresent()
    ProcessCommandQueue();

    local now = Now();
    for index = #notifications, 1, -1 do
        local row = notifications[index];
        local age = now - (tonumber(row.createdAt) or now);
        if (age > (DISPLAY_SECONDS + FADE_SECONDS)) then
            table.remove(notifications, index);
        end
    end

    if (#notifications <= 0) then
        return;
    end

    local maxAlpha = 0;
    for _, row in ipairs(notifications) do
        local age = now - (tonumber(row.createdAt) or now);
        local alpha = 1.0;
        if (age > DISPLAY_SECONDS) then
            alpha = math.max(0, 1.0 - ((age - DISPLAY_SECONDS) / FADE_SECONDS));
        end
        row.alpha = alpha;
        if (alpha > maxAlpha) then
            maxAlpha = alpha;
        end
    end

    if (maxAlpha <= 0.01) then
        return;
    end

    local displayW = GetDisplaySize();
    local windowW = TOAST_WIDTH;
    local drawList = imgui.GetForegroundDrawList ~= nil and imgui.GetForegroundDrawList() or (imgui.GetWindowDrawList ~= nil and imgui.GetWindowDrawList() or nil);
    if (drawList == nil) then
        return;
    end

    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local fontFamily = fonts.GetRole(globalSettings, false);
    local smallFontFamily = fonts.GetRole(globalSettings, true);
    local fontFlags = fonts.GetRoleFlags(globalSettings, false);
    local smallFontFlags = fonts.GetRoleFlags(globalSettings, true);
    local baseX = math.max(0, (displayW - windowW) * 0.5);
    local rowY = 118;

    for _, row in ipairs(notifications) do
        local alpha = tonumber(row.alpha) or maxAlpha;
        local age = now - (tonumber(row.createdAt) or now);
        local enterProgress = Clamp(age / 0.22, 0, 1);
        local easedEnter = 1 - math.pow(1 - enterProgress, 3);
        local slideX = (row.action == 'Stored' and -18 or 18) * (1 - easedEnter);
        local x = baseX + slideX;
        local y = rowY;
        local actionColor = row.action == 'Stored'
            and { 0.57, 0.87, 1.0, 1.0 }
            or { 0.58, 1.0, 0.62, 1.0 };
        local subtitle = tostring(row.itemName or '') .. ' x' .. tostring(row.amount or 1);

        drawList:AddRectFilled(
            { x, y },
            { x + windowW, y + TOAST_ROW_HEIGHT - 4 },
            ColorToU32({ 0.055, 0.040, 0.032, 0.74 * alpha }),
            0
        );
        drawList:AddRectFilled(
            { x, y },
            { x + 4, y + TOAST_ROW_HEIGHT - 4 },
            ColorToU32({ TOAST_ACCENT_COLOR[1], TOAST_ACCENT_COLOR[2], TOAST_ACCENT_COLOR[3], 0.80 * alpha }),
            0
        );

        AddTextTexture(drawList, tostring(row.action or 'Box'), x + 14, y + 5, {
            fontFamily = smallFontFamily,
            fontFlags = smallFontFlags,
            fontSize = 12,
            color = actionColor,
            outlineEnabled = true,
            outlineColor = { 0.0, 0.0, 0.0, 1.0 },
            outlineSize = 2,
            alpha = alpha,
        });

        AddTextTexture(drawList, subtitle, x + 14, y + 21, {
            fontFamily = fontFamily,
            fontFlags = fontFlags,
            fontSize = 14,
            color = { 0.92, 0.89, 0.84, 1.0 },
            outlineEnabled = true,
            outlineColor = { 0.0, 0.0, 0.0, 1.0 },
            outlineSize = 2,
            alpha = alpha,
        });

        rowY = rowY + TOAST_ROW_HEIGHT;
    end
end

function ephemeralBox.GetCache()
    return {
        categories = {},
        categoryOrder = {},
    };
end

function ephemeralBox.GetStatus()
    return lastStatus;
end

function ephemeralBox.GetProgress()
    return {
        busy = false,
        status = lastStatus,
    };
end

function ephemeralBox.IsBusy()
    return false;
end

function ephemeralBox.SetDebugEnabled(value)
    debugEnabled = value == true;
end

return ephemeralBox;
