local imgui = require('imgui');
local anchorControls = require('modules.widgets.anchor_controls');
local backgroundTextures = require('core.background_textures');

local background = {};
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

local function DrawCheckbox(label, value)
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

local function DrawTexturePreviewTooltip(fileName)
    local textureId = backgroundTextures.GetTextureId(fileName);

    if (imgui.IsItemHovered == nil or imgui.IsItemHovered() ~= true) then
        return;
    end

    if (
        textureId ~= nil and
        imgui.BeginTooltip ~= nil and
        imgui.EndTooltip ~= nil and
        imgui.Image ~= nil
    ) then
        imgui.BeginTooltip();
        imgui.Text(tostring(fileName or ''));
        imgui.Image(textureId, { 220, 110 }, { 0, 0 }, { 1, 1 });
        imgui.EndTooltip();
    elseif (imgui.SetTooltip ~= nil) then
        imgui.SetTooltip(tostring(fileName or ''));
    end
end

local function DrawTextureFile(label, current)
    local files = backgroundTextures.GetFiles();
    local value = tostring(current or files[1] or 'None');

    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        local comboOpen = imgui.BeginCombo('##background_texture_' .. tostring(label), value) == true;
        DrawTexturePreviewTooltip(value);

        if (comboOpen == true) then
            for _, file in ipairs(files) do
                local selected = (file == value);

                if (imgui.Selectable(tostring(file), selected) == true) then
                    value = file;
                end
                DrawTexturePreviewTooltip(file);

                if (selected == true and imgui.SetItemDefaultFocus ~= nil) then
                    imgui.SetItemDefaultFocus();
                end
            end

            imgui.EndCombo();
        end

        return value;
    end

    imgui.TextColored(valueColor, '[' .. value .. ' v]');
    return value;
end

local function DrawNumberFallback(label, value, minValue, maxValue, step)
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

local function DrawAnchorCombo(id, current, choices)
    local value = tostring(current or 'Plate');

    if (value == 'Plate') then
        value = 'None';
    end

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(230);
        end

        if (imgui.BeginCombo('##background_anchor_' .. tostring(id), value) == true) then
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

local DrawSliderControl = nil;

local function DrawSliderInt(label, id, value, minValue, maxValue, width)
    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    return DrawSliderControl(id, value, minValue, maxValue, width);
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

DrawSliderControl = function(id, value, minValue, maxValue, width)
    local current = math.floor((tonumber(value) or 0) + 0.5);
    local minimum = minValue or -1000;
    local maximum = maxValue or 1000;

    if (imgui.InputText == nil and imgui.SliderInt == nil) then
        return DrawNumberFallback('', value, minValue, maxValue, 1);
    end

    if (imgui.Button ~= nil) then
        if (IsHeldButton('-##background_' .. id .. '_minus')) then
            current = current - 1;
        end

        imgui.SameLine();
    end

    if (imgui.PushItemWidth ~= nil) then
        imgui.PushItemWidth(width or 95);
    end

    local ref = { current };
    if (imgui.InputText ~= nil) then
        ref = { tostring(current) };
        imgui.InputText('##background_' .. id, ref, 16);
    else
        imgui.SliderInt('##background_' .. id, ref, minimum, maximum);
    end

    if (imgui.PopItemWidth ~= nil) then
        imgui.PopItemWidth();
    end

    current = tonumber(ref[1]) or current;

    if (imgui.Button ~= nil) then
        imgui.SameLine();

        if (IsHeldButton('+##background_' .. id .. '_plus')) then
            current = current + 1;
        end
    end

    if (minValue ~= nil and current < minValue) then current = minValue; end
    if (maxValue ~= nil and current > maxValue) then current = maxValue; end

    return current;
end

local function DrawTableSlider(label, id, value, minValue, maxValue)
    imgui.TextColored(labelColor, label);
    imgui.TableNextColumn();
    return DrawSliderControl(id, value, minValue, maxValue, 58);
end

