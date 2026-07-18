local state = {
    worldEnabled = false,
    worldRuntimeDisabled = false,
    configOpen = false,
    profile = nil,
    profileManifest = nil,
    characterProfileName = nil,
    lastSave = 0,
    activeProfileName = nil,
    activeProfilePath = nil,
    loadedFromDisk = false,
    savedThisSession = false,
    lastBackup = 0,
    lastBackupPrune = 0,
    characterProfileCacheName = nil,
    characterProfileCacheClock = 0,
    revision = 0,
};

local settingsFileName = 'settings.lua';
local legacyProfileFileName = 'rebuild_profile.lua';
local globalProfileName = 'global';
local defaultUserProfileName = 'Default';
local profilesFolderName = 'profiles';
local presetsFolderName = 'presets';
local backupsFolderName = 'backups';
local profileSystemVersion = 1;
local suspiciousShrinkRatio = 0.50;
local suspiciousShrinkMinBytes = 8192;
local normalSaveBackupIntervalSeconds = 600;
local backupPruneIntervalSeconds = 600;
local maxBackupFiles = 1;
local maxBackupBytes = 256 * 1024 * 1024;
local SerializeValue = nil;
local CopyTable = nil;
local ApplyLoadedWorldEnabled = nil;

-- ============================================================
-- Lifecycle
-- ============================================================

local function GetConfigFolder()
    return AshitaCore:GetInstallPath() .. '\\config\\addons\\LibraPlates';
end

local function GetAddonFolder()
    return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates';
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
    local now = os.clock();
    if (state.characterProfileCacheName ~= nil and (now - (tonumber(state.characterProfileCacheClock) or 0)) < 1.0) then
        return state.characterProfileCacheName;
    end

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
        state.characterProfileCacheName = nil;
        state.characterProfileCacheClock = now;
        return nil;
    end

    state.characterProfileCacheName = name .. '_' .. tostring(serverId);
    state.characterProfileCacheClock = now;
    return state.characterProfileCacheName;
end

local function GetProfileFolder(profileName)
    return GetConfigFolder() .. '\\' .. (SanitizeProfilePart(profileName) or globalProfileName);
end

local function GetSettingsPath(profileName)
    return GetProfileFolder(profileName) .. '\\' .. settingsFileName;
end

local function GetProfilesFolder(profileName)
    return GetProfileFolder(profileName) .. '\\' .. profilesFolderName;
end

local function GetPresetsFolder()
    return GetAddonFolder() .. '\\' .. profilesFolderName .. '\\' .. presetsFolderName;
end

local function GetProfileDataPath(characterProfileName, userProfileName)
    return GetProfilesFolder(characterProfileName) .. '\\' .. (SanitizeProfilePart(userProfileName) or defaultUserProfileName) .. '.lua';
end

local function GetProfileRelativePath(userProfileName)
    return profilesFolderName .. '\\' .. (SanitizeProfilePart(userProfileName) or defaultUserProfileName) .. '.lua';
end

local function GetBackupsFolder(profileName)
    return GetProfileFolder(profileName) .. '\\' .. backupsFolderName;
end

local function GetTimestamp()
    local ok, value = pcall(function()
        return os.date('%Y%m%d-%H%M%S');
    end);

    if (ok == true and value ~= nil) then
        return tostring(value);
    end

    return tostring(math.floor(os.clock() * 1000));
end

local function GetProfileBackupPath(characterProfileName, userProfileName)
    return GetBackupsFolder(characterProfileName) .. '\\settings-backup.lua';
end

local function GetManifestBackupPath(characterProfileName)
    return GetBackupsFolder(characterProfileName) .. '\\settings-backup.lua';
end

local function GetLegacyProfilePath()
    return GetConfigFolder() .. '\\' .. legacyProfileFileName;
end

local function SetActiveUserProfileName(profileName)
    profileName = SanitizeProfilePart(profileName) or defaultUserProfileName;
    state.activeProfileName = profileName;
    state.activeProfilePath = GetProfileDataPath(state.characterProfileName, profileName);

    return profileName;
end

local function IsCharacterProfileName(profileName)
    profileName = tostring(profileName or '');

    return profileName ~= '' and profileName ~= globalProfileName;
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

