local imgui = require('imgui');
local uiTooltip = require('core.ui_tooltip');
local fileManager = require('core.file_manager');
local arrowAnimation = require('core.target_arrow_animation');
local targetTextures = require('core.target_textures');
local state = require('core.state');
local globalDefaults = require('config.global');

local targetModule = {};
local unpackTable = table.unpack or unpack;
local labelColor = { 0.92, 0.92, 0.90, 1.0 };
local valueColor = { 0.65, 0.90, 1.0, 1.0 };
local actionColor = { 1.0, 0.84, 0.0, 1.0 };
local shellBg = { 0.094, 0.094, 0.094, 1.0 };
local panelBg = { 0.145, 0.145, 0.145, 1.0 };
local boxedPanelSerial = 0;

local function GetContentRegionAvail()
    if (imgui.GetContentRegionAvail == nil) then
        return 640, 480;
    end

    local availA, availB = imgui.GetContentRegionAvail();

    if (type(availA) == 'table') then
        return tonumber(availA.x or availA[1]) or 640, tonumber(availA.y or availA[2]) or 480;
    end

    return tonumber(availA) or 640, tonumber(availB) or 480;
end

local function DrawSectionHeader(label)
    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.18);
    end

    imgui.TextColored(actionColor, tostring(label or ''));

    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.0);
    end
end

local function DrawBoxedPanel(label, render, first)
    boxedPanelSerial = boxedPanelSerial + 1;

    local panelGap = 8;
    local panelPadX = 16;
    local panelPadY = 10;
    local topGap = (first == true) and 2 or panelGap;

    if (imgui.Dummy ~= nil) then
        imgui.Dummy({ 1, topGap });
    elseif (first ~= true and imgui.Spacing ~= nil) then
        imgui.Spacing();
    end

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local availWidth = select(1, GetContentRegionAvail());
        local cardWidth = math.max(260, (tonumber(availWidth) or 260) - 16);
        local colorCount = 0;

        if (imgui.PushStyleColor ~= nil) then
            if (_G.ImGuiCol_TableRowBg ~= nil) then
                imgui.PushStyleColor(_G.ImGuiCol_TableRowBg, panelBg);
                colorCount = colorCount + 1;
            end
            if (_G.ImGuiCol_TableRowBgAlt ~= nil) then
                imgui.PushStyleColor(_G.ImGuiCol_TableRowBgAlt, panelBg);
                colorCount = colorCount + 1;
            end
        end

        if (imgui.BeginTable('##TargetModulePanel' .. tostring(boxedPanelSerial), 1, (_G.ImGuiTableFlags_RowBg or 0), { cardWidth, 0 })) then
            imgui.TableSetupColumn('##card', 0, cardWidth);
            imgui.TableNextRow();
            imgui.TableNextColumn();

            if (imgui.Dummy ~= nil) then imgui.Dummy({ 1, panelPadY }); end
            if (imgui.Indent ~= nil) then imgui.Indent(panelPadX); end

            if (label ~= nil and label ~= '') then
                DrawSectionHeader(label);
                if (imgui.Spacing ~= nil) then imgui.Spacing(); end
            end

            render();

            if (imgui.Unindent ~= nil) then imgui.Unindent(panelPadX); end
            if (imgui.Dummy ~= nil) then imgui.Dummy({ 1, panelPadY }); end
            imgui.EndTable();
        end

        if (colorCount > 0 and imgui.PopStyleColor ~= nil) then
            imgui.PopStyleColor(colorCount);
        end

        return;
    end

    if (label ~= nil and label ~= '') then
        DrawSectionHeader(label);
    end
    render();
end
local heldButtonState = {};
local targetModuleTableFlags = (_G.ImGuiTableFlags_SizingFixedFit or 0) + (_G.ImGuiTableFlags_BordersInnerH or 0);
local autoPlaceAnchorOptions = T{ 'Widest element', 'Name', 'HP Bar' };
local colorEditFlags = bit ~= nil and bit.bor ~= nil
    and bit.bor(_G.ImGuiColorEditFlags_NoAlpha or 0, _G.ImGuiColorEditFlags_NoInputs or 0)
    or ((_G.ImGuiColorEditFlags_NoAlpha or 0) + (_G.ImGuiColorEditFlags_NoInputs or 0));

local function ClickText(label, color)
    imgui.TextColored(color or valueColor, label);

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        return true;
    end

    if (imgui.IsItemHovered ~= nil and imgui.IsMouseDown ~= nil) then
        return (imgui.IsItemHovered() == true and imgui.IsMouseDown(0) == true);
    end

    return false;
end

local function DrawActionButton(label)
    if (imgui.Button ~= nil) then
        return imgui.Button(tostring(label)) == true;
    end

    return ClickText(tostring(label), actionColor) == true;
end

local function DrawToggle(label, value)
    if (imgui.Checkbox ~= nil) then
        local ref = { value == true };

        if (imgui.Checkbox(label, ref) == true) then
            return ref[1] == true;
        end

        return value == true;
    end

    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (ClickText((value == true) and 'On' or 'Off', valueColor) == true) then
        return not (value == true);
    end

    return value == true;
end

