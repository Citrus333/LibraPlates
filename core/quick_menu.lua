local imgui = require('imgui');
local state = require('core.state');
local globalDefaults = require('config.global');
local textureLoader = require('core.texture_loader');
local npcObjectInfo = require('core.npc_object_info');
local log = require('core.log');
local jobChange = require('core.job_change');
local jobIconTextures = require('core.job_icon_textures');
local mounts = require('core.mounts');
local targeting = require('core.targeting');
local playerBlacklist = require('core.player_blacklist');
local widgetDefaults = { enabled = true };
local quickMenuPresetCount = 10;

local quickMenu = {};
local pendingMenu = nil;
local pendingConfirm = nil;
local pendingInviteUntil = 0;
local pendingPartyRequestUntil = 0;
local pendingSelfToggles = {};
local popupId = 'LibraPlates Quick Menu';
local confirmPopupId = 'LibraPlates Quick Menu Confirm';
local iconCache = {};
local missingIcon = {};
local aceHeaderIconPath = 'widget-icons\\ace.png';
local npcBodyTextColor = { 0.92, 0.92, 0.90, 1.0 };
local npcSectionTextColor = { 1.0, 0.86, 0.36, 1.0 };
local npcLinkTextColor = { 0.48, 0.82, 1.0, 1.0 };
local invisibleTextColor = { 0.0, 0.0, 0.0, 0.0 };
local npcInfoBullet = '*';
local npcInfoMoreText = 'More on wiki...';
local OpenUrl = nil;
local EnsurePresetSettings = nil;

local function ColorToU32(color, fallback)
    local c = color or fallback or { 1.0, 1.0, 1.0, 1.0 };
    local r = math.floor((tonumber(c[1]) or 1.0) * 255 + 0.5);
    local g = math.floor((tonumber(c[2]) or 1.0) * 255 + 0.5);
    local b = math.floor((tonumber(c[3]) or 1.0) * 255 + 0.5);
    local a = math.floor((tonumber(c[4]) or 1.0) * 255 + 0.5);

    if (r < 0) then r = 0 elseif (r > 255) then r = 255 end
    if (g < 0) then g = 0 elseif (g > 255) then g = 255 end
    if (b < 0) then b = 0 elseif (b > 255) then b = 255 end
    if (a < 0) then a = 0 elseif (a > 255) then a = 255 end

    return (a * 0x1000000) + (b * 0x10000) + (g * 0x100) + r;
end