local function EnsureProfileSystemFolders(profileName)
    if (EnsureProfileFolder(profileName) ~= true) then
        return false;
    end

    if (EnsureFolder(GetProfilesFolder(profileName)) ~= true) then
        return false;
    end

    if (EnsureFolder(GetBackupsFolder(profileName)) ~= true) then
        return false;
    end

    return true;
end

local function ReadFileSize(path)
    local file = io.open(path, 'rb');

    if (file == nil) then
        return 0;
    end

    local size = file:seek('end') or 0;
    file:close();

    return tonumber(size) or 0;
end

local function CopyFile(sourcePath, targetPath)
    local source = io.open(sourcePath, 'rb');

    if (source == nil) then
        return false;
    end

    local data = source:read('*a');
    source:close();

    local target = io.open(targetPath, 'wb');

    if (target == nil) then
        return false;
    end

    target:write(data or '');
    target:close();

    return true;
end

local function GetDirectoryEntries(folder)
    local ok, files = pcall(function()
        if (ashita.fs.get_directory ~= nil) then
            return ashita.fs.get_directory(folder, '.*');
        end

        if (ashita.fs.get_dir ~= nil) then
            return ashita.fs.get_dir(folder, '.*');
        end

        return nil;
    end);

    if (ok ~= true or type(files) ~= 'table') then
        return {};
    end

    return files;
end

local function GetDirectoryEntryName(entry)
    if (type(entry) == 'table') then
        return tostring(entry.name or entry.Name or entry.file or entry.File or entry.path or entry.Path or '');
    end

    return tostring(entry or '');
end

local function PruneBackups(profileName, force)
    if (IsCharacterProfileName(profileName) ~= true) then
        return;
    end

    local now = os.clock();

    if (force ~= true and (now - (tonumber(state.lastBackupPrune) or 0)) < backupPruneIntervalSeconds) then
        return;
    end

    state.lastBackupPrune = now;

    local folder = GetBackupsFolder(profileName);
    local files = {};
    local totalBytes = 0;

    for _, entry in ipairs(GetDirectoryEntries(folder)) do
        local fileName = GetDirectoryEntryName(entry):gsub('^.*[\\/]', '');

        if (fileName ~= '' and fileName:lower():match('%.lua$') ~= nil) then
            local path = folder .. '\\' .. fileName;
            local size = ReadFileSize(path);

            files[#files + 1] = {
                name = fileName,
                path = path,
                size = size,
            };
            totalBytes = totalBytes + size;
        end
    end

    table.sort(files, function(left, right)
        local leftIsCurrent = tostring(left.name or ''):lower() == 'settings-backup.lua';
        local rightIsCurrent = tostring(right.name or ''):lower() == 'settings-backup.lua';

        if (leftIsCurrent ~= rightIsCurrent) then
            return leftIsCurrent == true;
        end

        return tostring(left.name or '') > tostring(right.name or '');
    end);

    local count = #files;
    local index = #files;

    while (index >= 1 and (count > maxBackupFiles or totalBytes > maxBackupBytes)) do
        local entry = files[index];

        pcall(function()
            os.remove(entry.path);
        end);

        totalBytes = totalBytes - (tonumber(entry.size) or 0);
        count = count - 1;
        index = index - 1;
    end
end

local function BackupActiveProfile(profileName, force)
    if (state.activeProfilePath == nil) then
        return;
    end

    if (ReadFileSize(state.activeProfilePath) <= 0) then
        return;
    end

    local now = os.clock();

    if (
        force ~= true and
        (now - (tonumber(state.lastBackup) or 0)) < normalSaveBackupIntervalSeconds
    ) then
        return;
    end

    if (CopyFile(state.activeProfilePath, GetProfileBackupPath(profileName, state.activeProfileName)) == true) then
        state.lastBackup = now;
    end

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

local function WriteLuaTableFile(path, value)
    local file = io.open(path, 'w');

    if (file == nil) then
        return false;
    end

    file:write('return ' .. SerializeValue(value, 0) .. '\n');
    file:close();

    return true;
end

local function IsSettingsProfile(value)
    return type(value) == 'table' and (type(value.global) == 'table' or type(value.plates) == 'table');
end

local function IsProfileManifest(value)
    return type(value) == 'table' and type(value.activeProfile) == 'string' and type(value.profiles) == 'table';
end

