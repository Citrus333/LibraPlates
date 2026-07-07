local imgui = require('imgui');
local uiTooltip = require('core.ui_tooltip');

local anchorControls = {};
local labelColor = { 0.92, 0.92, 0.90, 1.0 };
local valueColor = { 0.65, 0.90, 1.0, 1.0 };
local warningColor = { 1.0, 0.84, 0.0, 1.0 };
local tableFlags = (_G.ImGuiTableFlags_SizingFixedFit or 0) + (_G.ImGuiTableFlags_BordersInnerH or 0);
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

local function DrawCombo(id, current, choices, width, compactLabels)
    local value = ToDisplayValue(current);
    local function DisplayChoice(choice)
        local text = tostring(choice or '');
        if (compactLabels == true) then
            text = text:gsub('%s+icon$', '');
        end
        return text;
    end

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(width or 140);
        end

        if (imgui.BeginCombo('##anchor_' .. tostring(id), DisplayChoice(value)) == true) then
            for _, choice in ipairs(choices or {}) do
                local choiceValue = tostring(choice);
                local selected = value == choiceValue;

                if (imgui.Selectable(DisplayChoice(choiceValue), selected) == true) then
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

local function GetAvailableWidth(fallback)
    if (imgui.GetContentRegionAvail == nil) then
        return tonumber(fallback) or 260;
    end

    local availA, availB = imgui.GetContentRegionAvail();
    if (type(availA) == 'table') then
        return tonumber(availA.x or availA[1]) or tonumber(fallback) or 260;
    end

    return tonumber(availA) or tonumber(availB) or tonumber(fallback) or 260;
end

local function Release(settings)
    settings.anchorTo = 'Plate';
    settings.anchorPoint = nil;
    settings.offsetX = 0;
    settings.offsetY = 0;
    settings.anchorCollapse = nil;
    settings.anchorSpacing = nil;
end

local function GetAnchorTooltip(settings)
    return 'Bind this element to a specific spot on the nameplate so they move together.';
end

local function DrawCheckbox(label, value)
    local nextValue = value == true;
    local changed = false;

    if (imgui.Checkbox ~= nil) then
        local ref = { nextValue };

        if (imgui.Checkbox(label, ref) == true) then
            nextValue = ref[1] == true;
            changed = true;
        end
    else
        imgui.Text(tostring(label) .. ': ' .. tostring(nextValue));
    end

    return nextValue, changed;
end

local function DrawSpacingControl(key, settings)
    local value = math.max(0, math.min(64, tonumber(settings.anchorSpacing) or 6));
    local beganTable = false;

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        beganTable = imgui.BeginTable('##anchor_spacing_row_' .. tostring(key), 2, tableFlags) == true;
        if (beganTable == true) then
            imgui.TableSetupColumn('##label', 0, 145);
            imgui.TableSetupColumn('##control', 0, 170);
            imgui.TableNextRow();
            imgui.TableNextColumn();
        end
    end

    if (imgui.AlignTextToFramePadding ~= nil) then imgui.AlignTextToFramePadding(); end
    imgui.TextColored(labelColor, 'Spacing');

    if (beganTable == true and imgui.TableNextColumn ~= nil) then
        imgui.TableNextColumn();
    else
        imgui.SameLine();
    end

    if (imgui.Button ~= nil and imgui.Button('-##anchor_spacing_minus_' .. key) == true) then
        value = math.max(0, value - 1);
        settings.anchorSpacing = value;
    end
    imgui.SameLine();

    if (imgui.PushItemWidth ~= nil) then
        imgui.PushItemWidth(42);
    end

    if (imgui.InputInt ~= nil) then
        local ref = { value };
        if (imgui.InputInt('##anchor_spacing_' .. key, ref, 0, 0) == true) then
            value = math.max(0, math.min(64, tonumber(ref[1]) or value));
            settings.anchorSpacing = value;
        end
    else
        imgui.TextColored(valueColor, tostring(value));
    end

    if (imgui.PopItemWidth ~= nil) then
        imgui.PopItemWidth();
    end

    imgui.SameLine();
    if (imgui.Button ~= nil and imgui.Button('+##anchor_spacing_plus_' .. key) == true) then
        value = math.min(64, value + 1);
        settings.anchorSpacing = value;
    end

    if (beganTable == true and imgui.EndTable ~= nil) then
        imgui.EndTable();
    end
end

function anchorControls.IsCollapsedChild(settings)
    return settings ~= nil and tostring(settings.anchorTo or 'Plate') ~= 'Plate' and settings.anchorCollapse == true;
end

