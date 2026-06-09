local imgui = require('imgui');
local textScale = require('core.text_scale');
local anchorControls = require('modules.widgets.anchor_controls');

local textWidget = {};
local unpackTable = table.unpack or unpack;
local labelColor = { 0.92, 0.92, 0.90, 1.0 };
local valueColor = { 0.65, 0.90, 1.0, 1.0 };
local actionColor = { 1.0, 0.84, 0.0, 1.0 };
local colorEditFlags = bit ~= nil and bit.bor ~= nil
    and bit.bor(_G.ImGuiColorEditFlags_NoAlpha or 0, _G.ImGuiColorEditFlags_NoInputs or 0)
    or ((_G.ImGuiColorEditFlags_NoAlpha or 0) + (_G.ImGuiColorEditFlags_NoInputs or 0));
local tableFlags = (_G.ImGuiTableFlags_SizingFixedFit or 0) + (_G.ImGuiTableFlags_BordersInnerH or 0);
local pendingReset = nil;
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
        return imgui.IsItemHovered() == true and imgui.IsMouseDown(0) == true;
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
    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (ClickText((value == true) and 'On' or 'Off', valueColor) == true) then
        return not (value == true);
    end

    return value == true;
end

local function DrawCheckbox(label, value)
    if (imgui.Checkbox ~= nil) then
        local ref = { value == true };

        if (imgui.Checkbox(label, ref) == true) then
            return ref[1] == true;
        end

        return ref[1] == true;
    end

    return DrawToggle(label, value);
end

local function DrawNumber(label, value, minValue, maxValue, step)
    local current = tonumber(value) or 0;
    local amount = tonumber(step) or 1;

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

local function DrawSliderControl(id, value, minValue, maxValue, width, showButtons)
    local current = math.floor((tonumber(value) or 0) + 0.5);
    local minimum = minValue or -1000;
    local maximum = maxValue or 1000;

    if (showButtons == false and imgui.SliderInt == nil) then
        return DrawNumber('', value, minValue, maxValue, 1);
    end

    if (showButtons ~= false and imgui.InputText == nil and imgui.SliderInt == nil) then
        return DrawNumber('', value, minValue, maxValue, 1);
    end

    if (showButtons ~= false and imgui.Button ~= nil) then
        if (IsHeldButton('-##text_' .. id .. '_minus')) then
            current = current - 1;
        end

        imgui.SameLine();
    end

    if (imgui.PushItemWidth ~= nil) then
        imgui.PushItemWidth(width or 95);
    end

    local ref = { current };
    if (showButtons ~= false and imgui.InputText ~= nil) then
        ref = { tostring(current) };
        imgui.InputText('##text_' .. id, ref, 16);
    else
        imgui.SliderInt('##text_' .. id, ref, minimum, maximum);
    end

    if (imgui.PopItemWidth ~= nil) then
        imgui.PopItemWidth();
    end

    current = tonumber(ref[1]) or current;

    if (showButtons ~= false and imgui.Button ~= nil) then
        imgui.SameLine();

        if (IsHeldButton('+##text_' .. id .. '_plus')) then
            current = current + 1;
        end
    end

    if (minValue ~= nil and current < minValue) then current = minValue; end
    if (maxValue ~= nil and current > maxValue) then current = maxValue; end

    return current;
end

local function DrawTableSlider(label, id, value, minValue, maxValue, showButtons)
    imgui.TextColored(labelColor, label);
    imgui.TableNextColumn();
    return DrawSliderControl(id, value, minValue, maxValue, showButtons == false and 140 or 95, showButtons);
end

