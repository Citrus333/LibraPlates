local imgui = require('imgui');
local textScale = require('core.text_scale');
local state = require('core.state');
local targetTextures = require('core.target_textures');
local aoeRangeVisuals = require('core.aoe_range_visuals');
local fileManager = require('core.file_manager');

local aoeRange = {};
local defaults = require('config.widgets.aoe_range');
local labelColor = { 0.92, 0.92, 0.90, 1.0 };
local valueColor = { 0.65, 0.90, 1.0, 1.0 };
local headerColor = { 1.0, 0.84, 0.0, 1.0 };
local colorEditFlags = (_G.ImGuiColorEditFlags_NoAlpha or 0) + (_G.ImGuiColorEditFlags_NoInputs or 0);

local function DrawHeader(label)
    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.18);
    end

    imgui.TextColored(headerColor, tostring(label or ''));

    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.0);
    end
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
    imgui.TextColored(valueColor, value == true and 'On' or 'Off');
    return value == true;
end

local function DrawNumberControl(id, value, minValue, maxValue)
    local current = math.floor((tonumber(value) or 0) + 0.5);

    if (imgui.Button ~= nil and imgui.Button('-##aoe_range_' .. id .. '_minus') == true) then
        current = current - 1;
    end

    imgui.SameLine();

    if (imgui.PushItemWidth ~= nil) then
        imgui.PushItemWidth(58);
    end

    if (imgui.InputText ~= nil) then
        local ref = { tostring(current) };

        if (imgui.InputText('##aoe_range_' .. id, ref, 16) == true) then
            current = tonumber(ref[1]) or current;
        end
    else
        imgui.TextColored(valueColor, tostring(current));
    end

    if (imgui.PopItemWidth ~= nil) then
        imgui.PopItemWidth();
    end

    imgui.SameLine();

    if (imgui.Button ~= nil and imgui.Button('+##aoe_range_' .. id .. '_plus') == true) then
        current = current + 1;
    end

    if (minValue ~= nil and current < minValue) then current = minValue; end
    if (maxValue ~= nil and current > maxValue) then current = maxValue; end

    return current;
end

local function DrawFourColumnTable(id, draw)
    if (imgui.BeginTable == nil or imgui.TableSetupColumn == nil) then
        draw(false);
        return;
    end

    if (imgui.BeginTable('##aoe_range_table_' .. tostring(id), 4, 0)) then
        imgui.TableSetupColumn('##label_1', 0, 125);
        imgui.TableSetupColumn('##control_1', 0, 125);
        imgui.TableSetupColumn('##label_2', 0, 125);
        imgui.TableSetupColumn('##control_2', 0, 125);
        draw(true);
        imgui.EndTable();
    end
end

local function DrawCellLabel(label)
    imgui.TableNextColumn();
    imgui.TextColored(labelColor, label);
    imgui.TableNextColumn();
end

local function DrawCombo(id, items, selected, width, previewCategory, previewTextureFn, folderPath)
    local current = tostring(selected or items[1] or 'None');

    local function DrawPreviewTooltip(fileName)
        if (
            (previewCategory == nil and previewTextureFn == nil) or
            tostring(fileName or 'None') == 'None' or
            imgui.IsItemHovered == nil or
            imgui.IsItemHovered() ~= true
        ) then
            return;
        end

        local textureId = previewTextureFn ~= nil
            and previewTextureFn(fileName)
            or targetTextures.GetTextureId(previewCategory, fileName);
        if (textureId ~= nil and imgui.BeginTooltip ~= nil and imgui.EndTooltip ~= nil and imgui.Image ~= nil) then
            imgui.BeginTooltip();
            imgui.Text(tostring(fileName));
            imgui.Image(textureId, previewCategory == 'backgrounds' and { 220, 110 } or { 110, 110 }, { 0, 0 }, { 1, 1 });
            imgui.EndTooltip();
        end
    end

    if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(width or 300); end
    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        local comboOpen = imgui.BeginCombo('##aoe_range_' .. tostring(id), current) == true;
        DrawPreviewTooltip(current);
        if (comboOpen == true) then
            for _, item in ipairs(items) do
                local value = tostring(item);
                local isSelected = value == current;
                if (imgui.Selectable(value, isSelected) == true) then current = value; end
                DrawPreviewTooltip(value);
                if (isSelected == true and imgui.SetItemDefaultFocus ~= nil) then imgui.SetItemDefaultFocus(); end
            end
            imgui.EndCombo();
        end
    else
        imgui.TextColored(valueColor, current);
    end
    if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
    if (folderPath ~= nil) then
        fileManager.Draw(folderPath, 'AoeRangeFile_' .. tostring(id));
    end

    return current;
end

local function DrawWideRow(id, label, drawControl)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##aoe_range_wide_' .. tostring(id), 2, 0)) then
            imgui.TableSetupColumn('##label', 0, 125);
            imgui.TableSetupColumn('##control', 0, 360);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, label);
            imgui.TableNextColumn();
            drawControl();
            imgui.EndTable();
        end
    else
        imgui.TextColored(labelColor, label);
        imgui.SameLine();
        drawControl();
    end
end

local function DrawPanel(title, draw)
    if (_G.LibraPlatesSettingsDrawBoxedPanel ~= nil) then
        _G.LibraPlatesSettingsDrawBoxedPanel(title, draw, true);
        return;
    end

    DrawHeader(title);
    draw();
end

local function DrawColorControl(id, color)
    local current = color or { 1.0, 1.0, 1.0, 1.0 };

    if (imgui.ColorEdit4 ~= nil) then
        imgui.ColorEdit4('##aoe_range_' .. tostring(id), current, colorEditFlags);
    else
        imgui.TextColored(valueColor, 'color');
    end

    return current;