local function GetProfileMetadata(manifest, profileName)
    if (type(manifest) ~= 'table') then
        return nil;
    end

    if (type(manifest.profiles) ~= 'table') then
        manifest.profiles = {};
    end

    profileName = SanitizeProfilePart(profileName) or defaultUserProfileName;

    if (type(manifest.profiles[profileName]) ~= 'table') then
        manifest.profiles[profileName] = {
            name = profileName,
            file = GetProfileRelativePath(profileName),
            version = profileSystemVersion,
            created = GetTimestamp(),
            modified = GetTimestamp(),
        };
    end

    local metadata = manifest.profiles[profileName];

    if (metadata.name == nil) then metadata.name = profileName; end
    if (metadata.file == nil) then metadata.file = GetProfileRelativePath(profileName); end
    if (metadata.version == nil) then metadata.version = profileSystemVersion; end
    if (metadata.created == nil) then metadata.created = GetTimestamp(); end
    if (metadata.modified == nil) then metadata.modified = metadata.created; end

    return metadata;
end

local function CreateDefaultManifest(profileName)
    profileName = SanitizeProfilePart(profileName) or defaultUserProfileName;

    local now = GetTimestamp();
    local manifest = {
        profileSystemVersion = profileSystemVersion,
        activeProfile = profileName,
        profiles = {},
    };

    manifest.profiles[profileName] = {
        name = profileName,
        file = GetProfileRelativePath(profileName),
        version = profileSystemVersion,
        created = now,
        modified = now,
    };

    return manifest;
end

local function SaveProfileManifest()
    if (state.characterProfileName == nil or type(state.profileManifest) ~= 'table') then
        return false;
    end

    if (EnsureProfileSystemFolders(state.characterProfileName) ~= true) then
        return false;
    end

    return WriteLuaTableFile(GetSettingsPath(state.characterProfileName), state.profileManifest);
end

local function GetProfileId(profileName)
    return SanitizeProfilePart(profileName);
end

local function NormalizeJobCode(value, fallback)
    value = tostring(value or fallback or 'Any');
    value = value:gsub('%s+', '');
    value = string.upper(value);

    if (value == '' or value == 'NONE') then
        return fallback or 'Any';
    end

    return value;
end

local function ProfileExists(manifest, profileName)
    profileName = GetProfileId(profileName);

    return profileName ~= nil and type(manifest) == 'table' and type(manifest.profiles) == 'table' and type(manifest.profiles[profileName]) == 'table';
end

local function CountProfiles(manifest)
    local count = 0;

    if (type(manifest) ~= 'table' or type(manifest.profiles) ~= 'table') then
        return 0;
    end

    for _ in pairs(manifest.profiles) do
        count = count + 1;
    end

    return count;
end

local function GetFallbackProfileName(manifest, excludeName)
    excludeName = GetProfileId(excludeName);

    if (type(manifest) ~= 'table' or type(manifest.profiles) ~= 'table') then
        return nil;
    end

    for name in pairs(manifest.profiles) do
        if (tostring(name) ~= tostring(excludeName)) then
            return tostring(name);
        end
    end

    return nil;
end

local function LoadActiveUserProfile()
    if (state.characterProfileName == nil or type(state.profileManifest) ~= 'table') then
        return false;
    end

    local profileName = SetActiveUserProfileName(state.profileManifest.activeProfile or defaultUserProfileName);
    local metadata = GetProfileMetadata(state.profileManifest, profileName);
    local loaded = LoadLuaTableFile(state.activeProfilePath);

    if (IsSettingsProfile(loaded) == true) then
        state.profile = loaded;
        ApplyLoadedWorldEnabled(state.profile);
        return true;
    end

    state.profile = {
        global = {},
        plates = {},
    };
    metadata.modified = GetTimestamp();

    return false;
end

local function InstallProfileSystem(characterProfileName, sourceProfile, sourcePath)
    if (characterProfileName == nil or IsSettingsProfile(sourceProfile) ~= true) then
        return false;
    end

    if (EnsureProfileSystemFolders(characterProfileName) ~= true) then
        return false;
    end

    if (sourcePath ~= nil and ReadFileSize(sourcePath) > 0) then
        CopyFile(sourcePath, GetManifestBackupPath(characterProfileName));
    end

    local profileName = defaultUserProfileName;
    local profilePath = GetProfileDataPath(characterProfileName, profileName);

    if (ReadFileSize(profilePath) <= 0 and WriteLuaTableFile(profilePath, sourceProfile) ~= true) then
        return false;
    end

    state.characterProfileName = characterProfileName;
    state.profileManifest = CreateDefaultManifest(profileName);
    state.profileManifest.migratedAt = GetTimestamp();
    state.profileManifest.migratedFrom = sourcePath ~= nil and tostring(sourcePath) or 'generated';
    state.profile = CopyTable(sourceProfile);
    SetActiveUserProfileName(profileName);
    SaveProfileManifest();
    ApplyLoadedWorldEnabled(state.profile);

    return true;
