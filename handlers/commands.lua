local state = require('core.state');
local log = require('core.log');
local bit = require('bit');
local occlusion = require('core.occlusion');
local canvasDefaults = require('config.canvas');
local canvasTexture = require('core.canvas_texture');
local entities = require('core.entities');
local worldMarkerProbe = require('core.world_marker_probe');
local mouseControls = require('core.mouse_controls');
local targeting = require('core.targeting');
local engagedEnemies = require('core.engaged_enemies');
local enmity = require('core.enmity');
local enemyPlate = require('modules.plates.enemy');
local overlaySuppression = require('core.overlay_suppression');
local nativeTargetArrow = require('core.native_target_arrow');
local targetOverlay = require('modules.target_overlay');
local targetModuleMarker = require('core.target_module_marker');
local modules = require('modules.init');
local perfMeter = require('core.perf_meter');
local lagTest = require('core.lag_test');
local diagnostics = require('core.diagnostics');
local petState = require('core.pet_state');
local abilityRecast = require('libs.abilityrecast');
local enemyCasts = require('core.enemy_casts');
local targetActionRange = require('core.target_action_range');
local aoeNameHighlight = require('core.aoe_name_highlight');
local adaptivePerformance = require('core.adaptive_performance');
local cursorOverlay = require('core.cursor_overlay');
local petPlate = require('modules.plates.pet');
local mogJobDebug = require('core.mog_job_debug');
local luopanStatuses = require('core.luopan_statuses');
local jobChange = require('core.job_change');
local globalDefaults = require('config.global');
local jobDefaults = require('config.widgets.job');
local levelDefaults = require('config.widgets.level');
local buffsDefaults = require('config.widgets.buffs');
local debuffsDefaults = require('config.widgets.debuffs');
local playerStatuses = require('core.player_statuses');
local partyStatuses = require('core.party_statuses');
local enemyStatuses = require('core.enemy_statuses');
local npcObjectInfo = require('core.npc_object_info');
local typeLineDefaults = require('config.widgets.type_line');
local mounts = require('core.mounts');

local commands = {};
local visDebugCaptures = {};
local npcCapturePath = 'C:\\Users\\Lila\\Documents\\ffxi Addon Work\\WORK\\missing_npcs.txt';

local function HasFlag(value, flag)
    return bit.band(tonumber(value) or 0, flag) ~= 0;
end

