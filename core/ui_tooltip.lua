local imgui = require('imgui');
local textureLoader = require('core.texture_loader');

local uiTooltip = {};
local iconCache = {};

local function GetAddonPath()
    local ok, path = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and path ~= nil) then
        return tostring(path);
    end

    return '.\\';
end

local function GetIconTextureId(fileName)
    fileName = tostring(fileName or '');

    if (fileName == '') then
        return nil;
    end

    if (iconCache[fileName] ~= nil) then
        return iconCache[fileName];
    end

    iconCache[fileName] = textureLoader.ToTextureId(textureLoader.Load(
        GetAddonPath() .. 'assets\\images\\ui-icons\\' .. fileName
    ));

    return iconCache[fileName];
end

function uiTooltip.Info(text, sameLine)
    local textureId = GetIconTextureId('info.png');

    if (sameLine ~= false) then
        imgui.SameLine();
    end

    if (textureId ~= nil and imgui.Image ~= nil) then
        imgui.Image(textureId, { 24, 24 }, { 0, 0 }, { 1, 1 });
    else
        imgui.TextColored({ 0.65, 0.90, 1.0, 1.0 }, '(?)');
    end

    if (imgui.IsItemHovered == nil or imgui.IsItemHovered() ~= true) then
        return;
    end

    if (imgui.BeginTooltip ~= nil and imgui.EndTooltip ~= nil) then
        imgui.BeginTooltip();

        if (imgui.PushTextWrapPos ~= nil) then
            imgui.PushTextWrapPos(360);
        end

        if (imgui.TextWrapped ~= nil) then
            imgui.TextWrapped(tostring(text or ''));
        else
            imgui.Text(tostring(text or ''));
        end

        if (imgui.PopTextWrapPos ~= nil) then
            imgui.PopTextWrapPos();
        end

        imgui.EndTooltip();
    elseif (imgui.SetTooltip ~= nil) then
        imgui.SetTooltip(tostring(text or ''));
    end
end

return uiTooltip;
