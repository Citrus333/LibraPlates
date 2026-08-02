local currentTargetBar = {};

local imgui = require('imgui');
local targeting = require('core.targeting');
local entities = require('core.entities');
local state = require('core.state');
local engagedEnemies = require('core.engaged_enemies');
local enemyStatuses = require('core.enemy_statuses');
local partyStatuses = require('core.party_statuses');
local playerStatuses = require('core.player_statuses');
local currentTargetDebuffs = require('core.current_target_debuffs');
local mobInfoData = require('core.mobinfo_data');
local textureLoader = require('core.texture_loader');
local statusEffects = require('core.status_effects');
local statusIconTextures = require('core.status_icon_textures');
local statusTimerFormat = require('core.status_timer_format');
local nameDefaults = require('config.widgets.name');
local globalDefaults = require('config.global');
local fonts = require('core.fonts');
local textScale = require('core.text_scale');
local gdiTextTexture = require('ui.gdi_text_texture');

local hpVisualState = {
    key = nil,
    lastClock = nil,
    actualHp = nil,
    displayHp = nil,
    trailHp = nil,
    healHp = nil,
};
local GetServerId = nil;
local CopyTextStyle = nil;
local GetDistanceTextStyle = nil;
local GetTextureTextWidth = nil;
local AddTextureText = nil;
local peerIconTextureIds = {};
local missingPeerIconTextureIds = {};

local function Clamp(value, minimum, maximum)
    value = tonumber(value) or minimum;
    if (value < minimum) then return minimum; end
    if (value > maximum) then return maximum; end
    return value;
end

local function SafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function ColorToU32(color, fallback)
    if (imgui.GetColorU32 ~= nil) then
        return imgui.GetColorU32(color or fallback or { 1.0, 1.0, 1.0, 1.0 });
    end

    local source = color or fallback or { 1.0, 1.0, 1.0, 1.0 };
    local red = math.floor(Clamp(source[1], 0, 1) * 255);
    local green = math.floor(Clamp(source[2], 0, 1) * 255);
    local blue = math.floor(Clamp(source[3], 0, 1) * 255);
    local alpha = math.floor(Clamp(source[4] or 1.0, 0, 1) * 255);

    return (alpha * 0x1000000) + (blue * 0x10000) + (green * 0x100) + red;
end

local function ReadVec2(value)
    if (type(value) == 'table') then
        return tonumber(value[1] or value.x or value.X) or 0, tonumber(value[2] or value.y or value.Y) or 0;
    end

    return 0, 0;
end

