local currentTargetBar = {};

local imgui = require('imgui');
local targeting = require('core.targeting');
local entities = require('core.entities');
local state = require('core.state');
local engagedEnemies = require('core.engaged_enemies');
local enemyStatuses = require('core.enemy_statuses');
local partyStatuses = require('core.party_statuses');
local playerStatuses = require('core.player_statuses');
local trustStatusIcons = require('core.trust_status_icons');
local currentTargetDebuffs = require('core.current_target_debuffs');
local actionRelevance = require('core.action_relevance');
local mobInfoData = require('core.mobinfo_data');
local textureLoader = require('core.texture_loader');
local npcObjectInfo = require('core.npc_object_info');
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
local targetOfTargetActionTracker = {};
local targetOfTargetActionCount = 0;
local GetEntityServerId = nil;
local GetServerId = nil;
local CopyTextStyle = nil;
local GetDistanceTextStyle = nil;
local GetTextureTextWidth = nil;
local AddTextureText = nil;
local peerIconTextureIds = {};
local missingPeerIconTextureIds = {};
local targetOfTargetArrowTextureIds = {};
local lastTargetOfTargetClickRect = nil;

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

local function ReadImguiVec2(valueA, valueB)
    if (type(valueA) == 'table') then
        return tonumber(valueA.x or valueA.X or valueA[1]) or 0, tonumber(valueA.y or valueA.Y or valueA[2]) or 0;
    end

    return tonumber(valueA) or 0, tonumber(valueB) or 0;
end

local function GetMousePosition()
    if (imgui.GetMousePos ~= nil) then
        return ReadImguiVec2(imgui.GetMousePos());
    end

    if (imgui.GetIO == nil) then
        return nil, nil;
    end

    local ok, io = pcall(function()
        return imgui.GetIO();
    end);

    if (ok ~= true or io == nil or io.MousePos == nil) then
        return nil, nil;
    end

    return ReadImguiVec2(io.MousePos);
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

local function IsMouseClickedInRect(rect)
    if (rect == nil or imgui.IsMouseClicked == nil or IsImguiCapturingMouse() == true) then
        return false;
    end

    local mouseX, mouseY = GetMousePosition();
    if (mouseX == nil or mouseY == nil) then
        return false;
    end

    return
        mouseX >= rect.x1 and mouseX <= rect.x2 and
        mouseY >= rect.y1 and mouseY <= rect.y2 and
        imgui.IsMouseClicked(0) == true;
end

local function IsPointInRect(x, y, rect)
    local mouseX = tonumber(x);
    local mouseY = tonumber(y);

    if (mouseX == nil or mouseY == nil or rect == nil) then
        return false;
    end

    return mouseX >= rect.x1 and mouseX <= rect.x2 and mouseY >= rect.y1 and mouseY <= rect.y2;
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

local function GetAddonPath()
    local ok, path = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and path ~= nil) then
        return tostring(path);
    end

    return '.\\';
end

local function GetTargetOfTargetArrowTextureId(fileName)
    fileName = tostring(fileName or 'arrow_01.png'):gsub('^.*[\\/]', '');
    if (fileName == '' or fileName == 'None') then
        return nil;
    end

    if (targetOfTargetArrowTextureIds[fileName] ~= nil) then
        return targetOfTargetArrowTextureIds[fileName];
    end

    local path = GetAddonPath() .. 'assets\\images\\target-of-target\\' .. fileName;
    targetOfTargetArrowTextureIds[fileName] = textureLoader.ToTextureId(textureLoader.LoadPreserveAlpha(path));
    return targetOfTargetArrowTextureIds[fileName];
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

local function GetSelfIndex()
    local memory = AshitaCore ~= nil and AshitaCore:GetMemoryManager() or nil;
    local party = memory ~= nil and memory:GetParty() or nil;
    if (party == nil or party.GetMemberTargetIndex == nil) then
        return nil;
    end

    local ok, index = pcall(function()
        return party:GetMemberTargetIndex(0);
    end);

    if (ok ~= true) then
        return nil;
    end

    return tonumber(index);
end

