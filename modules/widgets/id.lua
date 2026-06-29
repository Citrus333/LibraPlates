local imgui = require('imgui');
local defaults = require('config.widgets.id');
local textScale = require('core.text_scale');
local anchorControls = require('modules.widgets.anchor_controls');
local uiTooltip = require('core.ui_tooltip');

local id = {};
local unpackTable = table.unpack or unpack;
local labelColor = { 0.92, 0.92, 0.90, 1.0 };
local valueColor = { 0.65, 0.90, 1.0, 1.0 };
local actionColor = { 1.0, 0.84, 0.0, 1.0 };
local tableFlags = (_G.ImGuiTableFlags_SizingFixedFit or 0) + (_G.ImGuiTableFlags_BordersInnerH or 0);
local colorEditFlags = (_G.ImGuiColorEditFlags_NoInputs or 0) + (_G.ImGuiColorEditFlags_AlphaPreviewHalf or 0);
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

    if (imgui.IsItemHovered ~= nil and imgui.IsMouseDown ~= nil) then
        return imgui.IsItemHovered() == true and imgui.IsMouseDown(0) == true;
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

local function DrawNumberControl(idValue, value, minValue, maxValue, width)
    local current = tonumber(value) or 0;

    if (imgui.Button ~= nil and IsHeldButton('-##id_' .. idValue .. '_minus') == true) then
        current = current - 1;
    end

    imgui.SameLine();

    if (imgui.InputText ~= nil) then
        local ref = { tostring(math.floor(current + 0.5)) };

        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(width or 92);
        end

        imgui.InputText('##id_' .. idValue .. '_input', ref, 16);

        if (imgui.PopItemWidth ~= nil) then
            imgui.PopItemWidth();
        end

        current = tonumber(ref[1]) or current;
    else
        imgui.TextColored(valueColor, tostring(current));
    end

    imgui.SameLine();

    if (imgui.Button ~= nil and IsHeldButton('+##id_' .. idValue .. '_plus') == true) then
        current = current + 1;
    end

    if (minValue ~= nil and current < minValue) then current = minValue; end
    if (maxValue ~= nil and current > maxValue) then current = maxValue; end

    return current;
end

local function DrawNumber(label, value, minValue, maxValue, step)
    imgui.TextColored(labelColor, label);
    imgui.SameLine();
    return DrawNumberControl(label:gsub('%s+', '_'), value, minValue, maxValue);
end

local function DrawTableNumber(label, idValue, value, minValue, maxValue)
    imgui.TextColored(labelColor, label);
    imgui.TableNextColumn();
    return DrawNumberControl(idValue, value, minValue, maxValue);
end

