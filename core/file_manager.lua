local imgui = require('imgui');
local textureLoader = require('core.texture_loader');

local fileManager = {};
local iconTextureId = nil;

local function GetAddonPath()
    local ok, path = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and path ~= nil) then
        return tostring(path);
    end

    return '.\\';
end

local function GetIconTextureId()
    if (iconTextureId == nil) then
        iconTextureId = textureLoader.ToTextureId(textureLoader.Load(
            GetAddonPath() .. 'assets\\images\\ui-icons\\file-manager.png'
        ));
    end

    return iconTextureId;
end

function fileManager.OpenFolder(folderPath)
    folderPath = tostring(folderPath or '');
    if (folderPath == '') then return; end
    os.execute('start "" "' .. folderPath:gsub('"', '') .. '"');
end

function fileManager.Draw(folderPath, id, sameLine)
    folderPath = tostring(folderPath or '');
    if (folderPath == '') then return false; end

    if (sameLine ~= false and imgui.SameLine ~= nil) then
        imgui.SameLine();
    end

    local clicked = false;
    local textureId = GetIconTextureId();

    if (textureId ~= nil and imgui.Image ~= nil) then
        imgui.Image(textureId, { 24, 24 }, { 0, 0 }, { 1, 1 });
        clicked = imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true;
    elseif (imgui.Button ~= nil) then
        clicked = imgui.Button('Open folder##' .. tostring(id or folderPath)) == true;
    end

    if (imgui.IsItemHovered ~= nil and imgui.IsItemHovered() == true and imgui.SetTooltip ~= nil) then
        imgui.SetTooltip('Open this file folder');
    end

    if (clicked == true) then
        fileManager.OpenFolder(folderPath);
    end

    return clicked;
end

return fileManager;