local function ResolveChevronFile(settings, defaults)
    if (settings ~= nil and settings.chevronEnabled == false) then
        return 'None';
    end

    return tostring((settings ~= nil and settings.chevronFile) or (defaults ~= nil and defaults.chevronFile) or 'None');
end

local function IsHeldButton(label)
    if (imgui.Button == nil) then
        return false;
    end

    local clicked = imgui.Button(label) == true;
    local active = imgui.IsItemActive ~= nil and imgui.IsItemActive() == true;
    local mouseDown = imgui.IsMouseDown == nil or imgui.IsMouseDown(0) == true;
    local now = os.clock();
    local key = tostring(label or '');

    if (active == true and mouseDown == true) then
        local itemClicked = (imgui.IsItemActivated ~= nil and imgui.IsItemActivated() == true)
            or (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true);
        local state = heldButtonState[key];

        if (state == nil) then
            state = { nextRepeat = now + 0.35, clicked = false };
            heldButtonState[key] = state;
        end

        if ((clicked == true or itemClicked == true) and state.clicked ~= true) then
            state.clicked = true;
            return true;
        end

        if (now >= (tonumber(state.nextRepeat) or now + 0.35)) then
            state.nextRepeat = now + 0.08;
            return true;
        end

        return false;
    end

    if (heldButtonState[key] ~= nil) then
        heldButtonState[key] = nil;
        return false;
    end

    return clicked;
end

local function DrawNumberControl(value, minValue, maxValue, step, id, sliderWidth)
    local current = tonumber(value) or 0;
    local amount = 1;
    local minimum = tonumber(minValue) or -1000;
    local maximum = tonumber(maxValue) or 1000;
    local itemId = tostring(id or 'number'):gsub('[^%w_]', '_');

    current = math.max(minimum, math.min(maximum, current));

    if (imgui.Button ~= nil and IsHeldButton('-##target_module_' .. itemId .. '_minus') == true) then
        current = current - amount;
    elseif (imgui.Button == nil and ClickText('less', actionColor) == true) then
        current = current - amount;
    end

    imgui.SameLine();

    if (imgui.InputText ~= nil) then
        local ref = { amount < 1 and tostring(current) or tostring(math.floor(current + 0.5)) };
        if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(tonumber(sliderWidth) or 90); end
        if (imgui.InputText('##target_module_' .. itemId, ref, 16) == true) then
            current = tonumber(ref[1]) or current;
        end
        if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
    elseif (amount < 1 and imgui.SliderFloat ~= nil) then
        local ref = { current };
        if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(tonumber(sliderWidth) or 90); end
        if (imgui.SliderFloat('##target_module_' .. itemId, ref, minimum, maximum) == true) then
            current = tonumber(ref[1]) or current;
        end
        if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
    elseif (amount >= 1 and imgui.SliderInt ~= nil) then
        local ref = { math.floor(current + 0.5) };
        if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(tonumber(sliderWidth) or 90); end
        if (imgui.SliderInt('##target_module_' .. itemId, ref, minimum, maximum) == true) then
            current = tonumber(ref[1]) or current;
        end
        if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
    elseif (amount < 1) then
        imgui.TextColored(valueColor, string.format('%.2f', current));
    else
        imgui.TextColored(valueColor, tostring(current));
    end

    imgui.SameLine();

    if (imgui.Button ~= nil and IsHeldButton('+##target_module_' .. itemId .. '_plus') == true) then
        current = current + amount;
    elseif (imgui.Button == nil and ClickText('more', actionColor) == true) then
        current = current + amount;
    end

    return math.max(minimum, math.min(maximum, current));
end

local function DrawNumber(label, value, minValue, maxValue, step, id, labelColumnWidth)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local result = value;

        if (imgui.BeginTable('##target_module_number_' .. tostring(id or label), 2, targetModuleTableFlags)) then
            imgui.TableSetupColumn('##label', 0, tonumber(labelColumnWidth) or 122);
            imgui.TableSetupColumn('##control', 0, 124);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, label);
            imgui.TableNextColumn();
            result = DrawNumberControl(value, minValue, maxValue, step, id or label, 58);
            imgui.EndTable();
        end

        return result;
    end

    local current = tonumber(value) or 0;
    local itemId = tostring(id or label or 'number'):gsub('[^%w_]', '_');

    imgui.TextColored(labelColor, label);
    imgui.SameLine();
    current = DrawNumberControl(current, minValue, maxValue, step, itemId, 58);

    return current;
end

