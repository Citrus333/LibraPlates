local ffi = require('ffi');
local ffi = require('ffi');
local bit = require('bit');
local imgui = require('imgui');
local state = require('core.state');
local log = require('core.log');
local entities = require('core.entities');
local statusEffects = require('core.status_effects');
local fonts = require('core.fonts');
local textScale = require('core.text_scale');
local alertSounds = require('core.alert_sounds');
local gdiTextTexture = require('ui.gdi_text_texture');
local globalDefaults = require('config.global');

local enemyAlerts = {};
local alerts = {};
local lastDebug = 'Enemy Alerts has not seen an action yet.';
local debugEnabled = false;
local debugUntil = nil;
local previewEnabled = false;
local previewRenderedFrame = nil;
local layoutPreviewEditDrag = nil;
local testAlertIndex = 0;
local lastPetTextAlert = nil;

local function SafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function GetSettings()
    local global = state.GetGlobalSettings(globalDefaults);

    if (type(global.enemyAlerts) ~= 'table') then
        global.enemyAlerts = {};
    end

    local settings = global.enemyAlerts;
    local defaults = globalDefaults.enemyAlerts or {};

    for key, value in pairs(defaults) do
        if (settings[key] == nil) then
            settings[key] = value;
        end
    end
    if (settings.customTriggers == defaults.customTriggers) then
        settings.customTriggers = {};
    end

    return settings;
end

local function IsEnabled()
    return GetSettings().enabled == true;
end

local function IsDebugEnabled()
    if (debugUntil ~= nil and os.clock() >= debugUntil) then
        debugEnabled = false;
        debugUntil = nil;
    end

    return debugEnabled == true;
end

local function GetEntityManager()
    local memory = AshitaCore:GetMemoryManager();

    if (memory == nil) then
        return nil;
    end

    return memory:GetEntity();
end

local function GetIndexFromServerId(serverId)
    serverId = tonumber(serverId) or 0;

    if (serverId == 0) then
        return 0;
    end

    local entityManager = GetEntityManager();

    if (entityManager == nil) then
        return 0;
    end

    for index = 1, 0x8FF do
        if (SafeCall(0, function() return entityManager:GetServerId(index); end) == serverId) then
            return index;
        end
    end

    return 0;
end

local function GetEntityName(index)
    local ent = nil;

    if (tonumber(index) ~= nil and tonumber(index) > 0) then
        ent = SafeCall(nil, function() return GetEntity(index); end);
    end

    local name = tostring(ent ~= nil and ent.Name or ''):gsub('\170', '');
    name = name:gsub('%c', ''):gsub('^%s+', ''):gsub('%s+$', '');

    return name ~= '' and name or 'Enemy';
end

local function IsEnemyIndex(index)
    index = tonumber(index) or 0;

    if (index == 0) then
        return false;
    end

    return entities.GetEnemy(index, true) ~= nil;
end

local function GetResourceNameValue(value)
    if (value == nil) then
        return nil;
    end

    if (type(value) == 'string') then
        return value;
    end

    local ok, result = pcall(function()
        return ffi.string(value);
    end);

    if (ok == true and result ~= nil and result ~= '') then
        return result;
    end

    return nil;
end

local function GetResourceName(resource, fallback)
    if (resource == nil) then
        return tostring(fallback or '');
    end

    if (resource.Name ~= nil) then
        local name = GetResourceNameValue(resource.Name[1]) or GetResourceNameValue(resource.Name[2]);

        if (name ~= nil and name ~= '') then
            return name;
        end
    end

    return GetResourceNameValue(resource.En) or GetResourceNameValue(resource.Name) or tostring(fallback or '');
end

local function GetResource(methodName, actionId)
    local resourceManager = AshitaCore:GetResourceManager();

    if (resourceManager == nil or type(resourceManager[methodName]) ~= 'function') then
        return nil;
    end

    return SafeCall(nil, function()
        return resourceManager[methodName](resourceManager, actionId);
    end);
end

local function ReadResourceNumber(resource, keys)
    if (resource == nil) then
        return nil;
    end

    for _, key in ipairs(keys) do
        local value = tonumber(resource[key]);

        if (value ~= nil) then
            return value;
        end
    end

    return nil;
end

local function HasTargetFlag(flags, flag)
    flags = tonumber(flags) or 0;
    flag = tonumber(flag) or 0;

    if (flags <= 0 or flag <= 0 or bit == nil or bit.band == nil) then
        return false;
    end

    return bit.band(flags, flag) ~= 0;
end

local function ClassifyMagicResource(resource)
    local statusId = ReadResourceNumber(resource, { 'Status', 'status', 'StatusId', 'statusId', 'StatusID', 'status_id' });
    local targets = ReadResourceNumber(resource, { 'Targets', 'targets', 'Target', 'target' });

    if (statusEffects.IsBuff(statusId) == true) then
        return 'defensive';
    end

    if (statusEffects.IsDebuff(statusId) == true) then
        return 'offensive';
    end

    if (targets == 1 or targets == 2 or targets == 3 or HasTargetFlag(targets, 1) == true or HasTargetFlag(targets, 2) == true) then
        return 'defensive';
    end

    return 'offensive';
end

local function ResolveSpellByName(name)
    local resourceManager = AshitaCore:GetResourceManager();
    name = tostring(name or ''):gsub('^%s*(.-)%s*$', '%1');

    if (resourceManager == nil or name == '') then
        return nil;
    end

    local methods = {
        { name },
        { name, 0 },
        { name, 1 },
    };

    for _, args in ipairs(methods) do
        local resource = SafeCall(nil, function()
            return resourceManager:GetSpellByName(unpack(args));
        end);

        if (resource ~= nil) then
            return resource;
        end
    end

    return nil;
end

local function ResolveAction(kind, actionType, packetParam, actionParam)
    local ids = { tonumber(actionParam) or 0, tonumber(packetParam) or 0 };
    local methods = nil;

    if (kind == 'MA') then
        methods = { 'GetSpellById' };
    elseif (tonumber(actionType) == 7) then
        methods = { 'GetWeaponSkillById', 'GetMobSkillById', 'GetAbilityById' };
    else
        methods = { 'GetAbilityById', 'GetMobSkillById', 'GetWeaponSkillById', 'GetSpellById' };
    end

    for _, id in ipairs(ids) do
        if (id > 0) then
            for _, methodName in ipairs(methods) do
                local resource = GetResource(methodName, id);

                if (resource ~= nil) then
                    return {
                        name = GetResourceName(resource, id),
                        id = id,
                        method = methodName,
                        resource = resource,
                        magicClass = (kind == 'MA') and ClassifyMagicResource(resource) or nil,
                    };
                end
            end
        end
    end

    return nil;
end

