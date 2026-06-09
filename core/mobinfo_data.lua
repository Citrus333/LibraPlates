require('common');

local bit = require('bit');

local mobInfo = {};
local currentZoneId = 0;
local zoneData = {
    Names = {},
    Indices = {},
};

local function PathExists(path)
    local ok, exists = pcall(function()
        return ashita.fs.exists(path);
    end);

    return ok == true and exists == true;
end

local function GetDataPath()
    return tostring(addon.path or '') .. '\\submodules\\mobdb\\addons\\mobdb\\data\\';
end

function mobInfo.HasActivityPointMarker(mobName)
    local text = tostring(mobName or '');

    return text:sub(1, 1) == string.char(0xAB) or text:sub(1, 2) == '«';
end

function mobInfo.GetLookupName(mobName)
    local text = tostring(mobName or '');

    while (text:sub(1, 1) == string.char(0xAB) or text:sub(1, 2) == '«') do
        if (text:sub(1, 1) == string.char(0xAB)) then
            text = text:sub(2);
        else
            text = text:sub(3);
        end
    end

    return text:gsub('^%s+', ''):gsub('%s+$', '');
end

function mobInfo.LoadZone(zoneId)
    zoneId = tonumber(zoneId) or 0;

    if (zoneId == currentZoneId) then
        return zoneData.Names ~= nil and next(zoneData.Names) ~= nil;
    end

    currentZoneId = zoneId;
    zoneData.Names = {};
    zoneData.Indices = {};

    if (zoneId == 0) then
        return false;
    end

    local filePath = GetDataPath() .. tostring(zoneId) .. '.lua';

    if (PathExists(filePath) ~= true) then
        return false;
    end

    local loadFunc, loadError = loadfile(filePath);

    if (loadFunc == nil) then
        print('[LibraPlates] Failed to load mob info: ' .. tostring(loadError));
        return false;
    end

    local ok, result = pcall(loadFunc);

    if (ok ~= true or type(result) ~= 'table') then
        print('[LibraPlates] Failed to read mob info: ' .. tostring(result));
        return false;
    end

    zoneData.Names = result.Names or {};
    zoneData.Indices = result.Indices or {};

    return next(zoneData.Names) ~= nil;
end

function mobInfo.LoadCurrentZone()
    local zoneId = 0;

    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    return mobInfo.LoadZone(zoneId);
end

function mobInfo.GetMobInfo(mobName, entityIndex)
    mobInfo.LoadCurrentZone();

    if (entityIndex ~= nil and zoneData.Indices ~= nil and zoneData.Indices[entityIndex] ~= nil) then
        return zoneData.Indices[entityIndex];
    end

    if (mobName == nil or zoneData.Names == nil) then
        return nil;
    end

    return zoneData.Names[mobName] or zoneData.Names[mobInfo.GetLookupName(mobName)];
end

function mobInfo.GetLevelString(info)
    if (info == nil) then
        return '';
    end

    local minLevel = info.MinLevel or info.Level;
    local maxLevel = info.MaxLevel or info.Level;

    if (minLevel == nil and maxLevel == nil) then
        return '';
    end

    if (maxLevel == nil or minLevel == maxLevel) then
        return tostring(minLevel or maxLevel);
    end

    return tostring(minLevel) .. '-' .. tostring(maxLevel);
end

function mobInfo.GetJobString(info)
    if (info == nil or info.Job == nil or tonumber(info.Job) == nil or tonumber(info.Job) == 0) then
        return '';
    end

    local ok, result = pcall(function()
        return AshitaCore:GetResourceManager():GetString('jobs.names_abbr', tonumber(info.Job));
    end);

    if (ok == true and result ~= nil) then
        return tostring(result);
    end

    local jobs = T{
        [1] = 'WAR',
        [2] = 'MNK',
        [3] = 'WHM',
        [4] = 'BLM',
        [5] = 'RDM',
        [6] = 'THF',
        [7] = 'PLD',
        [8] = 'DRK',
        [9] = 'BST',
        [10] = 'BRD',
        [11] = 'RNG',
        [12] = 'SAM',
        [13] = 'NIN',
        [14] = 'DRG',
        [15] = 'SMN',
        [16] = 'BLU',
        [17] = 'COR',
        [18] = 'PUP',
        [19] = 'DNC',
        [20] = 'SCH',
        [21] = 'GEO',
        [22] = 'RUN',
    };

    return jobs[tonumber(info.Job)] or '';
end

function mobInfo.GetModifierRows(info)
    local rows = {};

    if (info == nil or info.Modifiers == nil) then
        return rows;
    end

    for name, potency in pairs(info.Modifiers) do
        potency = tonumber(potency);

        if (potency ~= nil and potency ~= 1) then
            rows[#rows + 1] = {
                icon = tostring(name),
                potency = potency,
            };
        end
    end

    table.sort(rows, function(a, b)
        local aDelta = math.abs((a.potency or 1) - 1);
        local bDelta = math.abs((b.potency or 1) - 1);

        if (aDelta == bDelta) then
            return tostring(a.icon) < tostring(b.icon);
        end

        return aDelta > bDelta;
    end);

    return rows;
end

function mobInfo.GetFlags(info)
    local flags = {};

    if (info == nil) then
        return flags;
    end

    if (info.Notorious == true) then
        flags[#flags + 1] = info.Aggro == true and 'AggroHQ' or 'PassiveHQ';
    else
        flags[#flags + 1] = info.Aggro == true and 'AggroNQ' or 'PassiveNQ';
    end

    local names = T{ 'Link', 'TrueSight', 'Sight', 'Sound', 'Scent', 'Magic', 'JA', 'Blood' };

    for _, name in ipairs(names) do
        if (info[name] == true) then
            flags[#flags + 1] = name;
        end
    end

    return flags;
end

function mobInfo.GetImmunityFlags(info)
    local flags = {};
    local immunities = tonumber(info ~= nil and info.Immunities) or 0;
    local names = T{
        { flag = 0x01, icon = 'ImmuneSleep' },
        { flag = 0x02, icon = 'ImmuneGravity' },
        { flag = 0x04, icon = 'ImmuneBind' },
        { flag = 0x08, icon = 'ImmuneStun' },
        { flag = 0x10, icon = 'ImmuneSilence' },
        { flag = 0x20, icon = 'ImmuneParalyze' },
        { flag = 0x40, icon = 'ImmuneBlind' },
        { flag = 0x80, icon = 'ImmuneSlow' },
        { flag = 0x100, icon = 'ImmunePoison' },
        { flag = 0x200, icon = 'ImmuneElegy' },
        { flag = 0x400, icon = 'ImmuneRequiem' },
        { flag = 0x800, icon = 'ImmuneLightSleep' },
        { flag = 0x1000, icon = 'ImmuneDarkSleep' },
        { flag = 0x2000, icon = 'ImmunePetrify' },
    };

    for _, row in ipairs(names) do
        if (bit.band(immunities, row.flag) ~= 0) then
            flags[#flags + 1] = row.icon;
        end
    end

    return flags;
end

return mobInfo;
