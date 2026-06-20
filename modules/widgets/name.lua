local defaults = require('config.widgets.name');
local textScale = require('core.text_scale');
local imgui = require('imgui');
local anchorControls = require('modules.widgets.anchor_controls');

local name = {};
local unpackTable = table.unpack or unpack;
local anchorTargets = T{ 'Plate', 'HP Bar', 'MP Bar', 'TP Bar' };
local anchorPoints = T{ 'Top', 'Center', 'Bottom', 'Left', 'Right' };
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
    and bit.bor(_G.ImGuiColorEditFlags_NoAlpha or 0, _G.ImGuiColorEditFlags_NoInputs or 0)
    or ((_G.ImGuiColorEditFlags_NoAlpha or 0) + (_G.ImGuiColorEditFlags_NoInputs or 0));
local tableFlags = (_G.ImGuiTableFlags_SizingFixedFit or 0) + (_G.ImGuiTableFlags_BordersInnerH or 0);
local pendingReset = nil;
local heldButtonState = {};

local function ClickText(label, color)
    imgui.TextColored(color or { 0.65, 0.90, 1.0, 1.0 }, label);

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
    local amount = step or 1;

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

    if (minValue ~= nil and current < minValue) then
        current = minValue;
    end

    if (maxValue ~= nil and current > maxValue) then
        current = maxValue;
    end

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
        if (IsHeldButton('-##name_' .. id .. '_minus')) then
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
        imgui.InputText('##name_' .. id, ref, 16);
    else
        imgui.SliderInt('##name_' .. id, ref, minimum, maximum);
    end

    if (imgui.PopItemWidth ~= nil) then
        imgui.PopItemWidth();
    end

    current = tonumber(ref[1]) or current;

    if (showButtons ~= false and imgui.Button ~= nil) then
        imgui.SameLine();

        if (IsHeldButton('+##name_' .. id .. '_plus')) then
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

        if (imgui.BeginTable('##name_' .. rowId, 4, tableFlags)) then
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

local function DrawChoice(label, value, options)
    local current = tostring(value or options[1]);

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

local function ClampColorChannel(value)
    local channel = tonumber(value) or 0;

    if (channel < 0) then
        return 0;
    end

    if (channel > 1) then
        return 1;
    end

    return channel;
end

local function DrawColor(label, value)
    local color = value or { 1.0, 1.0, 1.0, 1.0 };
    local red = math.floor(ClampColorChannel(color[1]) * 255);
    local green = math.floor(ClampColorChannel(color[2]) * 255);
    local blue = math.floor(ClampColorChannel(color[3]) * 255);
    local edit = nil;

    if (imgui.ColorEdit4 ~= nil) then
        imgui.ColorEdit4('##name_' .. label, color, colorEditFlags);
        return color;
    end

    imgui.TextColored(color, label);

    imgui.SameLine();
    imgui.TextColored(valueColor, tostring(red) .. '/' .. tostring(green) .. '/' .. tostring(blue));
    imgui.SameLine();

    if (ClickText('red-', actionColor) == true) then
        edit = 'red-';
    end

    imgui.SameLine();

    if (ClickText('red+', actionColor) == true) then
        edit = 'red+';
    end

    imgui.SameLine();

    if (ClickText('green-', actionColor) == true) then
        edit = 'green-';
    end

    imgui.SameLine();

    if (ClickText('green+', actionColor) == true) then
        edit = 'green+';
    end

    imgui.SameLine();

    if (ClickText('blue-', actionColor) == true) then
        edit = 'blue-';
    end

    imgui.SameLine();

    if (ClickText('blue+', actionColor) == true) then
        edit = 'blue+';
    end

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

local function DrawLabeledColor(label, value)
    imgui.TextColored(labelColor, label);
    imgui.SameLine();
    return DrawColor(label:gsub('%s+', '_'), value);
end

local DrawColorCell = nil;