local function ParseActionPacket(e)
    if (e == nil or e.id ~= 0x0028 or e.data_raw == nil or ashita.bits == nil) then
        return nil;
    end

    local bitData = e.data_raw;
    local bitOffset = 40;
    local maxLength = (tonumber(e.size) or 0) * 8;

    local function UnpackBits(length)
        if ((bitOffset + length) >= maxLength) then
            maxLength = 0;
            return 0;
        end

        local value = ashita.bits.unpack_be(bitData, 0, bitOffset, length);
        bitOffset = bitOffset + length;
        return value;
    end

    local packet = {
        UserId = UnpackBits(32),
        Targets = {},
    };
    packet.UserIndex = GetIndexFromServerId(packet.UserId);

    local targetCount = UnpackBits(6);
    bitOffset = bitOffset + 4;
    packet.Type = UnpackBits(4);

    if (packet.Type == 8 or packet.Type == 9) then
        packet.Param = UnpackBits(16);
        packet.SpellGroup = UnpackBits(16);
    else
        packet.Param = UnpackBits(32);
    end

    packet.Recast = UnpackBits(32);

    for _ = 1, targetCount do
        local target = {
            Id = UnpackBits(32),
            Actions = {},
        };
        local actionCount = UnpackBits(4);

        if (actionCount == 0) then
            break;
        end

        for _ = 1, actionCount do
            local action = {};
            action.Reaction = UnpackBits(5);
            action.Animation = UnpackBits(12);
            action.SpecialEffect = UnpackBits(7);
            action.Knockback = UnpackBits(3);
            action.Param = UnpackBits(17);
            action.Message = UnpackBits(10);
            action.Flags = UnpackBits(31);

            if (UnpackBits(1) == 1) then
                action.AdditionalEffect = {
                    Damage = UnpackBits(10),
                    Param = UnpackBits(17),
                    Message = UnpackBits(10),
                };
            end

            if (UnpackBits(1) == 1) then
                action.SpikesEffect = {
                    Damage = UnpackBits(10),
                    Param = UnpackBits(14),
                    Message = UnpackBits(10),
                };
            end

            target.Actions[#target.Actions + 1] = action;
        end

        packet.Targets[#packet.Targets + 1] = target;
    end

    if (maxLength == 0) then
        return nil;
    end

    return packet;
end

local function GetSoundPlaybackVolume(value)
    value = tonumber(value) or 10;
    if (value > 10) then
        value = math.ceil(value / 10);
    end

    value = math.max(1, math.min(10, value));
    return value * 10;
end

local function GetLaneSettings(settings, lane)
    local soundVolume = GetSoundPlaybackVolume(settings.soundVolume);
    local fallbackSoundFile = alertSounds.ResolveFile(settings.soundFile, 'Alert01.wav');
    local resolveSoundFile = function(fileName)
        return alertSounds.ResolveFile(fileName, fallbackSoundFile);
    end

    if (lane == 'offensive') then
        return {
            enabled = settings.offensiveMagicEnabled ~= false,
            color = settings.offensiveColor or settings.color,
            outlineColor = settings.offensiveOutlineColor or settings.outlineColor,
            fontSize = tonumber(settings.offensiveFontSize) or tonumber(settings.fontSize) or 34,
            offsetX = tonumber(settings.offensiveOffsetX) or 0,
            offsetY = tonumber(settings.offensiveOffsetY) or 88,
            soundEnabled = settings.offensiveSoundEnabled == true,
            soundFile = resolveSoundFile(settings.offensiveSoundFile),
            soundVolume = soundVolume,
        };
    elseif (lane == 'defensive') then
        return {
            enabled = settings.defensiveMagicEnabled ~= false,
            color = settings.defensiveColor or settings.color,
            outlineColor = settings.defensiveOutlineColor or settings.outlineColor,
            fontSize = tonumber(settings.defensiveFontSize) or tonumber(settings.fontSize) or 30,
            offsetX = tonumber(settings.defensiveOffsetX) or 0,
            offsetY = tonumber(settings.defensiveOffsetY) or 44,
            soundEnabled = settings.defensiveSoundEnabled == true,
            soundFile = resolveSoundFile(settings.defensiveSoundFile),
            soundVolume = soundVolume,
        };
    elseif (lane == 'ability') then
        return {
            enabled = settings.showAbilities == true,
            color = settings.abilityColor or settings.color,
            outlineColor = settings.abilityOutlineColor or settings.outlineColor,
            fontSize = tonumber(settings.abilityFontSize) or tonumber(settings.fontSize) or 34,
            offsetX = tonumber(settings.abilityOffsetX) or 0,
            offsetY = tonumber(settings.abilityOffsetY) or 0,
            soundEnabled = settings.abilitySoundEnabled == true,
            soundFile = resolveSoundFile(settings.abilitySoundFile),
            soundVolume = soundVolume,
        };
    elseif (lane == 'pet') then
        return {
            enabled = settings.petAlertsEnabled ~= false,
            color = settings.petColor or { 0.72, 1.0, 0.58, 1.0 },
            outlineColor = settings.petOutlineColor or settings.outlineColor,
            fontSize = tonumber(settings.petFontSize) or 32,
            offsetX = tonumber(settings.petOffsetX) or 0,
            offsetY = tonumber(settings.petOffsetY) or -44,
            soundEnabled = settings.petSoundEnabled == true,
            soundFile = resolveSoundFile(settings.petSoundFile),
            soundVolume = soundVolume,
        };
    elseif (lane == 'custom') then
        return {
            enabled = settings.customAlertsEnabled ~= false,
            color = settings.customColor or { 1.0, 0.95, 0.35, 1.0 },
            outlineColor = settings.customOutlineColor or settings.outlineColor,
            fontSize = tonumber(settings.customFontSize) or 34,
            offsetX = tonumber(settings.customOffsetX) or 0,
            offsetY = tonumber(settings.customOffsetY) or 176,
            soundEnabled = settings.customSoundEnabled == true,
            soundFile = resolveSoundFile(settings.customSoundFile),
            soundVolume = soundVolume,
        };
    elseif (lane == 'builtIn') then
        return {
            enabled = true,
            color = settings.builtInColor or { 0.65, 0.90, 1.0, 1.0 },
            outlineColor = settings.builtInOutlineColor or settings.outlineColor,
            fontSize = tonumber(settings.builtInFontSize) or 30,
            offsetX = tonumber(settings.builtInOffsetX) or 0,
            offsetY = tonumber(settings.builtInOffsetY) or 132,
            soundEnabled = settings.builtInSoundEnabled == true,
            soundFile = resolveSoundFile(settings.builtInSoundFile),
            soundVolume = soundVolume,
        };
    end

    return {
        enabled = true,
        color = settings.color,
        outlineColor = settings.outlineColor,
        fontSize = tonumber(settings.fontSize) or 32,
        offsetX = 0,
        offsetY = 0,
        soundEnabled = settings.soundEnabled == true,
        soundFile = fallbackSoundFile,
        soundVolume = soundVolume,
    };
end

local function GetAlertPriority(lane)
    lane = tostring(lane or '');

    if (lane == 'custom') then return 1; end
    if (lane == 'offensive') then return 2; end
    if (lane == 'ability') then return 3; end
    if (lane == 'pet') then return 4; end
    if (lane == 'defensive') then return 5; end
    if (lane == 'builtIn') then return 6; end

    return 7;
end

local function GetMaxVisibleAlerts(settings)
    return math.max(1, math.min(12, math.floor((tonumber(settings.maxVisibleAlerts) or 4) + 0.5)));
end

local function TrimAlertsToLimit(settings)
    local maxVisibleAlerts = GetMaxVisibleAlerts(settings);

    while (#alerts > maxVisibleAlerts) do
        local removeIndex = 1;

        if (settings.dropLowerPriorityAlerts ~= false) then
            local worstPriority = -1;
            local oldestStart = math.huge;

            for index, alert in ipairs(alerts) do
                local priority = GetAlertPriority(alert.lane);
                local startTime = tonumber(alert.startTime) or 0;

                if (priority > worstPriority or (priority == worstPriority and startTime < oldestStart)) then
                    worstPriority = priority;
                    oldestStart = startTime;
                    removeIndex = index;
                end
            end
        end

        table.remove(alerts, removeIndex);
    end
end

local function PushAlert(kind, lane, actorName, actionName, options)
    local settings = GetSettings();
    local laneSettings = GetLaneSettings(settings, lane);
    options = options or {};

    if (laneSettings.enabled ~= true and options.force ~= true) then
        return;
    end

    local now = os.clock();
    local duration = math.max(0.5, tonumber(settings.duration) or 3.0);
    local fadeDuration = math.max(0.0, tonumber(settings.fadeDuration) or 0.0);
    local verb = (kind == 'MA') and 'starts casting' or 'uses';
    local text = tostring(options.text or (tostring(actorName or 'Enemy') .. ' ' .. verb .. ' ' .. tostring(actionName or '')));
    local stackKey = tostring(lane or 'default') .. '\30' .. tostring(kind or 'Alert') .. '\30';
    local stackAction = tostring(actionName or ''):gsub('^%s*(.-)%s*$', '%1');

    if (stackAction ~= '') then
        stackKey = stackKey .. stackAction:lower();
    else
        stackKey = stackKey .. text:lower();
    end

    if (settings.stackDuplicateAlerts ~= false and options.noStack ~= true) then
        for _, alert in ipairs(alerts) do
            if (alert.stackKey == stackKey and (tonumber(alert.fadeEnds) or 0) > now) then
                alert.stackCount = (tonumber(alert.stackCount) or 1) + 1;
                alert.text = tostring(alert.baseText or alert.text or text) .. ' x' .. tostring(alert.stackCount);
                alert.startTime = now;
                alert.expires = now + duration;
                alert.fadeEnds = now + duration + fadeDuration;
                alert.alpha = 1.0;

                local stackedSoundPlayed = false;
                local stackedSoundFile = options.soundFile or laneSettings.soundFile;
                if (settings.replayStackedAlertSounds == true) then
                    local stackedSoundEnabled = laneSettings.soundEnabled == true;
                    if (options.soundEnabled ~= nil) then
                        stackedSoundEnabled = options.soundEnabled == true;
                    end
                    if (stackedSoundEnabled == true or options.forceSound == true) then
                        if (options.forceSound == true and stackedSoundFile == 'None') then
                            stackedSoundFile = alertSounds.ResolveFile('Alert01.wav', 'Alert01.wav');
                        end
                        stackedSoundPlayed = alertSounds.Play(stackedSoundFile, laneSettings.soundVolume);
                    end
                end

                return stackedSoundPlayed, stackedSoundFile;
            end
        end
    end

    alerts[#alerts + 1] = {
        kind = tostring(kind or 'Alert'),
        lane = tostring(lane or 'default'),
        text = text,
        baseText = text,
        stackKey = stackKey,
        stackCount = 1,
        startTime = now,
        expires = now + duration,
        fadeEnds = now + duration + fadeDuration,
        color = laneSettings.color,
        outlineColor = laneSettings.outlineColor,
        fontSize = laneSettings.fontSize,
        offsetX = laneSettings.offsetX,
        offsetY = laneSettings.offsetY,
    };

    local soundPlayed = false;
    local soundFile = options.soundFile or laneSettings.soundFile;
    local soundEnabled = laneSettings.soundEnabled == true;
    if (options.soundEnabled ~= nil) then
        soundEnabled = options.soundEnabled == true;
    end
    if (soundEnabled == true or options.forceSound == true) then
        if (options.forceSound == true and soundFile == 'None') then
            soundFile = alertSounds.ResolveFile('Alert01.wav', 'Alert01.wav');
        end
        soundPlayed = alertSounds.Play(soundFile, laneSettings.soundVolume);
    end

    TrimAlertsToLimit(settings);

    return soundPlayed, soundFile;
end

local function IsPetAlertWidgetEnabled(entityName, stateName)
    local widgetSettings = state.GetWidgetSettings(tostring(entityName or ''), tostring(stateName or ''), 'Alerts', { enabled = false });
    return widgetSettings ~= nil and widgetSettings.enabled == true;
end

local function GetPetAlertSource(packet)
    if (packet == nil) then
        return nil;
    end

    local userIndex = tonumber(packet.UserIndex);
    local userId = tonumber(packet.UserId);

    local smnPet = entities.GetOwnSmnPet();
    if (
        smnPet ~= nil and
        (tonumber(smnPet.index) == userIndex or tonumber(smnPet.serverId) == userId)
    ) then
        local stateName = smnPet.petType == 'spirit' and 'Spirit' or 'Avatar';
        if (IsPetAlertWidgetEnabled('Pet (SMN)', stateName) == true) then
            return {
                entity = 'Pet (SMN)',
                state = stateName,
                name = smnPet.name,
            };
        end
    end

    local bstPet = entities.GetOwnBstPet();
    if (
        bstPet ~= nil and
        (tonumber(bstPet.index) == userIndex or tonumber(bstPet.serverId) == userId)
    ) then
        if (
            IsPetAlertWidgetEnabled('Pet (BST)', 'Jug Pet') == true or
            IsPetAlertWidgetEnabled('Pet (BST)', 'Charmed Pet') == true
        ) then
            return {
                entity = 'Pet (BST)',
                state = 'Pet',
                name = bstPet.name,
            };
        end
    end

    return nil;
end

local function GetPetTextAlertSource(actorName)
    local actorText = tostring(actorName or '');
    local compactActor = actorText:gsub('%s+', '');

    if (compactActor == '') then
        return nil;
    end

    local smnPet = entities.GetOwnSmnPet();
    if (smnPet ~= nil) then
        local compactPetName = tostring(smnPet.name or ''):gsub('%s+', '');
        if (compactPetName == compactActor) then
            local stateName = smnPet.petType == 'spirit' and 'Spirit' or 'Avatar';
            if (IsPetAlertWidgetEnabled('Pet (SMN)', stateName) == true) then
                return { entity = 'Pet (SMN)', state = stateName, name = smnPet.name };
            end
        end
    end

    if (compactActor:match('Spirit$') ~= nil and IsPetAlertWidgetEnabled('Pet (SMN)', 'Spirit') == true) then
        return { entity = 'Pet (SMN)', state = 'Spirit', name = actorText };
    end

    local bstPet = entities.GetOwnBstPet();
    if (bstPet ~= nil and tostring(bstPet.name or ''):gsub('%s+', '') == compactActor) then
        if (
            IsPetAlertWidgetEnabled('Pet (BST)', 'Jug Pet') == true or
            IsPetAlertWidgetEnabled('Pet (BST)', 'Charmed Pet') == true
        ) then
            return { entity = 'Pet (BST)', state = 'Pet', name = bstPet.name };
        end
    end

    local drgPet = entities.GetOwnDrgPet();
    if (drgPet ~= nil and tostring(drgPet.name or ''):gsub('%s+', '') == compactActor) then
        if (IsPetAlertWidgetEnabled('Pet (DRG)', 'Wyvern') == true) then
            return { entity = 'Pet (DRG)', state = 'Wyvern', name = drgPet.name };
        end
    end

    local pupPet = entities.GetOwnPupPet();
    if (pupPet ~= nil and tostring(pupPet.name or ''):gsub('%s+', '') == compactActor) then
        if (IsPetAlertWidgetEnabled('Pet (PUP)', 'Automaton') == true) then
            return { entity = 'Pet (PUP)', state = 'Automaton', name = pupPet.name };
        end
    end

    return nil;
end

local function MatchPetTextAction(message, verb)
    local text = tostring(message or ''):gsub('^%s*(.-)%s*$', '%1');
    local actorName, actionName = text:match('^The%s+(.-)%s+' .. verb .. '%s+(.+)%s*$');

    if (actorName == nil or actionName == nil) then
        actorName, actionName = text:match('^(.-)%s+' .. verb .. '%s+(.+)%s*$');
    end

    if (actionName ~= nil) then
        actionName = tostring(actionName)
            :gsub('[%.!].*$', '')
            :gsub('%s+%d+%s*$', '')
            :gsub('^%s*(.-)%s*$', '%1');
        actionName = actionName:match('^(.+%a)') or actionName;
    end

    if (actorName ~= nil) then
        actorName = tostring(actorName):gsub('^%s*(.-)%s*$', '%1');
    end

    return actorName, actionName;
end

local function IsRecentPetTextDuplicate(actorName, actionName)
    local now = os.clock();
    local function NormalizeKeyPart(value)
        return tostring(value or '')
            :lower()
            :gsub('^the%s+', '')
            :gsub('[%.!]+', '')
            :gsub('%s+', ' ')
            :gsub('^%s*(.-)%s*$', '%1');
    end

    local key = NormalizeKeyPart(actorName) .. '\30' .. NormalizeKeyPart(actionName);

    if (
        lastPetTextAlert ~= nil and
        lastPetTextAlert.key == key and
        (now - (tonumber(lastPetTextAlert.time) or 0)) < 10.0
    ) then
        return true;
    end

    lastPetTextAlert = {
        key = key,
        time = now,
    };

    return false;
end

local function HandlePetTextAlert(message)
    local actorName, actionName = MatchPetTextAction(message, 'starts casting');
    local kind = 'MA';

    if (actorName == nil or actionName == nil) then
        actorName, actionName = MatchPetTextAction(message, 'uses');
        kind = 'JA';
    end

    if (actorName == nil or actionName == nil) then
        actorName, actionName = MatchPetTextAction(message, 'readies');
        kind = 'JA';
    end

    if (actorName == nil or actionName == nil) then
        return false;
    end

    local petSource = GetPetTextAlertSource(actorName);
    if (petSource == nil) then
        return false;
    end

    if (IsRecentPetTextDuplicate(actorName, actionName) == true) then
        return true;
    end

    PushAlert(kind, 'pet', petSource.name or actorName, actionName);
    lastDebug = 'text-pet entity=' .. tostring(petSource.entity) .. ' state=' .. tostring(petSource.state) .. ' actor=' .. tostring(actorName) .. ' action=' .. tostring(actionName);
    if (IsDebugEnabled() == true) then
        log.Info('Enemy Alerts: ' .. lastDebug);
    end

    return true;
end

local function HandlePetActionPacket(packet, settings)
    local petSource = GetPetAlertSource(packet);
    if (petSource == nil) then
        return false;
    end

    local firstAction = packet.Targets[1] ~= nil and packet.Targets[1].Actions[1] or nil;
    local actionParam = firstAction ~= nil and firstAction.Param or nil;
    local message = firstAction ~= nil and firstAction.Message or nil;
    local kind = nil;

    if (packet.Type == 8) then
        kind = 'MA';
    elseif (
        packet.Type ~= 1 and
        packet.Type ~= 4 and
        packet.Type ~= 8 and
        packet.Type ~= 9 and
        packet.Type ~= 11
    ) then
        kind = 'JA';
    end

    if (kind == nil) then
        return false;
    end

    local actionInfo = ResolveAction(kind, packet.Type, packet.Param, actionParam);
    local actionName = actionInfo ~= nil and actionInfo.name or nil;
    local actorName = tostring(petSource.name or GetEntityName(packet.UserIndex) or 'Pet');

    if (actionName == nil or actionName == '') then
        return true;
    end

    PushAlert(kind, 'pet', actorName, actionName);
    lastDebug = string.format(
        'pet action entity=%s state=%s type=%s actor=%s action=%s message=%s',
        tostring(petSource.entity),
        tostring(petSource.state),
        tostring(packet.Type),
        tostring(actorName),
        tostring(actionName),
        tostring(message)
    );

    if (IsDebugEnabled() == true) then
        log.Info('Enemy Alerts: ' .. lastDebug);
    end

    return true;
end

local function HandleActionPacket(packet)
    if (packet == nil or packet.UserId == nil) then
        return;
    end

    local settings = GetSettings();

    if (settings.enabled ~= true) then
        return;
    end

    if (IsEnemyIndex(packet.UserIndex) ~= true) then
        return;
    end

    local firstAction = packet.Targets[1] ~= nil and packet.Targets[1].Actions[1] or nil;
    local actionParam = firstAction ~= nil and firstAction.Param or nil;
    local message = firstAction ~= nil and firstAction.Message or nil;
    local kind = nil;

    if (packet.Type == 8 and settings.showMagic ~= false) then
        kind = 'MA';
    elseif (
        settings.showAbilities == true and
        packet.Type ~= 1 and
        packet.Type ~= 4 and
        packet.Type ~= 8 and
        packet.Type ~= 9 and
        packet.Type ~= 11
    ) then
        kind = 'JA';
    end

    if (kind == nil) then
        if (IsDebugEnabled() == true and packet.Type ~= 1 and packet.Type ~= 4 and packet.Type ~= 11) then
            lastDebug = string.format(
                'ignored enemy action type=%s user=%s index=%s packetParam=%s actionParam=%s message=%s',
                tostring(packet.Type),
                tostring(packet.UserId),
                tostring(packet.UserIndex),
                tostring(packet.Param),
                tostring(actionParam),
                tostring(message)
            );
            log.Info('Enemy Alerts: ' .. lastDebug);
        end
        return;
    end

    local actionInfo = ResolveAction(kind, packet.Type, packet.Param, actionParam);
    local actionName = actionInfo ~= nil and actionInfo.name or nil;
    local actionId = actionInfo ~= nil and actionInfo.id or nil;
    local methodName = actionInfo ~= nil and actionInfo.method or nil;
    local lane = (kind == 'MA') and (actionInfo ~= nil and actionInfo.magicClass or 'offensive') or 'ability';
    local actorName = GetEntityName(packet.UserIndex);

    lastDebug = string.format(
        'type=%s kind=%s lane=%s user=%s index=%s actor=%s packetParam=%s actionParam=%s message=%s action=%s id=%s method=%s',
        tostring(packet.Type),
        tostring(kind),
        tostring(lane),
        tostring(packet.UserId),
        tostring(packet.UserIndex),
        tostring(actorName),
        tostring(packet.Param),
        tostring(actionParam),
        tostring(message),
        tostring(actionName),
        tostring(actionId),
        tostring(methodName)
    );

    if (IsDebugEnabled() == true) then
        log.Info('Enemy Alerts: ' .. lastDebug);
    end

    return;
end

function enemyAlerts.HandlePacketIn(e)
    if (e == nil) then
        return;
    end

    if (e.id == 0x000A) then
        alerts = {};
        lastDebug = 'Enemy Alerts reset on zone.';
        return;
    end

    if (e.id ~= 0x0028) then
        return;
    end

    if (IsEnabled() ~= true) then
        alerts = {};
        return;
    end

    HandleActionPacket(ParseActionPacket(e));
end

local function StripControlCodes(text)
    return tostring(text or ''):gsub(string.char(0x1E) .. '.', ''):gsub('[%z\1-\31]', '');
end

local function TrimText(value)
    return tostring(value or ''):gsub('^%s*(.-)%s*$', '%1');
end

local function TrimTrailingNonLetters(value)
    value = tostring(value or '');
    return value:match('^(.+%a)') or value;
end

local function CustomTriggerMatches(message, trigger)
    if (type(trigger) ~= 'table' or trigger.enabled == false) then
        return false;
    end

    local matchText = TrimText(trigger.match);
    if (matchText == '') then
        return false;
    end

    local mode = tostring(trigger.mode or 'Contains');
    if (mode == 'Lua pattern') then
        local ok, result = pcall(function()
            return tostring(message or ''):match(matchText);
        end);

        return ok == true and result ~= nil;
    end

    return tostring(message or ''):lower():find(matchText:lower(), 1, true) ~= nil;
end

local function GetCustomTriggerSoundOptions(settings, trigger)
    local fallbackSoundFile = alertSounds.ResolveFile(settings.customSoundFile, settings.soundFile or 'Alert01.wav');
    local soundEnabled = settings.customSoundEnabled == true;

    if (type(trigger) == 'table' and trigger.soundEnabled ~= nil) then
        soundEnabled = trigger.soundEnabled == true;
    end

    return {
        soundEnabled = soundEnabled,
        soundFile = alertSounds.ResolveFile(type(trigger) == 'table' and trigger.soundFile or nil, fallbackSoundFile),
    };
end

local function HandleCustomTextAlert(message)
    local settings = GetSettings();
    if (settings.customAlertsEnabled == false or type(settings.customTriggers) ~= 'table') then
        return false;
    end

    for _, trigger in ipairs(settings.customTriggers) do
        if (CustomTriggerMatches(message, trigger) == true) then
            local displayText = TrimText(trigger.text);
            local soundOptions = GetCustomTriggerSoundOptions(settings, trigger);
            if (displayText == '') then
                displayText = TrimText(message);
            end

            PushAlert('Custom', 'custom', 'Custom', '', {
                text = displayText,
                force = true,
                soundEnabled = soundOptions.soundEnabled,
                soundFile = soundOptions.soundFile,
            });

            lastDebug = 'text-custom match=' .. tostring(trigger.match or '');
            if (IsDebugEnabled() == true) then
                log.Info('Enemy Alerts: ' .. lastDebug);
            end
            return true;
        end
    end

    return false;
end

local function GetBuiltInSoundOptions(settings, prefix)
    local fallbackSoundFile = alertSounds.ResolveFile(settings.builtInSoundFile, settings.soundFile or 'Alert01.wav');

    return {
        soundEnabled = settings[prefix .. 'SoundEnabled'] == true,
        soundFile = alertSounds.ResolveFile(settings[prefix .. 'SoundFile'], fallbackSoundFile),
    };
end

local function PushSystemAlert(label, text, soundPrefix)
    local settings = GetSettings();
    local soundOptions = GetBuiltInSoundOptions(settings, tostring(soundPrefix or 'builtIn'));

    PushAlert('System', 'builtIn', tostring(label or 'Alert'), '', {
        text = tostring(text or ''),
        force = true,
        soundEnabled = soundOptions.soundEnabled,
        soundFile = soundOptions.soundFile,
    });
end

function enemyAlerts.HandleTextIn(e)
    local settings = GetSettings();

    if (settings.enabled ~= true) then
        return;
    end

    local message = StripControlCodes(
        (e ~= nil and (e.message or e.text or e.original or e.modified or e.injected)) or ''
    );

    if (message == '') then
        return;
    end

    if (HandleCustomTextAlert(message) == true) then
        return;
    end

    if (HandlePetTextAlert(message) == true) then
        return;
    end

    if (settings.builtInWildkeeperEnabled ~= false) then
        local zone, notorious = message:match('members%-wembers in (.-) says that (.-) could appear anytime in the next 5 minutes');
        if (zone ~= nil and notorious ~= nil) then
            PushSystemAlert('Wildkeeper Reive', string.format('Wildkeeper Reive: %s in %s soon', notorious, zone), 'builtInWildkeeper');
            lastDebug = 'text-wildkeeper zone=' .. tostring(zone) .. ' notorious=' .. tostring(notorious);
            if (IsDebugEnabled() == true) then log.Info('Enemy Alerts: ' .. lastDebug); end
            return;
        end
    end

    if (settings.builtInCampaignEnabled ~= false) then
        local zone = message:match('Enemy forces are headed towards (.-)!');
        if (zone ~= nil and zone ~= '') then
            PushSystemAlert('Campaign', 'Campaign: enemy forces headed to ' .. zone, 'builtInCampaign');
            lastDebug = 'text-campaign zone=' .. tostring(zone);
            if (IsDebugEnabled() == true) then log.Info('Enemy Alerts: ' .. lastDebug); end
            return;
        end
    end

    if (settings.builtInVenturesEnabled ~= false) then
        local coord, zone = message:match('Hmm%.%.%. Something is interrupting ventures at %((.-)%) in (.-)%.%.%.');
        if (coord ~= nil and zone ~= nil) then
            zone = zone:gsub('^%s*(.-)%s*$', '%1');
            local displayText = string.format('VNM %s %s', zone, coord);
            PushSystemAlert('Ventures', displayText, 'builtInVentures');
            lastDebug = 'text-venture ' .. displayText;
            if (IsDebugEnabled() == true) then
                log.Info('Enemy Alerts: ' .. lastDebug);
            end
            return;
        end

        if (message:find('Hmm%.%.%. Something is interrupting ventures in these zones%.%.%.') ~= nil) then
            PushSystemAlert('Ventures', 'Ventures: something is interrupting ventures', 'builtInVentures');
            lastDebug = 'text-venture zones';
            if (IsDebugEnabled() == true) then log.Info('Enemy Alerts: ' .. lastDebug); end
            return;
        end
    end

    if (settings.builtInVoidwatchEnabled ~= false) then
        local linkshell, zone, coord, notorious = message:match('heroic deeds of (.-) have caused a Rift to appear in (.-) %((.-)%)! Champions, stop (.-)%.?s escape!');
        if (linkshell ~= nil and zone ~= nil and coord ~= nil and notorious ~= nil) then
            PushSystemAlert('Voidwatch', string.format('Voidwatch: %s in %s (%s)', notorious, zone, coord), 'builtInVoidwatch');
            lastDebug = 'text-voidwatch zone=' .. tostring(zone) .. ' coord=' .. tostring(coord);
            if (IsDebugEnabled() == true) then log.Info('Enemy Alerts: ' .. lastDebug); end
            return;
        end
    end

    if (settings.builtInBlueMagicEnabled ~= false) then
        local learnedSpell = message:match('>>> Learned new spell: %[([^%]]+)%]');
        if (learnedSpell ~= nil and learnedSpell ~= '') then
            local displayText = string.format('Learned Blue Spell: %s', learnedSpell);
            PushSystemAlert('Blue Magic', displayText, 'builtInBlueMagic');
            lastDebug = 'text-blue spell=' .. tostring(learnedSpell);
            if (IsDebugEnabled() == true) then
                log.Info('Enemy Alerts: ' .. lastDebug);
            end
            return;
        end
    end

    if (settings.builtInDynamisEnabled ~= false) then
        if (message:find('The sands of the prismatic hourglass have begun to fall%.') ~= nil) then
            PushSystemAlert('Dynamis', 'Dynamis: hourglass started', 'builtInDynamis');
            lastDebug = 'text-dynamis started';
            if (IsDebugEnabled() == true) then log.Info('Enemy Alerts: ' .. lastDebug); end
            return;
        end

        local dynamisMinutes = message:match('You have (%d+) minutes %(Earth time%) remaining in Dynamis%.');
        if (dynamisMinutes ~= nil) then
            PushSystemAlert('Dynamis', 'Dynamis: ' .. dynamisMinutes .. ' minutes remaining', 'builtInDynamis');
            lastDebug = 'text-dynamis remaining=' .. tostring(dynamisMinutes);
            if (IsDebugEnabled() == true) then log.Info('Enemy Alerts: ' .. lastDebug); end
            return;
        end

        local extendedMinutes = message:match('Your stay in Dynamis has been extended by (%d+) minutes%.');
        if (extendedMinutes ~= nil) then
            PushSystemAlert('Dynamis', 'Dynamis: +' .. extendedMinutes .. ' minutes', 'builtInDynamis');
            lastDebug = 'text-dynamis extended=' .. tostring(extendedMinutes);
            if (IsDebugEnabled() == true) then log.Info('Enemy Alerts: ' .. lastDebug); end
            return;
        end

        local prowess = message:match('Dynamis Prowess Increased!%s*(.+)');
        if (prowess ~= nil and prowess ~= '') then
            PushSystemAlert('Dynamis', 'Dynamis Prowess: ' .. prowess, 'builtInDynamis');
            lastDebug = 'text-dynamis prowess=' .. tostring(prowess);
            if (IsDebugEnabled() == true) then log.Info('Enemy Alerts: ' .. lastDebug); end
            return;
        end
    end

    if (settings.builtInIncursionEnabled ~= false) then
        local incursionMinutes = message:match('You have (%d+) minutes remaining inside this Incursion%.');
        if (incursionMinutes ~= nil) then
            PushSystemAlert('Incursion', 'Incursion: ' .. incursionMinutes .. ' minutes remaining', 'builtInIncursion');
            lastDebug = 'text-incursion remaining=' .. tostring(incursionMinutes);
            if (IsDebugEnabled() == true) then log.Info('Enemy Alerts: ' .. lastDebug); end
            return;
        end

        local incursionZone = message:match('Incursion %[([^%]]+)%] Begins!');
        if (incursionZone ~= nil and incursionZone ~= '') then
            PushSystemAlert('Incursion', 'Incursion begins: ' .. incursionZone, 'builtInIncursion');
            lastDebug = 'text-incursion begins=' .. tostring(incursionZone);
            if (IsDebugEnabled() == true) then log.Info('Enemy Alerts: ' .. lastDebug); end
            return;
        end

        local objective = message:match('New Objective:%s*(.+)');
        if (objective ~= nil and objective ~= '') then
            PushSystemAlert('Incursion', 'Incursion objective: ' .. objective, 'builtInIncursion');
            lastDebug = 'text-incursion objective=' .. tostring(objective);
            if (IsDebugEnabled() == true) then log.Info('Enemy Alerts: ' .. lastDebug); end
            return;
        end

        local boss = message:match('%(Boss:%s*(.+)%)');
        if (boss ~= nil and boss ~= '') then
            PushSystemAlert('Incursion', 'Incursion boss: ' .. boss, 'builtInIncursion');
            lastDebug = 'text-incursion boss=' .. tostring(boss);
            if (IsDebugEnabled() == true) then log.Info('Enemy Alerts: ' .. lastDebug); end
            return;
        end

        local phase = message:match('Incursion %[([^%]]+)%] Phase #(.+)');
        if (phase ~= nil and phase ~= '') then
            PushSystemAlert('Incursion', 'Incursion phase: ' .. phase, 'builtInIncursion');
            lastDebug = 'text-incursion phase=' .. tostring(phase);
            if (IsDebugEnabled() == true) then log.Info('Enemy Alerts: ' .. lastDebug); end
            return;
        end
    end

    if (settings.showAbilities ~= true) then
        actorName = nil;
        actionName = nil;
    end

    if (settings.showMagic ~= false) then
        local castActor, castSpell = message:match('^The (.-) starts casting (.-)[%.!]?$');
        if (castActor ~= nil and castSpell ~= nil) then
            castActor = TrimText(castActor);
            castSpell = TrimText(TrimTrailingNonLetters(castSpell));

            local spellResource = ResolveSpellByName(castSpell);
            local lane = (spellResource ~= nil and ClassifyMagicResource(spellResource)) or 'offensive';

            PushAlert('MA', lane, castActor, castSpell, {
                text = castActor .. ' starts casting ' .. castSpell,
            });

            lastDebug = 'text-magic lane=' .. tostring(lane) .. ' actor=' .. tostring(castActor) .. ' spell=' .. tostring(castSpell);
            if (IsDebugEnabled() == true) then
                log.Info('Enemy Alerts: ' .. lastDebug);
            end
            return;
        end
    end

    if (settings.showAbilities ~= true) then
        return;
    end

    local actorName, actionName = message:match('^The (.-) readies (.-)[%.!]?$');
    local verb = 'readies';

    if (actorName == nil or actionName == nil) then
        return;
    end

    actorName = TrimText(actorName);
    actionName = TrimText(TrimTrailingNonLetters(actionName));

    PushAlert('JA', 'ability', actorName, actionName, {
        text = actorName .. ' ' .. verb .. ' ' .. actionName,
    });

    lastDebug = 'text-ability verb=' .. tostring(verb) .. ' actor=' .. tostring(actorName) .. ' action=' .. tostring(actionName);
    if (IsDebugEnabled() == true) then
        log.Info('Enemy Alerts: ' .. lastDebug);
    end
end

local function ColorToU32(color)
    if (imgui.GetColorU32 ~= nil) then
        return imgui.GetColorU32(color);
    end

    return 0xFFFFFFFF;
end

local function DrawOutlinedText(drawList, x, y, color, outlineColor, fontSize, text, alpha)
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    alpha = math.max(0.0, math.min(1.0, tonumber(alpha) or 1.0));
    local textureId, textW, textH = gdiTextTexture.GetTexture(tostring(text or ''), {
        fontFamily = fonts.GetRole(globalSettings, false),
        fontFlags = fonts.GetRoleFlags(globalSettings, false),
        fontSize = textScale.ToTextureFontSize(fontSize, 32),
        color = color or { 1.0, 0.82, 0.16, 1.0 },
        outlineEnabled = true,
        outlineColor = outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = 3,
    });

    if (drawList == nil or drawList.AddImage == nil or textureId == nil or tonumber(textW) == nil or tonumber(textH) == nil) then
        return 0, 0;
    end

    drawList:AddImage(textureId, { x - ((tonumber(textW) or 0) * 0.5), y }, { x + ((tonumber(textW) or 0) * 0.5), y + (tonumber(textH) or 0) }, { 0, 0 }, { 1, 1 }, ColorToU32({ 1.0, 1.0, 1.0, alpha }));
    return tonumber(textW) or 0, tonumber(textH) or 0;
end

local function ReadImguiVec2(valueA, valueB)
    if (type(valueA) == 'table') then
        return tonumber(valueA.x or valueA.X or valueA[1]) or 0, tonumber(valueA.y or valueA.Y or valueA[2]) or 0;
    end

    return tonumber(valueA) or 0, tonumber(valueB) or 0;
end

local function GetMousePosition()
    if (imgui.GetIO == nil) then
        return nil, nil;
    end

    local ok, io = pcall(function()
        return imgui.GetIO();
    end);

    if (ok ~= true or io == nil or io.MousePos == nil) then
        return nil, nil;
    end

    return
        tonumber(io.MousePos.x or io.MousePos.X or io.MousePos[1]),
        tonumber(io.MousePos.y or io.MousePos.Y or io.MousePos[2]);
end

local function IsImguiCapturingMouse()
    if (imgui.GetIO == nil) then
        return false;
    end

    local ok, io = pcall(function()
        return imgui.GetIO();
    end);

    if (ok ~= true or io == nil) then
        return false;
    end

    return io.WantCaptureMouse == true or io.WantCaptureMouseUnlessPopupClose == true;
end

local function GetMouseDragDelta()
    if (imgui.GetMouseDragDelta == nil) then
        return 0, 0;
    end

    return ReadImguiVec2(imgui.GetMouseDragDelta(0));
end

local function GetLaneEditKeys(lane)
    if (lane == 'offensive') then
        return 'offensiveFontSize', 'offensiveOffsetX', 'offensiveOffsetY', 'Offensive magic';
    elseif (lane == 'defensive') then
        return 'defensiveFontSize', 'defensiveOffsetX', 'defensiveOffsetY', 'Defensive magic';
    elseif (lane == 'ability') then
        return 'abilityFontSize', 'abilityOffsetX', 'abilityOffsetY', 'Job abilities';
    elseif (lane == 'pet') then
        return 'petFontSize', 'petOffsetX', 'petOffsetY', 'Pet alerts';
    elseif (lane == 'custom') then
        return 'customFontSize', 'customOffsetX', 'customOffsetY', 'Custom alerts';
    elseif (lane == 'builtIn') then
        return 'builtInFontSize', 'builtInOffsetX', 'builtInOffsetY', 'Built-in alerts';
    end

    return 'fontSize', 'offsetX', 'offsetY', 'Screen Alerts';
end

local function DrawLinePreviewEditOverlay(settings, row, baseX, baseY, rowX, rowY, textW, textH, drawListOverride)
    if (
        settings.layoutPreviewEditFrame ~= true or
        (drawListOverride == nil and imgui.GetForegroundDrawList == nil) or
        imgui.GetColorU32 == nil or
        imgui.IsMouseClicked == nil or
        imgui.IsMouseDown == nil
    ) then
        layoutPreviewEditDrag = nil;
        return;
    end

    local lane = tostring((row ~= nil and row.lane) or 'default');
    local fontKey, offsetXKey, offsetYKey, label = GetLaneEditKeys(lane);
    local handleSize = 18;
    local pad = 6;
    local w = math.max(40, (tonumber(textW) or 40) + (pad * 2));
    local h = math.max(24, (tonumber(textH) or 24) + (pad * 2));
    local x = (tonumber(rowX) or 0) - (w * 0.5);
    local y = (tonumber(rowY) or 0) - pad;
    local mouseX, mouseY = GetMousePosition();
    local hitPad = 10;

    if (mouseX ~= nil and mouseY ~= nil and imgui.IsMouseClicked(0) == true and IsImguiCapturingMouse() ~= true) then
        local inRect = mouseX >= x and mouseX <= x + w and mouseY >= y and mouseY <= y + h;
        local inRightHandle = mouseX >= x + w - handleSize and mouseX <= x + w and mouseY >= y + h - handleSize and mouseY <= y + h;
        local inLeftHandle = mouseX >= x and mouseX <= x + handleSize and mouseY >= y + h - handleSize and mouseY <= y + h;

        if (inRightHandle == true or inLeftHandle == true or inRect == true) then
            local clickDistance = (inRightHandle == true or inLeftHandle == true) and 0 or math.abs(mouseY - (y + (h * 0.5)));

            if (layoutPreviewEditDrag == nil or layoutPreviewEditDrag.selecting == true and clickDistance < (tonumber(layoutPreviewEditDrag.clickDistance) or 999999)) then
                layoutPreviewEditDrag = {
                    lane = lane,
                    mode = inRightHandle == true and 'resize-right' or (inLeftHandle == true and 'resize-left' or 'move'),
                    selecting = true,
                    clickDistance = clickDistance,
                };
            end

            if (imgui.ResetMouseDragDelta ~= nil) then
                imgui.ResetMouseDragDelta(0);
            end
        end
    end

    if (imgui.IsMouseDown(0) ~= true) then
        layoutPreviewEditDrag = nil;
    elseif (imgui.IsMouseClicked(0) ~= true and layoutPreviewEditDrag ~= nil and layoutPreviewEditDrag.lane == lane) then
        layoutPreviewEditDrag.selecting = false;
        local dx, dy = GetMouseDragDelta();

        if (math.abs(dx) >= 0.5 or math.abs(dy) >= 0.5) then
            if (layoutPreviewEditDrag.mode == 'move') then
                settings[offsetXKey] = math.floor(((rowX + dx) - baseX) + 0.5);
                settings[offsetYKey] = math.floor(((rowY + dy) - baseY) + 0.5);
            else
                local nextW = layoutPreviewEditDrag.mode == 'resize-left' and math.max(40, w - dx) or math.max(40, w + dx);
                local scale = math.max(0.35, math.min(3.0, nextW / math.max(1, w)));
                settings[fontKey] = math.max(12, math.min(120, math.floor(((tonumber(settings[fontKey]) or tonumber(row.fontSize) or 34) * scale) + 0.5)));
            end

            state.Save();

            if (imgui.ResetMouseDragDelta ~= nil) then
                imgui.ResetMouseDragDelta(0);
            end
        end
    end

    local drawList = drawListOverride or imgui.GetForegroundDrawList();
    if (drawList == nil) then
        return;
    end

    local fillColor = imgui.GetColorU32({ 1.0, 0.80, 0.10, 0.20 });
    local borderColor = imgui.GetColorU32({ 1.0, 0.80, 0.10, 1.0 });
    local textColor = imgui.GetColorU32({ 1.0, 1.0, 1.0, 1.0 });
    local handleColor = imgui.GetColorU32({ 1.0, 1.0, 1.0, 0.82 });

    drawList:AddRectFilled({ x, y }, { x + w, y + h }, fillColor);
    drawList:AddRect({ x, y }, { x + w, y + h }, borderColor, 0, 0, 4);

    if (drawList.AddTriangleFilled ~= nil) then
        drawList:AddTriangleFilled({ x + w, y + h - handleSize }, { x + w, y + h }, { x + w - handleSize, y + h }, handleColor);
        drawList:AddTriangleFilled({ x, y + h - handleSize }, { x, y + h }, { x + handleSize, y + h }, handleColor);
        drawList:AddTriangle({ x + w, y + h - handleSize }, { x + w, y + h }, { x + w - handleSize, y + h }, borderColor, 2);
        drawList:AddTriangle({ x, y + h - handleSize }, { x, y + h }, { x + handleSize, y + h }, borderColor, 2);
    else
        drawList:AddRectFilled({ x + w - handleSize, y + h - handleSize }, { x + w, y + h }, handleColor);
        drawList:AddRect({ x + w - handleSize, y + h - handleSize }, { x + w, y + h }, borderColor, 0, 0, 2);
        drawList:AddRectFilled({ x, y + h - handleSize }, { x + handleSize, y + h }, handleColor);
        drawList:AddRect({ x, y + h - handleSize }, { x + handleSize, y + h }, borderColor, 0, 0, 2);
    end

    if (drawList.AddText ~= nil) then
        drawList:AddText({ x + 6, y + 6 }, textColor, label);
    end
end

local function GetViewportSize()
    local viewportW = 1920;
    local viewportH = 1080;

    pcall(function()
        local io = imgui.GetIO();
        if (io ~= nil and io.DisplaySize ~= nil) then
            viewportW = tonumber(io.DisplaySize.x or io.DisplaySize.X or io.DisplaySize[1]) or viewportW;
            viewportH = tonumber(io.DisplaySize.y or io.DisplaySize.Y or io.DisplaySize[2]) or viewportH;
        end
    end);

    return viewportW, viewportH;
end

local function DrawAlertRows(settings, rows, drawListOverride, viewportWidth, viewportHeight)
    local drawList = drawListOverride or (imgui.GetForegroundDrawList ~= nil and imgui.GetForegroundDrawList() or nil);

    if (drawList == nil) then
        return;
    end

    local viewportW = tonumber(viewportWidth) or 1920;
    local viewportH = tonumber(viewportHeight) or 1080;

    if (viewportWidth == nil or viewportHeight == nil) then
        viewportW, viewportH = GetViewportSize();
    end

    local x = (viewportW * 0.5) + (tonumber(settings.offsetX) or 0);
    local y = (viewportH * 0.28) + (tonumber(settings.offsetY) or 0);
    local pushedClip = false;

    if (previewEnabled ~= true and drawList.PushClipRect ~= nil and drawList.PopClipRect ~= nil) then
        drawList:PushClipRect({ 0, 0 }, { viewportW, viewportH }, false);
        pushedClip = true;
    end

    local laneCounts = {};

    for i = #rows, 1, -1 do
        local row = rows[i];
        local lane = tostring(row.lane or 'default');
        local duplicateIndex = laneCounts[lane] or 0;
        laneCounts[lane] = duplicateIndex + 1;
        local stackOffsetY = (previewEnabled == true) and 0 or (duplicateIndex * 44);
        local rowX = x + (tonumber(row.offsetX) or 0);
        local rowY = y + (tonumber(row.offsetY) or 0) + stackOffsetY;
        local textW, textH = DrawOutlinedText(drawList, rowX, rowY, row.color, row.outlineColor, row.fontSize, row.text, row.alpha);

        if (previewEnabled == true) then
            DrawLinePreviewEditOverlay(settings, row, x, y, rowX, rowY, textW, textH, drawList);
        end
    end

    if (pushedClip == true) then
        drawList:PopClipRect();
    end
end

local function BuildPreviewRows(settings)
    local offensive = GetLaneSettings(settings, 'offensive');
    local defensive = GetLaneSettings(settings, 'defensive');
    local ability = GetLaneSettings(settings, 'ability');
    local pet = GetLaneSettings(settings, 'pet');
    local custom = GetLaneSettings(settings, 'custom');
    local builtIn = GetLaneSettings(settings, 'builtIn');

    return {
        {
            text = 'Custom alert: example trigger matched',
            color = custom.color,
            outlineColor = custom.outlineColor,
            fontSize = custom.fontSize,
            offsetX = custom.offsetX,
            offsetY = custom.offsetY,
            lane = 'custom',
        },
        {
            text = 'Campaign: enemy forces headed to Jugner Forest [S]',
            color = builtIn.color,
            outlineColor = builtIn.outlineColor,
            fontSize = builtIn.fontSize,
            offsetX = builtIn.offsetX,
            offsetY = builtIn.offsetY,
            lane = 'builtIn',
        },
        {
            text = 'Goblin Gambler starts casting Thunder',
            color = offensive.color,
            outlineColor = offensive.outlineColor,
            fontSize = offensive.fontSize,
            offsetX = offensive.offsetX,
            offsetY = offensive.offsetY,
            lane = 'offensive',
        },
        {
            text = 'Goblin Gambler starts casting Regen',
            color = defensive.color,
            outlineColor = defensive.outlineColor,
            fontSize = defensive.fontSize,
            offsetX = defensive.offsetX,
            offsetY = defensive.offsetY,
            lane = 'defensive',
        },
        {
            text = 'Goblin Leecher uses Goblin Rush',
            color = ability.color,
            outlineColor = ability.outlineColor,
            fontSize = ability.fontSize,
            offsetX = ability.offsetX,
            offsetY = ability.offsetY,
            lane = 'ability',
        },
        {
            text = 'LightSpirit starts casting Haste',
            color = pet.color,
            outlineColor = pet.outlineColor,
            fontSize = pet.fontSize,
            offsetX = pet.offsetX,
            offsetY = pet.offsetY,
            lane = 'pet',
        },
    };
end

local function GetImguiFrameCount()
    if (imgui.GetFrameCount == nil) then
        return nil;
    end

    local ok, frame = pcall(function()
        return imgui.GetFrameCount();
    end);

    if (ok ~= true) then
        return nil;
    end

    return tonumber(frame);
end

local function RenderPreview(settings)
    if (previewEnabled ~= true) then
        return false;
    end

    local frame = GetImguiFrameCount();
    if (frame ~= nil and previewRenderedFrame == frame) then
        return true;
    end

    settings = settings or GetSettings();
    DrawAlertRows(settings, BuildPreviewRows(settings));

    if (frame ~= nil) then
        previewRenderedFrame = frame;
    end

    return true;
end

function enemyAlerts.Render()
    local settings = GetSettings();

    if (previewEnabled == true) then
        RenderPreview(settings);
        return;
    end

    if (settings.enabled ~= true) then
        alerts = {};
        return;
    end

    if (#alerts == 0) then
        return;
    end

    local now = os.clock();
    local active = {};

    for _, alert in ipairs(alerts) do
        if ((tonumber(alert.expires) or 0) > now) then
            alert.alpha = 1.0;
            active[#active + 1] = alert;
        elseif ((tonumber(alert.fadeEnds) or 0) > now) then
            local fadeDuration = math.max(0.01, (tonumber(alert.fadeEnds) or now) - (tonumber(alert.expires) or now));
            alert.alpha = math.max(0.0, math.min(1.0, 1.0 - ((now - (tonumber(alert.expires) or now)) / fadeDuration)));
            active[#active + 1] = alert;
        end
    end

    alerts = active;

    if (#alerts == 0) then
        return;
    end

    DrawAlertRows(settings, alerts);
end

function enemyAlerts.Test(lane)
    local tests = {
        { kind = 'Custom', lane = 'custom', actor = 'Custom', action = '', text = 'Custom alert: example trigger matched', label = 'custom alert' },
        { kind = 'System', lane = 'builtIn', actor = 'Campaign', action = '', text = 'Campaign: enemy forces headed to Jugner Forest [S]', label = 'built-in alert' },
        { kind = 'MA', lane = 'offensive', actor = 'Goblin Gambler', action = 'Thunder', label = 'offensive magic' },
        { kind = 'MA', lane = 'defensive', actor = 'Goblin Gambler', action = 'Regen', label = 'defensive magic' },
        { kind = 'JA', lane = 'ability', actor = 'Goblin Leecher', action = 'Goblin Rush', label = 'job ability' },
        { kind = 'MA', lane = 'pet', actor = 'LightSpirit', action = 'Banish', label = 'pet alert' },
    };

    local test = nil;
    if (lane ~= nil) then
        for _, candidate in ipairs(tests) do
            if (candidate.lane == lane) then
                test = candidate;
                break;
            end
        end
    end

    if (test == nil) then
        testAlertIndex = (testAlertIndex % #tests) + 1;
        test = tests[testAlertIndex];
    end

    alerts = {};
    local soundPlayed, soundFile = PushAlert(test.kind, test.lane, test.actor, test.action, { force = true, forceSound = true, text = test.text });
    lastDebug = 'test alert: ' .. tostring(test.label) .. ' sound=' .. tostring(soundPlayed) .. ' file=' .. tostring(soundFile);
end

function enemyAlerts.TestBuiltIn(label, text, soundPrefix)
    alerts = {};
    PushSystemAlert(label, text, soundPrefix);
    lastDebug = 'test built-in alert: ' .. tostring(label);
end

function enemyAlerts.TestCustomTrigger(index)
    local settings = GetSettings();
    local trigger = type(settings.customTriggers) == 'table' and settings.customTriggers[tonumber(index) or 0] or nil;
    local displayText = TrimText(type(trigger) == 'table' and trigger.text or '');
    local matchText = TrimText(type(trigger) == 'table' and trigger.match or '');
    local soundOptions = GetCustomTriggerSoundOptions(settings, trigger);

    if (displayText == '') then
        displayText = matchText ~= '' and matchText or 'Custom alert: example trigger matched';
    end

    alerts = {};
    PushAlert('Custom', 'custom', 'Custom', '', {
        text = displayText,
        force = true,
        soundEnabled = soundOptions.soundEnabled,
        soundFile = soundOptions.soundFile,
    });
    lastDebug = 'test custom trigger: ' .. tostring(index);
end

function enemyAlerts.SetEnabled(value)
    local enabled = value == true;
    GetSettings().enabled = enabled;

    if (enabled ~= true) then
        alerts = {};
    end
end

function enemyAlerts.GetEnabled()
    return IsEnabled();
end

function enemyAlerts.SetPreviewEnabled(value)
    previewEnabled = value == true;
end

function enemyAlerts.GetPreviewEnabled()
    return previewEnabled == true;
end

function enemyAlerts.RenderPreview()
    return RenderPreview(GetSettings());
end

function enemyAlerts.SetDebugEnabled(value, seconds)
    debugEnabled = value == true;
    debugUntil = debugEnabled == true and (os.clock() + (tonumber(seconds) or 30)) or nil;
end

function enemyAlerts.GetStatusText()
    local settings = GetSettings();

    return 'enabled=' .. tostring(settings.enabled == true) ..
        ' showMA=' .. tostring(settings.showMagic ~= false) ..
        ' offensiveMA=' .. tostring(settings.offensiveMagicEnabled ~= false) ..
        ' defensiveMA=' .. tostring(settings.defensiveMagicEnabled ~= false) ..
        ' showJA=' .. tostring(settings.showAbilities == true) ..
        ' active=' .. tostring(#alerts) ..
        ' debug=' .. tostring(IsDebugEnabled()) ..
        ' last=' .. tostring(lastDebug);
end

return enemyAlerts;