local function DrawNumberPair(rowId, leftLabel, leftId, leftValue, leftMin, leftMax, rightLabel, rightId, rightValue, rightMin, rightMax)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local nextLeft = leftValue;
        local nextRight = rightValue;

        if (imgui.BeginTable('##id_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##left_label', 0, 118);
            imgui.TableSetupColumn('##left_control', 0, 170);
            imgui.TableSetupColumn('##right_label', 0, 118);
            imgui.TableSetupColumn('##right_control', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            nextLeft = DrawTableNumber(leftLabel, leftId, leftValue, leftMin, leftMax);
            imgui.TableNextColumn();
            nextRight = DrawTableNumber(rightLabel, rightId, rightValue, rightMin, rightMax);
            imgui.EndTable();
        end

        return nextLeft, nextRight;
    end

    local nextLeft = DrawNumber(leftLabel, leftValue, leftMin, leftMax, 1);
    imgui.SameLine();
    local nextRight = DrawNumber(rightLabel, rightValue, rightMin, rightMax, 1);
    return nextLeft, nextRight;
end

local function ClampChannel(value)
    value = tonumber(value) or 0;
    if (value < 0) then return 0; end
    if (value > 1) then return 1; end
    return value;
end

local function DrawColor(label, color)
    color = color or { 1.0, 1.0, 1.0, 1.0 };
    local red = math.floor(ClampChannel(color[1]) * 255);
    local green = math.floor(ClampChannel(color[2]) * 255);
    local blue = math.floor(ClampChannel(color[3]) * 255);

    if (imgui.ColorEdit4 ~= nil) then
        imgui.ColorEdit4('##id_' .. label, color, colorEditFlags);
        return color;
    end

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
    color[4] = tonumber(color[4]) or 1.0;

    return color;
end

local function DrawColorCell(label, idValue, color)
    imgui.TextColored(labelColor, label);
    imgui.TableNextColumn();
    return DrawColor(idValue, color);
end

local function DrawFontRow(settings)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##id_font_row', 4, tableFlags)) then
            imgui.TableSetupColumn('##font_size_label', 0, 118);
            imgui.TableSetupColumn('##font_size_control', 0, 170);
            imgui.TableSetupColumn('##font_color_label', 0, 118);
            imgui.TableSetupColumn('##font_color_control', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            settings.textSize = DrawTableNumber('Font size', 'font_size', textScale.NormalizeSetting(settings.textSize, defaults.textSize), textScale.GetMinVisualSize(), textScale.GetMaxVisualSize());
            imgui.TableNextColumn();
            settings.color = DrawColorCell('Font color', 'font_color', settings.color);
            imgui.EndTable();
        end

        return;
    end

    settings.textSize = DrawNumber('Font size', textScale.NormalizeSetting(settings.textSize, defaults.textSize), textScale.GetMinVisualSize(), textScale.GetMaxVisualSize(), 1);
    settings.color = DrawColor('font_color', settings.color);
end

local function DrawOutlineRow(settings)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##id_outline_row', 4, tableFlags)) then
            imgui.TableSetupColumn('##outline_size_label', 0, 118);
            imgui.TableSetupColumn('##outline_size_control', 0, 170);
            imgui.TableSetupColumn('##outline_color_label', 0, 118);
            imgui.TableSetupColumn('##outline_color_control', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            settings.outlineSize = DrawTableNumber('Outline size', 'outline_size', settings.outlineSize, 0, 8);
            imgui.TableNextColumn();
            settings.outlineColor = DrawColorCell('Outline color', 'outline_color', settings.outlineColor);
            imgui.EndTable();
        end

        return;
    end

    settings.outlineSize = DrawNumber('Outline size', settings.outlineSize, 0, 8, 1);
    settings.outlineColor = DrawColor('outline_color', settings.outlineColor);
end

local function DrawBoxColorRow(settings)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##id_box_color_row', 4, tableFlags)) then
            imgui.TableSetupColumn('##box_color_label', 0, 118);
            imgui.TableSetupColumn('##box_color_control', 0, 170);
            imgui.TableSetupColumn('##border_color_label', 0, 118);
            imgui.TableSetupColumn('##border_color_control', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            settings.boxBackgroundColor = DrawColorCell('Box color', 'box_color', settings.boxBackgroundColor);
            imgui.TableNextColumn();
            settings.boxBorderColor = DrawColorCell('Border color', 'border_color', settings.boxBorderColor);
            imgui.EndTable();
        end

        return;
    end

    settings.boxBackgroundColor = DrawColor('box_color', settings.boxBackgroundColor);
    settings.boxBorderColor = DrawColor('border_color', settings.boxBorderColor);
end

local function DrawAnchorCombo(idValue, current, choices)
    local value = tostring(current or 'Plate');

    if (value == 'Plate') then
        value = 'None';
    end

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(230);
        end

        if (imgui.BeginCombo('##id_anchor_' .. tostring(idValue), value) == true) then
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
    anchorControls.Draw(settings, context, 'ID');
end

local function ApplyDefaults(settings)
    for key, value in pairs(defaults) do
        if (settings[key] == nil) then
            settings[key] = type(value) == 'table' and { unpackTable(value) } or value;
        end
    end
end

local function Reset(settings)
    for key, value in pairs(defaults) do
        settings[key] = type(value) == 'table' and { unpackTable(value) } or value;
    end
end

function id.DrawSettings(settings, context)
    if (settings == nil) then
        return;
    end

    ApplyDefaults(settings);

    if ((context == nil or context.onlyPlacement ~= true) and (context == nil or context.boxed ~= true)) then
        DrawSectionHeader('ID settings');
    end
    if (context == nil or context.hideActive ~= true) then
        settings.enabled = DrawToggle('Active', settings.enabled);
    end

    if (context == nil or context.skipPlacement ~= true) then
        DrawAnchorControls(settings, context);
    end

    if (context ~= nil and context.onlyPlacement == true) then
        return;
    end

    local boxed = context ~= nil and context.boxed == true and _G.LibraPlatesSettingsDrawBoxedPanel ~= nil;

    local function DrawPanel(label, render, first)
        if (boxed == true) then
            _G.LibraPlatesSettingsDrawBoxedPanel(label, render, first);
        else
            if (first ~= true) then
                imgui.Separator();
                DrawSectionHeader(label);
            end
            render();
        end
    end

    DrawPanel('ID', function()
        settings.offsetX, settings.offsetY = DrawNumberPair(
            'position',
            'Position X', 'position_x', settings.offsetX, -400, 400,
            'Position Y', 'position_y', settings.offsetY, -400, 400
        );
    end, true);

    DrawPanel('Text Settings', function()
        DrawFontRow(settings);
        settings.useSmallFont = DrawToggle('Use small font', settings.useSmallFont);
        uiTooltip.Info('When enabled, this uses the Small text font style configured in General > Font.');
        settings.outlineEnabled = DrawToggle('Outline', settings.outlineEnabled);

        if (settings.outlineEnabled == true) then
            DrawOutlineRow(settings);
        end
    end);

    DrawPanel('Box Settings', function()
        settings.boxEnabled = DrawToggle('Box', settings.boxEnabled);

        if (settings.boxEnabled == true) then
            DrawBoxColorRow(settings);
            settings.boxSize, settings.cornerRadius = DrawNumberPair(
                'box_size',
                'Box size', 'box_size', settings.boxSize, 4, 160,
                'Corner radius', 'corner_radius', settings.cornerRadius, 0, 40
            );
            settings.boxBorderSize = DrawNumber('Border size', settings.boxBorderSize, 0, 20, 1);
            settings.boxDifficultyColorsEnabled = DrawToggle('Use difficulty box colors', settings.boxDifficultyColorsEnabled);

            if (settings.boxDifficultyColorsEnabled == true) then
                if (boxed ~= true) then
                    imgui.Separator();
                    DrawSectionHeader('Difficulty colors');
                end

                if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
                    if (imgui.BeginTable('##id_difficulty_colors', 6, tableFlags)) then
                        imgui.TableSetupColumn('##tw_label', 0, 58);
                        imgui.TableSetupColumn('##tw_control', 0, 96);
                        imgui.TableSetupColumn('##ep_label', 0, 58);
                        imgui.TableSetupColumn('##ep_control', 0, 96);
                        imgui.TableSetupColumn('##dc_label', 0, 58);
                        imgui.TableSetupColumn('##dc_control', 0, 96);
                        imgui.TableNextRow();
                        imgui.TableNextColumn();
                        settings.boxTwColor = DrawColorCell('TW', 'tw_box', settings.boxTwColor);
                        imgui.TableNextColumn();
                        settings.boxEpColor = DrawColorCell('EP', 'ep_box', settings.boxEpColor);
                        imgui.TableNextColumn();
                        settings.boxDcColor = DrawColorCell('DC', 'dc_box', settings.boxDcColor);
                        imgui.TableNextRow();
                        imgui.TableNextColumn();
                        settings.boxEmColor = DrawColorCell('EM', 'em_box', settings.boxEmColor);
                        imgui.TableNextColumn();
                        settings.boxTColor = DrawColorCell('T', 't_box', settings.boxTColor);
                        imgui.TableNextColumn();
                        settings.boxVtColor = DrawColorCell('VT', 'vt_box', settings.boxVtColor);
                        imgui.TableNextRow();
                        imgui.TableNextColumn();
                        settings.boxItColor = DrawColorCell('IT', 'it_box', settings.boxItColor);
                        imgui.EndTable();
                    end
                else
                    settings.boxTwColor = DrawColor('tw_box', settings.boxTwColor);
                    settings.boxEpColor = DrawColor('ep_box', settings.boxEpColor);
                    settings.boxDcColor = DrawColor('dc_box', settings.boxDcColor);
                    settings.boxEmColor = DrawColor('em_box', settings.boxEmColor);
                    settings.boxTColor = DrawColor('t_box', settings.boxTColor);
                    settings.boxVtColor = DrawColor('vt_box', settings.boxVtColor);
                    settings.boxItColor = DrawColor('it_box', settings.boxItColor);
                end
            end
        end
    end);

    if (context ~= nil and context.boxed == true) then
        imgui.Spacing();
        imgui.Spacing();
    else
        imgui.Separator();
    end

    if (DrawActionButton('Reset ID position') == true) then
        settings.offsetX = defaults.offsetX;
        settings.offsetY = defaults.offsetY;
    end

    if (DrawActionButton('Reset ID settings') == true) then
        Reset(settings);
    end
end

return id;
