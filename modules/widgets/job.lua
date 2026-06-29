local defaults = require('config.widgets.job');
local textScale = require('core.text_scale');
local jobIconTextures = require('core.job_icon_textures');
local imgui = require('imgui');
local anchorControls = require('modules.widgets.anchor_controls');

local job = {};
local unpackTable = table.unpack or unpack;
local labelColor = { 0.92, 0.92, 0.90, 1.0 };
local valueColor = { 0.65, 0.90, 1.0, 1.0 };
local actionColor = { 1.0, 0.84, 0.0, 1.0 };
local displayModes = T{ 'Text', 'Icon' };
local colorEditFlags = bit ~= nil and bit.bor ~= nil
    and bit.bor(_G.ImGuiColorEditFlags_NoAlpha or 0, _G.ImGuiColorEditFlags_NoInputs or 0)
    or ((_G.ImGuiColorEditFlags_NoAlpha or 0) + (_G.ImGuiColorEditFlags_NoInputs or 0));
local tableFlags = (_G.ImGuiTableFlags_SizingFixedFit or 0) + (_G.ImGuiTableFlags_BordersInnerH or 0);
local rowLabelWidth = 122;
local rowControlWidth = 124;
local heldButtonState = {};

local function ClickText(label, color)
    imgui.TextColored(color or valueColor, label);

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        return true;
    end

    if (imgui.IsItemActive ~= nil and imgui.IsItemActive() == true) then
        if (imgui.IsMouseDown == nil or imgui.IsMouseDown(0) == true) then
            return true;
        end
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

    return ClickText(tostring(label), { 1.0, 0.84, 0.0, 1.0 }) == true;
end

local function DrawToggle(label, value)
    if (imgui.Checkbox ~= nil) then
        local ref = { value == true };

        if (imgui.Checkbox(label, ref) == true) then
            return ref[1] == true;
        end

        return ref[1] == true;
    end

    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (ClickText((value == true) and 'On' or 'Off', valueColor) == true) then
        return not (value == true);
    end

    return value == true;
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

local function DrawNumber(label, value, minValue, maxValue, step)
    local current = tonumber(value) or 0;
    local amount = tonumber(step) or 1;

    if (imgui.SliderInt ~= nil) then
        local ref = { math.floor(current + 0.5) };

        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(230);
        end

        imgui.SliderInt(label, ref, minValue or -1000, maxValue or 1000);

        if (imgui.PopItemWidth ~= nil) then
            imgui.PopItemWidth();
        end

        current = tonumber(ref[1]) or current;

        if (step ~= nil and step > 1) then
            current = math.floor((current / amount) + 0.5) * amount;
        end

        if (minValue ~= nil and current < minValue) then current = minValue; end
        if (maxValue ~= nil and current > maxValue) then current = maxValue; end

        return current;
    end

    imgui.TextColored(labelColor, label);
    imgui.SameLine();
    imgui.TextColored(valueColor, tostring(current));
    imgui.SameLine();

    if (ClickText('less', actionColor) == true) then
        current = current - amount;
    end

    imgui.SameLine();

    if (ClickText('more', actionColor) == true) then
        current = current + amount;
    end

    if (minValue ~= nil and current < minValue) then current = minValue; end
    if (maxValue ~= nil and current > maxValue) then current = maxValue; end

    return current;
end

