local imgui = require('imgui');
local textScale = require('core.text_scale');
local statusIconTextures = require('core.status_icon_textures');
local uiTooltip = require('core.ui_tooltip');
local anchorControls = require('modules.widgets.anchor_controls');

local statusIcons = {};
local unpackTable = table.unpack or unpack;
local labelColor = { 0.92, 0.92, 0.90, 1.0 };
local valueColor = { 0.65, 0.90, 1.0, 1.0 };
local actionColor = { 1.0, 0.84, 0.0, 1.0 };
local function DrawSectionHeader(label)
    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.18);
    end

    imgui.TextColored(actionColor, tostring(label or ''));

    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.0);
    end
end
local colorEditFlags = bit ~= nil and bit.bor ~= nil
    and bit.bor(_G.ImGuiColorEditFlags_NoInputs or 0, _G.ImGuiColorEditFlags_NoAlpha or 0)
    or ((_G.ImGuiColorEditFlags_NoInputs or 0) + (_G.ImGuiColorEditFlags_NoAlpha or 0));
local tableFlags = (_G.ImGuiTableFlags_SizingFixedFit or 0) + (_G.ImGuiTableFlags_BordersInnerH or 0);
local heldButtonState = {};
local DrawComboRow = nil;
local pendingReset = nil;

local function ClickText(label, color)
    imgui.TextColored(color or valueColor, label);

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        return true;
    end

    if (imgui.IsItemHovered ~= nil and imgui.IsMouseDown ~= nil) then
        return imgui.IsItemHovered() == true and imgui.IsMouseDown(0) == true;
    end

    return false;
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

local function DrawRadioChoice(label, selected)
    if (imgui.RadioButton ~= nil) then
        return imgui.RadioButton(label, selected == true) == true;
    end

    local text = ((selected == true) and '(*) ' or '( ) ') .. tostring(label or '');
    return ClickText(text, (selected == true) and actionColor or labelColor);
end

local function NormalizeTimeUnit(unit)
    unit = tostring(unit or 'M'):upper();

    if (unit == 'H' or unit == 'M' or unit == 'S') then
        return unit;
    end

    return 'M';
end

local function TimeValueFromMinutes(minutes, unit)
    local value = tonumber(minutes) or 0;
    unit = NormalizeTimeUnit(unit);

    if (unit == 'H') then
        return math.max(1, math.floor((value / 60) + 0.5));
    end

    if (unit == 'S') then
        return math.max(1, math.floor((value * 60) + 0.5));
    end

    return math.max(1, math.floor(value + 0.5));
end

local function MinutesFromTimeValue(value, unit)
    local current = math.max(1, tonumber(value) or 1);
    unit = NormalizeTimeUnit(unit);

    if (unit == 'H') then
        return current * 60;
    end

    if (unit == 'S') then
        return current / 60;
    end

    return current;
end

local function TimeUnitLimits(unit)
    unit = NormalizeTimeUnit(unit);

    if (unit == 'H') then
        return 1, 168, 1;
    end

    if (unit == 'S') then
        return 1, 86400, 1;
    end

    return 1, 1440, 1;
end

local function DrawHideBuffsMode(settings)
    settings.hideOutOfCombat = DrawCheckbox('Hide buffs', settings.hideOutOfCombat);

    if (settings.hideOutOfCombat ~= true) then
        return;
    end

    local mode = tostring(settings.hideCombatMode or 'Out of combat');
    if (mode ~= 'In combat' and mode ~= 'Out of combat') then
        mode = 'Out of combat';
    end

    imgui.SameLine();
    if (DrawRadioChoice('In combat', mode == 'In combat') == true) then
        mode = 'In combat';
    end

    imgui.SameLine();
    if (DrawRadioChoice('Out of combat', mode == 'Out of combat') == true) then
        mode = 'Out of combat';
    end

    settings.hideCombatMode = mode;
end

local function DrawNumber(label, value, minValue, maxValue, step)
    local current = tonumber(value) or 0;
    local amount = tonumber(step) or 1;

    imgui.TextColored(labelColor, label);
    imgui.SameLine();
    imgui.TextColored(valueColor, tostring(current));
    imgui.SameLine();

    if (ClickText('less', actionColor) == true) then current = current - amount; end
    imgui.SameLine();
    if (ClickText('more', actionColor) == true) then current = current + amount; end

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

