local imgui = require('imgui');
local textScale = require('core.text_scale');
local uiTooltip = require('core.ui_tooltip');

local aoeRange = {};
local defaults = require('config.widgets.aoe_range');
local labelColor = { 0.92, 0.92, 0.90, 1.0 };
local valueColor = { 0.65, 0.90, 1.0, 1.0 };
local headerColor = { 1.0, 0.84, 0.0, 1.0 };
local colorEditFlags = (_G.ImGuiColorEditFlags_NoAlpha or 0) + (_G.ImGuiColorEditFlags_NoInputs or 0);
local fileCache = nil;
local autoPlaceAnchorOptions = T{ 'Widest element', 'Name', 'HP Bar' };

local function GetAddonPath()
    local ok, path = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and path ~= nil) then
        return tostring(path);
    end

    return '.\\';
end

local function AddFile(files, name)
    name = tostring(name or ''):gsub('^.*[\\/]', '');

    if (name == '' or string.lower(name):match('%.png$') == nil) then
        return;
    end

    for _, existing in ipairs(files) do
        if (existing == name) then
            return;
        end
    end

    files[#files + 1] = name;
end

local function GetBackgroundFiles()
    if (fileCache ~= nil) then
        return fileCache;
    end

    local files = T{ 'None' };
    local folder = GetAddonPath() .. 'assets\\images\\target\\backgrounds\\';
    local pipe = io.popen('dir /b "' .. folder .. '*.png" 2>nul');

    if (pipe ~= nil) then
        for line in pipe:lines() do
            AddFile(files, line);
        end

        pipe:close();
    end

    table.sort(files, function(a, b)
        if (a == 'None') then return true; end
        if (b == 'None') then return false; end
        return string.lower(tostring(a)) < string.lower(tostring(b));
    end);

    fileCache = files;
    return files;
end

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

local function DrawOption(label, options, value, id)
    local selected = tostring(value or (options ~= nil and options[1] or ''));

    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (imgui.BeginCombo ~= nil and imgui.BeginCombo('##aoe_range_' .. tostring(id or label), selected) == true) then
        for _, option in ipairs(options or {}) do
            local optionText = tostring(option);
            local isSelected = optionText == selected;

            if (imgui.Selectable(optionText, isSelected) == true) then
                selected = optionText;
            end

            if (isSelected == true and imgui.SetItemDefaultFocus ~= nil) then
                imgui.SetItemDefaultFocus();
            end
        end

        imgui.EndCombo();
    else
        imgui.TextColored(valueColor, selected);
    end

    return selected;
end

local function DrawNumberControl(id, value, minValue, maxValue)
    local current = math.floor((tonumber(value) or 0) + 0.5);

    if (imgui.Button ~= nil and imgui.Button('-##aoe_range_' .. id .. '_minus') == true) then
        current = current - 1;
    end

    imgui.SameLine();

    if (imgui.PushItemWidth ~= nil) then
        imgui.PushItemWidth(95);
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

local function DrawColorControl(id, color)
    local current = color or { 1.0, 1.0, 1.0, 1.0 };

    if (imgui.ColorEdit4 ~= nil) then
        imgui.ColorEdit4('##aoe_range_' .. tostring(id), current, colorEditFlags);
    else
        imgui.TextColored(valueColor, 'color');
    end

    return current;
end

function aoeRange.DrawSettings(settings)
    if (settings == nil) then
        return;
    end

    if (settings.enabled == nil) then settings.enabled = defaults.enabled; end
    if (settings.fontSize == nil) then settings.fontSize = defaults.fontSize; end
    if (settings.fontColor == nil) then settings.fontColor = defaults.fontColor; end
    if (settings.iconEnabled == nil) then settings.iconEnabled = defaults.iconEnabled; end
    if (settings.iconSize == nil) then settings.iconSize = defaults.iconSize; end
    if (settings.highlightEnabled == nil) then settings.highlightEnabled = defaults.highlightEnabled; end
    if (settings.backgroundFile == nil) then settings.backgroundFile = defaults.backgroundFile; end
    if (settings.autoPlaceBackground == nil) then settings.autoPlaceBackground = defaults.autoPlaceBackground; end
    if (settings.backgroundAutoPlaceAnchor == nil) then settings.backgroundAutoPlaceAnchor = defaults.backgroundAutoPlaceAnchor; end
    if (settings.backgroundSpacing == nil) then settings.backgroundSpacing = defaults.backgroundSpacing; end
    if (settings.backgroundWidth == nil) then settings.backgroundWidth = defaults.backgroundWidth; end
    if (settings.backgroundHeight == nil) then settings.backgroundHeight = defaults.backgroundHeight; end
    if (settings.backgroundOffsetX == nil) then settings.backgroundOffsetX = defaults.backgroundOffsetX; end
    if (settings.backgroundOffsetY == nil) then settings.backgroundOffsetY = defaults.backgroundOffsetY; end
    if (settings.backgroundColor == nil) then settings.backgroundColor = defaults.backgroundColor; end

    DrawHeader('AOE range');
    settings.enabled = DrawCheckbox('Use AOE name style', settings.enabled);

    if (settings.enabled ~= true) then
        return;
    end

    imgui.TextColored(labelColor, 'Font size');
    imgui.SameLine();
    settings.fontSize = DrawNumberControl('font_size', settings.fontSize, textScale.GetMinVisualSize(), 40);

    imgui.SameLine();
    imgui.TextColored(labelColor, 'Font color');
    imgui.SameLine();
    settings.fontColor = DrawColorControl('font_color', settings.fontColor);

    DrawHeader('Icon');
    settings.iconEnabled = DrawCheckbox('Show icon', settings.iconEnabled);
    if (settings.iconEnabled == true) then
        imgui.SameLine();
        imgui.TextColored(labelColor, 'Icon size');
        imgui.SameLine();
        settings.iconSize = DrawNumberControl('icon_size', settings.iconSize, 4, 128);
    end

    DrawHeader('Highlight');
    settings.highlightEnabled = DrawCheckbox('Show highlight', settings.highlightEnabled);
    uiTooltip.Info('Uses the same highlight image style as the Target/Subtarget module. The highlight appears only on names currently inside AOE range.');

    if (settings.highlightEnabled == true) then
        settings.backgroundFile = DrawOption('Highlight image', GetBackgroundFiles(), settings.backgroundFile or 'None', 'highlight_image');

        if (tostring(settings.backgroundFile or 'None') ~= 'None') then
            settings.autoPlaceBackground = DrawCheckbox('Auto place highlight', settings.autoPlaceBackground ~= false);

            if (settings.autoPlaceBackground ~= false) then
                settings.backgroundAutoPlaceAnchor = DrawOption('Auto place by', autoPlaceAnchorOptions, settings.backgroundAutoPlaceAnchor or 'Widest element', 'highlight_anchor');
                imgui.TextColored(labelColor, 'Size');
                imgui.SameLine();
                settings.backgroundSpacing = DrawNumberControl('highlight_spacing', settings.backgroundSpacing, 0, 300);
            else
                imgui.TextColored(labelColor, 'Width');
                imgui.SameLine();
                settings.backgroundWidth = DrawNumberControl('highlight_width', settings.backgroundWidth, 1, 1000);
                imgui.SameLine();
                imgui.TextColored(labelColor, 'Height');
                imgui.SameLine();
                settings.backgroundHeight = DrawNumberControl('highlight_height', settings.backgroundHeight, 1, 450);

                imgui.TextColored(labelColor, 'Position X');
                imgui.SameLine();
                settings.backgroundOffsetX = DrawNumberControl('highlight_x', settings.backgroundOffsetX, -500, 500);
                imgui.SameLine();
                imgui.TextColored(labelColor, 'Position Y');
                imgui.SameLine();
                settings.backgroundOffsetY = DrawNumberControl('highlight_y', settings.backgroundOffsetY, -500, 500);
            end

            imgui.TextColored(labelColor, 'Highlight tint');
            imgui.SameLine();
            settings.backgroundColor = DrawColorControl('highlight_tint', settings.backgroundColor);
        end
    end
end

return aoeRange;