local function DrawSliderPair(rowId, leftLabel, leftId, leftValue, leftMin, leftMax, rightLabel, rightId, rightValue, rightMin, rightMax)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local leftResult = leftValue;
        local rightResult = rightValue;

        if (imgui.BeginTable('##text_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##label_left', 0, 145);
            imgui.TableSetupColumn('##control_left', 0, 170);
            imgui.TableSetupColumn('##label_right', 0, 145);
            imgui.TableSetupColumn('##control_right', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            leftResult = DrawTableSlider(leftLabel, leftId, leftValue, leftMin, leftMax);
            imgui.TableNextColumn();
            rightResult = DrawTableSlider(rightLabel, rightId, rightValue, rightMin, rightMax);
            imgui.EndTable();
        end

        return leftResult, rightResult;
    end

    local leftResult = DrawNumber(leftLabel, leftValue, leftMin, leftMax, 1);
    imgui.SameLine();
    local rightResult = DrawNumber(rightLabel, rightValue, rightMin, rightMax, 1);
    return leftResult, rightResult;
end

local function ClampColorChannel(value)
    local channel = tonumber(value) or 0;

    if (channel < 0) then return 0; end
    if (channel > 1) then return 1; end

    return channel;
end

local function DrawColor(label, value)
    local color = value or { 1.0, 1.0, 1.0, 1.0 };
    local red = math.floor(ClampColorChannel(color[1]) * 255);
    local green = math.floor(ClampColorChannel(color[2]) * 255);
    local blue = math.floor(ClampColorChannel(color[3]) * 255);
    local edit = nil;

    if (imgui.ColorEdit4 ~= nil) then
        imgui.ColorEdit4('##text_' .. label, color, colorEditFlags);
        return color;
    end

    imgui.TextColored(color, label);
    imgui.SameLine();
    imgui.TextColored(valueColor, tostring(red) .. '/' .. tostring(green) .. '/' .. tostring(blue));
    imgui.SameLine();

    if (ClickText('red-', actionColor) == true) then edit = 'red-'; end
    imgui.SameLine();
    if (ClickText('red+', actionColor) == true) then edit = 'red+'; end
    imgui.SameLine();
    if (ClickText('green-', actionColor) == true) then edit = 'green-'; end
    imgui.SameLine();
    if (ClickText('green+', actionColor) == true) then edit = 'green+'; end
    imgui.SameLine();
    if (ClickText('blue-', actionColor) == true) then edit = 'blue-'; end
    imgui.SameLine();
    if (ClickText('blue+', actionColor) == true) then edit = 'blue+'; end

    if (edit == 'red-') then
        red = math.max(0, red - 5);
    elseif (edit == 'red+') then
        red = math.min(255, red + 5);
    elseif (edit == 'green-') then
        green = math.max(0, green - 5);
    elseif (edit == 'green+') then
        green = math.min(255, green + 5);
    elseif (edit == 'blue-') then
        blue = math.max(0, blue - 5);
    elseif (edit == 'blue+') then
        blue = math.min(255, blue + 5);
    end

    color[1] = red / 255;
    color[2] = green / 255;
    color[3] = blue / 255;
    color[4] = tonumber(color[4]) or 1.0;

    return color;
end

local function DrawColorCell(label, color)
    imgui.TextColored(labelColor, label);
    imgui.TableNextColumn();
    return DrawColor(label:gsub('%s+', '_'), color);
end

local function DrawFontRow(settings, defaults, showSmallFontToggle)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (showSmallFontToggle == true) then
            if (imgui.BeginTable('##text_font_row', 4, tableFlags)) then
                imgui.TableSetupColumn('##font_size_label', 0, 145);
                imgui.TableSetupColumn('##font_size_control', 0, 170);
                imgui.TableSetupColumn('##font_color_label', 0, 145);
                imgui.TableSetupColumn('##font_color_control', 0, 240);
                imgui.TableNextRow();

                imgui.TableNextColumn();
                settings.textSize = DrawTableSlider('Font size', 'font_size', textScale.NormalizeSetting(settings.textSize, defaults.textSize), textScale.GetMinVisualSize(), textScale.GetMaxVisualSize());
                imgui.TableNextColumn();
                imgui.TextColored(labelColor, 'Font color');
                imgui.TableNextColumn();
                settings.color = DrawColor('font_color', settings.color);
                imgui.SameLine();
                settings.useSmallFont = DrawCheckbox('Small font', settings.useSmallFont);

                imgui.EndTable();
            end

            return;
        end

        if (imgui.BeginTable('##text_font_row', 4, tableFlags)) then
            imgui.TableSetupColumn('##font_size_label', 0, 145);
            imgui.TableSetupColumn('##font_size_control', 0, 170);
            imgui.TableSetupColumn('##font_color_label', 0, 145);
            imgui.TableSetupColumn('##font_color_control', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            settings.textSize = DrawTableSlider('Font size', 'font_size', textScale.NormalizeSetting(settings.textSize, defaults.textSize), textScale.GetMinVisualSize(), textScale.GetMaxVisualSize());
            imgui.TableNextColumn();
            settings.color = DrawColorCell('Font color', settings.color);
            imgui.EndTable();
        end

        return;
    end

    settings.textSize = DrawNumber('Font size', textScale.NormalizeSetting(settings.textSize, defaults.textSize), textScale.GetMinVisualSize(), textScale.GetMaxVisualSize(), 1);
    if (showSmallFontToggle == true) then
        imgui.SameLine();
    end
    settings.color = DrawColor('Font color', settings.color);

    if (showSmallFontToggle == true) then
        imgui.SameLine();
        settings.useSmallFont = DrawCheckbox('Small font', settings.useSmallFont);
    end
end

local function DrawOutlineRow(settings)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##text_outline_row', 4, tableFlags)) then
            imgui.TableSetupColumn('##outline_size_label', 0, 145);
            imgui.TableSetupColumn('##outline_size_control', 0, 170);
            imgui.TableSetupColumn('##outline_color_label', 0, 145);
            imgui.TableSetupColumn('##outline_color_control', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            settings.outlineSize = DrawTableSlider('Outline size', 'outline_size', settings.outlineSize, 0, 12, false);
            imgui.TableNextColumn();
            settings.outlineColor = DrawColorCell('Outline color', settings.outlineColor);
            imgui.EndTable();
        end

        return;
    end

    settings.outlineSize = DrawNumber('Outline size', settings.outlineSize, 0, 12, 1);
    settings.outlineColor = DrawColor('Outline color', settings.outlineColor);
end

local function ApplyDefaults(settings, defaults)
    for key, value in pairs(defaults or {}) do
        if (settings[key] == nil) then
            settings[key] = type(value) == 'table' and { unpackTable(value) } or value;
        end
    end
end

local function ResetSettings(settings, defaults)
    for key, value in pairs(defaults or {}) do
        settings[key] = type(value) == 'table' and { unpackTable(value) } or value;
    end
end

local function RequestReset(kind, label)
    pendingReset = {
        kind = kind,
        label = label,
    };

    if (imgui.OpenPopup ~= nil) then
        imgui.OpenPopup('Reset text##libraplates_text_reset_confirm');
    end
end

local function DrawResetConfirm(settings, defaults, label)
    if (pendingReset == nil) then
        return;
    end

    if (imgui.BeginPopupModal == nil) then
        imgui.TextColored({ 0.20, 0.65, 0.67, 1.0 }, 'Reset ' .. pendingReset.label .. '?');

        if (ClickText('Cancel', actionColor) == true) then
            pendingReset = nil;
        end

        imgui.SameLine();

        if (ClickText('Confirm reset', actionColor) == true) then
            if (pendingReset.kind == 'position') then
                settings.offsetX = defaults.offsetX;
                settings.offsetY = defaults.offsetY;
            else
                ResetSettings(settings, defaults);
            end

            pendingReset = nil;
        end

        return;
    end

    if (imgui.BeginPopupModal('Reset text##libraplates_text_reset_confirm')) then
        imgui.Text('Reset ' .. pendingReset.label .. '?');

        if (pendingReset.kind == 'position') then
            imgui.Text('This will reset Position X and Position Y.');
        else
            imgui.Text('This will reset all ' .. label .. ' settings.');
        end

        imgui.Separator();

        if (imgui.Button('Cancel##text_reset_cancel')) then
            pendingReset = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.SameLine();

        if (imgui.Button('Reset##text_reset_confirm')) then
            if (pendingReset.kind == 'position') then
                settings.offsetX = defaults.offsetX;
                settings.offsetY = defaults.offsetY;
            else
                ResetSettings(settings, defaults);
            end

            pendingReset = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.EndPopup();
    end
end

local function DrawAnchorCombo(label, current, choices)
    local value = tostring(current or 'Plate');

    if (value == 'Plate') then
        value = 'None';
    end

    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.BeginCombo('##text_anchor_' .. label, value) == true) then
            for _, choice in ipairs(choices or {}) do
                local selected = (value == tostring(choice));

                if (imgui.Selectable(tostring(choice), selected) == true) then
                    value = tostring(choice);
                end
            end

            imgui.EndCombo();
        end
    else
        imgui.TextColored(valueColor, value);
    end

    if (value == 'None') then
        return 'Plate';
    end

    return value;
end

local function DrawAnchorControls(settings, context, label)
    anchorControls.Draw(settings, context, label);
end

function textWidget.DrawSettings(settings, context)
    if (settings == nil) then
        return;
    end

    local defaults = context ~= nil and context.defaults or {};
    local label = tostring(context ~= nil and context.widget or 'Text');

    ApplyDefaults(settings, defaults);

    if (context == nil or context.hideActive ~= true) then
        settings.enabled = DrawCheckbox('Active', settings.enabled);
    end
    local showSmallFontToggle = (context ~= nil and context.showSmallFontToggle == true) or label == 'Distance';

    DrawAnchorControls(settings, context, label);

    settings.offsetX, settings.offsetY = DrawSliderPair(
        'position',
        'Position X',
        'offset_x',
        settings.offsetX,
        -400,
        400,
        'Position Y',
        'offset_y',
        settings.offsetY,
        -400,
        400
    );
    DrawFontRow(settings, defaults, showSmallFontToggle);
    DrawOutlineRow(settings);
    settings.outlineEnabled = (tonumber(settings.outlineSize) or 0) > 0;

    if (context ~= nil and type(context.extraBeforeReset) == 'function') then
        context.extraBeforeReset(settings, defaults);
    end

    imgui.Separator();

    if (DrawActionButton('Reset ' .. label .. ' position') == true) then
        RequestReset('position', label .. ' position');
    end

    if (DrawActionButton('Reset ' .. label .. ' settings') == true) then
        RequestReset('settings', label .. ' settings');
    end

    DrawResetConfirm(settings, defaults, label);
end

return textWidget;