local function DrawSliderControl(id, value, minValue, maxValue, step, width, showButtons)
    local current = math.floor((tonumber(value) or 0) + 0.5);
    local amount = tonumber(step) or 1;

    if (showButtons == false and imgui.SliderInt == nil) then
        return DrawNumber('', value, minValue, maxValue, amount);
    end

    if (showButtons ~= false and imgui.InputText == nil and imgui.SliderInt == nil) then
        return DrawNumber('', value, minValue, maxValue, amount);
    end

    if (showButtons ~= false and imgui.Button ~= nil) then
        if (IsHeldButton('-##status_' .. id .. '_minus') == true) then
            current = current - amount;
        end

        imgui.SameLine();
    end

    if (imgui.PushItemWidth ~= nil) then
        imgui.PushItemWidth(width or 95);
    end

    local ref = { current };
    if (showButtons ~= false and imgui.InputText ~= nil) then
        ref = { tostring(current) };
        imgui.InputText('##status_' .. id, ref, 16);
    else
        imgui.SliderInt('##status_' .. id, ref, minValue or -1000, maxValue or 1000);
    end

    if (imgui.PopItemWidth ~= nil) then
        imgui.PopItemWidth();
    end

    current = tonumber(ref[1]) or current;

    if (showButtons ~= false and imgui.Button ~= nil) then
        imgui.SameLine();

        if (IsHeldButton('+##status_' .. id .. '_plus') == true) then
            current = current + amount;
        end
    end

    if (minValue ~= nil and current < minValue) then current = minValue; end
    if (maxValue ~= nil and current > maxValue) then current = maxValue; end

    return current;
end

local function DrawTableSlider(label, id, value, minValue, maxValue, step, showButtons)
    imgui.TextColored(labelColor, label);
    imgui.TableNextColumn();
    return DrawSliderControl(id, value, minValue, maxValue, step or 1, showButtons == false and 140 or 95, showButtons);
end

