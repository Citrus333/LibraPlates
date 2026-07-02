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

local function GetLaneSettings(settings, lane)
    local soundVolume = math.max(0, math.min(100, tonumber(settings.soundVolume) or 100));

    if (lane == 'offensive') then
        return {
            enabled = settings.offensiveMagicEnabled ~= false,
            color = settings.offensiveColor or settings.color,
            outlineColor = settings.offensiveOutlineColor or settings.outlineColor,
            fontSize = tonumber(settings.offensiveFontSize) or tonumber(settings.fontSize) or 34,
            soundEnabled = settings.offensiveSoundEnabled == true,
            soundFile = settings.offensiveSoundFile or settings.soundFile,
            soundVolume = soundVolume,
        };
    elseif (lane == 'defensive') then
        return {
            enabled = settings.defensiveMagicEnabled ~= false,
            color = settings.defensiveColor or settings.color,
            outlineColor = settings.defensiveOutlineColor or settings.outlineColor,
            fontSize = tonumber(settings.defensiveFontSize) or tonumber(settings.fontSize) or 30,
            soundEnabled = settings.defensiveSoundEnabled == true,
            soundFile = settings.defensiveSoundFile or settings.soundFile,
            soundVolume = soundVolume,
        };
    elseif (lane == 'ability') then
        return {
            enabled = settings.showAbilities == true,
            color = settings.abilityColor or settings.color,
            outlineColor = settings.abilityOutlineColor or settings.outlineColor,
            fontSize = tonumber(settings.abilityFontSize) or tonumber(settings.fontSize) or 34,
            soundEnabled = settings.abilitySoundEnabled == true,
            soundFile = settings.abilitySoundFile or settings.soundFile,
            soundVolume = soundVolume,
        };
    end

    return {
        enabled = true,
        color = settings.color,
        outlineColor = settings.outlineColor,
        fontSize = tonumber(settings.fontSize) or 32,
        soundEnabled = settings.soundEnabled == true,
        soundFile = settings.soundFile,
        soundVolume = soundVolume,
    };
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
    local verb = (kind == 'MA') and 'starts casting' or 'uses';
    local text = tostring(actorName or 'Enemy') .. ' ' .. verb .. ' ' .. tostring(actionName or '');

    alerts[#alerts + 1] = {
        kind = tostring(kind or 'Alert'),
        lane = tostring(lane or 'default'),
        text = text,
        startTime = now,
        expires = now + duration,
        color = laneSettings.color,
        outlineColor = laneSettings.outlineColor,
        fontSize = laneSettings.fontSize,
    };

    if (laneSettings.soundEnabled == true) then
        alertSounds.Play(laneSettings.soundFile, laneSettings.soundVolume);
    end

    while (#alerts > 4) do
        table.remove(alerts, 1);
    end
end

local function HandleActionPacket(packet)
    if (packet == nil or packet.UserId == nil or IsEnemyIndex(packet.UserIndex) ~= true) then
        return;
    end

    local settings = GetSettings();

    if (settings.enabled ~= true) then
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

    if (actionName == nil or actionName == '') then
        return;
    end

    PushAlert(kind, lane, actorName, actionName);
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

function enemyAlerts.HandleTextIn(e)
    local settings = GetSettings();

    if (settings.enabled ~= true or settings.showAbilities ~= true) then
        return;
    end

    local message = StripControlCodes(
        (e ~= nil and (e.message or e.text or e.original or e.modified or e.injected)) or ''
    );

    if (message == '') then
        return;
    end

    local actorName, actionName = message:match('^The%s+(.+)%s+readies%s+(.+)%.%s*$');

    if (actorName == nil or actionName == nil) then
        actorName, actionName = message:match('^(.+)%s+readies%s+(.+)%.%s*$');
    end

    if (actorName == nil or actionName == nil) then
        return;
    end

    PushAlert('JA', 'ability', actorName, actionName);

    lastDebug = 'text-ready actor=' .. tostring(actorName) .. ' action=' .. tostring(actionName);
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

local function DrawOutlinedText(drawList, x, y, color, outlineColor, fontSize, text)
    local globalSettings = state.GetGlobalSettings(globalDefaults);
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
        return;
    end

    drawList:AddImage(textureId, { x - ((tonumber(textW) or 0) * 0.5), y }, { x + ((tonumber(textW) or 0) * 0.5), y + (tonumber(textH) or 0) }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
end

local function DrawAlertRows(settings, rows)
    local drawList = imgui.GetForegroundDrawList ~= nil and imgui.GetForegroundDrawList() or nil;

    if (drawList == nil) then
        return;
    end

    local viewportW = 1920;
    local viewportH = 1080;

    pcall(function()
        local io = imgui.GetIO();
        if (io ~= nil and io.DisplaySize ~= nil) then
            viewportW = tonumber(io.DisplaySize.x or io.DisplaySize.X or io.DisplaySize[1]) or viewportW;
            viewportH = tonumber(io.DisplaySize.y or io.DisplaySize.Y or io.DisplaySize[2]) or viewportH;
        end
    end);

    local x = (viewportW * 0.5) + (tonumber(settings.offsetX) or 0);
    local y = (viewportH * 0.28) + (tonumber(settings.offsetY) or 0);

    for i = #rows, 1, -1 do
        DrawOutlinedText(drawList, x, y + ((#rows - i) * 44), rows[i].color, rows[i].outlineColor, rows[i].fontSize, rows[i].text);
    end
end

local function BuildPreviewRows(settings)
    local offensive = GetLaneSettings(settings, 'offensive');
    local defensive = GetLaneSettings(settings, 'defensive');
    local ability = GetLaneSettings(settings, 'ability');

    return {
        {
            text = 'Goblin Gambler starts casting Thunder',
            color = offensive.color,
            outlineColor = offensive.outlineColor,
            fontSize = offensive.fontSize,
        },
        {
            text = 'Goblin Gambler starts casting Regen',
            color = defensive.color,
            outlineColor = defensive.outlineColor,
            fontSize = defensive.fontSize,
        },
        {
            text = 'Goblin Leecher uses Goblin Rush',
            color = ability.color,
            outlineColor = ability.outlineColor,
            fontSize = ability.fontSize,
        },
    };
end

function enemyAlerts.Render()
    local settings = GetSettings();

    if (previewEnabled == true) then
        DrawAlertRows(settings, BuildPreviewRows(settings));
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
            active[#active + 1] = alert;
        end
    end

    alerts = active;

    if (#alerts == 0) then
        return;
    end

    DrawAlertRows(settings, alerts);
end

function enemyAlerts.Test()
    PushAlert('MA', 'offensive', 'Goblin Gambler', 'Thunder', { force = true });
    PushAlert('MA', 'defensive', 'Goblin Gambler', 'Regen', { force = true });
    PushAlert('JA', 'ability', 'Goblin Leecher', 'Goblin Rush', { force = true });
    lastDebug = 'preview alert';
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
