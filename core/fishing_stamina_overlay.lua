local imgui = require('imgui');
local state = require('core.state');
local fishing = require('core.fishing');
local globalDefaults = require('config.global');
local textureLoader = require('core.texture_loader');
local backgroundTextures = require('core.background_textures');

local overlay = {};
local lastSaved = nil;
local previewDrag = nil;
local staminaPreviewDrag = nil;
local hudOpen = false;
local closedRevision = -1;
local previousHasHudData = false;
local lastPreviewHudEnabled = false;
local uiIconTextureIds = {};
local lastReadyBarFishClock = 0;
local hudMinWidth = 440;
local hudMinHeight = 120;
local hudDefaultHeight = 220;
local hudAccent = { 0.20, 0.65, 0.67, 1.0 };
local hudAccentHovered = { 0.25, 0.76, 0.78, 1.0 };
local hudAccentActive = { 0.16, 0.55, 0.57, 1.0 };

local function Clamp(value, minValue, maxValue, fallback)
    value = tonumber(value) or fallback;
    return math.max(minValue, math.min(maxValue, value));
end

local function ColorToU32(color, fallback)
    color = color or fallback or { 1.0, 1.0, 1.0, 1.0 };

    local r = Clamp(color[1], 0, 1, fallback ~= nil and fallback[1] or 1);
    local g = Clamp(color[2], 0, 1, fallback ~= nil and fallback[2] or 1);
    local b = Clamp(color[3], 0, 1, fallback ~= nil and fallback[3] or 1);
    local a = Clamp(color[4], 0, 1, fallback ~= nil and fallback[4] or 1);

    return math.floor(a * 255) * 0x1000000
        + math.floor(b * 255) * 0x10000
        + math.floor(g * 255) * 0x100
        + math.floor(r * 255);
end

local rankColors = {
    Amateur = { 0.61, 0.64, 0.69, 1.0 },
    Recruit = { 0.88, 0.45, 0.75, 1.0 },
    Initiate = { 0.45, 0.76, 0.88, 1.0 },
    Novice = { 0.06, 0.72, 0.51, 1.0 },
    Apprentice = { 0.24, 0.36, 0.75, 1.0 },
    Journeyman = { 0.39, 0.40, 0.95, 1.0 },
    Craftsman = { 0.55, 0.36, 0.96, 1.0 },
    Artisan = { 1.0, 0.84, 0.04, 1.0 },
    Adept = { 0.96, 0.62, 0.04, 1.0 },
    Veteran = { 0.96, 0.62, 0.04, 1.0 },
    Expert = { 0.96, 0.62, 0.04, 1.0 },
};

local optionColors = {
    owned = { 1.0, 1.0, 1.0, 1.0 },
    suggestedOwned = { 0.38, 0.95, 0.56, 1.0 },
    missingSuggested = { 0.54, 0.56, 0.60, 1.0 },
};

local function GetSettings()
    local global = state.GetGlobalSettings(globalDefaults);
    return global.fishing or globalDefaults.fishing or {};
end

local function GetUiIconTextureId(fileName)
    fileName = tostring(fileName or '');
    if (fileName == '') then
        return nil;
    end

    if (uiIconTextureIds[fileName] ~= nil) then
        return uiIconTextureIds[fileName];
    end

    local path = addon.path .. '\\assets\\images\\ui-icons\\' .. fileName;
    uiIconTextureIds[fileName] = textureLoader.ToTextureId(textureLoader.Load(path));
    return uiIconTextureIds[fileName];
end

local function GetSelfGameMode()
    local party = AshitaCore:GetMemoryManager():GetParty();
    local selfIndex = nil;

    pcall(function()
        selfIndex = party ~= nil and party:GetMemberTargetIndex(0) or nil;
    end);

    if (selfIndex == nil or tonumber(selfIndex) == 0) then
        return '';
    end

    return require('core.game_mode').Resolve(tonumber(selfIndex), false);
end

local function ReadVec2(valueA, valueB)
    if (type(valueA) == 'table') then
        return tonumber(valueA.x or valueA[1]) or 0, tonumber(valueA.y or valueA[2]) or 0;
    end

    return tonumber(valueA) or 0, tonumber(valueB) or 0;
end

local function SaveHudWindow(settings)
    if (imgui.GetWindowPos == nil or imgui.GetWindowSize == nil) then
        return;
    end

    local x, y = ReadVec2(imgui.GetWindowPos());
    local w, h = ReadVec2(imgui.GetWindowSize());
    x = math.floor(x + 0.5);
    y = math.floor(y + 0.5);
    w = math.floor(math.max(hudMinWidth, w) + 0.5);
    h = math.floor(math.max(hudMinHeight, h) + 0.5);

    local signature = table.concat({ x, y, w, h }, ':');
    if (lastSaved == signature) then
        return;
    end

    settings.hudX = x;
    settings.hudY = y;
    settings.hudWidth = w;
    settings.hudHeight = h;
    state.Save();
    lastSaved = signature;
end

local function SaveHudPosition(settings, x, y)
    x = math.floor((tonumber(x) or tonumber(settings.hudX) or 24) + 0.5);
    y = math.floor((tonumber(y) or tonumber(settings.hudY) or 54) + 0.5);

    local signature = table.concat({ x, y, tonumber(settings.hudWidth) or hudMinWidth, tonumber(settings.hudHeight) or hudDefaultHeight }, ':');
    if (lastSaved == signature) then
        return;
    end

    settings.hudX = x;
    settings.hudY = y;
    state.Save();
    lastSaved = signature;
end