local function DebugFlagList(value, flags)
    local parts = {};

    value = tonumber(value) or 0;

    for _, flag in ipairs(flags) do
        if (HasFlag(value, flag) == true) then
            parts[#parts + 1] = string.format('0x%X', flag);
        end
    end

    if (#parts == 0) then
        return '-';
    end

    return table.concat(parts, ',');
end

function LibraPlatesFormatRenderFlags(targetIndex)
    local gameMode = require('core.game_mode');
    local parts = {};

    for flagIndex = 0, 7 do
        parts[#parts + 1] = 'r' .. tostring(flagIndex) .. '=0x' .. string.format('%X', gameMode.ReadRenderFlag(targetIndex, flagIndex));
    end

    return table.concat(parts, ' ');
end

function LibraPlatesResolveNativeNameColorProbe(targetIndex)
    local gameMode = require('core.game_mode');
    local playerIndicators = require('core.player_indicators');
    local anon = playerIndicators.HasAnonNameColor(targetIndex) == true;
    local modeText = gameMode.Resolve(targetIndex, false);

    if (anon == true) then
        return 'anon-blue#1A4C97';
    end

    if (modeText == 'CW' or modeText == 'UCW') then
        return tostring(modeText) .. '-orange#' .. playerIndicators.GetCampaignNameColorHex();
    end

    return 'normal';
end

-- ============================================================
-- Parsing
-- ============================================================

local function SplitCommand(command)
    local args = {};

    for part in tostring(command or ''):gmatch('%S+') do
        table.insert(args, part);
    end

    return args;
end

local function CommandSafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function GetDebugServerId(entityManager, index)
    index = tonumber(index) or 0;

    if (entityManager == nil or index <= 0) then
        return 0;
    end

    return tonumber(CommandSafeCall(0, function()
        return entityManager:GetServerId(index);
    end)) or 0;
end

local function GetDebugStatus(entityManager, index)
    index = tonumber(index) or 0;

    if (entityManager == nil or index <= 0) then
        return nil;
    end

    return CommandSafeCall(nil, function()
        return entityManager:GetStatus(index);
    end);
end

local function ProbeTargetMethod(targetManager, methodName, ...)
    if (targetManager == nil or targetManager[methodName] == nil) then
        return 'noapi';
    end

    local args = { ... };
    local ok, result = pcall(function()
        return targetManager[methodName](targetManager, unpack(args));
    end);

    if (ok ~= true) then
        return 'err:' .. tostring(result);
    end

    return tostring(result);
end

local function ProbeEntityAtIndex(entityManager, index)
    index = tonumber(index);

    if (entityManager == nil or index == nil or index <= 0) then
        return 'none';
    end

    local ent = GetEntity(index);
    local render0 = CommandSafeCall(nil, function() return entityManager:GetRenderFlags0(index); end);
    local render1 = CommandSafeCall(nil, function() return entityManager:GetRenderFlags1(index); end);
    local spawn = CommandSafeCall(nil, function() return entityManager:GetSpawnFlags(index); end);

    return
        'index=' .. tostring(index) ..
        ' name=' .. tostring(ent ~= nil and ent.Name or nil) ..
        ' type=' .. tostring(ent ~= nil and ent.Type or nil) ..
        ' status=' .. tostring(ent ~= nil and ent.Status or nil) ..
        ' hp=' .. tostring(ent ~= nil and ent.HPPercent or nil) ..
        ' distance=' .. tostring(ent ~= nil and ent.Distance or nil) ..
        ' server=' .. tostring(GetDebugServerId(entityManager, index)) ..
        ' spawn=0x' .. string.format('%X', tonumber(spawn) or 0) ..
        ' render0=0x' .. string.format('%X', tonumber(render0) or 0) ..
        ' render1=0x' .. string.format('%X', tonumber(render1) or 0);
end

local function LogCurrentTargetProbe(label)
    local memory = CommandSafeCall(nil, function()
        return AshitaCore:GetMemoryManager();
    end);
    local targetManager = memory ~= nil and CommandSafeCall(nil, function()
        return memory:GetTarget();
    end) or nil;
    local entityManager = memory ~= nil and CommandSafeCall(nil, function()
        return memory:GetEntity();
    end) or nil;
    local party = memory ~= nil and CommandSafeCall(nil, function()
        return memory:GetParty();
    end) or nil;

    local slots = {};
    for slot = 0, 7 do
        slots[#slots + 1] = tostring(slot) .. '=' .. ProbeTargetMethod(targetManager, 'GetTargetIndex', slot);
    end

    local partySelf = CommandSafeCall(nil, function()
        return party:GetMemberTargetIndex(0);
    end);
    local normalizedTarget = targeting.GetCurrentTargetIndex();
    local normalizedSub = targeting.GetCurrentSubTargetIndex();
    local candidates = {};
    local seen = {};

    local function addCandidate(value)
        local number = tonumber(value);
        if (number ~= nil and number > 0 and seen[number] ~= true) then
            seen[number] = true;
            candidates[#candidates + 1] = number;
        end
    end

    addCandidate(normalizedTarget);
    addCandidate(normalizedSub);
    addCandidate(partySelf);
    for slot = 0, 7 do
        local value = ProbeTargetMethod(targetManager, 'GetTargetIndex', slot);
        addCandidate(value);
    end

    log.Info(
        tostring(label or 'Current target probe') ..
        ' targetMgr=' .. tostring(targetManager ~= nil) ..
        ' normalizedTarget=' .. tostring(normalizedTarget) ..
        ' normalizedSub=' .. tostring(normalizedSub) ..
        ' subActive=' .. ProbeTargetMethod(targetManager, 'GetIsSubTargetActive') ..
        ' subFlags=' .. ProbeTargetMethod(targetManager, 'GetSubTargetFlags') ..
        ' locked=' .. ProbeTargetMethod(targetManager, 'GetIsLockedOn') ..
        ' lockedFlags=' .. ProbeTargetMethod(targetManager, 'GetLockedOnFlags') ..
        ' partySelfTarget=' .. tostring(partySelf) ..
        ' slots ' .. table.concat(slots, ' ')
    );

    if (#candidates <= 0) then
        log.Warn(tostring(label or 'Current target probe') .. ' found no target index from raw target APIs.');
        return;
    end

    for _, index in ipairs(candidates) do
        log.Info(tostring(label or 'Current target probe') .. ' entity ' .. ProbeEntityAtIndex(entityManager, index));
    end
end

local function FormatDebugNumber(value)
    local number = tonumber(value);

    if (number == nil) then
        return tostring(value);
    end

    return string.format('%.4f', number);
end

local function ParseDebugList(text)
    local values = {};

    for key, value in tostring(text or ''):gmatch('([^=,]+)=([^,]+)') do
        values[tostring(key)] = tonumber(value) or tostring(value);
    end

    return values;
end

local function FormatEntityScalarProbe(entity)
    if (type(entity) ~= 'table') then
        return 'none';
    end

    local keys = {
        'Name', 'Type', 'Status', 'HPPercent', 'MPPercent', 'TP', 'Distance',
        'SpawnFlags', 'RenderFlags0', 'RenderFlags1', 'RenderFlags2', 'RenderFlags3',
        'RenderFlags4', 'RenderFlags5', 'RenderFlags6', 'RenderFlags7',
        'LinkshellColor', 'GameMode', 'Flags', 'Flags1', 'Flags2', 'Flags3',
        'ClaimStatus', 'PetTargetIndex', 'TargetIndex',
    };
    local parts = {};

    for _, key in ipairs(keys) do
        local value = entity[key];

        if (value ~= nil and type(value) ~= 'table' and type(value) ~= 'function') then
            if (type(value) == 'number') then
                parts[#parts + 1] = key .. '=' .. tostring(value) .. '/0x' .. string.format('%X', value);
            else
                parts[#parts + 1] = key .. '=' .. tostring(value);
            end
        end
    end

    if (#parts == 0) then
        return 'none';
    end

    return table.concat(parts, ' ');
end

local function ReadPartyProbeValue(party, methodName, slot)
    if (party == nil or party[methodName] == nil) then
        return nil;
    end

    return CommandSafeCall(nil, function()
        return party[methodName](party, slot);
    end);
end

local function FormatPartySelfProbe()
    local party = CommandSafeCall(nil, function()
        return AshitaCore:GetMemoryManager():GetParty();
    end);

    if (party == nil) then
        return 'none';
    end

    local methodNames = {
        'GetMemberIsActive',
        'GetMemberTargetIndex',
        'GetMemberServerId',
        'GetMemberStatus',
        'GetMemberZone',
        'GetMemberHPPercent',
        'GetMemberMPPercent',
        'GetMemberTP',
        'GetMemberFlags',
        'GetMemberFlags1',
        'GetMemberFlags2',
        'GetMemberFlag',
        'GetMemberGameMode',
        'GetMemberLinkshellColor',
    };
    local parts = {};

    for _, methodName in ipairs(methodNames) do
        local value = ReadPartyProbeValue(party, methodName, 0);

        if (value ~= nil and type(value) ~= 'table' and type(value) ~= 'function') then
            if (type(value) == 'number') then
                parts[#parts + 1] = methodName .. '=' .. tostring(value) .. '/0x' .. string.format('%X', value);
            else
                parts[#parts + 1] = methodName .. '=' .. tostring(value);
            end
        end
    end

    if (#parts == 0) then
        return 'none';
    end

    return table.concat(parts, ' ');
end

_G.LibraPlatesFormatPartySelfProbe = FormatPartySelfProbe;

function LibraPlatesHandleSelfAnonProbe()
    local selfEntity = entities.GetSelf();
    local selfIndex = tonumber(selfEntity ~= nil and selfEntity.index) or 0;

    if (selfIndex == 0) then
        log.Warn('Self anon probe failed: self index missing.');
        return;
    end

    local entityManager = entities.GetEntityManager ~= nil and entities.GetEntityManager() or nil;
    local entity = GetEntity(selfIndex);
    local debug = entities.GetEntityDebugInfo(selfIndex, targeting.GetSettings().enemyPlateRange);
    local probeGameMode = require('core.game_mode');
    local probePlayerIndicators = require('core.player_indicators');
    local flagParts = {};

    for flagIndex = 0, 7 do
        local value = tonumber(debug ~= nil and debug.renderFlags ~= nil and debug.renderFlags[flagIndex]) or 0;
        flagParts[#flagParts + 1] = 'r' .. tostring(flagIndex) .. '=0x' .. string.format('%X', value);
    end

    log.Info(
        'Self anon probe main' ..
        ' index=' .. tostring(selfIndex) ..
        ' name=' .. tostring(selfEntity ~= nil and selfEntity.name or nil) ..
        ' serverId=' .. tostring(GetDebugServerId(entityManager, selfIndex)) ..
        ' status=' .. tostring(selfEntity ~= nil and selfEntity.status or nil) ..
        ' type=' .. tostring(debug ~= nil and debug.type or nil) ..
        ' spawn=0x' .. string.format('%X', tonumber(debug ~= nil and debug.spawnFlags or 0) or 0) ..
        ' flags=' .. table.concat(flagParts, ' ') ..
        ' mode=' .. tostring(probeGameMode.Resolve(selfIndex, false)) ..
        ' anonGuess=' .. tostring(probePlayerIndicators.HasAnonNameColor(selfIndex) == true) ..
        ' lpNameColorGuess=' .. LibraPlatesResolveNativeNameColorProbe(selfIndex)
    );

    log.Info(
        'Self anon probe bits' ..
        ' r0=' .. DebugFlagList(probeGameMode.ReadRenderFlag(selfIndex, 0), { 0x200, 0x800, 0x2000, 0x4000, 0x8000, 0x400000, 0x800000, 0x40000000, 0x80000000 }) ..
        ' r1=' .. DebugFlagList(probeGameMode.ReadRenderFlag(selfIndex, 1), { 0x8, 0x40, 0x400, 0x800, 0x8000, 0x800000, 0x1000000, 0x2000000, 0x4000000, 0x8000000, 0x10000000 }) ..
        ' r2=' .. DebugFlagList(probeGameMode.ReadRenderFlag(selfIndex, 2), { 0x1, 0x2, 0x4, 0x8, 0x10, 0x20, 0x40, 0x80, 0x100, 0x200, 0x400, 0x800, 0x1000 }) ..
        ' r4=' .. DebugFlagList(probeGameMode.ReadRenderFlag(selfIndex, 4), { 0x1000, 0x2000, 0x4000, 0x8000, 0x10000, 0x20000 })
    );

    log.Info('Self anon probe entity ' .. FormatEntityScalarProbe(entity));
    log.Info('Self anon probe party ' .. FormatPartySelfProbe());
end

local function GetPcRaceGuess(modelKey)
    modelKey = tonumber(modelKey);

    if (modelKey == nil) then
        return 'unknown';
    end

    if (modelKey == 0x0001) then
        return 'Hume';
    elseif (modelKey == 0x3D01) then
        return 'Mithra';
    elseif (modelKey == 0x7301) then
        return 'Elvaan';
    elseif (modelKey == 0xB701) then
        return 'Galka';
    end

    return 'unknown';
end

local function NearlyEqual(value, target, tolerance)
    value = tonumber(value);
    target = tonumber(target);
    tolerance = tonumber(tolerance) or 0.05;

    if (value == nil or target == nil) then
        return false;
    end

    return math.abs(value - target) <= tolerance;
end

local function GetPcBodyGuess(debug)
    if (debug == nil) then
        return 'unknown';
    end

    local bones = tonumber(debug.boneCount);
    local zSpan = tonumber(debug.boneSpanZ);
    local ySpan = tonumber(debug.boneSpanY);

    if (bones == 93 and NearlyEqual(zSpan, 2.10, 0.06) and NearlyEqual(ySpan, 1.90, 0.08)) then
        return 'Tarutaru';
    elseif (bones == 108 and NearlyEqual(zSpan, 2.00, 0.08) and NearlyEqual(ySpan, 2.50, 0.08)) then
        return 'Mithra';
    elseif ((bones == 97 or bones == 94 or bones == 93) and zSpan >= 2.10 and zSpan <= 2.70 and NearlyEqual(ySpan, 2.50, 0.08)) then
        return 'Hume';
    elseif (bones == 99 and NearlyEqual(zSpan, 3.40, 0.10) and NearlyEqual(ySpan, 2.50, 0.08)) then
        return 'Elvaan';
    elseif (bones == 107 and NearlyEqual(zSpan, 3.04, 0.10) and NearlyEqual(ySpan, 2.65, 0.08)) then
        return 'Galka';
    end

    return 'unknown';
end

local function GetPcHeightSizeBucket(sizeScale, familyKey)
    local scale = tonumber(sizeScale);

    if (scale == nil) then
        return 'unknown';
    end

    if (tostring(familyKey or '') == 'tarutaru') then
        if (scale < 0.845) then
            return 'Small';
        end

        if (scale < 0.895) then
            return 'Medium';
        end

        return 'Large';
    end

    if (tostring(familyKey or '') == 'mithra') then
        if (scale < 0.91) then
            return 'Small';
        end

        if (scale < 0.95) then
            return 'Medium';
        end

        return 'Large';
    end

    if (scale < 0.985) then
        return 'Small';
    end

    if (scale > 1.015) then
        return 'Large';
    end

    return 'Medium';
end

local function GetPcHeightFamilyKey(family)
    family = tostring(family or ''):lower();

    if (family == 'tarutaru') then
        return 'tarutaru';
    elseif (family == 'mithra') then
        return 'mithra';
    elseif (family == 'hume') then
        return 'hume';
    elseif (family == 'elvaan') then
        return 'elvaan';
    elseif (family == 'galka') then
        return 'galka';
    end

    return nil;
end

local function GetPcHeightBaselineY(familyKey, sex, sizeBucket)
    local sizeKey = tostring(sizeBucket or ''):lower();
    local sexKey = tostring(sex or ''):lower();
    local baselines = {
        tarutaru = {
            male = { small = 64, medium = 63, large = 52 },
            female = { small = 70, medium = 64, large = 62 },
        },
        mithra = {
            female = { small = 62, medium = 44, large = 42 },
        },
        hume = {
            male = { small = 30, medium = 28, large = 27 },
            female = { small = 52, medium = 31, large = 29 },
        },
        elvaan = {
            male = { small = 37, medium = 35, large = 33 },
            female = { small = 48, medium = 38, large = 36 },
        },
        galka = {
            male = { small = 34, medium = 31, large = 28 },
        },
    };
    local family = baselines[tostring(familyKey or '')];
    local bySex = family ~= nil and (family[sexKey] or family.male or family.female) or nil;

    if (bySex ~= nil) then
        return tonumber(bySex[sizeKey]) or tonumber(bySex.medium) or 0;
    end

    return 0;
end

local function GetPcHeightBucketKey(familyKey, sex, sizeBucket)
    local sexKey = tostring(sex or ''):lower();
    local sizeKey = tostring(sizeBucket or ''):lower();

    if (familyKey == nil or sexKey == '' or sizeKey == '') then
        return nil;
    end

    return tostring(familyKey) .. '_' .. sexKey .. '_' .. sizeKey;
end

local function GetPcHeightAdjustmentY(adjustments, familyKey, sex, sizeBucket)
    local bucketKey = GetPcHeightBucketKey(familyKey, sex, sizeBucket);
    local bucket = bucketKey ~= nil and type(adjustments.buckets) == 'table' and adjustments.buckets[bucketKey] or nil;

    if (type(bucket) == 'table' and bucket.y ~= nil) then
        return tonumber(bucket.y) or 0, bucketKey;
    end

    local race = familyKey ~= nil and type(adjustments[familyKey]) == 'table' and adjustments[familyKey] or nil;
    return tonumber(race ~= nil and race.y) or 0, bucketKey;
end

local EnsurePcHeightSettings = nil;

local function GetPcHeightReferenceText(familyKey, sizeBucket)
    familyKey = tostring(familyKey or '');
    sizeBucket = tostring(sizeBucket or '');

    local sizeIndex = ({ Small = 1, Medium = 2, Large = 3 })[sizeBucket];

    if (sizeIndex == nil) then
        return 'unknown';
    end

    local heights = {
        tarutaru = { '2ft10/86cm', '3ft0/91cm', '3ft2/97cm' },
        mithra = { '5ft4/163cm', '5ft7/170cm', '5ft10/178cm' },
        galka = { '7ft0/213cm', '7ft5/226cm', '7ft10/239cm' },
        humeFemale = { '5ft2/157cm', '5ft5/165cm', '5ft8/173cm' },
        humeMale = { '5ft7/170cm', '5ft10/178cm', '6ft1/185cm' },
        elvaanFemale = { '6ft1/185cm', '6ft5/196cm', '6ft9/206cm' },
        elvaanMale = { '6ft6/198cm', '6ft10/208cm', '7ft2/218cm' },
    };

    if (familyKey == 'hume') then
        return 'female=' .. heights.humeFemale[sizeIndex] .. '/male=' .. heights.humeMale[sizeIndex];
    elseif (familyKey == 'elvaan') then
        return 'female=' .. heights.elvaanFemale[sizeIndex] .. '/male=' .. heights.elvaanMale[sizeIndex];
    elseif (heights[familyKey] ~= nil) then
        return heights[familyKey][sizeIndex];
    end

    return 'unknown';
end

local function GetRaceInfoFromId(raceId)
    raceId = tonumber(raceId);

    local races = {
        [1] = { name = 'Hume', sex = 'Male' },
        [2] = { name = 'Hume', sex = 'Female' },
        [3] = { name = 'Elvaan', sex = 'Male' },
        [4] = { name = 'Elvaan', sex = 'Female' },
        [5] = { name = 'Tarutaru', sex = 'Male' },
        [6] = { name = 'Tarutaru', sex = 'Female' },
        [7] = { name = 'Mithra', sex = 'Female' },
        [8] = { name = 'Galka', sex = 'Male' },
        [29] = { name = 'Mithra Child', sex = 'Female' },
        [30] = { name = 'Elvaan/Hume Child', sex = 'Female' },
        [31] = { name = 'Elvaan/Hume Child', sex = 'Male' },
    };

    return races[raceId];
end

local function ReadHeightProbeMethod(object, methodName, index)
    if (object == nil or object[methodName] == nil) then
        return nil;
    end

    return CommandSafeCall(nil, function()
        return object[methodName](object, index);
    end);
end

local function BuildHeightProbeRaceReads(entityManager, entity, targetIndex)
    local reads = {};
    local directKeys = { 'Race', 'RaceId', 'ModelRace', 'LookRace', 'ModelId', 'Model', 'Look', 'Face' };

    for _, key in ipairs(directKeys) do
        local value = entity ~= nil and entity[key] or nil;

        if (value ~= nil and type(value) ~= 'table' and type(value) ~= 'function') then
            reads[#reads + 1] = key .. '=' .. tostring(value);
        end
    end

    local entityMethods = { 'GetRace', 'GetRaceId', 'GetModelRace', 'GetModelId', 'GetModel', 'GetLook', 'GetFace' };

    for _, methodName in ipairs(entityMethods) do
        local value = ReadHeightProbeMethod(entityManager, methodName, targetIndex);

        if (value ~= nil and type(value) ~= 'table' and type(value) ~= 'function') then
            reads[#reads + 1] = methodName .. '=' .. tostring(value);
        end
    end

    if (#reads == 0) then
        return 'none';
    end

    return table.concat(reads, ' ');
end

local function ReadHeightProbeRaceId(entityManager, entity, targetIndex)
    local directKeys = { 'Race', 'RaceId', 'ModelRace', 'LookRace' };

    for _, key in ipairs(directKeys) do
        local value = tonumber(entity ~= nil and entity[key] or nil);

        if (value ~= nil and GetRaceInfoFromId(value) ~= nil) then
            return value, key;
        end
    end

    local entityMethods = { 'GetRace', 'GetRaceId', 'GetModelRace' };

    for _, methodName in ipairs(entityMethods) do
        local value = tonumber(ReadHeightProbeMethod(entityManager, methodName, targetIndex));

        if (value ~= nil and GetRaceInfoFromId(value) ~= nil) then
            return value, methodName;
        end
    end

    return nil, nil;
end

local function GetPcHeightModelIdentity(modelKey, family)
    modelKey = tonumber(modelKey);
    family = tostring(family or '');

    local known = {
        [0xDA01] = { race = 'Tarutaru', sex = 'Female' },
    };

    if (modelKey ~= nil and known[modelKey] ~= nil and known[modelKey].race == family) then
        return known[modelKey].race, known[modelKey].sex, 'known-model';
    end

    if (family == 'Mithra') then
        return 'Mithra', 'Female', 'family-default';
    end

    return family ~= '' and family or 'unknown', 'unknown', 'family';
end

function LibraPlatesHandleHeightProbe(selector)
    local requested = tostring(selector or ''):gsub('^%s+', ''):gsub('%s+$', '');
    local requestedLower = requested:lower();
    local showRaw = requestedLower == 'raw';
    if (showRaw == true) then
        requested = '';
        requestedLower = '';
    end
    local entityManager = entities.GetEntityManager ~= nil and entities.GetEntityManager() or nil;
    local targetIndex = nil;
    local source = 'target';

    if (requestedLower == 'self') then
        local selfEntity = entities.GetSelf();
        targetIndex = tonumber(selfEntity ~= nil and selfEntity.index) or 0;
        source = 'self';
    elseif (tonumber(requested) ~= nil) then
        targetIndex = tonumber(requested);
        source = 'index';
    elseif (requested ~= '') then
        local wantedName = requestedLower;

        for index = 0, 2303 do
            local ent = GetEntity(index);

            if (
                tonumber(ent ~= nil and ent.Type or nil) == 0 and
                tostring(ent.Name or ''):lower() == wantedName
            ) then
                targetIndex = index;
                source = 'name';
                break;
            end
        end
    else
        targetIndex = targeting.GetCurrentTargetIndex() or targeting.GetCurrentSubTargetIndex();
    end

    local entity = targetIndex ~= nil and GetEntity(targetIndex) or nil;

    if (targetIndex == nil or entity == nil or tostring(entity.Name or '') == '' or tonumber(entity.Type or -1) ~= 0) then
        local selfEntity = entities.GetSelf();
        targetIndex = tonumber(selfEntity ~= nil and selfEntity.index) or 0;
        entity = targetIndex > 0 and GetEntity(targetIndex) or nil;
        source = 'self';
    end

    if (targetIndex == nil or targetIndex == 0 or entity == nil) then
        log.Warn('Height probe failed: target a PC, use /lp heightprobe self, /lp heightprobe <index>, or /lp heightprobe <name>.');
        return;
    end

    local modelDebug, modelErr = worldMarkerProbe.GetVisibilityDebug(targetIndex, entities.GetEntityManager, entities.GetBone);

    if (modelDebug == nil) then
        log.Warn('Height probe failed: ' .. tostring(modelErr) .. ' target=' .. tostring(targetIndex));
        return;
    end

    local actorInts = ParseDebugList(modelDebug.actorInts);
    local actorFloats = ParseDebugList(modelDebug.actorScalars);
    local modelKey = tonumber(actorInts['20']);
    local sizeScale = tonumber(actorFloats['6A0']);
    local raceGuess = GetPcRaceGuess(modelKey);
    local family = GetPcBodyGuess(modelDebug);
    local raceId, raceIdSource = ReadHeightProbeRaceId(entityManager, entity, targetIndex);
    local raceInfo = GetRaceInfoFromId(raceId);
    local displayRace, displaySex, identitySource = nil, nil, nil;

    if (raceInfo ~= nil) then
        displayRace = raceInfo.name;
        displaySex = raceInfo.sex == 'Male' and 'Male' or raceInfo.sex == 'Female' and 'Female' or raceInfo.sex;
        identitySource = 'race-id:' .. tostring(raceIdSource);
    else
        displayRace, displaySex, identitySource = GetPcHeightModelIdentity(modelKey, family);
    end

    local familyKey = GetPcHeightFamilyKey(displayRace) or GetPcHeightFamilyKey(family);
    local sizeBucket = GetPcHeightSizeBucket(sizeScale, familyKey);
    local raceReads = BuildHeightProbeRaceReads(entityManager, entity, targetIndex);
    local settings = targeting.GetSettings();

    local adjustments = type(settings.pcRacePlateAdjustments) == 'table' and settings.pcRacePlateAdjustments or {};
    local enabled = adjustments.enabled ~= false;
    local baselineY = GetPcHeightBaselineY(familyKey, displaySex, sizeBucket);
    local userY, bucketKey = GetPcHeightAdjustmentY(adjustments, familyKey, displaySex, sizeBucket);
    local finalY = enabled == true and (baselineY + userY) or 0;
    local bucket = tostring(displayRace or family or 'unknown') .. ' ' .. tostring(displaySex or 'unknown') .. ' ' .. tostring(sizeBucket);
    local finalWorldOffset = finalY * 0.01;

    log.Info(
        'Height probe: ' .. tostring(entity.Name or '') ..
        ' [' .. tostring(targetIndex) .. ', ' .. source .. ']' ..
        ' -> ' .. bucket ..
        ' (ref ' .. GetPcHeightReferenceText(familyKey, sizeBucket) .. ')' ..
        ' model=0x' .. string.format('%X', tonumber(modelKey) or 0) ..
        ' id=' .. tostring(identitySource)
    );

    log.Info(
        'Height adjustment: feature ' .. (enabled == true and 'on' or 'off') ..
        ', bucket ' .. tostring(bucketKey) ..
        ', hidden baseline ' .. tostring(baselineY) ..
        ', hidden bucket adjustment ' .. tostring(userY) ..
        ', applied ' .. tostring(finalY) ..
        ' (' .. string.format('%.2f', finalWorldOffset) .. ' world Y)' ..
        ', idle total ' .. string.format('%.2f', 0.05 + finalWorldOffset)
    );

    log.Info(
        'Height model: scale ' .. tostring(sizeScale) ..
        ', bones ' .. tostring(modelDebug.boneCount) ..
        ', zSpan ' .. tostring(modelDebug.boneSpanZ) ..
        ', ySpan ' .. tostring(modelDebug.boneSpanY) ..
        ', race reads ' .. raceReads ..
        '. Use /lp heightprobe raw for raw actor data.'
    );

    if (showRaw == true) then
        log.Info(
            'Height raw actorInts=' .. tostring(modelDebug.actorInts) ..
            ' actorScalars=' .. tostring(modelDebug.actorScalars)
        );
    end
end

local function NormalizePcHeightFamily(value)
    value = tostring(value or ''):lower();

    if (value == 'human' or value == 'hume') then
        return 'hume', 'Human / Hume';
    elseif (value == 'taru' or value == 'tarutaru') then
        return 'tarutaru', 'Tarutaru';
    elseif (value == 'mithra' or value == 'cat') then
        return 'mithra', 'Mithra';
    elseif (value == 'elvaan' or value == 'elf') then
        return 'elvaan', 'Elvaan';
    elseif (value == 'galka') then
        return 'galka', 'Galka';
    end

    return nil, nil;
end

local function NormalizePcHeightSex(value)
    value = tostring(value or ''):lower();

    if (value == 'm' or value == 'male') then
        return 'male', 'Male';
    elseif (value == 'f' or value == 'female') then
        return 'female', 'Female';
    end

    return nil, nil;
end

local function NormalizePcHeightSize(value)
    value = tostring(value or ''):lower();

    if (value == 's' or value == 'small') then
        return 'small', 'S';
    elseif (value == 'm' or value == 'medium' or value == 'med') then
        return 'medium', 'M';
    elseif (value == 'l' or value == 'large') then
        return 'large', 'L';
    end

    return nil, nil;
end

local function GetPcHeightBucketKeys()
    return {
        'tarutaru_male_small', 'tarutaru_male_medium', 'tarutaru_male_large',
        'tarutaru_female_small', 'tarutaru_female_medium', 'tarutaru_female_large',
        'hume_male_small', 'hume_male_medium', 'hume_male_large',
        'hume_female_small', 'hume_female_medium', 'hume_female_large',
        'mithra_female_small', 'mithra_female_medium', 'mithra_female_large',
        'elvaan_male_small', 'elvaan_male_medium', 'elvaan_male_large',
        'elvaan_female_small', 'elvaan_female_medium', 'elvaan_female_large',
        'galka_male_small', 'galka_male_medium', 'galka_male_large',
    };
end

local function EnsurePcHeightBuckets(settings)
    if (type(settings.pcRacePlateAdjustments.buckets) ~= 'table') then
        settings.pcRacePlateAdjustments.buckets = {};
    end

    local baselineVersion = tonumber(settings.pcRacePlateAdjustments.baselineVersion) or 0;
    for _, key in ipairs(GetPcHeightBucketKeys()) do
        if (type(settings.pcRacePlateAdjustments.buckets[key]) ~= 'table') then
            settings.pcRacePlateAdjustments.buckets[key] = { y = 0 };
        elseif (settings.pcRacePlateAdjustments.buckets[key].y == nil) then
            settings.pcRacePlateAdjustments.buckets[key].y = 0;
        end

        if (baselineVersion < 3) then
            settings.pcRacePlateAdjustments.buckets[key].y = 0;
        else
            settings.pcRacePlateAdjustments.buckets[key].y = math.max(-100, math.min(100, math.floor((tonumber(settings.pcRacePlateAdjustments.buckets[key].y) or 0) + 0.5)));
        end
    end
end

local function IsPcHeightBucketKey(value)
    value = tostring(value or ''):lower();

    for _, key in ipairs(GetPcHeightBucketKeys()) do
        if (value == key) then
            return true;
        end
    end

    return false;
end

local PcHeightCommand = {
    NormalizeFamily = NormalizePcHeightFamily,
    NormalizeSex = NormalizePcHeightSex,
    NormalizeSize = NormalizePcHeightSize,
    GetBucketKey = GetPcHeightBucketKey,
    GetBucketKeys = GetPcHeightBucketKeys,
    IsBucketKey = IsPcHeightBucketKey,
};

EnsurePcHeightSettings = function(settings)
    if (type(settings.pcRacePlateAdjustments) ~= 'table') then
        settings.pcRacePlateAdjustments = {};
    end

    if (settings.pcRacePlateAdjustments.enabled == nil) then
        settings.pcRacePlateAdjustments.enabled = true;
    end
    local baselines = {
        tarutaru = 82,
        mithra = 77,
        hume = 60,
        elvaan = 55,
        galka = 67,
    };

    local defaults = {
        tarutaru = { y = 0, size = 0 },
        mithra = { y = 0, size = 0 },
        hume = { y = 0, size = 0 },
        elvaan = { y = 0, size = 0 },
        galka = { y = 0, size = 0 },
    };

    for key, value in pairs(defaults) do
        if (type(settings.pcRacePlateAdjustments[key]) ~= 'table') then
            settings.pcRacePlateAdjustments[key] = {};
        end

        if (settings.pcRacePlateAdjustments[key].y == nil) then settings.pcRacePlateAdjustments[key].y = value.y; end
        if (settings.pcRacePlateAdjustments[key].size == nil) then settings.pcRacePlateAdjustments[key].size = value.size; end

        if ((tonumber(settings.pcRacePlateAdjustments.baselineVersion) or 0) < 2) then
            local yValue = tonumber(settings.pcRacePlateAdjustments[key].y) or 0;
            local baseline = baselines[key] or 0;
            if (math.abs(yValue - baseline) <= 1) then
                yValue = 0;
            elseif (math.abs(yValue) > 50 and baseline > 0) then
                yValue = yValue - baseline;
            end

            settings.pcRacePlateAdjustments[key].y = math.max(-100, math.min(100, math.floor(yValue + 0.5)));
        end
    end

    EnsurePcHeightBuckets(settings);
    settings.pcRacePlateAdjustments.baselineVersion = 3;
end

local function ApplyPcHeightDefaults(settings)
    EnsurePcHeightSettings(settings);

    local defaults = {
        tarutaru = { y = 0, size = 0 },
        mithra = { y = 0, size = 0 },
        hume = { y = 0, size = 0 },
        elvaan = { y = 0, size = 0 },
        galka = { y = 0, size = 0 },
    };

    for key, value in pairs(defaults) do
        settings.pcRacePlateAdjustments[key].y = value.y;
        settings.pcRacePlateAdjustments[key].size = value.size;
    end
    EnsurePcHeightBuckets(settings);
    for _, key in ipairs(GetPcHeightBucketKeys()) do
        settings.pcRacePlateAdjustments.buckets[key].y = 0;
    end
    settings.pcRacePlateAdjustments.baselineVersion = 3;
end

local function AddChangedField(parts, label, a, b)
    if (a == nil and b == nil) then
        return;
    end

    if (tostring(a) == tostring(b)) then
        return;
    end

    parts[#parts + 1] = label .. ':' .. FormatDebugNumber(a) .. '>' .. FormatDebugNumber(b);
end

local function BuildListDiff(prefix, aText, bText)
    local a = ParseDebugList(aText);
    local b = ParseDebugList(bText);
    local keys = {};
    local seen = {};

    for key, _ in pairs(a) do
        if (seen[key] ~= true) then
            keys[#keys + 1] = key;
            seen[key] = true;
        end
    end

    for key, _ in pairs(b) do
        if (seen[key] ~= true) then
            keys[#keys + 1] = key;
            seen[key] = true;
        end
    end

    table.sort(keys, function(left, right)
        local leftNumber = tonumber(left, 16);
        local rightNumber = tonumber(right, 16);

        if (leftNumber ~= nil and rightNumber ~= nil) then
            return leftNumber < rightNumber;
        end

        return tostring(left) < tostring(right);
    end);

    local parts = {};

    for _, key in ipairs(keys) do
        AddChangedField(parts, prefix .. key, a[key], b[key]);
    end

    return parts;
end

local function BuildVisibilityDiff(a, b)
    local parts = {};

    for _, field in ipairs({
        'status', 'hpPercent', 'type', 'spawnFlags', 'renderFlags0', 'renderFlags1',
        'boneCount', 'boneSpanZ', 'boneSpanY',
        'objectPointer',
    }) do
        AddChangedField(parts, field, a[field], b[field]);
    end

    for _, boneName in ipairs({ 'bone2', 'bone12' }) do
        local boneA = a[boneName] or {};
        local boneB = b[boneName] or {};
        local relZA = (boneA.worldZ ~= nil and a.baseZ ~= nil) and (boneA.worldZ - a.baseZ) or nil;
        local relZB = (boneB.worldZ ~= nil and b.baseZ ~= nil) and (boneB.worldZ - b.baseZ) or nil;

        AddChangedField(parts, boneName .. '.relZ', relZA, relZB);
    end

    for _, value in ipairs(BuildListDiff('af.', a.actorScalars, b.actorScalars)) do
        parts[#parts + 1] = value;
    end

    for _, value in ipairs(BuildListDiff('ai.', a.actorInts, b.actorInts)) do
        parts[#parts + 1] = value;
    end

    for _, value in ipairs(BuildListDiff('ab.', a.actorBytes, b.actorBytes)) do
        parts[#parts + 1] = value;
    end

    for _, value in ipairs(BuildListDiff('axb.', a.actorExtendedBytes, b.actorExtendedBytes)) do
        parts[#parts + 1] = value;
    end

    for _, value in ipairs(BuildListDiff('of.', a.objectScalars, b.objectScalars)) do
        parts[#parts + 1] = value;
    end

    for _, value in ipairs(BuildListDiff('oi.', a.objectInts, b.objectInts)) do
        parts[#parts + 1] = value;
    end

    for _, value in ipairs(BuildListDiff('ob.', a.objectBytes, b.objectBytes)) do
        parts[#parts + 1] = value;
    end

    return parts;
end

local function ReadTrustProbeStatusIds(memberPtr)
    local ids = {};
    local empty = false;

    if (memberPtr == nil or memberPtr == 0) then
        return ids;
    end

    for buffIndex = 0, 31 do
        if (empty == true) then
            break;
        end

        local highBits = CommandSafeCall(0, function()
            return ashita.memory.read_uint8(memberPtr + 8 + math.floor(buffIndex / 4));
        end);
        local shift = math.fmod(buffIndex, 4) * 2;
        highBits = bit.lshift(bit.band(bit.rshift(highBits, shift), 0x03), 8);

        local lowBits = CommandSafeCall(0, function()
            return ashita.memory.read_uint8(memberPtr + 16 + buffIndex);
        end);
        local statusId = highBits + lowBits;

        if (statusId == 255) then
            empty = true;
        elseif (statusId > 0) then
            ids[#ids + 1] = tostring(statusId);
        end
    end

    return ids;
end

local function GetTrustProbePartyStatusPointer()
    local pointerAddress = CommandSafeCall(0, function()
        return AshitaCore:GetPointerManager():Get('party.statusicons');
    end);

    pointerAddress = tonumber(pointerAddress) or 0;

    if (pointerAddress == 0) then
        return 0;
    end

    return tonumber(CommandSafeCall(0, function()
        return ashita.memory.read_uint32(pointerAddress);
    end)) or 0;
end

local function BuildTrustProbeMembers(party, entityManager)
    local members = {};

    for slot = 0, 17 do
        local active = CommandSafeCall(0, function() return party:GetMemberIsActive(slot); end);
        local targetIndex = CommandSafeCall(0, function() return party:GetMemberTargetIndex(slot); end);
        local serverId = CommandSafeCall(0, function() return party:GetMemberServerId(slot); end);
        local memberName = CommandSafeCall('', function() return party:GetMemberName(slot); end);
        local entityName = '';
        local entityStatus = nil;

        targetIndex = tonumber(targetIndex) or 0;
        serverId = tonumber(serverId) or 0;

        if (entityManager ~= nil and targetIndex > 0) then
            entityName = CommandSafeCall('', function() return entityManager:GetName(targetIndex); end);
            entityStatus = CommandSafeCall(nil, function() return entityManager:GetStatus(targetIndex); end);
        end

        if (tonumber(active) == 1 or targetIndex > 0 or serverId > 0) then
            members[#members + 1] = {
                slot = slot,
                active = active,
                targetIndex = targetIndex,
                serverId = serverId,
                memberName = memberName,
                entityName = entityName,
                entityStatus = entityStatus,
            };
        end
    end

    return members;
end

local function LogTrustBuffProbe(scanMode)
    local party = CommandSafeCall(nil, function()
        return AshitaCore:GetMemoryManager():GetParty();
    end);
    local entityManager = CommandSafeCall(nil, function()
        return AshitaCore:GetMemoryManager():GetEntity();
    end);
    local statusPointer = GetTrustProbePartyStatusPointer();

    log.Info('Trust buff probe statusPtr=0x' .. string.format('%X', tonumber(statusPointer) or 0));

    if (party == nil) then
        log.Warn('Trust buff probe failed: party manager unavailable.');
        return;
    end

    local members = BuildTrustProbeMembers(party, entityManager);

    if (scanMode == true and statusPointer ~= 0) then
        local wanted = {};

        for _, member in ipairs(members) do
            if ((tonumber(member.serverId) or 0) > 0) then
                wanted[tonumber(member.serverId)] = member;
            end
        end

        local found = 0;
        for offset = 0, 0x900, 4 do
            local value = CommandSafeCall(0, function()
                return ashita.memory.read_uint32(statusPointer + offset);
            end);
            local member = wanted[tonumber(value) or 0];

            if (member ~= nil) then
                found = found + 1;
                local rowPtr = statusPointer + offset;
                local ids = ReadTrustProbeStatusIds(rowPtr);

                log.Info(
                    'Trust buff scan match slot=' .. tostring(member.slot) ..
                    ' name=' .. tostring(member.memberName) ..
                    ' server=' .. tostring(member.serverId) ..
                    ' offset=0x' .. string.format('%X', offset) ..
                    ' rowPtr=0x' .. string.format('%X', rowPtr) ..
                    ' ids=' .. (#ids > 0 and table.concat(ids, '/') or 'none')
                );
            end
        end

        if (found == 0) then
            log.Info('Trust buff scan found no active party/trust server ids near party.statusicons.');
        end

        return;
    end

    for _, member in ipairs(members) do
        local memberPtr = (statusPointer ~= 0) and (statusPointer + (0x30 * member.slot)) or 0;
        local rawServerId = CommandSafeCall(0, function()
            return ashita.memory.read_uint32(memberPtr);
        end);
        local ids = {};

        if ((tonumber(rawServerId) or 0) == (tonumber(member.serverId) or -1)) then
            ids = ReadTrustProbeStatusIds(memberPtr);
        end

        log.Info(
            'Trust buff probe slot=' .. tostring(member.slot) ..
            ' active=' .. tostring(member.active) ..
            ' partyName=' .. tostring(member.memberName) ..
            ' entityName=' .. tostring(member.entityName) ..
            ' index=' .. tostring(member.targetIndex) ..
            ' server=' .. tostring(member.serverId) ..
            ' rawServer=' .. tostring(rawServerId) ..
            ' status=' .. tostring(member.entityStatus) ..
            ' ids=' .. (#ids > 0 and table.concat(ids, '/') or 'none')
        );
    end
end

local function FindAlTaieuFishIndex()
    local zoneId = nil;

    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    if (tonumber(zoneId) ~= 33) then
        return nil;
    end

    local entityManager = AshitaCore:GetMemoryManager():GetEntity();
    local bestIndex = nil;
    local bestDistance = nil;

    if (entityManager == nil) then
        return nil;
    end

    for index = 0, 2303 do
        local ent = GetEntity(index);
        local name = tostring(ent ~= nil and ent.Name or ''):gsub('\170', ''):lower();

        if (
            (name == "ul'hpemde" or name == "ul'phuabo") and
            ent.HPPercent ~= nil and
            ent.HPPercent > 0
        ) then
            local distance = tonumber(ent.Distance);

            if (bestIndex == nil or (distance ~= nil and (bestDistance == nil or distance < bestDistance))) then
                bestIndex = index;
                bestDistance = distance;
            end
        end
    end

    return bestIndex;
end

local function ResolveVisDebugTarget(args, firstIndex)
    local value = tostring(args[firstIndex] or ''):lower();

    if (value == 'pet') then
        return entities.GetOwnPetTargetIndex();
    end

    if (value == 'fish' or value == 'sea') then
        return FindAlTaieuFishIndex();
    end

    if (tonumber(args[firstIndex]) ~= nil) then
        return tonumber(args[firstIndex]);
    end

    return targeting.GetCurrentTargetIndex() or entities.GetOwnPetTargetIndex();
end

local function GetAddonRoot()
    local ok, path = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and path ~= nil) then
        return tostring(path);
    end

    return '.\\';
end

local function GetCurrentZoneName()
    local zoneId = nil;

    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    if (zoneId ~= nil and AshitaCore ~= nil and AshitaCore.GetResourceManager ~= nil) then
        local ok, zoneName = pcall(function()
            return AshitaCore:GetResourceManager():GetString('zones.names', zoneId);
        end);

        if (ok == true and zoneName ~= nil and tostring(zoneName) ~= '' and tostring(zoneName) ~= 'nil') then
            return tostring(zoneName);
        end
    end

    if (zoneId ~= nil) then
        return 'Zone ' .. tostring(zoneId);
    end

    return 'Unknown Zone';
end

local function GetCurrentTargetName()
    local targetIndex = targeting.GetCurrentTargetIndex() or targeting.GetCurrentSubTargetIndex();

    if (targetIndex == nil or targetIndex == 0) then
        return nil;
    end

    local ok, name = pcall(function()
        return AshitaCore:GetMemoryManager():GetEntity():GetName(targetIndex);
    end);

    if (ok ~= true or name == nil or tostring(name) == '' or tostring(name) == 'nil') then
        return nil;
    end

    return tostring(name);
end

local function AppendMissingNpc()
    local name = GetCurrentTargetName();

    if (name == nil) then
        log.Warn('NPC capture failed: target an NPC first.');
        return;
    end

    local zoneName = GetCurrentZoneName();
    local line = name .. ' | ' .. zoneName;
    local path = npcCapturePath;
    local file = io.open(path, 'a');

    if (file == nil) then
        log.Warn('NPC capture failed: could not open ' .. path);
        return;
    end

    file:write(line);
    file:write('\n');
    file:close();

    log.Info('NPC capture added: ' .. line);
end

local function FormatHex(value)
    return '0x' .. string.format('%X', tonumber(value or 0) or 0);
end

local function BuildRenderFlagText(debug)
    local parts = {};
    local flags = debug ~= nil and debug.renderFlags or nil;

    for flagIndex = 0, 7 do
        local value = flags ~= nil and flags[flagIndex] or debug ~= nil and debug['renderFlags' .. tostring(flagIndex)] or 0;
        parts[#parts + 1] = 'render' .. tostring(flagIndex) .. '=' .. FormatHex(value);
    end

    return table.concat(parts, ' | ');
end

function LibraPlatesCapturePlateHideProbe()
    local targetIndex = targeting.GetCurrentTargetIndex() or targeting.GetCurrentSubTargetIndex();
    local debug = entities.GetEntityDebugInfo(targetIndex, targeting.GetSettings().enemyPlateRange);

    if (debug == nil) then
        log.Warn('Hide probe failed: no current target.');
        return;
    end

    local zoneId = CommandSafeCall(nil, function()
        return AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);
    local entityManager = CommandSafeCall(nil, function()
        return AshitaCore:GetMemoryManager():GetEntity();
    end);
    local cleanName = tostring(debug.name or ''):gsub('\170', '');
    local resolvedKind = nil;

    if debug.isMob ~= true then
        local rawKind = (tonumber(debug.type) == 2 or tonumber(debug.type) == 3) and 'Object' or 'NPC';
        resolvedKind = select(1, npcObjectInfo.ResolveKind(cleanName, rawKind));
    end

    local function SafeField(value)
        return tostring(value == nil and '' or value):gsub('[\r\n\t]', ' ');
    end

    local fields = {
        'time=' .. SafeField(os.date('%Y-%m-%d %H:%M:%S')),
        'zone_id=' .. SafeField(zoneId),
        'zone_name=' .. SafeField(GetCurrentZoneName()),
        'target_index=' .. SafeField(debug.index),
        'server_id=' .. SafeField(GetDebugServerId(entityManager, debug.index)),
        'name=' .. SafeField(cleanName),
        'raw_name=' .. SafeField(debug.name),
        'entity_type=' .. SafeField(debug.type),
        'status=' .. SafeField(debug.status),
        'hp_percent=' .. SafeField(debug.hpPercent),
        'distance=' .. SafeField(debug.distance),
        'spawn_flags=' .. FormatHex(debug.spawnFlags),
        'is_mob=' .. SafeField(debug.isMob),
        'is_party=' .. SafeField(debug.isParty),
        'visible=' .. SafeField(debug.visible),
        'visible_skeleton=' .. SafeField(debug.visibleWithSkeleton),
        'index_allowed=' .. SafeField(debug.indexAllowed),
        'status_allowed=' .. SafeField(debug.statusAllowed),
        'npc_scan_allowed=' .. SafeField(debug.npcScanAllowed),
        'tactical_npc_allowed=' .. SafeField(debug.tacticalNpcAllowed),
        'resolved_kind=' .. SafeField(resolvedKind),
        'layout=' .. SafeField(debug.layoutStateName),
    };

    for flagIndex = 0, 7 do
        fields[#fields + 1] = 'render' .. tostring(flagIndex) .. '=' .. FormatHex(debug.renderFlags ~= nil and debug.renderFlags[flagIndex] or 0);
    end

    local path = GetAddonRoot() .. 'plate_hide_probes.txt';
    local file = io.open(path, 'a');

    if (file == nil) then
        log.Warn('Hide probe failed: could not open plate_hide_probes.txt.');
        return;
    end

    file:write(table.concat(fields, '\t'));
    file:write('\n');
    file:close();

    log.Info('Hide probe saved: ' .. cleanName .. ' | ' .. GetCurrentZoneName() .. ' | server ' .. tostring(GetDebugServerId(entityManager, debug.index)) .. '.');
end

-- ============================================================
-- Command handler
-- ============================================================

function commands.Handle(e)
    local args = SplitCommand(e.command);
    local command = tostring(args[1] or ''):lower();

    if (command == '/help' or command == '/h') then
        engagedEnemies.MarkCallForHelp(targeting.GetCurrentTargetIndex());
        return;
    end

    if (command ~= '/libraplates' and command ~= '/lp') then
        return;
    end

    e.blocked = true;

    local subcommand = tostring(args[2] or 'status'):lower();

    if (subcommand == 'reload') then
        pcall(function()
            AshitaCore:GetChatManager():QueueCommand(1, '/addon reload LibraPlates');
        end);
        return;
    end

    if (subcommand == 'itemtrace' or subcommand == 'traceitem') then
        local itemFlickerTrace = require('core.item_flicker_trace');
        local action = tostring(args[3] or 'start'):lower();

        if (action == 'status') then
            log.Info(itemFlickerTrace.GetStatusText());
            return;
        end

        itemFlickerTrace.Start(tonumber(args[3]) or tonumber(args[4]) or 5);
        return;
    end

    if (subcommand == 'npc' or subcommand == 'npcadd') then
        AppendMissingNpc();
        return;
    end

    if (subcommand == 'questtest' or subcommand == 'questlogtest') then
        require('core.quest_log_test').Request();
        return;
    end

    if (subcommand == 'hideprobe') then
        LibraPlatesCapturePlateHideProbe();
        return;
    end

    if (subcommand == 'mountdebug') then
        if (tostring(args[3] or ''):lower() == 'scout') then
            mounts.StartPacketScout(args[4]);
            return;
        end

        log.Info(mounts.GetDebugStatusText(tostring(args[3] or ''):lower() == 'all'));
        return;
    end

    if (subcommand == 'campaigncapture') then
        local action = tostring(args[3] or 'on'):lower();
        local captureWarpMenu = require('core.warp_menu');

        if (action == 'off' or action == 'stop') then
            captureWarpMenu.StopCampaignCapture();
            return;
        end

        if (action == 'status') then
            log.Info('Campaign Arbiter packet capture command ready. Use /lp campaigncapture on [seconds], then select a native Campaign Arbiter destination.');
            return;
        end

        captureWarpMenu.StartCampaignCapture(tonumber(args[4]) or tonumber(args[3]) or 30);
        return;
    end

    if (subcommand == 'expcapture') then
        local action = tostring(args[3] or 'on'):lower();
        local captureWarpMenu = require('core.warp_menu');

        if (action == 'off' or action == 'stop') then
            captureWarpMenu.StopExpGuideCapture();
            return;
        end

        if (action == 'status') then
            log.Info('EXP Guide packet capture command ready. Use /lp expcapture on [seconds], then select a native EXP Guide destination.');
            return;
        end

        captureWarpMenu.StartExpGuideCapture(tonumber(args[4]) or tonumber(args[3]) or 30);
        return;
    end

    if (subcommand == 'mhcapture' or subcommand == 'moghousecapture') then
        local action = tostring(args[3] or 'on'):lower();
        local captureWarpMenu = require('core.warp_menu');

        if (action == 'off' or action == 'stop') then
            captureWarpMenu.StopMogHouseExitCapture();
            return;
        end

        if (action == 'status') then
            log.Info('Mog House packet capture command ready. Use /lp mhcapture on [seconds], then select a native Mog House enter or exit option.');
            return;
        end

        captureWarpMenu.StartMogHouseExitCapture(tonumber(args[4]) or tonumber(args[3]) or 30);
        return;
    end

    if (subcommand == 'fmexit' or subcommand == 'fieldmanualexit') then
        local fieldManualSupport = require('core.field_manual_support');
        fieldManualSupport.EmergencyExit();
        return;
    end

    if (subcommand == 'nativecolors' or subcommand == 'nativecolour' or subcommand == 'nativecolours') then
        local value = tostring(args[3] or ''):lower();
        local settings = targeting.GetSettings();

        if (value == 'on' or value == 'true' or value == '1') then
            settings.overwriteNativeNameColors = true;
        elseif (value == 'off' or value == 'false' or value == '0') then
            settings.overwriteNativeNameColors = false;
        else
            settings.overwriteNativeNameColors = settings.overwriteNativeNameColors == false;
        end

        state.Save();
        log.Info('Overwrite native name colors=' .. tostring(settings.overwriteNativeNameColors ~= false));
        return;
    end

    if (subcommand == 'anon' or subcommand == 'anonymous') then
        local value = tostring(args[3] or ''):lower();
        local anonStatus = require('core.anon_status');

        if (value == 'target' or value == '<t>') then
            local targetIndex = targeting.GetCurrentTargetIndex() or targeting.GetCurrentSubTargetIndex();
            local entityManager = entities.GetEntityManager ~= nil and entities.GetEntityManager() or nil;
            local serverId = GetDebugServerId(entityManager, targetIndex);
            local ent = GetEntity(targetIndex);
            local targetValue = tostring(args[4] or 'on'):lower();
            local enabled = targetValue ~= 'off' and targetValue ~= 'false' and targetValue ~= '0';

            if (anonStatus.SetServerAnonymous(serverId, enabled) == true) then
                log.Info('Tracked anon ' .. tostring(enabled) .. ' for ' .. tostring(ent ~= nil and ent.Name or targetIndex) .. ' server=' .. tostring(serverId));
            else
                log.Warn('Anon target failed: no valid target/server id.');
            end
            return;
        end

        if (value ~= 'on' and value ~= 'off' and value ~= 'true' and value ~= 'false' and value ~= '1' and value ~= '0' and value ~= 'status' and value ~= '') then
            local wantedName = tostring(args[3] or ''):lower();
            local targetValue = tostring(args[4] or 'on'):lower();
            local enabled = targetValue ~= 'off' and targetValue ~= 'false' and targetValue ~= '0';
            local entityManager = entities.GetEntityManager ~= nil and entities.GetEntityManager() or nil;

            for index = 0, 2303 do
                local ent = GetEntity(index);
                if (tonumber(ent ~= nil and ent.Type or nil) == 0 and tostring(ent.Name or ''):lower() == wantedName) then
                    local serverId = GetDebugServerId(entityManager, index);
                    if (anonStatus.SetServerAnonymous(serverId, enabled) == true) then
                        log.Info('Tracked anon ' .. tostring(enabled) .. ' for ' .. tostring(ent.Name) .. ' server=' .. tostring(serverId));
                        return;
                    end
                end
            end

            log.Warn('Anon name failed: nearby PC not found: ' .. tostring(args[3]));
            return;
        end

        anonStatus.SetSelfAnonymous(false);

        local selfEntity = entities.GetSelf();
        local selfIndex = tonumber(selfEntity ~= nil and selfEntity.index) or 0;
        local liveAnon = false;

        if (selfIndex > 0) then
            local playerIndicators = require('core.player_indicators');
            liveAnon = playerIndicators.HasAnonNameColor(selfIndex) == true;
        end

        log.Info('Self anon uses live render flags; manual self override cleared. live=' .. tostring(liveAnon));
        return;
    end

    if (subcommand == 'blist' or subcommand == 'blacklist') then
        local action = tostring(args[3] or 'status'):lower();
        local playerBlacklist = require('core.player_blacklist');

        if (action == 'add' or action == 'insert') then
            local name = tostring(args[4] or '');
            local reasonParts = {};

            for i = 5, #args do
                reasonParts[#reasonParts + 1] = tostring(args[i] or '');
            end

            local ok, err = playerBlacklist.AddName(name, table.concat(reasonParts, ' '), 'lp-command');

            if (ok == true) then
                pcall(function()
                    AshitaCore:GetChatManager():QueueCommand(1, '/blacklist add "' .. name:gsub('"', '') .. '"');
                end);
                log.Info('Added ' .. name .. ' to LibraPlates blacklist.');
            else
                log.Warn(tostring(err or 'Blacklist add failed.'));
            end
            return;
        end

        if (action == 'delete' or action == 'del' or action == 'remove' or action == 'rm') then
            local name = tostring(args[4] or '');

            if (playerBlacklist.RemoveName(name) == true) then
                pcall(function()
                    AshitaCore:GetChatManager():QueueCommand(1, '/blacklist delete "' .. name:gsub('"', '') .. '"');
                end);
                log.Info('Removed ' .. name .. ' from LibraPlates blacklist.');
            else
                log.Warn('Blacklist remove failed; not listed locally: ' .. name);
            end
            return;
        end

        local rows = playerBlacklist.List();
        log.Info('LibraPlates blacklist entries=' .. tostring(#rows) .. '. Usage: /lp blist add <name> | /lp blist remove <name>');
        for i = 1, math.min(#rows, 8) do
            local row = rows[i];
            log.Info(
                tostring(i) .. '. ' ..
                tostring(row.name or '') ..
                ' id=' .. tostring(row.serverId or 'pending') ..
                ' reason=' .. tostring(row.reason or '')
            );
        end
        return;
    end

    if (subcommand == 'bltest' or subcommand == 'blacklisttest') then
        local target = tostring(args[3] or '');

        if (target == '') then
            log.Warn('Usage: /lp bltest <player-name-or-index>');
            return;
        end

        local blacklistModelReplace = require('core.blacklist_model_replace');
        local result = blacklistModelReplace.DiagnosePlayerRefresh(target);

        for _, line in ipairs((result ~= nil and result.lines) or { 'Blacklist test failed.' }) do
            log.Info(line);
        end

        return;
    end

    if (subcommand == 'blwatch' or subcommand == 'blacklistwatch') then
        local target = tostring(args[3] or '');

        if (target == '') then
            log.Warn('Usage: /lp blwatch <player-name-or-server-id|clear>');
            return;
        end

        local blacklistModelReplace = require('core.blacklist_model_replace');
        local ok, result = blacklistModelReplace.SetBlacklistWatch(target);

        if (ok == true) then
            log.Info('Blacklist watch: ' .. tostring(result));
        else
            log.Warn('Blacklist watch failed: ' .. tostring(result));
        end

        return;
    end

    if (subcommand == 'blrecover' or subcommand == 'blacklistrecover') then
        local target = tostring(args[3] or '');

        if (target == '') then
            log.Warn('Usage: /lp blrecover <player-name-or-server-id>');
            return;
        end

        local blacklistModelReplace = require('core.blacklist_model_replace');
        local result = blacklistModelReplace.RecoverBlacklistedPlayer(target);

        for _, line in ipairs((result ~= nil and result.lines) or { 'Blacklist recover failed.' }) do
            log.Info(line);
        end

        return;
    end

    if (subcommand == 'bllookwatch' or subcommand == 'blacklistlookwatch') then
        local target = tostring(args[3] or '');

        if (target == '') then
            log.Warn('Usage: /lp bllookwatch <player-name-or-server-id|clear>');
            return;
        end

        local blacklistModelReplace = require('core.blacklist_model_replace');
        local ok, result = blacklistModelReplace.SetBlacklistLookWatch(target);

        if (ok == true) then
            log.Info('Blacklist look watch: ' .. tostring(result));
        else
            log.Warn('Blacklist look watch failed: ' .. tostring(result));
        end

        return;
    end

    if (subcommand == 'blmodel' or subcommand == 'blacklistmodel') then
        local action = tostring(args[3] or 'status'):lower();
        local blacklistModelReplace = require('core.blacklist_model_replace');
        local playerBlacklist = require('core.player_blacklist');
        local settings = playerBlacklist.GetModelReplaceSettings();

        if (action == 'on' or action == 'enable') then
            settings.modelReplaceEnabled = true;
            state.Save();
            log.Info('Blacklist model replacement enabled.');
            return;
        end

        if (action == 'off' or action == 'disable') then
            settings.modelReplaceEnabled = false;
            state.Save();
            log.Info('Blacklist model replacement disabled.');
            return;
        end

        if (action == 'debug') then
            local value = tostring(args[4] or ''):lower();
            blacklistModelReplace.SetDebugEnabled(value == 'on' or value == 'true' or value == '1');
            log.Info(blacklistModelReplace.GetDebugStatusText());
            return;
        end

        if (action == 'probe') then
            local value = tostring(args[4] or 'status'):lower();

            if (value == 'on' or value == 'true' or value == '1') then
                blacklistModelReplace.SetFomorProbeEnabled(true);
            elseif (value == 'off' or value == 'false' or value == '0') then
                blacklistModelReplace.SetFomorProbeEnabled(false);
            elseif (value == 'target' or value == 't') then
                local targetIndex = targeting.GetCurrentTargetIndex() or targeting.GetCurrentSubTargetIndex();
                local ok, mode = blacklistModelReplace.SetFomorProbeTarget(targetIndex);

                if (ok == true and mode == 'cached') then
                    log.Info('Used cached Fomor probe for target index=' .. tostring(targetIndex) .. '.');
                elseif (ok == true) then
                    log.Info('Armed one-shot Fomor probe for target index=' .. tostring(targetIndex) .. '.');
                else
                    log.Warn('Fomor probe target failed: no current target.');
                end
                return;
            elseif (value == 'clear') then
                blacklistModelReplace.ClearCapturedFomorModels();
                log.Info('Cleared captured blacklist Fomor models.');
                return;
            else
                log.Info(blacklistModelReplace.GetDebugStatusText());
                return;
            end

            log.Info(blacklistModelReplace.GetDebugStatusText());
            return;
        end

        if (action == 'costume') then
            local value = tostring(args[4] or ''):lower();

            if (value == 'off' or value == 'clear' or value == '0') then
                blacklistModelReplace.SetCostumeModel(0);
                log.Info('Blacklist costume model disabled.');
            else
                log.Warn('Blacklist costume model is disabled after crash-risk tests. Use /lp blmodel watchcostume for packet watching only.');
            end
            return;
        end

        if (action == 'queuecostume' or action == 'seqcostume' or action == 'sequence') then
            log.Warn('Blacklist live costume sequence is disabled after crash-risk tests.');
            return;
        end

        if (action == 'watchcostume' or action == 'costumewatch' or action == 'watch') then
            local targetText = tostring(args[4] or ''):lower();
            local targetIndex = nil;
            local name = nil;

            if (targetText == '' or targetText == 'target' or targetText == 't') then
                targetIndex = targeting.GetCurrentTargetIndex() or targeting.GetCurrentSubTargetIndex();
            elseif (targetText == 'off' or targetText == 'clear') then
                blacklistModelReplace.ClearCostumeWatch();
                log.Info('Costume watch cleared.');
                return;
            elseif (tonumber(args[4]) ~= nil) then
                targetIndex = tonumber(args[4]);
            else
                name = args[4];
            end

            local ok, result = blacklistModelReplace.SetCostumeWatch(targetIndex or name);

            if (ok == true) then
                log.Info('Costume watch armed: ' .. tostring(result) .. '. Put a real costume on that character now.');
            else
                log.Warn('Costume watch failed: ' .. tostring(result));
            end
            return;
        end

        if (action == 'looktest' or action == 'dressuptest' or action == 'look') then
            log.Warn('Blacklist live look test is disabled after crash-risk tests.');
            return;
        end

        if (action == 'livecostume' or action == 'live') then
            log.Warn('Blacklist live costume writes are disabled after crash-risk tests.');
            return;
        end

        if (action == 'preserverace' or action == 'preserve') then
            local value = tostring(args[4] or ''):lower();
            settings.modelReplacePreserveRace = value ~= 'off' and value ~= 'false' and value ~= '0';
            state.Save();
            log.Info('Blacklist Fomor preserve race=' .. tostring(settings.modelReplacePreserveRace == true) .. '.');
            return;
        end

        if (action == 'race') then
            local ok, family, fixedModelId = blacklistModelReplace.SetReplacementRace(args[4]);

            if (ok == true) then
                log.Info(
                    'Blacklist forced Fomor family=' .. tostring(family or 'unknown') ..
                    ' race=' .. tostring(settings.modelReplaceRace) ..
                    ' fixedId=' .. tostring(fixedModelId or 0) ..
                    ' preserveRace=false.'
                );
            else
                log.Warn('Usage: /lp blmodel race <hume|elvaan|tarutaru|mithra|galka|1-8>');
            end
            return;
        end

        if (action == 'tryfixed' or action == 'runtimefixed') then
            local family = tostring(args[4] or '');
            local modelId = tostring(args[5] or '');
            local ok, result, value = blacklistModelReplace.SetRuntimeFixedFomorModel(family, modelId);

            if (ok == true) then
                log.Info(
                    'Runtime blacklist fixed Fomor override ' ..
                    tostring(result) ..
                    (tonumber(value) ~= nil and tonumber(value) > 0 and ('=' .. tostring(value)) or '') ..
                    '. This is not saved to profile.'
                );
            else
                log.Warn('Usage: /lp blmodel tryfixed <hume|hume_female|elvaan|tarutaru|mithra|galka|clear> <model-id>');
            end
            return;
        end

        if (action == 'step' or action == 'stepfixed') then
            local family = tostring(args[4] or '');
            local firstId = tostring(args[5] or '');
            local lastId = tostring(args[6] or '');
            local ok, result = blacklistModelReplace.StartRuntimeFixedStepper(family, firstId, lastId);

            if (ok == true) then
                log.Info('Runtime blacklist fixed Fomor ' .. tostring(result) .. '. Use /lp blmodel next.');
            else
                log.Warn('Usage: /lp blmodel step <hume_female|family> <first-id> <last-id>');
            end
            return;
        end

        if (action == 'next' or action == 'nextfixed') then
            local ok, result = blacklistModelReplace.NextRuntimeFixedStep();

            if (ok == true) then
                log.Info('Runtime blacklist fixed Fomor ' .. tostring(result) .. '. Range/reload target now.');
            else
                log.Warn('Runtime blacklist fixed Fomor step failed: ' .. tostring(result));
            end
            return;
        end

        if (action == 'fomor') then
            local value = tostring(args[4] or ''):lower();
            settings.modelReplaceUseFomor = value ~= 'off' and value ~= 'false' and value ~= '0';
            state.Save();
            log.Info('Blacklist Fomor packet replacement=' .. tostring(settings.modelReplaceUseFomor == true) .. '.');
            return;
        end

        if (action == 'fixed' or action == 'npccostume' or action == 'fixedcostume' or action == 'refresh' or action == 'clearrefresh') then
            log.Warn('Blacklist fixed NPC/costume refresh paths are disabled; packet-only Fomor replacement remains enabled.');
            return;
        end

        log.Info(
            'Blacklist model replacement enabled=' .. tostring(settings.modelReplaceEnabled == true) ..
            ' race=' .. tostring(settings.modelReplaceRace) ..
            ' hair=' .. tostring(settings.modelReplaceHair) ..
            ' preserveRace=' .. tostring(settings.modelReplacePreserveRace ~= false) ..
            ' fomor=' .. tostring(settings.modelReplaceUseFomor ~= false) ..
            ' clearGear=' .. tostring(settings.modelReplaceClearGear == true) ..
            ' | ' .. blacklistModelReplace.GetDebugStatusText()
        );
        return;
    end

    if (subcommand == 'stack' or subcommand == 'platestack' or subcommand == 'stacking') then
        local action = tostring(args[3] or 'status'):lower();
        local settings = targeting.GetSettings();

        if (action == 'on' or action == 'enable') then
            settings.plateStackingEnabled = true;
            state.Save();
        elseif (action == 'off' or action == 'disable') then
            settings.plateStackingEnabled = false;
            state.Save();
        elseif (action == 'pc' or action == 'players') then
            local value = tostring(args[4] or ''):lower();
            if (type(settings.plateStackingTypes) ~= 'table') then settings.plateStackingTypes = {}; end
            settings.plateStackingTypes.pc = value == 'on' or value == 'true' or value == '1';
            state.Save();
        elseif (action ~= 'status') then
            log.Warn('Usage: /lp stack on|off|status|pc on|pc off');
            return;
        end

        log.Info(
            'Plate stacking enabled=' .. tostring(settings.plateStackingEnabled ~= false) ..
            ' pc=' .. tostring(type(settings.plateStackingTypes) == 'table' and settings.plateStackingTypes.pc == true) ..
            ' enemy=' .. tostring(type(settings.plateStackingTypes) == 'table' and settings.plateStackingTypes.enemy == true) ..
            ' trust=' .. tostring(type(settings.plateStackingTypes) == 'table' and settings.plateStackingTypes.trust == true) ..
            ' padding=' .. tostring(settings.plateStackGap) ..
            ' effectivePadding=' .. tostring((tonumber(settings.plateStackGap) or 10) - 10) ..
            ' speed=' .. tostring(settings.plateStackTravelSpeed) ..
            ' maxWorldPlateCount=' .. tostring(settings.maxWorldPlateCount or 0)
        );
        return;
    end

    if (subcommand == 'clamp' or subcommand == 'tacticalclamp' or subcommand == 'screenclamp') then
        local action = tostring(args[3] or 'status'):lower();
        local settings = targeting.GetSettings();

        if (action == 'on' or action == 'enable') then
            settings.tacticalScreenClampEnabled = true;
            state.Save();
        elseif (action == 'off' or action == 'disable') then
            settings.tacticalScreenClampEnabled = false;
            state.Save();
        elseif (action ~= 'status') then
            log.Warn('Usage: /lp clamp on|off|status');
            return;
        end

        log.Info(
            'Keep tactical plates on screen=' .. tostring(settings.tacticalScreenClampEnabled == true) ..
            ' top=' .. tostring(settings.tacticalScreenClampTopPadding or 24) ..
            ' bottom=' .. tostring(settings.tacticalScreenClampBottomPadding or 24) ..
            ' left=' .. tostring(settings.tacticalScreenClampLeftPadding or 0) ..
            ' right=' .. tostring(settings.tacticalScreenClampRightPadding or 0)
        );
        return;
    end

    if (subcommand == 'platecap' or subcommand == 'worldcap') then
        local action = tostring(args[3] or 'status'):lower();
        local settings = targeting.GetSettings();
        local value = tonumber(args[3]);

        if (action == 'off' or action == 'unlimited' or action == 'none') then
            settings.maxWorldPlateCount = 0;
            state.Save();
        elseif (value ~= nil) then
            settings.maxWorldPlateCount = math.max(0, math.min(300, math.floor(value + 0.5)));
            state.Save();
        elseif (action ~= 'status') then
            log.Warn('Usage: /lp platecap 0|40|80|status');
            return;
        end

        log.Info('Max world plate count=' .. tostring(settings.maxWorldPlateCount or 0) .. ' (0 = unlimited).');
        return;
    end

    if (subcommand == 'world') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            state.SetWorldEnabled(true);
        elseif (value == 'off') then
            state.SetWorldEnabled(false);
        else
            state.SetWorldEnabled(not state.GetWorldEnabled());
        end

        log.Info('World plates enabled=' .. tostring(state.GetWorldEnabled()));
        return;
    end

    if (subcommand == 'worlddepth') then
        if (canvasDefaults.worldDepth == nil) then
            canvasDefaults.worldDepth = {};
        end

        canvasDefaults.worldDepth.enabled = false;
        log.Warn('World depth plate is disabled; the experimental beginscene path changes scene lighting.');
        return;
    end

    if (subcommand == 'bridge' or subcommand == 'worldmarker') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            worldMarkerProbe.SetEnabled(true);
            worldMarkerProbe.SetReplacePlates(true);
        elseif (value == 'off') then
            worldMarkerProbe.SetEnabled(false);
        elseif (value == 'status' or value == '') then
            log.Info(
                worldMarkerProbe.GetStatusText() ..
                ' target=' .. tostring(targeting.GetCurrentTargetIndex()) ..
                ' subtarget=' .. tostring(targeting.GetCurrentSubTargetIndex()) ..
                ' locked=' .. tostring(targeting.GetIsTargetLockedOn()) ..
                ' ' .. targeting.GetDebugStatus()
            );
            return;
        else
            worldMarkerProbe.SetEnabled(not worldMarkerProbe.GetEnabled());
            worldMarkerProbe.SetReplacePlates(true);
        end

        log.Info('World marker bridge enabled=' .. tostring(worldMarkerProbe.GetEnabled()));
        return;
    end

    if (subcommand == 'isolate' or subcommand == 'perfiso') then
        local name = tostring(args[3] or 'status'):lower();
        local value = tostring(args[4] or 'status'):lower();

        if (name == 'status' or name == '') then
            log.Info('Perf isolate disabled subsystems: ' .. modules.GetPerfIsolationStatus());
            return;
        end

        if (value == 'on' or value == 'disable' or value == 'disabled') then
            if (modules.SetPerfIsolation(name, true) ~= true) then
                log.Warn('Usage: /lp isolate targeting|native|mouse|overlays|self|enemy|pc|trust|pet|npc|plates|all on|off|status');
                return;
            end
        elseif (value == 'off' or value == 'enable' or value == 'enabled') then
            if (modules.SetPerfIsolation(name, false) ~= true) then
                log.Warn('Usage: /lp isolate targeting|native|mouse|overlays|self|enemy|pc|trust|pet|npc|plates|all on|off|status');
                return;
            end
        elseif (value == 'toggle' or value == '') then
            if (modules.SetPerfIsolation(name, modules.GetPerfIsolation(name) ~= true) ~= true) then
                log.Warn('Usage: /lp isolate targeting|native|mouse|overlays|self|enemy|pc|trust|pet|npc|plates|all on|off|status');
                return;
            end
        elseif (value ~= 'status') then
            log.Warn('Usage: /lp isolate targeting|native|mouse|overlays|self|enemy|pc|trust|pet|npc|plates|all on|off|status');
            return;
        end

        log.Info('Perf isolate disabled subsystems: ' .. modules.GetPerfIsolationStatus());
        return;
    end

    if (subcommand == 'clickdebug') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            worldMarkerProbe.SetClickDebug(true);
        elseif (value == 'off') then
            worldMarkerProbe.SetClickDebug(false);
        else
            worldMarkerProbe.SetClickDebug(not worldMarkerProbe.GetClickDebug());
        end

        log.Info('Click debug path enabled=' .. tostring(worldMarkerProbe.GetClickDebug()) .. ' visible=' .. tostring(worldMarkerProbe.GetClickBordersVisible()));
        return;
    end

    if (subcommand == 'canvasdebug' or subcommand == 'canvascenter') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            worldMarkerProbe.SetCanvasCenterDebug(true);
        elseif (value == 'off') then
            worldMarkerProbe.SetCanvasCenterDebug(false);
        else
            worldMarkerProbe.SetCanvasCenterDebug(not worldMarkerProbe.GetCanvasCenterDebug());
        end

        log.Info('Canvas center debug=' .. tostring(worldMarkerProbe.GetCanvasCenterDebug()));
        return;
    end

    if (subcommand == 'petpos' or subcommand == 'petposition') then
        local action = tostring(args[3] or 'status'):lower();
        local value = tonumber(args[4]);

        if (action == 'bone' and value ~= nil) then
            petPlate.SetAnchorBone(value);
        elseif ((action == 'offset' or action == 'offsety' or action == 'y') and value ~= nil) then
            petPlate.SetWorldOffsetY(value);
        elseif (action == 'reset') then
            petPlate.ResetPositionDebug();
        elseif (action ~= 'status' and action ~= '') then
            log.Warn('Usage: /lp petpos bone <0-32> | offset <number> | reset | status');
            return;
        end

        log.Info(petPlate.GetPositionDebugText());
        return;
    end

    if (subcommand == 'pettargeting' or subcommand == 'petclick') then
        local value = tostring(args[3] or 'status'):lower();
        local settings = targeting.GetSettings();

        if (value == 'on') then
            settings.enablePetPlateTargeting = true;
        elseif (value == 'off') then
            settings.enablePetPlateTargeting = false;
        elseif (value ~= 'status' and value ~= '') then
            settings.enablePetPlateTargeting = settings.enablePetPlateTargeting == false;
        end

        state.Save();
        log.Info('Pet plate targeting enabled=' .. tostring(settings.enablePetPlateTargeting ~= false));
        return;
    end

    if (subcommand == 'enemypos' or subcommand == 'enemyposition') then
        local action = tostring(args[3] or 'status'):lower();
        local value = tonumber(args[4]);

        if (action == 'bone' and value ~= nil) then
            enemyPlate.SetAnchorBone(value);
        elseif ((action == 'offset' or action == 'offsety' or action == 'y') and value ~= nil) then
            enemyPlate.SetWorldOffsetY(value);
        elseif (action == 'reset') then
            enemyPlate.ResetPositionDebug();
        elseif (action ~= 'status' and action ~= '') then
            log.Warn('Usage: /lp enemypos bone <0-32> | offset <number> | reset | status');
            return;
        end

        log.Info(enemyPlate.GetPositionDebugText());
        return;
    end

    if (subcommand == 'anchor') then
        local action = tostring(args[3] or 'status'):lower();
        local value = tostring(args[4] or ''):lower();

        if (action == 'debug' or action == 'dump') then
            local targetIndex = nil;

            if (value == 'pet') then
                targetIndex = entities.GetOwnPetTargetIndex();
            elseif (tonumber(args[4]) ~= nil) then
                targetIndex = tonumber(args[4]);
            else
                targetIndex = targeting.GetCurrentTargetIndex() or entities.GetOwnPetTargetIndex();
            end

            local debug, err = worldMarkerProbe.GetAnchorDebug(targetIndex, entities.GetEntityManager, entities.GetBone);

            if (debug == nil) then
                log.Warn('Anchor debug failed: ' .. tostring(err) .. ' target=' .. tostring(targetIndex));
                return;
            end

            log.Info(
                'Anchor debug target=' .. tostring(debug.targetIndex) ..
                ' boneScreen=' .. tostring(debug.boneScreenX) .. ',' .. tostring(debug.boneScreenY) .. ',' .. tostring(debug.boneScreenZ) ..
                ' exactOk=' .. tostring(debug.exactOk) ..
                ' exactScreen=' .. tostring(debug.exactScreenX) .. ',' .. tostring(debug.exactScreenY) .. ',' .. tostring(debug.exactScreenZ) ..
                ' delta=' .. tostring(debug.deltaScreenX) .. ',' .. tostring(debug.deltaScreenY) ..
                ' helper=' .. tostring(debug.helperStatus)
            );
            return;
        elseif (action == 'bone' and tonumber(args[4]) ~= nil) then
            worldMarkerProbe.SetAnchorMode('bone');
            worldMarkerProbe.SetAnchorBone(tonumber(args[4]));
        elseif (action == 'bone') then
            worldMarkerProbe.SetAnchorMode('bone');
        elseif (action == 'exact' or action == 'nameplate') then
            worldMarkerProbe.SetAnchorMode('exact');
        elseif (action == 'compare') then
            if (value == 'on') then
                worldMarkerProbe.SetCompareAnchors(true);
            elseif (value == 'off') then
                worldMarkerProbe.SetCompareAnchors(false);
            else
                worldMarkerProbe.SetCompareAnchors(not worldMarkerProbe.GetCompareAnchors());
            end
        elseif (action == 'offset' and tonumber(args[4]) ~= nil) then
            worldMarkerProbe.SetVerticalOffset(tonumber(args[4]));
        elseif ((action == 'nameheight' or action == 'nameoffset') and tonumber(args[4]) ~= nil) then
            worldMarkerProbe.SetNameVerticalOffset(tonumber(args[4]));
        elseif (action ~= 'status' and action ~= '') then
            log.Warn('Usage: /lp anchor bone [0-32] | exact | compare [on/off] | offset <n> | nameheight <n> | debug [pet/index] | status');
            return;
        end

        log.Info(worldMarkerProbe.GetStatusText());
        return;
    end

    if (subcommand == 'pcheight' or subcommand == 'pcheights') then
        local settings = targeting.GetSettings();
        EnsurePcHeightSettings(settings);

        local action = tostring(args[3] or ''):lower();

        if (action == 'default' or action == 'defaults' or action == 'reset') then
            ApplyPcHeightDefaults(settings);
            state.Save();
            log.Info('PC height adjustments reset to 0. Zero now means the built-in race/sex/size baseline.');
            return;
        end

        local familyKey, familyLabel = PcHeightCommand.NormalizeFamily(args[3]);
        local directBucketKey = PcHeightCommand.IsBucketKey(args[3]) == true and tostring(args[3]):lower() or nil;

        if (directBucketKey ~= nil) then
            local yValue = tonumber(args[4]);
            local bucket = settings.pcRacePlateAdjustments.buckets[directBucketKey];

            if (yValue == nil) then
                log.Info('PC height ' .. directBucketKey .. ' y=' .. tostring(bucket.y) .. '. 0 is the built-in bucket baseline; positive lowers more.');
                return;
            end

            bucket.y = math.max(-100, math.min(100, math.floor(yValue + 0.5)));
            state.Save();
            log.Info('PC height ' .. directBucketKey .. ' set y=' .. tostring(bucket.y) .. '.');
            return;
        end

        if (familyKey == nil) then
            local parts = {};
            for _, key in ipairs(PcHeightCommand.GetBucketKeys()) do
                local bucket = settings.pcRacePlateAdjustments.buckets[key] or {};
                if (tonumber(bucket.y) ~= 0) then
                    parts[#parts + 1] = key .. '=' .. tostring(bucket.y);
                end
            end

            log.Info('PC height adjustments enabled=' .. tostring(settings.pcRacePlateAdjustments.enabled ~= false) .. ' changed buckets=' .. (next(parts) ~= nil and table.concat(parts, ' | ') or 'none'));
            log.Info('Usage: /lp pcheight taru female small <y> | /lp pcheight hume_male_medium <y> | /lp pcheight defaults. 0 is the built-in bucket baseline; positive lowers more.');
            return;
        end

        local sexKey, sexLabel = PcHeightCommand.NormalizeSex(args[4]);
        local sizeKey, sizeLabel = PcHeightCommand.NormalizeSize(args[5]);
        local yValue = tonumber(args[6]);

        if (sexKey == nil or sizeKey == nil) then
            log.Info('PC height ' .. familyLabel .. ' uses race/sex/size buckets. Usage: /lp pcheight ' .. tostring(args[3]) .. ' female small <y> or adjust in settings.');
            return;
        end

        local bucketKey = PcHeightCommand.GetBucketKey(familyKey, sexKey, sizeKey);
        local bucket = bucketKey ~= nil and settings.pcRacePlateAdjustments.buckets[bucketKey] or nil;

        if (bucket == nil) then
            log.Warn('No PC height bucket exists for ' .. tostring(familyLabel) .. ' ' .. tostring(sexLabel) .. ' ' .. tostring(sizeLabel) .. '.');
            return;
        end

        if (yValue == nil) then
            log.Info('PC height ' .. familyLabel .. ' ' .. tostring(sexLabel) .. ' ' .. tostring(sizeLabel) .. ' y=' .. tostring(bucket.y) .. '. 0 is the built-in bucket baseline; positive lowers more.');
            return;
        end

        bucket.y = math.max(-100, math.min(100, math.floor(yValue + 0.5)));

        state.Save();
        log.Info('PC height ' .. familyLabel .. ' ' .. tostring(sexLabel) .. ' ' .. tostring(sizeLabel) .. ' set y=' .. tostring(bucket.y) .. '.');
        return;
    end

    if (subcommand == 'visdebug' or subcommand == 'visibilitydebug' or subcommand == 'invisdebug') then
        local action = tostring(args[3] or ''):lower();

        if (action == 'compare' or action == 'diff') then
            local leftName = tostring(args[4] or 'large'):lower();
            local rightName = tostring(args[5] or 'small'):lower();
            local left = visDebugCaptures[leftName];
            local right = visDebugCaptures[rightName];

            if (left == nil or right == nil) then
                log.Warn('Visibility compare needs saved captures. Use: /lp invisdebug save visible, /lp invisdebug save invisible, then /lp invisdebug compare visible invisible');
                return;
            end

            local diffs = BuildVisibilityDiff(left, right);

            log.Info(
                'Visibility compare ' .. leftName .. '(' .. tostring(left.name) .. '#' .. tostring(left.targetIndex) .. ')' ..
                ' -> ' .. rightName .. '(' .. tostring(right.name) .. '#' .. tostring(right.targetIndex) .. ')' ..
                ' diffs=' .. tostring(#diffs)
            );

            if (#diffs == 0) then
                return;
            end

            local chunk = {};

            for i, diff in ipairs(diffs) do
                chunk[#chunk + 1] = diff;

                if (#chunk >= 12 or i == #diffs) then
                    log.Info('Visibility diff: ' .. table.concat(chunk, ' '));
                    chunk = {};
                end
            end

            return;
        end

        local captureName = nil;
        local targetArgIndex = 3;

        if (action == 'save' or action == 'capture') then
            captureName = tostring(args[4] or ''):lower();

            if (captureName == '') then
                log.Warn('Usage: /lp invisdebug save <label> [target/pet/index]');
                return;
            end

            targetArgIndex = 5;
        end

        local targetIndex = ResolveVisDebugTarget(args, targetArgIndex);
        local debug, err = worldMarkerProbe.GetVisibilityDebug(targetIndex, entities.GetEntityManager, entities.GetBone);

        if (debug == nil) then
            log.Warn('Visibility debug failed: ' .. tostring(err) .. ' target=' .. tostring(targetIndex));
            return;
        end

        if (captureName ~= nil) then
            visDebugCaptures[captureName] = debug;
            log.Info('Visibility debug saved ' .. captureName .. '=' .. tostring(debug.name) .. '#' .. tostring(debug.targetIndex));
        end

        local bone2 = debug.bone2 or {};
        local bone12 = debug.bone12 or {};
        local enemyPlate2 = debug.enemyPlate2 or {};
        local playerIndicators = require('core.player_indicators');
        local flagParts = {};

        for flagIndex = 0, 7 do
            local value = tonumber(debug.renderFlags ~= nil and debug.renderFlags[flagIndex]);

            if (value == nil) then
                value = tonumber(debug['renderFlags' .. tostring(flagIndex)]) or 0;
            end

            flagParts[#flagParts + 1] = 'r' .. tostring(flagIndex) .. '=0x' .. string.format('%X', value);
        end

        local cleanDebugName = tostring(debug.name or ''):gsub('\170', ''):lower();
        local fishDebug = tonumber(debug.zoneId) == 33 and (cleanDebugName == "ul'hpemde" or cleanDebugName == "ul'phuabo");
        local fishBelow = fishDebug == true
            and tonumber(enemyPlate2.plateWorldY) ~= nil
            and tonumber(debug.selfZ) ~= nil
            and tonumber(enemyPlate2.plateWorldY) < (tonumber(debug.selfZ) - 1.50);

        log.Info(
            'Visibility debug target=' .. tostring(debug.targetIndex) ..
            ' zone=' .. tostring(debug.zoneId) ..
            ' name=' .. tostring(debug.name) ..
            ' fish=' .. tostring(fishDebug) ..
            ' fishBelow=' .. tostring(fishBelow) ..
            ' status=' .. tostring(debug.status) ..
            ' hp=' .. tostring(debug.hpPercent) ..
            ' type=' .. tostring(debug.type) ..
            ' spawn=0x' .. string.format('%X', tonumber(debug.spawnFlags) or 0) ..
            ' rf0=0x' .. string.format('%X', tonumber(debug.renderFlags0) or 0) ..
            ' rf1=0x' .. string.format('%X', tonumber(debug.renderFlags1) or 0) ..
            ' flags=' .. table.concat(flagParts, ' ') ..
            ' gmNative=' .. tostring(playerIndicators.IsGameMaster(debug.targetIndex) == true) ..
            ' gmDebug=' .. tostring(playerIndicators.GetGameMasterDebugText(debug.targetIndex)) ..
            ' local=' .. tostring(debug.localX) .. ',' .. tostring(debug.localY) .. ',' .. tostring(debug.localZ) ..
            ' last=' .. tostring(debug.lastX) .. ',' .. tostring(debug.lastY) .. ',' .. tostring(debug.lastZ) ..
            ' b2=' .. tostring(bone2.screenX) .. ',' .. tostring(bone2.screenY) .. ',' .. tostring(bone2.screenZ) .. ',p=' .. tostring(bone2.projected) ..
            ' b12=' .. tostring(bone12.screenX) .. ',' .. tostring(bone12.screenY) .. ',' .. tostring(bone12.screenZ) .. ',p=' .. tostring(bone12.projected) ..
            ' plate2=' .. tostring(enemyPlate2.screenX) .. ',' .. tostring(enemyPlate2.screenY) .. ',' .. tostring(enemyPlate2.screenZ) .. ',p=' .. tostring(enemyPlate2.projected) ..
            ' plateY=' .. tostring(enemyPlate2.plateWorldY) ..
            ' selfZ=' .. tostring(debug.selfZ) ..
            ' viewH=' .. tostring(debug.viewportHeight) ..
            ' bones=' .. tostring(debug.boneCount) ..
            ' z=' .. tostring(debug.boneMinZ) .. '/' .. tostring(debug.boneMaxZ) .. '/' .. tostring(debug.boneSpanZ) ..
            ' y=' .. tostring(debug.boneMinY) .. '/' .. tostring(debug.boneMaxY) .. '/' .. tostring(debug.boneSpanY) ..
            ' baseZ=' .. tostring(debug.baseZ) ..
            ' obj=0x' .. string.format('%X', tonumber(debug.objectPointer) or 0) ..
            ' af=' .. tostring(debug.actorScalars) ..
            ' ai=' .. tostring(debug.actorInts) ..
            ' of=' .. tostring(debug.objectScalars) ..
            ' oi=' .. tostring(debug.objectInts) ..
            ' byteProbe=' .. tostring(debug.actorBytes ~= nil or debug.objectBytes ~= nil)
        );
        return;
    end

    if (subcommand == 'targetoverlay') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            enemyPlate.SetTargetOverlayEnabled(true);
        elseif (value == 'off') then
            enemyPlate.SetTargetOverlayEnabled(false);
        else
            enemyPlate.SetTargetOverlayEnabled(not enemyPlate.GetTargetOverlayEnabled());
        end

        log.Info('Target overlay enabled=' .. tostring(enemyPlate.GetTargetOverlayEnabled()));
        return;
    end

    if (subcommand == 'nativearrow') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'debugoff') then
            nativeTargetArrow.SetTraceEnabled(false);
            nativeTargetArrow.SetDrawBlockEnabled(false);
            nativeTargetArrow.SetPartyTraceEnabled(false);
            nativeTargetArrow.SetPartyBlockEnabled(false);
            nativeTargetArrow.SetHardHideEveryDrawEnabled(false);
            log.Info('native arrow debug modes disabled');
            return;
        end

        if (value == 'windowstatus') then
            nativeTargetArrow.WriteTargetWindowStatus('manual');
            log.Info('native target windowstatus written file=' .. nativeTargetArrow.GetTraceFilePath());
            return;
        end

        if (value ~= '' and value ~= 'status') then
            log.Warn('Usage: /lp nativearrow status | /lp nativearrow debugoff | /lp nativearrow windowstatus');
            return;
        end

        log.Info(nativeTargetArrow.GetStatusText() .. ' ' .. modules.GetNativeTargetArrowDebugStatus() .. ' ' .. nativeTargetArrow.GetTraceStatusText() .. ' ' .. nativeTargetArrow.GetHardHideEveryDrawStatusText());
        return;
    end

    if (subcommand == 'perf' or subcommand == 'performance') then
        local value = tostring(args[3] or 'status'):lower();

        if (value == 'detail') then
            local detailValue = tostring(args[4] or 'status'):lower();

            if (detailValue == 'on') then
                perfMeter.SetDetailEnabled(true);
            elseif (detailValue == 'off') then
                perfMeter.SetDetailEnabled(false);
            elseif (detailValue ~= 'status' and detailValue ~= '') then
                log.Warn('Usage: /lp perf detail [on|off|status]');
                return;
            end
        elseif (value == 'on') then
            perfMeter.SetOverlayEnabled(true);
        elseif (value == 'off') then
            perfMeter.SetOverlayEnabled(false);
        elseif (value == 'reset') then
            perfMeter.Reset();
            log.Info('Performance meter reset.');
            return;
        elseif (value == 'report') then
            perfMeter.WritePerformanceReport();
            log.Info('Performance report saved.');
            return;
        elseif (value == 'record') then
            local recordValue = tostring(args[4] or '60'):lower();

            if (recordValue == 'status') then
                log.Info('Performance recording: ' .. perfMeter.GetTimedReportStatus());
                return;
            elseif (recordValue == 'cancel' or recordValue == 'stop') then
                if (perfMeter.StopTimedReport(false) == true) then
                    log.Info('Performance recording cancelled.');
                else
                    log.Info('No performance recording is active.');
                end
                return;
            end

            local duration = perfMeter.StartTimedReport(tonumber(args[4]) or 60);
            log.Info('Performance recording started for ' .. tostring(duration) .. ' seconds. Reproduce the freeze; report will save automatically.');
            return;
        elseif (value ~= 'status' and value ~= '') then
            log.Warn('Usage: /lp perf [on|off|reset|report|record|status] | /lp perf detail [on|off|status] | /lp perf record [seconds|status|cancel]');
            return;
        end

        for _, line in ipairs(perfMeter.GetSummaryLines()) do
            log.Info(line);
        end

        local canvasStats = canvasTexture.GetCacheStats();

        if (canvasStats ~= nil) then
            log.Info(
                'Canvas texture cache: ' ..
                tostring(canvasStats.count) .. '/' .. tostring(canvasStats.max) ..
                ' evictions=' .. tostring(canvasStats.evictions)
            );
        end

        return;
    end

    if (subcommand == 'backups') then
        local value = tostring(args[3] or 'prune'):lower();

        if (value ~= 'prune' and value ~= 'clean' and value ~= 'status') then
            log.Warn('Usage: /lp backups status');
            return;
        end

        log.Warn('In-game backup pruning is disabled. Close the game and delete old files from the LibraPlates backups folder manually. Future backups overwrite settings-backup.lua only.');

        return;
    end

    if (subcommand == 'lagtest' or subcommand == 'lagcheck') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'cancel' or value == 'stop') then
            lagTest.Cancel();
        elseif (value == 'status') then
            log.Info(lagTest.GetStatusText());
        elseif (value == 'self') then
            lagTest.Start(tonumber(args[4]), 'self');
        else
            lagTest.Start(tonumber(args[3]));
        end

        return;
    end

    if (subcommand == 'perftest') then
        adaptivePerformance.SetEnabled(true);
        perfMeter.Reset();
        perfMeter.SetDetailEnabled(true);
        perfMeter.SetOverlayEnabled(true);
        log.Info('Perf test ready: fpsobserve=on detail=on overlay=on. After a stutter, run /lp perf status.');
        return;
    end

    if (subcommand == 'lag') then
        local path, phaseName, seconds = diagnostics.StartAuto(tonumber(args[3]) or 15);
        log.Info('Lag diagnostics started. Play normally; I will say when done. file=' .. tostring(path) .. ' phase=' .. tostring(phaseName) .. ' seconds=' .. tostring(seconds));
        return;
    end

    if (subcommand == 'diag' or subcommand == 'diagnostics') then
        local action = tostring(args[3] or 'status'):lower();

        if (action == 'start') then
            local path = diagnostics.Start(args[4] or '');
            log.Info('Diagnostics started file=' .. tostring(path));
            return;
        elseif (action == 'stop') then
            local path = diagnostics.Stop();
            log.Info('Diagnostics stopped file=' .. tostring(path));
            return;
        elseif (action == 'mark') then
            diagnostics.Mark(table.concat(args, ' ', 4));
            log.Info('Diagnostics marked.');
            return;
        elseif (action == 'scenario') then
            local ok, result = diagnostics.ApplyScenario(args[4] or '');

            if (ok == true) then
                log.Info('Diagnostics scenario applied=' .. tostring(result) .. ' file=' .. tostring(diagnostics.GetFilePath()));
            else
                log.Warn('Usage: /lp diag scenario native-off | native-arrow-on | native-party-on | target-off | target-on');
            end

            return;
        elseif (action == 'restore') then
            diagnostics.Restore();
            log.Info('Diagnostics restored original target/native settings.');
            return;
        elseif (action == 'auto') then
            local subaction = tostring(args[4] or 'start'):lower();

            if (subaction == 'stop') then
                local path = diagnostics.StopAuto();
                log.Info('Diagnostics auto stopped file=' .. tostring(path));
                return;
            end

            local path, phaseName, seconds = diagnostics.StartAuto(args[4]);
            log.Info('Diagnostics auto started phase=' .. tostring(phaseName) .. ' seconds=' .. tostring(seconds) .. ' file=' .. tostring(path));
            return;
        elseif (action ~= 'status' and action ~= '') then
            log.Warn('Usage: /lp diag auto [seconds] | /lp diag auto stop | start | stop | mark <text> | scenario <name> | restore | status');
            return;
        end

        log.Info(diagnostics.GetStatusText());
        return;
    end

    if (subcommand == 'engaged') then
        log.Info(engagedEnemies.GetStatusText());
        return;
    end

    if (subcommand == 'enmitydebug' or subcommand == 'aggrodebug') then
        local memory = CommandSafeCall(nil, function()
            return AshitaCore:GetMemoryManager();
        end);
        local party = memory ~= nil and CommandSafeCall(nil, function()
            return memory:GetParty();
        end) or nil;
        local entityManager = memory ~= nil and CommandSafeCall(nil, function()
            return memory:GetEntity();
        end) or nil;
        local selfIndex = party ~= nil and (tonumber(CommandSafeCall(0, function()
            return party:GetMemberTargetIndex(0);
        end)) or 0) or 0;
        local targetIndex = tonumber(args[3]) or targeting.GetCurrentTargetIndex() or targeting.GetCurrentSubTargetIndex() or 0;
        local selfServerId = GetDebugServerId(entityManager, selfIndex);
        local targetServerId = GetDebugServerId(entityManager, targetIndex);
        local targetDebug = entities.GetEntityDebugInfo(targetIndex, targeting.GetSettings().enemyPlateRange);
        local targetName = targetDebug ~= nil and targetDebug.name or CommandSafeCall('', function()
            return entityManager:GetName(targetIndex);
        end);
        local targetIsEnemy = targetDebug ~= nil and targetDebug.isMob == true;
        local enemyTargetingSelf = enmity.IsEnemyTargetingSelf({
            index = targetIndex,
            serverId = targetServerId,
        });
        local selfTargetedByAnyEnemy = enmity.IsServerIdTargeted(selfServerId, selfIndex);

        log.Info(
            'Enmity debug self=' .. tostring(selfIndex) ..
            ' selfServer=' .. tostring(selfServerId) ..
            ' selfStatus=' .. tostring(GetDebugStatus(entityManager, selfIndex)) ..
            ' target=' .. tostring(targetIndex) ..
            ' targetServer=' .. tostring(targetServerId) ..
            ' targetName=' .. tostring(targetName) ..
            ' targetStatus=' .. tostring(GetDebugStatus(entityManager, targetIndex)) ..
            ' targetHp=' .. tostring(targetDebug ~= nil and targetDebug.hpPercent or nil) ..
            ' targetType=' .. tostring(targetDebug ~= nil and targetDebug.type or nil) ..
            ' targetIsEnemy=' .. tostring(targetIsEnemy) ..
            ' targetClaim=' .. tostring(engagedEnemies.GetClaimCategory(targetIndex)) ..
            ' targetTracked=' .. tostring(engagedEnemies.IsEngaged(targetIndex)) ..
            ' targetAimingSelf=' .. tostring(enemyTargetingSelf) ..
            ' selfTargetedByAny=' .. tostring(selfTargetedByAnyEnemy)
        );
        return;
    end

    if (subcommand == 'claimdebug') then
        local action = tostring(args[3] or 'on'):lower();

        if (action == 'off' or action == 'stop') then
            engagedEnemies.DisableClaimDebug();
        else
            engagedEnemies.EnableClaimDebugForSeconds(tonumber(args[4]) or tonumber(args[3]) or 20);
        end

        return;
    end

    if (subcommand == 'overlaystatus') then
        log.Info(overlaySuppression.GetStatusText());
        return;
    end

    if (subcommand == 'targetdebug') then
        log.Info(targetModuleMarker.GetDebugStatus());
        log.Info(targetOverlay.GetDebugStatus());
        return;
    end

    if (subcommand == 'doorscan') then
        local range = tonumber(args[3]) or 12;
        local objects = entities.GetNearbyRawObjects(range, 10);

        if (#objects == 0) then
            log.Warn('Door scan found no raw objects in range=' .. tostring(range));
            return;
        end

        log.Info('Door scan range=' .. tostring(range) .. ' objects=' .. tostring(#objects));
        log.Info('Door scan mogHouseObjectSuppression=' .. tostring(entities.IsMogHouseObjectSuppressionArea()));

        for _, object in ipairs(objects) do
            log.Info(
                'Door scan object index=' .. tostring(object.index) ..
                ' name=' .. tostring(object.name) ..
                ' nameLen=' .. tostring(object.nameLen) ..
                ' type=' .. tostring(object.type) ..
                ' status=' .. tostring(object.status) ..
                ' distance=' .. string.format('%.2f', tonumber(object.distance) or 0) ..
                ' spawn=0x' .. string.format('%X', tonumber(object.spawnFlags) or 0) ..
                ' render0=0x' .. string.format('%X', tonumber(object.renderFlags0) or 0) ..
                ' render1=0x' .. string.format('%X', tonumber(object.renderFlags1) or 0) ..
                ' visible=' .. tostring(object.visible) ..
                ' mogFurniture=' .. tostring(object.mogHouseFurniturePlaceholder) ..
                ' statusAllowed=' .. tostring(object.statusAllowed)
            );
        end

        return;
    end

    if (subcommand == 'hiddenscan' or subcommand == 'hiddenmobscan') then
        local range = tonumber(args[3]) or targeting.GetSettings().enemyPlateRange or 50;
        local limit = math.max(1, math.min(30, tonumber(args[4]) or 12));
        local nameFilter = tostring(args[5] or ''):lower();
        local entityManager = entities.GetEntityManager ~= nil and entities.GetEntityManager() or nil;

        if (entityManager == nil) then
            log.Warn('Hidden scan failed: no entity manager.');
            return;
        end

        local rangeSq = range * range;
        local rows = {};
        local mobCount = 0;
        local visibleCount = 0;
        local hiddenCandidateCount = 0;

        for index = 0, 2303 do
            if (index < 1024 or index > 1791) then
                local ent = GetEntity(index);
                local distanceSq = tonumber(ent ~= nil and ent.Distance or nil);

                if (
                    ent ~= nil and
                    tostring(ent.Name or '') ~= '' and
                    distanceSq ~= nil and
                    distanceSq <= rangeSq
                ) then
                    local spawnFlags = tonumber(CommandSafeCall(0, function()
                        return entityManager:GetSpawnFlags(index);
                    end)) or 0;
                    local isMob = HasFlag(spawnFlags, 0x10);

                    if (isMob == true) then
                        mobCount = mobCount + 1;

                        local hp = tonumber(ent.HPPercent);
                        local render0 = tonumber(CommandSafeCall(0, function()
                            return entityManager:GetRenderFlags0(index);
                        end)) or 0;
                        local render1 = tonumber(CommandSafeCall(0, function()
                            return entityManager:GetRenderFlags1(index);
                        end)) or 0;
                        local actorPointer = tonumber(CommandSafeCall(0, function()
                            return entityManager:GetActorPointer(index);
                        end)) or 0;
                        local hiddenUntilAggro = entities.IsHiddenUntilAggroEnemyNameStatus(ent.Name, ent.Status) == true;
                        local plateVisible =
                            HasFlag(render0, 0x200) == true and
                            HasFlag(render0, 0x4000) ~= true and
                            actorPointer ~= 0 and
                            hiddenUntilAggro ~= true;

                        local cleanName = tostring(ent.Name or ''):gsub('\170', ''):lower();
                        local nameMatches = nameFilter == '' or cleanName:find(nameFilter, 1, true) ~= nil;

                        if (plateVisible == true) then
                            visibleCount = visibleCount + 1;
                        else
                            hiddenCandidateCount = hiddenCandidateCount + 1;
                        end

                        if (nameMatches == true or (nameFilter == '' and plateVisible ~= true)) then
                            local reason = {};
                            if (plateVisible == true) then reason[#reason + 1] = 'visibleByLP'; end
                            if (HasFlag(render0, 0x200) ~= true) then reason[#reason + 1] = 'no-r0-0x200'; end
                            if (HasFlag(render0, 0x4000) == true) then reason[#reason + 1] = 'r0-0x4000'; end
                            if (actorPointer == 0) then reason[#reason + 1] = 'no-actor'; end
                            if (hiddenUntilAggro == true) then reason[#reason + 1] = 'hidden-until-aggro'; end
                            if (#reason == 0) then reason[#reason + 1] = 'unknown'; end

                            rows[#rows + 1] = {
                                index = index,
                                name = ent.Name,
                                distance = math.sqrt(distanceSq),
                                status = ent.Status,
                                hp = hp,
                                serverId = GetDebugServerId(entityManager, index),
                                spawnFlags = spawnFlags,
                                render0 = render0,
                                render1 = render1,
                                actorPointer = actorPointer,
                                reason = table.concat(reason, ','),
                            };
                        end
                    end
                end
            end
        end

        table.sort(rows, function(left, right)
            return (tonumber(left.distance) or 9999) < (tonumber(right.distance) or 9999);
        end);

        log.Info(
            'Hidden scan range=' .. tostring(range) ..
            ' mobs=' .. tostring(mobCount) ..
            ' visibleByLP=' .. tostring(visibleCount) ..
            ' hiddenCandidates=' .. tostring(hiddenCandidateCount) ..
            ' filter=' .. tostring(nameFilter ~= '' and nameFilter or '-') ..
            ' showing=' .. tostring(math.min(#rows, limit))
        );

        for rowIndex = 1, math.min(#rows, limit) do
            local row = rows[rowIndex];
            log.Info(
                'Hidden scan ' .. tostring(rowIndex) ..
                ' index=' .. tostring(row.index) ..
                ' name=' .. tostring(row.name) ..
                ' serverId=' .. tostring(row.serverId) ..
                ' dist=' .. string.format('%.1f', tonumber(row.distance) or 0) ..
                ' status=' .. tostring(row.status) ..
                ' hp=' .. tostring(row.hp) ..
                ' spawn=0x' .. string.format('%X', tonumber(row.spawnFlags) or 0) ..
                ' render0=0x' .. string.format('%X', tonumber(row.render0) or 0) ..
                ' render1=0x' .. string.format('%X', tonumber(row.render1) or 0) ..
                ' actor=0x' .. string.format('%X', tonumber(row.actorPointer) or 0) ..
                ' reason=' .. tostring(row.reason) ..
                ' r0Bits=' .. DebugFlagList(row.render0, { 0x200, 0x2000, 0x4000, 0x400000, 0x800000, 0x40000000, 0x80000000 }) ..
                ' r1Bits=' .. DebugFlagList(row.render1, { 0x8, 0x40, 0x400, 0x800, 0x8000, 0x2000000 })
            );
        end

        return;
    end

    if (subcommand == 'npcstance') then
        local label = tostring(args[3] or '-');
        local targetIndex = tonumber(args[3]) or tonumber(args[4]) or targeting.GetCurrentTargetIndex() or targeting.GetCurrentSubTargetIndex();
        local debug = entities.GetEntityDebugInfo(targetIndex, targeting.GetWorldPlateRange());

        if (debug == nil) then
            log.Warn('NPC stance probe failed: no current target. current=' .. tostring(targeting.GetCurrentTargetIndex()) .. ' sub=' .. tostring(targeting.GetCurrentSubTargetIndex()));
            return;
        end

        if (tonumber(args[3]) ~= nil) then
            label = '-';
        end

        local rawEntityName = (tonumber(debug.type) == 2 or tonumber(debug.type) == 3) and 'Object' or 'NPC';
        local cleanName = tostring(debug.name or ''):gsub('\170', '');
        local resolvedEntityName, info = npcObjectInfo.ResolveKind(cleanName, rawEntityName, { targetIndex = debug.index });
        local backgroundSettings = state.GetWidgetSettings(resolvedEntityName, 'Idle', 'Background', require('config.widgets.background'));
        local nameSettings = state.GetWidgetSettings(resolvedEntityName, 'Idle', 'Name', require('config.widgets.name'));
        local typeLineSettings = state.GetWidgetSettings(resolvedEntityName, 'Idle', 'Type line', typeLineDefaults);
        local iconSettings = state.GetWidgetSettings(resolvedEntityName, 'Idle', 'Icon', require('config.widgets.npc_object_icon'));
        local render0 = tonumber(debug.renderFlags0) or 0;
        local render1 = tonumber(debug.renderFlags1) or 0;

        log.Info(
            'NPC stance probe label=' .. tostring(label) ..
            ' target=' .. tostring(debug.index) ..
            ' name=' .. tostring(cleanName) ..
            ' status=' .. tostring(debug.status) ..
            ' type=' .. tostring(debug.type) ..
            ' hp=' .. tostring(debug.hpPercent) ..
            ' dist=' .. string.format('%.2f', tonumber(debug.distance) or 0) ..
            ' worldScan=' .. tostring(debug.npcScanAllowed) ..
            ' tacticalScan=' .. tostring(debug.tacticalNpcAllowed) ..
            ' gates=index:' .. tostring(debug.indexAllowed) ..
            ',status:' .. tostring(debug.statusAllowed) ..
            ',visible:' .. tostring(debug.visible) ..
            ',settled:' .. tostring(debug.settled) ..
            ',range:' .. tostring(debug.inRange) ..
            ',mob:' .. tostring(debug.isMob) ..
            ',party:' .. tostring(debug.isParty) ..
            ',mog:' .. tostring(debug.mogHouseFurniturePlaceholder) ..
            ' current=' .. tostring(targeting.GetCurrentTargetIndex()) ..
            ' sub=' .. tostring(targeting.GetCurrentSubTargetIndex()) ..
            ' resolved=' .. tostring(resolvedEntityName) ..
            ' infoSource=' .. tostring(info ~= nil and info.source or nil) ..
            ' infoType=' .. tostring(info ~= nil and info.type or nil) ..
            ' widgets=name:' .. tostring(nameSettings ~= nil and nameSettings.enabled == true) ..
            ',type:' .. tostring(typeLineSettings ~= nil and typeLineSettings.enabled == true) ..
            ',icon:' .. tostring(iconSettings ~= nil and iconSettings.enabled == true) ..
            ',bg:' .. tostring(backgroundSettings ~= nil and backgroundSettings.enabled == true) ..
            ' spawn=0x' .. string.format('%X', tonumber(debug.spawnFlags) or 0) ..
            ' r0=0x' .. string.format('%X', render0) ..
            ' r1=0x' .. string.format('%X', render1) ..
            ' r0Bits=' .. DebugFlagList(render0, { 0x200, 0x2000, 0x4000, 0x400000, 0x800000, 0x40000000, 0x80000000 }) ..
            ' r1Bits=' .. DebugFlagList(render1, { 0x8, 0x40, 0x400, 0x800, 0x8000, 0x2000000 })
        );
        return;
    end

    if (subcommand == 'currenttarget' or subcommand == 'targetprobe' or subcommand == 'doorprobe') then
        LogCurrentTargetProbe('Current target probe');
        return;
    end

    if (subcommand == 'entitydebug' or subcommand == 'targetcap' or subcommand == 'doorcap') then
        if (subcommand == 'doorcap' and tonumber(args[3]) == nil) then
            LogCurrentTargetProbe('Door target probe');
        end

        local targetIndex = tonumber(args[3]) or targeting.GetCurrentTargetIndex() or targeting.GetCurrentSubTargetIndex();
        local debug = entities.GetEntityDebugInfo(targetIndex, targeting.GetSettings().enemyPlateRange);

        if (debug == nil) then
            log.Warn('Entity debug failed: no current target. current=' .. tostring(targeting.GetCurrentTargetIndex()) .. ' sub=' .. tostring(targeting.GetCurrentSubTargetIndex()));
            return;
        end

        local rawEntityName = (tonumber(debug.type) == 2 or tonumber(debug.type) == 3) and 'Object' or 'NPC';
        local cleanName = tostring(debug.name or ''):gsub('\170', '');
        local resolvedEntityName, info = npcObjectInfo.ResolveKind(cleanName, rawEntityName);
        local typeLineSettings = state.GetWidgetSettings(resolvedEntityName, 'Idle', 'Type line', typeLineDefaults);
        local render0 = tonumber(debug.renderFlags0) or 0;
        local render1 = tonumber(debug.renderFlags1) or 0;
        local hasNativeSpecialNameMarker = tostring(debug.name or ''):sub(1, 1) == string.char(0xAA);
        local expectedStar = hasNativeSpecialNameMarker == true and HasFlag(render1, 0x800) == true;

        log.Info(
            'Entity debug target=' .. tostring(debug.index) ..
            ' name=' .. tostring(debug.name) ..
            ' type=' .. tostring(debug.type) ..
            ' status=' .. tostring(debug.status) ..
            ' hp=' .. tostring(debug.hpPercent) ..
            ' mp=' .. tostring(debug.mp) .. '/' .. tostring(debug.maxMp) ..
            ' mpPct=' .. tostring(debug.mpPercent) ..
            ' tp=' .. tostring(debug.tp) ..
            ' partySlot=' .. tostring(debug.partySlot) ..
            ' partyHp=' .. tostring(debug.partyHp) .. '/' .. tostring(debug.partyMaxHp) ..
            ' partyHpPct=' .. tostring(debug.partyHpPercent) ..
            ' partyMp=' .. tostring(debug.partyMp) .. '/' .. tostring(debug.partyMaxMp) ..
            ' partyMpPct=' .. tostring(debug.partyMpPercent) ..
            ' partyTp=' .. tostring(debug.partyTp) ..
            ' partyJob=' .. tostring(debug.partyMainJob) ..
            ' partyLevel=' .. tostring(debug.partyMainJobLevel) ..
            ' distance=' .. tostring(debug.distance) ..
            ' current=' .. tostring(targeting.GetCurrentTargetIndex()) ..
            ' sub=' .. tostring(targeting.GetCurrentSubTargetIndex()) ..
            ' nameLen=' .. tostring(string.len(tostring(debug.name or ''))) ..
            ' cleanLen=' .. tostring(string.len(cleanName)) ..
            ' spawn=0x' .. string.format('%X', tonumber(debug.spawnFlags) or 0) ..
            ' render0=0x' .. string.format('%X', render0) ..
            ' render1=0x' .. string.format('%X', render1) ..
            ' specialNameBit=' .. tostring(HasFlag(render1, 0x800)) ..
            ' specialNameMarker=' .. tostring(hasNativeSpecialNameMarker) ..
            ' r0hi=' .. tostring(HasFlag(render0, 0x80000000)) ..
            ' r0mid=' .. tostring(HasFlag(render0, 0x40000000)) ..
            ' indexAllowed=' .. tostring(debug.indexAllowed) ..
            ' isMob=' .. tostring(debug.isMob) ..
            ' isParty=' .. tostring(debug.isParty) ..
            ' invisibleActor=' .. tostring(debug.invisibleActor) ..
            ' objectCostumePlayer=' .. tostring(debug.objectCostumePlayer) ..
            ' visible=' .. tostring(debug.visible) ..
            ' visibleSkeleton=' .. tostring(debug.visibleWithSkeleton) ..
            ' mogFurniture=' .. tostring(debug.mogHouseFurniturePlaceholder) ..
            ' mogObjectSuppression=' .. tostring(debug.mogHouseObjectSuppression) ..
            ' settled=' .. tostring(debug.settled) ..
            ' inRange=' .. tostring(debug.inRange) ..
            ' statusAllowed=' .. tostring(debug.statusAllowed) ..
            ' npcScanAllowed=' .. tostring(debug.npcScanAllowed) ..
            ' tacticalNpcAllowed=' .. tostring(debug.tacticalNpcAllowed) ..
            ' alliedTacticalInfo=' .. tostring(debug.alliedTacticalInfo) ..
            ' tacticalNpcInfoType=' .. tostring(debug.tacticalNpcInfoType) ..
            ' layout=' .. tostring(debug.layoutStateName) ..
            ' resolved=' .. tostring(resolvedEntityName) ..
            ' infoSource=' .. tostring(info ~= nil and info.source or nil) ..
            ' infoType=' .. tostring(info ~= nil and info.type or nil) ..
            ' typeLineEnabled=' .. tostring(typeLineSettings ~= nil and typeLineSettings.enabled == true)
        );
        log.Info(
            'Entity icon probe target=' .. tostring(debug.index) ..
            ' name=' .. tostring(cleanName) ..
            ' nativeSpecial=' .. tostring(HasFlag(render1, 0x800)) ..
            ' nativeMarker=' .. tostring(hasNativeSpecialNameMarker) ..
            ' r0Bits=' .. DebugFlagList(render0, { 0x200, 0x2000, 0x400000, 0x800000, 0x40000000, 0x80000000 }) ..
            ' r1Bits=' .. DebugFlagList(render1, { 0x8, 0x40, 0x400, 0x800, 0x8000, 0x2000000 }) ..
            ' expectedStar=' .. tostring(expectedStar)
        );
        return;
    end

    if (subcommand == 'pcscan' or subcommand == 'pcflags') then
        local entityManager = entities.GetEntityManager ~= nil and entities.GetEntityManager() or nil;
        local probeGameMode = require('core.game_mode');
        local probePlayerIndicators = require('core.player_indicators');
        local maxDistance = tonumber(args[3]) or 50;
        local rows = {};

        for index = 0, 2303 do
            local ent = GetEntity(index);
            local entityType = tonumber(ent ~= nil and ent.Type or nil);
            if (
                (entityType == 0 or (index >= 1024 and index <= 1791 and entityType == 2)) and
                tostring(ent ~= nil and ent.Name or '') ~= ''
            ) then
                local distanceSq = tonumber(ent.Distance);
                if (distanceSq ~= nil and distanceSq <= (maxDistance * maxDistance)) then
                    rows[#rows + 1] = {
                        index = index,
                        name = ent.Name,
                        type = entityType,
                        distance = math.sqrt(distanceSq),
                        serverId = GetDebugServerId(entityManager, index),
                    };
                end
            end
        end

        table.sort(rows, function(a, b)
            return (tonumber(a.distance) or 0) < (tonumber(b.distance) or 0);
        end);

        log.Info('PC scan count=' .. tostring(#rows) .. ' range=' .. tostring(maxDistance));

        for rowIndex = 1, math.min(#rows, 20) do
            local row = rows[rowIndex];
            log.Info(
                'PC scan ' .. tostring(rowIndex) ..
                ' index=' .. tostring(row.index) ..
                ' name=' .. tostring(row.name) ..
                ' type=' .. tostring(row.type) ..
                ' serverId=' .. tostring(row.serverId) ..
                ' dist=' .. string.format('%.1f', tonumber(row.distance) or 0) ..
                ' renderAll=' .. LibraPlatesFormatRenderFlags(row.index) ..
                ' gmNative=' .. tostring(probePlayerIndicators.IsGameMaster(row.index) == true) ..
                ' gmDebug=' .. tostring(probePlayerIndicators.GetGameMasterDebugText(row.index)) ..
                ' mode=' .. tostring(probeGameMode.Resolve(row.index, false)) ..
                ' anonGuess=' .. tostring(probePlayerIndicators.HasAnonNameColor(row.index) == true) ..
                ' r0hi=' .. tostring(HasFlag(probeGameMode.ReadRenderFlag(row.index, 0), 0x80000000)) ..
                ' r1special=' .. tostring(HasFlag(probeGameMode.ReadRenderFlag(row.index, 1), 0x00000800)) ..
                ' r1anonExtra=' .. tostring(HasFlag(probeGameMode.ReadRenderFlag(row.index, 1), 0x02000000)) ..
                ' r1hiExtra=' .. tostring(HasFlag(probeGameMode.ReadRenderFlag(row.index, 1), 0x08000000)) ..
                ' lpNameColorGuess=' .. LibraPlatesResolveNativeNameColorProbe(row.index)
            );
        end

        return;
    end

    if (subcommand == 'pcdebug') then
        local targetIndex = targeting.GetCurrentTargetIndex();
        local players = entities.GetNearbyPlayers(64.4);
        local found = nil;

        for _, player in ipairs(players) do
            if (tonumber(player.index) == tonumber(targetIndex)) then
                found = player;
                break;
            end
        end

        if (found == nil) then
            local entityManager = entities.GetEntityManager();
            local ent = GetEntity(targetIndex);
            local debug = entities.GetEntityDebugInfo(targetIndex, targeting.GetSettings().enemyPlateRange);

            if (targetIndex == nil or ent == nil or tostring(ent.Name or '') == '' or tonumber(debug ~= nil and debug.type or -1) ~= 0) then
                log.Warn('PC debug failed: target is not a PC. target=' .. tostring(targetIndex) .. ' type=' .. tostring(debug ~= nil and debug.type or nil));
                return;
            end

            found = {
                index = targetIndex,
                serverId = GetDebugServerId(entityManager, targetIndex),
                name = ent.Name,
                status = ent.Status,
                distance = ent.Distance ~= nil and math.sqrt(ent.Distance) or nil,
                hpPercent = ent.HPPercent or 100,
            };
        end

        local layoutStateName = (tonumber(found.slot) ~= nil or tonumber(found.status) == 1) and 'Combat' or 'Idle';
        local jobSettings = state.GetWidgetSettings('PC', layoutStateName, 'Job', jobDefaults);
        local levelSettings = state.GetWidgetSettings('PC', layoutStateName, 'Level', levelDefaults);
        local debug = entities.GetEntityDebugInfo(found.index, targeting.GetSettings().enemyPlateRange);
        local entity = GetEntity(found.index);
        local linkshellColor = tonumber(entity ~= nil and entity.LinkshellColor) or 0;
        local probeGameMode = require('core.game_mode');
        local probePlayerIndicators = require('core.player_indicators');

        log.Info(
            'PC debug target=' .. tostring(found.index) ..
            ' name=' .. tostring(found.name) ..
            ' serverId=' .. tostring(found.serverId) ..
            ' status=' .. tostring(found.status) ..
            ' type=' .. tostring(debug ~= nil and debug.type or nil) ..
            ' spawn=0x' .. string.format('%X', tonumber(debug ~= nil and debug.spawnFlags or 0) or 0) ..
            ' render0=0x' .. string.format('%X', tonumber(debug ~= nil and debug.renderFlags0 or 0) or 0) ..
            ' render1=0x' .. string.format('%X', tonumber(debug ~= nil and debug.renderFlags1 or 0) or 0) ..
            ' renderAll=' .. LibraPlatesFormatRenderFlags(found.index) ..
            ' mode=' .. tostring(probeGameMode.Resolve(found.index, false)) ..
            ' anonGuess=' .. tostring(probePlayerIndicators.HasAnonNameColor(found.index) == true) ..
            ' lpNameColorGuess=' .. LibraPlatesResolveNativeNameColorProbe(found.index) ..
            ' overwriteNativeNameColors=' .. tostring(targeting.GetSettings().overwriteNativeNameColors ~= false) ..
            ' useNativeNames=' .. tostring(targeting.GetSettings().hideNativeNamesOnLoad ~= true) ..
            ' layout=' .. tostring(layoutStateName) ..
            ' slot=' .. tostring(found.slot) ..
            ' hp=' .. tostring(found.hp) .. '/' .. tostring(found.maxHp) .. ' pct=' .. tostring(found.hpPercent) ..
            ' mp=' .. tostring(found.mp) .. '/' .. tostring(found.maxMp) .. ' pct=' .. tostring(found.mpPercent) ..
            ' tp=' .. tostring(found.tp) ..
            ' job=' .. tostring(found.mainJob) ..
            ' lvl=' .. tostring(found.mainJobLevel) ..
            ' linkshellColor=0x' .. string.format('%06X', linkshellColor) ..
            ' jobEnabled=' .. tostring(jobSettings.enabled == true) ..
            ' jobXY=' .. tostring(jobSettings.offsetX) .. ',' .. tostring(jobSettings.offsetY) ..
            ' jobMode=' .. tostring(jobSettings.displayModeIndex) ..
            ' levelEnabled=' .. tostring(levelSettings.enabled == true) ..
            ' levelXY=' .. tostring(levelSettings.offsetX) .. ',' .. tostring(levelSettings.offsetY)
        );

        local modelDebug, modelErr = worldMarkerProbe.GetVisibilityDebug(found.index, entities.GetEntityManager, entities.GetBone);

        if (modelDebug ~= nil) then
            local actorInts = ParseDebugList(modelDebug.actorInts);
            local actorFloats = ParseDebugList(modelDebug.actorScalars);
            local modelKey = tonumber(actorInts['20']);
            local sizeScale = tonumber(actorFloats['6A0']);

            log.Info(
                'PC model probe target=' .. tostring(found.index) ..
                ' name=' .. tostring(found.name) ..
                ' serverId=' .. tostring(found.serverId) ..
                ' modelKey=0x' .. string.format('%X', tonumber(modelKey) or 0) ..
                ' raceGuess=' .. GetPcRaceGuess(modelKey) ..
                ' bodyGuess=' .. GetPcBodyGuess(modelDebug) ..
                ' sizeScale=' .. tostring(sizeScale) ..
                ' type=' .. tostring(modelDebug.type) ..
                ' spawn=0x' .. string.format('%X', tonumber(modelDebug.spawnFlags) or 0) ..
                ' rf0=0x' .. string.format('%X', tonumber(modelDebug.renderFlags0) or 0) ..
                ' rf1=0x' .. string.format('%X', tonumber(modelDebug.renderFlags1) or 0) ..
                ' bones=' .. tostring(modelDebug.boneCount) ..
                ' z=' .. tostring(modelDebug.boneMinZ) .. '/' .. tostring(modelDebug.boneMaxZ) .. '/' .. tostring(modelDebug.boneSpanZ) ..
                ' y=' .. tostring(modelDebug.boneMinY) .. '/' .. tostring(modelDebug.boneMaxY) .. '/' .. tostring(modelDebug.boneSpanY) ..
                ' baseZ=' .. tostring(modelDebug.baseZ) ..
                ' b2=' .. tostring(modelDebug.bone2 ~= nil and modelDebug.bone2.worldX or nil) .. ',' .. tostring(modelDebug.bone2 ~= nil and modelDebug.bone2.worldY or nil) .. ',' .. tostring(modelDebug.bone2 ~= nil and modelDebug.bone2.worldZ or nil) ..
                ' b12=' .. tostring(modelDebug.bone12 ~= nil and modelDebug.bone12.worldX or nil) .. ',' .. tostring(modelDebug.bone12 ~= nil and modelDebug.bone12.worldY or nil) .. ',' .. tostring(modelDebug.bone12 ~= nil and modelDebug.bone12.worldZ or nil) ..
                ' obj=0x' .. string.format('%X', tonumber(modelDebug.objectPointer) or 0) ..
                ' af=' .. tostring(modelDebug.actorScalars) ..
                ' ai=' .. tostring(modelDebug.actorInts) ..
                ' of=' .. tostring(modelDebug.objectScalars) ..
                ' oi=' .. tostring(modelDebug.objectInts)
            );
        else
            log.Warn('PC model probe failed: ' .. tostring(modelErr) .. ' target=' .. tostring(found.index));
        end

        return;
    end

    if (subcommand == 'selfdebug') then
        local selfEntity = entities.GetSelf();
        local selfIndex = tonumber(selfEntity ~= nil and selfEntity.index) or 0;

        if (selfIndex == 0) then
            log.Warn('Self debug failed: self index missing.');
            return;
        end

        local debug = entities.GetEntityDebugInfo(selfIndex, targeting.GetSettings().enemyPlateRange);
        local probeGameMode = require('core.game_mode');
        local probePlayerIndicators = require('core.player_indicators');

        log.Info(
            'Self debug target=' .. tostring(selfIndex) ..
            ' name=' .. tostring(selfEntity ~= nil and selfEntity.name or nil) ..
            ' serverId=' .. tostring(selfEntity ~= nil and selfEntity.serverId or nil) ..
            ' status=' .. tostring(selfEntity ~= nil and selfEntity.status or nil) ..
            ' type=' .. tostring(debug ~= nil and debug.type or nil) ..
            ' spawn=0x' .. string.format('%X', tonumber(debug ~= nil and debug.spawnFlags or 0) or 0) ..
            ' render0=0x' .. string.format('%X', tonumber(debug ~= nil and debug.renderFlags0 or 0) or 0) ..
            ' render1=0x' .. string.format('%X', tonumber(debug ~= nil and debug.renderFlags1 or 0) or 0) ..
            ' renderAll=' .. LibraPlatesFormatRenderFlags(selfIndex) ..
            ' mode=' .. tostring(probeGameMode.Resolve(selfIndex, false)) ..
            ' anonGuess=' .. tostring(probePlayerIndicators.HasAnonNameColor(selfIndex) == true) ..
            ' lpNameColorGuess=' .. LibraPlatesResolveNativeNameColorProbe(selfIndex) ..
            ' overwriteNativeNameColors=' .. tostring(targeting.GetSettings().overwriteNativeNameColors ~= false) ..
            ' useNativeNames=' .. tostring(targeting.GetSettings().hideNativeNamesOnLoad ~= true)
        );

        return;
    end

    if (subcommand == 'selfanonprobe' or subcommand == 'anonprobe') then
        LibraPlatesHandleSelfAnonProbe();
        return;
    end

    if (subcommand == 'heightprobe' or subcommand == 'plateheightprobe') then
        LibraPlatesHandleHeightProbe();
        return;
    end

    if (subcommand == 'petstate') then
        log.Info(petState.GetStatusText());
        return;
    end

    if (subcommand == 'petprobe') then
        local selfEntity = entities.GetSelf();
        local petIndex = entities.GetOwnPetTargetIndex();
        local mainJob = entities.GetPlayerMainJobId();
        local pet = entities.GetOwnDrgPet() or entities.GetOwnBstPet() or entities.GetOwnSmnPet() or entities.GetOwnPupPet() or entities.GetOwnLuopan();
        local debug = petIndex ~= nil and entities.GetEntityDebugInfo(petIndex, targeting.GetSettings().enemyPlateRange) or nil;
        local selfStatus = tonumber(selfEntity ~= nil and selfEntity.status or nil);
        local petStatus = tonumber(pet ~= nil and pet.status or nil);
        local restingTrigger = petStatus == 33 or selfStatus == 33;
        local petAnchorBone = (pet ~= nil and pet.petType == 'wyvern') and petPlate.GetWyvernAnchorBone(pet) or nil;
        local petWorldOffset = (pet ~= nil and pet.petType == 'wyvern') and petPlate.GetWyvernWorldOffsetY(pet) or nil;
        local petOverlayOffset = (pet ~= nil and pet.petType == 'wyvern') and petPlate.GetWyvernOverlayOffsetY(pet) or nil;

        log.Info(
            'Pet probe mainJob=' .. tostring(mainJob) ..
            ' selfStatus=' .. tostring(selfStatus) ..
            ' petIndex=' .. tostring(petIndex) ..
            ' petName=' .. tostring(pet ~= nil and pet.name or nil) ..
            ' petType=' .. tostring(pet ~= nil and pet.petType or nil) ..
            ' petServer=' .. tostring(pet ~= nil and pet.serverId or nil) ..
            ' petStatus=' .. tostring(petStatus) ..
            ' petHpPct=' .. tostring(pet ~= nil and pet.hpPercent or nil) ..
            ' petDistance=' .. tostring(pet ~= nil and pet.distance or nil) ..
            ' restingTrigger=' .. tostring(restingTrigger) ..
            ' petAnchorBone=' .. tostring(petAnchorBone) ..
            ' petWorldOffsetY=' .. tostring(petWorldOffset) ..
            ' petOverlayOffsetY=' .. tostring(petOverlayOffset) ..
            ' rawName=' .. tostring(debug ~= nil and debug.name or nil) ..
            ' rawType=' .. tostring(debug ~= nil and debug.type or nil) ..
            ' rawStatus=' .. tostring(debug ~= nil and debug.status or nil) ..
            ' spawn=0x' .. string.format('%X', tonumber(debug ~= nil and debug.spawnFlags or 0) or 0) ..
            ' render0=0x' .. string.format('%X', tonumber(debug ~= nil and debug.renderFlags0 or 0) or 0) ..
            ' render1=0x' .. string.format('%X', tonumber(debug ~= nil and debug.renderFlags1 or 0) or 0)
        );
        return;
    end

    if (subcommand == 'pupdebug') then
        log.Info(entities.GetOwnPupDebugText());
        return;
    end

    if (subcommand == 'restdebug') then
        local center = entities.GetSelfCanvasCenter(canvasDefaults.offsetX, canvasDefaults.offsetY);
        local global = state.GetGlobalSettings(globalDefaults);
        local resting = global.resting or {};

        if (center == nil) then
            log.Warn('Rest debug failed: self projection unavailable.');
            return;
        end

        log.Info(
            'Rest debug status=' .. tostring(center.status) ..
            ' hp=' .. tostring(center.hp) .. '/' .. tostring(center.maxHp) .. ' pct=' .. tostring(center.hpPercent) ..
            ' mp=' .. tostring(center.mp) .. '/' .. tostring(center.maxMp) .. ' pct=' .. tostring(center.mpPercent) ..
            ' enabled=' .. tostring(resting.enabled ~= false) ..
            ' display=' .. tostring(resting.displayMode or 'Bar') ..
            ' hideFullHp=' .. tostring(resting.hideAtFullHp == true) ..
            ' hideFullMp=' .. tostring(resting.hideAtFullMp == true)
        );
        return;
    end

    if (subcommand == 'buffdebug' or subcommand == 'statusdebug') then
        local selfEntity = entities.GetSelf();
        local liveState = 'Idle';
        local targetIndex = targeting.GetCurrentTargetIndex();
        local targetEntity = nil;

        if (selfEntity ~= nil and tonumber(selfEntity.status) == 1) then
            liveState = 'Combat';
        elseif (selfEntity ~= nil and tonumber(selfEntity.status) == 33) then
            liveState = 'Resting';
        end

        if (targetIndex ~= nil and targetIndex ~= 0) then
            local entityManager = AshitaCore:GetMemoryManager():GetEntity();

            if (entityManager ~= nil) then
                local ok = pcall(function()
                    targetEntity = {
                        index = targetIndex,
                        name = entityManager:GetName(targetIndex),
                        serverId = entityManager:GetServerId(targetIndex),
                    };
                end);

                if (ok ~= true) then
                    targetEntity = nil;
                end
            end
        end

        local buffsSettings = state.GetWidgetSettings('Self', liveState, 'Buffs', buffsDefaults);
        local debuffsSettings = state.GetWidgetSettings('Self', liveState, 'Debuffs', debuffsDefaults);
        local pcBuffsSettings = state.GetWidgetSettings('PC', 'Combat', 'Buffs', buffsDefaults);
        local pcDebuffsSettings = state.GetWidgetSettings('PC', 'Combat', 'Debuffs', debuffsDefaults);
        local targetServerId = targetEntity ~= nil and targetEntity.serverId or nil;

        log.Info(
            'Buff debug state=' .. tostring(liveState) ..
            ' selfStatus=' .. tostring(selfEntity ~= nil and selfEntity.status or nil) ..
            ' buffsEnabled=' .. tostring(buffsSettings ~= nil and buffsSettings.enabled == true) ..
            ' debuffsEnabled=' .. tostring(debuffsSettings ~= nil and debuffsSettings.enabled == true) ..
            ' buffsXY=' .. tostring(buffsSettings ~= nil and buffsSettings.offsetX or nil) .. ',' .. tostring(buffsSettings ~= nil and buffsSettings.offsetY or nil) ..
            ' debuffsXY=' .. tostring(debuffsSettings ~= nil and debuffsSettings.offsetX or nil) .. ',' .. tostring(debuffsSettings ~= nil and debuffsSettings.offsetY or nil) ..
            ' ' .. playerStatuses.GetSelfDebugText() ..
            ' target=' .. tostring(targetEntity ~= nil and targetEntity.name or nil) ..
            ' targetServer=' .. tostring(targetServerId) ..
            ' pcBuffsEnabled=' .. tostring(pcBuffsSettings ~= nil and pcBuffsSettings.enabled == true) ..
            ' pcDebuffsEnabled=' .. tostring(pcDebuffsSettings ~= nil and pcDebuffsSettings.enabled == true) ..
            ' ' .. partyStatuses.GetDebugText(targetServerId)
        );
        return;
    end

    if (subcommand == 'trustbuffdebug' or subcommand == 'truststatusdebug') then
        local action = tostring(args[3] or ''):lower();
        LogTrustBuffProbe(action == 'scan');
        return;
    end

    if (subcommand == 'luopanprobe' or subcommand == 'luopandebug') then
        local action = tostring(args[3] or 'status'):lower();
        local seconds = tonumber(args[4]);

        if (action == 'on' or action == 'start') then
            luopanStatuses.EnableProbe(seconds or 120);
            return;
        end

        if (action == 'off' or action == 'stop') then
            luopanStatuses.DisableProbe();
            return;
        end

        if (action == 'status' or action == '') then
            log.Info(luopanStatuses.GetProbeStatusText());
            return;
        end

        log.Info('Usage: /lp luopanprobe on [seconds] | off | status');
        return;
    end

        if (subcommand == 'enemystatusdebug' or subcommand == 'enemybuffdebug' or subcommand == 'enemydebuffdebug') then
        local action = tostring(args[3] or 'status'):lower();
        local seconds = tonumber(args[4]);
        local targetIndex = targeting.GetCurrentTargetIndex() or targeting.GetCurrentSubTargetIndex();
        local targetName = nil;
        local targetServerId = 0;
        local targetEnemy = nil;
        local targetEngaged = false;
        local geoRows = {};

        if (targetIndex ~= nil and targetIndex ~= 0) then
            local entityManager = AshitaCore:GetMemoryManager():GetEntity();

            if (entityManager ~= nil) then
                targetName = CommandSafeCall(nil, function() return entityManager:GetName(targetIndex); end);
                targetServerId = CommandSafeCall(0, function() return entityManager:GetServerId(targetIndex); end);
            end

            targetEnemy = entities.GetEnemy(targetIndex, true);
            targetEngaged = engagedEnemies.IsEngaged(targetIndex) == true;
            geoRows = enemyStatuses.GetGeoAuraDebuffRows(targetEnemy ~= nil and targetEnemy.distance or nil, targetEngaged);
        end

        if (action == 'on' or action == 'capture') then
            enemyStatuses.EnableDebugForSeconds(seconds or 20, targetServerId);
            log.Info(
                'Enemy status capture on for ' .. tostring(seconds or 20) ..
                ' seconds. target=' .. tostring(targetName) ..
                ' server=' .. tostring(targetServerId)
            );
            return;
        end

        if (action == 'off') then
            enemyStatuses.SetDebugEnabled(false);
            log.Info('Enemy status capture off.');
            return;
        end

        if (targetServerId == 0) then
            log.Warn('Enemy status debug failed: target an enemy first.');
            return;
        end

        log.Info(
            'Enemy target=' .. tostring(targetName) ..
            ' index=' .. tostring(targetIndex) ..
            ' server=' .. tostring(targetServerId) ..
            ' distance=' .. tostring(targetEnemy ~= nil and targetEnemy.distance or nil) ..
            ' engaged=' .. tostring(targetEngaged) ..
            ' geoRows=' .. tostring(#geoRows) ..
            ' ' .. enemyStatuses.GetDebugText(targetServerId)
        );
        return;
    end

    if (subcommand == 'fishingdebug' or subcommand == 'gatheringdebug' or subcommand == 'gathering') then
        local action = tostring(args[3] or 'status'):lower();

        if (action == 'test' or action == 'show') then
            targeting.ForceGatheringDisplay(args[4] or 'hatchet', tonumber(args[5]) or 8);
            log.Info('Gathering test display: ' .. targeting.GetGatheringDebugStatus());
            return;
        end

        if (action == 'trace') then
            local fishingModule = require('core.fishing');
            nativeTargetArrow.SetPartyTraceEnabled(true);
            fishingModule.EnablePacketDebugForSeconds(tonumber(args[4]) or 120);
            log.Info('Fishing native UI trace and packet debug started file=' .. nativeTargetArrow.GetPartyTraceFilePath() .. ' ' .. fishingModule.GetPacketDebugStatus());
            return;
        end

        if (action == 'barprobe' or action == 'probe') then
            nativeTargetArrow.StartFishingBarProbe(tonumber(args[4]) or 15);
            log.Info(nativeTargetArrow.GetFishingBarProbeStatusText());
            return;
        end

        if (action == 'packets') then
            local packetAction = tostring(args[4] or 'on'):lower();
            local fishingModule = require('core.fishing');

            if (packetAction == 'on') then
                fishingModule.EnablePacketDebugForSeconds(tonumber(args[5]) or 60);
                log.Info('Fishing packet debug on: ' .. fishingModule.GetPacketDebugStatus());
                return;
            end

            if (packetAction == 'off') then
                fishingModule.SetPacketDebugEnabled(false);
                log.Info('Fishing packet debug off: ' .. fishingModule.GetPacketDebugStatus());
                return;
            end

            if (packetAction == 'status') then
                log.Info('Fishing packet debug: ' .. fishingModule.GetPacketDebugStatus());
                return;
            end

            log.Info('Usage: /lp fishingdebug packets [on|off|status] [seconds]');
            return;
        end

        log.Info(
            'Fishing/gathering debug interact=' .. tostring(targeting.GetGatheringInteractStatus()) ..
            ' equip=' .. tostring(targeting.GetFishingEquipmentStatus()) ..
            ' gather=' .. tostring(targeting.GetGatheringDebugStatus()) ..
            ' party=' .. tostring(_G.LibraPlatesFormatPartySelfProbe ~= nil and _G.LibraPlatesFormatPartySelfProbe() or 'none') ..
            ' packets=' .. tostring(require('core.fishing').GetPacketDebugStatus()) ..
            ' ' .. worldMarkerProbe.GetStatusText()
        );
        return;
    end

    if (subcommand == 'recasts') then
        log.Info(abilityRecast.GetDebugText());
        return;
    end

    if (subcommand == 'castdebug') then
        local action = tostring(args[3] or 'on'):lower();
        local seconds = tonumber(args[4]);

        if (action == 'check' or action == 'probe') then
            local rawCommand = tostring(e.command or '');
            local probeCommand = rawCommand:gsub('^%s*%S+%s+%S+%s+%S+%s*', '', 1);

            if (probeCommand == '') then
                log.Info('Usage: /lp castdebug check /ma "Cure" <stpc>');
                return;
            end

            log.Info(targetActionRange.ProbeCommandText(probeCommand));
            return;
        end

        if (action == 'packets') then
            local packetAction = tostring(args[4] or 'on'):lower();
            local packetSeconds = tonumber(args[5]);

            if (packetAction == 'on') then
                targetActionRange.EnablePacketDebugForSeconds(packetSeconds or 20);
                log.Info('Cast packet debug on for ' .. tostring(packetSeconds or 20) .. ' seconds.');
                return;
            end

            if (packetAction == 'off') then
                targetActionRange.SetPacketDebugEnabled(false);
                log.Info('Cast packet debug off.');
                return;
            end

            if (packetAction == 'status') then
                log.Info('Cast packet debug enabled=' .. tostring(targetActionRange.GetPacketDebugEnabled()) .. '.');
                return;
            end

            log.Info('Usage: /lp castdebug packets on [seconds] | off | status');
            return;
        end

        if (action == 'tracker') then
            local trackerAction = tostring(args[4] or 'status'):lower();
            local trackerSeconds = tonumber(args[5]);

            if (trackerAction == 'on') then
                enemyCasts.EnableDebugForSeconds(trackerSeconds or 20);
                log.Info('Cast tracker capture on for ' .. tostring(trackerSeconds or 20) .. ' seconds.');
                return;
            end

            if (trackerAction == 'off') then
                enemyCasts.SetDebugEnabled(false);
                log.Info('Cast tracker capture off.');
                return;
            end

            if (trackerAction == 'status') then
                log.Info(enemyCasts.GetDebugText());
                return;
            end

            log.Info('Usage: /lp castdebug tracker on [seconds] | off | status');
            return;
        end

        if (action == 'on') then
            targetActionRange.EnableDebugForSeconds(seconds or 20);
            log.Info('Cast range debug on for ' .. tostring(seconds or 20) .. ' seconds.');
            return;
        end

        if (action == 'off') then
            targetActionRange.SetDebugEnabled(false);
            log.Info('Cast range debug off.');
            return;
        end

        if (action == 'status') then
            log.Info(targetActionRange.GetDebugText());
            log.Info(targetActionRange.GetQueuedActionText());
            log.Info('Cast packet debug enabled=' .. tostring(targetActionRange.GetPacketDebugEnabled()) .. '.');
            return;
        end

        log.Info('Usage: /lp castdebug on [seconds] | off | status | check /ma "Cure" <stpc> | packets on [seconds] | packets off | packets status | tracker on [seconds] | tracker off | tracker status');
        return;
    end

    if (subcommand == 'aoedebug') then
        log.Info(aoeNameHighlight.GetDebugText());
        return;
    end

    if (subcommand == 'mogjobdebug' or subcommand == 'mogdebug') then
        local action = tostring(args[3] or 'status'):lower();
        local seconds = tonumber(args[4]);

        if (action == 'on') then
            mogJobDebug.EnableForSeconds(seconds or 20);
            return;
        end

        if (action == 'off') then
            mogJobDebug.SetEnabled(false);
            log.Info('Mog job debug off.');
            return;
        end

        if (action == 'status') then
            log.Info(mogJobDebug.GetDebugText());
            return;
        end

        log.Info('Usage: /lp mogjobdebug on [seconds] | off | status');
        return;
    end

    if (subcommand == 'jobchange' or subcommand == 'job') then
        local action = tostring(args[3] or 'status');
        local actionLower = action:lower();

        if (actionLower == 'status') then
            log.Info(jobChange.GetStatusText());
            return;
        end

        if (actionLower == 'cancel' or actionLower == 'off') then
            jobChange.Cancel();
            log.Info('Queued job change cancelled.');
            return;
        end

        local success = false;
        local err = nil;

        if (actionLower == 'main') then
            success, err = jobChange.ChangeJobs(args[4], nil);
        elseif (actionLower == 'sub') then
            success, err = jobChange.ChangeJobs(nil, args[4]);
        else
            local pair = tostring(args[3] or ''):gsub('\\', '/');
            local slashIndex = pair:find('/', 1, true);

            if (slashIndex ~= nil) then
                local mainJob = pair:sub(1, slashIndex - 1);
                local subJob = pair:sub(slashIndex + 1);
                success, err = jobChange.ChangeJobs(mainJob ~= '' and mainJob or nil, subJob ~= '' and subJob or nil);
            else
                success, err = jobChange.ChangeJobs(action, nil);
            end
        end

        if (success ~= true) then
            local message = tostring(err or 'Job change failed.');

            if (message == 'No change required.') then
                log.Info(message);
            else
                log.Warn(message);
                log.Info('Usage: /lp jobchange WAR | main WAR | sub NIN | PUP/COR | status | cancel');
            end
        end
        return;
    end

    if (subcommand == 'mousemove' or subcommand == 'mousecontrols') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            mouseControls.SetBothButtonForwardEnabled(true);
        elseif (value == 'off') then
            mouseControls.SetBothButtonForwardEnabled(false);
        elseif (value == 'status' or value == '') then
            log.Info('Both-button forward enabled=' .. tostring(mouseControls.GetBothButtonForwardEnabled()));
            return;
        else
            mouseControls.SetBothButtonForwardEnabled(not mouseControls.GetBothButtonForwardEnabled());
        end

        state.Save();
        log.Info('Both-button forward enabled=' .. tostring(mouseControls.GetBothButtonForwardEnabled()));
        return;
    end

    if (subcommand == 'mousesteer') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            mouseControls.SetBothButtonSteerEnabled(true);
        elseif (value == 'off') then
            mouseControls.SetBothButtonSteerEnabled(false);
        elseif (value == 'status' or value == '') then
            log.Info('Both-button steer enabled=' .. tostring(mouseControls.GetBothButtonSteerEnabled()));
            return;
        else
            mouseControls.SetBothButtonSteerEnabled(not mouseControls.GetBothButtonSteerEnabled());
        end

        state.Save();
        log.Info('Both-button steer enabled=' .. tostring(mouseControls.GetBothButtonSteerEnabled()));
        return;
    end

    if (subcommand == 'mouseinvert') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            mouseControls.SetInvertSteer(true);
        elseif (value == 'off') then
            mouseControls.SetInvertSteer(false);
        elseif (value == 'status' or value == '') then
            log.Info('Mouse steer inverted=' .. tostring(mouseControls.GetInvertSteer()));
            return;
        else
            mouseControls.SetInvertSteer(not mouseControls.GetInvertSteer());
        end

        state.Save();
        log.Info('Mouse steer inverted=' .. tostring(mouseControls.GetInvertSteer()));
        return;
    end

    if (subcommand == 'config' or subcommand == 'settings') then
        state.SetConfigOpen(not state.GetConfigOpen());
        return;
    end

    if (subcommand == 'depthbridge') then
        occlusion.PrintStatus();
        return;
    end

    if (subcommand == 'depthtest') then
        local center = entities.GetSelfCanvasCenter(canvasDefaults.offsetX, canvasDefaults.offsetY);

        if (center == nil) then
            log.Warn('Depth test failed: self projection unavailable.');
            return;
        end

        local result, err, nativeStatus = occlusion.TestScreenPoint(
            center.boneScreenX,
            center.boneScreenY,
            center.boneScreenZ,
            canvasDefaults.occlusion
        );

        if (result == nil) then
            log.Warn(string.format(
                'Depth test failed: screen=%s,%s projectedDepth=%s error=%s %s',
                tostring(center.boneScreenX),
                tostring(center.boneScreenY),
                tostring(center.boneScreenZ),
                tostring(err),
                occlusion.FormatNativeStatus(nativeStatus)
            ));
            return;
        end

        log.Info(string.format(
            'Depth test: screen=%s,%s projectedDepth=%s sampledDepth=%s occluded=%s source=%s %s',
            tostring(center.boneScreenX),
            tostring(center.boneScreenY),
            tostring(result.projectedDepth),
            tostring(result.sampledDepth),
            tostring(result.occluded),
            tostring(result.source),
            occlusion.FormatNativeStatus(nativeStatus)
        ));
        return;
    end

    if (subcommand == 'fpsobserve') then
        local action = tostring(args[3] or 'status'):lower();

        if (action == 'on') then
            adaptivePerformance.SetEnabled(true);
        elseif (action == 'off') then
            adaptivePerformance.SetEnabled(false);
        end

        log.Info(adaptivePerformance.GetStatusText());
        return;
    end

    if (subcommand == 'fpsmode') then
        local mode = tostring(args[3] or ''):lower();

        if (mode == 'auto' or mode == 'quality' or mode == 'smooth' or mode == 'fps1' or mode == 'light') then
            adaptivePerformance.SetSelectedMode(mode);
        end

        log.Info(adaptivePerformance.GetStatusText());
        return;
    end

    if (subcommand == 'fpsstatus') then
        log.Info(adaptivePerformance.GetStatusText());
        return;
    end

    if (subcommand == 'imgui') then
        local imguiApi = require('imgui');
        local names = T{
            'PushFont',
            'PopFont',
            'SetWindowFontScale',
            'SetWindowFontSize',
            'SetWindowScale',
            'GetFont',
            'GetFontBaked',
            'GetFontSize',
        };
        local parts = T{};

        for _, name in ipairs(names) do
            parts:append(tostring(name) .. '=' .. tostring(type(imguiApi[name])));
        end

        log.Info('ImGui API: ' .. table.concat(parts, ' '));
        return;
    end

    if (subcommand == 'cursor') then
        local action = tostring(args[3] or 'toggle'):lower();

        if (action == 'on') then
            cursorOverlay.SetEnabled(true);
        elseif (action == 'off') then
            cursorOverlay.SetEnabled(false);
        elseif (action == 'toggle') then
            cursorOverlay.Toggle();
        end

        state.Save();
        log.Info('Cursor overlay enabled=' .. tostring(cursorOverlay.GetEnabled()));
        return;
    end

    log.Info('Commands: /lp config, /lp petprobe, /lp perf on, /lp perf detail on, /lp isolate status, /lp diag start, /lp diag scenario target-on, /lp diag restore, /lp world on, /lp world off, /lp mousemove on, /lp mousesteer on, /lp bridge status, /lp depthbridge, /lp depthtest, /lp castdebug on [seconds], /lp fpsstatus, /lp imgui, /lp cursor on');
end

return commands;