local function DrawChoice(label, value, options)
    local currentIndex = tonumber(value) or 1;

    if (currentIndex < 1 or currentIndex > #options) then
        currentIndex = 1;
    end

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(230);
        end

        if (imgui.BeginCombo(label, options[currentIndex]) == true) then
            for index, option in ipairs(options) do
                local selected = index == currentIndex;

                if (imgui.Selectable(tostring(option), selected) == true) then
                    currentIndex = index;
                end

                if (selected == true and imgui.SetItemDefaultFocus ~= nil) then
                    imgui.SetItemDefaultFocus();
                end
            end

            imgui.EndCombo();
        end

        if (imgui.PopItemWidth ~= nil) then
            imgui.PopItemWidth();
        end

        return currentIndex;
    end

    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (ClickText(options[currentIndex], valueColor) == true) then
        currentIndex = currentIndex + 1;

        if (currentIndex > #options) then
            currentIndex = 1;
        end
    end

    return currentIndex;
end

local function DrawStringChoice(label, value, options)
    local current = tostring(value or options[1]);
    local index = 1;

    for i, option in ipairs(options) do
        if (option == current) then
            index = i;
            break;
        end
    end

    return options[DrawChoice(label, index, options)] or options[1];
end

local function DrawChoiceControl(id, value, options, width)
    local currentIndex = tonumber(value) or 1;

    if (currentIndex < 1 or currentIndex > #options) then
        currentIndex = 1;
    end

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(tonumber(width) or 124);
        end

        if (imgui.BeginCombo('##job_' .. tostring(id), tostring(options[currentIndex])) == true) then
            for index, option in ipairs(options) do
                local selected = index == currentIndex;

                if (imgui.Selectable(tostring(option), selected) == true) then
                    currentIndex = index;
                end

                if (selected == true and imgui.SetItemDefaultFocus ~= nil) then
                    imgui.SetItemDefaultFocus();
                end
            end

            imgui.EndCombo();
        end

        if (imgui.PopItemWidth ~= nil) then
            imgui.PopItemWidth();
        end

        return currentIndex;
    end

    if (ClickText(tostring(options[currentIndex]), valueColor) == true) then
        currentIndex = currentIndex + 1;

        if (currentIndex > #options) then
            currentIndex = 1;
        end
    end

    return currentIndex;
end

local function DrawStringChoiceControl(id, value, options, width)
    local current = tostring(value or options[1]);
    local index = 1;

    for i, option in ipairs(options) do
        if (option == current) then
            index = i;
            break;
        end
    end

    return options[DrawChoiceControl(id, index, options, width)] or options[1];
end

local function DrawDisplayRow(settings)
    local iconMode = (tonumber(settings.displayModeIndex) or 1) == 2;

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local columns = iconMode == true and 4 or 2;

        if (imgui.BeginTable('##job_display_row', columns, tableFlags)) then
            imgui.TableSetupColumn('##display_label', 0, rowLabelWidth);
            imgui.TableSetupColumn('##display_control', 0, rowControlWidth);

            if (iconMode == true) then
                imgui.TableSetupColumn('##theme_label', 0, rowLabelWidth);
                imgui.TableSetupColumn('##theme_control', 0, rowControlWidth);
            end

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Display');
            imgui.TableNextColumn();
            settings.displayModeIndex = DrawChoiceControl('display', settings.displayModeIndex, displayModes, 124);

            if (iconMode == true) then
                imgui.TableNextColumn();
                imgui.TextColored(labelColor, 'Icon theme');
                imgui.TableNextColumn();
                settings.iconTheme = DrawStringChoiceControl('icon_theme', settings.iconTheme, jobIconTextures.GetThemeNames(), 124);
            end

            imgui.EndTable();
        end

        return;
    end

    settings.displayModeIndex = DrawChoice('Display', settings.displayModeIndex, displayModes);

    if ((tonumber(settings.displayModeIndex) or 1) == 2) then
        settings.iconTheme = DrawStringChoice('Icon theme', settings.iconTheme, jobIconTextures.GetThemeNames());
    end
end

local function DrawSliderControl(id, value, minValue, maxValue, step, width)
    local current = tonumber(value) or 0;
    local original = current;
    local minimum = tonumber(minValue) or -1000;
    local maximum = tonumber(maxValue) or 1000;
    local amount = tonumber(step) or 1;
    local itemId = tostring(id or 'value');

    current = math.max(minimum, math.min(maximum, current));

    if (imgui.Button ~= nil and IsHeldButton('-##job_' .. itemId .. '_minus') == true) then
        current = current - amount;
    elseif (imgui.Button == nil and ClickText('-', actionColor) == true) then
        current = current - amount;
    end

    imgui.SameLine();

    if (imgui.InputText ~= nil) then
        local ref = { tostring(math.floor(current + 0.5)) };
        if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(tonumber(width) or 58); end
        if (imgui.InputText('##job_' .. itemId, ref, 16) == true) then
            current = tonumber(ref[1]) or current;
        end
        if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
    elseif (imgui.SliderInt ~= nil) then
        local ref = { math.floor(current + 0.5) };
        if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(tonumber(width) or 58); end
        if (imgui.SliderInt('##job_' .. itemId, ref, minimum, maximum) == true) then
            current = tonumber(ref[1]) or current;
        end
        if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
    else
        imgui.TextColored(valueColor, tostring(current));
    end

    imgui.SameLine();

    if (imgui.Button ~= nil and IsHeldButton('+##job_' .. itemId .. '_plus') == true) then
        current = current + amount;
    elseif (imgui.Button == nil and ClickText('+', actionColor) == true) then
        current = current + amount;
    end

    current = math.max(minimum, math.min(maximum, current));

    return current, current ~= original;
end

local function DrawPlacementPair(leftLabel, leftValue, leftId, rightLabel, rightValue, rightId, minValue, maxValue, step)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local leftResult = leftValue;
        local rightResult = rightValue;

        if (imgui.BeginTable('##job_pair_' .. tostring(leftId) .. '_' .. tostring(rightId), 4, tableFlags)) then
            imgui.TableSetupColumn('##label_left', 0, rowLabelWidth);
            imgui.TableSetupColumn('##control_left', 0, rowControlWidth);
            imgui.TableSetupColumn('##label_right', 0, rowLabelWidth);
            imgui.TableSetupColumn('##control_right', 0, rowControlWidth);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, leftLabel);
            imgui.TableNextColumn();
            leftResult = DrawSliderControl(leftId, leftValue, minValue, maxValue, step, 58);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, rightLabel);
            imgui.TableNextColumn();
            rightResult = DrawSliderControl(rightId, rightValue, minValue, maxValue, step, 58);
            imgui.EndTable();
        end

        return leftResult, rightResult;
    end

    local leftResult = DrawNumber(leftLabel, leftValue, minValue, maxValue, step);
    imgui.SameLine();
    local rightResult = DrawNumber(rightLabel, rightValue, minValue, maxValue, step);
    return leftResult, rightResult;
end

local function DrawSingleSlider(label, id, value, minValue, maxValue, step)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local result = value;

        if (imgui.BeginTable('##job_single_' .. tostring(id), 2, tableFlags)) then
            imgui.TableSetupColumn('##label', 0, rowLabelWidth);
            imgui.TableSetupColumn('##control', 0, rowControlWidth);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, label);
            imgui.TableNextColumn();
            result = DrawSliderControl(id, value, minValue, maxValue, step, 58);
            imgui.EndTable();
        end

        return result;
    end

    return DrawNumber(label, value, minValue, maxValue, step);
end

local function CopyColor(color)
    color = color or { 1.0, 1.0, 1.0, 1.0 };

    return {
        tonumber(color[1]) or 1.0,
        tonumber(color[2]) or 1.0,
        tonumber(color[3]) or 1.0,
        tonumber(color[4]) or 1.0,
    };
end

local function DrawColorControl(id, color)
    color = CopyColor(color);

    if (imgui.ColorEdit4 ~= nil) then
        imgui.ColorEdit4('##job_' .. tostring(id), color, colorEditFlags);
        return color;
    end

    imgui.TextColored(color, 'sample');
    return color;
end

local function DrawSliderAndColorRow(sizeLabel, sizeId, sizeValue, minValue, maxValue, colorLabel, colorId, colorValue, labelWidth)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local sizeResult = sizeValue;
        local colorResult = colorValue;
        local width = tonumber(labelWidth) or rowLabelWidth;

        if (imgui.BeginTable('##job_size_color_' .. tostring(sizeId) .. '_' .. tostring(colorId), 4, tableFlags)) then
            imgui.TableSetupColumn('##size_label', 0, width);
            imgui.TableSetupColumn('##size_control', 0, rowControlWidth);
            imgui.TableSetupColumn('##color_label', 0, width);
            imgui.TableSetupColumn('##color_control', 0, 60);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, sizeLabel);
            imgui.TableNextColumn();
            sizeResult = DrawSliderControl(sizeId, sizeValue, minValue, maxValue, 1, 58);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, colorLabel);
            imgui.TableNextColumn();
            colorResult = DrawColorControl(colorId, colorValue);
            imgui.EndTable();
        end

        return sizeResult, colorResult;
    end

    local sizeResult = DrawNumber(sizeLabel, sizeValue, minValue, maxValue, 1);
    local colorResult = DrawColor(colorLabel, colorValue);
    return sizeResult, colorResult;