local function DrawNumberPair(leftLabel, leftValue, rightLabel, rightValue, minValue, maxValue, step, leftId, rightId, labelColumnWidth)
    leftId = leftId or leftLabel;
    rightId = rightId or rightLabel;

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local left = leftValue;
        local right = rightValue;

        if (imgui.BeginTable('##target_module_pair_' .. tostring(leftId) .. '_' .. tostring(rightId), 5, targetModuleTableFlags)) then
            imgui.TableSetupColumn('##label_left', 0, tonumber(labelColumnWidth) or 122);
            imgui.TableSetupColumn('##control_left', 0, 124);
            imgui.TableSetupColumn('##spacer', 0, 28);
            imgui.TableSetupColumn('##label_right', 0, 104);
            imgui.TableSetupColumn('##control_right', 0, 124);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, leftLabel);
            imgui.TableNextColumn();
            left = DrawNumberControl(leftValue, minValue, maxValue, step, leftId, 58);
            imgui.TableNextColumn();
            if (imgui.Dummy ~= nil) then imgui.Dummy({ 28, 1 }); end
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, rightLabel);
            imgui.TableNextColumn();
            right = DrawNumberControl(rightValue, minValue, maxValue, step, rightId, 58);
            imgui.EndTable();
        end

        return left, right;
    end

    local left = DrawNumber(leftLabel, leftValue, minValue, maxValue, step, leftId);

    imgui.SameLine();

    local right = DrawNumber(rightLabel, rightValue, minValue, maxValue, step, rightId);

    return left, right;
end

local function ClampOffsetToVisibleEdge(value, size, canvasSize, minVisible)
    local halfCanvas = (tonumber(canvasSize) or 0) * 0.5;
    local halfSize = (tonumber(size) or 0) * 0.5;
    local visible = math.max(1, tonumber(minVisible) or 24);
    local limit = math.max(0, halfCanvas + halfSize - visible);
    local current = tonumber(value) or 0;

    if (current < -limit) then
        return -limit;
    end

    if (current > limit) then
        return limit;
    end

    return current;
end

local function CopyDefaults(settings, defaults)
    for key, value in pairs(defaults or {}) do
        if (type(value) == 'table') then
            settings[key] = { unpackTable(value) };
        else
            settings[key] = value;
        end
    end
end

local function ApplyDefaults(settings, defaults)
    for key, value in pairs(defaults or {}) do
        if (settings[key] == nil) then
            if (
                (key == 'backgroundColor' or key == 'arrowColor' or key == 'lockColor' or key == 'chevronColor') and
                type(settings.color) == 'table'
            ) then
                settings[key] = { unpackTable(settings.color) };
            elseif (type(value) == 'table') then
                settings[key] = { unpackTable(value) };
            else
                settings[key] = value;
            end
        end
    end
end

local pendingCopy = {};
local selectedCopySourceKey = {};

local function GetCopyContextKey(context, label)
    local entity = tostring(context ~= nil and context.entity or '');
    local stateName = tostring(context ~= nil and context.state or '');
    local widget = tostring(context ~= nil and context.widget or label or 'Target Module');

    return (entity .. '_' .. stateName .. '_' .. widget):gsub('[^%w_]+', '_');
end