local function SaveStaminaPosition(settings, x, y)
    x = math.floor((tonumber(x) or tonumber(settings.staminaBarScreenX) or 24) + 0.5);
    y = math.floor((tonumber(y) or tonumber(settings.staminaBarScreenY) or 190) + 0.5);

    local signature = table.concat({ 'stamina', x, y }, ':');
    if (lastSaved == signature) then
        return;
    end

    settings.staminaBarScreenX = x;
    settings.staminaBarScreenY = y;
    state.Save();
    lastSaved = signature;
end

local function ReadMousePos()
    if (imgui.GetMousePos == nil) then
        return nil, nil;
    end

    return ReadVec2(imgui.GetMousePos());
end

local function ReadMouseDragDelta()
    if (imgui.GetMouseDragDelta == nil) then
        return 0, 0;
    end

    return ReadVec2(imgui.GetMouseDragDelta(0));
end

local function DrawPreviewFrame(drawList, x, y, w, h)
    if (drawList == nil or imgui.GetColorU32 == nil) then
        return;
    end

    local handleSize = 18;
    local fillColor = imgui.GetColorU32({ hudAccent[1], hudAccent[2], hudAccent[3], 0.16 });
    local borderColor = imgui.GetColorU32(hudAccent);
    local handleColor = imgui.GetColorU32({ hudAccentHovered[1], hudAccentHovered[2], hudAccentHovered[3], 0.86 });

    if (drawList.AddRectFilled ~= nil) then
        drawList:AddRectFilled({ x, y }, { x + w, y + h }, fillColor);
    end

    if (drawList.AddRect ~= nil) then
        drawList:AddRect({ x, y }, { x + w, y + h }, borderColor, 0, 0, 4);
    end

    if (drawList.AddTriangleFilled ~= nil) then
        drawList:AddTriangleFilled({ x + w, y + h - handleSize }, { x + w, y + h }, { x + w - handleSize, y + h }, handleColor);
        drawList:AddTriangle({ x + w, y + h - handleSize }, { x + w, y + h }, { x + w - handleSize, y + h }, borderColor, 2);
    elseif (drawList.AddRectFilled ~= nil and drawList.AddRect ~= nil) then
        drawList:AddRectFilled({ x + w - handleSize, y + h - handleSize }, { x + w, y + h }, handleColor);
        drawList:AddRect({ x + w - handleSize, y + h - handleSize }, { x + w, y + h }, borderColor, 0, 0, 2);
    end
end

local function HandleUnlockedHudInteraction(settings, x, y, w, h)
    if (
        settings.hudLocked ~= false or
        imgui.IsMouseClicked == nil or
        imgui.IsMouseDown == nil
    ) then
        return;
    end

    local mouseX, mouseY = ReadMousePos();
    if (mouseX == nil or mouseY == nil) then
        previewDrag = nil;
        return;
    end

    local handleSize = 22;
    if (imgui.IsMouseClicked(0) == true) then
        local inRect = mouseX >= x and mouseX <= x + w and mouseY >= y and mouseY <= y + h;
        local inButtons = mouseX >= x + w - 54 and mouseX <= x + w and mouseY >= y and mouseY <= y + 30;
        local inResize = mouseX >= x + w - handleSize and mouseX <= x + w and mouseY >= y + h - handleSize and mouseY <= y + h;

        if (inRect == true and inButtons ~= true) then
            previewDrag = {
                mode = inResize == true and 'resize' or 'move',
                x = x,
                y = y,
                w = w,
                h = h,
            };

            if (imgui.ResetMouseDragDelta ~= nil) then
                imgui.ResetMouseDragDelta(0);
            end
        end
    end

    if (imgui.IsMouseDown(0) ~= true) then
        previewDrag = nil;
        return;
    end

    if (previewDrag == nil) then
        return;
    end

    local dx, dy = ReadMouseDragDelta();
    if (math.abs(dx) < 0.5 and math.abs(dy) < 0.5) then
        return;
    end

    if (previewDrag.mode == 'resize') then
        settings.hudWidth = math.max(hudMinWidth, math.floor((previewDrag.w + dx) + 0.5));
        settings.hudHeight = math.max(hudMinHeight, math.floor((previewDrag.h + dy) + 0.5));
        state.Save();
    else
        SaveHudPosition(settings, previewDrag.x + dx, previewDrag.y + dy);
    end
end

local function DrawStaminaPreviewFrame(drawList, x, y, w, h)
    if (drawList == nil or imgui.GetColorU32 == nil) then
        return;
    end

    local handleSize = 16;
    local fillColor = imgui.GetColorU32({ 1.0, 0.84, 0.04, 0.10 });
    local borderColor = imgui.GetColorU32({ 1.0, 0.84, 0.04, 1.0 });
    local handleColor = imgui.GetColorU32({ 1.0, 0.84, 0.04, 0.82 });

    if (drawList.AddRectFilled ~= nil) then
        drawList:AddRectFilled({ x, y }, { x + w, y + h }, fillColor);
    end

    if (drawList.AddRect ~= nil) then
        drawList:AddRect({ x, y }, { x + w, y + h }, borderColor, 0, 0, 3);
    end

    if (drawList.AddTriangleFilled ~= nil) then
        drawList:AddTriangleFilled({ x + w, y + h - handleSize }, { x + w, y + h }, { x + w - handleSize, y + h }, handleColor);
        drawList:AddTriangle({ x + w, y + h - handleSize }, { x + w, y + h }, { x + w - handleSize, y + h }, borderColor, 2);
    elseif (drawList.AddRectFilled ~= nil and drawList.AddRect ~= nil) then
        drawList:AddRectFilled({ x + w - handleSize, y + h - handleSize }, { x + w, y + h }, handleColor);
        drawList:AddRect({ x + w - handleSize, y + h - handleSize }, { x + w, y + h }, borderColor, 0, 0, 2);
    end
