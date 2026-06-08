local state = {
    worldEnabled = false,
    worldRuntimeDisabled = false,
    configOpen = false,
    profile = nil,
    lastSave = 0,
    activeProfileName = nil,
    activeProfilePath = nil,
};

local settingsFileName = 'settings.lua';
local legacyProfileFileName = 'rebuild_profile.lua';
local globalProfileName = 'global';

-- ============================================================
-- Lifecycle
-- ============================================================

local function GetConfigFolder()
    return AshitaCore:GetInstallPath() .. '\\config\\addons\\LibraPlates';
end

local function SanitizeProfilePart(value)
    value = tostring(value or '');
    value = value:gsub('[\\/:*?"<>|]', '_');
    value = value:gsub('%s+', '_');
    value = value:gsub('[^%w_%-]', '_');

    if (value == '') then
        return nil;
    end

    return value;
end

local function GetCharacterProfileName()
    local name = nil;
    local serverId = nil;

    pcall(function()
        local memory = AshitaCore:GetMemoryManager();
        local party = memory ~= nil and memory:GetParty() or nil;

        if (party ~= nil) then
            name = party:GetMemberName(0);
            serverId = party:GetMemberServerId(0);
        end
    end);

    name = SanitizeProfilePart(name);
    serverId = tonumber(serverId) or 0;

    if (name == nil or serverId <= 0) then
        return nil;
    end

    return name .. '_' .. tostring(serverId);
end

local function GetProfileFolder(profileName)
    return GetConfigFolder() .. '\\' .. (SanitizeProfilePart(profileName) or globalProfileName);
end

local function GetSettingsPath(profileName)
    return GetProfileFolder(profileName) .. '\\' .. settingsFileName;
end

local function GetLegacyProfilePath()
    return GetConfigFolder() .. '\\' .. legacyProfileFileName;
end

local function SetActiveProfileName(profileName)
    profileName = SanitizeProfilePart(profileName) or globalProfileName;
    state.activeProfileName = profileName;
    state.activeProfilePath = GetSettingsPath(profileName);

    return profileName;
end

local function EnsureFolder(folder)
    local exists = false;

    pcall(function()
        exists = ashita.fs.exists(folder);
    end);

    if (exists == true) then
        return true;
    end

    local ok = pcall(function()
        if (ashita.fs.create_dir ~= nil) then
            ashita.fs.create_dir(folder);
        elseif (ashita.fs.create_directory ~= nil) then
            ashita.fs.create_directory(folder);
        end
    end);

    return ok == true;
end

local function EnsureProfileFolder(profileName)
    EnsureFolder(GetConfigFolder());

    return EnsureFolder(GetProfileFolder(profileName));
end

local function LoadLuaTableFile(path)
    if (path == nil or path == '') then
        return nil;
    end

    local file = io.open(path, 'r');

    if (file == nil) then
        return nil;
    end

    file:close();

    local ok, loaded = pcall(function()
        return dofile(path);
    end);

    if (ok == true and type(loaded) == 'table') then
        return loaded;
    end

    return nil;
end

local function SerializeValue(value, indent)
    indent = indent or 0;

    if (type(value) == 'number' or type(value) == 'boolean') then
        return tostring(value);
    end

    if (type(value) == 'string') then
        return string.format('%q', value);
    end

    if (type(value) ~= 'table') then
        return 'nil';
    end

    local spaces = string.rep(' ', indent);
    local childSpaces = string.rep(' ', indent + 4);
    local lines = { '{' };

    for key, child in pairs(value) do
        local keyText = nil;

        if (type(key) == 'string' and key:match('^[%a_][%w_]*$') ~= nil) then
            keyText = key;
        else
            keyText = '[' .. SerializeValue(key, 0) .. ']';
        end

        table.insert(lines, childSpaces .. keyText .. ' = ' .. SerializeValue(child, indent + 4) .. ',');
    end

    table.insert(lines, spaces .. '}');

    return table.concat(lines, '\n');
end

local function CopyTable(value)
    if (type(value) ~= 'table') then
        return value;
    end

    local copy = {};

    for key, child in pairs(value) do
        copy[key] = CopyTable(child);
    end

    return copy;