end

ApplyLoadedWorldEnabled = function(profile)
    if (type(profile) == 'table' and type(profile.global) == 'table' and profile.global.worldEnabled ~= nil) then
        state.worldEnabled = profile.global.worldEnabled == true;
    end
end

local function BumpRevision()
    state.revision = (tonumber(state.revision) or 0) + 1;
end

function state.GetRevision()
    return tonumber(state.revision) or 0;
end

local function RefreshCharacterProfile()
    local profileName = GetCharacterProfileName();

    if (profileName == nil or profileName == globalProfileName) then
        return false;
    end

    if (state.characterProfileName == profileName and type(state.profile) == 'table') then
        return true;
    end

    if (state.characterProfileName ~= profileName) then
        state.Load();
        return type(state.profile) == 'table';
    end

    return false;
end

SerializeValue = function(value, indent)
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

CopyTable = function(value)
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
    state.profileManifest = nil;
    state.characterProfileName = nil;
    state.lastSave = 0;
    state.activeProfileName = nil;
    state.activeProfilePath = nil;
    state.loadedFromDisk = false;
    state.savedThisSession = false;

    local profileName = GetCharacterProfileName() or globalProfileName;
    state.characterProfileName = profileName;

    local candidates = {
        GetSettingsPath(profileName),
    };

    if (profileName ~= globalProfileName) then
        table.insert(candidates, GetSettingsPath(globalProfileName));
    end

    table.insert(candidates, GetLegacyProfilePath());

    local loadedPath = nil;
    local loadedSettings = nil;

    for _, path in ipairs(candidates) do
        local loaded = LoadLuaTableFile(path);

        if (type(loaded) == 'table') then
            loadedSettings = loaded;
            state.loadedFromDisk = true;
            loadedPath = path;
            break;
        end
    end

    if (IsProfileManifest(loadedSettings) == true) then
        state.profileManifest = loadedSettings;
        LoadActiveUserProfile();
    elseif (IsSettingsProfile(loadedSettings) == true) then
        InstallProfileSystem(profileName, loadedSettings, loadedPath);
    else
        state.profileManifest = CreateDefaultManifest(defaultUserProfileName);
        SetActiveUserProfileName(defaultUserProfileName);
        state.profile = nil;
    end

    ApplyLoadedWorldEnabled(state.profile);
    BumpRevision();

end

function state.Save()
    -- Ashita invokes ImGui from native code.  Do not perform filesystem work
    -- while the LibraPlates Settings window is being drawn; settingsUi flushes
    -- this request immediately after it has called imgui.End().
    if (_G.LibraPlatesSettingsUiActive == true) then
        _G.LibraPlatesSettingsSaveRequested = true;
        return true;
    end

    local profile = state.profile;

    if (type(profile) ~= 'table') then
        return false;
    end

    local profileName = GetCharacterProfileName();

    if (profileName == nil and IsCharacterProfileName(state.characterProfileName) == true) then
        profileName = state.characterProfileName;
    end

    if (profileName == nil or IsCharacterProfileName(profileName) ~= true) then
        return false;
    end

    if (state.characterProfileName ~= profileName or state.activeProfilePath == nil) then
        state.characterProfileName = profileName;
        if (type(state.profileManifest) ~= 'table') then
            state.profileManifest = CreateDefaultManifest(defaultUserProfileName);
        end
        SetActiveUserProfileName(state.profileManifest.activeProfile or defaultUserProfileName);
    end

    if (EnsureProfileSystemFolders(profileName) ~= true) then
        return false;
    end

    local serialized = 'return ' .. SerializeValue(profile, 0) .. '\n';
    local oldSize = ReadFileSize(state.activeProfilePath);
    local newSize = string.len(serialized);

    if (
        oldSize >= suspiciousShrinkMinBytes and
        newSize > 0 and
        newSize < (oldSize * suspiciousShrinkRatio)
    ) then
        return false;
    end

    BackupActiveProfile(profileName, false);

    local file = io.open(state.activeProfilePath, 'w');

    if (file == nil) then
        return false;
    end

    file:write(serialized);
    file:close();
    state.lastSave = os.clock();
    state.loadedFromDisk = true;
    state.savedThisSession = true;

    if (type(state.profileManifest) ~= 'table') then
        state.profileManifest = CreateDefaultManifest(state.activeProfileName or defaultUserProfileName);
    end

    state.profileManifest.activeProfile = state.activeProfileName or defaultUserProfileName;
    local metadata = GetProfileMetadata(state.profileManifest, state.profileManifest.activeProfile);
    metadata.modified = GetTimestamp();
    SaveProfileManifest();
    BumpRevision();

    return true;
