local baseDefaults = require('config.widgets.bar');
local barTextures = require('core.bar_textures');
local barAnimations = require('core.bar_animations');
local textScale = require('core.text_scale');
local imgui = require('imgui');
local anchorControls = require('modules.widgets.anchor_controls');
local uiTooltip = require('core.ui_tooltip');

local bar = {};
local unpackTable = table.unpack or unpack;
local labelColor = { 0.92, 0.92, 0.90, 1.0 };
local valueColor = { 0.65, 0.90, 1.0, 1.0 };
local actionColor = { 1.0, 0.84, 0.0, 1.0 };
local colorEditFlags = bit ~= nil and bit.bor ~= nil
    and bit.bor(_G.ImGuiColorEditFlags_NoAlpha or 0, _G.ImGuiColorEditFlags_NoInputs or 0)
    or ((_G.ImGuiColorEditFlags_NoAlpha or 0) + (_G.ImGuiColorEditFlags_NoInputs or 0));
local tableFlags = (_G.ImGuiTableFlags_SizingFixedFit or 0) + (_G.ImGuiTableFlags_BordersInnerH or 0);
local pairLabelWidth = 158;
local pairControlWidth = 180;
local colorLabelWidth = 142;
local colorControlWidth = 62;
local pendingReset = nil;
local heldButtonState = {};

local function DrawSectionHeader(label)
    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.18);
    end

    imgui.TextColored(actionColor, tostring(label or ''));

    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.0);
    end
end

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

local function DrawInlineToggle(label, value)
    local result = DrawToggle(label, value);
    imgui.SameLine();
    imgui.Spacing();
    imgui.SameLine();
    imgui.Spacing();
    imgui.SameLine();
    return result;
end

local function DrawRadio(label, selected)
    if (imgui.RadioButton ~= nil) then
        return imgui.RadioButton(tostring(label), selected == true) == true;
    end

    local marker = (selected == true) and '(*) ' or '( ) ';
    return ClickText(marker .. tostring(label), selected == true and actionColor or labelColor) == true;
end

local function DrawNumber(label, value, minValue, maxValue, step)
    local current = tonumber(value) or 0;
    local amount = 1;

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

    heldButtonState[key] = nil;
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
        if (IsHeldButton('-##bar_' .. id .. '_minus')) then
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
        imgui.InputText('##bar_' .. id, ref, 16);
    else
        imgui.SliderInt('##bar_' .. id, ref, minimum, maximum);
    end

    if (imgui.PopItemWidth ~= nil) then
        imgui.PopItemWidth();
    end

    current = tonumber(ref[1]) or current;

    if (showButtons ~= false and imgui.Button ~= nil) then
        imgui.SameLine();

        if (IsHeldButton('+##bar_' .. id .. '_plus')) then
            current = current + 1;
        end
    end

    if (minValue ~= nil and current < minValue) then current = minValue; end
    if (maxValue ~= nil and current > maxValue) then current = maxValue; end

    return current;
end

local function DrawTableSlider(label, id, value, minValue, maxValue, showButtons, width)
    imgui.TextColored(labelColor, label);
    imgui.TableNextColumn();
    return DrawSliderControl(id, value, minValue, maxValue, width or (showButtons == false and 140 or 95), showButtons);
end

local function DrawSingleSlider(label, id, value, minValue, maxValue, showButtons, labelWidth, controlWidth, suffix, numericWidth)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local result = value;
        local hasSuffix = suffix ~= nil and tostring(suffix) ~= '';

        if (imgui.BeginTable('##bar_' .. id .. '_row', 2, tableFlags)) then
            imgui.TableSetupColumn('##label', 0, labelWidth or pairLabelWidth);
            imgui.TableSetupColumn('##control', 0, (controlWidth or 170) + (hasSuffix and 32 or 0));
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, label);
            imgui.TableNextColumn();
            local sliderWidth = numericWidth or ((showButtons == false) and (hasSuffix and 95 or 140) or 95);
            result = DrawSliderControl(id, value, minValue, maxValue, sliderWidth, showButtons);
            if (hasSuffix == true) then
                imgui.SameLine();
                local suffixText = tostring(suffix);
                imgui.TextColored(labelColor, suffixText == '%' and '%%' or suffixText);
            end
            imgui.EndTable();
        end

        return result;
    end

    imgui.TextColored(labelColor, label);
    imgui.SameLine();
    local sliderWidth = numericWidth or ((showButtons == false) and ((suffix ~= nil and tostring(suffix) ~= '') and 95 or 140) or 95);
    local result = DrawSliderControl(id, value, minValue, maxValue, sliderWidth, showButtons);
    if (suffix ~= nil and tostring(suffix) ~= '') then
        imgui.SameLine();
        local suffixText = tostring(suffix);
        imgui.TextColored(labelColor, suffixText == '%' and '%%' or suffixText);
    end
    return result;
end