end

local defaultBarBackgroundColor = { 0.255, 0.255, 0.255, 0.95 };

local function ColorsMatch(left, right)
    if (type(left) ~= 'table' or type(right) ~= 'table') then
        return false;
    end

    for index = 1, 4 do
        if (math.abs((tonumber(left[index]) or 0) - (tonumber(right[index]) or 0)) > 0.001) then
            return false;
        end
    end

    return true;
end

local function NormalizeBarBackground(widgetKey, node)
    if (
        type(node) ~= 'table' or
        (
            widgetKey ~= 'HP Bar' and
            widgetKey ~= 'MP Bar' and
            widgetKey ~= 'TP Bar' and
            widgetKey ~= 'Cast bar'
        )
    ) then
        return;
    end

    if (ColorsMatch(node.backgroundColor, node.color) == true) then
        node.backgroundColor = CopyTable(defaultBarBackgroundColor);
    end
end

local function NormalizePcTacticalWidget(entity, stateName, widgetKey, node)
    if (
        tostring(entity or '') ~= 'PC' or
        tostring(stateName or '') ~= 'Combat' or
        type(node) ~= 'table'
    ) then
        return;
    end

    if (tostring(widgetKey or '') == 'Job') then
        if ((tonumber(node.offsetX) or 0) == 0 and (tonumber(node.offsetY) or -54) == -54) then
            node.offsetX = -108;
            node.offsetY = -17;
        end

        if (node.iconTheme == nil or tostring(node.iconTheme) == '') then
            node.iconTheme = 'FFXIV';
        end
    elseif (tostring(widgetKey or '') == 'Level') then
        if ((tonumber(node.offsetX) or -88) == -88 and (tonumber(node.offsetY) or -54) == -54) then
            node.offsetX = -110;
            node.offsetY = 4;
        end
    end
end

local function GetExistingWidgetNode(profile, entity, stateName, widgetKey)
    if (
        type(profile) ~= 'table' or
        type(profile.plates) ~= 'table' or
        type(profile.plates[entity]) ~= 'table' or
        type(profile.plates[entity][stateName]) ~= 'table' or
        type(profile.plates[entity][stateName][widgetKey]) ~= 'table'
    ) then
        return nil;
    end

    return profile.plates[entity][stateName][widgetKey];
end

local function SeedSelfStatusIconsFromPc(profile, stateName, widgetKey, node, wasEmpty)
    if (
        wasEmpty ~= true or
        tostring(widgetKey or '') ~= 'Buffs' and tostring(widgetKey or '') ~= 'Debuffs' or
        type(node) ~= 'table'
    ) then
        return;
    end

    local source = GetExistingWidgetNode(profile, 'PC', tostring(stateName or 'Idle'), widgetKey)
        or GetExistingWidgetNode(profile, 'PC', 'Combat', widgetKey);

    if (type(source) ~= 'table' or next(source) == nil) then
        return;
    end

    for key, value in pairs(source) do
        node[key] = CopyTable(value);
    end
end

function state.Load()
    state.worldEnabled = true;
    state.worldRuntimeDisabled = false;
    state.configOpen = false;
    state.profile = nil;
    state.lastSave = 0;
    state.activeProfileName = nil;
    state.activeProfilePath = nil;

    local profileName = GetCharacterProfileName() or globalProfileName;
    SetActiveProfileName(profileName);

    local candidates = {
        state.activeProfilePath,
    };

    if (profileName ~= globalProfileName) then
        table.insert(candidates, GetSettingsPath(globalProfileName));
    end

    table.insert(candidates, GetLegacyProfilePath());

    local loadedPath = nil;

    for _, path in ipairs(candidates) do
        local loaded = LoadLuaTableFile(path);

        if (type(loaded) == 'table') then
            state.profile = loaded;
            loadedPath = path;
            break;
        end
    end

    local profile = state.profile;

    if (type(profile) == 'table' and type(profile.global) == 'table' and profile.global.worldEnabled ~= nil) then
        state.worldEnabled = profile.global.worldEnabled == true;
    end

    if (loadedPath ~= nil and loadedPath ~= state.activeProfilePath) then
        state.Save();
    end