local function DrawSliderPair(rowId, leftLabel, leftId, leftValue, leftMin, leftMax, rightLabel, rightId, rightValue, rightMin, rightMax)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local leftResult = leftValue;
        local rightResult = rightValue;

        if (imgui.BeginTable('##background_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##label_left', 0, 104);
            imgui.TableSetupColumn('##control_left', 0, 124);
            imgui.TableSetupColumn('##label_right', 0, 104);
            imgui.TableSetupColumn('##control_right', 0, 124);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            leftResult = DrawTableSlider(leftLabel, leftId, leftValue, leftMin, leftMax);
            imgui.TableNextColumn();
            rightResult = DrawTableSlider(rightLabel, rightId, rightValue, rightMin, rightMax);
            imgui.EndTable();
        end

        return leftResult, rightResult;
    end

    local leftResult = DrawSliderInt(leftLabel, leftId, leftValue, leftMin, leftMax, 95);
    imgui.SameLine();
    local rightResult = DrawSliderInt(rightLabel, rightId, rightValue, rightMin, rightMax, 95);
    return leftResult, rightResult;
end

local function ClampChannel(value)
    value = tonumber(value) or 0;
    if (value < 0) then return 0; end
    if (value > 1) then return 1; end
    return value;
end

local function DrawOpacitySlider(color)
    color[4] = ClampChannel(color[4] or 1.0);

    if (imgui.SliderInt == nil) then
        color[4] = DrawNumberFallback('Opacity', math.floor(color[4] * 100), 0, 100, 5) / 100;
        return color;
    end

    if (imgui.PushItemWidth ~= nil) then
        imgui.PushItemWidth(58);
    end

    local ref = { math.floor((color[4] * 100) + 0.5) };
    imgui.SliderInt('##background_opacity', ref, 0, 100);

    if (imgui.PopItemWidth ~= nil) then
        imgui.PopItemWidth();
    end

    color[4] = ClampChannel((tonumber(ref[1]) or 100) / 100);
    return color;
end

local function DrawColor(label, color)
    color = color or { 1.0, 1.0, 1.0, 1.0 };
    color[4] = ClampChannel(color[4] or 1.0);

    if (imgui.ColorEdit4 ~= nil) then
        imgui.ColorEdit4('##background_' .. label, color, colorEditFlags);
        return color;
    end

    imgui.TextColored(color, label);
    imgui.SameLine();
    color[1] = DrawNumberFallback('R', math.floor(ClampChannel(color[1]) * 255), 0, 255, 5) / 255;
    color[2] = DrawNumberFallback('G', math.floor(ClampChannel(color[2]) * 255), 0, 255, 5) / 255;
    color[3] = DrawNumberFallback('B', math.floor(ClampChannel(color[3]) * 255), 0, 255, 5) / 255;

    return color;
end

local function DrawColorAndSliderRow(rowId, colorLabel, color, sliderLabel, sliderId, sliderValue, minValue, maxValue)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local colorResult = color;
        local sliderResult = sliderValue;

        if (imgui.BeginTable('##background_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##color_label', 0, 104);
            imgui.TableSetupColumn('##color_control', 0, 60);
            imgui.TableSetupColumn('##slider_label', 0, 104);
            imgui.TableSetupColumn('##slider_control', 0, 124);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, colorLabel);
            imgui.TableNextColumn();
            colorResult = DrawColor(rowId .. '_color', colorResult);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, sliderLabel);
            imgui.TableNextColumn();
            sliderResult = DrawSliderControl(sliderId, sliderResult, minValue, maxValue, 58);
            imgui.EndTable();
        end

        return colorResult, sliderResult;
    end

    imgui.TextColored(labelColor, colorLabel);
    imgui.SameLine();
    color = DrawColor(rowId .. '_color', color);
    imgui.SameLine();
    imgui.TextColored(labelColor, sliderLabel);
    imgui.SameLine();
    sliderValue = DrawSliderControl(sliderId, sliderValue, minValue, maxValue, 58);

    return color, sliderValue;
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
        imgui.OpenPopup('Reset background##libraplates_background_reset_confirm');
    end
end

local function DrawResetConfirm(settings, defaults)
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
                Reset(settings, defaults);
            end

            pendingReset = nil;
        end

        return;
    end

    if (imgui.BeginPopupModal('Reset background##libraplates_background_reset_confirm')) then
        imgui.Text('Reset ' .. pendingReset.label .. '?');

        if (pendingReset.kind == 'position') then
            imgui.Text('This will reset Position X and Position Y.');
        else
            imgui.Text('This will reset all Background settings.');
        end

        imgui.Separator();

        if (imgui.Button('Cancel##background_reset_cancel')) then
            pendingReset = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.SameLine();

        if (imgui.Button('Reset##background_reset_confirm')) then
            if (pendingReset.kind == 'position') then
                settings.offsetX = defaults.offsetX;
                settings.offsetY = defaults.offsetY;
            else
                Reset(settings, defaults);
            end

            pendingReset = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.EndPopup();
    end
end

function background.DrawSettings(settings, context)
    if (settings == nil) then
        return;
    end

    local defaults = context ~= nil and context.defaults or {};
    local label = tostring(context ~= nil and context.widget or 'Background');

    ApplyDefaults(settings, defaults);

    if (context == nil or context.hideActive ~= true) then
        settings.enabled = DrawCheckbox('Active', settings.enabled);
    end
    DrawAnchorControls(settings, context, label);

    settings.width, settings.height = DrawSliderPair(
        'size',
        'Width',
        'width',
        settings.width,
        8,
        1000,
        'Height',
        'height',
        settings.height,
        8,
        450
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

    settings.texture = DrawTextureFile('Background image', settings.texture or defaults.texture or 'None');

    settings.color = settings.color or { 0.0, 0.0, 0.0, 0.45 };
    settings.color[4] = ClampChannel(settings.color[4] or 1.0);

    local opacity = math.floor((settings.color[4] * 100) + 0.5);
    settings.color, opacity = DrawColorAndSliderRow('fill_opacity', 'Fill color', settings.color, 'Opacity', 'opacity', opacity, 0, 100);
    settings.color[4] = ClampChannel((tonumber(opacity) or 100) / 100);

    settings.borderColor, settings.borderSize = DrawColorAndSliderRow('border_size', 'Border color', settings.borderColor, 'Border size', 'border_size', settings.borderSize, 0, 40);

    imgui.Separator();

    if (DrawActionButton('Reset ' .. label .. ' position') == true) then
        RequestReset('position', label .. ' position');
    end

    if (DrawActionButton('Reset ' .. label .. ' settings') == true) then
        RequestReset('settings', label .. ' settings');
    end

    DrawResetConfirm(settings, defaults);
end

return background;