local function DrawSliderPair(rowId, leftLabel, leftId, leftValue, leftMin, leftMax, rightLabel, rightId, rightValue, rightMin, rightMax, labelWidth, controlWidth, numericWidth)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local leftResult = leftValue;
        local rightResult = rightValue;

        if (imgui.BeginTable('##bar_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##label_left', 0, tonumber(labelWidth) or pairLabelWidth);
            imgui.TableSetupColumn('##control_left', 0, tonumber(controlWidth) or pairControlWidth);
            imgui.TableSetupColumn('##label_right', 0, tonumber(labelWidth) or pairLabelWidth);
            imgui.TableSetupColumn('##control_right', 0, tonumber(controlWidth) or pairControlWidth);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            leftResult = DrawTableSlider(leftLabel, leftId, leftValue, leftMin, leftMax, true, tonumber(numericWidth) or 95);
            imgui.TableNextColumn();
            rightResult = DrawTableSlider(rightLabel, rightId, rightValue, rightMin, rightMax, true, tonumber(numericWidth) or 95);
            imgui.EndTable();
        end

        return leftResult, rightResult;
    end

    local leftResult = DrawNumber(leftLabel, leftValue, leftMin, leftMax, 1);
    imgui.SameLine();
    local rightResult = DrawNumber(rightLabel, rightValue, rightMin, rightMax, 1);
    return leftResult, rightResult;
end

local function DrawChoice(label, value, options, id, width)
    local current = tostring(value or options[1]);
    local comboId = '##bar_' .. tostring(id or label or 'choice');
    local currentAllowed = false;

    for _, option in ipairs(options) do
        if (option == current) then
            currentAllowed = true;
            break;
        end
    end

    if (currentAllowed ~= true) then
        current = options[1];
    end

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(width or 230);
        end

        if (imgui.BeginCombo(comboId, current) == true) then
            for _, option in ipairs(options) do
                local selected = (option == current);

                if (imgui.Selectable(tostring(option), selected) == true) then
                    current = option;
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

        return current;
    end

    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (ClickText(current, valueColor) ~= true) then
        return current;
    end

    for index, option in ipairs(options) do
        if (option == current) then
            local nextIndex = index + 1;

            if (nextIndex > #options) then
                nextIndex = 1;
            end

            return options[nextIndex];
        end
    end

    return options[1];
end

local function DrawBarTexturePreviewTooltip(style)
    if (imgui.IsItemHovered == nil or imgui.IsItemHovered() ~= true) then
        return;
    end

    local textureId = barTextures.GetTextureId(style);

    if (
        textureId ~= nil and
        imgui.BeginTooltip ~= nil and
        imgui.EndTooltip ~= nil and
        imgui.Image ~= nil
    ) then
        imgui.BeginTooltip();
        imgui.Text(tostring(style or ''));
        imgui.Image(textureId, { 220, 32 }, { 0, 0 }, { 1, 1 });
        imgui.EndTooltip();
    elseif (imgui.SetTooltip ~= nil) then
        imgui.SetTooltip(tostring(style or ''));
    end
end

local function DrawBarTextureChoice(value, id, width)
    local options = barTextures.GetOptions();
    local current = tostring(value or options[1] or 'Solid');
    local currentAllowed = false;

    for _, option in ipairs(options) do
        if (option == current) then
            currentAllowed = true;
            break;
        end
    end

    if (currentAllowed ~= true) then
        current = options[1] or 'Solid';
    end

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(width or 170);
        end

        local comboOpen = imgui.BeginCombo('##bar_' .. tostring(id or 'texture'), current) == true;
        DrawBarTexturePreviewTooltip(current);

        if (comboOpen == true) then
            for _, option in ipairs(options) do
                local selected = (option == current);

                if (imgui.Selectable(tostring(option), selected) == true) then
                    current = option;
                end
                DrawBarTexturePreviewTooltip(option);

                if (selected == true and imgui.SetItemDefaultFocus ~= nil) then
                    imgui.SetItemDefaultFocus();
                end
            end

            imgui.EndCombo();
        end

        if (imgui.PopItemWidth ~= nil) then
            imgui.PopItemWidth();
        end

        return current;
    end

    return DrawChoice('Texture', value, options, id, width);
end

local function ColorToU32(color, fallback)
    local source = color or fallback or { 1.0, 1.0, 1.0, 1.0 };
    local function Clamp(value)
        value = tonumber(value) or 0;
        if (value < 0) then return 0; end
        if (value > 1) then return 1; end
        return value;
    end

    local red = math.floor(Clamp(source[1]) * 255);
    local green = math.floor(Clamp(source[2]) * 255);
    local blue = math.floor(Clamp(source[3]) * 255);
    local alpha = math.floor(Clamp(source[4] or 1.0) * 255);

    return (alpha * 0x1000000) + (blue * 0x10000) + (green * 0x100) + red;
end

local function DrawAnimationPreviewTooltip(style, speed, animationColor, fillColor, backgroundColor)
    if (imgui.IsItemHovered == nil or imgui.IsItemHovered() ~= true) then
        return;
    end

    local animationName = tostring(style or 'None');
    if (animationName == 'Blink') then
        animationName = 'Pulse';
    end
    local textureId = barAnimations.GetTextureId(animationName);

    if (
        animationName ~= 'None' and
        (textureId ~= nil or animationName == 'Pulse') and
        imgui.BeginTooltip ~= nil and
        imgui.EndTooltip ~= nil and
        imgui.GetWindowDrawList ~= nil and
        imgui.GetCursorScreenPos ~= nil
    ) then
        imgui.BeginTooltip();
        imgui.Text(animationName);

        local width = 220;
        local height = 28;
        local progress = 0.72;
        local x, y = imgui.GetCursorScreenPos();
        local drawList = imgui.GetWindowDrawList();
        local fillWidth = width * progress;

        drawList:AddRectFilled({ x, y }, { x + width, y + height }, ColorToU32(backgroundColor, { 0.10, 0.11, 0.13, 1.0 }), 0);
        drawList:AddRectFilled({ x, y }, { x + fillWidth, y + height }, ColorToU32(fillColor, { 1.0, 0.0, 0.0, 1.0 }), 0);

        if (animationName == 'Pulse') then
            local previewSpeed = tonumber(speed) or 40;
            local rate = math.max(0.2, previewSpeed / 40);
            local pulse = 0.10 + (0.30 * ((math.sin(os.clock() * rate * math.pi * 2) + 1) * 0.5));
            drawList:AddRectFilled({ x, y }, { x + fillWidth, y + height }, ColorToU32({ 1.0, 1.0, 1.0, pulse }), 0);
        else
            local tileWidth = math.max(height, height * 3.64);
            local offset = (os.clock() * (tonumber(speed) or 40)) % tileWidth;
            local tileX = x - offset;

            while (tileX < (x + fillWidth)) do
                local drawX = math.max(tileX, x);
                local drawRight = math.min(tileX + tileWidth, x + fillWidth);
                local drawWidth = drawRight - drawX;

                if (drawWidth > 0 and drawList.AddImage ~= nil) then
                    drawList:AddImage(
                        textureId,
                        { drawX, y },
                        { drawX + drawWidth, y + height },
                        { 0, 0 },
                        { drawWidth / tileWidth, 1 },
                        ColorToU32(animationColor, { 1.0, 1.0, 1.0, 0.35 })
                    );
                end

                tileX = tileX + tileWidth;
            end
        end

        drawList:AddRect({ x, y }, { x + width, y + height }, ColorToU32({ 1.0, 1.0, 1.0, 0.35 }), 0);
        if (imgui.Dummy ~= nil) then
            imgui.Dummy({ width, height });
        end
        imgui.EndTooltip();
    elseif (imgui.SetTooltip ~= nil) then
        imgui.SetTooltip(animationName);
    end
end

local GetAnimationOptions = nil;

local function DrawAnimationChoice(value, id, speed, animationColor, fillColor, backgroundColor, width)
    local options = GetAnimationOptions();
    local current = tostring(value or 'None');
    if (current == 'Blink') then
        current = 'Pulse';
    end
    local currentAllowed = false;

    for _, option in ipairs(options) do
        if (option == current) then
            currentAllowed = true;
            break;
        end
    end

    if (currentAllowed ~= true) then
        current = 'None';
    end

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(width or 170);
        end

        local comboOpen = imgui.BeginCombo('##bar_' .. tostring(id or 'animation'), current) == true;
        DrawAnimationPreviewTooltip(current, speed, animationColor, fillColor, backgroundColor);

        if (comboOpen == true) then
            for _, option in ipairs(options) do
                local selected = option == current;

                if (imgui.Selectable(tostring(option), selected) == true) then
                    current = option;
                end
                DrawAnimationPreviewTooltip(option, speed, animationColor, fillColor, backgroundColor);

                if (selected == true and imgui.SetItemDefaultFocus ~= nil) then
                    imgui.SetItemDefaultFocus();
                end
            end

            imgui.EndCombo();
        end

        if (imgui.PopItemWidth ~= nil) then
            imgui.PopItemWidth();
        end

        return current;
    end

    return DrawChoice('Warning animation', current, options, id, width);
end

local function DrawComboRow(label, value, options, id, comboWidth, labelWidth, controlWidth)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local result = value;

        if (imgui.BeginTable('##bar_' .. tostring(id or label or 'combo') .. '_row', 2, tableFlags)) then
            imgui.TableSetupColumn('##label', 0, tonumber(labelWidth) or pairLabelWidth);
            imgui.TableSetupColumn('##control', 0, tonumber(controlWidth) or 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, label);
            imgui.TableNextColumn();
            result = DrawChoice(label, value, options, id, comboWidth);
            imgui.EndTable();
        end

        return result;
    end

    imgui.TextColored(labelColor, label);
    imgui.SameLine();
    return DrawChoice(label, value, options, id);
end

local function DrawAnchorCombo(label, current, choices)
    local value = tostring(current or 'Plate');

    if (value == 'Plate') then
        value = 'None';
    end

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.BeginCombo('##bar_anchor_' .. label, value) == true) then
            for _, choice in ipairs(choices or {}) do
                local selected = (value == tostring(choice));

                if (imgui.Selectable(tostring(choice), selected) == true) then
                    value = tostring(choice);
                end
            end

            imgui.EndCombo();
        end
    else
        imgui.TextColored(labelColor, label);
        imgui.SameLine();
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

local function ClampColorChannel(value)
    local channel = tonumber(value) or 0;

    if (channel < 0) then return 0; end
    if (channel > 1) then return 1; end

    return channel;
end

local function DrawColor(label, value)
    local color = value or { 1.0, 1.0, 1.0, 1.0 };
    color[4] = tonumber(color[4]) or 1.0;
    local red = math.floor(ClampColorChannel(color[1]) * 255);
    local green = math.floor(ClampColorChannel(color[2]) * 255);
    local blue = math.floor(ClampColorChannel(color[3]) * 255);
    local edit = nil;

    if (imgui.ColorEdit4 ~= nil) then
        imgui.ColorEdit4('##bar_' .. label, color, colorEditFlags);
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
        red = math.max(0, red - 1);
    elseif (edit == 'red+') then
        red = math.min(255, red + 1);
    elseif (edit == 'green-') then
        green = math.max(0, green - 1);
    elseif (edit == 'green+') then
        green = math.min(255, green + 1);
    elseif (edit == 'blue-') then
        blue = math.max(0, blue - 1);
    elseif (edit == 'blue+') then
        blue = math.min(255, blue + 1);
    end

    color[1] = red / 255;
    color[2] = green / 255;
    color[3] = blue / 255;
    color[4] = tonumber(color[4]) or 1.0;

    return color;
end

local function DrawColorCell(label, id, color)
    imgui.TextColored(labelColor, label);
    imgui.TableNextColumn();
    return DrawColor(id, color);
end

local function DrawColorPair(rowId, leftLabel, leftId, leftValue, rightLabel, rightId, rightValue, labelWidth, controlWidth)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local leftResult = leftValue;
        local rightResult = rightValue;

        if (imgui.BeginTable('##bar_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##label_left', 0, tonumber(labelWidth) or pairLabelWidth);
            imgui.TableSetupColumn('##control_left', 0, tonumber(controlWidth) or pairControlWidth);
            imgui.TableSetupColumn('##label_right', 0, tonumber(labelWidth) or pairLabelWidth);
            imgui.TableSetupColumn('##control_right', 0, tonumber(controlWidth) or pairControlWidth);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            leftResult = DrawColorCell(leftLabel, leftId, leftValue);
            imgui.TableNextColumn();
            rightResult = DrawColorCell(rightLabel, rightId, rightValue);
            imgui.EndTable();
        end

        return leftResult, rightResult;
    end

    imgui.TextColored(labelColor, leftLabel);
    imgui.SameLine();
    local leftResult = DrawColor(leftId, leftValue);
    imgui.SameLine();
    imgui.TextColored(labelColor, rightLabel);
    imgui.SameLine();
    local rightResult = DrawColor(rightId, rightValue);
    return leftResult, rightResult;
end

local function DrawColorTextureRow(rowId, fillColor, backgroundColor, texture, textureStrength, labelWidth, controlWidth, numericWidth)
    local nextFillColor = fillColor;
    local nextBackgroundColor = backgroundColor;
    local nextTexture = texture;
    local nextTextureStrength = tonumber(textureStrength) or 100;
    local key = tostring(rowId or 'color_texture');

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        nextFillColor, nextBackgroundColor = DrawColorPair(key .. '_colors', 'Fill color', key .. '_fill_color', fillColor, 'BG color', key .. '_bg_color', backgroundColor, labelWidth, controlWidth);

        if (imgui.BeginTable('##bar_' .. key .. '_texture_strength', 4, tableFlags)) then
            imgui.TableSetupColumn('##label_left', 0, tonumber(labelWidth) or pairLabelWidth);
            imgui.TableSetupColumn('##control_left', 0, tonumber(controlWidth) or pairControlWidth);
            imgui.TableSetupColumn('##label_right', 0, tonumber(labelWidth) or pairLabelWidth);
            imgui.TableSetupColumn('##control_right', 0, tonumber(controlWidth) or pairControlWidth);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Texture');
            imgui.TableNextColumn();
            nextTexture = DrawBarTextureChoice(texture, key .. '_texture', 170);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Strength');
            imgui.TableNextColumn();
            nextTextureStrength = DrawSliderControl(key .. '_texture_strength', nextTextureStrength, 0, 100, tonumber(numericWidth) or 95, true);
            imgui.EndTable();
        end

        return nextFillColor, nextBackgroundColor, nextTexture, nextTextureStrength;
    end

    imgui.TextColored(labelColor, 'Fill color');
    imgui.SameLine();
    nextFillColor = DrawColor(key .. '_fill_color', fillColor);
    imgui.SameLine();
    imgui.TextColored(labelColor, 'BG color');
    imgui.SameLine();
    nextBackgroundColor = DrawColor(key .. '_bg_color', backgroundColor);
    imgui.SameLine();
    imgui.TextColored(labelColor, 'Texture');
    imgui.SameLine();
    nextTexture = DrawChoice('Texture', texture, barTextures.GetOptions(), key .. '_texture');
    NewLine();
    imgui.TextColored(labelColor, 'Strength');
    imgui.SameLine();
    nextTextureStrength = DrawSliderControl(key .. '_texture_strength', nextTextureStrength, 0, 100, 95, true);

    return nextFillColor, nextBackgroundColor, nextTexture, nextTextureStrength;
end

local function DrawBorderRow(rowId, borderColor, borderSize, labelWidth, controlWidth, rightLabelWidth, numericWidth)
    local nextBorderColor = borderColor;
    local nextBorderSize = borderSize;
    local key = tostring(rowId or 'border');
    local leftLabelWidth = labelWidth or colorLabelWidth;
    local leftControlWidth = controlWidth or colorControlWidth;
    local sizeLabelWidth = rightLabelWidth or colorLabelWidth;
    local sizeControlWidth = controlWidth or pairControlWidth;
    local sizeNumericWidth = numericWidth or 95;

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##bar_' .. key, 4, tableFlags)) then
            imgui.TableSetupColumn('##color_label', 0, leftLabelWidth);
            imgui.TableSetupColumn('##color_control', 0, leftControlWidth);
            imgui.TableSetupColumn('##size_label', 0, sizeLabelWidth);
            imgui.TableSetupColumn('##size_control', 0, sizeControlWidth);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Border color');
            imgui.TableNextColumn();
            nextBorderColor = DrawColor(key .. '_color', borderColor);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Border size');
            imgui.TableNextColumn();
            nextBorderSize = DrawSliderControl(key .. '_size', borderSize, 0, 24, sizeNumericWidth, true);
            imgui.EndTable();
        end

        return nextBorderColor, nextBorderSize;
    end

    imgui.TextColored(labelColor, 'Border color');
    imgui.SameLine();
    nextBorderColor = DrawColor(key .. '_color', borderColor);
    imgui.SameLine();
    imgui.TextColored(labelColor, 'Border size');
    imgui.SameLine();
    nextBorderSize = DrawSliderControl(key .. '_size', borderSize, 0, 24, 95, true);

    return nextBorderColor, nextBorderSize;
end

local function DrawSectionOptionsRow(rowId, sectionGap, section2Color, section3Color, defaults, baseColor)
    local nextGap = sectionGap;
    local nextColor2 = section2Color;
    local nextColor3 = section3Color;
    local key = tostring(rowId or 'sections');

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##bar_' .. key, 6, tableFlags)) then
            imgui.TableSetupColumn('##gap_label', 0, 42);
            imgui.TableSetupColumn('##gap_control', 0, 154);
            imgui.TableSetupColumn('##color2_label', 0, 82);
            imgui.TableSetupColumn('##color2_control', 0, 42);
            imgui.TableSetupColumn('##color3_label', 0, 82);
            imgui.TableSetupColumn('##color3_control', 0, 42);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Gap');
            imgui.TableNextColumn();
            nextGap = DrawSliderControl(key .. '_gap', sectionGap, 0, 24, 95, true);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Section 2');
            imgui.TableNextColumn();
            nextColor2 = DrawColor(key .. '_color2', section2Color or defaults.color2 or baseColor);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Section 3');
            imgui.TableNextColumn();
            nextColor3 = DrawColor(key .. '_color3', section3Color or defaults.color3 or baseColor);
            imgui.EndTable();
        end

        return nextGap, nextColor2, nextColor3;
    end

    imgui.TextColored(labelColor, 'Section gap');
    imgui.SameLine();
    nextGap = DrawSliderControl(key .. '_gap', sectionGap, 0, 24, 78, true);
    imgui.SameLine();
    imgui.TextColored(labelColor, 'Section 2');
    imgui.SameLine();
    nextColor2 = DrawColor(key .. '_color2', section2Color or defaults.color2 or baseColor);
    imgui.SameLine();
    imgui.TextColored(labelColor, 'Section 3');
    imgui.SameLine();
    nextColor3 = DrawColor(key .. '_color3', section3Color or defaults.color3 or baseColor);

    return nextGap, nextColor2, nextColor3;
end

local function DrawLowWarningRow(rowId, percentValue, warningColor)
    local nextPercent = percentValue;
    local nextColor = warningColor;
    local key = tostring(rowId or 'low_warning');

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##bar_' .. key, 6, tableFlags)) then
            imgui.TableSetupColumn('##warn_label', 0, 70);
            imgui.TableSetupColumn('##warn_control', 0, 128);
            imgui.TableSetupColumn('##warn_suffix', 0, 78);
            imgui.TableSetupColumn('##color_label', 0, 128);
            imgui.TableSetupColumn('##color_control', 0, 34);
            imgui.TableSetupColumn('##spacer', 0, 1);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Warn at');
            imgui.TableNextColumn();
            nextPercent = DrawSliderControl(key .. '_percent', percentValue, 1, 100, 68, true);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, '%');
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Bar color');
            imgui.TableNextColumn();
            nextColor = DrawColor(key .. '_color', warningColor);
            imgui.EndTable();
        end

        return nextPercent, nextColor;
    end

    imgui.TextColored(labelColor, 'Warn at');
    imgui.SameLine();
    nextPercent = DrawSliderControl(key .. '_percent', percentValue, 1, 100, 95, true);
    imgui.SameLine();
    imgui.TextColored(labelColor, '%');
    imgui.SameLine();
    imgui.TextColored(labelColor, 'Bar color');
    imgui.SameLine();
    nextColor = DrawColor(key .. '_color', warningColor);

    return nextPercent, nextColor;
end

local function DrawToggleGroupRow(rowId, items)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##bar_' .. tostring(rowId or 'toggles'), #items, tableFlags)) then
            for index = 1, #items do
                imgui.TableSetupColumn('##toggle_' .. tostring(index), 0, 190);
            end

            imgui.TableNextRow();

            for _, item in ipairs(items) do
                imgui.TableNextColumn();
                item.value = DrawToggle(item.label, item.value);
            end

            imgui.EndTable();
        end

        return;
    end

    for index, item in ipairs(items) do
        if (index < #items) then
            item.value = DrawInlineToggle(item.label, item.value);
        else
            item.value = DrawToggle(item.label, item.value);
        end
    end
end

local function DrawFontRow(settings, defaults, idPrefix, labelWidth, controlWidth, numericWidth, rightLabelWidth)
    idPrefix = tostring(idPrefix or '');
    labelWidth = labelWidth or pairLabelWidth;
    rightLabelWidth = rightLabelWidth or labelWidth;
    controlWidth = controlWidth or pairControlWidth;
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##bar_' .. idPrefix .. 'font_row', 4, tableFlags)) then
            imgui.TableSetupColumn('##font_size_label', 0, labelWidth);
            imgui.TableSetupColumn('##font_size_control', 0, controlWidth);
            imgui.TableSetupColumn('##font_color_label', 0, rightLabelWidth);
            imgui.TableSetupColumn('##font_color_control', 0, colorControlWidth);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            settings.fontSize = DrawTableSlider('Font size', idPrefix .. 'font_size', textScale.NormalizeSetting(settings.fontSize, defaults.fontSize), textScale.GetMinVisualSize(), textScale.GetMaxVisualSize(), true, numericWidth);
            imgui.TableNextColumn();
            settings.textColor = DrawColorCell('Font color', 'font_color', settings.textColor);
            imgui.EndTable();
        end

        return;
    end

    settings.fontSize = DrawNumber('Font size', textScale.NormalizeSetting(settings.fontSize, defaults.fontSize), textScale.GetMinVisualSize(), textScale.GetMaxVisualSize(), 1);
    settings.textColor = DrawColor('font_color', settings.textColor);
end

local function DrawOutlineRow(settings, idPrefix, labelWidth, controlWidth, numericWidth, rightLabelWidth)
    idPrefix = tostring(idPrefix or '');
    labelWidth = labelWidth or pairLabelWidth;
    rightLabelWidth = rightLabelWidth or labelWidth;
    controlWidth = controlWidth or pairControlWidth;
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##bar_' .. idPrefix .. 'outline_row', 4, tableFlags)) then
            imgui.TableSetupColumn('##outline_size_label', 0, labelWidth);
            imgui.TableSetupColumn('##outline_size_control', 0, controlWidth);
            imgui.TableSetupColumn('##outline_color_label', 0, rightLabelWidth);
            imgui.TableSetupColumn('##outline_color_control', 0, colorControlWidth);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            settings.textOutlineSize = DrawTableSlider('Outline size', idPrefix .. 'outline_size', settings.textOutlineSize, 0, 12, true, numericWidth);
            imgui.TableNextColumn();
            settings.textOutlineColor = DrawColorCell('Outline color', 'outline_color', settings.textOutlineColor);
            imgui.EndTable();
        end

        return;
    end

    settings.textOutlineSize = DrawNumber('Outline size', settings.textOutlineSize, 0, 12, 1);
    settings.textOutlineColor = DrawColor('outline_color', settings.textOutlineColor);
end

local function ApplyDefaults(settings, defaults)
    for key, value in pairs(defaults or baseDefaults) do
        if (settings[key] == nil) then
            settings[key] = type(value) == 'table' and { unpackTable(value) } or value;
        end
    end
end

local function ResetSettings(settings, defaults)
    for key, value in pairs(defaults or baseDefaults) do
        settings[key] = type(value) == 'table' and { unpackTable(value) } or value;
    end
end

local function RequestReset(kind, label)
    pendingReset = {
        kind = kind,
        label = label,
    };

    if (imgui.OpenPopup ~= nil) then
        imgui.OpenPopup('Reset bar##libraplates_bar_reset_confirm');
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

    if (imgui.BeginPopupModal('Reset bar##libraplates_bar_reset_confirm')) then
        imgui.Text('Reset ' .. pendingReset.label .. '?');

        if (pendingReset.kind == 'position') then
            imgui.Text('This will reset Position X and Position Y.');
        else
            imgui.Text('This will reset all ' .. label .. ' settings.');
        end

        imgui.Separator();

        if (imgui.Button('Cancel##bar_reset_cancel')) then
            pendingReset = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.SameLine();

        if (imgui.Button('Reset##bar_reset_confirm')) then
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

GetAnimationOptions = function()
    local options = T{ 'None' };

    for _, option in ipairs(barAnimations.GetOptions()) do
        options[#options + 1] = option;
    end

    return options;
end

-- ============================================================
-- Defaults
-- ============================================================

function bar.GetDefaults()
    return baseDefaults;
end

-- ============================================================
-- Settings UI
-- ============================================================

function bar.DrawSettings(settings, context)
    if (settings == nil) then
        return;
    end

    local label = tostring(context ~= nil and context.widget or 'Bar');
    local resourceName = tostring(context ~= nil and context.resourceName or 'HP');
    local idPrefix = tostring(label .. '_' .. resourceName):gsub('[^%w_]', '_') .. '_';
    local defaults = context ~= nil and context.defaults or baseDefaults;
    local isSegmentedResource = (
        resourceName == 'TP' or
        resourceName == 'Ready' or
        (context ~= nil and context.segmentedResource == true)
    );
    local showLowState = (
        (context == nil or context.hideLowState ~= true) and
        resourceName ~= 'TP' and
        resourceName ~= 'Ready' and
        resourceName ~= 'Sic' and
        resourceName ~= 'Reward' and
        resourceName ~= 'Ward' and
        resourceName ~= 'Rage' and
        resourceName ~= 'Favor'
    );
    local labelIconOptions = context ~= nil and context.labelIconOptions == true;
    local boxedSettings = context ~= nil and context.boxed == true;
    local boxedResourceBar = context ~= nil and context.boxed == true and (label == 'HP Bar' or label == 'MP Bar' or label == 'TP Bar');

    ApplyDefaults(settings, defaults);

    if (resourceName == 'HP') then
        if (settings.criticalColorEnabled == nil) then
            settings.criticalColorEnabled = defaults.criticalColorEnabled ~= false;
        end
        if (settings.criticalColorPercent == nil) then
            settings.criticalColorPercent = tonumber(defaults.criticalColorPercent) or 25;
        end
        if (settings.criticalColor == nil) then
            settings.criticalColor = defaults.criticalColor or { 1.0, 0.15, 0.10, 1.0 };
        end
    end

    if (context == nil or context.hideActive ~= true) then
        settings.enabled = DrawToggle('Active', settings.enabled);
    end

    if (context == nil or context.skipPlacement ~= true) then
        DrawAnchorControls(settings, context, label);
    end

    if (context ~= nil and context.onlyPlacement == true) then
        return;
    end

    local function DrawPanel(panelLabel, render, first)
        if (boxedSettings == true and _G.LibraPlatesSettingsDrawBoxedPanel ~= nil) then
            _G.LibraPlatesSettingsDrawBoxedPanel(panelLabel, render, first);
            return;
        end

        render();
    end

    local function DrawInnerBreak()
        if (boxedResourceBar == true) then
            if (imgui.Spacing ~= nil) then
                imgui.Spacing();
                imgui.Spacing();
            end
            return;
        end

        imgui.Separator();
    end

    local function DrawInnerHeader(text)
        if (boxedResourceBar == true) then
            return;
        end

        DrawSectionHeader(text);
    end

    if (boxedResourceBar == true) then
        local resourceLabel = resourceName;
        local barLabelWidth = 125;
        local barRightLabelWidth = 125;
        local barControlWidth = 125;
        local barNumericWidth = 58;
        local barComboWidth = 108;

        local function DrawHpToggleRows(rowId, items)
            if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
                if (imgui.BeginTable('##bar_hp_' .. rowId, 4, tableFlags)) then
                    imgui.TableSetupColumn('##label_left', 0, barLabelWidth);
                    imgui.TableSetupColumn('##control_left', 0, barControlWidth);
                    imgui.TableSetupColumn('##label_right', 0, barRightLabelWidth);
                    imgui.TableSetupColumn('##control_right', 0, barControlWidth);

                    for index, item in ipairs(items) do
                        if index % 2 == 1 then
                            imgui.TableNextRow();
                            imgui.TableNextColumn();
                        end

                        imgui.TextColored(labelColor, item.label);
                        imgui.TableNextColumn();
                        item.value = DrawToggle('##bar_hp_' .. rowId .. '_' .. tostring(index), item.value);

                        if index % 2 == 1 then
                            imgui.TableNextColumn();
                        end
                    end

                    imgui.EndTable();
                end
                return;
            end

            DrawToggleGroupRow(rowId, items);
        end

        local function DrawHpLabeledToggle(rowId, toggleLabel, value)
            local items = { { label = toggleLabel, value = value } };
            DrawHpToggleRows(rowId, items);
            return items[1].value;
        end

        local function DrawHpLowWarningRow(rowId, percentValue, warningColor)
            if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
                if (imgui.BeginTable('##bar_hp_' .. rowId, 4, tableFlags)) then
                    imgui.TableSetupColumn('##label_left', 0, barLabelWidth);
                    imgui.TableSetupColumn('##control_left', 0, barControlWidth);
                    imgui.TableSetupColumn('##label_right', 0, barRightLabelWidth);
                    imgui.TableSetupColumn('##control_right', 0, barControlWidth);
                    imgui.TableNextRow();
                    imgui.TableNextColumn();
                    imgui.TextColored(labelColor, 'Warn at');
                    imgui.TableNextColumn();
                    percentValue = DrawSliderControl(rowId .. '_percent', percentValue, 1, 100, barNumericWidth, true);
                    imgui.SameLine();
                    imgui.TextColored(labelColor, '%');
                    imgui.TableNextColumn();
                    imgui.TextColored(labelColor, 'Bar color');
                    imgui.TableNextColumn();
                    warningColor = DrawColor(rowId .. '_color', warningColor);
                    imgui.EndTable();
                end
            end
            return percentValue, warningColor;
        end

        local function DrawHpSliderPair(rowId, leftLabel, leftId, leftValue, leftMin, leftMax, rightLabel, rightId, rightValue, rightMin, rightMax)
            if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
                local leftResult = leftValue;
                local rightResult = rightValue;

                if (imgui.BeginTable('##bar_hp_' .. rowId, 4, tableFlags)) then
                    imgui.TableSetupColumn('##label_left', 0, barLabelWidth);
                    imgui.TableSetupColumn('##control_left', 0, barControlWidth);
                    imgui.TableSetupColumn('##label_right', 0, barRightLabelWidth);
                    imgui.TableSetupColumn('##control_right', 0, barControlWidth);
                    imgui.TableNextRow();
                    imgui.TableNextColumn();
                    leftResult = DrawTableSlider(leftLabel, leftId, leftValue, leftMin, leftMax, true, barNumericWidth);
                    imgui.TableNextColumn();
                    rightResult = DrawTableSlider(rightLabel, rightId, rightValue, rightMin, rightMax, true, barNumericWidth);
                    imgui.EndTable();
                end

                return leftResult, rightResult;
            end

            return DrawSliderPair(rowId, leftLabel, leftId, leftValue, leftMin, leftMax, rightLabel, rightId, rightValue, rightMin, rightMax);
        end

        local function DrawHpGeometryRows()
            local width = settings.width;
            local height = settings.height;
            local offsetX = settings.offsetX;
            local offsetY = settings.offsetY;

            if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
                if (imgui.BeginTable('##bar_hp_' .. idPrefix .. 'geometry', 4, tableFlags)) then
                    imgui.TableSetupColumn('##label_left', 0, barLabelWidth);
                    imgui.TableSetupColumn('##control_left', 0, barControlWidth);
                    imgui.TableSetupColumn('##label_right', 0, barRightLabelWidth);
                    imgui.TableSetupColumn('##control_right', 0, barControlWidth);

                    imgui.TableNextRow();
                    imgui.TableNextColumn();
                    width = DrawTableSlider('Width', idPrefix .. 'width', width, 20, 800, true, barNumericWidth);
                    imgui.TableNextColumn();
                    height = DrawTableSlider('Height', idPrefix .. 'height', height, 1, 160, true, barNumericWidth);

                    imgui.TableNextRow();
                    imgui.TableNextColumn();
                    offsetX = DrawTableSlider('Position X', idPrefix .. 'offset_x', offsetX, -400, 400, true, barNumericWidth);
                    imgui.TableNextColumn();
                    offsetY = DrawTableSlider('Position Y', idPrefix .. 'offset_y', offsetY, -400, 400, true, barNumericWidth);
                    imgui.EndTable();
                end

                return width, height, offsetX, offsetY;
            end

            width, height = DrawHpSliderPair(idPrefix .. 'size', 'Width', idPrefix .. 'width', settings.width, 20, 800, 'Height', idPrefix .. 'height', settings.height, 1, 160);
            offsetX, offsetY = DrawHpSliderPair(idPrefix .. 'position', 'Position X', idPrefix .. 'offset_x', settings.offsetX, -400, 400, 'Position Y', idPrefix .. 'offset_y', settings.offsetY, -400, 400);
            return width, height, offsetX, offsetY;
        end

        local function DrawHpColorPair(rowId, leftLabel, leftId, leftValue, rightLabel, rightId, rightValue)
            if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
                local leftResult = leftValue;
                local rightResult = rightValue;

                if (imgui.BeginTable('##bar_hp_' .. rowId, 4, tableFlags)) then
                    imgui.TableSetupColumn('##label_left', 0, barLabelWidth);
                    imgui.TableSetupColumn('##control_left', 0, barControlWidth);
                    imgui.TableSetupColumn('##label_right', 0, barRightLabelWidth);
                    imgui.TableSetupColumn('##control_right', 0, barControlWidth);
                    imgui.TableNextRow();
                    imgui.TableNextColumn();
                    leftResult = DrawColorCell(leftLabel, leftId, leftValue);
                    imgui.TableNextColumn();
                    rightResult = DrawColorCell(rightLabel, rightId, rightValue);
                    imgui.EndTable();
                end

                return leftResult, rightResult;
            end

            return DrawColorPair(rowId, leftLabel, leftId, leftValue, rightLabel, rightId, rightValue);
        end

        local function DrawHpTextureRow(rowId, fillColor, backgroundColor, texture, textureStrength)
            local key = tostring(rowId or 'color_texture');
            local nextFillColor, nextBackgroundColor = DrawHpColorPair(key .. '_colors', 'Fill color', key .. '_fill_color', fillColor, 'BG color', key .. '_bg_color', backgroundColor);
            local nextTexture = texture;
            local nextTextureStrength = tonumber(textureStrength) or 100;

            if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
                if (imgui.BeginTable('##bar_hp_' .. key .. '_texture', 4, tableFlags)) then
                    imgui.TableSetupColumn('##label_left', 0, barLabelWidth);
                    imgui.TableSetupColumn('##control_left', 0, barControlWidth);
                    imgui.TableSetupColumn('##label_right', 0, barRightLabelWidth);
                    imgui.TableSetupColumn('##control_right', 0, barControlWidth);
                    imgui.TableNextRow();
                    imgui.TableNextColumn();
                    imgui.TextColored(labelColor, 'Texture');
                    imgui.TableNextColumn();
                    nextTexture = DrawBarTextureChoice(texture, key .. '_texture', barComboWidth);
                    imgui.TableNextColumn();
                    imgui.TextColored(labelColor, 'Strength');
                    imgui.TableNextColumn();
                    nextTextureStrength = DrawSliderControl(key .. '_texture_strength', nextTextureStrength, 0, 100, barNumericWidth, true);
                    imgui.EndTable();
                end
            else
                nextTexture = DrawComboRow('Texture', texture, barTextures.GetOptions(), key .. '_texture', 170);
                NewLine();
                imgui.TextColored(labelColor, 'Strength');
                imgui.SameLine();
                nextTextureStrength = DrawSliderControl(key .. '_texture_strength', nextTextureStrength, 0, 100, 95, true);
            end

            return nextFillColor, nextBackgroundColor, nextTexture, nextTextureStrength;
        end

        local function DrawHpBorderRow(rowId, borderColor, borderSize)
            local key = tostring(rowId or 'border');

            if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
                local nextBorderColor = borderColor;
                local nextBorderSize = borderSize;

                if (imgui.BeginTable('##bar_hp_' .. key, 4, tableFlags)) then
                    imgui.TableSetupColumn('##color_label', 0, barLabelWidth);
                    imgui.TableSetupColumn('##color_control', 0, barControlWidth);
                    imgui.TableSetupColumn('##size_label', 0, barRightLabelWidth);
                    imgui.TableSetupColumn('##size_control', 0, barControlWidth);
                    imgui.TableNextRow();
                    imgui.TableNextColumn();
                    imgui.TextColored(labelColor, 'Border color');
                    imgui.TableNextColumn();
                    nextBorderColor = DrawColor(key .. '_color', borderColor);
                    imgui.TableNextColumn();
                    imgui.TextColored(labelColor, 'Border size');
                    imgui.TableNextColumn();
                    nextBorderSize = DrawSliderControl(key .. '_size', borderSize, 0, 24, barNumericWidth, true);
                    imgui.EndTable();
                end

                return nextBorderColor, nextBorderSize;
            end

            return DrawBorderRow(rowId, borderColor, borderSize);
        end

        local function DrawHpSingleSlider(rowId, label, value, minValue, maxValue)
            if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
                local result = value;

                if (imgui.BeginTable('##bar_hp_' .. rowId, 4, tableFlags)) then
                    imgui.TableSetupColumn('##label_left', 0, barLabelWidth);
                    imgui.TableSetupColumn('##control_left', 0, barControlWidth);
                    imgui.TableSetupColumn('##label_right', 0, barRightLabelWidth);
                    imgui.TableSetupColumn('##control_right', 0, barControlWidth);
                    imgui.TableNextRow();
                    imgui.TableNextColumn();
                    result = DrawTableSlider(label, rowId, value, minValue, maxValue, true, barNumericWidth);
                    imgui.EndTable();
                end

                return result;
            end

            return DrawSingleSlider(label, rowId, value, minValue, maxValue, true, barLabelWidth, barControlWidth, nil, barNumericWidth);
        end

        local function DrawTpThresholdColorRow(rowId, showAtPercent, fullColor)
            local nextShowAtPercent = tonumber(showAtPercent) or 300;
            local nextFullColor = fullColor or defaults.fullColor or settings.color;

            if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
                if (imgui.BeginTable('##bar_tp_' .. rowId, 4, tableFlags)) then
                    imgui.TableSetupColumn('##threshold_label', 0, barLabelWidth);
                    imgui.TableSetupColumn('##threshold_control', 0, barControlWidth);
                    imgui.TableSetupColumn('##full_color_label', 0, barRightLabelWidth);
                    imgui.TableSetupColumn('##full_color_control', 0, barControlWidth);
                    imgui.TableNextRow();
                    imgui.TableNextColumn();
                    imgui.TextColored(labelColor, 'Show at TP %%');
                    imgui.TableNextColumn();
                    nextShowAtPercent = DrawSliderControl(rowId .. '_threshold', nextShowAtPercent, 0, 300, barNumericWidth, true);
                    imgui.TableNextColumn();
                    imgui.TextColored(labelColor, 'Full color');
                    imgui.TableNextColumn();
                    nextFullColor = DrawColor(rowId .. '_full_color', nextFullColor);
                    imgui.EndTable();
                end

                return nextShowAtPercent, nextFullColor;
            end

            nextShowAtPercent = DrawSingleSlider('Show at TP %%', rowId .. '_threshold', nextShowAtPercent, 0, 300, true, barLabelWidth, barControlWidth, nil, barNumericWidth);
            imgui.TextColored(labelColor, 'Full color');
            imgui.SameLine();
            nextFullColor = DrawColor(rowId .. '_full_color', nextFullColor);
            return nextShowAtPercent, nextFullColor;
        end

        DrawPanel('Bar Settings', function()
            if (anchorControls.IsCollapsedChild(settings) == true) then
                settings.width, settings.height = DrawHpSliderPair(idPrefix .. 'size', 'Width', idPrefix .. 'width', settings.width, 20, 800, 'Height', idPrefix .. 'height', settings.height, 1, 160);
                anchorControls.DrawSpacing(settings, idPrefix .. 'position', barLabelWidth, barControlWidth, barRightLabelWidth);
            else
                settings.width, settings.height, settings.offsetX, settings.offsetY = DrawHpGeometryRows();
            end
            settings.color, settings.backgroundColor, settings.texture, settings.textureStrength = DrawHpTextureRow(idPrefix .. 'colors_texture', settings.color, settings.backgroundColor, settings.texture, settings.textureStrength);
            settings.borderColor, settings.borderSize = DrawHpBorderRow(idPrefix .. 'border', settings.borderColor, settings.borderSize);
            settings.cornerRadius = DrawHpSingleSlider(idPrefix .. 'corner_radius', 'Corner radius', settings.cornerRadius, 0, 80);

            if ((resourceName == 'HP' or resourceName == 'MP')
                and (context == nil or context.hideShowAtPercent ~= true)) then
                settings.showAtPercent = DrawHpSingleSlider(idPrefix .. 'show_at_percent', 'Show at ' .. resourceLabel .. ' %%', settings.showAtPercent, 1, 100);
            elseif (resourceName == 'TP') then
                settings.showAtPercent, settings.fullColor = DrawTpThresholdColorRow(idPrefix .. 'show_at_full_color', settings.showAtPercent, settings.fullColor);
            end

            if (context ~= nil and context.showOutOfRangeOpacity == true) then
                if (imgui.Spacing ~= nil) then imgui.Spacing(); end
                settings.outOfRangeOpacityEnabled = DrawHpLabeledToggle(idPrefix .. 'out_of_range_toggle', 'Use out of range color', settings.outOfRangeOpacityEnabled);

                if (settings.outOfRangeOpacityEnabled == true) then
                    imgui.TextColored(labelColor, 'Out of range color');
                    imgui.SameLine();
                    settings.outOfRangeColor = DrawColor(idPrefix .. 'out_of_range_color', settings.outOfRangeColor);
                end
            end
        end, true);

        if (isSegmentedResource == true) then
            DrawPanel(resourceLabel .. ' Sections', function()
                if (DrawRadio('One section', settings.segmented == false) == true) then
                    settings.segmented = false;
                end
                imgui.SameLine();
                if (DrawRadio('Three sections', settings.segmented ~= false) == true) then
                    settings.segmented = true;
                end

                if (settings.segmented ~= false) then
                    settings.segmentGap, settings.color2, settings.color3 = DrawSectionOptionsRow(idPrefix .. 'tp_sections', settings.segmentGap, settings.color2, settings.color3, defaults, settings.color);
                end
            end);
        end

        DrawPanel('Text Settings', function()
            DrawFontRow(settings, defaults, idPrefix, barLabelWidth, barControlWidth, barNumericWidth, barRightLabelWidth);
            DrawOutlineRow(settings, idPrefix, barLabelWidth, barControlWidth, barNumericWidth, barRightLabelWidth);
            settings.textOutlineEnabled = (tonumber(settings.textOutlineSize) or 0) > 0;
            settings.textOffsetX, settings.textOffsetY = DrawHpSliderPair(idPrefix .. 'text_position', 'Position X', idPrefix .. 'text_offset_x', settings.textOffsetX, -400, 400, 'Position Y', idPrefix .. 'text_offset_y', settings.textOffsetY, -400, 400);

            local textToggles = {};
            local showValueIndex = nil;
            local showPercentIndex = nil;
            local useSmallFontIndex = nil;

            if (context ~= nil and context.showValueControl == false) then
                settings.showValue = false;
            else
                showValueIndex = #textToggles + 1;
                textToggles[showValueIndex] = { label = 'Show ' .. resourceLabel .. ' value', value = settings.showValue };
            end

            showPercentIndex = #textToggles + 1;
            textToggles[showPercentIndex] = {
                label = tostring(context ~= nil and context.showPercentLabel or ('Show ' .. resourceLabel .. ' %%')),
                value = settings.showPercent,
            };

            useSmallFontIndex = #textToggles + 1;
            textToggles[useSmallFontIndex] = { label = 'Use small font', value = settings.useSmallFont };

            DrawHpToggleRows(idPrefix .. 'text_toggles', textToggles);

            if (showValueIndex ~= nil) then
                settings.showValue = textToggles[showValueIndex].value;
            else
                settings.showValue = false;
            end

            settings.showPercent = textToggles[showPercentIndex].value;
            settings.useSmallFont = textToggles[useSmallFontIndex].value;
            uiTooltip.Info('When enabled, this uses the Small text font style configured in General > Font.');
        end);

        if (showLowState == true) then
            DrawPanel(resourceName == 'HP' and 'Low HP warnings' or ('Low ' .. resourceLabel .. ' warning'), function()
                settings.lowColorEnabled = DrawHpLabeledToggle(idPrefix .. 'low_state_toggle', 'Low ' .. resourceLabel, settings.lowColorEnabled);

                if (settings.lowColorEnabled == true) then
                    settings.lowColorPercent, settings.lowColor = DrawHpLowWarningRow(idPrefix .. 'low_warning', settings.lowColorPercent, settings.lowColor);
                end

                if (resourceName == 'HP') then
                    settings.criticalColorEnabled = DrawHpLabeledToggle(idPrefix .. 'critical_state_toggle', 'Critical HP', settings.criticalColorEnabled);
                    if (settings.criticalColorEnabled == true) then
                        settings.criticalColorPercent, settings.criticalColor = DrawHpLowWarningRow(
                            idPrefix .. 'critical_warning',
                            settings.criticalColorPercent,
                            settings.criticalColor
                        );
                    end
                end

                local animationStateEnabled = settings.lowColorEnabled == true;
                if (resourceName == 'HP') then
                    animationStateEnabled = settings.criticalColorEnabled == true;
                end
                if (animationStateEnabled == true) then
                    local animation = settings.lowAnimationEnabled == true and tostring(settings.lowAnimation or defaults.lowAnimation or 'Important') or 'None';
                    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
                        if (imgui.BeginTable('##bar_hp_low_animation', 4, tableFlags)) then
                            imgui.TableSetupColumn('##animation_label', 0, barLabelWidth);
                            imgui.TableSetupColumn('##animation_control', 0, barControlWidth);
                            imgui.TableSetupColumn('##speed_label', 0, barRightLabelWidth);
                            imgui.TableSetupColumn('##speed_control', 0, barControlWidth);
                            imgui.TableNextRow();
                            imgui.TableNextColumn();
                            imgui.TextColored(labelColor, 'Animation');
                            imgui.TableNextColumn();
                            animation = DrawAnimationChoice(
                                animation,
                                idPrefix .. 'low_animation',
                                settings.lowAnimationSpeed,
                                { 1.0, 1.0, 1.0, 0.35 },
                                resourceName == 'HP' and settings.criticalColor or settings.lowColor,
                                settings.backgroundColor,
                                barComboWidth
                            );
                            if (animation ~= 'None') then
                                imgui.TableNextColumn();
                                imgui.TextColored(labelColor, 'Animation speed');
                                imgui.TableNextColumn();
                                settings.lowAnimationSpeed = DrawSliderControl(idPrefix .. 'low_animation_speed', settings.lowAnimationSpeed, 0, 240, barComboWidth, false);
                            end
                            imgui.EndTable();
                        end
                    else
                        animation = DrawAnimationChoice(
                            animation,
                            idPrefix .. 'low_animation',
                            settings.lowAnimationSpeed,
                            { 1.0, 1.0, 1.0, 0.35 },
                            resourceName == 'HP' and settings.criticalColor or settings.lowColor,
                            settings.backgroundColor,
                            170
                        );
                        if (animation ~= 'None') then
                            imgui.SameLine();
                            imgui.TextColored(labelColor, 'Animation speed');
                            imgui.SameLine();
                            settings.lowAnimationSpeed = DrawSliderControl(idPrefix .. 'low_animation_speed', settings.lowAnimationSpeed, 0, 240, barComboWidth, false);
                        end
                    end

                    if (animation == 'None') then
                        settings.lowAnimationEnabled = false;
                    else
                        settings.lowAnimationEnabled = true;
                        settings.lowAnimation = animation;
                    end
                end
            end);
        end

        imgui.Spacing();
        imgui.Spacing();

        if (DrawActionButton('Reset ' .. label .. ' position') == true) then
            RequestReset('position', label .. ' position');
        end

        if (DrawActionButton('Reset ' .. label .. ' settings') == true) then
            RequestReset('settings', label .. ' settings');
        end

        DrawResetConfirm(settings, defaults, label);
        return;
    end

    if (boxedSettings == true and labelIconOptions == true and (resourceName == 'Ward' or resourceName == 'Rage' or resourceName == 'Favor')) then
        local panelLabelWidth = 150;
        local panelControlWidth = 170;

        DrawPanel('Bar Settings', function()
            settings.width, settings.height = DrawSliderPair(idPrefix .. 'size', 'Width', idPrefix .. 'width', settings.width, 20, 800, 'Height', idPrefix .. 'height', settings.height, 1, 160);
            if (anchorControls.IsCollapsedChild(settings) == true) then
                anchorControls.DrawSpacing(settings, idPrefix .. 'position', panelLabelWidth, panelControlWidth);
            else
                settings.offsetX, settings.offsetY = DrawSliderPair(idPrefix .. 'position', 'Position X', idPrefix .. 'offset_x', settings.offsetX, -400, 400, 'Position Y', idPrefix .. 'offset_y', settings.offsetY, -400, 400);
            end
            settings.color, settings.backgroundColor, settings.texture, settings.textureStrength = DrawColorTextureRow(idPrefix .. 'colors_texture', settings.color, settings.backgroundColor, settings.texture, settings.textureStrength);
            settings.borderColor, settings.borderSize = DrawBorderRow(idPrefix .. 'border', settings.borderColor, settings.borderSize);
            settings.cornerRadius = DrawSingleSlider('Corner radius', idPrefix .. 'corner_radius', settings.cornerRadius, 0, 80, true, panelLabelWidth, panelControlWidth);
            settings.fillDirection = DrawComboRow('Fill direction', settings.fillDirection or defaults.fillDirection or 'Left to right', { 'Left to right', 'Right to left', 'Bottom to top', 'Top to bottom' }, idPrefix .. 'fill_direction', 150);
        end, true);

        DrawPanel(resourceName .. ' Icon/Text', function()
            if (settings.labelDisplayMode == 'Icon + text') then
                settings.labelDisplayMode = 'Text';
            end
            settings.labelDisplayMode = DrawComboRow('Display', settings.labelDisplayMode or 'Text', { 'None', 'Text', 'Icon' }, idPrefix .. 'label_display');

            if (settings.labelDisplayMode == 'Text' or settings.labelDisplayMode == 'Icon') then
                local positionLabel = settings.labelDisplayMode == 'Icon' and 'Icon' or 'Label';
                settings.labelIconOffsetX, settings.labelIconOffsetY = DrawSliderPair(idPrefix .. 'label_position', positionLabel .. ' X', idPrefix .. 'label_icon_offset_x', settings.labelIconOffsetX, -400, 400, positionLabel .. ' Y', idPrefix .. 'label_icon_offset_y', settings.labelIconOffsetY, -400, 400);
            end

            if (settings.labelDisplayMode == 'Icon') then
                settings.labelIconSize = DrawSingleSlider('Icon size', idPrefix .. 'label_icon_size', settings.labelIconSize, 6, 256);
            end
        end);

        DrawPanel(resourceName == 'Favor' and 'Charge Text' or 'Timer Text', function()
            settings.showValue = false;
            settings.showPercent = DrawToggle('Show ' .. string.lower(resourceName) .. (resourceName == 'Favor' and ' charge' or ' timer'), settings.showPercent ~= false);
            if (settings.showPercent == true) then
                settings.textOffsetX, settings.textOffsetY = DrawSliderPair(idPrefix .. 'timer_position', 'Timer X', idPrefix .. 'text_offset_x', settings.textOffsetX, -400, 400, 'Timer Y', idPrefix .. 'text_offset_y', settings.textOffsetY, -400, 400);
            end

            if (settings.labelDisplayMode == 'Text' or settings.showPercent == true) then
                DrawFontRow(settings, defaults, idPrefix);
                DrawOutlineRow(settings, idPrefix);
                settings.textOutlineEnabled = (tonumber(settings.textOutlineSize) or 0) > 0;
                settings.useSmallFont = DrawToggle('Use small font', settings.useSmallFont);
                uiTooltip.Info('When enabled, this uses the Small text font style configured in General > Font.');
            end
        end);

        imgui.Spacing();
        imgui.Spacing();

        if (DrawActionButton('Reset ' .. label .. ' position') == true) then
            RequestReset('position', label .. ' position');
        end

        if (DrawActionButton('Reset ' .. label .. ' settings') == true) then
            RequestReset('settings', label .. ' settings');
        end

        DrawResetConfirm(settings, defaults, label);
        return;
    end

    local function DrawBody()
    local settingsGridColumnWidth = context ~= nil and tonumber(context.settingsGridColumnWidth) or nil;
    local settingsGridNumericWidth = settingsGridColumnWidth ~= nil and 58 or nil;
    DrawInnerHeader('Bar Settings:');
    settings.width, settings.height = DrawSliderPair(idPrefix .. 'size', 'Width', idPrefix .. 'width', settings.width, 20, 800, 'Height', idPrefix .. 'height', settings.height, 1, 160, settingsGridColumnWidth, settingsGridColumnWidth, settingsGridNumericWidth);
    settings.offsetX, settings.offsetY = DrawSliderPair(idPrefix .. 'position', 'Position X', idPrefix .. 'offset_x', settings.offsetX, -400, 400, 'Position Y', idPrefix .. 'offset_y', settings.offsetY, -400, 400, settingsGridColumnWidth, settingsGridColumnWidth, settingsGridNumericWidth);
    settings.color, settings.backgroundColor, settings.texture, settings.textureStrength = DrawColorTextureRow(idPrefix .. 'colors_texture', settings.color, settings.backgroundColor, settings.texture, settings.textureStrength, settingsGridColumnWidth, settingsGridColumnWidth, settingsGridNumericWidth);
    local alignBarSettingsGrid = context ~= nil and context.alignBarSettingsGrid == true;
    local alignedLabelWidth = settingsGridColumnWidth or (alignBarSettingsGrid and pairLabelWidth or nil);
    local alignedControlWidth = settingsGridColumnWidth or (alignBarSettingsGrid and pairControlWidth or nil);
    settings.borderColor, settings.borderSize = DrawBorderRow(
        idPrefix .. 'border',
        settings.borderColor,
        settings.borderSize,
        alignedLabelWidth,
        alignedControlWidth,
        alignedLabelWidth,
        settingsGridNumericWidth or (alignBarSettingsGrid and 95 or nil)
    );

    settings.cornerRadius = DrawSingleSlider(
        'Corner radius',
        idPrefix .. 'corner_radius',
        settings.cornerRadius,
        0,
        80,
        true,
        alignedLabelWidth or 108,
        alignedControlWidth or 150,
        nil,
        settingsGridNumericWidth
    );

    if (resourceName == 'Ward' or resourceName == 'Rage' or resourceName == 'Favor') then
        settings.fillDirection = DrawComboRow('Fill direction', settings.fillDirection or defaults.fillDirection or 'Left to right', { 'Left to right', 'Right to left', 'Bottom to top', 'Top to bottom' }, idPrefix .. 'fill_direction', settingsGridColumnWidth ~= nil and 108 or 150, settingsGridColumnWidth, settingsGridColumnWidth);
    end

    if (resourceName == 'HP' and (context == nil or context.hideShowAtPercent ~= true)) then
        settings.showAtPercent = DrawSingleSlider(
            'Show at HP',
            idPrefix .. 'show_at_percent',
            settings.showAtPercent,
            1,
            100,
            true,
            alignedLabelWidth or 108,
            alignedControlWidth or 150,
            '%',
            settingsGridNumericWidth
        );
    elseif (resourceName == 'MP' and (context == nil or context.hideShowAtPercent ~= true)) then
        settings.showAtPercent = DrawSingleSlider(
            'Show at MP',
            idPrefix .. 'show_at_percent',
            settings.showAtPercent,
            1,
            100,
            true,
            alignedLabelWidth or 108,
            alignedControlWidth or 150,
            '%',
            settingsGridNumericWidth
        );
    end

    if (resourceName == 'HP' and context ~= nil and context.showOutOfRangeOpacity == true) then
        DrawInnerBreak();
        DrawInnerHeader('Out of range:');
        settings.outOfRangeOpacityEnabled = DrawToggle('Use out of range color', settings.outOfRangeOpacityEnabled);

        if (settings.outOfRangeOpacityEnabled == true) then
            imgui.TextColored(labelColor, 'Out of range color');
            imgui.SameLine();
            settings.outOfRangeColor = DrawColor(idPrefix .. 'out_of_range_color', settings.outOfRangeColor);
        end
    end

    if (isSegmentedResource == true) then
        DrawInnerBreak();
        DrawInnerHeader(resourceName .. ' Sections:');
        if (DrawRadio('One section', settings.segmented == false) == true) then
            settings.segmented = false;
        end
        imgui.SameLine();
        if (DrawRadio('Three sections', settings.segmented ~= false) == true) then
            settings.segmented = true;
        end

        if (settings.segmented ~= false) then
            settings.segmentGap, settings.color2, settings.color3 = DrawSectionOptionsRow(idPrefix .. 'tp_sections', settings.segmentGap, settings.color2, settings.color3, defaults, settings.color);
        end

        if (resourceName == 'Ready') then
            settings.chargeSeconds = DrawSingleSlider('Seconds per charge', idPrefix .. 'charge_seconds', settings.chargeSeconds or defaults.chargeSeconds or 30, 10, 30, true);
        end
    end

    if (labelIconOptions ~= true) then
        DrawInnerBreak();
        DrawInnerHeader('Text Settings:');
        DrawFontRow(settings, defaults, idPrefix, settingsGridColumnWidth, settingsGridColumnWidth, settingsGridNumericWidth, settingsGridColumnWidth);
        DrawOutlineRow(settings, idPrefix, settingsGridColumnWidth, settingsGridColumnWidth, settingsGridNumericWidth, settingsGridColumnWidth);
        settings.textOutlineEnabled = (tonumber(settings.textOutlineSize) or 0) > 0;
        settings.textOffsetX, settings.textOffsetY = DrawSliderPair(idPrefix .. 'text_position', 'Position X', idPrefix .. 'text_offset_x', settings.textOffsetX, -400, 400, 'Position Y', idPrefix .. 'text_offset_y', settings.textOffsetY, -400, 400, settingsGridColumnWidth, settingsGridColumnWidth, settingsGridNumericWidth);

        local showValueLabel = nil;
        local showPercentLabel = nil;

        if (context ~= nil and context.showValueControl == false) then
            settings.showValue = false;
        elseif (resourceName == 'Ready') then
            showValueLabel = 'Show ' .. resourceName .. ' text';
        else
            showValueLabel = 'Show ' .. resourceName .. ' value';
        end

        if (resourceName == 'Ready') then
            showPercentLabel = 'Show ' .. string.lower(resourceName) .. ' counter';
        elseif (resourceName == 'Sic') then
            settings.showPercent = false;
        else
            showPercentLabel = tostring(
                context ~= nil and context.showPercentLabel
                or ('Show ' .. resourceName .. ' percent')
            );
        end

        local textToggles = {};

        if (showValueLabel ~= nil) then
            textToggles[#textToggles + 1] = { label = showValueLabel, value = settings.showValue };
        end

        if (showPercentLabel ~= nil) then
            textToggles[#textToggles + 1] = { label = showPercentLabel, value = settings.showPercent };
        end

        textToggles[#textToggles + 1] = { label = 'Use small font', value = settings.useSmallFont };
        DrawToggleGroupRow(idPrefix .. 'text_toggles', textToggles);

        local toggleIndex = 1;
        if (showValueLabel ~= nil) then
            settings.showValue = textToggles[toggleIndex].value;
            toggleIndex = toggleIndex + 1;
        end

        if (showPercentLabel ~= nil) then
            settings.showPercent = textToggles[toggleIndex].value;
            toggleIndex = toggleIndex + 1;
        end

        settings.useSmallFont = textToggles[toggleIndex].value;
        uiTooltip.Info('When enabled, this uses the Small text font style configured in General > Font.');
    end

    local function DrawLabelTextSettings()
        DrawFontRow(settings, defaults, idPrefix, settingsGridColumnWidth, settingsGridColumnWidth, settingsGridNumericWidth, settingsGridColumnWidth);
        DrawOutlineRow(settings, idPrefix, settingsGridColumnWidth, settingsGridColumnWidth, settingsGridNumericWidth, settingsGridColumnWidth);
        settings.textOutlineEnabled = (tonumber(settings.textOutlineSize) or 0) > 0;
        settings.useSmallFont = DrawToggle('Use small font', settings.useSmallFont);
        uiTooltip.Info('When enabled, this uses the Small text font style configured in General > Font.');
    end

    if (labelIconOptions == true) then
        DrawInnerBreak();
        if (resourceName == 'Ward' or resourceName == 'Rage' or resourceName == 'Favor') then
            DrawInnerHeader(resourceName .. ' Icon/Text:');
        else
            DrawInnerHeader('Labels:');
        end

        if (settings.labelDisplayMode == 'Icon + text') then
            settings.labelDisplayMode = 'Text';
        end
        local labelDisplayOptions = (context ~= nil and context.labelDisplayOptions ~= nil) and context.labelDisplayOptions or { 'None', 'Text', 'Icon' };
        settings.labelDisplayMode = DrawComboRow('Display', settings.labelDisplayMode or 'Text', labelDisplayOptions, idPrefix .. 'label_display', settingsGridColumnWidth ~= nil and 108 or nil, settingsGridColumnWidth, settingsGridColumnWidth);

        if (settings.labelDisplayMode == 'Text' or settings.labelDisplayMode == 'Icon') then
            local positionLabel = (settings.labelDisplayMode == 'Icon') and 'Icon' or 'Label';
            settings.labelIconOffsetX, settings.labelIconOffsetY = DrawSliderPair(idPrefix .. 'label_position', positionLabel .. ' X', idPrefix .. 'label_icon_offset_x', settings.labelIconOffsetX, -400, 400, positionLabel .. ' Y', idPrefix .. 'label_icon_offset_y', settings.labelIconOffsetY, -400, 400, settingsGridColumnWidth, settingsGridColumnWidth, settingsGridNumericWidth);
        end

        if (settings.labelDisplayMode == 'Icon') then
            settings.labelIconSize = DrawSingleSlider('Icon size', idPrefix .. 'label_icon_size', settings.labelIconSize, 6, 256, true, settingsGridColumnWidth, settingsGridColumnWidth, nil, settingsGridNumericWidth);
        end

        if (resourceName == 'Ready') then
            settings.showValue = false;
            settings.showPercent = DrawToggle('Show ' .. string.lower(resourceName) .. ' counter', settings.showPercent);
            if (settings.showPercent == true) then
                settings.counterOffsetX, settings.counterOffsetY = DrawSliderPair(
                    idPrefix .. 'counter_position',
                    'Counter X',
                    idPrefix .. 'counter_offset_x',
                    settings.counterOffsetX,
                    -400,
                    400,
                    'Counter Y',
                    idPrefix .. 'counter_offset_y',
                    settings.counterOffsetY,
                    -400,
                    400
                );
            end
            imgui.Separator();
            DrawInnerHeader('Cooldown Timer:');
            settings.showReadyTimer = DrawToggle('Show cooldown timer', settings.showReadyTimer ~= false);
            if (settings.showPercent == true or settings.showReadyTimer == true) then
                settings.textOffsetX, settings.textOffsetY = DrawSliderPair(idPrefix .. 'timer_position', 'Timer X', idPrefix .. 'text_offset_x', settings.textOffsetX, -400, 400, 'Timer Y', idPrefix .. 'text_offset_y', settings.textOffsetY, -400, 400);
            end
        elseif (resourceName == 'Ward' or resourceName == 'Rage' or resourceName == 'Favor') then
            imgui.Separator();
            DrawInnerHeader(resourceName == 'Favor' and 'Charge Text:' or 'Timer Text:');
            settings.showValue = false;
            settings.showPercent = DrawToggle('Show ' .. string.lower(resourceName) .. (resourceName == 'Favor' and ' charge' or ' timer'), settings.showPercent ~= false);
            if (settings.showPercent == true) then
                settings.textOffsetX, settings.textOffsetY = DrawSliderPair(idPrefix .. 'timer_position', 'Timer X', idPrefix .. 'text_offset_x', settings.textOffsetX, -400, 400, 'Timer Y', idPrefix .. 'text_offset_y', settings.textOffsetY, -400, 400, settingsGridColumnWidth, settingsGridColumnWidth, settingsGridNumericWidth);
            end
        elseif (context ~= nil and context.cooldownTimerOptions == true) then
            settings.showValue = false;
            imgui.Separator();
            DrawInnerHeader('Cooldown Timer:');
            settings.showPercent = DrawToggle('Show cooldown timer', settings.showPercent ~= false);
            if (settings.showPercent == true) then
                settings.textOffsetX, settings.textOffsetY = DrawSliderPair(
                    idPrefix .. 'timer_position',
                    'Timer X',
                    idPrefix .. 'text_offset_x',
                    settings.textOffsetX,
                    -400,
                    400,
                    'Timer Y',
                    idPrefix .. 'text_offset_y',
                    settings.textOffsetY,
                    -400,
                    400,
                    settingsGridColumnWidth,
                    settingsGridColumnWidth,
                    settingsGridNumericWidth
                );
            end
        elseif (resourceName == 'Sic') then
            settings.showValue = false;
            settings.showPercent = false;
            imgui.Separator();
            DrawInnerHeader('Cooldown Timer:');
            settings.showSicTimer = DrawToggle('Show cooldown timer', settings.showSicTimer ~= false);
            if (settings.showSicTimer == true) then
                settings.textOffsetX, settings.textOffsetY = DrawSliderPair(idPrefix .. 'timer_position', 'Timer X', idPrefix .. 'text_offset_x', settings.textOffsetX, -400, 400, 'Timer Y', idPrefix .. 'text_offset_y', settings.textOffsetY, -400, 400, settingsGridColumnWidth, settingsGridColumnWidth, settingsGridNumericWidth);
            end
        elseif (resourceName == 'Reward') then
            settings.showValue = false;
            settings.showPercent = false;
            imgui.Separator();
            DrawInnerHeader('Cooldown Timer:');
            settings.showRewardTimer = DrawToggle('Show cooldown timer', settings.showRewardTimer ~= false);
            if (settings.showRewardTimer == true) then
                settings.textOffsetX, settings.textOffsetY = DrawSliderPair(idPrefix .. 'timer_position', 'Timer X', idPrefix .. 'text_offset_x', settings.textOffsetX, -400, 400, 'Timer Y', idPrefix .. 'text_offset_y', settings.textOffsetY, -400, 400, settingsGridColumnWidth, settingsGridColumnWidth, settingsGridNumericWidth);
            end
        end

        if (
            settings.labelDisplayMode == 'Text' or
            settings.showPercent == true or
            (resourceName == 'Ready' and settings.showReadyTimer ~= false) or
            (resourceName == 'Sic' and settings.showSicTimer == true) or
            (resourceName == 'Reward' and settings.showRewardTimer == true)
        ) then
            DrawLabelTextSettings();
        end
    end

    if (showLowState == true) then
        DrawInnerBreak();
        DrawInnerHeader(resourceName == 'HP' and 'Low HP warnings:' or ('Low ' .. resourceName .. ' warning:'));
        settings.lowColorEnabled = DrawToggle('Low ' .. resourceName, settings.lowColorEnabled);

        if (settings.lowColorEnabled == true) then
            settings.lowColorPercent, settings.lowColor = DrawLowWarningRow(idPrefix .. 'low_warning', settings.lowColorPercent, settings.lowColor);
        end

        if (resourceName == 'HP') then
            settings.criticalColorEnabled = DrawToggle('Critical HP', settings.criticalColorEnabled);
            if (settings.criticalColorEnabled == true) then
                settings.criticalColorPercent, settings.criticalColor = DrawLowWarningRow(
                    idPrefix .. 'critical_warning',
                    settings.criticalColorPercent,
                    settings.criticalColor
                );
            end
        end

        local animationStateEnabled = settings.lowColorEnabled == true;
        if (resourceName == 'HP') then
            animationStateEnabled = settings.criticalColorEnabled == true;
        end
        if (animationStateEnabled == true) then
            local animation = settings.lowAnimationEnabled == true and tostring(settings.lowAnimation or defaults.lowAnimation or 'Important') or 'None';
            if (animation == 'Blink') then
                animation = 'Pulse';
            end
            animation = DrawComboRow('Animation', animation, GetAnimationOptions(), idPrefix .. 'low_animation', 170);

            if (animation == 'None') then
                settings.lowAnimationEnabled = false;
            else
                settings.lowAnimationEnabled = true;
                settings.lowAnimation = animation;
                settings.lowAnimationSpeed = DrawSingleSlider('Animation speed', idPrefix .. 'low_animation_speed', settings.lowAnimationSpeed, 0, 240, false);
            end
        end
    end
    end

    local specialPanelLabels = {
        Sic = 'Sic',
        Reward = 'Reward',
    };
    local panelLabel = boxedResourceBar == true and '' or (specialPanelLabels[resourceName] or 'HP Bar');
    DrawPanel(panelLabel, DrawBody, true);

    if (context == nil or context.hideResetControls ~= true) then
        if (context ~= nil and context.boxed == true) then
            imgui.Spacing();
            imgui.Spacing();
        else
            imgui.Separator();
        end

        if (DrawActionButton('Reset ' .. label .. ' position') == true) then
            RequestReset('position', label .. ' position');
        end

        if (DrawActionButton('Reset ' .. label .. ' settings') == true) then
            RequestReset('settings', label .. ' settings');
        end

        DrawResetConfirm(settings, defaults, label);
    end
end

return bar;