end

function aoeRange.DrawSettings(settings, options)
    if (settings == nil) then
        return;
    end

    options = options or {};

    if (settings.enabled == nil) then settings.enabled = defaults.enabled; end
    if (settings.fontSize == nil) then settings.fontSize = defaults.fontSize; end
    if (settings.fontColor == nil) then settings.fontColor = defaults.fontColor; end
    if (settings.iconEnabled == nil) then settings.iconEnabled = defaults.iconEnabled; end
    if (settings.iconFile == nil) then settings.iconFile = defaults.iconFile; end
    if (settings.iconSize == nil) then settings.iconSize = defaults.iconSize; end
    if (settings.iconOffsetX == nil) then settings.iconOffsetX = defaults.iconOffsetX; end
    if (settings.iconOffsetY == nil) then settings.iconOffsetY = defaults.iconOffsetY; end
    if (settings.iconAnchorTo == nil) then settings.iconAnchorTo = defaults.iconAnchorTo; end
    if (settings.iconAnchorPoint == nil) then settings.iconAnchorPoint = defaults.iconAnchorPoint; end

    local before = {
        enabled = settings.enabled,
        fontSize = settings.fontSize,
        fontColor1 = tonumber(settings.fontColor[1]),
        fontColor2 = tonumber(settings.fontColor[2]),
        fontColor3 = tonumber(settings.fontColor[3]),
        fontColor4 = tonumber(settings.fontColor[4]),
        iconEnabled = settings.iconEnabled,
        iconFile = settings.iconFile,
        iconSize = settings.iconSize,
        iconOffsetX = settings.iconOffsetX,
        iconOffsetY = settings.iconOffsetY,
    };

    local function Panel(title, draw)
        if (options.drawPanel ~= nil) then
            options.drawPanel(title, draw);
        else
            DrawPanel(title, draw);
        end
    end

    Panel('AOE range settings', function()
        settings.enabled = DrawCheckbox('Use AOE name style', settings.enabled);

        if (settings.enabled == true) then
            DrawFourColumnTable('name_style', function(usingTable)
                if (usingTable == true) then
                    imgui.TableNextRow();
                    DrawCellLabel('Font size');
                    settings.fontSize = DrawNumberControl('font_size', settings.fontSize, textScale.GetMinVisualSize(), 40);
                    DrawCellLabel('Font color');
                    settings.fontColor = DrawColorControl('font_color', settings.fontColor);
                else
                    imgui.TextColored(labelColor, 'Font size');
                    imgui.SameLine();
                    settings.fontSize = DrawNumberControl('font_size', settings.fontSize, textScale.GetMinVisualSize(), 40);
                    imgui.SameLine();
                    imgui.TextColored(labelColor, 'Font color');
                    imgui.SameLine();
                    settings.fontColor = DrawColorControl('font_color', settings.fontColor);
                end
            end);

        end
    end);

    if (settings.enabled == true) then
        Panel('Icon', function()
            settings.iconEnabled = DrawCheckbox('Show icon', settings.iconEnabled);
            if (settings.iconEnabled == true) then
                DrawWideRow('icon_image', 'Icon image', function()
                    settings.iconFile = DrawCombo(
                        'icon_image',
                        aoeRangeVisuals.GetIconFiles(),
                        settings.iconFile,
                        300,
                        nil,
                        aoeRangeVisuals.GetIconTextureId,
                        aoeRangeVisuals.GetIconFolderPath()
                    );
                end);
                DrawFourColumnTable('icon', function(usingTable)
                    if (usingTable == true) then
                        imgui.TableNextRow();
                        DrawCellLabel('Position X');
                        settings.iconOffsetX = DrawNumberControl('icon_x', settings.iconOffsetX, -500, 500);
                        DrawCellLabel('Position Y');
                        settings.iconOffsetY = DrawNumberControl('icon_y', settings.iconOffsetY, -500, 500);
                        imgui.TableNextRow();
                        DrawCellLabel('Icon size');
                        settings.iconSize = DrawNumberControl('icon_size', settings.iconSize, 4, 256);
                    else
                        imgui.TextColored(labelColor, 'Position X');
                        imgui.SameLine();
                        settings.iconOffsetX = DrawNumberControl('icon_x', settings.iconOffsetX, -500, 500);
                        imgui.SameLine();
                        imgui.TextColored(labelColor, 'Position Y');
                        imgui.SameLine();
                        settings.iconOffsetY = DrawNumberControl('icon_y', settings.iconOffsetY, -500, 500);
                        imgui.TextColored(labelColor, 'Icon size');
                        imgui.SameLine();
                        settings.iconSize = DrawNumberControl('icon_size', settings.iconSize, 4, 256);
                    end
                end);
            end
        end);
    end

    if (
        before.enabled ~= settings.enabled or
        before.fontSize ~= settings.fontSize or
        before.fontColor1 ~= tonumber(settings.fontColor[1]) or
        before.fontColor2 ~= tonumber(settings.fontColor[2]) or
        before.fontColor3 ~= tonumber(settings.fontColor[3]) or
        before.fontColor4 ~= tonumber(settings.fontColor[4]) or
        before.iconEnabled ~= settings.iconEnabled or
        before.iconFile ~= settings.iconFile or
        before.iconSize ~= settings.iconSize or
        before.iconOffsetX ~= settings.iconOffsetX or
        before.iconOffsetY ~= settings.iconOffsetY
    ) then
        state.Save();
    end

end

return aoeRange;
