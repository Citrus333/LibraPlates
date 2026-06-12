local imgui = require('imgui');
local uiTooltip = require('core.ui_tooltip');

local anchorControls = {};
local labelColor = { 0.92, 0.92, 0.90, 1.0 };
local valueColor = { 0.65, 0.90, 1.0, 1.0 };
local warningColor = { 1.0, 0.84, 0.0, 1.0 };
local pendingRelease = {};
local pendingCopy = {};
local selectedCopySourceKey = {};

local anchorPoints = {
    'Top Left', 'Top', 'Top Right',
    'Left', 'Center', 'Right',
    'Bottom Left', 'Bottom', 'Bottom Right',
};

local function ToDisplayValue(value)
    value = tostring(value or 'Plate');

    if (value == 'Plate') then
        return 'None';
    end

    return value;
end

local function ToStoredValue(value)
    if (tostring(value or '') == 'None') then
        return 'Plate';
    end

    return tostring(value or 'Plate');
end

local function DrawCombo(id, current, choices, width)
    local value = ToDisplayValue(current);

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(width or 140);
        end

        if (imgui.BeginCombo('##anchor_' .. tostring(id), value) == true) then
            for _, choice in ipairs(choices or {}) do
                local choiceValue = tostring(choice);
                local selected = value == choiceValue;

                if (imgui.Selectable(choiceValue, selected) == true) then
                    value = choiceValue;
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

    return ToStoredValue(value);
end

local function Release(settings)
    settings.anchorTo = 'Plate';
    settings.anchorPoint = nil;
    settings.offsetX = 0;
    settings.offsetY = 0;
end

local function GetAnchorTooltip(settings)
    if (tostring(settings.anchorTo or 'Plate') == 'Plate') then
        return table.concat({
            'Anchor',
            'Choose a target widget to attach this one to.',
        }, '\n');
    end

    return table.concat({
        'Anchor',
        'Anchored to ' .. tostring(settings.anchorTo) .. ' at ' .. tostring(settings.anchorPoint or 'Center') .. '.',
        '',
        'Direction',
        'Left: attach to the target\'s left edge.',
        'Right: attach to the target\'s right edge.',
        'Top / Bottom: attach to that side of the target.',
        '',
        'Result',
        'This widget appears on the outside of that side.',
        '',
        'Missing parent',
        'If the parent widget is missing, anchored children use that parent\'s position slot so rows can collapse cleanly.',
    }, '\n');
end

local function DrawReleaseConfirm(settings, key)
    local popupName = 'Release anchor##libraplates_anchor_release_' .. key;

    if (pendingRelease[key] == true and imgui.OpenPopup ~= nil) then
        imgui.OpenPopup(popupName);
        pendingRelease[key] = nil;
    end

    if (imgui.BeginPopupModal ~= nil and imgui.BeginPopupModal(popupName) == true) then
        imgui.Text('Release anchor?');
        imgui.Text('This will clear the anchor and reset Position X/Y.');
        imgui.Separator();

        if (imgui.Button ~= nil and imgui.Button('Cancel##anchor_release_cancel')) then
            imgui.CloseCurrentPopup();
        end

        imgui.SameLine();

        if (imgui.Button ~= nil and imgui.Button('Release##anchor_release_confirm')) then
            Release(settings);
            imgui.CloseCurrentPopup();
        end

        imgui.EndPopup();
    elseif (pendingRelease[key] == true) then
        pendingRelease[key] = nil;
        Release(settings);
    end
end

local function GetCopyContextKey(context, label)
    local entity = tostring(context ~= nil and context.entity or '');
    local state = tostring(context ~= nil and context.state or '');
    local widget = tostring(context ~= nil and context.widget or label or 'settings');

    return (entity .. '_' .. state .. '_' .. widget):gsub('[^%w_]+', '_');
end