end

function state.SaveIfLoadedOrSaved()
    if (state.loadedFromDisk ~= true and state.savedThisSession ~= true) then
        return false;
    end

    return state.Save();
end

function state.SaveThrottled(interval)
    interval = tonumber(interval) or 1.0;

    if ((os.clock() - (state.lastSave or 0)) < interval) then
        return;
    end

    state.Save();
end

function state.PruneBackups()
    local profileName = state.characterProfileName or GetCharacterProfileName();

    if (profileName == nil or IsCharacterProfileName(profileName) ~= true) then
        return false;
    end

    PruneBackups(profileName, true);
    return true;
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
    RefreshCharacterProfile();

    if (type(state.profileManifest) ~= 'table') then
        state.profileManifest = CreateDefaultManifest(defaultUserProfileName);
    end

    if (state.activeProfilePath == nil) then
        SetActiveUserProfileName(state.profileManifest.activeProfile or defaultUserProfileName);
    end

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

function state.GetRuntime()
    local profile = state.GetProfile();

    if (type(profile.runtime) ~= 'table') then
        profile.runtime = {};
    end

    return profile.runtime;
end

function state.GetAnonymousByServerId()
    local runtime = state.GetRuntime();

    if (type(runtime.anonymousByServerId) ~= 'table') then
        runtime.anonymousByServerId = {};
    end

    return runtime.anonymousByServerId;
end

function state.GetVisualBlacklist()
    local runtime = state.GetRuntime();

    if (type(runtime.visualBlacklist) ~= 'table') then
        runtime.visualBlacklist = {};
    end

    if (type(runtime.visualBlacklist.entries) ~= 'table') then
        runtime.visualBlacklist.entries = {};
    end

    if (type(runtime.visualBlacklist.pendingNames) ~= 'table') then
        runtime.visualBlacklist.pendingNames = {};
    end

    if (runtime.visualBlacklist.modelReplaceEnabled == nil) then
        runtime.visualBlacklist.modelReplaceEnabled = true;
    end

    runtime.visualBlacklist.modelReplaceRace = tonumber(runtime.visualBlacklist.modelReplaceRace) or 5;
    runtime.visualBlacklist.modelReplaceHair = tonumber(runtime.visualBlacklist.modelReplaceHair) or 2;
    if (runtime.visualBlacklist.modelReplacePreserveRace == nil) then
        runtime.visualBlacklist.modelReplacePreserveRace = true;
    end
    if (runtime.visualBlacklist.modelReplaceClearGear == nil) then
        runtime.visualBlacklist.modelReplaceClearGear = true;
    end
    if (runtime.visualBlacklist.modelReplaceUseFomor == nil) then
        runtime.visualBlacklist.modelReplaceUseFomor = true;
    end
    if (runtime.visualBlacklist.displayNameReplaceEnabled == nil) then
        runtime.visualBlacklist.displayNameReplaceEnabled = true;
    end
    if (type(runtime.visualBlacklist.displayNameColor) ~= 'table') then
        runtime.visualBlacklist.displayNameColor = { 1.0, 0.22, 0.22, 1.0 };
    end

    return runtime.visualBlacklist;
end

function state.GetActiveProfileName()
    RefreshCharacterProfile();

    return state.activeProfileName or defaultUserProfileName;
end

function state.GetProfileManifest()
    RefreshCharacterProfile();

    if (type(state.profileManifest) ~= 'table') then
        state.profileManifest = CreateDefaultManifest(defaultUserProfileName);
    end

    return state.profileManifest;
end