local function GetTextWidth(text)
    text = tostring(text or '');
    if (imgui.CalcTextSize == nil) then
        return #text * 8;
    end

    local width = nil;
    pcall(function()
        width = ReadVec2(imgui.CalcTextSize(text));
    end);

    return tonumber(width) or (#text * 8);
end

local function AddDrawListText(drawList, x, y, textColor, outlineColor, text)
    if (drawList == nil or drawList.AddText == nil or text == nil or text == '') then
        return;
    end

    text = tostring(text);
    drawList:AddText({ x + 1, y + 1 }, outlineColor, text);
    drawList:AddText({ x, y }, textColor, text);
end

local function GetTextWindowFlags()
    return
        (_G.ImGuiWindowFlags_NoTitleBar or 0) +
        (_G.ImGuiWindowFlags_NoScrollbar or 0) +
        (_G.ImGuiWindowFlags_NoScrollWithMouse or 0) +
        (_G.ImGuiWindowFlags_NoSavedSettings or 0) +
        (_G.ImGuiWindowFlags_NoBackground or 0) +
        (_G.ImGuiWindowFlags_NoResize or 0) +
        (_G.ImGuiWindowFlags_NoMove or 0) +
        (_G.ImGuiWindowFlags_NoInputs or 0);
end

local function GetTarget()
    local subTargetIndex = targeting.GetCurrentSubTargetIndex();
    local targetIndex = subTargetIndex or targeting.GetCurrentTargetIndex();
    if (targetIndex == nil) then
        return nil;
    end

    local entity = entities.GetEntity(targetIndex);
    if (entity == nil or entity.Name == nil or entity.Name == '') then
        return nil;
    end

    return entity, targetIndex;
end

local function GetEntityServerId(entity)
    if (entity == nil) then
        return nil;
    end

    for _, key in ipairs({ 'ServerId', 'ServerID', 'serverId', 'serverID', 'Id', 'ID', 'id' }) do
        local value = tonumber(entity[key]);
        if (value ~= nil and value > 0) then
            return value;
        end
    end

    return nil;
end

local function GetTargetVisualKey(targetIndex, entity)
    return table.concat({
        tostring(targetIndex or 0),
        tostring(entity ~= nil and entity.Name or ''),
        tostring(GetEntityServerId(entity) or GetServerId(targetIndex) or 0),
    }, ':');
end

local function Approach(current, target, speed, dt)
    current = tonumber(current) or target;
    target = tonumber(target) or current;
    local amount = math.max(0.0, math.min(1.0, (tonumber(speed) or 1.0) * (tonumber(dt) or 0.0)));

    return current + ((target - current) * amount);
end

local function UpdateHpVisual(targetIndex, entity, hpPercent, hpPrediction)
    hpPercent = Clamp(hpPercent, 0, 100);
    hpPrediction = hpPrediction or {};

    local key = GetTargetVisualKey(targetIndex, entity);
    local now = os.clock();

    local smoothHpMovement = hpPrediction.smoothHpMovement ~= false;
    local damagePrediction = hpPrediction.damagePrediction ~= false;
    local healingPrediction = hpPrediction.healingPrediction ~= false;

    if (hpVisualState.key ~= key or hpVisualState.displayHp == nil or hpVisualState.trailHp == nil) then
        hpVisualState.key = key;
        hpVisualState.lastClock = now;
        hpVisualState.actualHp = hpPercent;
        hpVisualState.displayHp = hpPercent;
        hpVisualState.trailHp = hpPercent;
        hpVisualState.healHp = hpPercent;
        return hpPercent, hpPercent, hpPercent;
    end

    if (smoothHpMovement ~= true) then
        hpVisualState.lastClock = now;
        hpVisualState.actualHp = hpPercent;
        hpVisualState.displayHp = hpPercent;
        hpVisualState.trailHp = hpPercent;
        hpVisualState.healHp = hpPercent;
        return hpPercent, hpPercent, hpPercent;
    end

    local dt = math.max(0.0, math.min(0.12, now - (tonumber(hpVisualState.lastClock) or now)));
    hpVisualState.lastClock = now;

    local previousActual = tonumber(hpVisualState.actualHp) or hpPercent;
    hpVisualState.actualHp = hpPercent;

    if (hpPercent < previousActual) then
        if (damagePrediction == true) then
            hpVisualState.trailHp = math.max(tonumber(hpVisualState.trailHp) or hpPercent, previousActual);
        else
            hpVisualState.trailHp = hpPercent;
        end
    elseif (hpPercent > previousActual) then
        hpVisualState.trailHp = tonumber(hpVisualState.displayHp) or hpPercent;
        if (healingPrediction == true) then
            hpVisualState.healHp = math.max(tonumber(hpVisualState.healHp) or hpPercent, hpPercent);
        else
            hpVisualState.healHp = hpPercent;
        end
    end

    hpVisualState.displayHp = Approach(hpVisualState.displayHp, hpPercent, 13.0, dt);
    if (damagePrediction == true and hpPercent < (tonumber(hpVisualState.displayHp) or hpPercent)) then
        hpVisualState.trailHp = Approach(hpVisualState.trailHp, hpPercent, 2.8, dt);
    else
        hpVisualState.trailHp = hpVisualState.displayHp;
    end

    if (math.abs((tonumber(hpVisualState.displayHp) or hpPercent) - hpPercent) < 0.15) then
        hpVisualState.displayHp = hpPercent;
    end

    if (math.abs((tonumber(hpVisualState.trailHp) or hpPercent) - hpPercent) < 0.15) then
        hpVisualState.trailHp = hpPercent;
    end

    hpVisualState.displayHp = Clamp(hpVisualState.displayHp, 0, 100);
    hpVisualState.trailHp = Clamp(hpVisualState.trailHp, 0, 100);
    hpVisualState.healHp = healingPrediction == true and Approach(hpVisualState.healHp or hpPercent, hpPercent, 10.0, dt) or hpVisualState.displayHp;

    local healHp = healingPrediction == true and math.max(hpVisualState.displayHp, hpVisualState.healHp or hpPercent, hpPercent) or hpVisualState.displayHp;

    return hpVisualState.displayHp, hpVisualState.trailHp, Clamp(healHp, 0, 100);
end

local function ShouldShowHpPercent(settings, targetIndex)
    local mode = tostring(settings.hpPercentMode or 'Enemies only');
    if (mode == 'Always') then
        return true;
    end

    if (mode == 'Hidden' or mode == 'Off') then
        return false;
    end

    return entities.IsEnemy(targetIndex) == true;
end

GetServerId = function(targetIndex)
    local entityManager = entities.GetEntityManager();
    if (entityManager == nil or entityManager.GetServerId == nil) then
        return nil;
    end

    local ok, serverId = pcall(function()
        return entityManager:GetServerId(targetIndex);
    end);

    if (ok ~= true or tonumber(serverId) == nil or tonumber(serverId) == 0) then
        return nil;
    end

    return tonumber(serverId);
end

local function IsSelfTarget(targetIndex)
    local self = entities.GetSelf();
    return self ~= nil and tonumber(self.index) == tonumber(targetIndex);
end

local function IsSelfTargetEntity(entity)
    local memory = AshitaCore ~= nil and AshitaCore:GetMemoryManager() or nil;
    local player = memory ~= nil and memory:GetPlayer() or nil;
    local party = memory ~= nil and memory:GetParty() or nil;

    if (entity == nil or player == nil or party == nil) then
        return false;
    end

    local selfIndex = SafeCall(nil, function()
        if (player.GetTargetIndex ~= nil) then
            return player:GetTargetIndex();
        end

        return party:GetMemberTargetIndex(0);
    end);

    if (selfIndex == nil) then
        return false;
    end

    local selfEntity = entities.GetEntity(selfIndex);
    return selfEntity ~= nil and selfEntity == entity;
end

local function IsMemberOfParty(targetIndex)
    local memory = AshitaCore ~= nil and AshitaCore:GetMemoryManager() or nil;
    local party = memory ~= nil and memory:GetParty() or nil;

    if (party == nil) then
        return false;
    end

    for index = 0, 17 do
        local memberIndex = SafeCall(nil, function()
            return party:GetMemberTargetIndex(index);
        end);

        if (tonumber(memberIndex) == tonumber(targetIndex)) then
            return true;
        end
    end

    return false;
end

local function IsPlayerIndex(targetIndex)
    targetIndex = tonumber(targetIndex);
    return targetIndex ~= nil and targetIndex >= 1024 and targetIndex <= 1791;
end

local function IsTargetStatusTrackedEntity(entity)
    if (entity == nil) then
        return false;
    end

    local spawnFlags = tonumber(entity.SpawnFlags) or 0;
    if (bit.band(spawnFlags, 0x0001) == 0x0001 or bit.band(spawnFlags, 0x0002) == 0x0002) then
        return false;
    end

    return true;
end

local function SafeReadEntityStatusList(entity)
    if (entity == nil) then
        return nil;
    end

    for _, key in ipairs({ 'StatusEffects', 'statusEffects', 'Buffs', 'buffs' }) do
        local value = entity[key];
        if (type(value) == 'table') then
            return value;
        end
    end

    for _, methodName in ipairs({ 'GetStatusEffects', 'GetBuffs' }) do
        local method = entity[methodName];
        if (type(method) == 'function') then
            local ok, value = pcall(function()
                return method(entity);
            end);

            if (ok == true and type(value) == 'table') then
                return value;
            end
        end
    end

    return nil;
end

local function BuildRowsFromEntityStatuses(entity, kind)
    local statuses = SafeReadEntityStatusList(entity);
    local rows = {};

    if (statuses == nil) then
        return rows;
    end

    local startIndex = statuses[0] ~= nil and 0 or 1;
    local endIndex = statuses[0] ~= nil and 31 or 32;

    for index = startIndex, endIndex do
        local statusId = tonumber(statuses[index]);
        if (
            statusId ~= nil and
            statusId > 0 and
            statusId ~= 255 and
            (
                (kind == 'buff' and statusEffects.IsBuff(statusId) == true) or
                (kind == 'debuff' and statusEffects.IsDebuff(statusId) == true) or
                (kind ~= 'buff' and kind ~= 'debuff')
            )
        ) then
            rows[#rows + 1] = {
                id = statusId,
                order = index,
            };
        end
    end

    return rows;
end

local function BuildRowsFromStatusIds(statusIds, kind)
    local rows = {};

    if (type(statusIds) ~= 'table') then
        return rows;
    end

    for index = 1, 32 do
        local statusId = tonumber(statusIds[index]);
        if (
            statusId ~= nil and
            statusId > 0 and
            statusId ~= 255 and
            statusId ~= -1 and
            (
                (kind == 'buff' and statusEffects.IsBuff(statusId) == true) or
                (kind == 'debuff' and statusEffects.IsDebuff(statusId) == true) or
                (kind ~= 'buff' and kind ~= 'debuff')
            )
        ) then
            rows[#rows + 1] = {
                id = statusId,
                order = index,
            };
        end
    end

    return rows;
end

local function GetStatusRows(targetIndex, entity, kind, isEnemy)
    if (targetIndex == nil) then
        return {};
    end

    if (IsSelfTargetEntity(entity) == true or IsSelfTarget(targetIndex) == true) then
        local player = SafeCall(nil, function()
            return AshitaCore:GetMemoryManager():GetPlayer();
        end);
        local statusIds = SafeCall(nil, function()
            return player ~= nil and player.GetBuffs ~= nil and player:GetBuffs() or nil;
        end);
        local rows = BuildRowsFromStatusIds(statusIds, kind);
        if (#rows > 0) then
            return rows;
        end

        return playerStatuses.GetSelfRows(kind) or {};
    end

    local serverId = GetEntityServerId(entity) or GetServerId(targetIndex);
    if (serverId == nil) then
        return {};
    end

    local isPartyMember = IsMemberOfParty(targetIndex) == true;

    if (isPartyMember ~= true and isEnemy ~= true and kind == 'debuff') then
        return currentTargetDebuffs.GetRows(serverId);
    end

    local useTrackedTargetStatuses = isEnemy == true or IsTargetStatusTrackedEntity(entity) == true;

    if (useTrackedTargetStatuses == true) then
        local rows = enemyStatuses.GetActiveStatusRows(serverId, kind) or {};
        if (kind == 'debuff') then
            local distance = entity ~= nil and entity.Distance ~= nil and math.sqrt(tonumber(entity.Distance) or 0) or nil;
            local geoRows = enemyStatuses.GetGeoAuraDebuffRows(distance, true) or {};
            for _, row in ipairs(geoRows) do
                rows[#rows + 1] = row;
            end
        end

        return rows;
    end

    local rows = isPartyMember == true and (partyStatuses.GetMemberRows(serverId, kind) or {}) or {};
    if (#rows == 0 and IsPlayerIndex(targetIndex) == true) then
        rows = BuildRowsFromEntityStatuses(entity, kind);
    end

    return rows;
end

local function DrawStatusRows(drawList, rows, settings, originX, originY)
    if (
        drawList == nil or
        drawList.AddImage == nil or
        settings == nil or
        settings.enabled ~= true or
        rows == nil or
        #rows == 0
    ) then
        return;
    end

    local maxIcons = math.max(1, math.min(32, tonumber(settings.maxIcons) or 12));
    local iconsPerRow = math.max(1, math.min(32, tonumber(settings.iconsPerRow) or 12));
    local iconSize = math.max(6, math.min(96, tonumber(settings.iconSize) or 18));
    local spacing = math.max(0, math.min(32, tonumber(settings.iconSpacing) or 2));
    local rowSpacing = math.max(0, math.min(48, tonumber(settings.rowSpacing) or 2));
    local baseX = originX + math.floor(tonumber(settings.offsetX) or 0);
    local baseY = originY + math.floor(tonumber(settings.offsetY) or 0);
    local total = math.min(maxIcons, #rows);

    for index = 1, total do
        local rowData = rows[index];
        local statusId = type(rowData) == 'table' and rowData.id or rowData;
        local textureId = statusIconTextures.GetTextureId(statusId);

        if (textureId ~= nil) then
            local row = math.floor((index - 1) / iconsPerRow);
            local col = (index - 1) % iconsPerRow;
            local x = baseX + (col * (iconSize + spacing));
            local y = baseY + (row * (iconSize + rowSpacing));

            drawList:AddImage(textureId, { x, y }, { x + iconSize, y + iconSize }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);

            local timerSeconds = type(rowData) == 'table' and tonumber(rowData.seconds) or nil;
            if (settings.showTimers == true and timerSeconds ~= nil and timerSeconds > 0) then
                local timerText = statusTimerFormat.Format(timerSeconds);
                local textColor = ColorToU32({ 1.0, 1.0, 1.0, 1.0 });
                local outlineColor = ColorToU32({ 0.0, 0.0, 0.0, 1.0 });
                local textX = x + math.max(0, math.floor((iconSize - GetTextWidth(timerText)) * 0.5));
                AddDrawListText(drawList, textX, y + iconSize - 3, textColor, outlineColor, timerText);
            end
        end
    end
end

local function SanitizePeerIconStyle(iconStyle)
    local style = tostring(iconStyle or 'round'):gsub('[\\/]', '');
    if (style == '' or style == '.' or style == '..') then
        return 'round';
    end

    return style;
end

local function ResolvePeerIconStyle(globalSettings, peerSettings)
    return SanitizePeerIconStyle(globalSettings ~= nil and globalSettings.enemyIconStyle or 'round');
end

local function GetPeerIconTextureId(iconName, iconStyle)
    iconName = tostring(iconName or '');
    if (iconName == '') then
        return nil;
    end

    iconStyle = SanitizePeerIconStyle(iconStyle);
    local cacheKey = iconStyle .. ':' .. iconName;
    if (peerIconTextureIds[cacheKey] ~= nil) then
        return peerIconTextureIds[cacheKey];
    end
    if (missingPeerIconTextureIds[cacheKey] == true) then
        return nil;
    end

    local path = tostring(addon.path or '') .. '\\assets\\images\\peer-icons\\' .. iconStyle .. '\\' .. iconName .. '.png';
    peerIconTextureIds[cacheKey] = textureLoader.ToTextureId(textureLoader.Load(path));
    if (peerIconTextureIds[cacheKey] == nil and iconStyle ~= 'round') then
        local fallbackKey = 'round:' .. iconName;
        if (peerIconTextureIds[fallbackKey] ~= nil) then
            peerIconTextureIds[cacheKey] = peerIconTextureIds[fallbackKey];
        elseif (missingPeerIconTextureIds[fallbackKey] ~= true) then
            local fallbackPath = tostring(addon.path or '') .. '\\assets\\images\\peer-icons\\round\\' .. iconName .. '.png';
            peerIconTextureIds[fallbackKey] = textureLoader.ToTextureId(textureLoader.Load(fallbackPath));
            peerIconTextureIds[cacheKey] = peerIconTextureIds[fallbackKey];
            if (peerIconTextureIds[fallbackKey] == nil) then
                missingPeerIconTextureIds[fallbackKey] = true;
            end
        end
    end
    if (peerIconTextureIds[cacheKey] == nil) then
        missingPeerIconTextureIds[cacheKey] = true;
    end

    return peerIconTextureIds[cacheKey];
end

local function FormatModifierPercent(potency)
    potency = tonumber(potency) or 1;
    local percent = math.floor(((potency - 1) * 100) + (potency >= 1 and 0.5 or -0.5));

    if (percent > 0) then
        return '+' .. tostring(percent) .. '%';
    end

    return tostring(percent) .. '%';
end

local function AppendMobInfoIconRow(rows, info, settings)
    if (settings.showBehavior ~= false or settings.showDetects ~= false or settings.showLinks ~= false) then
        for _, iconName in ipairs(mobInfoData.GetFlags(info)) do
            local isBehavior = iconName == 'AggroHQ' or iconName == 'AggroNQ' or iconName == 'PassiveHQ' or iconName == 'PassiveNQ';
            local isLink = iconName == 'Link';
            local allowed = (
                (isBehavior == true and settings.showBehavior ~= false) or
                (isLink == true and settings.showLinks ~= false) or
                (isBehavior ~= true and isLink ~= true and settings.showDetects ~= false)
            );

            if (allowed == true) then
                rows[#rows + 1] = { icon = iconName };
            end
        end
    end

    if (settings.showWeakResist ~= false) then
        local pendingGroup = nil;

        local function FlushModifierGroup()
            if (pendingGroup ~= nil and #pendingGroup.icons > 0) then
                rows[#rows + 1] = pendingGroup;
            end
            pendingGroup = nil;
        end

        for _, modifier in ipairs(mobInfoData.GetModifierRows(info)) do
            local potency = tonumber(modifier.potency) or 1;
            local text = FormatModifierPercent(potency);
            local kind = potency > 1 and 'weak' or 'resist';

            if (pendingGroup == nil or pendingGroup.text ~= text or pendingGroup.kind ~= kind) then
                FlushModifierGroup();
                pendingGroup = {
                    icons = {},
                    text = text,
                    kind = kind,
                };
            end

            pendingGroup.icons[#pendingGroup.icons + 1] = modifier.icon;
        end

        FlushModifierGroup();
    end

    if (settings.showImmunities == true) then
        for _, iconName in ipairs(mobInfoData.GetImmunityFlags(info)) do
            rows[#rows + 1] = { icon = iconName };
        end
    end
end

local function DrawMobInfoRow(drawList, entity, targetIndex, settings, textStyle, fontSize, originX, originY)
    if (
        drawList == nil or
        drawList.AddImage == nil or
        settings == nil or
        settings.enabled ~= true or
        entity == nil
    ) then
        return;
    end

    local info = mobInfoData.GetMobInfo(entity.Name, targetIndex);
    if (info == nil) then
        return;
    end

    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local peerSettings = globalSettings ~= nil and globalSettings.peer or {};
    local iconStyle = ResolvePeerIconStyle(globalSettings, peerSettings);
    local iconSize = math.max(6, math.min(96, tonumber(settings.iconSize) or tonumber(peerSettings.iconSize) or 18));
    local spacing = math.max(0, math.min(32, tonumber(settings.iconSpacing) or 2));
    local maxIcons = math.max(1, math.min(32, tonumber(settings.maxIcons) or 16));
    local baseX = originX + math.floor(tonumber(settings.offsetX) or 0);
    local baseY = originY + math.floor(tonumber(settings.offsetY) or 0);
    local cursorX = baseX;
    local rowTextStyle = CopyTextStyle(textStyle, settings.textColor or { 1.0, 1.0, 1.0, 1.0 });
    rowTextStyle.outlineColor = settings.outlineColor or { 0.0, 0.0, 0.0, 1.0 };
    rowTextStyle.outlineSize = tonumber(settings.outlineSize) or 1;
    rowTextStyle.outlineEnabled = rowTextStyle.outlineSize > 0;
    local rowFontSize = math.max(6, math.min(80, tonumber(settings.fontSize) or math.max(10, (tonumber(fontSize) or 14) - 2)));
    local labelParts = {};

    if (settings.showJobLevel ~= false) then
        local jobText = mobInfoData.GetJobString(info);
        local levelText = mobInfoData.GetLevelString(info);
        if (jobText ~= '') then labelParts[#labelParts + 1] = jobText; end
        if (levelText ~= '') then labelParts[#labelParts + 1] = levelText; end
    end

    if (#labelParts > 0) then
        local label = table.concat(labelParts, ' ');
        AddTextureText(drawList, cursorX, baseY + math.floor((iconSize - rowFontSize) * 0.5) - 1, label, rowTextStyle, rowFontSize);
        cursorX = cursorX + math.floor(GetTextureTextWidth(label, rowTextStyle, rowFontSize) + spacing + 4);
    end

    local rows = {};
    AppendMobInfoIconRow(rows, info, settings);

    for index = 1, math.min(maxIcons, #rows) do
        local row = rows[index];
        local rowIcons = type(row.icons) == 'table' and row.icons or { row.icon };
        local drewIcon = false;

        for _, iconName in ipairs(rowIcons) do
            local textureId = GetPeerIconTextureId(iconName, iconStyle);
            if (textureId ~= nil) then
                drawList:AddImage(textureId, { cursorX, baseY }, { cursorX + iconSize, baseY + iconSize }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
                cursorX = cursorX + iconSize + spacing;
                drewIcon = true;
            end
        end

        if (drewIcon == true) then
            if (row.text ~= nil and row.text ~= '') then
                local modifierTextStyle = rowTextStyle;
                if (row.kind == 'weak') then
                    modifierTextStyle = CopyTextStyle(rowTextStyle, { 0.44, 0.95, 0.70, 1.0 });
                elseif (row.kind == 'resist') then
                    modifierTextStyle = CopyTextStyle(rowTextStyle, { 1.0, 0.58, 0.50, 1.0 });
                end
                modifierTextStyle.fontFamily = fonts.GetRole(globalSettings, true);
                modifierTextStyle.fontFlags = fonts.GetRoleFlags(globalSettings, true);

                local textX = cursorX - spacing + 1;
                AddTextureText(drawList, textX, baseY + math.floor(iconSize * 0.55), row.text, modifierTextStyle, rowFontSize);
                cursorX = cursorX + math.floor(GetTextureTextWidth(row.text, modifierTextStyle, rowFontSize) + spacing + 3);
            end
        end
    end
end

local function GetClaimNameColor(nameSettings, claimCategory)
    if (claimCategory == 'party') then
        return nameSettings.claimPartyColor or nameDefaults.claimPartyColor or nameSettings.color or nameDefaults.color;
    end

    if (claimCategory == 'other') then
        return nameSettings.claimOtherColor or nameDefaults.claimOtherColor or nameSettings.color or nameDefaults.color;
    end

    if (claimCategory == 'call_for_help') then
        return nameSettings.claimCallForHelpColor or nameDefaults.claimCallForHelpColor or nameSettings.color or nameDefaults.color;
    end

    return nameSettings.claimUnclaimedColor or nameDefaults.claimUnclaimedColor or nameSettings.color or nameDefaults.color;
end

local function GetClaimNameOutlineColor(nameSettings, claimCategory)
    if (claimCategory == 'party') then
        return nameSettings.claimPartyOutlineColor or nameDefaults.claimPartyOutlineColor or nameSettings.outlineColor or nameDefaults.outlineColor;
    end

    if (claimCategory == 'other') then
        return nameSettings.claimOtherOutlineColor or nameDefaults.claimOtherOutlineColor or nameSettings.outlineColor or nameDefaults.outlineColor;
    end

    if (claimCategory == 'call_for_help') then
        return nameSettings.claimCallForHelpOutlineColor or nameDefaults.claimCallForHelpOutlineColor or nameSettings.outlineColor or nameDefaults.outlineColor;
    end

    return nameSettings.claimUnclaimedOutlineColor or nameDefaults.claimUnclaimedOutlineColor or nameSettings.outlineColor or nameDefaults.outlineColor;
end

local function GetNameWidgetEntityName(entity, targetIndex, isEnemy)
    if (IsSelfTarget(targetIndex) == true) then
        return 'Self';
    end

    if (isEnemy == true) then
        return 'Enemy';
    end

    if (IsPlayerIndex(targetIndex) == true) then
        return 'PC';
    end

    if (entity ~= nil and (tonumber(entity.Type) == 2 or tonumber(entity.Type) == 3)) then
        return 'Object';
    end

    return 'NPC';
end

local function GetNameWidgetStateName(targetIndex)
    local targetState = targeting.GetTargetStateName(targetIndex);
    return tostring(targetState or 'Idle') == 'Idle' and 'Idle' or 'Combat';
end

local function GetInheritedNameStyle(entity, targetIndex, isEnemy)
    local entityName = GetNameWidgetEntityName(entity, targetIndex, isEnemy);
    local layoutStateName = GetNameWidgetStateName(targetIndex);
    local nameSettings = state.GetWidgetSettings(entityName, layoutStateName, 'Name', nameDefaults);
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local claimCategory = isEnemy == true and engagedEnemies.GetClaimCategory(targetIndex) or nil;

    if (isEnemy == true) then
        return {
            textColor = GetClaimNameColor(nameSettings, claimCategory),
            outlineColor = GetClaimNameOutlineColor(nameSettings, claimCategory),
            outlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
            outlineSize = tonumber(nameSettings.outlineSize) or 0,
            fontFamily = fonts.GetRole(globalSettings, false),
            fontFlags = fonts.GetRoleFlags(globalSettings, false),
        };
    end

    return {
        textColor = nameSettings.color or nameDefaults.color or { 1.0, 1.0, 1.0, 1.0 },
        outlineColor = nameSettings.outlineColor or nameDefaults.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        outlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        outlineSize = tonumber(nameSettings.outlineSize) or 0,
        fontFamily = fonts.GetRole(globalSettings, false),
        fontFlags = fonts.GetRoleFlags(globalSettings, false),
    };
end

CopyTextStyle = function(style, color)
    return {
        textColor = color or (style ~= nil and style.textColor) or { 1.0, 1.0, 1.0, 1.0 },
        outlineColor = (style ~= nil and style.outlineColor) or { 0.0, 0.0, 0.0, 1.0 },
        outlineEnabled = style ~= nil and style.outlineEnabled == true,
        outlineSize = tonumber(style ~= nil and style.outlineSize) or 0,
        fontFamily = style ~= nil and style.fontFamily or nil,
        fontFlags = tonumber(style ~= nil and style.fontFlags) or 0,
    };
end

GetDistanceTextStyle = function(nameStyle)
    return CopyTextStyle(nameStyle, { 1.0, 1.0, 1.0, 1.0 });
end

local function GetHpPercentColor(hpPercent)
    hpPercent = tonumber(hpPercent) or 100;

    if (hpPercent >= 80) then
        return { 1.0, 1.0, 1.0, 1.0 };
    end

    if (hpPercent >= 50) then
        return { 1.0, 0.92, 0.10, 1.0 };
    end

    if (hpPercent >= 25) then
        return { 1.0, 0.55, 0.05, 1.0 };
    end

    return { 1.0, 0.18, 0.18, 1.0 };
end

local function GetHpPercentTextStyle(nameStyle, hpPercent)
    return CopyTextStyle(nameStyle, GetHpPercentColor(hpPercent));
end

local function GetNameRenderFontSize(fontSize)
    local size = math.max(1, tonumber(fontSize) or 14);
    return math.min(44, math.floor(size + 0.5));
end

local function GetNameRenderScale(fontSize, renderFontSize)
    local renderSize = math.max(1, tonumber(renderFontSize) or 14);
    return math.max(1.0, (tonumber(fontSize) or renderSize) / renderSize);
end

local function GetTextureTextMetrics(text, style, fontSize)
    local renderFontSize = GetNameRenderFontSize(textScale.ToNameTextureFontSize(fontSize, 14));
    local renderScale = GetNameRenderScale(textScale.ToNameTextureFontSize(fontSize, 14), renderFontSize);
    local textureId, width, height = gdiTextTexture.GetTexture(tostring(text or ''), {
        fontFamily = style.fontFamily,
        fontFlags = tonumber(style.fontFlags) or 0,
        fontSize = renderFontSize,
        color = style.textColor or { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = style.outlineEnabled == true,
        outlineColor = style.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = tonumber(style.outlineSize) or 0,
    });

    return textureId, (tonumber(width) or 0) * renderScale, (tonumber(height) or 0) * renderScale;
end

GetTextureTextWidth = function(text, style, fontSize)
    local _, width = GetTextureTextMetrics(text, style, fontSize);
    return tonumber(width) or GetTextWidth(text);
end

AddTextureText = function(drawList, x, y, text, style, fontSize)
    if (drawList == nil or drawList.AddImage == nil or text == nil or text == '') then
        return false;
    end

    local renderTextureSize = textScale.ToNameTextureFontSize(fontSize, 14);
    local renderFontSize = GetNameRenderFontSize(renderTextureSize);
    local renderScale = GetNameRenderScale(renderTextureSize, renderFontSize);
    local textureId, width, height = gdiTextTexture.GetTexture(tostring(text or ''), {
        fontFamily = style.fontFamily,
        fontFlags = tonumber(style.fontFlags) or 0,
        fontSize = renderFontSize,
        color = style.textColor or { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = style.outlineEnabled == true,
        outlineColor = style.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = tonumber(style.outlineSize) or 0,
    });

    width = (tonumber(width) or 0) * renderScale;
    height = (tonumber(height) or 0) * renderScale;

    if (textureId == nil or width <= 0 or height <= 0) then
        return false;
    end

    drawList:AddImage(textureId, { x, y }, { x + width, y + height }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
    return true;
end

local function GetTextSettings(settings)
    if (type(settings.text) == 'table') then
        return settings.text;
    end

    return settings;
end

local EndTextWindow = nil;

local function BeginTextWindow(fontSize)
    if (imgui.Begin == nil or imgui.End == nil or imgui.SetNextWindowPos == nil or imgui.SetNextWindowSize == nil) then
        return false;
    end

    local width = 4000;
    local height = 4000;
    if (imgui.GetIO ~= nil) then
        local io = imgui.GetIO();
        if (type(io) == 'table' and type(io.DisplaySize) == 'table') then
            width = tonumber(io.DisplaySize[1] or io.DisplaySize.x or io.DisplaySize.X) or width;
            height = tonumber(io.DisplaySize[2] or io.DisplaySize.y or io.DisplaySize.Y) or height;
        end
    end

    imgui.SetNextWindowPos({ 0, 0 }, _G.ImGuiCond_Always or 1);
    imgui.SetNextWindowSize({ width, height }, _G.ImGuiCond_Always or 1);

    if (imgui.PushStyleVar ~= nil and _G.ImGuiStyleVar_WindowPadding ~= nil) then
        imgui.PushStyleVar(_G.ImGuiStyleVar_WindowPadding, { 0, 0 });
    end

    local visible = imgui.Begin('LibraPlates Current Target Bar Text##CurrentTargetBarText', true, GetTextWindowFlags());

    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(math.max(0.25, math.min(6.0, (tonumber(fontSize) or 14) / 14)));
    end

    if (visible ~= true) then
        EndTextWindow();
        return false;
    end

    return visible == true;
end

EndTextWindow = function()
    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.0);
    end

    if (imgui.End ~= nil) then
        imgui.End();
    end

    if (imgui.PopStyleVar ~= nil and _G.ImGuiStyleVar_WindowPadding ~= nil) then
        imgui.PopStyleVar();
    end
end

function currentTargetBar.Render()
    local targetingSettings = targeting.GetSettings();
    local settings = targetingSettings.currentTargetBar;
    if (settings == nil or settings.enabled ~= true) then
        return;
    end

    local entity, targetIndex = GetTarget();
    if (entity == nil) then
        return;
    end

    local isEnemy = entities.IsEnemy(targetIndex) == true;
    local textSettings = GetTextSettings(settings);
    local inheritedNameStyle = GetInheritedNameStyle(entity, targetIndex, isEnemy);
    local beganTextWindow = BeginTextWindow(textSettings.fontSize or 14);
    local drawList = nil;

    if (beganTextWindow == true and imgui.GetWindowDrawList ~= nil) then
        drawList = imgui.GetWindowDrawList();
    elseif (imgui.GetForegroundDrawList ~= nil) then
        drawList = imgui.GetForegroundDrawList();
    end

    local statusDrawList = drawList;
    if (imgui.GetForegroundDrawList ~= nil) then
        statusDrawList = imgui.GetForegroundDrawList();
    end

    if (drawList == nil or drawList.AddRectFilled == nil) then
        if (beganTextWindow == true) then
            EndTextWindow();
        end
        return;
    end

    local buffRows = GetStatusRows(targetIndex, entity, 'buff', isEnemy);
    local debuffRows = GetStatusRows(targetIndex, entity, 'debuff', isEnemy);

    local x = math.floor(Clamp(settings.x, 0, 4000) + 0.5);
    local y = math.floor(Clamp(settings.y, 0, 4000) + 0.5);
    local width = math.floor(Clamp(settings.width, 20, 2000) + 0.5);
    local height = math.floor(Clamp(settings.height, 1, 200) + 0.5);
    local radius = math.floor(Clamp(settings.radius, 0, 40) + 0.5);
    local borderSize = math.floor(Clamp(settings.borderSize, 0, 20) + 0.5);
    local hpPercent = Clamp(entity.HPPercent or 100, 0, 100);
    local displayHpPercent, trailHpPercent, healHpPercent = UpdateHpVisual(targetIndex, entity, hpPercent, targetingSettings.hpPrediction);
    local fillWidth = math.floor((width * displayHpPercent / 100) + 0.5);
    local trailWidth = math.floor((width * trailHpPercent / 100) + 0.5);
    local healWidth = math.floor((width * healHpPercent / 100) + 0.5);
    local bgColor = ColorToU32(settings.backgroundColor, { 0.02, 0.05, 0.10, 0.92 });
    local fillColor = ColorToU32(settings.fillColor, { 0.95, 0.38, 0.46, 1.0 });
    local trailColor = ColorToU32({ 0.86, 0.12, 0.18, 0.92 });
    local healColor = ColorToU32({ 0.20, 0.95, 0.58, 0.76 });
    local borderColor = ColorToU32(settings.borderColor, { 0.0, 0.0, 0.0, 0.95 });
    local textColor = inheritedNameStyle.textColor or { 1.0, 1.0, 1.0, 1.0 };
    local outlineColor = inheritedNameStyle.outlineColor or { 0.0, 0.0, 0.0, 0.95 };

    if (borderSize > 0) then
        drawList:AddRectFilled({ x - borderSize, y - borderSize }, { x + width + borderSize, y + height + borderSize }, borderColor, radius + borderSize);
    end

    drawList:AddRectFilled({ x, y }, { x + width, y + height }, bgColor, radius);
    if (healWidth > fillWidth) then
        drawList:AddRectFilled({ x + fillWidth, y }, { x + healWidth, y + height }, healColor, radius);
    end
    if (trailWidth > fillWidth) then
        drawList:AddRectFilled({ x + fillWidth, y }, { x + trailWidth, y + height }, trailColor, radius);
    end
    if (fillWidth > 0) then
        drawList:AddRectFilled({ x, y }, { x + fillWidth, y + height }, fillColor, radius);
    end

    pcall(DrawMobInfoRow, drawList, entity, targetIndex, settings.mobInfo, inheritedNameStyle, textSettings.fontSize or 14, x, y);
    DrawStatusRows(statusDrawList, buffRows, settings.buffs, x, y);
    DrawStatusRows(statusDrawList, debuffRows, settings.debuffs, x, y);

    local nameText = tostring(entity.Name or '');
    local nameX = x + math.floor(tonumber(textSettings.nameOffsetX) or tonumber(settings.nameOffsetX) or 0);
    local nameY = y + math.floor(tonumber(textSettings.nameOffsetY) or tonumber(settings.nameOffsetY) or -19);

    local distance = entity.Distance ~= nil and math.sqrt(tonumber(entity.Distance) or 0) or nil;
    local distanceText = nil;
    local distanceX = nil;
    local distanceY = nil;
    if (distance ~= nil) then
        distanceText = string.format('%.1f', distance);
    end

    local hpText = nil;
    if (ShouldShowHpPercent(settings, targetIndex) == true) then
        hpText = tostring(math.floor(hpPercent + 0.5)) .. '%';
    end

    if (beganTextWindow == true) then
        AddTextureText(drawList, nameX, nameY, nameText, inheritedNameStyle, textSettings.fontSize or 14);

        if (distanceText ~= nil) then
            local distanceStyle = GetDistanceTextStyle(inheritedNameStyle);
            distanceX = x + width + math.floor(tonumber(textSettings.distanceOffsetX) or tonumber(settings.distanceOffsetX) or -12) - GetTextureTextWidth(distanceText, distanceStyle, textSettings.fontSize or 14);
            distanceY = y + math.floor(tonumber(textSettings.distanceOffsetY) or tonumber(settings.distanceOffsetY) or -19);
            AddTextureText(drawList, distanceX, distanceY, distanceText, distanceStyle, textSettings.fontSize or 14);
        end

        if (hpText ~= nil) then
            local hpStyle = GetHpPercentTextStyle(inheritedNameStyle, hpPercent);
            local hpX = x + width + math.floor(tonumber(textSettings.hpPercentOffsetX) or tonumber(settings.hpPercentOffsetX) or -12) - GetTextureTextWidth(hpText, hpStyle, textSettings.fontSize or 14);
            local hpY = y + math.floor(tonumber(textSettings.hpPercentOffsetY) or tonumber(settings.hpPercentOffsetY) or 16);
            AddTextureText(drawList, hpX, hpY, hpText, hpStyle, textSettings.fontSize or 14);
        end

        EndTextWindow();
    else
        local textU32 = ColorToU32(textColor, { 1.0, 1.0, 1.0, 1.0 });
        local outlineU32 = ColorToU32(outlineColor, { 0.0, 0.0, 0.0, 0.95 });
        AddDrawListText(drawList, nameX, nameY, textU32, outlineU32, nameText);

        if (distanceText ~= nil) then
            local distanceStyle = GetDistanceTextStyle(inheritedNameStyle);
            distanceX = x + width + math.floor(tonumber(textSettings.distanceOffsetX) or tonumber(settings.distanceOffsetX) or -12) - GetTextureTextWidth(distanceText, distanceStyle, textSettings.fontSize or 14);
            distanceY = y + math.floor(tonumber(textSettings.distanceOffsetY) or tonumber(settings.distanceOffsetY) or -19);
            AddTextureText(drawList, distanceX, distanceY, distanceText, distanceStyle, textSettings.fontSize or 14);
        end

        if (hpText ~= nil) then
            local hpStyle = GetHpPercentTextStyle(inheritedNameStyle, hpPercent);
            local hpX = x + width + math.floor(tonumber(textSettings.hpPercentOffsetX) or tonumber(settings.hpPercentOffsetX) or -12) - GetTextureTextWidth(hpText, hpStyle, textSettings.fontSize or 14);
            local hpY = y + math.floor(tonumber(textSettings.hpPercentOffsetY) or tonumber(settings.hpPercentOffsetY) or 16);
            AddTextureText(drawList, hpX, hpY, hpText, hpStyle, textSettings.fontSize or 14);
        end
    end
end

return currentTargetBar;