local function DrawSliderPair(rowId, leftLabel, leftId, leftValue, leftMin, leftMax, rightLabel, rightId, rightValue, rightMin, rightMax, step)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local leftResult = leftValue;
        local rightResult = rightValue;

        if (imgui.BeginTable('##status_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##label_left', 0, 145);
            imgui.TableSetupColumn('##control_left', 0, 170);
            imgui.TableSetupColumn('##label_right', 0, 145);
            imgui.TableSetupColumn('##control_right', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            leftResult = DrawTableSlider(leftLabel, leftId, leftValue, leftMin, leftMax, step or 1);
            imgui.TableNextColumn();
            rightResult = DrawTableSlider(rightLabel, rightId, rightValue, rightMin, rightMax, step or 1);
            imgui.EndTable();
        end

        return leftResult, rightResult;
    end

    local leftResult = DrawNumber(leftLabel, leftValue, leftMin, leftMax, step or 1);
    imgui.SameLine();
    local rightResult = DrawNumber(rightLabel, rightValue, rightMin, rightMax, step or 1);
    return leftResult, rightResult;
end

local function DrawSingleSliderRow(rowId, label, id, value, minValue, maxValue, step)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local result = value;

        if (imgui.BeginTable('##status_' .. rowId, 2, tableFlags)) then
            imgui.TableSetupColumn('##label', 0, 145);
            imgui.TableSetupColumn('##control', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            result = DrawTableSlider(label, id, value, minValue, maxValue, step or 1);
            imgui.EndTable();
        end

        return result;
    end

    imgui.TextColored(labelColor, label);
    imgui.SameLine();
    return DrawSliderControl(id, value, minValue, maxValue, step or 1);
end

local function ClampChannel(value)
    value = tonumber(value) or 0;

    if (value < 0) then return 0; end
    if (value > 1) then return 1; end

    return value;
end

local function DrawColor(id, color)
    color = color or { 1.0, 1.0, 1.0, 1.0 };

    if (imgui.ColorEdit4 ~= nil) then
        imgui.ColorEdit4('##status_' .. id, color, colorEditFlags);
        color[4] = tonumber(color[4]) or 1.0;
        return color;
    end

    local red = math.floor(ClampChannel(color[1]) * 255);
    local green = math.floor(ClampChannel(color[2]) * 255);
    local blue = math.floor(ClampChannel(color[3]) * 255);

    imgui.TextColored(color, '■');
    imgui.SameLine();
    imgui.TextColored(valueColor, tostring(red) .. '/' .. tostring(green) .. '/' .. tostring(blue));

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

local function DrawSliderAndColorRow(rowId, sliderLabel, sliderId, sliderValue, minValue, maxValue, colorLabel, colorId, colorValue)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local sliderResult = sliderValue;
        local colorResult = colorValue;

        if (imgui.BeginTable('##status_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##slider_label', 0, 145);
            imgui.TableSetupColumn('##slider_control', 0, 170);
            imgui.TableSetupColumn('##color_label', 0, 145);
            imgui.TableSetupColumn('##color_control', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            sliderResult = DrawTableSlider(sliderLabel, sliderId, sliderValue, minValue, maxValue);
            imgui.TableNextColumn();
            colorResult = DrawColorCell(colorLabel, colorId, colorValue);
            imgui.EndTable();
        end

        return sliderResult, colorResult;
    end

    local sliderResult = DrawNumber(sliderLabel, sliderValue, minValue, maxValue, 1);
    imgui.SameLine();
    imgui.TextColored(labelColor, colorLabel);
    imgui.SameLine();
    return sliderResult, DrawColor(colorId, colorValue);
end

local function DrawColorAndSliderRow(rowId, colorLabel, colorId, colorValue, sliderLabel, sliderId, sliderValue, minValue, maxValue)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local colorResult = colorValue;
        local sliderResult = sliderValue;

        if (imgui.BeginTable('##status_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##color_label', 0, 145);
            imgui.TableSetupColumn('##color_control', 0, 170);
            imgui.TableSetupColumn('##slider_label', 0, 145);
            imgui.TableSetupColumn('##slider_control', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            colorResult = DrawColorCell(colorLabel, colorId, colorValue);
            imgui.TableNextColumn();
            sliderResult = DrawTableSlider(sliderLabel, sliderId, sliderValue, minValue, maxValue);
            imgui.EndTable();
        end

        return colorResult, sliderResult;
    end

    imgui.TextColored(labelColor, colorLabel);
    imgui.SameLine();
    local colorResult = DrawColor(colorId, colorValue);
    imgui.SameLine();
    local sliderResult = DrawNumber(sliderLabel, sliderValue, minValue, maxValue, 1);
    return colorResult, sliderResult;
end

local function DrawColorPairRow(rowId, leftLabel, leftId, leftValue, rightLabel, rightId, rightValue)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local leftResult = leftValue;
        local rightResult = rightValue;

        if (imgui.BeginTable('##status_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##left_label', 0, 145);
            imgui.TableSetupColumn('##left_control', 0, 170);
            imgui.TableSetupColumn('##right_label', 0, 145);
            imgui.TableSetupColumn('##right_control', 0, 170);
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

local function DrawTimeUnitButtons(rowId, unit)
    local result = NormalizeTimeUnit(unit);

    for _, option in ipairs({ 'H', 'M', 'S' }) do
        if (option ~= 'H') then
            imgui.SameLine();
        end

        if (ClickText(option, (result == option) and valueColor or labelColor) == true) then
            result = option;
        end
    end

    return result;
end

local function DrawBuffFilterDurationRow(rowId, enabledValue, minutesValue, unitValue)
    local unitResult = NormalizeTimeUnit(unitValue);

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local enabledResult = enabledValue == true;
        local minutesResult = minutesValue;
        local displayValue = TimeValueFromMinutes(minutesResult, unitResult);
        local minValue, maxValue, step = TimeUnitLimits(unitResult);

        if (imgui.BeginTable('##status_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##check', 0, 245);
            imgui.TableSetupColumn('##control', 0, 170);
            imgui.TableSetupColumn('##unit', 0, 70);
            imgui.TableSetupColumn('##spacer', 0, 1);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            enabledResult = DrawCheckbox('Hide buffs longer than', enabledResult);
            imgui.TableNextColumn();

            if (enabledResult == true) then
                displayValue = DrawSliderControl('hide_above_value_' .. unitResult, displayValue, minValue, maxValue, step, 95);
                minutesResult = MinutesFromTimeValue(displayValue, unitResult);
                imgui.TableNextColumn();
                local newUnit = DrawTimeUnitButtons(rowId, unitResult);

                if (newUnit ~= unitResult) then
                    unitResult = newUnit;
                end
            end

            imgui.EndTable();
        end

        return enabledResult, minutesResult, unitResult;
    end

    local enabledResult = DrawCheckbox('Hide buffs longer than', enabledValue);

    if (enabledResult == true) then
        imgui.SameLine();
        local displayValue = TimeValueFromMinutes(minutesValue, unitResult);
        local minValue, maxValue, step = TimeUnitLimits(unitResult);
        displayValue = DrawSliderControl('hide_above_value_' .. unitResult, displayValue, minValue, maxValue, step, 95);
        local minutesResult = MinutesFromTimeValue(displayValue, unitResult);
        imgui.SameLine();
        unitResult = DrawTimeUnitButtons(rowId, unitResult);
        return enabledResult, minutesResult, unitResult;
    end

    return enabledResult, minutesValue, unitResult;
end

local function DrawComboAndSliderRow(rowId, comboLabel, items, selected, comboId, sliderLabel, sliderId, sliderValue, minValue, maxValue, step)
    local comboResult = selected;
    local sliderResult = sliderValue;

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##status_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##combo_label', 0, 145);
            imgui.TableSetupColumn('##combo_control', 0, 170);
            imgui.TableSetupColumn('##slider_label', 0, 145);
            imgui.TableSetupColumn('##slider_control', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, comboLabel);
            imgui.TableNextColumn();
            if (imgui.PushItemWidth ~= nil) then
                imgui.PushItemWidth(140);
            end

            comboResult = tostring(selected or items[1] or '');
            if (imgui.BeginCombo ~= nil and imgui.BeginCombo('##status_combo_' .. tostring(comboId or comboLabel), comboResult)) then
                for _, item in ipairs(items) do
                    local value = tostring(item);
                    local isSelected = value == comboResult;
                    if (imgui.Selectable(value, isSelected) == true) then
                        comboResult = value;
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
            imgui.TableNextColumn();
            sliderResult = DrawTableSlider(sliderLabel, sliderId, sliderValue, minValue, maxValue, step or 1);
            imgui.EndTable();
        end

        return comboResult, sliderResult;
    end

    comboResult = DrawComboRow(comboLabel, items, selected, nil, comboId);
    imgui.SameLine();
    sliderResult = DrawNumber(sliderLabel, sliderValue, minValue, maxValue, step or 1);
    return comboResult, sliderResult;
end

local function DrawStageTimeRow(rowId, settings)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##status_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##stage1', 0, 175);
            imgui.TableSetupColumn('##stage2', 0, 175);
            imgui.TableSetupColumn('##stage3', 0, 175);
            imgui.TableSetupColumn('##unit', 0, 70);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Stage 1');
            imgui.SameLine();
            settings.timerWarningStage1Seconds = DrawSliderControl('timer_warning_stage_1', settings.timerWarningStage1Seconds, 1, 300, 1, 56);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Stage 2');
            imgui.SameLine();
            settings.timerWarningStage2Seconds = DrawSliderControl('timer_warning_stage_2', settings.timerWarningStage2Seconds, 1, settings.timerWarningStage1Seconds, 1, 56);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Stage 3');
            imgui.SameLine();
            settings.timerWarningStage3Seconds = DrawSliderControl('timer_warning_stage_3', settings.timerWarningStage3Seconds, 1, settings.timerWarningStage2Seconds, 1, 56);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Seconds');
            imgui.EndTable();
        end

        return;
    end

    settings.timerWarningStage1Seconds = DrawNumber('Stage 1', settings.timerWarningStage1Seconds, 1, 300, 1);
    imgui.SameLine();
    settings.timerWarningStage2Seconds = DrawNumber('Stage 2', settings.timerWarningStage2Seconds, 1, settings.timerWarningStage1Seconds, 1);
    imgui.SameLine();
    settings.timerWarningStage3Seconds = DrawNumber('Stage 3', settings.timerWarningStage3Seconds, 1, settings.timerWarningStage2Seconds, 1);
    imgui.SameLine();
    imgui.TextColored(labelColor, 'Seconds');
end

local function DrawHeaderCheckbox(label, value)
    if (imgui.Checkbox ~= nil) then
        local ref = { value == true };
        imgui.Checkbox('##status_header_' .. tostring(label), ref);
        imgui.SameLine();
        DrawSectionHeader(tostring(label));
        return ref[1] == true;
    end

    return DrawCheckbox(label, value);
end

local function DrawHeaderCheckboxPair(primaryLabel, primaryValue, secondaryLabel, secondaryValue)
    if (imgui.Checkbox ~= nil) then
        local primaryRef = { primaryValue == true };
        local secondaryRef = { secondaryValue == true };

        imgui.Checkbox('##status_header_' .. tostring(primaryLabel), primaryRef);
        imgui.SameLine();
        DrawSectionHeader(tostring(primaryLabel));

        if (primaryRef[1] == true) then
            imgui.SameLine();
            imgui.Checkbox(tostring(secondaryLabel), secondaryRef);
            if (tostring(secondaryLabel) == 'Use small font') then
                uiTooltip.Info('When enabled, this uses the Small text font style configured in General > Font.');
            end
        end

        return primaryRef[1] == true, secondaryRef[1] == true;
    end

    local primaryResult = DrawCheckbox(primaryLabel, primaryValue);
    local secondaryResult = secondaryValue == true;

    if (primaryResult == true) then
        imgui.SameLine();
        secondaryResult = DrawCheckbox(secondaryLabel, secondaryResult);
        if (tostring(secondaryLabel) == 'Use small font') then
            uiTooltip.Info('When enabled, this uses the Small text font style configured in General > Font.');
        end
    end

    return primaryResult, secondaryResult;
end

local function DrawActionButton(label)
    if (imgui.Button ~= nil) then
        return imgui.Button(tostring(label)) == true;
    end

    return ClickText(tostring(label), { 1.0, 0.84, 0.0, 1.0 }) == true;
end

local function DrawTextFontRows(fontSize, fontColor, outlineSize, outlineColor)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local fontResult = fontSize;
        local fontColorResult = fontColor;
        local outlineResult = outlineSize;
        local outlineColorResult = outlineColor;

        if (imgui.BeginTable('##status_timer_text_font_rows', 4, tableFlags)) then
            imgui.TableSetupColumn('##font_label', 0, 105);
            imgui.TableSetupColumn('##font_control', 0, 170);
            imgui.TableSetupColumn('##color_label', 0, 125);
            imgui.TableSetupColumn('##color_control', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            fontResult = DrawTableSlider('Font size', 'timer_font_size', fontSize, 3, textScale.GetMaxVisualSize(), 1);
            imgui.TableNextColumn();
            fontColorResult = DrawColorCell('Font color', 'timer_text_color', fontColor);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            outlineResult = DrawTableSlider('Outline size', 'timer_outline_size', outlineSize, 0, 12, 1);
            imgui.TableNextColumn();
            outlineColorResult = DrawColorCell('Outline color', 'timer_outline_color', outlineColor);
            imgui.EndTable();
        end

        return fontResult, fontColorResult, outlineResult, outlineColorResult;
    end

    local fontResult = DrawNumber('Font size', fontSize, 3, textScale.GetMaxVisualSize(), 1);
    imgui.SameLine();
    imgui.TextColored(labelColor, 'Font color');
    imgui.SameLine();
    local fontColorResult = DrawColor('timer_text_color', fontColor);
    local outlineResult = DrawNumber('Outline size', outlineSize, 0, 12, 1);
    imgui.SameLine();
    imgui.TextColored(labelColor, 'Outline color');
    imgui.SameLine();
    local outlineColorResult = DrawColor('timer_outline_color', outlineColor);
    return fontResult, fontColorResult, outlineResult, outlineColorResult;
end

DrawComboRow = function(label, items, selected, onSelect, id)
    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (imgui.PushItemWidth ~= nil) then
        imgui.PushItemWidth(140);
    end

    local current = tostring(selected or items[1] or '');

    if (imgui.BeginCombo ~= nil and imgui.BeginCombo('##status_combo_' .. tostring(id or label), current)) then
        for _, item in ipairs(items) do
            local value = tostring(item);
            local isSelected = value == current;

            if (imgui.Selectable(value, isSelected) == true) then
                current = value;

                if (onSelect ~= nil) then
                    onSelect(value);
                end
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

    return current;
end

local function ApplyDefaults(settings, defaults)
    for key, value in pairs(defaults or {}) do
        if (settings[key] == nil) then
            settings[key] = type(value) == 'table' and { unpackTable(value) } or value;
        end
    end
end

local function Reset(settings, defaults)
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
        imgui.OpenPopup('Reset status icons##libraplates_status_icons_reset_confirm');
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
                local enabled = settings.enabled;
                Reset(settings, defaults);
                settings.enabled = enabled;
            end

            pendingReset = nil;
        end

        return;
    end

    if (imgui.BeginPopupModal('Reset status icons##libraplates_status_icons_reset_confirm')) then
        imgui.Text('Reset ' .. pendingReset.label .. '?');

        if (pendingReset.kind == 'position') then
            imgui.Text('This will reset Position X and Position Y.');
        else
            imgui.Text('This will reset all ' .. tostring(label or 'status icon') .. ' settings.');
        end

        imgui.Separator();

        if (imgui.Button('Cancel##status_icons_reset_cancel')) then
            pendingReset = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.SameLine();

        if (imgui.Button('Reset##status_icons_reset_confirm')) then
            if (pendingReset.kind == 'position') then
                settings.offsetX = defaults.offsetX;
                settings.offsetY = defaults.offsetY;
            else
                local enabled = settings.enabled;
                Reset(settings, defaults);
                settings.enabled = enabled;
            end

            pendingReset = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.EndPopup();
    end
end

local function NormalizeTimerWarningSettings(settings, defaults)
    local defaultStage1 = tonumber(defaults.timerWarningStage1Seconds) or 10;
    local defaultStage2 = tonumber(defaults.timerWarningStage2Seconds) or 8;
    local defaultStage3 = tonumber(defaults.timerWarningStage3Seconds) or 5;
    local stage1 = tonumber(settings.timerWarningStage1Seconds) or defaultStage1;
    local stage2 = tonumber(settings.timerWarningStage2Seconds) or defaultStage2;
    local stage3 = tonumber(settings.timerWarningStage3Seconds) or defaultStage3;

    if (stage1 < stage2 or stage2 < stage3) then
        stage1 = defaultStage1;
        stage2 = defaultStage2;
        stage3 = defaultStage3;
    end

    settings.timerWarningStage1Seconds = math.max(1, math.min(300, stage1));
    settings.timerWarningStage2Seconds = math.max(1, math.min(settings.timerWarningStage1Seconds, stage2));
    settings.timerWarningStage3Seconds = math.max(1, math.min(settings.timerWarningStage2Seconds, stage3));

    local function CopyColor(color, fallback)
        color = color or fallback or { 1.0, 1.0, 1.0, 1.0 };
        return { color[1] or 1.0, color[2] or 1.0, color[3] or 1.0, color[4] or 1.0 };
    end

    local stage1Color = settings.timerWarningStage1Color or defaults.timerWarningStage1Color or { 1.0, 0.90, 0.20, 1.0 };
    local stage2Color = settings.timerWarningStage2Color or defaults.timerWarningStage2Color or { 1.0, 0.50, 0.05, 1.0 };
    local stage3Color = settings.timerWarningStage3Color or defaults.timerWarningStage3Color or { 1.0, 0.15, 0.15, 1.0 };

    if (settings.timerWarningBoxStage1Color == nil) then settings.timerWarningBoxStage1Color = CopyColor(stage1Color); end
    if (settings.timerWarningBoxStage2Color == nil) then settings.timerWarningBoxStage2Color = CopyColor(stage2Color); end
    if (settings.timerWarningBoxStage3Color == nil) then settings.timerWarningBoxStage3Color = CopyColor(stage3Color); end
    if (settings.timerWarningBoxBorderStage1Color == nil) then settings.timerWarningBoxBorderStage1Color = CopyColor(stage1Color); end
    if (settings.timerWarningBoxBorderStage2Color == nil) then settings.timerWarningBoxBorderStage2Color = CopyColor(stage2Color); end
    if (settings.timerWarningBoxBorderStage3Color == nil) then settings.timerWarningBoxBorderStage3Color = CopyColor(stage3Color); end
    if (settings.timerWarningFontStage1Color == nil) then settings.timerWarningFontStage1Color = CopyColor(defaults.timerWarningFontStage1Color, settings.timerTextColor); end
    if (settings.timerWarningFontStage2Color == nil) then settings.timerWarningFontStage2Color = CopyColor(defaults.timerWarningFontStage2Color, settings.timerTextColor); end
    if (settings.timerWarningFontStage3Color == nil) then settings.timerWarningFontStage3Color = CopyColor(defaults.timerWarningFontStage3Color, settings.timerTextColor); end
    if (settings.timerWarningOutlineStage1Color == nil) then settings.timerWarningOutlineStage1Color = CopyColor(defaults.timerWarningOutlineStage1Color, settings.timerTextOutlineColor); end
    if (settings.timerWarningOutlineStage2Color == nil) then settings.timerWarningOutlineStage2Color = CopyColor(defaults.timerWarningOutlineStage2Color, settings.timerTextOutlineColor); end
    if (settings.timerWarningOutlineStage3Color == nil) then settings.timerWarningOutlineStage3Color = CopyColor(defaults.timerWarningOutlineStage3Color, settings.timerTextOutlineColor); end
    if (settings.timerWarningIconBackgroundStage1Color == nil) then settings.timerWarningIconBackgroundStage1Color = CopyColor(stage1Color); settings.timerWarningIconBackgroundStage1Color[4] = 1.0; end
    if (settings.timerWarningIconBackgroundStage2Color == nil) then settings.timerWarningIconBackgroundStage2Color = CopyColor(stage2Color); settings.timerWarningIconBackgroundStage2Color[4] = 1.0; end
    if (settings.timerWarningIconBackgroundStage3Color == nil) then settings.timerWarningIconBackgroundStage3Color = CopyColor(stage3Color); settings.timerWarningIconBackgroundStage3Color[4] = 1.0; end
    if (settings.timerWarningIconBorderStage1Color == nil) then settings.timerWarningIconBorderStage1Color = CopyColor(stage1Color); end
    if (settings.timerWarningIconBorderStage2Color == nil) then settings.timerWarningIconBorderStage2Color = CopyColor(stage2Color); end
    if (settings.timerWarningIconBorderStage3Color == nil) then settings.timerWarningIconBorderStage3Color = CopyColor(stage3Color); end

    if (settings.timerWarningBoxColorEnabled == nil) then
        settings.timerWarningBoxColorEnabled = false;
    end

    if (settings.timerWarningOutlineColorEnabled == nil) then
        settings.timerWarningOutlineColorEnabled = false;
    end

    if (settings.timerWarningBoxBorderEnabled == nil) then
        settings.timerWarningBoxBorderEnabled = false;
    end
end

local function DrawWarningColorSet(label, enabledKey, prefix, settings)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##status_warning_color_' .. prefix, 4, tableFlags)) then
            imgui.TableSetupColumn('##enabled', 0, 190);
            imgui.TableSetupColumn('##stage1', 0, 74);
            imgui.TableSetupColumn('##stage2', 0, 74);
            imgui.TableSetupColumn('##stage3', 0, 74);
            imgui.TableNextRow();

            imgui.TableNextColumn();
            settings[enabledKey] = DrawCheckbox(label .. ' Stage:', settings[enabledKey]);

            if (settings[enabledKey] == true) then
                imgui.TableNextColumn();
                imgui.TextColored(labelColor, '1');
                imgui.SameLine();
                settings[prefix .. 'Stage1Color'] = DrawColor(prefix .. '_stage_1', settings[prefix .. 'Stage1Color']);
                imgui.TableNextColumn();
                imgui.TextColored(labelColor, '2');
                imgui.SameLine();
                settings[prefix .. 'Stage2Color'] = DrawColor(prefix .. '_stage_2', settings[prefix .. 'Stage2Color']);
                imgui.TableNextColumn();
                imgui.TextColored(labelColor, '3');
                imgui.SameLine();
                settings[prefix .. 'Stage3Color'] = DrawColor(prefix .. '_stage_3', settings[prefix .. 'Stage3Color']);
            end

            imgui.EndTable();
        end

        return;
    end

    settings[enabledKey] = DrawCheckbox(label .. ' Stage:', settings[enabledKey]);

    if (settings[enabledKey] ~= true) then
        return;
    end

    imgui.SameLine();
    imgui.TextColored(labelColor, '1');
    imgui.SameLine();
    settings[prefix .. 'Stage1Color'] = DrawColor(prefix .. '_stage_1', settings[prefix .. 'Stage1Color']);
    imgui.SameLine();
    imgui.TextColored(labelColor, '2');
    imgui.SameLine();
    settings[prefix .. 'Stage2Color'] = DrawColor(prefix .. '_stage_2', settings[prefix .. 'Stage2Color']);
    imgui.SameLine();
    imgui.TextColored(labelColor, '3');
    imgui.SameLine();
    settings[prefix .. 'Stage3Color'] = DrawColor(prefix .. '_stage_3', settings[prefix .. 'Stage3Color']);
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

        if (imgui.BeginCombo('##status_anchor_' .. tostring(id), value) == true) then
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

local function DrawAnchorControls(settings, context, label)
    anchorControls.Draw(settings, context, label);
end

function statusIcons.DrawSettings(settings, context)
    if (settings == nil) then
        return;
    end

    local defaults = context ~= nil and context.defaults or {};
    local label = tostring(context ~= nil and context.widget or 'Status icons');
    local itemLabel = (label == 'Buffs') and 'Buff' or ((label == 'Debuffs') and 'Debuff' or 'Icon');
    local itemPlural = (label == 'Buffs') and 'Buffs' or ((label == 'Debuffs') and 'Debuffs' or 'Icons');

    ApplyDefaults(settings, defaults);

    if (context == nil or context.hideActive ~= true) then
        settings.enabled = DrawCheckbox('Active', settings.enabled);
    end
    DrawAnchorControls(settings, context, itemPlural);

    imgui.Separator();
    DrawSectionHeader(itemLabel .. ' settings');
    settings.iconPack = nil;
    settings.growthDirection, settings.iconSize = DrawComboAndSliderRow(
        'icon_size_growth',
        'Growth direction',
        { 'Right', 'Left' },
        settings.growthDirection or defaults.growthDirection or 'Right',
        'growth_direction_' .. tostring(label),
        itemLabel .. ' size',
        'icon_size',
        settings.iconSize,
        8,
        160,
        1
    );

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

    settings.iconWarningPadding, settings.iconSpacing = DrawSliderPair(
        'icon_padding_spacing',
        itemLabel .. ' padding',
        'icon_warning_padding',
        settings.iconWarningPadding,
        0,
        32,
        itemLabel .. ' spacer',
        'icon_spacing',
        settings.iconSpacing,
        0,
        32
    );

    settings.maxIcons, settings.iconsPerRow = DrawSliderPair(
        'icon_counts',
        'Max ' .. string.lower(itemPlural),
        'max_icons',
        settings.maxIcons,
        1,
        64,
        itemPlural .. ' per row',
        'icons_per_row',
        settings.iconsPerRow,
        1,
        24
    );

    imgui.Separator();
    DrawSectionHeader('Timer settings');
    settings.showTimers = DrawCheckbox('Show timers', settings.showTimers);
    imgui.SameLine();
    settings.timerUseSmallFont = DrawCheckbox('Use small font', settings.timerUseSmallFont);

    if (settings.showTimers == true) then
        settings.timerFontSize, settings.timerTextColor, settings.timerTextOutlineSize, settings.timerTextOutlineColor = DrawTextFontRows(
            settings.timerFontSize,
            settings.timerTextColor,
            settings.timerTextOutlineSize,
            settings.timerTextOutlineColor
        );
        settings.timerTextOutline = settings.timerTextOutlineSize > 0;

        imgui.Separator();
        settings.timerBackground = DrawCheckbox('Show timer background', settings.timerBackground);

        if (settings.timerBackground == true) then
            imgui.TextColored(labelColor, 'BG color');
            imgui.SameLine();
            settings.timerBackgroundColor = DrawColor('timer_box_bg_color', settings.timerBackgroundColor);

            settings.timerBackgroundPaddingX, settings.timerBackgroundPaddingY = DrawSliderPair(
                'timer_padding',
                'BG padding X',
                'timer_pad_x',
                settings.timerBackgroundPaddingX,
                0,
                24,
                'BG padding Y',
                'timer_pad_y',
                settings.timerBackgroundPaddingY,
                0,
                24
            );

            settings.timerCornerRadius, settings.timerOffsetY = DrawSliderPair(
                'timer_corner_spacer',
                'BG corner radius',
                'timer_corner_radius',
                settings.timerCornerRadius,
                0,
                40,
                'BG box spacer',
                'timer_y',
                settings.timerOffsetY,
                -40,
                40
            );

            settings.timerBackgroundBorderSize, settings.timerBackgroundBorderColor = DrawSliderAndColorRow(
                'timer_box_border',
                'BG border size',
                'timer_box_border_size',
                settings.timerBackgroundBorderSize,
                0,
                12,
                'BG border color',
                'timer_box_border_color',
                settings.timerBackgroundBorderColor
            );
        end

    end

    imgui.Separator();

    if (label == 'Buffs') then
        DrawSectionHeader('Buff filtering');
        settings.hideAboveDurationEnabled, settings.hideAboveDurationMinutes, settings.hideAboveDurationUnit = DrawBuffFilterDurationRow(
            'buff_filter_duration',
            settings.hideAboveDurationEnabled,
            settings.hideAboveDurationMinutes,
            settings.hideAboveDurationUnit
        );
        DrawHideBuffsMode(settings);
    elseif (label == 'Debuffs') then
        DrawSectionHeader('Debuff filtering');
        settings.hideOutOfCombat = DrawCheckbox('Hide debuffs out of combat', settings.hideOutOfCombat);
    end

    NormalizeTimerWarningSettings(settings, defaults);
    settings.timerWarningEnabled = DrawCheckbox('Expiring warnings', settings.timerWarningEnabled);
    uiTooltip.Info('Uses warning stages when seconds left is at or below the stage value.');

    if (settings.timerWarningEnabled == true) then
        DrawStageTimeRow('timer_warning_stages', settings);
        settings.timerWarningStage2Seconds = math.min(settings.timerWarningStage1Seconds, settings.timerWarningStage2Seconds);
        settings.timerWarningStage3Seconds = math.min(settings.timerWarningStage2Seconds, settings.timerWarningStage3Seconds);
    end

    imgui.Separator();
    DrawSectionHeader('Duration warning colors:');
    DrawWarningColorSet('Font', 'timerWarningTextColorEnabled', 'timerWarningFont', settings);
    DrawWarningColorSet('Text outline', 'timerWarningOutlineColorEnabled', 'timerWarningOutline', settings);
    DrawWarningColorSet('Background', 'timerWarningBackgroundEnabled', 'timerWarningIconBackground', settings);
    DrawWarningColorSet('Icon border', 'timerWarningBorderEnabled', 'timerWarningIconBorder', settings);
    if (settings.timerBackground == true) then
        DrawWarningColorSet('Box color', 'timerWarningBoxColorEnabled', 'timerWarningBox', settings);
        DrawWarningColorSet('Box border', 'timerWarningBoxBorderEnabled', 'timerWarningBoxBorder', settings);
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

return statusIcons;