local function DrawCopySettings(settings, context, label)
    if (
        settings == nil or
        context == nil or
        context.defaults == nil or
        _G.LibraPlatesSettingsBuildWidgetCopySources == nil or
        _G.LibraPlatesSettingsCopySettingsFromSource == nil
    ) then
        return;
    end

    local copySources = _G.LibraPlatesSettingsBuildWidgetCopySources(context.entity, context.state, context.widget);

    if (copySources == nil or type(copySources) ~= 'table' or #copySources == 0) then
        return;
    end

    local key = GetCopyContextKey(context, label);
    local selectedSource = nil;
    local selectedKey = tostring(selectedCopySourceKey[key] or '');

    for _, source in ipairs(copySources) do
        if (selectedKey == tostring(source.key or '')) then
            selectedSource = source;
            break;
        end
    end

    if (selectedSource == nil) then
        selectedSource = copySources[1];
        selectedCopySourceKey[key] = tostring(selectedSource.key or '');
    end

    imgui.Separator();
    imgui.TextColored(labelColor, 'Copy ' .. tostring(label or 'Target Module') .. ' settings from');
    imgui.SameLine();

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(220);
        end

        if (imgui.BeginCombo('##target_module_copy_' .. key, tostring(selectedSource.label or 'Unknown')) == true) then
            for _, source in ipairs(copySources) do
                local sourceKey = tostring(source.key or '');
                local isSelected = selectedCopySourceKey[key] == sourceKey;

                if (imgui.Selectable(tostring(source.label or sourceKey), isSelected) == true) then
                    selectedCopySourceKey[key] = sourceKey;
                    selectedSource = source;
                end

                if (isSelected == true and imgui.SetItemDefaultFocus ~= nil) then
                    imgui.SetItemDefaultFocus();
                end
            end

            imgui.EndCombo();
        end

        if (imgui.PopItemWidth ~= nil) then
            imgui.PopItemWidth();
        end
    else
        imgui.TextColored(valueColor, tostring(selectedSource.label or 'Unknown'));
    end

    imgui.SameLine();

    if (imgui.Button ~= nil and imgui.Button('Copy##target_module_copy_from_' .. key)) then
        pendingCopy[key] = selectedSource;
        if (imgui.OpenPopup ~= nil) then
            imgui.OpenPopup('Copy settings confirm##target_module_copy_' .. key);
        end
    end

    imgui.SameLine();
    uiTooltip.Info('Copies the selected source settings into this ' .. tostring(label or 'Target Module') .. ' module. You will get a confirmation before anything is replaced.');

    if (pendingCopy[key] == nil) then
        return;
    end

    local popupName = 'Copy settings confirm##target_module_copy_' .. key;

    if (imgui.BeginPopupModal ~= nil) then
        if (imgui.BeginPopupModal(popupName) == true) then
            imgui.Text('Copy ' .. tostring(label or 'Target Module') .. ' settings?');
            imgui.Text('Source: ' .. tostring(pendingCopy[key].label or 'Unknown'));
            imgui.Text('This will replace the current settings.');
            imgui.Separator();

            if (imgui.Button('Cancel##target_module_copy_cancel_' .. key)) then
                pendingCopy[key] = nil;
                imgui.CloseCurrentPopup();
            end

            imgui.SameLine();

            if (imgui.Button('Copy##target_module_copy_confirm_' .. key)) then
                _G.LibraPlatesSettingsCopySettingsFromSource(settings, pendingCopy[key], context.defaults);
                pendingCopy[key] = nil;
                imgui.CloseCurrentPopup();
            end

            imgui.EndPopup();
        end
    else
        if (imgui.Button ~= nil and imgui.Button('Copy##target_module_copy_confirm_fallback_' .. key)) then
            _G.LibraPlatesSettingsCopySettingsFromSource(settings, pendingCopy[key], context.defaults);
            pendingCopy[key] = nil;
        end

        if (imgui.Button ~= nil and imgui.Button('Cancel##target_module_copy_cancel_fallback_' .. key)) then
            pendingCopy[key] = nil;
        end
    end
end

local function DrawColor(label, color)
    color = color or { 1.0, 1.0, 1.0, 1.0 };
    color[1] = tonumber(color[1]) or 1.0;
    color[2] = tonumber(color[2]) or 1.0;
    color[3] = tonumber(color[3]) or 1.0;
    color[4] = tonumber(color[4]) or 1.0;

    if (imgui.ColorEdit4 ~= nil) then
        imgui.ColorEdit4(label, color, colorEditFlags);
        return color;
    end

    imgui.TextColored(color, '#');
    imgui.SameLine();
    imgui.TextColored(labelColor, label);

    local colorId = tostring(label or 'Color'):gsub('[^%w_]', '_');
    color[1] = DrawNumber('Red', color[1], 0, 1, 0.01, colorId .. 'Red');
    color[2] = DrawNumber('Green', color[2], 0, 1, 0.01, colorId .. 'Green');
    color[3] = DrawNumber('Blue', color[3], 0, 1, 0.01, colorId .. 'Blue');
    color[4] = DrawNumber('Alpha', color[4], 0, 1, 0.01, colorId .. 'Alpha');

    return color;
end

local function DrawColorLabelFirst(label, color)
    color = color or { 1.0, 1.0, 1.0, 1.0 };
    color[1] = tonumber(color[1]) or 1.0;
    color[2] = tonumber(color[2]) or 1.0;
    color[3] = tonumber(color[3]) or 1.0;
    color[4] = tonumber(color[4]) or 1.0;

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##target_module_color_label_first_' .. tostring(label or 'Color'), 2, targetModuleTableFlags)) then
            imgui.TableSetupColumn('##label', 0, 132);
            imgui.TableSetupColumn('##control', 0, 48);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, label);
            imgui.TableNextColumn();

            if (imgui.ColorEdit4 ~= nil) then
                imgui.ColorEdit4('##' .. tostring(label or 'Color'), color, colorEditFlags);
            else
                imgui.TextColored(color, '#');
            end

            imgui.EndTable();
        end

        return color;
    end

    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (imgui.ColorEdit4 ~= nil) then
        imgui.ColorEdit4('##' .. tostring(label or 'Color'), color, colorEditFlags);
        return color;
    end

    imgui.TextColored(color, '#');

    local colorId = tostring(label or 'Color'):gsub('[^%w_]', '_');
    color[1] = DrawNumber('Red', color[1], 0, 1, 0.01, colorId .. 'Red');
    color[2] = DrawNumber('Green', color[2], 0, 1, 0.01, colorId .. 'Green');
    color[3] = DrawNumber('Blue', color[3], 0, 1, 0.01, colorId .. 'Blue');
    color[4] = DrawNumber('Alpha', color[4], 0, 1, 0.01, colorId .. 'Alpha');

    return color;
end

local function GetOpacityPercent(color, fallback)
    color = color or {};
    return math.max(0, math.min(100, math.floor((((tonumber(color[4]) or fallback or 1.0) * 100) + 0.5))));
end

local function SetOpacityPercent(color, value)
    color = color or { 1.0, 1.0, 1.0, 1.0 };
    color[4] = math.max(0, math.min(100, tonumber(value) or 100)) / 100;
    return color;
end

local function ContainsValue(options, value)
    for _, option in ipairs(options or {}) do
        if (option == value) then
            return true;
        end
    end

    return false;
end

local function GetFirstRealFile(options)
    for _, option in ipairs(options or {}) do
        if (option ~= 'None') then
            return option;
        end
    end

    return 'None';
end