local function GetTargetOfTarget(targetIndex)
    targetIndex = tonumber(targetIndex);
    if (targetIndex == nil or targetIndex == 0) then
        return nil, nil;
    end

    local targetEntity = entities.GetEntity(targetIndex);
    if (targetEntity == nil) then
        return nil, nil;
    end

    if (tonumber(targetIndex) == tonumber(GetSelfIndex())) then
        return targetEntity, targetIndex;
    end

    local targetOfTargetIndex = nil;
    local serverId = GetEntityServerId(targetEntity) or GetServerId(targetIndex);

    if (serverId ~= nil) then
        local tracked = targetOfTargetActionTracker[serverId];
        if (tracked ~= nil and (tracked.timestamp + 30) >= os.time()) then
            targetOfTargetIndex = tonumber(tracked.targetIndex);
        elseif (tracked ~= nil) then
            targetOfTargetActionTracker[serverId] = nil;
        end
    end

    if (targetOfTargetIndex == nil or targetOfTargetIndex == 0) then
        targetOfTargetIndex = tonumber(targetEntity.TargetedIndex);
    end

    if (targetOfTargetIndex == nil or targetOfTargetIndex == 0) then
        return nil, nil;
    end

    local entity = entities.GetEntity(targetOfTargetIndex);
    if (entity == nil or entity.Name == nil or entity.Name == '') then
        return nil, nil;
    end

    return entity, targetOfTargetIndex;
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

    if (targetCount > 0) then
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
    end

    if (maxLength ~= 0 and #packet.Targets > 0) then
        return packet;
    end

    return nil;
end

local function CleanupTargetOfTargetTracker()
    local now = os.time();
    for serverId, entry in pairs(targetOfTargetActionTracker) do
        if (entry == nil or (tonumber(entry.timestamp) or 0) + 30 < now) then
            targetOfTargetActionTracker[serverId] = nil;
        end
    end
end

local function IsCombatActionType(actionType)
    actionType = tonumber(actionType);
    return actionType == 1 or actionType == 4 or actionType == 7 or actionType == 11;
end

local function IsPlayerServerId(serverId)
    local index = actionRelevance.GetIndexFromServerId(serverId);
    index = tonumber(index);
    return index ~= nil and index >= 1024 and index <= 1791;
end

GetEntityServerId = function(entity)
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
    if (entity == nil) then
        return false;
    end

    local self = entities.GetSelf();
    if (self == nil) then
        return false;
    end

    local entityServerId = GetEntityServerId(entity);
    if (entityServerId ~= nil and tonumber(self.serverId) ~= nil) then
        return tonumber(entityServerId) == tonumber(self.serverId);
    end

    return tostring(entity.Name or '') ~= '' and tostring(entity.Name or '') == tostring(self.name or '');
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

    local startIndex = statusIds[0] ~= nil and 0 or 1;
    local endIndex = statusIds[0] ~= nil and 31 or 32;

    for index = startIndex, endIndex do
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

    if (IsSelfTarget(targetIndex) == true or IsSelfTargetEntity(entity) == true) then
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

    if (isPartyMember == true) then
        local rows = partyStatuses.GetMemberRows(serverId, kind) or {};
        if (#rows > 0) then
            return rows;
        end
    end

    if (isEnemy ~= true) then
        local trustRows = trustStatusIcons.GetRows(serverId, kind) or {};
        if (#trustRows > 0) then
            return trustRows;
        end
    end

    if (isEnemy ~= true and IsPlayerIndex(targetIndex) == true) then
        local rows = BuildRowsFromEntityStatuses(entity, kind);
        if (#rows > 0) then
            return rows;
        end
    end

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

    return {};
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

local function MeasureMobInfoEntry(row, rowTextStyle, rowFontSize, iconSize, spacing)
    local iconCount = type(row.icons) == 'table' and #row.icons or (row.icon ~= nil and 1 or 0);
    local width = iconCount > 0 and ((iconCount * iconSize) + (math.max(0, iconCount - 1) * spacing)) or 0;

    if (row.text ~= nil and row.text ~= '') then
        width = width + spacing + math.floor(GetTextureTextWidth(row.text, rowTextStyle, rowFontSize) + 0.5);
    end

    return math.max(0, width);
end

local function MeasureMobInfoGroup(rows, rowTextStyle, rowFontSize, iconSize, spacing, entrySpacing)
    local width = 0;
    for index, row in ipairs(rows or {}) do
        if (index > 1) then
            width = width + entrySpacing;
        end
        width = width + MeasureMobInfoEntry(row, rowTextStyle, rowFontSize, iconSize, spacing);
    end

    return width;
end

local function DrawMobInfoEntry(drawList, row, iconStyle, rowTextStyle, rowFontSize, iconSize, spacing, cursorX, baseY, globalSettings)
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

    if (drewIcon == true and row.text ~= nil and row.text ~= '') then
        local modifierTextStyle = rowTextStyle;
        if (row.kind == 'weak') then
            modifierTextStyle = CopyTextStyle(rowTextStyle, { 0.44, 0.95, 0.70, 1.0 });
        elseif (row.kind == 'resist') then
            modifierTextStyle = CopyTextStyle(rowTextStyle, { 1.0, 0.58, 0.50, 1.0 });
        end
        modifierTextStyle.fontFamily = fonts.GetRole(globalSettings, true);
        modifierTextStyle.fontFlags = fonts.GetRoleFlags(globalSettings, true);

        AddTextureText(drawList, cursorX, baseY + math.floor((iconSize - rowFontSize) * 0.5), row.text, modifierTextStyle, rowFontSize);
        cursorX = cursorX + math.floor(GetTextureTextWidth(row.text, modifierTextStyle, rowFontSize) + 0.5);
    elseif (drewIcon == true) then
        cursorX = cursorX - spacing;
    end

    return cursorX;
end

local function DrawMobInfoGroup(drawList, rows, iconStyle, rowTextStyle, rowFontSize, iconSize, spacing, entrySpacing, cursorX, baseY, globalSettings, backgroundColor)
    if (rows == nil or #rows == 0) then
        return cursorX;
    end

    local padX = backgroundColor ~= nil and 4 or 0;
    local padY = backgroundColor ~= nil and 2 or 0;
    local groupWidth = MeasureMobInfoGroup(rows, rowTextStyle, rowFontSize, iconSize, spacing, entrySpacing);
    if (backgroundColor ~= nil and groupWidth > 0 and drawList.AddRectFilled ~= nil) then
        drawList:AddRectFilled(
            { cursorX - padX, baseY - padY },
            { cursorX + groupWidth + padX, baseY + iconSize + padY },
            ColorToU32(backgroundColor),
            2
        );
    end

    for index, row in ipairs(rows) do
        if (index > 1) then
            cursorX = cursorX + entrySpacing;
        end
        cursorX = DrawMobInfoEntry(drawList, row, iconStyle, rowTextStyle, rowFontSize, iconSize, spacing, cursorX, baseY, globalSettings);
    end

    return cursorX;
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

    local neutralRows = {};
    local resistRows = {};
    local weakRows = {};
    local allRows = {};
    AppendMobInfoIconRow(allRows, info, settings);

    for _, row in ipairs(allRows) do
        if (#neutralRows + #resistRows + #weakRows >= maxIcons) then
            break;
        end

        if (row.kind == 'resist') then
            resistRows[#resistRows + 1] = row;
        elseif (row.kind == 'weak') then
            weakRows[#weakRows + 1] = row;
        else
            neutralRows[#neutralRows + 1] = row;
        end
    end

    local entrySpacing = math.max(2, spacing + 3);
    cursorX = DrawMobInfoGroup(drawList, neutralRows, iconStyle, rowTextStyle, rowFontSize, iconSize, spacing, entrySpacing, cursorX, baseY, globalSettings, nil);
    if (#neutralRows > 0 and (#resistRows > 0 or #weakRows > 0)) then
        cursorX = cursorX + math.max(4, spacing + 4);
    end
    cursorX = DrawMobInfoGroup(drawList, resistRows, iconStyle, rowTextStyle, rowFontSize, iconSize, spacing, entrySpacing, cursorX, baseY, globalSettings, settings.resistBackgroundColor or { 0.85, 0.18, 0.18, 0.38 });
    if (#resistRows > 0 and #weakRows > 0) then
        cursorX = cursorX + math.max(4, spacing + 4);
    end
    DrawMobInfoGroup(drawList, weakRows, iconStyle, rowTextStyle, rowFontSize, iconSize, spacing, entrySpacing, cursorX, baseY, globalSettings, settings.weakBackgroundColor or { 0.12, 0.70, 0.32, 0.34 });
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

    local rawEntityName = 'NPC';
    if (entity ~= nil and (tonumber(entity.Type) == 2 or tonumber(entity.Type) == 3)) then
        rawEntityName = 'Object';
    end

    local function ResolveNpcObjectKind(kind)
        local name = tostring(entity ~= nil and entity.Name or ''):gsub('\170', '');
        name = name:gsub('%c', ''):gsub('^%s+', ''):gsub('%s+$', '');
        return npcObjectInfo.ResolveKind(name, kind, { targetIndex = targetIndex });
    end

    local resolvedEntityName = rawEntityName;
    local npcInfo = nil;
    local ok, resolved, info = pcall(ResolveNpcObjectKind, rawEntityName);
    if (ok == true) then
        resolvedEntityName = tostring(resolved or rawEntityName);
        npcInfo = info;
    end

    if (npcInfo == nil) then
        local fallbackKind = rawEntityName == 'Object' and 'NPC' or 'Object';
        ok, resolved, info = pcall(ResolveNpcObjectKind, fallbackKind);
        if (ok == true and info ~= nil) then
            resolvedEntityName = tostring(resolved or fallbackKind);
            npcInfo = info;
        end
    end

    if (npcInfo ~= nil and resolvedEntityName == 'Object') then
        return 'Object';
    end

    if (npcInfo ~= nil and resolvedEntityName == 'NPC') then
        return 'NPC';
    end

    if (IsPlayerIndex(targetIndex) == true) then
        return 'PC';
    end

    if (rawEntityName == 'Object') then
        return 'Object';
    end

    return 'NPC';
end

local function GetNameWidgetStateName(targetIndex, entityName)
    if (entityName == 'Object') then
        return 'Idle';
    end

    local targetState = targeting.GetTargetStateName(targetIndex);
    return tostring(targetState or 'Idle') == 'Idle' and 'Idle' or 'Combat';
end

local function GetInheritedNameStyle(entity, targetIndex, isEnemy)
    local entityName = GetNameWidgetEntityName(entity, targetIndex, isEnemy);
    local layoutStateName = GetNameWidgetStateName(targetIndex, entityName);
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

local function DrawTargetOfTargetBar(drawList, x, y, width, height, radius, borderSize, colors, textSettings, targetIndex, settings)
    if (drawList == nil or drawList.AddRectFilled == nil) then
        return nil;
    end

    settings = type(settings) == 'table' and settings or {};
    if (settings.enabled ~= true) then
        return nil;
    end

    local entity, index = GetTargetOfTarget(targetIndex);
    if (entity == nil or index == nil) then
        return nil;
    end

    local miniWidth = math.floor(Clamp(settings.width or (width * 0.36), 20, 1000) + 0.5);
    local miniHeight = math.floor(Clamp(settings.height or height, 1, 200) + 0.5);
    local offsetX = math.floor(tonumber(settings.offsetX) or 42);
    local offsetY = math.floor(tonumber(settings.offsetY) or 0);
    local arrowSize = math.floor(Clamp(settings.arrowSize or 22, 0, 200) + 0.5);
    local arrowOffsetX = math.floor(tonumber(settings.arrowOffsetX) or 0);
    local arrowOffsetY = math.floor(tonumber(settings.arrowOffsetY) or 0);
    local miniX = x + width + offsetX;
    local miniY = y + offsetY;
    local arrowX = x + width + math.floor((offsetX - arrowSize) * 0.5) + arrowOffsetX;
    local centerY = y + math.floor(height * 0.5);
    local arrowY = centerY - math.floor(arrowSize * 0.5) + arrowOffsetY;
    local miniRadius = math.max(0, math.min(radius, math.floor(miniHeight * 0.45)));
    local miniBorderSize = math.max(1, borderSize);

    local arrowColor = ColorToU32(settings.arrowColor or { 0.92, 0.95, 1.0, 1.0 });
    local arrowShadow = ColorToU32({ 0.0, 0.0, 0.0, 0.95 });

    if (arrowSize > 0) then
        local arrowTextureId = GetTargetOfTargetArrowTextureId(settings.arrowFile or 'arrow_01.png');
        if (arrowTextureId ~= nil and drawList.AddImage ~= nil) then
            drawList:AddImage(arrowTextureId, { arrowX, arrowY }, { arrowX + arrowSize, arrowY + arrowSize }, { 0, 0 }, { 1, 1 }, arrowColor);
        elseif (drawList.AddLine ~= nil) then
            drawList:AddLine({ arrowX, centerY - 8 }, { arrowX + arrowSize - 8, centerY }, arrowShadow, 5);
            drawList:AddLine({ arrowX, centerY + 8 }, { arrowX + arrowSize - 8, centerY }, arrowShadow, 5);
            drawList:AddLine({ arrowX, centerY - 8 }, { arrowX + arrowSize - 8, centerY }, arrowColor, 3);
            drawList:AddLine({ arrowX, centerY + 8 }, { arrowX + arrowSize - 8, centerY }, arrowColor, 3);
        end
    end

    local hpPercent = Clamp(entity.HPPercent or 100, 0, 100);
    local fillWidth = math.floor((miniWidth * hpPercent / 100) + 0.5);

    if (miniBorderSize > 0) then
        drawList:AddRectFilled(
            { miniX - miniBorderSize, miniY - miniBorderSize },
            { miniX + miniWidth + miniBorderSize, miniY + miniHeight + miniBorderSize },
            colors.border,
            miniRadius + miniBorderSize
        );
    end

    drawList:AddRectFilled({ miniX, miniY }, { miniX + miniWidth, miniY + miniHeight }, colors.background, miniRadius);
    if (fillWidth > 0) then
        drawList:AddRectFilled({ miniX, miniY }, { miniX + fillWidth, miniY + miniHeight }, colors.fill, miniRadius);
    end

    local isEnemy = entities.IsEnemy(index) == true;
    local nameStyle = GetInheritedNameStyle(entity, index, isEnemy);
    local fontSize = textSettings.fontSize or 14;
    local nameText = tostring(entity.Name or '');
    local nameX = miniX + 8;
    local nameY = miniY + math.floor(tonumber(textSettings.nameOffsetY) or -19);

    AddTextureText(drawList, nameX, nameY, nameText, nameStyle, fontSize);

    return {
        targetIndex = index,
        x1 = math.min(miniX - miniBorderSize, arrowSize > 0 and arrowX or miniX),
        y1 = math.min(miniY - miniBorderSize, nameY, arrowSize > 0 and arrowY or miniY),
        x2 = math.max(miniX + miniWidth + miniBorderSize, arrowSize > 0 and (arrowX + arrowSize) or (miniX + miniWidth)),
        y2 = math.max(miniY + miniHeight + miniBorderSize, arrowSize > 0 and (arrowY + arrowSize) or (miniY + miniHeight)),
    };
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

function currentTargetBar.HandlePacketIn(e)
    local targetingSettings = targeting.GetSettings();
    local settings = targetingSettings ~= nil and targetingSettings.currentTargetBar or nil;
    local targetOfTargetSettings = settings ~= nil and settings.targetOfTarget or nil;

    if (
        settings == nil or
        settings.enabled ~= true or
        targetOfTargetSettings == nil or
        targetOfTargetSettings.enabled ~= true
    ) then
        return;
    end

    local packet = ParseActionPacket(e);
    if (packet == nil or packet.UserId == nil) then
        return;
    end

    if (IsCombatActionType(packet.Type) ~= true) then
        return;
    end

    if (IsPlayerServerId(packet.UserId) == true) then
        return;
    end

    if (packet.Targets == nil or packet.Targets[1] == nil or packet.Targets[1].Id == nil) then
        return;
    end

    local targetIndex = actionRelevance.GetIndexFromServerId(packet.Targets[1].Id);
    if (targetIndex == nil or tonumber(targetIndex) == 0) then
        return;
    end

    targetOfTargetActionTracker[packet.UserId] = {
        targetId = packet.Targets[1].Id,
        targetIndex = tonumber(targetIndex),
        timestamp = os.time(),
    };

    targetOfTargetActionCount = targetOfTargetActionCount + 1;
    if ((targetOfTargetActionCount % 100) == 0) then
        CleanupTargetOfTargetTracker();
    end
end

function currentTargetBar.HandleMouse(e)
    if (e == nil or tonumber(e.message) ~= 513) then
        return false;
    end

    if (IsImguiCapturingMouse() == true) then
        return false;
    end

    if (IsPointInRect(e.x, e.y, lastTargetOfTargetClickRect) ~= true) then
        return false;
    end

    if (targeting.SelectTarget(lastTargetOfTargetClickRect.targetIndex) == true) then
        e.blocked = true;
        return true;
    end

    return false;
end

function currentTargetBar.Render()
    local targetingSettings = targeting.GetSettings();
    local settings = targetingSettings.currentTargetBar;
    if (settings == nil or settings.enabled ~= true) then
        lastTargetOfTargetClickRect = nil;
        return;
    end

    local entity, targetIndex = GetTarget();
    if (entity == nil) then
        lastTargetOfTargetClickRect = nil;
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
        lastTargetOfTargetClickRect = nil;
        if (beganTextWindow == true) then
            EndTextWindow();
        end
        return;
    end

    local buffRows = (settings.buffs ~= nil and settings.buffs.enabled == true)
        and GetStatusRows(targetIndex, entity, 'buff', isEnemy)
        or {};
    local debuffRows = (settings.debuffs ~= nil and settings.debuffs.enabled == true)
        and GetStatusRows(targetIndex, entity, 'debuff', isEnemy)
        or {};

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

    lastTargetOfTargetClickRect = DrawTargetOfTargetBar(drawList, x, y, width, height, radius, borderSize, {
        background = bgColor,
        fill = fillColor,
        border = borderColor,
    }, textSettings, targetIndex, settings.targetOfTarget);

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