end

local function HandleStaminaPreviewDrag(settings, barX, barY, frameX, frameY, frameW, frameH)
    if (
        settings.previewStaminaBar ~= true or
        imgui.IsMouseClicked == nil or
        imgui.IsMouseDown == nil
    ) then
        staminaPreviewDrag = nil;
        return;
    end

    local mouseX, mouseY = ReadMousePos();
    if (mouseX == nil or mouseY == nil) then
        staminaPreviewDrag = nil;
        return;
    end

    if (imgui.IsMouseClicked(0) == true) then
        local inRect = mouseX >= frameX and mouseX <= frameX + frameW and mouseY >= frameY and mouseY <= frameY + frameH;
        if (inRect == true) then
            staminaPreviewDrag = {
                x = barX,
                y = barY,
            };

            if (imgui.ResetMouseDragDelta ~= nil) then
                imgui.ResetMouseDragDelta(0);
            end
        end
    end

    if (imgui.IsMouseDown(0) ~= true) then
        staminaPreviewDrag = nil;
        return;
    end

    if (staminaPreviewDrag == nil) then
        return;
    end

    local dx, dy = ReadMouseDragDelta();
    if (math.abs(dx) < 0.5 and math.abs(dy) < 0.5) then
        return;
    end

    SaveStaminaPosition(settings, staminaPreviewDrag.x + dx, staminaPreviewDrag.y + dy);
end

local function AddText(drawList, x, y, color, text)
    if (drawList == nil or drawList.AddText == nil or text == nil or text == '') then
        return;
    end

    local shadow = 0xCC000000;
    drawList:AddText({ x + 1, y + 1 }, shadow, tostring(text));
    drawList:AddText({ x, y }, color, tostring(text));
end