end

local function ClampColorChannel(value)
    value = tonumber(value) or 0;
    if (value < 0) then return 0; end
    if (value > 1) then return 1; end
    return value;
end

local function DrawColor(label, color)
    color = color or { 1.0, 1.0, 1.0, 1.0 };
    color[4] = tonumber(color[4]) or 1.0;

    if (imgui.ColorEdit4 ~= nil) then
        imgui.ColorEdit4(label, color, (_G.ImGuiColorEditFlags_NoAlpha or 0) + (_G.ImGuiColorEditFlags_NoInputs or 0));
        return color;
    end

    local red = math.floor(ClampColorChannel(color[1]) * 255);
    local green = math.floor(ClampColorChannel(color[2]) * 255);
    local blue = math.floor(ClampColorChannel(color[3]) * 255);

    imgui.TextColored(color, label);
    imgui.SameLine();
    imgui.TextColored(valueColor, tostring(red) .. '/' .. tostring(green) .. '/' .. tostring(blue));
    imgui.SameLine();

    if (ClickText('red-', actionColor) == true) then red = math.max(0, red - 5); end
    imgui.SameLine();
    if (ClickText('red+', actionColor) == true) then red = math.min(255, red + 5); end
    imgui.SameLine();
    if (ClickText('green-', actionColor) == true) then green = math.max(0, green - 5); end
    imgui.SameLine();
    if (ClickText('green+', actionColor) == true) then green = math.min(255, green + 5); end
    imgui.SameLine();
    if (ClickText('blue-', actionColor) == true) then blue = math.max(0, blue - 5); end
    imgui.SameLine();
    if (ClickText('blue+', actionColor) == true) then blue = math.min(255, blue + 5); end

    color[1] = red / 255;
    color[2] = green / 255;
    color[3] = blue / 255;

    return color;