local function DrawCopySettings(settings, context, label)
    if (settings == nil or context == nil or context.defaults == nil) then
        return;
    end

    local copySources = context.copySources;
    local copySettings = context.copySettings;
    local defaults = context.defaults;
    local labelText = tostring(label or 'Settings');
    local key = GetCopyContextKey(context, labelText);

    if (copySources == nil and _G.LibraPlatesSettingsBuildWidgetCopySources ~= nil) then
        copySources = _G.LibraPlatesSettingsBuildWidgetCopySources(context.entity, context.state, context.widget);
    end

    if (
        copySources == nil or
        type(copySources) ~= 'table' or
        #copySources == 0 or
        (copySettings == nil and _G.LibraPlatesSettingsCopySettingsFromSource == nil)
    ) then
        return;
    end

    if (copySettings == nil) then
        copySettings = _G.LibraPlatesSettingsCopySettingsFromSource;
    end

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

    if (imgui.GetWindowDrawList ~= nil and imgui.GetCursorScreenPos ~= nil and imgui.GetContentRegionAvail ~= nil and imgui.GetColorU32 ~= nil) then
        local posA, posB = imgui.GetCursorScreenPos();
        local availA = imgui.GetContentRegionAvail();
        local x = 0;
        local y = 0;
        local width = 520;

        if (type(posA) == 'table') then
            x = tonumber(posA.x or posA[1]) or 0;
            y = tonumber(posA.y or posA[2]) or 0;
        else
            x = tonumber(posA) or 0;
            y = tonumber(posB) or 0;
        end

        if (type(availA) == 'table') then
            width = tonumber(availA.x or availA[1]) or width;
        else
            width = tonumber(availA) or width;
        end

        imgui.GetWindowDrawList():AddRectFilled(
            { x, y - 2 },
            { x + math.max(1, width), y + 24 },
            imgui.GetColorU32({ 0.25, 0.29, 0.36, 1.0 }),
            0
        );
    end

    imgui.TextColored(labelColor, 'Copy ' .. labelText .. ' settings from');
    imgui.SameLine();

    local sourceLabel = tostring(selectedSource.label or 'Unknown');
    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(200);
        end

        if (imgui.BeginCombo('##copy_' .. key, sourceLabel) == true) then
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
        imgui.TextColored(valueColor, sourceLabel);
    end

    imgui.SameLine();

    if (imgui.Button ~= nil) then
        if (imgui.Button('Copy##copy_from_' .. key)) then
            pendingCopy[key] = selectedSource;
            if (imgui.OpenPopup ~= nil) then
                imgui.OpenPopup('Copy settings confirm##libraplates_copy_' .. key);
            end
        end
    else
        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            pendingCopy[key] = selectedSource;
            if (imgui.OpenPopup ~= nil) then
                imgui.OpenPopup('Copy settings confirm##libraplates_copy_' .. key);
            end
        end
    end

    imgui.SameLine();
    uiTooltip.Info('Copies the selected source settings into this ' .. labelText .. ' widget. You will get a confirmation before anything is replaced.');

    if (pendingCopy[key] == nil) then
        return;
    end

    local copyLabel = tostring((pendingCopy[key].label) or sourceLabel);
    local popupName = 'Copy settings confirm##libraplates_copy_' .. key;

    if (imgui.BeginPopupModal ~= nil) then
        if (imgui.BeginPopupModal(popupName) == true) then
            imgui.Text('Copy ' .. labelText .. ' settings?');
            imgui.Text('Source: ' .. copyLabel);
            imgui.Text('This will replace the current ' .. labelText .. ' settings.');
            imgui.Separator();

            if (imgui.Button('Cancel##copy_cancel_' .. key)) then
                pendingCopy[key] = nil;
                imgui.CloseCurrentPopup();
            end

            imgui.SameLine();

            if (imgui.Button('Copy##copy_confirm_' .. key)) then
                if (copySettings ~= nil) then
                    copySettings(settings, pendingCopy[key], defaults);
                end

                pendingCopy[key] = nil;
                imgui.CloseCurrentPopup();
            end

            imgui.EndPopup();
        end
    else
        if (imgui.Button ~= nil and imgui.Button('Copy##copy_confirm_fallback_' .. key)) then
            if (copySettings ~= nil) then
                copySettings(settings, pendingCopy[key], defaults);
            end
            pendingCopy[key] = nil;
        end
        if (imgui.Button ~= nil and imgui.Button('Cancel##copy_cancel_fallback_' .. key)) then
            pendingCopy[key] = nil;
        end
    end
end

function anchorControls.Draw(settings, context, label)
    if (settings == nil or context == nil or context.anchorChoices == nil) then
        return;
    end

    local key = tostring(context.widget or label or 'anchor'):gsub('[^%w_]+', '_');
    local choices = context.anchorChoices or { 'None' };
    local points = context.anchorPoints or anchorPoints;

    DrawCopySettings(settings, context, label);

    if (_G.LibraPlatesSettingsDrawContextLoadMode ~= nil) then
        _G.LibraPlatesSettingsDrawContextLoadMode(settings, context);
    end
    imgui.Separator();

    imgui.TextColored(labelColor, 'Anchor to');
    imgui.SameLine();

    local anchorTo = DrawCombo(key .. '_to', settings.anchorTo or 'Plate', choices, 230);
    imgui.SameLine();
    uiTooltip.Info(GetAnchorTooltip(settings));

    if (anchorTo ~= settings.anchorTo) then
        settings.anchorTo = anchorTo;

        if (anchorTo == 'Plate') then
            settings.anchorPoint = nil;
        elseif (settings.anchorPoint == nil) then
            settings.anchorPoint = 'Center';
        end
    end

    if (tostring(settings.anchorTo or 'Plate') ~= 'Plate') then
        imgui.SameLine();
        settings.anchorPoint = DrawCombo(key .. '_point', settings.anchorPoint or 'Center', points, 155);
        imgui.SameLine();

        if (imgui.Button ~= nil) then
            if (imgui.Button('Release anchor##' .. key)) then
                pendingRelease[key] = true;
            end
        else
            imgui.TextColored(warningColor, 'Release anchor');
        end

        DrawReleaseConfirm(settings, key);
    end
    imgui.Separator();
end

return anchorControls;
