local defaults = require('config.widgets.game_mode_icon');
local imgui = require('imgui');
local anchorControls = require('modules.widgets.anchor_controls');

local gameModeIcon = {};
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
local tableFlags = (_G.ImGuiTableFlags_SizingFixedFit or 0) + (_G.ImGuiTableFlags_BordersInnerH or 0);
local heldButtonState = {};
local pendingReset = nil;

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

local function DrawSliderControl(id, value, minValue, maxValue, step, width)
    local current = math.floor((tonumber(value) or 0) + 0.5);
    local amount = tonumber(step) or 1;

    if (imgui.InputText == nil and imgui.SliderInt == nil) then
        return DrawNumber('', value, minValue, maxValue, amount);
    end

    if (imgui.Button ~= nil and IsHeldButton('-##game_mode_' .. id .. '_minus') == true) then
        current = current - amount;
    end

    imgui.SameLine();

    if (imgui.PushItemWidth ~= nil) then
        imgui.PushItemWidth(width or 95);
    end

    local ref = { current };
    if (imgui.InputText ~= nil) then
        ref = { tostring(current) };
        imgui.InputText('##game_mode_' .. id, ref, 16);
    else
        imgui.SliderInt('##game_mode_' .. id, ref, minValue or -1000, maxValue or 1000);
    end

    if (imgui.PopItemWidth ~= nil) then
        imgui.PopItemWidth();
    end

    current = tonumber(ref[1]) or current;
    imgui.SameLine();

    if (imgui.Button ~= nil and IsHeldButton('+##game_mode_' .. id .. '_plus') == true) then
        current = current + amount;
    end

    if (minValue ~= nil and current < minValue) then current = minValue; end
    if (maxValue ~= nil and current > maxValue) then current = maxValue; end

    return current;
end

local function DrawTableSlider(label, id, value, minValue, maxValue, step)
    imgui.TextColored(labelColor, label);
    imgui.TableNextColumn();
    return DrawSliderControl(id, value, minValue, maxValue, step or 1, 95);
end

local function DrawSliderPair(rowId, leftLabel, leftId, leftValue, leftMin, leftMax, rightLabel, rightId, rightValue, rightMin, rightMax, step)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local leftResult = leftValue;
        local rightResult = rightValue;

        if (imgui.BeginTable('##game_mode_' .. rowId, 4, tableFlags)) then
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

local function DrawAnchorCombo(id, current, choices)
    local value = tostring(current or 'Plate');

    if (value == 'Plate') then
        value = 'None';
    end

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(230);
        end

        if (imgui.BeginCombo('##game_mode_anchor_' .. tostring(id), value) == true) then
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
    anchorControls.Draw(settings, context, 'Game mode icon');
end

local function DrawSingleSliderRow(rowId, label, id, value, minValue, maxValue, step)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local result = value;

        if (imgui.BeginTable('##game_mode_' .. rowId, 2, tableFlags)) then
            imgui.TableSetupColumn('##label', 0, 145);
            imgui.TableSetupColumn('##control', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            result = DrawTableSlider(label, id, value, minValue, maxValue, step or 1);
            imgui.EndTable();
        end

        return result;
    end

    return DrawNumber(label, value, minValue, maxValue, step or 1);
end

local function DrawActionButton(label)
    if (imgui.Button ~= nil) then
        return imgui.Button(tostring(label)) == true;
    end

    return ClickText(tostring(label), actionColor) == true;
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
end

local function Reset(settings)
    local enabled = settings.enabled;

    for key, value in pairs(defaults) do
        if (type(value) == 'table') then
            settings[key] = { unpackTable(value) };
        else
            settings[key] = value;
        end
    end

    settings.enabled = enabled;
end

local function RequestReset(kind, label)
    pendingReset = {
        kind = kind,
        label = label,
    };

    if (imgui.OpenPopup ~= nil) then
        imgui.OpenPopup('Reset game mode icon##libraplates_game_mode_icon_reset_confirm');
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
                Reset(settings);
            end

            pendingReset = nil;
        end

        return;
    end

    if (imgui.BeginPopupModal('Reset game mode icon##libraplates_game_mode_icon_reset_confirm')) then
        imgui.Text('Reset ' .. pendingReset.label .. '?');

        if (pendingReset.kind == 'position') then
            imgui.Text('This will reset Position X and Position Y.');
        else
            imgui.Text('This will reset all Game mode icon settings.');
        end

        imgui.Separator();

        if (imgui.Button('Cancel##game_mode_icon_reset_cancel')) then
            pendingReset = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.SameLine();

        if (imgui.Button('Reset##game_mode_icon_reset_confirm')) then
            if (pendingReset.kind == 'position') then
                settings.offsetX = defaults.offsetX;
                settings.offsetY = defaults.offsetY;
            else
                Reset(settings);
            end

            pendingReset = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.EndPopup();
    end
end

function gameModeIcon.GetDefaults()
    return defaults;
end

function gameModeIcon.Draw(data, settings, context)
    if (
        settings == nil or settings.enabled ~= true or
        data == nil or data.textureId == nil or
        context == nil or context.drawList == nil or context.canvas == nil or context.bounds == nil
    ) then
        return;
    end

    ApplyDefaults(settings);

    local size = tonumber(settings.iconSize) or 16;

    if (size <= 0 or context.drawList.AddImage == nil) then
        return;
    end

    local centerX, centerY = context.canvas.ToScreen(context.bounds, settings.offsetX, settings.offsetY);
    centerX, centerY = context.canvas.ClampPoint(context.bounds, centerX, centerY);

    local left = centerX - (size / 2);
    local top = centerY - (size / 2);

    context.drawList:AddImage(
        tonumber(data.textureId),
        { left, top },
        { left + size, top + size },
        { 0, 0 },
        { 1, 1 },
        0xFFFFFFFF
    );
end

function gameModeIcon.DrawSettings(settings, context)
    if (settings == nil) then
        return;
    end

    ApplyDefaults(settings);

    if ((context == nil or context.onlyPlacement ~= true) and (context == nil or context.boxed ~= true)) then
        DrawSectionHeader('Game mode icon settings');
    end
    if (context == nil or context.hideActive ~= true) then
        settings.enabled = DrawCheckbox('Active', settings.enabled);
    end
    if (context == nil or context.skipPlacement ~= true) then
        DrawAnchorControls(settings, context);
    end

    if (context ~= nil and context.onlyPlacement == true) then
        return;
    end
    local function DrawBody()
        settings.iconSize = DrawSingleSliderRow('icon_size', 'Icon size', 'icon_size', settings.iconSize, 6, 64, 1);
        if (anchorControls.IsCollapsedChild(settings) == true) then
            anchorControls.DrawSpacing(settings, 'game_mode_icon_position', 145, 170);
        else
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
                400,
                5
            );
        end
    end

    if (context ~= nil and context.boxed == true and _G.LibraPlatesSettingsDrawBoxedPanel ~= nil) then
        _G.LibraPlatesSettingsDrawBoxedPanel('Game mode icon', DrawBody, true);
    else
        DrawBody();
    end

    if (context ~= nil and context.boxed == true) then
        imgui.Spacing();
        imgui.Spacing();
    else
        imgui.Separator();
    end

    if (DrawActionButton('Reset Game mode icon position') == true) then
        RequestReset('position', 'Game mode icon position');
    end

    if (DrawActionButton('Reset Game mode icon settings') == true) then
        RequestReset('settings', 'Game mode icon settings');
    end

    DrawResetConfirm(settings);
end

return gameModeIcon;