local function ColorLuma(color)
    color = color or {};

    local r = tonumber(color[1]) or 0;
    local g = tonumber(color[2]) or 0;
    local b = tonumber(color[3]) or 0;

    return (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
end

local function GetReadableTextColor(menu)
    local textColor = menu ~= nil and menu.textColor or nil;
    local backgroundColor = menu ~= nil and menu.backgroundColor or nil;

    if (type(textColor) ~= 'table') then
        return { 0.92, 0.92, 0.90, 1.0 };
    end

    local textAlpha = tonumber(textColor[4]) or 1.0;
    local bgAlpha = tonumber(backgroundColor ~= nil and backgroundColor[4]) or 1.0;
    local contrast = math.abs(ColorLuma(textColor) - ColorLuma(backgroundColor));

    if (bgAlpha > 0.35 and (textAlpha < 0.65 or contrast < 0.28)) then
        if (ColorLuma(backgroundColor) < 0.5) then
            return { 0.92, 0.92, 0.90, 1.0 };
        end

        return { 0.08, 0.08, 0.10, 1.0 };
    end

    return textColor;
end

local function ReadVec(valueA, valueB)
    if (type(valueA) == 'table') then
        return tonumber(valueA[1] or valueA.x or valueA.X) or 0, tonumber(valueA[2] or valueA.y or valueA.Y) or 0;
    end

    return tonumber(valueA) or 0, tonumber(valueB) or 0;
end

local function GetWindowPos()
    if (imgui.GetWindowPos == nil) then
        return 0, 0;
    end

    local ok, a, b = pcall(function()
        return imgui.GetWindowPos();
    end);

    if (ok ~= true) then
        return 0, 0;
    end

    return ReadVec(a, b);
end

local function GetWindowSize()
    if (imgui.GetWindowSize == nil) then
        return 0, 0;
    end

    local ok, a, b = pcall(function()
        return imgui.GetWindowSize();
    end);

    if (ok ~= true) then
        return 0, 0;
    end

    return ReadVec(a, b);
end

local function GetCursorPos()
    if (imgui.GetCursorPos == nil) then
        return 0, 0;
    end

    local ok, a, b = pcall(function()
        return imgui.GetCursorPos();
    end);

    if (ok ~= true) then
        return 0, 0;
    end

    return ReadVec(a, b);
end

local function SplitLines(text)
    local lines = {};
    text = tostring(text or ''):gsub('\r\n', '\n'):gsub('\r', '\n');

    for line in (text .. '\n'):gmatch('(.-)\n') do
        lines[#lines + 1] = line;
    end

    return lines;
end

local function WrapLine(line, maxChars)
    local wrapped = {};
    line = tostring(line or '');
    maxChars = math.max(12, tonumber(maxChars) or 34);

    if (#line <= maxChars) then
        wrapped[#wrapped + 1] = line;
        return wrapped;
    end

    local current = '';

    for word in line:gmatch('%S+') do
        if (current == '') then
            current = word;
        elseif (#current + #word + 1 <= maxChars) then
            current = current .. ' ' .. word;
        else
            wrapped[#wrapped + 1] = current;
            current = word;
        end
    end

    if (current ~= '') then
        wrapped[#wrapped + 1] = current;
    end

    if (#wrapped == 0) then
        wrapped[#wrapped + 1] = line;
    end

    return wrapped;
end

local function QueueForegroundTextBlock(text, color, maxWidth, linkResolver, sectionColor, linkColor)
    if (pendingMenu == nil or pendingMenu.foreground == nil) then
        return 0;
    end

    local cursorX, cursorY = GetCursorPos();
    local windowX = tonumber(pendingMenu.foreground.windowX) or 0;
    local windowY = tonumber(pendingMenu.foreground.windowY) or 0;
    local maxChars = math.floor((tonumber(maxWidth) or tonumber(pendingMenu.foreground.width) or 270) / 7);
    local y = windowY + cursorY;
    local canPlaceLinks = linkResolver ~= nil
        and imgui.InvisibleButton ~= nil
        and imgui.SetCursorPosX ~= nil
        and imgui.SetCursorPosY ~= nil;

    pendingMenu.foreground.textRows = pendingMenu.foreground.textRows or {};

    local lineHeight = 15;

    for _, line in ipairs(SplitLines(text)) do
        if (line == '') then
            y = y + lineHeight;
        else
            local isBullet = line:match('^%*%s+') ~= nil;
            local isSectionHeader = isBullet ~= true and line:match(':%s*$') ~= nil;
            local displayLine = isBullet and line:gsub('^%*%s+', '') or line;
            local textX = windowX + cursorX + (isBullet and 12 or 0);
            local link = linkResolver ~= nil and linkResolver(line) or nil;
            local lineColor = isSectionHeader and (sectionColor or npcSectionTextColor) or color;

            for index, wrapped in ipairs(WrapLine(displayLine, maxChars - (isBullet and 2 or 0))) do
                if (canPlaceLinks == true and index == 1 and link ~= nil and link.url ~= nil and link.url ~= '') then
                    local buttonWidth = math.min(math.max(80, #wrapped * 7 + 16), math.max(80, (tonumber(maxWidth) or 270) - (isBullet and 12 or 0)));
                    imgui.SetCursorPosX(textX - windowX);
                    imgui.SetCursorPosY(y - windowY);

                    if (imgui.InvisibleButton('##npc_info_link_' .. tostring(#pendingMenu.foreground.textRows + 1), { buttonWidth, lineHeight }) == true) then
                        OpenUrl(link.url);

                        if (imgui.CloseCurrentPopup ~= nil) then
                            imgui.CloseCurrentPopup();
                        end
                    end
                end

                pendingMenu.foreground.textRows[#pendingMenu.foreground.textRows + 1] = {
                    x = textX,
                    y = y,
                    text = wrapped,
                    color = (link ~= nil and index == 1) and (link.color or linkColor or npcLinkTextColor) or lineColor,
                    bullet = isBullet == true and index == 1,
                    bulletX = windowX + cursorX + 3,
                };
                y = y + lineHeight;
            end
        end
    end

    if (canPlaceLinks == true) then
        imgui.SetCursorPosX(cursorX);
        imgui.SetCursorPosY(cursorY);
    end

    return math.max(0, y - (windowY + cursorY));
end

local function ReserveTextBlockHeight(height, fallbackText)
    height = math.max(0, tonumber(height) or 0);

    if (height <= 0) then
        return;
    end

    if (imgui.Dummy ~= nil) then
        imgui.Dummy({ 1, height });
        return;
    end

    if (imgui.InvisibleButton ~= nil and pendingMenu ~= nil and pendingMenu.foreground ~= nil) then
        pendingMenu.foreground.spacerCount = (tonumber(pendingMenu.foreground.spacerCount) or 0) + 1;
        imgui.InvisibleButton('##npc_info_spacer_' .. tostring(pendingMenu.foreground.spacerCount), { 1, height });
        return;
    end

    imgui.TextColored(invisibleTextColor, tostring(fallbackText or ''));
end

local function NormalizeNpcInfoText(text)
    text = tostring(text or ''):gsub('\r\n', '\n'):gsub('\r', '\n');

    text = text:gsub('◆', npcInfoBullet);
    text = text:gsub('(^)%s*[%-%*]%s+', '%1' .. npcInfoBullet .. ' ');
    text = text:gsub('(\n)%s*[%-%*]%s+', '%1' .. npcInfoBullet .. ' ');

    return text;
end

local function StripNpcNotesSection(text)
    local output = {};
    local skippingNotes = false;

    for _, line in ipairs(SplitLines(text)) do
        local clean = tostring(line or ''):gsub('^%s+', ''):gsub('%s+$', '');
        local isBullet = clean:match('^%*%s+') ~= nil;
        local isHeader = isBullet ~= true and clean:match(':%s*$') ~= nil;

        if (isHeader == true and clean:match('^Notes:%s*$') ~= nil) then
            skippingNotes = true;
        elseif (skippingNotes == true and isHeader == true) then
            skippingNotes = false;
            output[#output + 1] = line;
        elseif (skippingNotes ~= true) then
            output[#output + 1] = line;
        end
    end

    return table.concat(output, '\n'):gsub('\n+$', '');
end

local function LimitNpcInfoText(text, maxChars, maxLines)
    text = StripNpcNotesSection(NormalizeNpcInfoText(text));
    maxChars = math.max(120, tonumber(maxChars) or 420);
    maxLines = math.max(4, tonumber(maxLines) or 10);

    local output = {};
    local used = 0;
    local truncated = false;

    for _, line in ipairs(SplitLines(text)) do
        if (#output >= maxLines) then
            truncated = true;
            break;
        end

        local nextLine = tostring(line or '');
        local nextLen = #nextLine + ((#output > 0) and 1 or 0);

        if ((used + nextLen) > maxChars) then
            local remaining = math.max(0, maxChars - used - ((#output > 0) and 1 or 0));

            if (remaining > 12) then
                output[#output + 1] = nextLine:sub(1, remaining):gsub('%s+$', '') .. '...';
            end

            truncated = true;
            break;
        end

        output[#output + 1] = nextLine;
        used = used + nextLen;
    end

    local result = table.concat(output, '\n'):gsub('\n+$', '');

    if (truncated == true) then
        if (result ~= '') then
            result = result .. '\n\n' .. npcInfoMoreText;
        else
            result = npcInfoMoreText;
        end
    end

    return result;
end

local function SafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok == true and result ~= nil) then
        return result;
    end

    return fallback;
end

local function GetIcon(fileName)
    local name = tostring(fileName or '');

    if (name == '') then
        return nil;
    end

    if (missingIcon[name] == true) then
        return nil;
    end

    if (iconCache[name] ~= nil) then
        return iconCache[name];
    end

    local path = addon.path .. '\\assets\\images\\quick-menu\\' .. name;
    local exists = false;

    pcall(function()
        exists = ashita.fs.exists(path);
    end);

    if (exists ~= true) then
        missingIcon[name] = true;
        return nil;
    end

    local ok, texture = pcall(function()
        return textureLoader.Load(path);
    end);

    if (ok ~= true or texture == nil) then
        missingIcon[name] = true;
        return nil;
    end

    iconCache[name] = textureLoader.ToTextureId(texture);

    if (iconCache[name] == nil) then
        missingIcon[name] = true;
    end

    return iconCache[name];
end

local function GetImageIcon(relativePath)
    local name = tostring(relativePath or ''):gsub('/', '\\');

    if (name == '') then
        return nil;
    end

    local cacheKey = 'image:' .. name;

    if (missingIcon[cacheKey] == true) then
        return nil;
    end

    if (iconCache[cacheKey] ~= nil) then
        return iconCache[cacheKey];
    end

    local path = addon.path .. '\\assets\\images\\' .. name;
    local exists = false;

    pcall(function()
        exists = ashita.fs.exists(path);
    end);

    if (exists ~= true) then
        missingIcon[cacheKey] = true;
        return nil;
    end

    local ok, texture = pcall(function()
        return textureLoader.Load(path);
    end);

    if (ok ~= true or texture == nil) then
        missingIcon[cacheKey] = true;
        return nil;
    end

    iconCache[cacheKey] = textureLoader.ToTextureId(texture);

    if (iconCache[cacheKey] == nil) then
        missingIcon[cacheKey] = true;
    end

    return iconCache[cacheKey];
end

local function IsCatseyeInfo(info)
    local source = tostring(info ~= nil and info.source or '');

    return source == 'catseye_npc' or source == 'catseye_item';
end

local function GetStorageStateName(entry)
    local name = tostring(entry ~= nil and entry.layoutStateName or '');

    if (name == 'Combat' or name == 'Tactical') then
        return 'Combat';
    end

    if (name == 'Resting' or name == 'Fishing' or name == 'Crafting' or name == 'Gathering') then
        return name;
    end

    return 'Idle';
end

local function EnsureSettings()
    local global = state.GetGlobalSettings(globalDefaults);
    global.quickMenu = global.quickMenu or {};
    local menu = global.quickMenu;

    if (menu.enabled == nil) then menu.enabled = true; end
    if (menu.openOnRightClick == nil) then menu.openOnRightClick = true; end
    if (menu.modifier == nil) then menu.modifier = 'None'; end
	if (menu.width == nil or menu.width < 300) then menu.width = 300; end
    if (menu.iconsEnabled == nil) then menu.iconsEnabled = true; end
    if (menu.iconSize == nil) then menu.iconSize = 22; end
    if (menu.backgroundColor == nil) then menu.backgroundColor = { 0.02, 0.02, 0.07, 0.96 }; end
    if (menu.borderColor == nil) then menu.borderColor = { 0.25, 0.25, 0.36, 1.0 }; end
    if (menu.borderSize == nil) then menu.borderSize = 1; end
    if (menu.textColor == nil) then menu.textColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (menu.headerColor == nil) then menu.headerColor = { 1.0, 0.84, 0.0, 1.0 }; end
    if (menu.linkColor == nil) then menu.linkColor = npcLinkTextColor; end
    menu.textColor = GetReadableTextColor(menu);
    if (menu.pc == nil) then menu.pc = {}; end
    if (menu.pc.examine == nil) then menu.pc.examine = true; end
    if (menu.pc.catseyeProfile == nil) then menu.pc.catseyeProfile = true; end
    if (menu.pc.follow == nil) then menu.pc.follow = true; end
    if (menu.pc.inviteToParty == nil) then menu.pc.inviteToParty = true; end
    if (menu.pc.requestJoinParty == nil) then menu.pc.requestJoinParty = true; end
    if (menu.pc.invitePartyToAlliance == nil) then menu.pc.invitePartyToAlliance = true; end
    if (menu.pc.passPartyLeader == nil) then menu.pc.passPartyLeader = true; end
    if (menu.pc.passAllianceLeader == nil) then menu.pc.passAllianceLeader = true; end
    if (menu.pc.blacklist == nil) then menu.pc.blacklist = true; end
    if (menu.self == nil) then menu.self = {}; end
    if (menu.self.acceptInvite == nil) then menu.self.acceptInvite = true; end
    if (menu.self.declineInvite == nil) then menu.self.declineInvite = true; end
    if (menu.self.leaveParty == nil) then menu.self.leaveParty = true; end
    if (menu.self.leaveAlliance == nil) then menu.self.leaveAlliance = true; end
    if (menu.self.cancelPartyRequest == nil) then menu.self.cancelPartyRequest = true; end
    if (menu.self.aceTownMog == nil) then menu.self.aceTownMog = true; end
    if (menu.self.mount == nil) then menu.self.mount = true; end
    local ownedMountChoices = mounts.GetOwnedChoices();
    if (menu.self.selectedMount == nil or tostring(menu.self.selectedMount or '') == '' or mounts.IsOwned(menu.self.selectedMount) ~= true) then menu.self.selectedMount = ownedMountChoices[1] or ''; end
    if (menu.self.autogroup == nil) then menu.self.autogroup = (menu.self.autogroupOn ~= false or menu.self.autogroupOff ~= false); end
    if (menu.self.ignoreTrust == nil) then menu.self.ignoreTrust = (menu.self.ignoreTrustOn ~= false or menu.self.ignoreTrustOff ~= false); end
    if (menu.self.hideTrust == nil) then menu.self.hideTrust = (menu.self.hideTrustOn ~= false or menu.self.hideTrustOff ~= false); end
    if (menu.self.emoteTrust == nil) then menu.self.emoteTrust = (menu.self.emoteTrustOn ~= false or menu.self.emoteTrustOff ~= false); end
    if (menu.self.ignoreTrustState == nil) then menu.self.ignoreTrustState = false; end
    if (menu.self.hideTrustState == nil) then menu.self.hideTrustState = false; end
    if (menu.self.emoteTrustState == nil) then menu.self.emoteTrustState = false; end
    if (menu.trust == nil) then menu.trust = {}; end
    if (menu.trust.dismiss == nil) then menu.trust.dismiss = true; end
    if (menu.trust.dismissAll == nil) then menu.trust.dismissAll = true; end
    if (menu.trust.confirmDismissAll == nil) then menu.trust.confirmDismissAll = true; end
    if (menu.npc == nil) then menu.npc = {}; end
    if (menu.npc.showType == nil) then menu.npc.showType = true; end
    if (menu.npc.showInfo == nil) then menu.npc.showInfo = true; end
    if (menu.npc.openLink == nil) then menu.npc.openLink = true; end
    if (menu.npc.maxInfoChars == nil) then menu.npc.maxInfoChars = 420; end
    if (menu.npc.maxInfoLines == nil) then menu.npc.maxInfoLines = 10; end
    if (menu.npc.maxQuestLinks == nil or tonumber(menu.npc.maxQuestLinks) == 4) then menu.npc.maxQuestLinks = 8; end
    EnsurePresetSettings(menu);

    return menu;
end

local function IsModifierDown(menu)
    local modifier = tostring(menu.modifier or 'None');

    if (modifier == 'None') then
        return true;
    end

    if (imgui.GetIO == nil) then
        return false;
    end

    local ok, io = pcall(function()
        return imgui.GetIO();
    end);

    if (ok ~= true or io == nil) then
        return false;
    end

    if (modifier == 'Shift') then
        return io.KeyShift == true;
    end

    if (modifier == 'Ctrl') then
        return io.KeyCtrl == true;
    end

    if (modifier == 'Alt') then
        return io.KeyAlt == true;
    end

    return true;
end

local function GetEntityName(targetIndex, fallback)
    local entity = GetEntity(tonumber(targetIndex) or 0);
    local name = entity ~= nil and tostring(entity.Name or '') or '';

    if (name ~= '') then
        return name;
    end

    return tostring(fallback or 'Player');
end

local function QueueCommand(command, mode)
    if (AshitaCore == nil or AshitaCore.GetChatManager == nil) then
        return;
    end

    AshitaCore:GetChatManager():QueueCommand(tonumber(mode) or 1, tostring(command or ''));
end

local function QuoteCommandName(name)
    return '"' .. tostring(name or ''):gsub('"', '') .. '"';
end

EnsurePresetSettings = function(menu)
    menu.presets = menu.presets or {};
    if (menu.presets.iconTheme == nil) then menu.presets.iconTheme = 'FFXI'; end
    if (menu.presets.hideInfo == nil) then menu.presets.hideInfo = true; end
    menu.presets.entries = menu.presets.entries or {};

    for index = 1, quickMenuPresetCount do
        menu.presets.entries[index] = menu.presets.entries[index] or {};
        if (menu.presets.entries[index].mainJob == nil) then menu.presets.entries[index].mainJob = 'None'; end
        if (menu.presets.entries[index].subJob == nil) then menu.presets.entries[index].subJob = 'None'; end
        if (menu.presets.entries[index].lockstyleSet == nil) then menu.presets.entries[index].lockstyleSet = 0; end
    end
end

local function NormalizeLockstyleSet(value)
    local number = tonumber(tostring(value or ''):match('%d+')) or 0;
    number = math.floor(number + 0.5);

    if (number < 0) then number = 0; end
    if (number > 999) then number = 999; end

    return number;
end

local function GetPresetRows(menu)
    local rows = {};
    local entries = menu ~= nil and menu.presets ~= nil and menu.presets.entries or nil;
    local theme = menu ~= nil and menu.presets ~= nil and menu.presets.iconTheme or 'FFXI';

    if (type(entries) ~= 'table') then
        return rows;
    end

    for _, entry in ipairs(entries) do
        local mainJob = tostring(entry.mainJob or 'None');
        local subJob = tostring(entry.subJob or 'None');
        local lockstyleSet = NormalizeLockstyleSet(entry.lockstyleSet);

        if (mainJob ~= 'None' and subJob ~= 'None' and mainJob ~= subJob) then
            rows[#rows + 1] = {
                label = mainJob .. '/' .. subJob .. (lockstyleSet > 0 and ('  LS ' .. string.format('%03d', lockstyleSet)) or ''),
                mainJob = mainJob,
                subJob = subJob,
                lockstyleSet = lockstyleSet,
                textureId = jobIconTextures.GetTextureId(mainJob, theme),
            };
        end
    end

    return rows;
end

OpenUrl = function(url)
    pcall(function()
        os.execute('start "" "' .. tostring(url or '') .. '"');
    end);
end

local function UrlEncodePathPart(value)
    local text = tostring(value or '');

    text = text:gsub(' ', '_');
    text = text:gsub('([^%w%-%._~])', function(char)
        return string.format('%%%02X', string.byte(char));
    end);

    return text;
end

local function BuildNpcLink(name, info)
    local npcName = tostring(name or '');

    if (npcName == '') then
        return '';
    end

    local explicit = tostring(info ~= nil and info.link or '');

    if (explicit ~= '') then
        return explicit;
    end

    if (tostring(info ~= nil and info.source or '') == 'catseye_npc') then
        return 'https://www.bg-wiki.com/ffxi/CatsEyeXI_NPCs#' .. UrlEncodePathPart(npcName);
    end

    return 'https://www.bg-wiki.com/ffxi/' .. UrlEncodePathPart(npcName);
end

local function BuildWikiLink(title)
    title = tostring(title or ''):gsub('^%s+', ''):gsub('%s+$', '');

    if (title == '') then
        return '';
    end

    return 'https://www.bg-wiki.com/ffxi/' .. UrlEncodePathPart(title);
end

local function BuildQuestLink(title, info)
    local wikiTitle = tostring(title or ''):gsub('^%s+', ''):gsub('%s+$', '');
    local source = tostring(info ~= nil and info.source or '');
    local link = tostring(info ~= nil and info.link or '');

    if (wikiTitle == '') then
        return '';
    end

    if (source == 'catseye_npc' and link ~= '' and link:match('CatsEyeXI_Systems/Quests') ~= nil) then
        local base = link:gsub('#.*$', '');

        if (base ~= '') then
            return base .. '#' .. UrlEncodePathPart(wikiTitle);
        end
    end

    return BuildWikiLink(wikiTitle);
end

local function ExtractQuestLinks(text, maxLinks, info)
    local links = {};
    local seen = {};
    local inQuestSection = false;
    maxLinks = math.max(0, tonumber(maxLinks) or 4);

    if (maxLinks == 0) then
        return links;
    end

    for _, line in ipairs(SplitLines(NormalizeNpcInfoText(text))) do
        local clean = tostring(line or ''):gsub('^%s+', ''):gsub('%s+$', '');

        if (clean == '') then
            inQuestSection = false;
        elseif (
            clean:lower():match('^starts quest[s]?:') ~= nil or
            clean:lower():match('^involved in quest[s]?:') ~= nil or
            clean:lower():match('^starts mission[s]?:') ~= nil or
            clean:lower():match('^involved in mission[s]?:') ~= nil
        ) then
            inQuestSection = true;
        elseif (clean:match('^[%w%s]+:') ~= nil and clean:match('^%*%s+') == nil) then
            inQuestSection = false;
        elseif (inQuestSection == true) then
            local title = clean:gsub('^%*%s+', ''):gsub('^%-%s+', ''):gsub('%s+$', '');

            if (title ~= '' and seen[title] ~= true) then
                seen[title] = true;
                links[#links + 1] = {
                    title = title,
                    url = BuildQuestLink(title, info),
                };

                if (#links >= maxLinks) then
                    break;
                end
            end
        end
    end

    return links;
end

local function CreateQuestLineLinkResolver(maxLinks, linkColor, info)
    local seen = {};
    local count = 0;
    local inQuestSection = false;
    maxLinks = math.max(0, tonumber(maxLinks) or 4);

    return function(line)
        if (maxLinks == 0) then
            return nil;
        end

        local clean = tostring(line or ''):gsub('^%s+', ''):gsub('%s+$', '');

        if (clean == '') then
            inQuestSection = false;
            return nil;
        end

        if (
            clean:lower():match('^starts quest[s]?:') ~= nil or
            clean:lower():match('^involved in quest[s]?:') ~= nil or
            clean:lower():match('^starts mission[s]?:') ~= nil or
            clean:lower():match('^involved in mission[s]?:') ~= nil
        ) then
            inQuestSection = true;
            return nil;
        end

        if (clean:match('^[%w%s]+:') ~= nil and clean:match('^%*%s+') == nil) then
            inQuestSection = false;
            return nil;
        end

        if (inQuestSection ~= true or clean:match('^%*%s+') == nil) then
            return nil;
        end

        local title = clean:gsub('^%*%s+', ''):gsub('%s+$', '');

        if (title == '' or seen[title] == true or count >= maxLinks) then
            return nil;
        end

        seen[title] = true;
        count = count + 1;

        return {
            title = title,
            url = BuildQuestLink(title, info),
            color = linkColor or npcLinkTextColor,
        };
    end;
end

local function GetParty()
    return SafeCall(nil, function()
        return AshitaCore:GetMemoryManager():GetParty();
    end);
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
        return party, nil;
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
        return 0;
    end

    if (partyIndex == 3 and party.GetAlliancePartyLeaderServerId3 ~= nil) then
        return tonumber(SafeCall(0, function() return party:GetAlliancePartyLeaderServerId3(); end)) or 0;
    end

    if (partyIndex == 2 and party.GetAlliancePartyLeaderServerId2 ~= nil) then
        return tonumber(SafeCall(0, function() return party:GetAlliancePartyLeaderServerId2(); end)) or 0;
    end

    if (party.GetAlliancePartyLeaderServerId1 ~= nil) then
        return tonumber(SafeCall(0, function() return party:GetAlliancePartyLeaderServerId1(); end)) or 0;
    end

    if (party.GetAlliancePartyLeaderServerId ~= nil) then
        return tonumber(SafeCall(0, function() return party:GetAlliancePartyLeaderServerId((tonumber(partyIndex) or 1) - 1); end)) or 0;
    end

    return 0;
end

local function GetPartyContext(targetIndex)
    local party, targetSlot = GetPartySlotByTargetIndex(targetIndex);

    if (party == nil) then
        return {
            selfSolo = true,
            selfPartyLeader = false,
            selfAllianceLeader = false,
            selfInParty = false,
            inAlliance = false,
            targetIsSelf = false,
            targetInMyParty = false,
            targetInAlliance = false,
            targetPartyLeader = false,
        };
    end

    local selfPartyIndex = 1;
    local targetPartyIndex = targetSlot ~= nil and (math.floor(targetSlot / 6) + 1) or nil;
    local selfPartyCount = GetPartyMemberCount(party, selfPartyIndex);
    local activePartyCount = GetActiveAlliancePartyCount(party);
    local selfServerId = tonumber(SafeCall(0, function() return party:GetMemberServerId(0); end)) or 0;
    local selfLeaderId = GetPartyLeaderServerId(party, selfPartyIndex);
    local selfIsLeader = selfLeaderId ~= 0 and selfServerId ~= 0 and selfLeaderId == selfServerId;

    if (selfLeaderId == 0 and selfPartyCount > 1) then
        selfIsLeader = true;
    end

    local targetIsLeader = false;

    if (targetSlot ~= nil and targetPartyIndex ~= nil) then
        local targetServerId = tonumber(SafeCall(0, function() return party:GetMemberServerId(targetSlot); end)) or 0;
        local targetLeaderId = GetPartyLeaderServerId(party, targetPartyIndex);

        if (targetLeaderId ~= 0 and targetServerId ~= 0) then
            targetIsLeader = targetLeaderId == targetServerId;
        elseif (GetPartyMemberCount(party, targetPartyIndex) > 1) then
            targetIsLeader = targetSlot == ((targetPartyIndex - 1) * 6);
        end
    end

    return {
        selfSolo = selfPartyCount <= 1 and activePartyCount <= 1,
        selfInParty = selfPartyCount > 1 or activePartyCount > 1,
        selfPartyLeader = selfIsLeader == true,
        selfAllianceLeader = selfIsLeader == true and activePartyCount > 1,
        inAlliance = activePartyCount > 1,
        targetIsSelf = targetSlot == 0,
        targetInMyParty = targetSlot ~= nil and targetSlot >= 0 and targetSlot <= 5,
        targetInAlliance = targetSlot ~= nil,
        targetPartyLeader = targetIsLeader == true,
    };
end

local function MenuItem(label, iconFile, action, menu, keepOpen, textureIdOverride)
    local rowStartX = imgui.GetCursorPosX ~= nil and imgui.GetCursorPosX() or nil;
    local rowStartY = imgui.GetCursorPosY ~= nil and imgui.GetCursorPosY() or nil;
    local iconSize = tonumber(menu.iconSize) or 22;
    local rowHeight = math.max(24, iconSize + 2);
    local rowWidth = math.max(160, (tonumber(menu.width) or 270) - 26);

    if (imgui.InvisibleButton ~= nil) then
        local clicked = imgui.InvisibleButton('##quick_menu_' .. tostring(iconFile or '') .. '_' .. tostring(label or '') .. '_' .. tostring(textureIdOverride or ''), { rowWidth, rowHeight }) == true;
        local afterX = imgui.GetCursorPosX ~= nil and imgui.GetCursorPosX() or nil;
        local afterY = imgui.GetCursorPosY ~= nil and imgui.GetCursorPosY() or nil;

        if (rowStartX ~= nil and rowStartY ~= nil and imgui.SetCursorPosX ~= nil and imgui.SetCursorPosY ~= nil) then
            imgui.SetCursorPosX(rowStartX);
            imgui.SetCursorPosY(rowStartY);
        end

        if (menu.iconsEnabled ~= false and imgui.Image ~= nil) then
            local textureId = textureIdOverride or GetIcon(iconFile);

            if (textureId ~= nil) then
                imgui.Image(textureId, { iconSize, iconSize }, { 0, 0 }, { 1, 1 });
                imgui.SameLine();
            end
        end

        if (imgui.SetCursorPosY ~= nil and rowStartY ~= nil) then
            imgui.SetCursorPosY(rowStartY + math.max(0, math.floor((rowHeight - 18) * 0.5)));
        end

        imgui.TextColored(GetReadableTextColor(menu), label);

        if (afterX ~= nil and afterY ~= nil and imgui.SetCursorPosX ~= nil and imgui.SetCursorPosY ~= nil) then
            imgui.SetCursorPosX(afterX);
            imgui.SetCursorPosY(afterY);
        end

        if (clicked == true) then
            action();
            if (keepOpen ~= true and imgui.CloseCurrentPopup ~= nil) then
                imgui.CloseCurrentPopup();
            end
        end

        if (pendingMenu ~= nil and pendingMenu.foreground ~= nil and rowStartX ~= nil and rowStartY ~= nil) then
            local windowX = tonumber(pendingMenu.foreground.windowX) or 0;
            local windowY = tonumber(pendingMenu.foreground.windowY) or 0;
            pendingMenu.foreground.rows[#pendingMenu.foreground.rows + 1] = {
                x = windowX + rowStartX,
                y = windowY + rowStartY,
                label = tostring(label or ''),
                iconFile = iconFile,
                textureId = textureIdOverride,
                rowHeight = rowHeight,
                iconSize = iconSize,
            };
        end
        return;
    end

    imgui.TextColored(GetReadableTextColor(menu), label);
    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        action();
        if (keepOpen ~= true and imgui.CloseCurrentPopup ~= nil) then
            imgui.CloseCurrentPopup();
        end
    end
end

local function ToggleMenuItem(label, iconFile, currentState, commandBase, setState, menu, offIconFile, keepOpen)
    local known = currentState == true or currentState == false;
    local isOn = currentState == true;
    local nextState = known and (not isOn) or true;
    local display = tostring(label or 'Toggle') .. ': ' .. (known and (isOn and 'On' or 'Off') or 'Unknown');
    local command = tostring(commandBase or '') .. (nextState and ' on' or ' off');
    local displayIcon = (isOn or known ~= true) and iconFile or (offIconFile or iconFile);

    MenuItem(display, displayIcon, function()
        QueueCommand(command);
        setState(nextState);
        pcall(function()
            state.Save();
        end);
    end, menu, keepOpen == true);
end

local function SelfToggleMenuItem(key, label, iconFile, currentState, commandBase, setState, menu, offIconFile)
    local pending = pendingSelfToggles[key];

    if (pending ~= nil and os.clock() < (tonumber(pending.expiresAt) or 0)) then
        local display = tostring(label or 'Toggle') .. ': ...';
        MenuItem(display, iconFile, function()
        end, menu, true);
        return;
    end

    pendingSelfToggles[key] = nil;

    local isOn = currentState == true;
    local nextState = not isOn;
    local display = tostring(label or 'Toggle') .. ': ' .. (isOn and 'On' or 'Off');
    local command = tostring(commandBase or '') .. (nextState and ' on' or ' off');
    local displayIcon = isOn and iconFile or (offIconFile or iconFile);

    MenuItem(display, displayIcon, function()
        pendingSelfToggles[key] = {
            expected = nextState == true,
            expiresAt = os.clock() + 2.0,
        };
        QueueCommand(command, 0);
    end, menu, true);
end

local function RequestConfirm(label, command, options)
    options = options or {};

    pendingConfirm = {
        label = tostring(label or 'action'),
        command = (type(command) == 'string') and tostring(command or '') or nil,
        action = type(command) == 'function' and command or options.action,
        reasonEnabled = options.reasonEnabled == true,
        reasonLabel = tostring(options.reasonLabel or 'Reason'),
        reasonRef = { tostring(options.reason or '') },
        confirmLabel = tostring(options.confirmLabel or 'Confirm'),
        open = true,
    };
end

local function DrawConfirm()
    if (pendingConfirm == nil) then
        return;
    end

    if (pendingConfirm.open == true and imgui.OpenPopup ~= nil) then
        imgui.OpenPopup(confirmPopupId);
        pendingConfirm.open = false;
    end

    if (imgui.BeginPopupModal == nil) then
        imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, pendingConfirm.label .. '?');

        if (pendingConfirm.reasonEnabled == true and imgui.InputText ~= nil) then
            imgui.Text(tostring(pendingConfirm.reasonLabel or 'Reason'));
            imgui.InputText('##quick_menu_confirm_reason', pendingConfirm.reasonRef, 160);
        end

        if (imgui.Button ~= nil and imgui.Button('Cancel') == true) then
            pendingConfirm = nil;
            return;
        end

        imgui.SameLine();

        if (imgui.Button ~= nil and imgui.Button(pendingConfirm.confirmLabel or 'Confirm') == true) then
            if (pendingConfirm.action ~= nil) then
                pendingConfirm.action(tostring(pendingConfirm.reasonRef ~= nil and pendingConfirm.reasonRef[1] or ''));
            elseif (pendingConfirm.command ~= nil) then
                QueueCommand(pendingConfirm.command);
            end
            pendingConfirm = nil;
        end

        return;
    end

    if (imgui.SetNextWindowSize ~= nil) then
        imgui.SetNextWindowSize({ 230, 0 }, _G.ImGuiCond_Always or 2);
    end

    if (imgui.BeginPopupModal(confirmPopupId)) then
        imgui.Text(pendingConfirm.label .. '?');
        if (pendingConfirm.reasonEnabled == true and imgui.InputText ~= nil) then
            imgui.Text(tostring(pendingConfirm.reasonLabel or 'Reason'));
            imgui.InputText('##quick_menu_confirm_reason', pendingConfirm.reasonRef, 160);
        end
        imgui.Separator();

        if (imgui.Button ~= nil and imgui.Button('Cancel') == true) then
            pendingConfirm = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.SameLine();

        if (imgui.Button ~= nil and imgui.Button(pendingConfirm.confirmLabel or 'Confirm') == true) then
            if (pendingConfirm.action ~= nil) then
                pendingConfirm.action(tostring(pendingConfirm.reasonRef ~= nil and pendingConfirm.reasonRef[1] or ''));
            elseif (pendingConfirm.command ~= nil) then
                QueueCommand(pendingConfirm.command);
            end
            pendingConfirm = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.EndPopup();
    end
end

local function DrawForegroundMenu(menu)
    if (pendingMenu == nil or pendingMenu.foreground == nil or imgui.GetForegroundDrawList == nil) then
        return;
    end

    local drawList = imgui.GetForegroundDrawList();

    if (drawList == nil) then
        return;
    end

    local foreground = pendingMenu.foreground;
    local x = tonumber(foreground.windowX) or tonumber(pendingMenu.x) or 0;
    local y = tonumber(foreground.windowY) or tonumber(pendingMenu.y) or 0;
    local width = math.max(160, tonumber(foreground.width) or tonumber(menu.width) or 270);
    local height = math.max(40, tonumber(foreground.height) or 40);
    local iconSize = tonumber(menu.iconSize) or 22;
    local textColor = ColorToU32(GetReadableTextColor(menu), { 1.0, 1.0, 1.0, 1.0 });
    local headerColor = ColorToU32(menu.headerColor, { 1.0, 0.84, 0.0, 1.0 });
    local bgColor = ColorToU32(menu.backgroundColor, { 0.02, 0.02, 0.07, 0.96 });
    local borderColor = ColorToU32(menu.borderColor, { 0.25, 0.25, 0.36, 1.0 });

    if (drawList.AddRectFilled ~= nil) then
        drawList:AddRectFilled({ x, y }, { x + width, y + height }, bgColor);
    end

    if (drawList.AddRect ~= nil and (tonumber(menu.borderSize) or 1) > 0) then
        drawList:AddRect({ x, y }, { x + width, y + height }, borderColor, 0, 0, tonumber(menu.borderSize) or 1);
    end

    if (foreground.header ~= nil) then
        local headerX = tonumber(foreground.header.x) or (x + 12);
        local headerY = tonumber(foreground.header.y) or (y + 10);

        if (menu.iconsEnabled ~= false and drawList.AddImage ~= nil and (foreground.header.textureId ~= nil or foreground.header.iconFile ~= nil)) then
            local textureId = foreground.header.textureId or GetIcon(foreground.header.iconFile);

            if (textureId ~= nil) then
                drawList:AddImage(textureId, { headerX, headerY }, { headerX + iconSize, headerY + iconSize }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
                headerX = headerX + iconSize + 8;
            end
        end

        if (drawList.AddText ~= nil) then
            drawList:AddText({ headerX, headerY + 2 }, headerColor, tostring(foreground.header.label or ''));
        end
    end

    if (drawList.AddLine ~= nil and foreground.separatorY ~= nil) then
        drawList:AddLine({ x + 12, foreground.separatorY }, { x + width - 12, foreground.separatorY }, borderColor, 1);
    end

    for _, row in ipairs(foreground.rows or {}) do
        local rowX = tonumber(row.x) or (x + 12);
        local rowY = tonumber(row.y) or (y + 36);
        local labelX = rowX;

        if (menu.iconsEnabled ~= false and drawList.AddImage ~= nil and (row.textureId ~= nil or row.iconFile ~= nil)) then
            local textureId = row.textureId or GetIcon(row.iconFile);
            local size = tonumber(row.iconSize) or iconSize;

            if (textureId ~= nil) then
                drawList:AddImage(textureId, { rowX, rowY }, { rowX + size, rowY + size }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
                labelX = rowX + size + 8;
            end
        end

        if (drawList.AddText ~= nil) then
            drawList:AddText({ labelX, rowY + 3 }, textColor, tostring(row.label or ''));
        end
    end

    for _, row in ipairs(foreground.textRows or {}) do
        if (drawList.AddText ~= nil) then
            local rowColor = ColorToU32(row.color or npcBodyTextColor, npcBodyTextColor);

            if (row.bullet == true and drawList.AddCircleFilled ~= nil) then
                local bulletX = tonumber(row.bulletX) or (tonumber(row.x) or (x + 12)) - 9;
                local bulletY = (tonumber(row.y) or (y + 36)) + 7;
                drawList:AddCircleFilled({ bulletX, bulletY }, 2.5, rowColor, 8);
            end

            drawList:AddText(
                { tonumber(row.x) or (x + 12), tonumber(row.y) or (y + 36) },
                rowColor,
                tostring(row.text or '')
            );
        end
    end
end

function quickMenu.GetSettings()
    return EnsureSettings();
end

function quickMenu.HasPendingInvite()
    return os.clock() < (tonumber(pendingInviteUntil) or 0);
end

function quickMenu.ClearTextureCache()
    iconCache = {};
    missingIcon = {};
end

local function HasPendingPartyRequest()
    return os.clock() < (tonumber(pendingPartyRequestUntil) or 0);
end

function quickMenu.HandleTextIn(e)
    local raw = tostring((e ~= nil and (e.message or e.original or e.modified)) or '');
    local text = raw:gsub(string.char(0x1E) .. '.', ''):gsub('[%z\1-\31]', ''):lower();

    if (text == '') then
        return;
    end

    local menu = EnsureSettings();

    if (
        (text:find('invites you', 1, true) ~= nil and text:find('join', 1, true) ~= nil) or
        (text:find('invited you', 1, true) ~= nil) or
        (text:find('invitation to join', 1, true) ~= nil) or
        (text:find('party invitation', 1, true) ~= nil) or
        (text:find('alliance invitation', 1, true) ~= nil) or
        (text:find('invitation from', 1, true) ~= nil and text:find('party', 1, true) ~= nil)
    ) then
        pendingInviteUntil = os.clock() + 60;
        return;
    end

    if (
        text:find('you join', 1, true) ~= nil or
        text:find('you have joined', 1, true) ~= nil or
        text:find('decline', 1, true) ~= nil or
        text:find('invitation has expired', 1, true) ~= nil or
        text:find('invitation was canceled', 1, true) ~= nil or
        text:find('invitation canceled', 1, true) ~= nil
    ) then
        pendingInviteUntil = 0;
    end

    if (
        text:find('party request', 1, true) ~= nil and
        (
            text:find('cancel', 1, true) ~= nil or
            text:find('decline', 1, true) ~= nil or
            text:find('accepted', 1, true) ~= nil or
            text:find('expired', 1, true) ~= nil
        )
    ) then
        pendingPartyRequestUntil = 0;
    end

    if (
        text:find('autogroup', 1, true) ~= nil and
        (
            text:find('enabled', 1, true) ~= nil or
            text:find('on', 1, true) ~= nil or
            text:find('auto_accepted', 1, true) ~= nil or
            text:find('auto accepted', 1, true) ~= nil
        )
    ) then
        menu.self.autogroupState = true;
        state.Save();
    elseif (
        text:find('autogroup', 1, true) ~= nil and
        (
            text:find('disabled', 1, true) ~= nil or
            text:find('off', 1, true) ~= nil
        )
    ) then
        menu.self.autogroupState = false;
        state.Save();
    elseif (text:find("targeting of other players' alter egos has been disabled", 1, true) ~= nil) then
        menu.self.ignoreTrustState = true;
        pendingSelfToggles.ignoreTrust = nil;
        state.Save();
    elseif (text:find("targeting of other players' alter egos has been enabled", 1, true) ~= nil) then
        menu.self.ignoreTrustState = false;
        pendingSelfToggles.ignoreTrust = nil;
        state.Save();
    elseif (text:find("display of other players' alter egos has been disabled", 1, true) ~= nil) then
        menu.self.hideTrustState = true;
        pendingSelfToggles.hideTrust = nil;
        state.Save();
    elseif (text:find("display of other players' alter egos has been enabled", 1, true) ~= nil) then
        menu.self.hideTrustState = false;
        pendingSelfToggles.hideTrust = nil;
        state.Save();
    elseif (text:find('alter ego emotions: linked', 1, true) ~= nil) then
        menu.self.emoteTrustState = true;
        pendingSelfToggles.emoteTrust = nil;
        state.Save();
    elseif (text:find('alter ego emotions: not linked', 1, true) ~= nil) then
        menu.self.emoteTrustState = false;
        pendingSelfToggles.emoteTrust = nil;
        state.Save();
    end
end

function quickMenu.OpenForPlate(entry, x, y)
    local menu = EnsureSettings();
    local targetType = tostring(entry ~= nil and entry.targetType or '');

    if (menu.enabled ~= true or menu.openOnRightClick ~= true) then
        return false;
    end

    if (targetType ~= 'pc' and targetType ~= 'npc' and targetType ~= 'object' and targetType ~= 'self' and targetType ~= 'trust') then
        return false;
    end

    if (IsModifierDown(menu) ~= true) then
        return false;
    end

    local name = tostring(entry.clickName or '');

    if (name == '') then
        name = GetEntityName(entry.targetIndex, entry.name);
    end

    if (targeting.IsGatheringPointName(name) == true) then
        return false;
    end

    if ((targetType == 'trust' or targetType == 'object') and jobChange.IsJobChangeNpcName(name) == true) then
        targetType = 'npc';
    end

    local storageEntity = 'PC';
    if (targetType == 'npc') then
        storageEntity = 'NPC';
    elseif (targetType == 'object') then
        storageEntity = 'Object';
    elseif (targetType == 'self') then
        storageEntity = 'Self';
    elseif (targetType == 'trust') then
        storageEntity = 'Trust';
    end
    local storageState = GetStorageStateName(entry);
    local plateSettings = state.GetWidgetSettings(storageEntity, storageState, 'Quick Menu', widgetDefaults);
    if (plateSettings.enabled ~= true) then
        return false;
    end

    local npcInfo = nil;

    if (targetType == 'npc' or targetType == 'object') then
        npcInfo = npcObjectInfo.Find(name, (targetType == 'object') and 'Object' or 'NPC');
    end

    pendingMenu = {
        targetType = targetType,
        targetIndex = entry.targetIndex,
        serverId = entry.serverId,
        layoutStateName = storageState,
        trustIsMine = entry.trustIsMine == true,
        name = name,
        npcInfo = npcInfo,
        x = tonumber(x) or 0,
        y = tonumber(y) or 0,
        open = true,
    };

    return true;
end

function quickMenu.IsOpen()
    return pendingMenu ~= nil or pendingConfirm ~= nil;
end

function quickMenu.GetTargetIndex()
    return pendingMenu ~= nil and pendingMenu.targetIndex or nil;
end

function quickMenu.GetTargetType()
    return pendingMenu ~= nil and pendingMenu.targetType or nil;
end

function quickMenu.Render()
    local menu = EnsureSettings();

    if (pendingMenu == nil and pendingConfirm == nil) then
        return;
    end

    if (pendingMenu == nil) then
        DrawConfirm();
        return;
    end

    if (pendingMenu.open == true) then
        if (imgui.SetNextWindowPos ~= nil) then
            local popupX = tonumber(pendingMenu.x) or 0;
            local popupY = tonumber(pendingMenu.y) or 0;

            if (pendingMenu.targetType == 'self') then
                popupX = popupX + 24;
                popupY = popupY + 48;
            end

            imgui.SetNextWindowPos({ popupX, popupY }, _G.ImGuiCond_Always or 2);
        end

        if (imgui.OpenPopup ~= nil) then
            imgui.OpenPopup(popupId);
        end

        if (imgui.SetWindowFocus ~= nil) then
            pcall(function()
                imgui.SetWindowFocus(popupId);
            end);
        end

        pendingMenu.open = false;
    end

    if (imgui.SetNextWindowSize ~= nil) then
        imgui.SetNextWindowSize({ tonumber(menu.width) or 270, 0 }, _G.ImGuiCond_Always or 2);
    end

    local colorCount = 0;
    if (imgui.PushStyleColor ~= nil) then
        if (_G.ImGuiCol_PopupBg ~= nil) then imgui.PushStyleColor(_G.ImGuiCol_PopupBg, menu.backgroundColor); colorCount = colorCount + 1; end
        if (_G.ImGuiCol_Border ~= nil) then imgui.PushStyleColor(_G.ImGuiCol_Border, menu.borderColor); colorCount = colorCount + 1; end
        if (_G.ImGuiCol_Text ~= nil) then imgui.PushStyleColor(_G.ImGuiCol_Text, GetReadableTextColor(menu)); colorCount = colorCount + 1; end
    end

    local varCount = 0;
    if (imgui.PushStyleVar ~= nil) then
        if (_G.ImGuiStyleVar_WindowPadding ~= nil) then imgui.PushStyleVar(_G.ImGuiStyleVar_WindowPadding, { 12, 10 }); varCount = varCount + 1; end
        if (_G.ImGuiStyleVar_ItemSpacing ~= nil) then imgui.PushStyleVar(_G.ImGuiStyleVar_ItemSpacing, { 8, 6 }); varCount = varCount + 1; end
    end

    if (imgui.BeginPopup == nil) then
        return;
    end

    local menuOpen = imgui.BeginPopup(popupId);

    if (menuOpen == true) then
        if (imgui.SetWindowFocus ~= nil) then
            pcall(function()
                imgui.SetWindowFocus(popupId);
            end);
        end
        local headerTextureId = nil;
        local windowX, windowY = GetWindowPos();
        local cursorX, cursorY = GetCursorPos();
        local useForeground = pendingMenu.targetType == 'npc' or pendingMenu.targetType == 'object';

        if (useForeground == true) then
            pendingMenu.foreground = {
                windowX = windowX,
                windowY = windowY,
                width = tonumber(menu.width) or 270,
                height = 80,
                rows = {},
                textRows = {},
                header = {
                    x = windowX + cursorX,
                    y = windowY + cursorY,
                    label = pendingMenu.name or ((pendingMenu.targetType == 'npc') and 'NPC' or 'Player'),
                    iconFile = nil,
                    textureId = nil,
                },
                separatorY = nil,
            };
        else
            pendingMenu.foreground = nil;
        end

        if (menu.iconsEnabled ~= false and imgui.Image ~= nil) then
            local iconSize = tonumber(menu.iconSize) or 22;

            if (pendingMenu.targetType == 'npc' or pendingMenu.targetType == 'object') then
                if (IsCatseyeInfo(pendingMenu.npcInfo) == true) then
                    headerTextureId = GetImageIcon(aceHeaderIconPath);
                else
                    headerTextureId = npcObjectInfo.GetTextureId(
                        pendingMenu.name,
                        (pendingMenu.targetType == 'object') and 'Object' or 'NPC'
                    );
                end
                if (pendingMenu.foreground ~= nil) then
                    pendingMenu.foreground.header.textureId = headerTextureId;
                end
            else
                headerTextureId = GetIcon('Player.png');
            end

            if (headerTextureId ~= nil) then
                imgui.Image(headerTextureId, { iconSize, iconSize }, { 0, 0 }, { 1, 1 });
                imgui.SameLine();
            end
        end

        imgui.TextColored(menu.headerColor, pendingMenu.name or ((pendingMenu.targetType == 'npc') and 'NPC' or 'Player'));
        local sepX, sepY = GetCursorPos();
        if (pendingMenu.foreground ~= nil) then
            pendingMenu.foreground.separatorY = windowY + sepY + 3;
        end
        imgui.Separator();

        if (pendingMenu.targetType == 'npc' or pendingMenu.targetType == 'object') then
            local info = pendingMenu.npcInfo or {};
            local typeText = NormalizeNpcInfoText(info.type or '');
            local infoText = LimitNpcInfoText(info.info or '', menu.npc.maxInfoChars, menu.npc.maxInfoLines);
            local link = BuildNpcLink(pendingMenu.name, info);
            local canUseJobPresets = (pendingMenu.targetType == 'npc' or pendingMenu.targetType == 'object') and jobChange.CanUseTarget(pendingMenu.name, pendingMenu.targetIndex) == true;
            local hideInfoForJobPresets = canUseJobPresets == true and menu.presets ~= nil and menu.presets.hideInfo == true;
            local bodyTextColor = GetReadableTextColor(menu);
            local sectionTextColor = menu.headerColor or npcSectionTextColor;
            local linkTextColor = menu.linkColor or npcLinkTextColor;
            local questLineLinkResolver = (menu.npc.openLink == true) and CreateQuestLineLinkResolver(menu.npc.maxQuestLinks, linkTextColor, info) or nil;
            local bodyWidth = math.max(160, (tonumber(menu.width) or 270) - 24);

            if (hideInfoForJobPresets ~= true and menu.npc.showType == true and typeText ~= '') then
                ReserveTextBlockHeight(QueueForegroundTextBlock(typeText, bodyTextColor, bodyWidth, nil, sectionTextColor, linkTextColor), typeText);
            end

            if (hideInfoForJobPresets ~= true and menu.npc.showInfo == true and infoText ~= '') then
                if (typeText ~= '') then
                    imgui.Separator();
                end

                ReserveTextBlockHeight(QueueForegroundTextBlock(infoText, bodyTextColor, bodyWidth, questLineLinkResolver, sectionTextColor, linkTextColor), infoText);
            end

            if (hideInfoForJobPresets ~= true and menu.npc.openLink == true and link ~= '' and canUseJobPresets ~= true) then
                if (typeText ~= '' or infoText ~= '') then
                    imgui.Separator();
                end

                MenuItem('Open Wiki Page', 'catseye.png', function()
                    OpenUrl(link);
                end, menu);
            end

            if (canUseJobPresets == true) then
                local presetRows = GetPresetRows(menu);
                local hadContentAbove = hideInfoForJobPresets ~= true and (typeText ~= '' or infoText ~= '' or link ~= '');

                if (hadContentAbove == true) then
                    imgui.Separator();
                end

                imgui.TextColored(menu.headerColor or npcSectionTextColor, 'Job change presets');

                if (#presetRows > 0) then
                    for _, row in ipairs(presetRows) do
                        MenuItem(row.label, nil, function()
                            local ok, err = jobChange.ChangeJobs(row.mainJob, row.subJob, row.lockstyleSet);
                            if (ok ~= true) then
                                log.Warn(tostring(err or 'Job preset failed.'));
                            end
                        end, menu, false, row.textureId);
                    end
                else
                    imgui.TextColored(GetReadableTextColor(menu), 'No presets configured in Settings > Quick Menu.');
                end
            end
        elseif (pendingMenu.targetType == 'self') then
            local context = GetPartyContext(pendingMenu.targetIndex);
            local isTown = jobChange.IsTownZone() == true;

            local hasPendingInvite = quickMenu.HasPendingInvite() == true or context.selfSolo == true;

            if (menu.self.acceptInvite == true and hasPendingInvite == true) then
                MenuItem('Accept Invite', 'accept-invite.png', function()
                    QueueCommand('/join');
                    pendingInviteUntil = 0;
                end, menu);
            end

            if (menu.self.declineInvite == true and hasPendingInvite == true) then
                MenuItem('Decline Invite', 'decline-invite.png', function()
                    QueueCommand('/decline');
                    pendingInviteUntil = 0;
                end, menu);
            end

            if (menu.self.leaveParty == true and context.selfSolo ~= true) then
                MenuItem('Leave Party', 'LeaveParty.png', function()
                    QueueCommand('/pcmd leave');
                end, menu);
            end

            if (menu.self.leaveAlliance == true and context.inAlliance == true and context.selfPartyLeader == true) then
                MenuItem('Leave Alliance', 'LeaveAlliance.png', function()
                    QueueCommand('/acmd leave');
                end, menu);
            end

            if (menu.self.cancelPartyRequest == true and HasPendingPartyRequest() == true) then
                MenuItem('Cancel Party Request', 'cancel-party-request.png', function()
                    QueueCommand('/prcmd off');
                    pendingPartyRequestUntil = 0;
                end, menu);
            end

            if (menu.self.aceTownMog == true and jobChange.CanUseAceTownMog() == true) then
                local presetRows = GetPresetRows(menu);

                if (#presetRows > 0) then
                    imgui.TextColored(menu.headerColor or npcSectionTextColor, 'ACE Mog House');

                    for _, row in ipairs(presetRows) do
                        MenuItem(row.label, nil, function()
                            local ok, err = jobChange.ChangeJobsViaAceTownMog(row.mainJob, row.subJob, row.lockstyleSet);
                            if (ok ~= true) then
                                log.Warn(tostring(err or 'ACE town job preset failed.'));
                            end
                        end, menu, false, row.textureId);
                    end

                    imgui.Separator();
                end
            end

            if (isTown ~= true and menu.self.mount == true) then
                if (mounts.IsMounted() == true) then
                    MenuItem('Dismount', 'mount.png', function()
                        QueueCommand('/dismount', 1);
                    end, menu);
                else
                    local selectedMount = tostring(menu.self.selectedMount or 'Chocobo');
                    MenuItem('Mount: ' .. (selectedMount ~= '' and selectedMount or 'None found'), 'mount.png', function()
                        local mountName = selectedMount == 'Random' and mounts.GetRandomChoice() or selectedMount;

                        if (mountName ~= nil and tostring(mountName or '') ~= '') then
                            QueueCommand('/mount "' .. tostring(mountName) .. '"', 1);
                        end
                    end, menu);
                end
            end

            if (isTown ~= true and menu.self.ignoreTrust == true) then
                SelfToggleMenuItem('ignoreTrust', 'Ignore Other Trusts', 'ignore-trust-on.png', menu.self.ignoreTrustState == true, '/ignoretrust', function(value)
                    menu.self.ignoreTrustState = value == true;
                end, menu, 'ignore-trust-off.png');
            end

            if (isTown ~= true and menu.self.hideTrust == true) then
                SelfToggleMenuItem('hideTrust', 'Hide Other Trusts', 'hide-other-trusts-on.png', menu.self.hideTrustState == true, '/hidetrust', function(value)
                    menu.self.hideTrustState = value == true;
                end, menu, 'hide-other-trusts-off.png');
            end

            if (isTown ~= true and menu.self.emoteTrust == true) then
                SelfToggleMenuItem('emoteTrust', 'Emote Trust', 'emote-trusts-on.png', menu.self.emoteTrustState == true, '/emotetrust', function(value)
                    menu.self.emoteTrustState = value == true;
                end, menu, 'emote-trusts-off.png');
            end
        elseif (pendingMenu.targetType == 'trust') then
            if (pendingMenu.trustIsMine == true) then
                if (menu.trust.dismiss == true) then
                    MenuItem('Dismiss This Trust', 'DismissTrust.png', function()
                        QueueCommand('/retr "' .. tostring(pendingMenu.name or '') .. '"');
                    end, menu);
                end

                if (menu.trust.dismissAll == true) then
                    MenuItem('Dismiss All Trusts', 'DismissAllTrusts.png', function()
                        if (menu.trust.confirmDismissAll == true) then
                            RequestConfirm('Dismiss All Trusts', '/retr all');
                        else
                            QueueCommand('/retr all');
                        end
                    end, menu);
                end
            else
                if (menu.self.ignoreTrust == true) then
                    SelfToggleMenuItem('ignoreTrust', 'Ignore Other Trusts', 'ignore-trust-on.png', menu.self.ignoreTrustState == true, '/ignoretrust', function(value)
                        menu.self.ignoreTrustState = value == true;
                    end, menu, 'ignore-trust-off.png');
                end

                if (menu.self.hideTrust == true) then
                    SelfToggleMenuItem('hideTrust', 'Hide Other Trusts', 'hide-other-trusts-on.png', menu.self.hideTrustState == true, '/hidetrust', function(value)
                        menu.self.hideTrustState = value == true;
                    end, menu, 'hide-other-trusts-off.png');
                end
            end
        else
            local context = GetPartyContext(pendingMenu.targetIndex);
            local blacklistPlayer = {
                name = pendingMenu.name,
                serverId = pendingMenu.serverId,
            };

            if (menu.pc.blacklist == true and context.targetIsSelf ~= true) then
                if (playerBlacklist.IsListed(blacklistPlayer) == true) then
                    MenuItem('Remove from blacklist', 'blacklist.png', function()
                        local targetName = tostring(blacklistPlayer.name or '');
                        RequestConfirm('Remove ' .. targetName .. ' from blacklist', function()
                            if (playerBlacklist.RemovePlayer(blacklistPlayer) == true) then
                                QueueCommand('/blacklist delete ' .. QuoteCommandName(targetName));
                                log.Info('Removed ' .. targetName .. ' from LibraPlates blacklist.');
                            else
                                log.Warn(targetName .. ' was not in the LibraPlates blacklist.');
                            end
                        end, {
                            confirmLabel = 'Remove',
                        });
                    end, menu);
                else
                    MenuItem('Add to blacklist', 'blacklist.png', function()
                        local targetName = tostring(blacklistPlayer.name or '');
                        RequestConfirm('Blacklist ' .. targetName, function(reason)
                            local ok, err = playerBlacklist.AddPlayer(blacklistPlayer, reason, 'quick-menu');

                            if (ok == true) then
                                QueueCommand('/blacklist add ' .. QuoteCommandName(targetName));
                                log.Info('Added ' .. targetName .. ' to LibraPlates blacklist.');
                            else
                                log.Warn(tostring(err or 'Failed to add player to LibraPlates blacklist.'));
                            end
                        end, {
                            reasonEnabled = true,
                            reasonLabel = 'Reason (optional)',
                            confirmLabel = 'Add',
                        });
                    end, menu);
                end
            end

            if (menu.pc.examine == true) then
                MenuItem('Examine', 'Examine.png', function()
                    QueueCommand('/check "' .. tostring(pendingMenu.name or '') .. '"');
                end, menu);
            end

            if (menu.pc.catseyeProfile == true) then
                MenuItem('Open Catseye Profile', 'catseye.png', function()
                    if (pendingMenu.serverId ~= nil and tonumber(pendingMenu.serverId) ~= 0) then
                        OpenUrl('https://catseyexi.com/char/' .. tostring(pendingMenu.serverId));
                    end
                end, menu);
            end

            if (menu.pc.follow == true) then
                MenuItem('Follow', 'Follow.png', function()
                    QueueCommand('/follow "' .. tostring(pendingMenu.name or '') .. '"');
                end, menu);
            end

            if (menu.pc.inviteToParty == true) then
                if (context.targetInAlliance ~= true and (context.selfSolo == true or context.selfPartyLeader == true)) then
                    MenuItem('Invite to Party', 'InviteToParty.png', function()
                        QueueCommand('/pcmd add "' .. tostring(pendingMenu.name or '') .. '"');
                    end, menu);
                end
            end

            if (menu.pc.requestJoinParty == true) then
                if (context.selfSolo == true and context.targetInAlliance ~= true) then
                    MenuItem('Request to Join Party', 'request-to-join-party.png', function()
                        QueueCommand('/prcmd add "' .. tostring(pendingMenu.name or '') .. '"');
                        pendingPartyRequestUntil = os.clock() + 60;
                    end, menu);
                end
            end

            if (menu.pc.invitePartyToAlliance == true) then
                if (context.targetInAlliance ~= true and context.targetInMyParty ~= true and (context.selfPartyLeader == true or context.selfInParty == true)) then
                    MenuItem('Invite Party to Alliance', 'InvitePartyToAlliance.png', function()
                        QueueCommand('/acmd add "' .. tostring(pendingMenu.name or '') .. '"');
                    end, menu);
                end
            end

            if (menu.pc.passPartyLeader == true) then
                if (context.targetInMyParty == true and context.targetIsSelf ~= true and (context.selfPartyLeader == true or context.selfInParty == true)) then
                    MenuItem('Pass Party Leader', 'PassPartyLeader.png', function()
                        QueueCommand('/pcmd leader "' .. tostring(pendingMenu.name or '') .. '"');
                    end, menu);
                end
            end

            if (menu.pc.passAllianceLeader == true) then
                if (context.selfAllianceLeader == true and context.targetPartyLeader == true) then
                    MenuItem('Pass Alliance Leader', 'PassAllianceLeader.png', function()
                        QueueCommand('/acmd leader "' .. tostring(pendingMenu.name or '') .. '"');
                    end, menu);
                end
            end
        end

        local windowWidth, windowHeight = GetWindowSize();
        if (pendingMenu ~= nil and pendingMenu.foreground ~= nil) then
            pendingMenu.foreground.width = (windowWidth > 0) and windowWidth or (tonumber(menu.width) or 270);
            pendingMenu.foreground.height = (windowHeight > 0) and windowHeight or pendingMenu.foreground.height;
        end

        imgui.EndPopup();
    else
        pendingMenu = nil;
    end

    if (varCount > 0 and imgui.PopStyleVar ~= nil) then
        imgui.PopStyleVar(varCount);
    end

    if (colorCount > 0 and imgui.PopStyleColor ~= nil) then
        imgui.PopStyleColor(colorCount);
    end

    DrawForegroundMenu(menu);
    DrawConfirm();
end

return quickMenu;