end

function state.Save()
    local profile = state.profile;

    if (type(profile) ~= 'table') then
        return false;
    end

    local profileName = GetCharacterProfileName() or state.activeProfileName or globalProfileName;
    SetActiveProfileName(profileName);

    if (EnsureProfileFolder(profileName) ~= true) then
        return false;
    end

    local file = io.open(state.activeProfilePath, 'w');

    if (file == nil) then
        return false;
    end

    file:write('return ');
    file:write(SerializeValue(profile, 0));
    file:write('\n');
    file:close();
    state.lastSave = os.clock();

    return true;
end

function state.SaveThrottled(interval)
    interval = tonumber(interval) or 1.0;

    if ((os.clock() - (state.lastSave or 0)) < interval) then
        return;
    end

    state.Save();
end

-- ============================================================
-- World plate toggle
-- ============================================================

function state.SetWorldEnabled(enabled)
    state.worldEnabled = (enabled == true);
    state.worldRuntimeDisabled = false;

    local profile = state.GetProfile();
    profile.global.worldEnabled = state.worldEnabled == true;
    state.Save();
end

function state.GetWorldEnabled()
    return state.worldEnabled == true and state.worldRuntimeDisabled ~= true;
end

function state.SetWorldRuntimeDisabled(disabled)
    state.worldRuntimeDisabled = disabled == true;
end

function state.GetWorldRuntimeDisabled()
    return state.worldRuntimeDisabled == true;
end

-- ============================================================
-- Config window toggle
-- ============================================================

function state.SetConfigOpen(open)
    state.configOpen = (open == true);
end

function state.GetConfigOpen()
    return state.configOpen == true;
end

-- ============================================================
-- Profile settings
-- ============================================================

local function EnsurePath(root, keys)
    local node = root;

    for _, key in ipairs(keys) do
        if (node[key] == nil) then
            node[key] = {};
        end

        node = node[key];
    end

    return node;
end

function state.GetProfile()
    if (state.profile == nil) then
        state.profile = {
            global = {},
            plates = {},
        };
    end

    if (type(state.profile.global) ~= 'table') then
        state.profile.global = {};
    end

    if (type(state.profile.plates) ~= 'table') then
        state.profile.plates = {};
    end

    return state.profile;
end

function state.GetGlobalSettings(defaults)
    local profile = state.GetProfile();

    if (defaults ~= nil) then
        for key, value in pairs(defaults) do
            if (profile.global[key] == nil) then
                profile.global[key] = CopyTable(value);
            end
        end
    end

    return profile.global;
end

function state.GetWidgetSettings(entity, stateName, widgetKey, defaults)
    local profile = state.GetProfile();
    local node = EnsurePath(profile.plates, {
        tostring(entity or 'Self'),
        tostring(stateName or 'Idle'),
        tostring(widgetKey or 'Name'),
    });
    local wasEmpty = next(node) == nil;

    if (tostring(entity or '') == 'Self') then
        SeedSelfStatusIconsFromPc(profile, stateName, widgetKey, node, wasEmpty);
    end

    if (
        (tostring(widgetKey or '') == 'Target Module' or tostring(widgetKey or '') == 'Subtarget Module') and
        node.backgroundEnabled == nil and
        node.showBackground ~= nil
    ) then
        node.backgroundEnabled = node.showBackground == true;
    end

    if (defaults ~= nil) then
        for key, value in pairs(defaults) do
            if (node[key] == nil) then
                if (
                    (key == 'backgroundColor' or key == 'arrowColor' or key == 'chevronColor') and
                    type(node.color) == 'table'
                ) then
                    node[key] = CopyTable(node.color);
                else
                    node[key] = CopyTable(value);
                end
            end
        end
    end

    NormalizePcTacticalWidget(entity, stateName, widgetKey, node);
    NormalizeBarBackground(tostring(widgetKey or ''), node);

    return node;
end

return state;