local function CleanName(value)
    return tostring(value or ''):gsub('\170', ''):gsub('%c', ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local function NamesEqual(left, right)
    return CleanName(left):lower() == CleanName(right):lower();
end

local function IsMouseClickedInRect(x, y, w, h)
    if (imgui.IsMouseClicked == nil) then
        return false;
    end

    local mouseX, mouseY = ReadMousePos();
    if (mouseX == nil or mouseY == nil) then
        return false;
    end

    return mouseX >= x and mouseX <= x + w and mouseY >= y and mouseY <= y + h and imgui.IsMouseClicked(0) == true;
end

local function ShouldRenderHud(settings, stamina)
    if (settings.previewHud == true and state.GetConfigOpen ~= nil and state.GetConfigOpen() ~= true) then
        settings.previewHud = false;
        hudOpen = false;
        lastPreviewHudEnabled = false;
        previousHasHudData = stamina ~= nil or (fishing.HasHudData ~= nil and fishing.HasHudData() == true);
        closedRevision = fishing.GetHudRevision ~= nil and fishing.GetHudRevision() or closedRevision;
        state.Save();
        return false;
    end

    if (settings.previewHud == true) then
        hudOpen = true;
        lastPreviewHudEnabled = true;
        previousHasHudData = stamina ~= nil or (fishing.HasHudData ~= nil and fishing.HasHudData() == true);
        return true;
    end

    if (lastPreviewHudEnabled == true) then
        hudOpen = false;
        lastPreviewHudEnabled = false;
        previousHasHudData = stamina ~= nil or (fishing.HasHudData ~= nil and fishing.HasHudData() == true);
        closedRevision = fishing.GetHudRevision ~= nil and fishing.GetHudRevision() or closedRevision;
        return false;
    end

    local revision = fishing.GetHudRevision ~= nil and fishing.GetHudRevision() or 0;
    local hasHudData = stamina ~= nil or (fishing.HasHudData ~= nil and fishing.HasHudData() == true);

    if (hasHudData == true and previousHasHudData ~= true) then
        hudOpen = true;
    elseif (revision > closedRevision and hasHudData == true) then
        hudOpen = true;
    end

    previousHasHudData = hasHudData == true;

    return hudOpen == true;
end

local function HandleCloseInteraction(settings, x, y, w, revision)
    if (
        imgui.IsMouseClicked == nil
    ) then
        return;
    end

    local mouseX, mouseY = ReadMousePos();
    if (mouseX == nil or mouseY == nil) then
        return;
    end

    local size = 18;
    local closeX = x + w - size - 7;
    local closeY = y + 7;

    if (
        mouseX >= closeX and mouseX <= closeX + size and
        mouseY >= closeY and mouseY <= closeY + size and
        imgui.IsMouseClicked(0) == true
    ) then
        hudOpen = false;
        if (settings.previewHud == true) then
            settings.previewHud = false;
            state.Save();
        end
        closedRevision = tonumber(revision) or closedRevision;
    end
end

local function DrawCloseButton(drawList, x, y, w, color)
    if (drawList == nil or drawList.AddText == nil) then
        return;
    end

    AddText(drawList, x + w - 20, y + 8, color, 'x');
end

local function HandleLockInteraction(settings, x, y, w)
    if (imgui.IsMouseClicked == nil) then
        return;
    end

    local size = 18;
    local iconX = x + w - 46;
    local iconY = y + 7;

    if (IsMouseClickedInRect(iconX, iconY, size, size) == true) then
        settings.hudLocked = settings.hudLocked == false;
        state.Save();
    end
end

local function DrawLockButton(drawList, settings, x, y, w, color)
    local size = 18;
    local iconX = x + w - 46;
    local iconY = y + 7;
    local fileName = settings.hudLocked == false and 'unlocked (1).png' or 'locked.png';
    local textureId = GetUiIconTextureId(fileName);

    if (textureId ~= nil and drawList ~= nil and drawList.AddImage ~= nil) then
        drawList:AddImage(textureId, { iconX, iconY }, { iconX + size, iconY + size }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
        return;
    end

    AddText(drawList, iconX + 4, iconY + 2, color, settings.hudLocked == false and 'U' or 'L');
end

local function AddInfoRow(drawList, x, y, labelColor, valueColor, label, value)
    AddText(drawList, x, y, labelColor, tostring(label or ''));
    AddText(drawList, x + 112, y, valueColor, tostring(value or '-'));
end

local function AddVentureRows(drawList, x, y, labelColor, valueColor, mutedColor, venture)
    if (type(venture) ~= 'table') then
        AddInfoRow(drawList, x, y, labelColor, mutedColor, 'Venture', venture or 'Not loaded');
        return y + 16;
    end

    if (venture.loaded ~= true) then
        AddInfoRow(drawList, x, y, labelColor, mutedColor, 'Venture', venture.text or 'Not loaded');
        return y + 16;
    end

    AddInfoRow(drawList, x, y, labelColor, valueColor, 'Venture', 'Fishing');
    y = y + 16;

    AddInfoRow(drawList, x, y, labelColor, valueColor, 'Low', venture.low ~= '' and venture.low or '-');
    y = y + 16;
    AddInfoRow(drawList, x, y, labelColor, valueColor, 'Mid', venture.mid ~= '' and venture.mid or '-');
    y = y + 16;
    AddInfoRow(drawList, x, y, labelColor, valueColor, 'High', venture.high ~= '' and venture.high or '-');
    y = y + 16;

    return y;
end

local function GetTextWidth(text)
    if (imgui.CalcTextSize == nil) then
        return #tostring(text or '') * 8;
    end

    local width = 0;
    pcall(function()
        width = ReadVec2(imgui.CalcTextSize(tostring(text or '')));
    end);

    return tonumber(width) or (#tostring(text or '') * 8);
end

local function AddSkillRow(drawList, x, y, labelColor, valueColor, rankColor, label, prefix, rank)
    label = tostring(label or '');
    AddText(drawList, x, y, labelColor, label);

    local valueX = x + math.max(122, GetTextWidth(label) + 10);
    local prefixText = tostring(prefix or '');
    AddText(drawList, valueX, y, valueColor, prefixText);
    AddText(drawList, valueX + GetTextWidth(prefixText), y, rankColor or valueColor, tostring(rank or ''));
end

local function AddTaggedInfoRow(drawList, x, y, labelColor, valueColor, okColor, badColor, label, value, match)
    AddText(drawList, x, y, labelColor, tostring(label or ''));

    local color = valueColor;
    if (match == true) then
        color = okColor;
    elseif (match == false) then
        color = badColor;
    end

    AddText(drawList, x + 112, y, color, tostring(value or '-'));
end

local function GetOptionDisplay(option, fallback)
    if (type(option) ~= 'table') then
        return tostring(fallback or option or '-');
    end

    local name = tostring((type(option) == 'table' and option.name) or fallback or '-');
    if (tonumber(option.count) ~= nil and tonumber(option.count) > 1) then
        return name .. ' x' .. tostring(math.floor(tonumber(option.count) or 0));
    end

    return name;
end

local function GetOptionColor(option)
    if (type(option) ~= 'table') then
        return optionColors.owned;
    end

    if (option.owned == true and option.suggested == true) then
        return optionColors.suggestedOwned;
    end

    if (option.owned ~= true and option.suggested == true) then
        return optionColors.missingSuggested;
    end

    return optionColors.owned;
end

local function PushTextColor(color)
    if (imgui.PushStyleColor == nil or _G.ImGuiCol_Text == nil) then
        return false;
    end

    local ok = pcall(function()
        imgui.PushStyleColor(_G.ImGuiCol_Text, color);
    end);

    return ok == true;
end

local function PushHudComboStyle()
    if (imgui.PushStyleColor == nil) then
        return 0;
    end

    local pushed = 0;
    local function push(colorId, color)
        if (colorId == nil) then
            return;
        end

        local ok = pcall(function()
            imgui.PushStyleColor(colorId, color);
        end);
        if (ok == true) then
            pushed = pushed + 1;
        end
    end

    push(_G.ImGuiCol_Button, { hudAccent[1], hudAccent[2], hudAccent[3], 0.82 });
    push(_G.ImGuiCol_ButtonHovered, { hudAccentHovered[1], hudAccentHovered[2], hudAccentHovered[3], 0.92 });
    push(_G.ImGuiCol_ButtonActive, hudAccentActive);
    push(_G.ImGuiCol_Header, { hudAccent[1], hudAccent[2], hudAccent[3], 0.42 });
    push(_G.ImGuiCol_HeaderHovered, { hudAccentHovered[1], hudAccentHovered[2], hudAccentHovered[3], 0.58 });
    push(_G.ImGuiCol_HeaderActive, { hudAccentActive[1], hudAccentActive[2], hudAccentActive[3], 0.74 });

    return pushed;
end

local function PopHudComboStyle(pushed)
    pushed = tonumber(pushed) or 0;
    if (pushed > 0 and imgui.PopStyleColor ~= nil) then
        pcall(function()
            imgui.PopStyleColor(pushed);
        end);
    end
end

local function AddRecommendationCombo(drawList, x, y, width, labelColor, valueColor, label, value, match, items, equipped, id, equipSlot)
    if (
        imgui.BeginCombo == nil or
        imgui.Selectable == nil or
        imgui.SetCursorScreenPos == nil or
        type(items) ~= 'table' or
        #items == 0
    ) then
        AddTaggedInfoRow(drawList, x, y, labelColor, valueColor, valueColor, valueColor, label, value, match);
        return;
    end

    AddText(drawList, x, y, labelColor, tostring(label or ''));

    local comboX = x + 112;
    local comboY = y - 4;
    local comboWidth = math.max(120, width - 112);
    imgui.SetCursorScreenPos({ comboX, comboY });
    if (imgui.PushItemWidth ~= nil) then
        imgui.PushItemWidth(comboWidth);
    end

    local pushedComboStyle = PushHudComboStyle();
    if (imgui.BeginCombo('##fishing_' .. tostring(id or label), tostring(value or '-')) == true) then
        for _, option in ipairs(items) do
            local optionName = type(option) == 'table' and tostring(option.name or '') or tostring(option or '');
            local itemMatch = (type(option) == 'table' and option.equipped == true) or NamesEqual(optionName, equipped) == true;
            local itemLabel = GetOptionDisplay(option, optionName);
            local pushedColor = PushTextColor(GetOptionColor(option));

            if (imgui.Selectable(itemLabel, itemMatch) == true) then
                if (itemMatch ~= true and type(option) == 'table' and option.owned == true and fishing.EquipFishingItem ~= nil) then
                    fishing.EquipFishingItem(equipSlot, option.itemName or optionName);
                end
            end

            if (itemMatch == true and imgui.SetItemDefaultFocus ~= nil) then
                imgui.SetItemDefaultFocus();
            end

            if (pushedColor == true and imgui.PopStyleColor ~= nil) then
                imgui.PopStyleColor(1);
            end
        end

        imgui.EndCombo();
    end
    PopHudComboStyle(pushedComboStyle);

    if (imgui.PopItemWidth ~= nil) then
        imgui.PopItemWidth();
    end
end

local function GetTargetDisplay(option, fallback)
    if (type(option) ~= 'table') then
        return tostring(fallback or option or '-');
    end

    local name = tostring((type(option) == 'table' and option.name) or fallback or '-');
    if (tonumber(option.level) ~= nil and tonumber(option.level) > 0) then
        return name .. ' Lv.' .. tostring(math.floor(tonumber(option.level) or 0));
    end

    return name;
end

local function AddTargetCombo(drawList, x, y, width, labelColor, valueColor, label, value, items)
    if (
        imgui.BeginCombo == nil or
        imgui.Selectable == nil or
        imgui.SetCursorScreenPos == nil or
        type(items) ~= 'table' or
        #items == 0
    ) then
        AddInfoRow(drawList, x, y, labelColor, valueColor, label, value);
        return;
    end

    AddText(drawList, x, y, labelColor, tostring(label or ''));

    local comboX = x + 112;
    local comboY = y - 4;
    local comboWidth = math.max(120, width - 112);
    imgui.SetCursorScreenPos({ comboX, comboY });
    if (imgui.PushItemWidth ~= nil) then
        imgui.PushItemWidth(comboWidth);
    end

    local pushedComboStyle = PushHudComboStyle();
    if (imgui.BeginCombo('##fishing_target', tostring(value or 'Any')) == true) then
        if (imgui.Selectable('Any', tostring(value or 'Any') == 'Any') == true and fishing.SetTargetFish ~= nil) then
            fishing.SetTargetFish(nil);
        end

        for _, option in ipairs(items) do
            local optionName = type(option) == 'table' and tostring(option.name or '') or tostring(option or '');
            local selected = (type(option) == 'table' and option.selected == true) or NamesEqual(optionName, value) == true;
            if (imgui.Selectable(GetTargetDisplay(option, optionName), selected) == true and fishing.SetTargetFish ~= nil) then
                fishing.SetTargetFish(optionName, type(option) == 'table' and option.id or nil);
            end

            if (selected == true and imgui.SetItemDefaultFocus ~= nil) then
                imgui.SetItemDefaultFocus();
            end
        end

        imgui.EndCombo();
    end
    PopHudComboStyle(pushedComboStyle);

    if (imgui.PopItemWidth ~= nil) then
        imgui.PopItemWidth();
    end
end

local function FormatBait(info)
    local bait = tostring(info ~= nil and info.bait or 'None');
    local count = tonumber(info ~= nil and info.baitCount);

    if (bait == '' or bait == 'None') then
        return 'None';
    end

    if (count ~= nil) then
        return bait .. ' x' .. tostring(count);
    end

    return bait;
end

local function GetSkillDisplay(info)
    local skill = info ~= nil and info.skill or nil;
    if (skill == nil or tonumber(skill.level) == nil) then
        return nil;
    end

    local rank = tostring(skill.rank or 'Amateur');
    return {
        prefix = string.format('%d/%d - Rank: ', math.floor(tonumber(skill.level) or 0), tonumber(skill.cap) or 110),
        rank = rank,
        color = ColorToU32(rankColors[rank], rankColors[rank] or { 1.0, 1.0, 1.0, 1.0 }),
    };
end

local function GetHudStatus(info)
    return tostring(info ~= nil and info.status or 'Ready');
end

local function TryReadyBarFish(settings, status, x, y, width, height)
    if (settings.enableReadyBarFish ~= true or status ~= 'Ready') then
        return;
    end

    if (IsMouseClickedInRect(x, y, width, height) ~= true) then
        return;
    end

    local now = os.clock();
    if ((now - (tonumber(lastReadyBarFishClock) or 0)) < 1.0) then
        return;
    end

    lastReadyBarFishClock = now;

    if (fishing.MarkFishCommandAttempt ~= nil) then
        fishing.MarkFishCommandAttempt(4);
    end

    pcall(function()
        AshitaCore:GetChatManager():QueueCommand(1, '/fish');
    end);

    if (fishing.MarkFishCommandQueued ~= nil) then
        fishing.MarkFishCommandQueued('ready-bar', status);
    end
end

local function DrawHudStatusBar(drawList, x, y, width, height, info, textColor, settings)
    if (drawList == nil or drawList.AddRectFilled == nil) then
        AddText(drawList, x, y, textColor, GetHudStatus(info));
        return;
    end

    local status = GetHudStatus(info);
    local cooldown = info ~= nil and info.cooldown or nil;
    local progress = 1;
    local fillColor = { 0.20, 0.72, 0.38, 0.92 };

    if (status == 'Fishing') then
        fillColor = { 0.20, 0.55, 0.95, 0.92 };
    elseif (status == 'Waiting') then
        progress = tonumber(cooldown ~= nil and cooldown.progress) or 0;
        fillColor = { 0.95, 0.68, 0.18, 0.92 };
    end

    progress = math.max(0, math.min(1, progress));

    local bg = ColorToU32({ 0.05, 0.06, 0.08, 0.88 }, { 0.05, 0.06, 0.08, 0.88 });
    local fill = ColorToU32(fillColor, fillColor);
    local border = ColorToU32({ 0.0, 0.0, 0.0, 1.0 }, { 0.0, 0.0, 0.0, 1.0 });
    local fillWidth = math.max(0, width * progress);

    drawList:AddRectFilled({ x, y }, { x + width, y + height }, bg);
    if (fillWidth > 0) then
        drawList:AddRectFilled({ x, y }, { x + fillWidth, y + height }, fill);
    end
    if (drawList.AddRect ~= nil) then
        drawList:AddRect({ x, y }, { x + width, y + height }, border, 0, 0, 1);
    end

    local label = status;
    if (status == 'Waiting' and cooldown ~= nil and cooldown.active == true and tonumber(cooldown.remaining) ~= nil) then
        label = label .. ' ' .. string.format('%.1fs', math.max(0, tonumber(cooldown.remaining) or 0));
    end

    TryReadyBarFish(settings or {}, status, x, y, width, height);
    AddText(drawList, x + 8, y + math.max(2, math.floor((height - 14) / 2)), textColor, label);

    if (status == 'Ready' and settings ~= nil and settings.enableReadyBarFish == true) then
        local actionText = 'Click to fish';
        AddText(drawList, x + math.max(8, math.floor((width - GetTextWidth(actionText)) * 0.5)), y + math.max(2, math.floor((height - 14) / 2)), textColor, actionText);
    end
end

local function DrawStandaloneStaminaBar(settings, stamina)
    if (stamina == nil or imgui.GetForegroundDrawList == nil) then
        return;
    end

    local drawList = imgui.GetForegroundDrawList();
    if (drawList == nil or drawList.AddRectFilled == nil) then
        return;
    end

    local x = tonumber(settings.staminaBarScreenX) or ((tonumber(settings.hudX) or 24) + 14);
    local y = tonumber(settings.staminaBarScreenY) or ((tonumber(settings.hudY) or 54) + (tonumber(settings.hudHeight) or 124) + 8);
    local width = math.max(120, tonumber(settings.staminaBarWidth) or 160);
    local height = math.max(6, tonumber(settings.staminaBarHeight) or 10);
    local progress = math.max(0, math.min(100, tonumber(stamina.progress) or 0)) / 100;
    local fillWidth = width * progress;
    local borderSize = math.max(1, tonumber(settings.staminaBarBorderSize) or 1);

    local bg = ColorToU32(settings.staminaBarBackgroundColor, { 0.05, 0.05, 0.05, 0.86 });
    local fill = ColorToU32(settings.staminaBarColor, { 0.95, 0.38, 0.46, 1.0 });
    local border = ColorToU32(settings.staminaBarBorderColor, { 0.0, 0.0, 0.0, 1.0 });
    local textColor = ColorToU32(settings.staminaBarTextColor, { 1.0, 1.0, 1.0, 1.0 });

    if (settings.previewStaminaBar == true) then
        local textWidth = GetTextWidth(stamina.text or '60%');
        local frameX = x - 8;
        local frameY = y - 24;
        local frameW = width + textWidth + 28;
        local frameH = height + 34;

        HandleStaminaPreviewDrag(settings, x, y, frameX, frameY, frameW, frameH);
        DrawStaminaPreviewFrame(drawList, frameX, frameY, frameW, frameH);
    end

    AddText(drawList, x, y - 17, textColor, stamina.labelText or 'Fish stamina');
    drawList:AddRectFilled({ x, y }, { x + width, y + height }, bg);

    if (fillWidth > 0) then
        drawList:AddRectFilled({ x, y }, { x + fillWidth, y + height }, fill);
    end

    if (drawList.AddRect ~= nil) then
        drawList:AddRect({ x, y }, { x + width, y + height }, border, 0, 0, borderSize);
    end

    if (progress > 0 and fillWidth <= (borderSize * 2 + 6)) then
        local capWidth = math.min(width, math.max(fillWidth, borderSize * 2 + 6));
        local insetY = math.min(2, math.max(1, math.floor(height / 4)));
        drawList:AddRectFilled({ x + 1, y + insetY }, { x + capWidth, y + height - insetY }, fill);
    end

    AddText(drawList, x + width + 7, y - 3, textColor, stamina.text);
end

function overlay.Render()
    local settings = GetSettings();
    local stamina = fishing.GetStaminaBarState(settings);
    local revision = fishing.GetHudRevision ~= nil and fishing.GetHudRevision() or 0;

    if (settings.previewStaminaBar == true and state.GetConfigOpen ~= nil and state.GetConfigOpen() ~= true) then
        settings.previewStaminaBar = false;
        state.Save();
    end

    if (settings.previewStaminaBar == true and stamina == nil) then
        stamina = {
            progress = 60,
            text = '60%',
            labelText = 'Fish stamina',
            live = false,
            source = 'preview',
        };
    end

    if (settings.showStaminaBar ~= false or settings.previewStaminaBar == true) then
        DrawStandaloneStaminaBar(settings, stamina);
    end

    if (ShouldRenderHud(settings, stamina) ~= true) then
        return;
    end

    local x = tonumber(settings.hudX or settings.staminaBarScreenX) or 24;
    local y = tonumber(settings.hudY or settings.staminaBarScreenY) or 54;
    local width = math.max(hudMinWidth, tonumber(settings.hudWidth) or hudMinWidth);
    local height = math.max(hudMinHeight, tonumber(settings.hudHeight) or hudDefaultHeight);
    local windowFlags =
        (_G.ImGuiWindowFlags_NoSavedSettings or 0) +
        (_G.ImGuiWindowFlags_NoScrollbar or 0) +
        (_G.ImGuiWindowFlags_NoScrollWithMouse or 0) +
        (_G.ImGuiWindowFlags_NoMove or 0) +
        (_G.ImGuiWindowFlags_NoResize or 0) +
        (_G.ImGuiWindowFlags_NoTitleBar or 0) +
        (_G.ImGuiWindowFlags_NoBackground or 0);

    if (imgui.SetNextWindowPos ~= nil) then
        imgui.SetNextWindowPos({ x, y }, _G.ImGuiCond_Always or 1);
    end

    if (imgui.SetNextWindowSize ~= nil) then
        imgui.SetNextWindowSize({ width, height }, _G.ImGuiCond_Always or 1);
    end

    local visible = true;
    if (imgui.Begin ~= nil) then
        visible = imgui.Begin('LibraPlates Fishing HUD##FishingHud', true, windowFlags);
    end

    if (visible ~= true) then
        if (imgui.End ~= nil) then imgui.End(); end
        return;
    end

    local drawList = nil;
    pcall(function()
        drawList = imgui.GetWindowDrawList ~= nil and imgui.GetWindowDrawList() or imgui.GetForegroundDrawList();
    end);

    if (drawList == nil) then
        if (imgui.End ~= nil) then imgui.End(); end
        return;
    end

    SaveHudWindow(settings);

    local windowX, windowY = x, y;
    if (imgui.GetWindowPos ~= nil) then
        windowX, windowY = ReadVec2(imgui.GetWindowPos());
    end

    local windowWidth, windowHeight = width, height;
    if (imgui.GetWindowSize ~= nil) then
        windowWidth, windowHeight = ReadVec2(imgui.GetWindowSize());
    end

    HandleUnlockedHudInteraction(settings, windowX, windowY, windowWidth, windowHeight);
    HandleLockInteraction(settings, windowX, windowY, windowWidth);
    HandleCloseInteraction(settings, windowX, windowY, windowWidth, revision);
    if (settings.hudLocked == false) then
        DrawPreviewFrame(drawList, windowX, windowY, windowWidth, windowHeight);
    end

    if (drawList.AddRectFilled ~= nil) then
        local backgroundOpacity = math.max(0, math.min(100, tonumber(settings.backgroundOpacity) or 78)) / 100;
        local textureId = backgroundTextures.GetTextureId(settings.backgroundTexture or 'None');
        if (textureId ~= nil and drawList.AddImage ~= nil) then
            drawList:AddImage(textureId, { windowX + 2, windowY + 2 }, { windowX + windowWidth - 2, windowY + windowHeight - 2 }, { 0, 0 }, { 1, 1 }, ColorToU32({ 1.0, 1.0, 1.0, backgroundOpacity }));
        else
            local panelColor = settings.backgroundColor or { 0.04, 0.05, 0.07, 0.78 };
            panelColor = {
                panelColor[1],
                panelColor[2],
                panelColor[3],
                backgroundOpacity,
            };
            local panelBg = ColorToU32(panelColor, { 0.04, 0.05, 0.07, 0.78 });
            drawList:AddRectFilled({ windowX + 2, windowY + 2 }, { windowX + windowWidth - 2, windowY + windowHeight - 2 }, panelBg);
        end
    end

    local paddingX = 14;
    local titleY = windowY + 10;
    local lineY = titleY + 20;

    local textColor = ColorToU32(settings.staminaBarTextColor, { 1.0, 1.0, 1.0, 1.0 });
    local labelColor = ColorToU32({ 0.78, 0.84, 0.88, 1.0 }, { 0.78, 0.84, 0.88, 1.0 });
    local mutedColor = ColorToU32({ 0.64, 0.68, 0.72, 1.0 }, { 0.64, 0.68, 0.72, 1.0 });
    local okColor = ColorToU32({ 0.48, 0.90, 0.36, 1.0 }, { 0.48, 0.90, 0.36, 1.0 });
    local badColor = ColorToU32({ 1.0, 0.25, 0.28, 1.0 }, { 1.0, 0.25, 0.28, 1.0 });
    local title = 'Fishing HUD';
    AddText(drawList, windowX + paddingX, titleY, textColor, title);
    DrawLockButton(drawList, settings, windowX, windowY, windowWidth, textColor);
    DrawCloseButton(drawList, windowX, windowY, windowWidth, textColor);

    local hudInfo = fishing.GetHudInfo ~= nil and fishing.GetHudInfo(settings) or {};
    if (settings.previewHud == true and tostring(hudInfo.status or 'Ready') == 'Ready') then
        hudInfo.status = 'Fishing';
        hudInfo.active = true;
    end

    local rowY = lineY;
    local skillDisplay = GetSkillDisplay(hudInfo);
    if (skillDisplay ~= nil) then
        AddSkillRow(drawList, windowX + paddingX, rowY, labelColor, textColor, skillDisplay.color, 'Current level', skillDisplay.prefix, skillDisplay.rank);
        rowY = rowY + 22;
    end

    rowY = rowY + 6;
    DrawHudStatusBar(drawList, windowX + paddingX, rowY, math.max(120, windowWidth - (paddingX * 2)), 22, hudInfo, textColor, settings);
    rowY = rowY + 30;

    if (settings.showRodBait ~= false) then
        local recommendation = hudInfo.recommendation or {};
        local listWidth = math.max(120, windowWidth - (paddingX * 2));
        local rodOptions = hudInfo.rodOptions or recommendation.rods;
        local baitOptions = hudInfo.baitOptions or recommendation.baits;
        local hasRodList = type(rodOptions) == 'table' and #rodOptions > 0;
        local hasBaitList = type(baitOptions) == 'table' and #baitOptions > 0;

        if (hasRodList ~= true and tostring(hudInfo.rod or '') ~= '' and tostring(hudInfo.rod or '') ~= 'None') then
            rodOptions = {
                { name = hudInfo.rod, itemName = hudInfo.rod, owned = true, equipped = true },
            };
            hasRodList = true;
        end

        if (hasBaitList ~= true and tostring(hudInfo.bait or '') ~= '' and tostring(hudInfo.bait or '') ~= 'None') then
            baitOptions = {
                { name = hudInfo.bait, itemName = hudInfo.bait, count = hudInfo.baitCount, owned = true, equipped = true },
            };
            hasBaitList = true;
        end

        if (hasRodList == true) then
            AddRecommendationCombo(drawList, windowX + paddingX, rowY, listWidth, labelColor, textColor, 'Rod', hudInfo.rod or 'None', recommendation.rodMatch, rodOptions, hudInfo.rod, 'rod', 'range');
        else
            AddTaggedInfoRow(drawList, windowX + paddingX, rowY, labelColor, textColor, okColor, badColor, 'Rod', hudInfo.rod or 'None', recommendation.rodMatch);
        end
        rowY = rowY + 24;

        if (hasBaitList == true) then
            AddRecommendationCombo(drawList, windowX + paddingX, rowY, listWidth, labelColor, textColor, 'Bait', FormatBait(hudInfo), recommendation.baitMatch, baitOptions, hudInfo.bait, 'bait', 'ammo');
        else
            AddTaggedInfoRow(drawList, windowX + paddingX, rowY, labelColor, textColor, okColor, badColor, 'Bait', FormatBait(hudInfo), recommendation.baitMatch);
        end
        rowY = rowY + 24;

        if (type(hudInfo.targetOptions) == 'table' and #hudInfo.targetOptions > 0) then
            AddTargetCombo(drawList, windowX + paddingX, rowY, listWidth, labelColor, textColor, 'Target', hudInfo.target or 'Any', hudInfo.targetOptions);
        else
            AddInfoRow(drawList, windowX + paddingX, rowY, labelColor, mutedColor, 'Target', 'No spot data');
        end
        rowY = rowY + 24;
    end

    if (settings.showRecentResult ~= false) then
        AddInfoRow(drawList, windowX + paddingX, rowY, labelColor, textColor, 'Last catch', hudInfo.lastCatch or 'None');
        rowY = rowY + 16;
        AddInfoRow(drawList, windowX + paddingX, rowY, labelColor, textColor, 'Session', tostring(tonumber(hudInfo.totalCatches) or 0) .. ' catches');
        rowY = rowY + 16;
    end

    if (settings.showVentures ~= false) then
        rowY = AddVentureRows(drawList, windowX + paddingX, rowY, labelColor, textColor, mutedColor, hudInfo.venture);
    end

    if (settings.showFatigue == true and hudInfo.fatigue ~= nil) then
        local fatigueColor = hudInfo.fatigue.exempt == true and mutedColor or textColor;
        AddInfoRow(drawList, windowX + paddingX, rowY, labelColor, fatigueColor, 'Fatigue', hudInfo.fatigue.text or 'Waiting for data');
    end

    local borderDrawList = (imgui.GetForegroundDrawList ~= nil and imgui.GetForegroundDrawList()) or drawList;
    if (borderDrawList ~= nil and borderDrawList.AddRectFilled ~= nil and (tonumber(settings.backgroundBorderSize) or 0) > 0) then
        local borderColor = settings.backgroundBorderColor or hudAccent;
        local borderSize = math.max(1, tonumber(settings.backgroundBorderSize) or 1);
        local borderLeft = windowX + 2;
        local borderTop = windowY + 2;
        local borderRight = windowX + windowWidth - 2;
        local borderBottom = windowY + windowHeight - 2;
        local border = nil;

        borderColor = { borderColor[1], borderColor[2], borderColor[3], 1.0 };
        border = ColorToU32(borderColor, hudAccent);

        borderDrawList:AddRectFilled({ borderLeft, borderTop }, { borderRight, borderTop + borderSize }, border);
        borderDrawList:AddRectFilled({ borderLeft, borderBottom - borderSize }, { borderRight, borderBottom }, border);
        borderDrawList:AddRectFilled({ borderLeft, borderTop }, { borderLeft + borderSize, borderBottom }, border);
        borderDrawList:AddRectFilled({ borderRight - borderSize, borderTop }, { borderRight, borderBottom }, border);
    end

    if (imgui.End ~= nil) then
        imgui.End();
    end
end

return overlay;