local function FormatArrowChoiceName(fileName)
    local value = tostring(fileName or 'None');

    if (value == 'None') then
        return value;
    end

    value = value:gsub('%.png$', '');
    local simpleArrow = value:match('^arrow_([%d]+)$');

    if (simpleArrow ~= nil) then
        return 'Arrow ' .. tostring(tonumber(simpleArrow) or simpleArrow);
    end

    value = value:gsub('^arrow_', '');
    value = value:gsub('^Arrow_', '');
    value = value:gsub('_%d%d$', '');
    value = value:gsub('_', ' ');
    value = value:gsub('(%a)([%w]*)', function(first, rest)
        return string.upper(first) .. string.lower(rest);
    end);

    if (value == '') then
        return tostring(fileName or '');
    end

    return value;
end

local function FormatLockChoiceName(fileName)
    local value = tostring(fileName or 'None');

    if (value == 'None') then
        return value;
    end

    value = value:gsub('%.png$', '');
    value = value:gsub('_%d%d$', '');
    value = value:gsub('_', ' ');
    value = value:gsub('(%a)([%w]*)', function(first, rest)
        return string.upper(first) .. string.lower(rest);
    end);

    if (value == '') then
        return tostring(fileName or '');
    end

    return value;
end

local function DrawFile(label, category, current, filesOverride, displayNameFn)
    local files = filesOverride or targetTextures.GetFiles(category);
    local value = tostring(current or files[1] or 'None');

    if (category == 'arrows') then
        value = arrowAnimation.GetDropdownFileName(value);
    end

    if ((category == 'arrows' or filesOverride ~= nil) and ContainsValue(files, value) ~= true) then
        value = GetFirstRealFile(files);
    end

    local function GetDisplayName(fileName)
        if (displayNameFn ~= nil) then
            return displayNameFn(fileName);
        end

        return tostring(fileName or '');
    end

    local function DrawPreviewTooltip(fileName)
        if (imgui.IsItemHovered == nil or imgui.IsItemHovered() ~= true) then
            return;
        end

        local textureId = targetTextures.GetTextureId(category, fileName);
        local previewSize = (category == 'backgrounds') and { 220, 110 } or { 110, 110 };

        if (
            textureId ~= nil and
            imgui.BeginTooltip ~= nil and
            imgui.EndTooltip ~= nil and
            imgui.Image ~= nil
        ) then
            imgui.BeginTooltip();
            imgui.Text(tostring(fileName or ''));
            imgui.Image(textureId, previewSize, { 0, 0 }, { 1, 1 });
            imgui.EndTooltip();
        elseif (imgui.SetTooltip ~= nil) then
            imgui.SetTooltip(tostring(fileName or ''));
        end
    end

    local function DrawCombo()
        if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
            if (imgui.PushItemWidth ~= nil) then
                imgui.PushItemWidth(282);
            end

            local comboOpen = imgui.BeginCombo('##' .. label .. category, GetDisplayName(value)) == true;
            DrawPreviewTooltip(value);

            if (comboOpen == true) then
                for _, file in ipairs(files) do
                    local selected = (file == value);

                    if (imgui.Selectable(GetDisplayName(file), selected) == true) then
                        value = file;
                    end
                    DrawPreviewTooltip(file);

                    if (selected == true and imgui.SetItemDefaultFocus ~= nil) then
                        imgui.SetItemDefaultFocus();
                    end
                end

                imgui.EndCombo();
            end

            if (imgui.PopItemWidth ~= nil) then
                imgui.PopItemWidth();
            end

            fileManager.Draw(targetTextures.GetFolderPath(category), 'TargetFile_' .. tostring(label) .. '_' .. tostring(category));

            return;
        end

        imgui.TextColored(valueColor, '[' .. value .. ' v]');

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            local index = 1;

            for i, file in ipairs(files) do
                if (file == value) then
                    index = i;
                    break;
                end
            end

            index = index + 1;

            if (index > #files) then
                index = 1;
            end

            value = files[index] or value;
        end

        fileManager.Draw(targetTextures.GetFolderPath(category), 'TargetFile_' .. tostring(label) .. '_' .. tostring(category));
    end

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##target_module_file_' .. tostring(label) .. tostring(category), 2, targetModuleTableFlags)) then
            imgui.TableSetupColumn('##label', 0, 150);
            imgui.TableSetupColumn('##control', 0, 318);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, label);
            imgui.TableNextColumn();
            DrawCombo();
            imgui.EndTable();
        end

        return value;
    end

    imgui.TextColored(labelColor, label);
    imgui.SameLine();
    DrawCombo();

    return value;
end