end

local function DrawAnchorCombo(id, current, choices)
    local value = tostring(current or 'Plate');

    if (value == 'Plate') then
        value = 'None';
    end

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(230);
        end

        if (imgui.BeginCombo('##job_anchor_' .. tostring(id), value) == true) then
            for _, choice in ipairs(choices or {}) do
                local selected = value == tostring(choice);

                if (imgui.Selectable(tostring(choice), selected) == true) then
                    value = tostring(choice);
                end

                if (selected == true and imgui.SetItemDefaultFocus ~= nil) then
                    imgui.SetItemDefaultFocus();
                end
            end

            imgui.EndCombo();
        end

        if (imgui.PopItemWidth ~= nil) then
            imgui.PopItemWidth();
        end
    else
        imgui.TextColored(valueColor, value);
    end

    if (value == 'None') then
        return 'Plate';
    end

    return value;
end

local function DrawAnchorControls(settings, context)
    anchorControls.Draw(settings, context, 'Job');
end

local function ApplyDefaults(settings)
    for key, value in pairs(defaults) do
        if (settings[key] == nil) then
            settings[key] = type(value) == 'table' and { unpackTable(value) } or value;
        end
    end

    if (settings.displayModeIndex == nil and settings.mode ~= nil) then
        settings.displayModeIndex = (tostring(settings.mode):lower() == 'icon') and 2 or 1;
        settings.mode = nil;
    end
end

-- ============================================================
-- Defaults
-- ============================================================

function job.GetDefaults()
    return defaults;
end

-- ============================================================
-- Rendering
-- ============================================================

function job.Draw(data, settings, context)
end

-- ============================================================
-- Settings UI
-- ============================================================

function job.DrawSettings(settings, context)
    if (settings == nil) then
        return;
    end

    ApplyDefaults(settings);

    if (context == nil or context.hideActive ~= true) then
        settings.enabled = DrawToggle('Active', settings.enabled);
    end
    if (context == nil or context.skipPlacement ~= true) then
        DrawAnchorControls(settings, context);
    end

    if (context ~= nil and context.onlyPlacement == true) then
        return;
    end

    local function DrawBody()
        DrawDisplayRow(settings);
        settings.offsetX, settings.offsetY = DrawPlacementPair('Position X', settings.offsetX, 'offset_x', 'Position Y', settings.offsetY, 'offset_y', -400, 400, 1);

        if ((tonumber(settings.displayModeIndex) or 1) == 2) then
            settings.iconSize = DrawSingleSlider('Icon size', 'icon_size', settings.iconSize, 8, 160, 1);
        else
            settings.textSize, settings.color = DrawSliderAndColorRow(
                'Font size',
                'text_size',
                textScale.NormalizeSetting(settings.textSize, defaults.textSize),
                textScale.GetMinVisualSize(),
                textScale.GetMaxVisualSize(),
                'Font color',
                'text_color',
                settings.color
            );
            if (context ~= nil and context.entity == 'Enemy') then
                settings.outlineSize, settings.outlineColor = DrawSliderAndColorRow(
                    'Outline size',
                    'outline_size',
                    settings.outlineSize,
                    0,
                    8,
                    'Outline color',
                    'outline_color',
                    settings.outlineColor,
                    122
                );
                settings.outlineEnabled = (tonumber(settings.outlineSize) or 0) > 0;
            else
                settings.outlineEnabled = DrawToggle('Text outline', settings.outlineEnabled);

                if (settings.outlineEnabled == true) then
                    settings.outlineSize, settings.outlineColor = DrawSliderAndColorRow(
                        'Outline size',
                        'outline_size',
                        settings.outlineSize,
                        0,
                        8,
                        'Outline color',
                        'outline_color',
                        settings.outlineColor,
                        122
                    );
                end
            end
        end
    end

    if (context ~= nil and context.boxed == true and _G.LibraPlatesSettingsDrawBoxedPanel ~= nil) then
        _G.LibraPlatesSettingsDrawBoxedPanel('Job', DrawBody, true);
    else
        DrawBody();
    end

    if (context ~= nil and context.boxed == true) then
        imgui.Spacing();
        imgui.Spacing();
    else
        imgui.Separator();
    end

    if (DrawActionButton('Reset Job position') == true) then
        settings.offsetX = defaults.offsetX;
        settings.offsetY = defaults.offsetY;
    end

    if (DrawActionButton('Reset Job settings') == true) then
        for key, value in pairs(defaults) do
            settings[key] = type(value) == 'table' and { unpackTable(value) } or value;
        end
    end
end

return job;