function anchorControls.DrawSpacing(settings, key)
    DrawSpacingControl(tostring(key or 'spacing'), settings);
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

    if (context.suppressHeaderSeparators ~= true) then
        imgui.Separator();
    end

    if (
        context.suppressHeaderSeparators ~= true and
        imgui.GetWindowDrawList ~= nil and
        imgui.GetCursorScreenPos ~= nil and
        imgui.GetContentRegionAvail ~= nil and
        imgui.GetColorU32 ~= nil
    ) then
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

    if (imgui.AlignTextToFramePadding ~= nil) then imgui.AlignTextToFramePadding(); end
    local rowX = nil;
    local rowY = nil;
    if (context.suppressHeaderSeparators == true and GetCursorScreenPos ~= nil) then
        local posA, posB = GetCursorScreenPos();
        if (type(posA) == 'table') then
            rowX = tonumber(posA.x or posA[1]);
            rowY = tonumber(posA.y or posA[2]);
        else
            rowX = tonumber(posA);
            rowY = tonumber(posB);
        end
    end

    imgui.TextColored(labelColor, 'Copy settings');
    if (rowX ~= nil and rowY ~= nil and imgui.SetCursorScreenPos ~= nil) then
        imgui.SetCursorScreenPos({ rowX + (tonumber(context.headerControlOffset) or 140), rowY });
    else
        imgui.SameLine();
    end

    local sourceLabel = tostring(selectedSource.label or 'Unknown');
    local copyComboWidth = 180;
    if (context.suppressHeaderSeparators == true) then
        copyComboWidth = math.max(104, math.min(180, GetAvailableWidth(240) - 84));
    end

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(copyComboWidth);
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
    uiTooltip.Info('Copy settings from the selected source.');

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
    local headerRowX = nil;

    if (context.suppressHeaderSeparators == true and GetCursorScreenPos ~= nil) then
        local posA = GetCursorScreenPos();
        if (type(posA) == 'table') then
            headerRowX = tonumber(posA.x or posA[1]);
        else
            headerRowX = tonumber(posA);
        end
    end

    DrawCopySettings(settings, context, label);

    if (_G.LibraPlatesSettingsDrawContextLoadMode ~= nil) then
        _G.LibraPlatesSettingsDrawContextLoadMode(settings, context);
    end
    if (context.suppressHeaderSeparators ~= true) then
        imgui.Separator();
    end

    if (headerRowX ~= nil and imgui.SetCursorScreenPos ~= nil and GetCursorScreenPos ~= nil) then
        local posA, posB = GetCursorScreenPos();
        local y = nil;
        if (type(posA) == 'table') then
            y = tonumber(posA.y or posA[2]);
        else
            y = tonumber(posB);
        end
        imgui.SetCursorScreenPos({ headerRowX, y or 0 });
    end

    if (imgui.AlignTextToFramePadding ~= nil) then imgui.AlignTextToFramePadding(); end
    local anchorRowX = nil;
    local anchorRowY = nil;
    if (context.suppressHeaderSeparators == true and GetCursorScreenPos ~= nil) then
        local posA, posB = GetCursorScreenPos();
        if (type(posA) == 'table') then
            anchorRowX = tonumber(posA.x or posA[1]);
            anchorRowY = tonumber(posA.y or posA[2]);
        else
            anchorRowX = tonumber(posA);
            anchorRowY = tonumber(posB);
        end
    end

    imgui.TextColored(labelColor, 'Anchor to');
    if (anchorRowX ~= nil and anchorRowY ~= nil and imgui.SetCursorScreenPos ~= nil) then
        imgui.SetCursorScreenPos({ anchorRowX + (tonumber(context.headerControlOffset) or 140), anchorRowY });
    else
        imgui.SameLine();
    end

    local hasAnchorPoint = tostring(settings.anchorTo or 'Plate') ~= 'Plate';
    local anchorComboWidth = 180;
    local pointComboWidth = 155;

    if (context.suppressHeaderSeparators == true) then
        local remainingWidth = GetAvailableWidth(320);
        local maxHeaderWidth = tonumber(context.headerMaxControlWidth);
        if (maxHeaderWidth ~= nil) then
            remainingWidth = math.min(remainingWidth, maxHeaderWidth);
        end

        if (hasAnchorPoint == true) then
            local reservedWidth = 168;
            pointComboWidth = math.max(58, math.min(155, math.floor((remainingWidth - reservedWidth) * 0.34)));
            anchorComboWidth = math.max(70, math.min(180, remainingWidth - pointComboWidth - reservedWidth));
        else
            anchorComboWidth = math.max(80, math.min(180, remainingWidth - 30));
        end
    end

    local compactAnchorLabels = context.suppressHeaderSeparators == true;
    local anchorTo = DrawCombo(key .. '_to', settings.anchorTo or 'Plate', choices, anchorComboWidth, compactAnchorLabels);

    if (anchorTo ~= settings.anchorTo) then
        settings.anchorTo = anchorTo;

        if (anchorTo == 'Plate') then
            settings.anchorPoint = nil;
            settings.anchorCollapse = nil;
            settings.anchorSpacing = nil;
        elseif (settings.anchorPoint == nil) then
            settings.anchorPoint = 'Center';
        end
    end

    if (tostring(settings.anchorTo or 'Plate') ~= 'Plate') then
        imgui.SameLine();
        settings.anchorPoint = DrawCombo(key .. '_point', settings.anchorPoint or 'Center', points, pointComboWidth, false);
        imgui.SameLine();

        if (imgui.Button ~= nil) then
            if (imgui.Button('Release##' .. key)) then
                pendingRelease[key] = true;
            end
        else
            imgui.TextColored(warningColor, 'Release');
        end

        if (imgui.SetCursorScreenPos ~= nil and anchorRowX ~= nil and anchorRowY ~= nil) then
            imgui.SetCursorScreenPos({ anchorRowX, anchorRowY + 30 });
        end
        local collapse, collapseChanged = DrawCheckbox('Collapse##' .. key, settings.anchorCollapse ~= false);
        if (collapseChanged == true) then
            settings.anchorCollapse = collapse == true;
        elseif (settings.anchorCollapse == nil) then
            settings.anchorCollapse = true;
        end
        imgui.SameLine();
        uiTooltip.Info(GetAnchorTooltip(settings));

        DrawReleaseConfirm(settings, key);

        if (context.suppressHeaderSeparators == true and imgui.SetCursorScreenPos ~= nil and anchorRowX ~= nil and anchorRowY ~= nil) then
            imgui.SetCursorScreenPos({ anchorRowX, anchorRowY + 58 });
        end
    else
        imgui.SameLine();
        uiTooltip.Info(GetAnchorTooltip(settings));
    end
    if (context.suppressHeaderSeparators ~= true) then
        imgui.Separator();
    end
end

return anchorControls;