local function DrawOption(label, options, current, id)
    local value = tostring(current or options[1] or '');
    local comboId = '##' .. tostring(id or label or 'option');

    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.BeginCombo(comboId, value) == true) then
            for _, option in ipairs(options) do
                local selected = (option == value);

                if (imgui.Selectable(tostring(option), selected) == true) then
                    value = option;
                end

                if (selected == true and imgui.SetItemDefaultFocus ~= nil) then
                    imgui.SetItemDefaultFocus();
                end
            end

            imgui.EndCombo();
        end

        return value;
    end

    if (ClickText(value, valueColor) == true) then
        local index = 1;

        for i, option in ipairs(options) do
            if (option == value) then
                index = i;
                break;
            end
        end

        index = index + 1;

        if (index > #options) then
            index = 1;
        end

        value = options[index] or value;
    end

    return value;
end

function targetModule.DrawSettings(settings, context)
    if (settings == nil) then
        return;
    end

    boxedPanelSerial = 0;

    local defaults = context ~= nil and context.defaults or {};
    local label = tostring(context ~= nil and context.widget or 'Target Module');
    local entityName = tostring(context ~= nil and context.entity or '');
    local sourceStateName = tostring(context ~= nil and (context.sourceState or context.state) or '');
    local isSubtargetModule = tostring(label) == 'Subtarget (module)';
    local lockOnly = context ~= nil and context.lockOnly == true;
    local allowHighlight = not (entityName == 'NPC' and (sourceStateName == 'World' or sourceStateName == 'Idle'));
    local isPet = (
        entityName == 'Pet (BST)' or
        entityName == 'Pet (SMN)' or
        entityName == 'Wyvern' or
        entityName == 'Automaton'
    );

    ApplyDefaults(settings, defaults);

    if (isSubtargetModule ~= true) then
        settings.arrowDistanceColoring = false;
    end

    local function DrawLockOnIconPanel()
        DrawBoxedPanel('Lock-on icon', function()
            if (lockOnly ~= true) then
                settings.lockEnabled = DrawToggle('Show lock-on icon', settings.lockEnabled ~= false);
            end

            if (lockOnly == true or settings.lockEnabled ~= false) then
                local lockTypeOptions = T{ 'Still image', 'Animation' };
                local lockType = settings.lockSprite == true and 'Animation' or 'Still image';
                lockType = DrawOption('Lock-on type', lockTypeOptions, lockType, 'TargetModuleLockType');
                settings.lockSprite = lockType == 'Animation';

                if (settings.lockSprite == true) then
                    settings.lockFile = DrawFile('Lock-on animation', 'lock', settings.lockFile, targetTextures.GetAnimationFiles('lock'), FormatLockChoiceName);

                    if (tostring(settings.lockFile or 'None') ~= 'None') then
                        settings.lockAnimationSpeed = DrawNumber('Animation speed', settings.lockAnimationSpeed, 1, 60, 1, 'TargetModuleLockAnimationSpeed');
                    end
                else
                    settings.lockFile = DrawFile('Lock-on image', 'lock', settings.lockFile, targetTextures.GetStillFiles('lock'), FormatLockChoiceName);
                end

                settings.lockWidth, settings.lockHeight = DrawNumberPair(
                    'Width',
                    settings.lockWidth,
                    'Height',
                    settings.lockHeight,
                    1,
                    200,
                    1,
                    'TargetModuleLockWidth',
                    'TargetModuleLockHeight'
                );
                settings.lockOffsetX, settings.lockOffsetY = DrawNumberPair(
                    'Position X',
                    settings.lockOffsetX,
                    'Position Y',
                    settings.lockOffsetY,
                    -500,
                    500,
                    1,
                    'TargetModuleLockX',
                    'TargetModuleLockY'
                );
                settings.lockColor = DrawColorLabelFirst('Lock-on tint', settings.lockColor);
            end
        end);
    end

    if (context == nil or context.boxed ~= true) then
        DrawBoxedPanel(label .. ' settings', function()
            imgui.TextColored((settings.enabled ~= false) and valueColor or { 0.20, 0.65, 0.67, 1.0 }, (settings.enabled ~= false) and 'ON' or 'OFF');
            uiTooltip.Info('This controls only the LibraPlates custom target/subtarget module. The native game target arrow is controlled globally in General > Targeting.');

            if (lockOnly ~= true) then
                DrawCopySettings(settings, context, label);

                if (_G.LibraPlatesSettingsDrawContextLoadMode ~= nil) then
                    _G.LibraPlatesSettingsDrawContextLoadMode(settings, context);
                end
            end
        end, true);
    end

    if (lockOnly == true) then
        DrawLockOnIconPanel();

        if (imgui.Spacing ~= nil) then
            imgui.Spacing();
        end

        if (DrawActionButton('Reset Lock-on icon position') == true) then
            settings.lockOffsetX = defaults.lockOffsetX;
            settings.lockOffsetY = defaults.lockOffsetY;
            state.Save();
        end

        if (DrawActionButton('Reset Lock-on icon settings') == true) then
            settings.lockEnabled = defaults.lockEnabled;
            settings.lockFile = defaults.lockFile;
            settings.lockSprite = defaults.lockSprite;
            settings.lockAnimationSpeed = defaults.lockAnimationSpeed;
            settings.lockWidth = defaults.lockWidth;
            settings.lockHeight = defaults.lockHeight;
            settings.lockOffsetX = defaults.lockOffsetX;
            settings.lockOffsetY = defaults.lockOffsetY;
            settings.lockColor = type(defaults.lockColor) == 'table'
                and { unpackTable(defaults.lockColor) }
                or defaults.lockColor;
            state.Save();
        end

        return;
    end

    if (isPet == true and label ~= 'Subtarget Module') then
        local globalSettings = state.GetGlobalSettings(globalDefaults);
        globalSettings.targeting = globalSettings.targeting or {};

        if (globalSettings.targeting.enablePetPlateTargeting == nil) then
            globalSettings.targeting.enablePetPlateTargeting = true;
        end

        DrawBoxedPanel('Pet targeting', function()
            local enabled = DrawToggle('Allow pet plate targeting', globalSettings.targeting.enablePetPlateTargeting ~= false);

            if (enabled ~= (globalSettings.targeting.enablePetPlateTargeting ~= false)) then
                globalSettings.targeting.enablePetPlateTargeting = enabled == true;
                state.Save();
            end

            uiTooltip.Info('When off, pet plates stay visible but LibraPlates will not target the pet from plate clicks and will suppress the pet Target module overlay.');
        end);

        if (globalSettings.targeting.enablePetPlateTargeting == false) then
            return;
        end
    end

    if (allowHighlight == true) then
        DrawBoxedPanel('Highlight', function()
            settings.backgroundFile = DrawFile('Highlight image', 'backgrounds', settings.backgroundFile);
            if (tostring(settings.backgroundFile or 'None') == 'None') then
                settings.backgroundEnabled = false;
                settings.showBackground = false;
            elseif (settings.showBackground == true and settings.backgroundEnabled == false) then
                settings.backgroundEnabled = true;
            end

            if (tostring(settings.backgroundFile or 'None') ~= 'None') then
                settings.backgroundClickable = DrawToggle('Highlight is clickable', settings.backgroundClickable ~= false);
                uiTooltip.Info('When off, the highlight image still draws but does not expand the plate click area.');

                settings.autoPlaceBackground = DrawToggle('Auto place highlight', settings.autoPlaceBackground ~= false);
                uiTooltip.Info('When enabled, the highlight image follows the selected plate element. Size expands it outward from the anchor edges. Turn it off to use manual highlight width, height, and position.');

                if (settings.autoPlaceBackground ~= false) then
                    settings.backgroundAutoPlaceAnchor = DrawOption('Auto place by', autoPlaceAnchorOptions, settings.backgroundAutoPlaceAnchor or 'Widest element', 'TargetModuleBackgroundAnchorMode');
                    settings.backgroundSpacing = DrawNumber('Size', settings.backgroundSpacing, 0, 300, 1, 'TargetModuleBackgroundSpacing');
                    settings.backgroundOffsetY = DrawNumber('Position Y', settings.backgroundOffsetY, -100, 100, 1, 'TargetModuleBackgroundAutoY');
                else
                    settings.backgroundWidth, settings.backgroundHeight = DrawNumberPair(
                        'Width',
                        settings.backgroundWidth,
                        'Height',
                        settings.backgroundHeight,
                        8,
                        1000,
                        5,
                        'TargetModuleBackgroundWidth',
                        'TargetModuleBackgroundHeight'
                    );
                    settings.backgroundOffsetX = DrawNumber('Position X', settings.backgroundOffsetX, -350, 350, 1, 'TargetModuleBackgroundX');

                    local backgroundHeight = tonumber(settings.backgroundHeight) or 90;
                    settings.backgroundOffsetY = DrawNumber(
                        'Position Y',
                        ClampOffsetToVisibleEdge(settings.backgroundOffsetY, backgroundHeight, 512, 24),
                        -500,
                        500,
                        5,
                        'TargetModuleBackgroundY'
                    );
                    settings.backgroundOffsetY = ClampOffsetToVisibleEdge(settings.backgroundOffsetY, backgroundHeight, 512, 24);
                end
                settings.backgroundColor = DrawColorLabelFirst('Highlight tint', settings.backgroundColor);
                settings.backgroundColor = SetOpacityPercent(settings.backgroundColor, GetOpacityPercent(settings.backgroundColor, 0.95));
                local backgroundOpacity = DrawNumber('Opacity', GetOpacityPercent(settings.backgroundColor, 0.95), 0, 100, 1, 'TargetModuleBackgroundOpacity');
                settings.backgroundColor = SetOpacityPercent(settings.backgroundColor, backgroundOpacity);
            end
        end);
    end

    DrawBoxedPanel('Arrow', function()
        arrowAnimation.UpgradeLegacySettings(settings);

        local arrowTypeOptions = T{ 'Still image', 'Animation' };
        local arrowType = settings.arrowSprite == true and 'Animation' or 'Still image';
        arrowType = DrawOption('Arrow type', arrowTypeOptions, arrowType, 'TargetModuleArrowType');
        settings.arrowSprite = arrowType == 'Animation';

        if (settings.arrowSprite == true) then
            local animationFiles = targetTextures.GetArrowAnimationFiles();

            settings.arrowFile = DrawFile('Arrow animation', 'arrows', settings.arrowFile, animationFiles, FormatArrowChoiceName);
            uiTooltip.Info('Choose an animation set. The dropdown shows one entry per animation, not every frame.');

            if (tostring(settings.arrowFile or 'None') ~= 'None') then
                settings.arrowAnimationSpeed = DrawNumber('Animation speed', settings.arrowAnimationSpeed, 1, 60, 1, 'TargetModuleArrowAnimationSpeed', 140);
            end
        else
            local stillFiles = targetTextures.GetArrowStillFiles();

            settings.arrowFile = DrawFile('Arrow image', 'arrows', settings.arrowFile, stillFiles, FormatArrowChoiceName);
            uiTooltip.Info('Choose a still arrow image. Switch Arrow type to Animation for animated arrows.');
        end

        if (tostring(settings.arrowFile or 'None') ~= 'None') then
            settings.arrowWidth, settings.arrowHeight = DrawNumberPair(
                'Width',
                settings.arrowWidth,
                'Height',
                settings.arrowHeight,
                8,
                200,
                1,
                'TargetModuleArrowWidth',
                'TargetModuleArrowHeight',
                140
            );

            settings.arrowOffsetX, settings.arrowOffsetY = DrawNumberPair(
                'Position X',
                settings.arrowOffsetX,
                'Position Y',
                settings.arrowOffsetY,
                -500,
                500,
                5,
                'TargetModuleArrowX',
                'TargetModuleArrowY',
                140
            );
            if (isSubtargetModule == true and entityName ~= 'Self') then
                DrawBoxedPanel('Range colors', function()
                    settings.arrowDistanceColoring = true;
                    settings.arrowOutOfRangeColor = DrawColor('Out-of-range tint', settings.arrowOutOfRangeColor);
                    settings.arrowWarningColor = DrawColor('Warning tint', settings.arrowWarningColor);
                    settings.arrowInRangeColor = DrawColor('In-range tint', settings.arrowInRangeColor);
                    uiTooltip.Info('Used by the Subtarget arrow when LibraPlates has a queued spell, ability, or weapon skill range from Ashita resources.');
                end);
            else
                if (isSubtargetModule == true) then
                    settings.arrowDistanceColoring = false;
                end
                settings.arrowColor = DrawColorLabelFirst('Arrow tint', settings.arrowColor);
            end
        else
            settings.arrowSprite = false;
        end
    end);

    DrawBoxedPanel('Chevrons', function()
        settings.chevronFile = DrawFile('Chevron image', 'chevrons', ResolveChevronFile(settings, defaults));
        settings.chevronEnabled = tostring(settings.chevronFile or 'None') ~= 'None';

        if (tostring(settings.chevronFile or 'None') ~= 'None') then
            settings.chevronWidth, settings.chevronHeight = DrawNumberPair(
                'Width',
                settings.chevronWidth,
                'Height',
                settings.chevronHeight,
                8,
                200,
                1,
                'TargetModuleChevronsWidth',
                'TargetModuleChevronsHeight'
            );
            settings.autoPlaceChevrons = DrawToggle('Auto place chevrons', settings.autoPlaceChevrons ~= false);
            uiTooltip.Info('When enabled, chevrons are placed outside the full measured plate width for the current enemy state. Chevron spacing then adds extra distance outward from that edge. Turn it off only when you want to shift chevrons manually with Chevrons X.');
            if (settings.autoPlaceChevrons ~= false) then
                settings.chevronAutoPlaceAnchor = DrawOption('Auto place by', autoPlaceAnchorOptions, settings.chevronAutoPlaceAnchor or 'Widest element', 'TargetModuleChevronsAnchorMode');
            end
            settings.chevronSpacing = DrawNumber('Chevron spacing', settings.chevronSpacing, 0, 900, 1, 'TargetModuleChevronsSpacing');

            if (settings.autoPlaceChevrons == false) then
                settings.chevronOffsetX = DrawNumber('Position X', settings.chevronOffsetX, -350, 350, 1, 'TargetModuleChevronsX');
            end

            settings.chevronOffsetY = DrawNumber('Position Y', settings.chevronOffsetY, -500, 500, 1, 'TargetModuleChevronsY');
            settings.chevronColor = DrawColorLabelFirst('Chevron tint', settings.chevronColor);
        end
    end);

    if (isSubtargetModule ~= true) then
        DrawLockOnIconPanel();
    end

    if (imgui.Spacing ~= nil) then
        imgui.Spacing();
    end

    if (DrawActionButton('Reset ' .. label .. ' position') == true) then
        settings.backgroundOffsetX = defaults.backgroundOffsetX;
        settings.backgroundOffsetY = defaults.backgroundOffsetY;
        settings.arrowOffsetX = defaults.arrowOffsetX;
        settings.arrowOffsetY = defaults.arrowOffsetY;
        settings.lockOffsetX = defaults.lockOffsetX;
        settings.lockOffsetY = defaults.lockOffsetY;
        settings.chevronOffsetX = defaults.chevronOffsetX;
        settings.chevronOffsetY = defaults.chevronOffsetY;
        settings.chevronSpacing = defaults.chevronSpacing;
        settings.autoPlaceChevrons = defaults.autoPlaceChevrons;
        settings.backgroundAutoPlaceAnchor = defaults.backgroundAutoPlaceAnchor or 'Widest element';
        settings.chevronAutoPlaceAnchor = defaults.chevronAutoPlaceAnchor or 'Widest element';
    end

    if (DrawActionButton('Reset ' .. label .. ' settings') == true) then
        CopyDefaults(settings, defaults);
    end
end

return targetModule;