local function DrawClaimColorRow(label, colorValue, outlineValue)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##claim_color_' .. label:gsub('%s+', '_'), 4, tableFlags)) then
            imgui.TableSetupColumn('##claim_color_label', 0, 170);
            imgui.TableSetupColumn('##claim_color_control', 0, 170);
            imgui.TableSetupColumn('##claim_outline_label', 0, 170);
            imgui.TableSetupColumn('##claim_outline_control', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            colorValue = DrawColorCell(label, colorValue);
            imgui.TableNextColumn();
            outlineValue = DrawColorCell('Outline color', outlineValue);
            imgui.EndTable();
        end

        return colorValue, outlineValue;
    end

    colorValue = DrawLabeledColor(label, colorValue);
    outlineValue = DrawLabeledColor(label .. ' outline', outlineValue);
    return colorValue, outlineValue;
end

DrawColorCell = function(label, color)
    imgui.TextColored(labelColor, label);
    imgui.TableNextColumn();
    return DrawColor(label:gsub('%s+', '_'), color);
end

local function DrawFontRow(settings, context)
    local maxFontSize = 40;
    local showColor = context == nil or context.entity ~= 'Enemy';

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##name_font_row', showColor == true and 4 or 2, tableFlags)) then
            imgui.TableSetupColumn('##font_size_label', 0, 145);
            imgui.TableSetupColumn('##font_size_control', 0, 170);
            if (showColor == true) then
                imgui.TableSetupColumn('##font_color_label', 0, 145);
                imgui.TableSetupColumn('##font_color_control', 0, 170);
            end
            imgui.TableNextRow();
            imgui.TableNextColumn();
            settings.textSize = DrawTableSlider('Font size', 'font_size', math.min(maxFontSize, textScale.NormalizeSetting(settings.textSize, defaults.textSize)), textScale.GetMinVisualSize(), maxFontSize);
            if (showColor == true) then
                imgui.TableNextColumn();
                settings.color = DrawColorCell('Font color', settings.color);
            end
            imgui.EndTable();
        end

        return;
    end

    settings.textSize = DrawNumber('Font size', math.min(maxFontSize, textScale.NormalizeSetting(settings.textSize, defaults.textSize)), textScale.GetMinVisualSize(), maxFontSize, 1);
    if (showColor == true) then
        settings.color = DrawColor('Font color', settings.color);
    end
end

local function DrawOutlineRow(settings)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##name_outline_row', 4, tableFlags)) then
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

local function ColorToU32(color)
    local red = math.floor(ClampColorChannel(color[1]) * 255);
    local green = math.floor(ClampColorChannel(color[2]) * 255);
    local blue = math.floor(ClampColorChannel(color[3]) * 255);
    local alpha = math.floor(ClampColorChannel(color[4] or 1.0) * 255);

    return (alpha * 0x1000000) + (red * 0x10000) + (green * 0x100) + blue;
end

local function ApplyDefaults(settings)
    for key, value in pairs(defaults) do
        if (settings[key] == nil) then
            if (type(value) == 'table') then
                settings[key] = { unpackTable(value) };
            else
                settings[key] = value;
            end
        end
    end

    if (settings.textSize == nil and settings.fontSize ~= nil) then
        settings.textSize = settings.fontSize;
        settings.fontSize = nil;
    end

    if (settings.outlineEnabled == nil and settings.borderEnabled ~= nil) then
        settings.outlineEnabled = settings.borderEnabled;
        settings.borderEnabled = nil;
    end

    if (settings.outlineSize == nil and settings.borderSize ~= nil) then
        settings.outlineSize = settings.borderSize;
        settings.borderSize = nil;
    end

    if (settings.outlineColor == nil and settings.borderColor ~= nil) then
        settings.outlineColor = settings.borderColor;
        settings.borderColor = nil;
    end
end

local function ResetSettings(settings)
    for key, value in pairs(defaults) do
        if (type(value) == 'table') then
            settings[key] = { unpackTable(value) };
        else
            settings[key] = value;
        end
    end
end

local function RequestReset(kind, label)
    pendingReset = {
        kind = kind,
        label = label,
    };

    if (imgui.OpenPopup ~= nil) then
        imgui.OpenPopup('Reset name##libraplates_name_reset_confirm');
    end
end

local function DrawResetConfirm(settings)
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
                ResetSettings(settings);
            end

            pendingReset = nil;
        end

        return;
    end

    if (imgui.BeginPopupModal('Reset name##libraplates_name_reset_confirm')) then
        imgui.Text('Reset ' .. pendingReset.label .. '?');

        if (pendingReset.kind == 'position') then
            imgui.Text('This will reset Position X and Position Y.');
        else
            imgui.Text('This will reset all Name settings.');
        end

        imgui.Separator();

        if (imgui.Button('Cancel##name_reset_cancel')) then
            pendingReset = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.SameLine();

        if (imgui.Button('Reset##name_reset_confirm')) then
            if (pendingReset.kind == 'position') then
                settings.offsetX = defaults.offsetX;
                settings.offsetY = defaults.offsetY;
            else
                ResetSettings(settings);
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
        if (imgui.BeginCombo('##name_anchor_' .. label, value) == true) then
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

local function DrawAnchorControls(settings, context)
    anchorControls.Draw(settings, context, 'Name');
end

-- ============================================================
-- Defaults
-- ============================================================

function name.GetDefaults()
    return defaults;
end

-- ============================================================
-- Rendering
-- ============================================================

function name.Draw(data, settings, context)
    if (settings == nil or settings.enabled ~= true or context == nil or context.drawList == nil) then
        return;
    end

    ApplyDefaults(settings);

    local text = tostring((data ~= nil and data.name) or 'Libra');

    if ((tonumber(settings.shortenName) or 0) > 0 and string.len(text) > settings.shortenName) then
        text = string.sub(text, 1, settings.shortenName);
    end

    local x, y = context.canvas.ToScreen(context.bounds, settings.offsetX, settings.offsetY);
    x, y = context.canvas.ClampPoint(context.bounds, x, y);

    context.drawList:AddText({ x, y }, ColorToU32(settings.color), text);
end

-- ============================================================
-- Settings UI
-- ============================================================

function name.DrawSettings(settings, context)
    if (settings == nil) then
        return;
    end

    ApplyDefaults(settings);

    if (context == nil or context.hideActive ~= true) then
        settings.enabled = DrawCheckbox('Active', settings.enabled);
    end

    if ((tonumber(settings.textSize) or defaults.textSize) > 40) then
        settings.textSize = 40;
    end

    DrawAnchorControls(settings, context);

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
    DrawFontRow(settings, context);
    DrawOutlineRow(settings);
    settings.outlineEnabled = (tonumber(settings.outlineSize) or 0) > 0;

    if (context ~= nil and context.entity == 'Enemy') then
        imgui.Separator();
        DrawSectionHeader('Claim colors');
        settings.claimUnclaimedColor, settings.claimUnclaimedOutlineColor = DrawClaimColorRow('Unclaimed', settings.claimUnclaimedColor, settings.claimUnclaimedOutlineColor);
        settings.claimPartyColor, settings.claimPartyOutlineColor = DrawClaimColorRow('Claimed', settings.claimPartyColor, settings.claimPartyOutlineColor);
        settings.claimOtherColor, settings.claimOtherOutlineColor = DrawClaimColorRow('Claimed by others', settings.claimOtherColor, settings.claimOtherOutlineColor);
        settings.claimCallForHelpColor, settings.claimCallForHelpOutlineColor = DrawClaimColorRow('Call for help', settings.claimCallForHelpColor, settings.claimCallForHelpOutlineColor);
    end

    imgui.Separator();

    if (DrawActionButton('Reset Name position') == true) then
        RequestReset('position', 'Name position');
    end

    if (DrawActionButton('Reset Name settings') == true) then
        RequestReset('settings', 'Name settings');
    end

    DrawResetConfirm(settings);
end

return name;