function state.GetProfileNames()
    local manifest = state.GetProfileManifest();
    local names = {};

    for name, metadata in pairs(manifest.profiles or {}) do
        names[#names + 1] = tostring(metadata ~= nil and metadata.name or name);
    end

    table.sort(names, function(a, b)
        return string.lower(tostring(a)) < string.lower(tostring(b));
    end);

    return names;
end

local function GetPresetFilePath(presetName)
    local presetId = SanitizeProfilePart(presetName);

    if (presetId == nil) then
        return nil;
    end

    return GetPresetsFolder() .. '\\' .. presetId .. '.lua';
end

local function LoadPreset(presetName)
    local path = GetPresetFilePath(presetName);
    local loaded = LoadLuaTableFile(path);

    if (type(loaded) ~= 'table') then
        return nil;
    end

    local profile = type(loaded.profile) == 'table' and loaded.profile or loaded;

    if (IsSettingsProfile(profile) ~= true) then
        return nil;
    end

    local presetId = SanitizeProfilePart(presetName);
    return {
        id = presetId,
        name = tostring(loaded.name or presetId),
        description = tostring(loaded.description or ''),
        profile = profile,
    };
end

function state.GetPresetNames()
    local presets = {};

    for _, entry in ipairs(GetDirectoryEntries(GetPresetsFolder())) do
        local fileName = GetDirectoryEntryName(entry):gsub('^.*[\\/]', '');
        local presetId = fileName:gsub('%.lua$', '');

        if (fileName:lower():match('%.lua$') ~= nil) then
            local preset = LoadPreset(presetId);

            if (preset ~= nil) then
                presets[#presets + 1] = preset;
            end
        end
    end

    table.sort(presets, function(left, right)
        return tostring(left.name or ''):lower() < tostring(right.name or ''):lower();
    end);

    return presets;
end

function state.GetPreset(presetName)
    return LoadPreset(presetName);
end

function state.GetPresetCopyName(presetName)
    local preset = LoadPreset(presetName);

    if (preset == nil) then
        return nil;
    end

    local manifest = state.GetProfileManifest();
    local baseName = tostring(preset.name or preset.id);
    local candidate = baseName;
    local suffix = 2;

    while (ProfileExists(manifest, candidate) == true) do
        candidate = baseName .. ' ' .. tostring(suffix);
        suffix = suffix + 1;
    end

    return candidate;
end

function state.CreateProfileFromPreset(presetName)
    local preset = LoadPreset(presetName);

    if (preset == nil) then
        return false, 'Preset is missing or invalid.';
    end

    local manifest = state.GetProfileManifest();
    local profileName = state.GetPresetCopyName(preset.id);
    local profileId = GetProfileId(profileName);

    if (profileName == nil or profileId == nil) then
        return false, 'Preset profile name is invalid.';
    end

    if (ProfileExists(manifest, profileId) == true) then
        return false, 'Profile name already exists.';
    end

    if (EnsureProfileSystemFolders(state.characterProfileName) ~= true) then
        return false, 'Profile folder could not be created.';
    end

    state.Save();

    local profile = CopyTable(preset.profile);
    local profilePath = GetProfileDataPath(state.characterProfileName, profileId);

    if (WriteLuaTableFile(profilePath, profile) ~= true) then
        return false, 'Preset copy could not be saved.';
    end

    local now = GetTimestamp();
    manifest.profiles[profileId] = {
        name = profileName,
        file = GetProfileRelativePath(profileId),
        version = profileSystemVersion,
        created = now,
        modified = now,
        preset = preset.id,
        autoSwitch = {
            enabled = false,
            mainJob = 'WAR',
            subJob = 'Any',
        },
    };
    manifest.activeProfile = profileId;
    SetActiveUserProfileName(profileId);
    state.profile = profile;
    state.loadedFromDisk = true;
    state.savedThisSession = true;
    ApplyLoadedWorldEnabled(state.profile);
    SaveProfileManifest();

    return true, profileName;
end

function state.GetProfileAutoSwitchEnabled()
    local manifest = state.GetProfileManifest();

    if (manifest.autoSwitchProfilesEnabled == nil) then
        manifest.autoSwitchProfilesEnabled = false;
    end

    return manifest.autoSwitchProfilesEnabled == true;
end

function state.SetProfileAutoSwitchEnabled(enabled)
    local manifest = state.GetProfileManifest();
    manifest.autoSwitchProfilesEnabled = enabled == true;

    return SaveProfileManifest();
end

function state.GetProfileAssignment(profileName)
    local manifest = state.GetProfileManifest();
    local profileId = GetProfileId(profileName or manifest.activeProfile);

    if (profileId == nil or ProfileExists(manifest, profileId) ~= true) then
        return {
            enabled = false,
            mainJob = 'WAR',
            subJob = 'Any',
        };
    end

    local metadata = GetProfileMetadata(manifest, profileId);

    if (type(metadata.autoSwitch) ~= 'table') then
        metadata.autoSwitch = {};
    end

    metadata.autoSwitch.enabled = metadata.autoSwitch.enabled == true;
    metadata.autoSwitch.mainJob = NormalizeJobCode(metadata.autoSwitch.mainJob, 'WAR');
    metadata.autoSwitch.subJob = NormalizeJobCode(metadata.autoSwitch.subJob, 'Any');
    if (metadata.autoSwitch.subJob == metadata.autoSwitch.mainJob) then
        metadata.autoSwitch.subJob = 'Any';
    end

    return metadata.autoSwitch;
end

function state.SetProfileAssignment(profileName, enabled, mainJob, subJob)
    local manifest = state.GetProfileManifest();
    local profileId = GetProfileId(profileName or manifest.activeProfile);

    if (profileId == nil or ProfileExists(manifest, profileId) ~= true) then
        return false;
    end

    local metadata = GetProfileMetadata(manifest, profileId);
    mainJob = NormalizeJobCode(mainJob, 'WAR');
    subJob = NormalizeJobCode(subJob, 'Any');

    if (subJob == mainJob) then
        subJob = 'Any';
    end

    metadata.autoSwitch = {
        enabled = enabled == true,
        mainJob = mainJob,
        subJob = subJob,
    };
    metadata.modified = GetTimestamp();

    return SaveProfileManifest();
end

function state.SetActiveProfile(profileName)
    local manifest = state.GetProfileManifest();
    profileName = SanitizeProfilePart(profileName);

    if (profileName == nil or manifest.profiles == nil or manifest.profiles[profileName] == nil) then
        return false;
    end

    state.Save();
    manifest.activeProfile = profileName;
    SetActiveUserProfileName(profileName);

    if (LoadActiveUserProfile() ~= true) then
        return false;
    end

    SaveProfileManifest();

    return true;
end

function state.CreateProfile(profileName, copyCurrent)
    local manifest = state.GetProfileManifest();
    local profileId = GetProfileId(profileName);

    if (profileId == nil) then
        return false, 'Profile name is empty.';
    end

    if (ProfileExists(manifest, profileId) == true) then
        return false, 'Profile name already exists.';
    end

    if (EnsureProfileSystemFolders(state.characterProfileName) ~= true) then
        return false, 'Profile folder could not be created.';
    end

    local source = (copyCurrent ~= false) and CopyTable(state.GetProfile()) or { global = {}, plates = {} };
    local profilePath = GetProfileDataPath(state.characterProfileName, profileId);

    if (WriteLuaTableFile(profilePath, source) ~= true) then
        return false, 'Profile could not be saved.';
    end

    local now = GetTimestamp();
    manifest.profiles[profileId] = {
        name = tostring(profileName or profileId),
        file = GetProfileRelativePath(profileId),
        version = profileSystemVersion,
        created = now,
        modified = now,
    };
    manifest.activeProfile = profileId;
    SaveProfileManifest();
    SetActiveUserProfileName(profileId);
    state.profile = source;
    state.loadedFromDisk = true;
    state.savedThisSession = true;

    return true;
end

function state.CopyProfile(sourceName, newName)
    local manifest = state.GetProfileManifest();
    local sourceId = GetProfileId(sourceName);
    local newId = GetProfileId(newName);

    if (sourceId == nil or ProfileExists(manifest, sourceId) ~= true) then
        return false, 'Source profile is missing.';
    end

    if (newId == nil) then
        return false, 'Profile name is empty.';
    end

    if (ProfileExists(manifest, newId) == true) then
        return false, 'Profile name already exists.';
    end

    state.Save();

    local sourcePath = GetProfileDataPath(state.characterProfileName, sourceId);
    local targetPath = GetProfileDataPath(state.characterProfileName, newId);

    if (CopyFile(sourcePath, targetPath) ~= true) then
        return false, 'Profile copy failed.';
    end

    local now = GetTimestamp();
    manifest.profiles[newId] = {
        name = tostring(newName or newId),
        file = GetProfileRelativePath(newId),
        version = profileSystemVersion,
        created = now,
        modified = now,
        copiedFrom = sourceId,
        autoSwitch = {
            enabled = false,
            mainJob = 'WAR',
            subJob = 'Any',
        },
    };
    manifest.activeProfile = newId;
    SaveProfileManifest();
    SetActiveUserProfileName(newId);
    LoadActiveUserProfile();

    return true;
end

function state.RenameProfile(oldName, newName)
    local manifest = state.GetProfileManifest();
    local oldId = GetProfileId(oldName);
    local newId = GetProfileId(newName);

    if (oldId == nil or ProfileExists(manifest, oldId) ~= true) then
        return false, 'Profile is missing.';
    end

    if (newId == nil) then
        return false, 'Profile name is empty.';
    end

    if (oldId ~= newId and ProfileExists(manifest, newId) == true) then
        return false, 'Profile name already exists.';
    end

    state.Save();

    local oldPath = GetProfileDataPath(state.characterProfileName, oldId);
    local newPath = GetProfileDataPath(state.characterProfileName, newId);

    if (oldId ~= newId) then
        CopyFile(oldPath, GetProfileBackupPath(state.characterProfileName, oldId));

        local renameOk, renameResult = pcall(function()
            return os.rename(oldPath, newPath);
        end);

        if ((renameOk ~= true or renameResult ~= true) and CopyFile(oldPath, newPath) ~= true) then
            return false, 'Profile rename failed.';
        end

        if (renameOk ~= true or renameResult ~= true) then
            pcall(function()
                os.remove(oldPath);
            end);
        end
    end

    local metadata = manifest.profiles[oldId] or {};
    manifest.profiles[oldId] = nil;
    metadata.name = tostring(newName or newId);
    metadata.file = GetProfileRelativePath(newId);
    metadata.modified = GetTimestamp();
    manifest.profiles[newId] = metadata;

    if (manifest.activeProfile == oldId) then
        manifest.activeProfile = newId;
        SetActiveUserProfileName(newId);
    end

    SaveProfileManifest();

    return true;
end

function state.DeleteProfile(profileName)
    local manifest = state.GetProfileManifest();
    local profileId = GetProfileId(profileName);

    if (profileId == nil or ProfileExists(manifest, profileId) ~= true) then
        return false, 'Profile is missing.';
    end

    if (CountProfiles(manifest) <= 1) then
        return false, 'Cannot delete the last profile.';
    end

    state.Save();

    local fallback = GetFallbackProfileName(manifest, profileId);

    if (fallback == nil) then
        return false, 'No fallback profile exists.';
    end

    local profilePath = GetProfileDataPath(state.characterProfileName, profileId);

    CopyFile(profilePath, GetProfileBackupPath(state.characterProfileName, profileId));
    pcall(function()
        os.remove(profilePath);
    end);

    manifest.profiles[profileId] = nil;
    manifest.activeProfile = fallback;
    SetActiveUserProfileName(fallback);
    LoadActiveUserProfile();
    SaveProfileManifest();

    return true;
end

function state.ResetProfile(profileName)
    local manifest = state.GetProfileManifest();
    local profileId = GetProfileId(profileName or manifest.activeProfile);

    if (profileId == nil or ProfileExists(manifest, profileId) ~= true) then
        return false, 'Profile is missing.';
    end

    local profilePath = GetProfileDataPath(state.characterProfileName, profileId);

    CopyFile(profilePath, GetProfileBackupPath(state.characterProfileName, profileId));

    local fresh = {
        global = {},
        plates = {},
    };

    if (WriteLuaTableFile(profilePath, fresh) ~= true) then
        return false, 'Profile reset failed.';
    end

    local metadata = GetProfileMetadata(manifest, profileId);
    metadata.modified = GetTimestamp();

    if (manifest.activeProfile == profileId) then
        state.profile = fresh;
        SetActiveUserProfileName(profileId);
        ApplyLoadedWorldEnabled(state.profile);
    end

    SaveProfileManifest();

    return true;
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

    if (profile.global.enemyIconStyle == nil or tostring(profile.global.enemyIconStyle) == '') then
        local peerStyle = type(profile.global.peer) == 'table' and profile.global.peer.iconStyle or nil;
        profile.global.enemyIconStyle = tostring(peerStyle or 'round');
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
