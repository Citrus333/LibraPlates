local imgui = require('imgui');
local targetPosition = require('core.target_position');
local state = require('core.state');
local textureLoader = require('core.texture_loader');
local arrowAnimation = require('core.target_arrow_animation');
local fonts = require('core.fonts');
local textScale = require('core.text_scale');
local entities = require('core.entities');
local npcObjectInfo = require('core.npc_object_info');
local globalDefaults = require('config.global');
local nameDefaults = require('config.widgets.name');
local distanceDefaults = require('config.widgets.distance');
local typeLineDefaults = require('config.widgets.type_line');
local npcObjectIconDefaults = require('config.widgets.npc_object_icon');
local gdiTextTexture = require('ui.gdi_text_texture');
local worldMarkerProbe = require('core.world_marker_probe');
local overlaySuppression = require('core.overlay_suppression');
local targetModuleMarker = require('core.target_module_marker');
local nativeUiPolicy = require('core.native_ui_policy');
local perfMeter = require('core.perf_meter');

local targetOverlay = {};
local textureIds = {};
local overlayScale = 0.35;
local chevronMinEdgeSpacing = 28;
local chevronMaxEdgeSpacing = 280;
local lastDebug = 'target overlay has not drawn yet';
local lastNativeHideDebug = 'native hide gate has not run yet';
local DrawImage;
local bstMainJobId = 9;
local smnMainJobId = 15;
local drgMainJobId = 14;
local pupMainJobId = 18;
local geoMainJobId = 21;

local function CleanDisplayName(name)
    local text = tostring(name or ''):gsub('\170', '');
    text = text:gsub('%c', '');
    text = text:gsub('^%s+', ''):gsub('%s+$', '');
    return text;
end

local function GetManualNameOutlineRadius(value)
    local size = math.max(0, tonumber(value) or 0);

    if (size <= 2) then
        return 0;
    end

    return math.min(8, math.floor(size + 0.5));
end

local function BuildOutlineOffsets(radius)
    local r = math.max(0, tonumber(radius) or 0);

    if (r <= 0) then
        return {};
    end

    local inner = math.max(1, math.floor((r * 0.55) + 0.5));

    return {
        { -r, 0 }, { r, 0 }, { 0, -r }, { 0, r },
        { -r, -r }, { r, -r }, { -r, r }, { r, r },
        { -inner, 0 }, { inner, 0 }, { 0, -inner }, { 0, inner },
        { -inner, -inner }, { inner, -inner }, { -inner, inner }, { inner, inner },
    };
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

local function GetTextureId(category, fileName)
    fileName = tostring(fileName or 'None'):gsub('^.*[\\/]', '');

    if (fileName == '' or fileName == 'None') then
        return nil;
    end

    local key = tostring(category) .. '/' .. fileName;

    if (textureIds[key] ~= nil) then
        return textureIds[key];
    end

    textureIds[key] = textureLoader.ToTextureId(textureLoader.Load(
        GetAddonPath() .. 'assets\\images\\target\\' .. tostring(category or '') .. '\\' .. fileName
    ));

    return textureIds[key];
end

local function Number(settings, key, fallback)
    local value = tonumber(settings ~= nil and settings[key]);

    if (value == nil) then
        return fallback;
    end

    return value;
end

local function Clamp(value, fallback, minValue, maxValue)
    value = tonumber(value) or fallback;

    if (value < minValue) then
        return minValue;
    end

    if (value > maxValue) then
        return maxValue;
    end

    return value;
end

local function ClampNumber(value, minValue, maxValue)
    value = tonumber(value);

    if (value == nil) then
        return nil;
    end

    if (value < minValue) then
        return minValue;
    end

    if (value > maxValue) then
        return maxValue;
    end

    return value;
end

local function GetDistanceNameScale(ent)
    if (ent == nil or ent.Distance == nil) then
        return 1.0;
    end

    local distance = math.sqrt(math.max(0, tonumber(ent.Distance) or 0));

    if (distance <= 0) then
        return 1.0;
    end

    return ClampNumber(14.0 / distance, 0.32, 3.5) or 1.0;
end

local function Color(settings, defaults, key)
    if (settings ~= nil and key ~= nil and settings[key] ~= nil) then
        return settings[key];
    end

    if (defaults ~= nil and key ~= nil and defaults[key] ~= nil) then
        return defaults[key];
    end

    return settings ~= nil and settings.color or defaults.color or { 1.0, 1.0, 1.0, 1.0 };
end

local function CloneColor(source, fallback)
    if (type(source) ~= 'table') then
        source = fallback;
    end

    fallback = type(fallback) == 'table' and fallback or { 1.0, 1.0, 1.0, 1.0 };

    if (type(source) ~= 'table') then
        return {
            fallback[1],
            fallback[2],
            fallback[3],
            fallback[4],
        };
    end

    return {
        tonumber(source[1]) or fallback[1],
        tonumber(source[2]) or fallback[2],
        tonumber(source[3]) or fallback[3],
        tonumber(source[4]) or fallback[4],
    };
end

local function ResolveArrowDistanceColor(distance, settings)
    return CloneColor(settings and settings.arrowColor);
end

local function GetColorU32(color)
    if (imgui.GetColorU32 ~= nil) then
        return imgui.GetColorU32(color);
    end

    return 0xFFFFFFFF;
end

local function DrawTargetDistance(drawList, ent, context, layoutStateName, cx, cy)
    if (ent == nil or ent.Distance == nil) then
        return;
    end

    local entityName = tostring(context ~= nil and context.entityName or '');

    if (entityName ~= 'Enemy' and entityName ~= 'PC') then
        return;
    end

    local settings = state.GetWidgetSettings(entityName, layoutStateName, 'Distance', distanceDefaults);

    if (settings == nil or settings.enabled ~= true) then
        return;
    end

    local distance = math.sqrt(math.max(0, tonumber(ent.Distance) or 0));
    local text = tostring(settings.prefix or '') .. string.format('%.1f', distance);
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local textureId, textW, textH = gdiTextTexture.GetTexture(text, {
        fontFamily = fonts.GetRole(globalSettings, settings.useSmallFont == true),
        fontFlags = fonts.GetRoleFlags(globalSettings, settings.useSmallFont == true),
        fontSize = textScale.ToTextureFontSize(settings.textSize, distanceDefaults.textSize),
        color = settings.color or distanceDefaults.color,
        outlineEnabled = settings.outlineEnabled == true,
        outlineColor = settings.outlineColor or distanceDefaults.outlineColor,
        outlineSize = tonumber(settings.outlineSize) or distanceDefaults.outlineSize,
    });

    if (textureId == nil or tonumber(textW) == nil or tonumber(textH) == nil or textW <= 0 or textH <= 0) then
        return;
    end

    local drawW = textW * overlayScale;
    local drawH = textH * overlayScale;
    local textX = cx + ((tonumber(settings.offsetX) or distanceDefaults.offsetX) * overlayScale) - (drawW * 0.5);
    local textY = cy + ((tonumber(settings.offsetY) or distanceDefaults.offsetY) * overlayScale) - (drawH * 0.5);

    DrawImage(drawList, textureId, textX, textY, drawW, drawH, 0xFFFFFFFF);
end

local function GetTargetManager()
    local memory = AshitaCore:GetMemoryManager();

    if (memory == nil) then
        return nil;
    end

    return memory:GetTarget();
end

local function GetPartyManager()
    local memory = AshitaCore:GetMemoryManager();

    if (memory == nil) then
        return nil;
    end

    return memory:GetParty();
end

local function TargetCall(target, fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function GetTargets()
    local target = GetTargetManager();

    if (target == nil) then
        return nil, nil;
    end

    local subActive = TargetCall(target, 0, function() return target:GetIsSubTargetActive(); end);
    local flags = TargetCall(target, 0xFFFFFFFF, function() return target:GetSubTargetFlags(); end);
    local mainIndex = 0;
    local subIndex = 0;

    if (subActive == 1 or subActive == true) then
        mainIndex = 0;
        subIndex = TargetCall(target, 0, function() return target:GetTargetIndex(0); end);

        if (subIndex == 0) then
            subIndex = TargetCall(target, 0, function() return target:GetTargetIndex(1); end);
        end
    elseif (flags == 0xFFFFFFFF) then
        mainIndex = TargetCall(target, 0, function() return target:GetTargetIndex(0); end);
    else
        subIndex = TargetCall(target, 0, function() return target:GetTargetIndex(0); end);
    end

    if (mainIndex == 0) then mainIndex = nil; end
    if (subIndex == 0) then subIndex = nil; end

    return mainIndex, subIndex;
end

local function IsPartyMemberIndex(index)
    index = tonumber(index);

    if (index == nil or index == 0) then
        return false;
    end

    local party = GetPartyManager();

    if (party == nil) then
        return false;
    end

    for slot = 1, 17 do
        local okActive, active = pcall(function()
            return party:GetMemberIsActive(slot);
        end);

        if (okActive == true and (active == 1 or active == true)) then
            local okIndex, memberIndex = pcall(function()
                return party:GetMemberTargetIndex(slot);
            end);

            if (okIndex == true and tonumber(memberIndex) == index) then
                return true;
            end
        end
    end

    return false;
end

local function GetPartySlotInfo(index)
    index = tonumber(index);

    if (index == nil or index == 0) then
        return 'none';
    end

    local party = GetPartyManager();

    if (party == nil) then
        return 'no-party';
    end

    for slot = 0, 17 do
        local okActive, active = pcall(function()
            return party:GetMemberIsActive(slot);
        end);
        local okIndex, memberIndex = pcall(function()
            return party:GetMemberTargetIndex(slot);
        end);

        if (okActive == true and (active == 1 or active == true) and okIndex == true and tonumber(memberIndex) == index) then
            return tostring(slot);
        end
    end

    return 'none';
end

local function ResolveEntityContext(index)
    local ent = GetEntity(index);
    local selfEntity = entities.GetSelf();
    local ownBstPet = nil;
    local ownSmnPet = nil;
    local ownDrgPet = nil;
    local ownLuopan = nil;
    local entityName = 'Enemy';
    local targetType = 'enemy';
    local valid = true;
    local resolvedInfo = nil;

    if (entities.GetPlayerMainJobId() == bstMainJobId) then
        ownBstPet = entities.GetOwnBstPet();
    elseif (entities.GetPlayerMainJobId() == smnMainJobId) then
        ownSmnPet = entities.GetOwnSmnPet();
    elseif (entities.GetPlayerMainJobId() == drgMainJobId) then
        ownDrgPet = entities.GetOwnDrgPet();
    elseif (entities.GetPlayerMainJobId() == geoMainJobId) then
        ownLuopan = entities.GetOwnLuopan();
    end

    if (
        ent == nil or
        ent.Name == nil or
        ent.Name == '' or
        (ent.HPPercent ~= nil and tonumber(ent.HPPercent) ~= nil and tonumber(ent.HPPercent) <= 0)
    ) then
        valid = false;
    end

    if (
        ownBstPet ~= nil and
        tonumber(ownBstPet.index) == tonumber(index)
    ) then
        entityName = 'Pet (BST)';
        targetType = 'pet';
        valid = true;
    elseif (
        ownSmnPet ~= nil and
        tonumber(ownSmnPet.index) == tonumber(index)
    ) then
        entityName = 'Pet (SMN)';
        targetType = 'pet';
        valid = true;
    elseif (
        ownDrgPet ~= nil and
        tonumber(ownDrgPet.index) == tonumber(index)
    ) then
        entityName = 'Wyvern';
        targetType = 'pet';
        valid = true;
    elseif (entities.GetPlayerMainJobId() == pupMainJobId and entities.IsOwnPetIndex(index) == true) then
        entityName = 'Automaton';
        targetType = 'pet';
        valid = true;
    elseif (
        (ownLuopan ~= nil and tonumber(ownLuopan.index) == tonumber(index)) or
        entities.IsOwnLuopanIndex(index) == true
    ) then
        entityName = 'Luopan';
        targetType = 'pet';
        valid = true;
    elseif (selfEntity ~= nil and tonumber(selfEntity.index) == tonumber(index)) then
        entityName = 'Self';
        targetType = 'self';
        valid = true;
    elseif (IsPartyMemberIndex(index) == true and (tonumber(index) == nil or tonumber(index) < 1024 or tonumber(index) > 1791)) then
        entityName = 'Trust';
        targetType = 'trust';
    elseif (tonumber(index) ~= nil and tonumber(index) >= 1024 and tonumber(index) <= 1791) then
        entityName = 'PC';
        targetType = 'pc';
    elseif (entities.GetEnemy(index, true) ~= nil) then
        entityName = 'Enemy';
        targetType = 'enemy';
    else
        local rawEntityName = (ent ~= nil and (ent.Type == 2 or ent.Type == 3)) and 'Object' or 'NPC';
        local displayName = CleanDisplayName(ent ~= nil and ent.Name or '');
        local resolvedEntityName, info = npcObjectInfo.ResolveKind(displayName, rawEntityName, { targetIndex = index });

        entityName = resolvedEntityName;
        targetType = (resolvedEntityName == 'Object') and 'object' or 'npc';
        resolvedInfo = info;
    end

    return {
        entityName = entityName,
        targetType = targetType,
        layoutStateName = (ownBstPet ~= nil and tonumber(ownBstPet.index) == tonumber(index))
            and ((ownBstPet.durationMinutes ~= nil) and 'Jug Pet' or 'Charmed Pet')
            or (ownSmnPet ~= nil and tonumber(ownSmnPet.index) == tonumber(index))
            and ((ownSmnPet.petType == 'spirit') and 'Spirit' or 'Avatar')
            or ((ownDrgPet ~= nil and tonumber(ownDrgPet.index) == tonumber(index)) and 'Wyvern')
            or ((entities.GetPlayerMainJobId() == pupMainJobId and entities.IsOwnPetIndex(index) == true) and 'Automaton')
            or (((ownLuopan ~= nil and tonumber(ownLuopan.index) == tonumber(index)) or entities.IsOwnLuopanIndex(index) == true) and 'Luopan')
            or ((ent ~= nil and ent.Status == 1) and 'Combat' or 'Idle'),
        valid = valid,
        partySlot = GetPartySlotInfo(index),
        rawTargetType = (ent ~= nil and (ent.Type == 2 or ent.Type == 3)) and 'object' or 'npc',
        resolvedInfo = resolvedInfo,
    };
end

local function IsRawObjectContext(context)
    return context ~= nil and tostring(context.rawTargetType or '') == 'object';
end

local function IsUnknownRawObjectNpcContext(context)
    return
        IsRawObjectContext(context) == true and
        tostring(context.targetType or '') == 'npc' and
        context.resolvedInfo == nil;
end

local function HasNpcObjectWorldPlateRect(index)
    return
        worldMarkerProbe.GetWidestPlateRect(index, 'npc', { 'name', 'type' }) ~= nil or
        worldMarkerProbe.GetWidestPlateRect(index, 'object', { 'name', 'type' }) ~= nil;
end

local function DrawFallbackTargetName(drawList, index, context, stateName, cx, cy, scale)
    local ent = GetEntity(index);
    local displayName = CleanDisplayName(ent ~= nil and ent.Name or '');

    if (displayName == '') then
        return;
    end

    if (HasNpcObjectWorldPlateRect(index) == true) then
        return;
    end

    local rawEntityName = IsRawObjectContext(context) == true and 'Object' or tostring(context.entityName or 'NPC');
    local _, knownInfo = npcObjectInfo.ResolveKind(displayName, rawEntityName, { targetIndex = index });

    if (knownInfo ~= nil) then
        return;
    end

    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local nameSettings = state.GetWidgetSettings(context.entityName, 'Idle', 'Name', nameDefaults);
    local textureId, textW, textH = gdiTextTexture.GetTexture(displayName, {
        fontFamily = fonts.GetRole(globalSettings, false),
        fontFlags = fonts.GetRoleFlags(globalSettings, false),
        fontSize = textScale.ToTextureFontSize(nameSettings.textSize, nameDefaults.textSize),
        color = nameSettings.color or nameDefaults.color,
        outlineEnabled = nameSettings.outlineEnabled == true,
        outlineColor = nameSettings.outlineColor or nameDefaults.outlineColor,
        outlineSize = tonumber(nameSettings.outlineSize) or nameDefaults.outlineSize,
    });

    if (textureId == nil or tonumber(textW) == nil or tonumber(textH) == nil or textW <= 0 or textH <= 0) then
        return;
    end

    local fallbackScale = 0.38;
    local drawW = textW * fallbackScale;
    local drawH = textH * fallbackScale;
    local textX = cx - (drawW * 0.5) + (Number(nameSettings, 'offsetX', 0) * scale);
    local textY = cy + (Number(nameSettings, 'offsetY', nameDefaults.offsetY) * scale);
    DrawImage(drawList, textureId, textX, textY, drawW, drawH, 0xFFFFFFFF);
end

local function IsDataBackedObjectTarget(index)
    local ent = GetEntity(index);

    if (ent == nil or ent.Name == nil or ent.Name == '') then
        return false;
    end

    local rawEntityName = (ent.Type == 2 or ent.Type == 3) and 'Object' or 'NPC';
    local displayName = tostring(ent.Name):gsub('\170', '');
    local resolvedEntityName, info = npcObjectInfo.ResolveKind(displayName, rawEntityName, { targetIndex = index });

    return resolvedEntityName == 'Object' and info ~= nil;
end

local objectFallbackTransitions = {};

local function CanDrawDataBackedObjectFallback(slotName, index)
    local slot = tostring(slotName or 'Target');

    if (IsDataBackedObjectTarget(index) ~= true) then
        objectFallbackTransitions[slot] = nil;
        return true;
    end

    local now = os.clock();
    local transition = objectFallbackTransitions[slot];

    if (transition == nil or tonumber(transition.index) ~= tonumber(index)) then
        objectFallbackTransitions[slot] = {
            index = index,
            firstSeen = now,
        };
        return false;
    end

    -- The regular object plate and its click rectangle are produced in
    -- different render phases.  Give that plate time to publish its bounds
    -- before enabling the emergency overlay, otherwise the first target
    -- frame draws a duplicate arrow and enlarged fallback name.
    return (now - (tonumber(transition.firstSeen) or now)) >= 0.10;
end

DrawImage = function(drawList, textureId, x, y, w, h, tint)
    if (drawList == nil or textureId == nil or tonumber(textureId) == nil or tonumber(textureId) == 0) then
        return false;
    end

    drawList:AddImage(tonumber(textureId), { x, y }, { x + w, y + h }, { 0, 0 }, { 1, 1 }, tint);
    return true;
end;

local function DrawFallbackCorners(drawList, cx, cy, settings, tint)
    local width = Number(settings, 'width', 220);
    local height = Number(settings, 'height', 74);
    local corner = math.max(8, Number(settings, 'cornerLength', 12));
    local thickness = math.max(1, Number(settings, 'thickness', 2));
    local x = cx - (width * 0.5) + Number(settings, 'chevronOffsetX', 0);
    local y = cy - (height * 0.5) + Number(settings, 'chevronOffsetY', 0);

    drawList:AddRectFilled({ x, y }, { x + corner, y + thickness }, tint);
    drawList:AddRectFilled({ x, y }, { x + thickness, y + corner }, tint);
    drawList:AddRectFilled({ x + width - corner, y }, { x + width, y + thickness }, tint);
    drawList:AddRectFilled({ x + width - thickness, y }, { x + width, y + corner }, tint);
    drawList:AddRectFilled({ x, y + height - thickness }, { x + corner, y + height }, tint);
    drawList:AddRectFilled({ x, y + height - corner }, { x + thickness, y + height }, tint);
    drawList:AddRectFilled({ x + width - corner, y + height - thickness }, { x + width, y + height }, tint);
    drawList:AddRectFilled({ x + width - thickness, y + height - corner }, { x + width, y + height }, tint);
end

local function DrawAlwaysVisiblePlates(drawList)
    for _, plate in ipairs(worldMarkerProbe.GetAlwaysVisiblePlates()) do
        local rect = plate.rect;
        local textureId = tonumber(plate.textureId);
        if (
            rect ~= nil and
            textureId ~= nil and
            textureId ~= 0 and
            tonumber(rect.x1) ~= nil and
            tonumber(rect.y1) ~= nil and
            tonumber(rect.x2) ~= nil and
            tonumber(rect.y2) ~= nil
        ) then
            if (perfMeter ~= nil and perfMeter.CountDrawnCanvas ~= nil) then
                perfMeter.CountDrawnCanvas(
                    plate.targetType,
                    plate.textureWidth,
                    plate.textureHeight,
                    plate.worldWidth,
                    plate.worldHeight
                );
            end

            drawList:AddImage(
                textureId,
                { rect.x1, rect.y1 },
                { rect.x2, rect.y2 },
                { 0, 0 },
                { 1, 1 },
                0xFFFFFFFF
            );

            local animatedMarker = plate.animatedTargetMarker;
            local function DrawAnimatedComponent(component)
                if (
                    component == nil or
                    tonumber(component.textureId) == nil or
                    tonumber(component.textureId) == 0 or
                    tonumber(component.x1) == nil or
                    tonumber(component.y1) == nil or
                    tonumber(component.x2) == nil or
                    tonumber(component.y2) == nil
                ) then
                    return;
                end

                local textureWidth = math.max(1, tonumber(plate.textureWidth) or 1);
                local textureHeight = math.max(1, tonumber(plate.textureHeight) or 1);
                local screenWidth = tonumber(rect.x2) - tonumber(rect.x1);
                local screenHeight = tonumber(rect.y2) - tonumber(rect.y1);
                local x1 = tonumber(rect.x1) + ((tonumber(component.x1) / textureWidth) * screenWidth);
                local y1 = tonumber(rect.y1) + ((tonumber(component.y1) / textureHeight) * screenHeight);
                local x2 = tonumber(rect.x1) + ((tonumber(component.x2) / textureWidth) * screenWidth);
                local y2 = tonumber(rect.y1) + ((tonumber(component.y2) / textureHeight) * screenHeight);

                drawList:AddImage(
                    tonumber(component.textureId),
                    { x1, y1 },
                    { x2, y2 },
                    { 0, 0 },
                    { 1, 1 },
                    GetColorU32(component.color or { 1, 1, 1, 1 })
                );
            end

            if (animatedMarker ~= nil) then
                DrawAnimatedComponent(animatedMarker.lock);
                DrawAnimatedComponent(animatedMarker.arrow);
                perfMeter.Count('pc.targetArrow.liveDraw', 1);
            end

            if (worldMarkerProbe.GetCanvasCenterDebug() == true) then
                local cx = (rect.x1 + rect.x2) * 0.5;
                local cy = (rect.y1 + rect.y2) * 0.5;
                drawList:AddRectFilled({ rect.x1, rect.y1 }, { rect.x2, rect.y2 }, 0x4400FFFF);
                drawList:AddRect({ rect.x1, rect.y1 }, { rect.x2, rect.y2 }, 0xFF00FFFF, 0, 0, 2);
                drawList:AddRectFilled({ cx - 5, cy - 5 }, { cx + 5, cy + 5 }, 0xFFFF2020);
                drawList:AddRect({ cx - 8, cy - 8 }, { cx + 8, cy + 8 }, 0xFFFFFF00, 0, 0, 2);
            end
        end
    end
end

local function DrawObjectTargetInfo(drawList, index)
    local context = ResolveEntityContext(index);

    if (context.valid ~= true or context.targetType ~= 'object') then
        return;
    end

    if (entities.IsMogHouseFurniturePlaceholder(index) == true) then
        return;
    end

    local ent = GetEntity(index);

    if (ent == nil or ent.Name == nil or ent.Name == '') then
        return;
    end

    if (
        worldMarkerProbe.GetWidestPlateRect(index, 'object', { 'name', 'type' }) ~= nil or
        worldMarkerProbe.GetWidestPlateRect(index, 'npc', { 'name', 'type' }) ~= nil
    ) then
        return;
    end

    local displayName = tostring(ent.Name):gsub('\170', '');
    local info = npcObjectInfo.Find(displayName, 'Object', { targetIndex = index });

    if (info == nil) then
        return;
    end

    local pos = targetPosition.Resolve(index);

    if (pos == nil or pos.z < 0 or pos.z > 1) then
        return;
    end

    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local nameSettings = state.GetWidgetSettings('Object', 'Idle', 'Name', nameDefaults);
    local typeSettings = state.GetWidgetSettings('Object', 'Idle', 'Type line', typeLineDefaults);
    local iconSettings = state.GetWidgetSettings('Object', 'Idle', 'Icon', npcObjectIconDefaults);
    local nameText = displayName;
    local typeText = tostring(info.type or '');
    local iconTextureId = npcObjectInfo.GetTextureIdForInfo(info) or npcObjectInfo.GetTextureId(displayName, 'Object', { targetIndex = index });
    local fallbackScale = 0.38;
    local iconSize = math.max(6, math.min(256, tonumber(iconSettings.iconSize) or npcObjectIconDefaults.iconSize or 22));
    local nameTextureId = nil;
    local nameOutlineTextureId = nil;
    local nameOutlineRadius = 0;
    local nameW = 0;
    local nameH = 0;
    local textTextureId = nil;
    local textW = 0;
    local textH = 0;

    if (nameSettings.enabled == true and nameText ~= '') then
        nameOutlineRadius = GetManualNameOutlineRadius(nameSettings.outlineSize);
        nameTextureId, nameW, nameH = gdiTextTexture.GetTexture(nameText, {
            fontFamily = fonts.GetRole(globalSettings, false),
            fontFlags = fonts.GetRoleFlags(globalSettings, false),
            fontSize = textScale.ToNameTextureFontSize(nameSettings.textSize, nameDefaults.textSize),
            color = nameSettings.color or nameDefaults.color,
            outlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0 and nameOutlineRadius <= 0,
            outlineColor = nameSettings.outlineColor or nameDefaults.outlineColor,
            outlineSize = tonumber(nameSettings.outlineSize) or nameDefaults.outlineSize,
        });

        if (nameOutlineRadius > 0) then
            nameOutlineTextureId = select(1, gdiTextTexture.GetTexture(nameText, {
                fontFamily = fonts.GetRole(globalSettings, false),
                fontFlags = fonts.GetRoleFlags(globalSettings, false),
                fontSize = textScale.ToNameTextureFontSize(nameSettings.textSize, nameDefaults.textSize),
                color = nameSettings.outlineColor or nameDefaults.outlineColor,
                outlineEnabled = false,
                outlineColor = nameSettings.outlineColor or nameDefaults.outlineColor,
                outlineSize = 0,
            }));
        end
    end

    if (typeSettings.enabled == true and typeText ~= '') then
        textTextureId, textW, textH = gdiTextTexture.GetTexture(typeText, {
            fontFamily = fonts.GetRole(globalSettings, typeSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, typeSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(typeSettings.textSize, typeLineDefaults.textSize),
            color = typeSettings.color or typeLineDefaults.color,
            outlineEnabled = typeSettings.outlineEnabled == true,
            outlineColor = typeSettings.outlineColor or typeLineDefaults.outlineColor,
            outlineSize = tonumber(typeSettings.outlineSize) or typeLineDefaults.outlineSize,
        });
    end

    local showIcon = iconSettings.enabled == true and iconTextureId ~= nil;
    local showName = nameTextureId ~= nil and nameW > 0 and nameH > 0 and nameText ~= '';
    local showType = textTextureId ~= nil and textW > 0 and textH > 0 and typeText ~= '';

    if (showIcon ~= true and showName ~= true and showType ~= true) then
        return;
    end

    local gap = 5;
    local totalW = 0;
    local rowH = 0;
    local textBlockW = 0;
    local textBlockH = 0;
    local scaledNameW = nameW * fallbackScale;
    local scaledNameH = nameH * fallbackScale;
    local scaledNameOutlineRadius = nameOutlineRadius * fallbackScale;
    local scaledTextW = textW * fallbackScale;
    local scaledTextH = textH * fallbackScale;

    if (showIcon == true) then
        totalW = totalW + iconSize;
        rowH = math.max(rowH, iconSize);
    end

    if (showName == true) then
        textBlockW = math.max(textBlockW, scaledNameW + (scaledNameOutlineRadius * 2));
        textBlockH = textBlockH + scaledNameH + (scaledNameOutlineRadius * 2);
    end

    if (showType == true) then
        if (textBlockH > 0) then
            textBlockH = textBlockH + 2;
        end

        textBlockW = math.max(textBlockW, scaledTextW);
        textBlockH = textBlockH + scaledTextH;
    end

    if (textBlockW > 0 and textBlockH > 0) then
        if (totalW > 0) then
            totalW = totalW + gap;
        end

        totalW = totalW + textBlockW;
        rowH = math.max(rowH, textBlockH);
    end

    local x = pos.x - (totalW * 0.5);
    local y = pos.y + 24;

    if (showIcon == true) then
        DrawImage(drawList, iconTextureId, x, y + ((rowH - iconSize) * 0.5), iconSize, iconSize, 0xFFFFFFFF);
        x = x + iconSize + gap;
    end

    local textY = y + ((rowH - textBlockH) * 0.5);

    if (showName == true) then
        local nameX = x + ((textBlockW - scaledNameW) * 0.5);
        local nameY = textY + scaledNameOutlineRadius;

        if (nameOutlineTextureId ~= nil and nameOutlineRadius > 0) then
            for _, offset in ipairs(BuildOutlineOffsets(nameOutlineRadius)) do
                DrawImage(
                    drawList,
                    nameOutlineTextureId,
                    nameX + (offset[1] * fallbackScale),
                    nameY + (offset[2] * fallbackScale),
                    scaledNameW,
                    scaledNameH,
                    0xFFFFFFFF
                );
            end
        end

        DrawImage(drawList, nameTextureId, nameX, nameY, scaledNameW, scaledNameH, 0xFFFFFFFF);
        textY = textY + scaledNameH + (scaledNameOutlineRadius * 2) + 2;
    end

    if (showType == true) then
        DrawImage(drawList, textTextureId, x + ((textBlockW - scaledTextW) * 0.5), textY, scaledTextW, scaledTextH, 0xFFFFFFFF);
    end
end

local function GetValidRect(rect)
    if (rect == nil) then
        return nil;
    end

    local x1 = tonumber(rect.x1);
    local y1 = tonumber(rect.y1);
    local x2 = tonumber(rect.x2);
    local y2 = tonumber(rect.y2);

    if (x1 == nil or y1 == nil or x2 == nil or y2 == nil or x2 <= x1 or y2 <= y1) then
        return nil;
    end

    return {
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
    };
end

local function GetAutoPlaceAnchorKinds(value)
    if (tostring(value or '') == 'Name') then
        return { 'name' };
    end

    if (tostring(value or '') == 'HP Bar') then
        return { 'hp' };
    end

    return { 'name', 'hp' };
end

local function DrawHighlight(drawList, index, context, settings, defaults, cx, cy, scale)
    local textureId = settings.backgroundEnabled ~= false and GetTextureId('backgrounds', settings.backgroundFile) or nil;

    if (textureId == nil) then
        return nil;
    end

    local tint = GetColorU32(Color(settings, defaults, 'backgroundColor'));
    local autoPlace = settings.autoPlaceBackground ~= false;
    local offsetX = autoPlace == true and 0 or (Number(settings, 'backgroundOffsetX', 0) * scale);
    local offsetY = autoPlace == true and 0 or (Number(settings, 'backgroundOffsetY', 0) * scale);
    local x = nil;
    local y = nil;
    local w = nil;
    local h = nil;
    local anchorRect = GetValidRect(worldMarkerProbe.GetWidestPlateRect(index, context.targetType, GetAutoPlaceAnchorKinds(settings.backgroundAutoPlaceAnchor)));

    if (autoPlace == true and anchorRect ~= nil) then
        local spacing = math.max(0, Number(settings, 'backgroundSpacing', 0)) * scale;

        x = anchorRect.x1 - spacing + offsetX;
        y = anchorRect.y1 - spacing + offsetY;
        w = (anchorRect.x2 - anchorRect.x1) + (spacing * 2);
        h = (anchorRect.y2 - anchorRect.y1) + (spacing * 2);
    else
        w = Clamp(settings.backgroundWidth, 220, 1, 2000) * scale;
        h = Clamp(settings.backgroundHeight, 74, 1, 2000) * scale;

        local anchorX = cx;
        local anchorY = cy;

        if (anchorRect ~= nil) then
            anchorX = (anchorRect.x1 + anchorRect.x2) * 0.5;
            anchorY = (anchorRect.y1 + anchorRect.y2) * 0.5;
        end

        x = anchorX - (w * 0.5) + offsetX;
        y = anchorY - (h * 0.5) + offsetY;
    end

    if (DrawImage(drawList, textureId, x, y, w, h, tint) == true) then
        return {
            anchor = anchorRect,
            x = x,
            y = y,
            w = w,
            h = h,
            auto = autoPlace,
            textureId = textureId,
        };
    end

    return nil;
end

local function DrawOne(drawList, index, stateName, offsetY, drawHighlight)
    local context = ResolveEntityContext(index);

    if (context.valid ~= true) then
        lastDebug = string.format(
            '%s index=%s invalid/dead target',
            tostring(stateName),
            tostring(index)
        );
        return;
    end

    if (context.targetType == 'pet' and stateName == 'Subtarget') then
        lastDebug = string.format(
            '%s index=%s entity=%s layout=%s pet-subtarget-disabled',
            tostring(stateName),
            tostring(index),
            tostring(context.entityName),
            tostring(context.layoutStateName)
        );
        return;
    end

    if (context.targetType == 'pet') then
        local globalSettings = state.GetGlobalSettings(globalDefaults);
        local targetingSettings = globalSettings.targeting or {};

        if (targetingSettings.enablePetPlateTargeting == false) then
            lastDebug = string.format(
                '%s index=%s entity=%s layout=%s pet-targeting-disabled',
                tostring(stateName),
                tostring(index),
                tostring(context.entityName),
                tostring(context.layoutStateName)
            );
            return;
        end
    end

    local targetModuleLayout = (
        tostring(context.entityName or '') == 'NPC' and
        (stateName == 'Target' or stateName == 'Subtarget')
    ) and 'Combat' or context.layoutStateName;
    local settings, defaults = targetModuleMarker.GetSettings(context.entityName, targetModuleLayout, stateName);
    arrowAnimation.UpgradeLegacySettings(settings);

    if (settings.enabled ~= true) then
        lastDebug = string.format(
            '%s index=%s entity=%s layout=%s disabled',
            tostring(stateName),
            tostring(index),
            tostring(context.entityName),
            tostring(context.layoutStateName)
        );
        return;
    end

    local pos = targetPosition.Resolve(index);

    if (pos == nil or pos.z < 0 or pos.z > 1) then
        lastDebug = string.format(
            '%s index=%s entity=%s layout=%s pos=%s',
            tostring(stateName),
            tostring(index),
            tostring(context.entityName),
            tostring(context.layoutStateName),
            pos == nil and 'nil' or ('z=' .. tostring(pos.z))
        );
        return;
    end

    local ent = GetEntity(index);
    local arrowDistance = nil;
    local rawArrowDistance = ent and tonumber(ent.Distance);
    if (rawArrowDistance ~= nil) then
        arrowDistance = math.sqrt(math.max(0, rawArrowDistance));
    end

    local arrowTint = GetColorU32(ResolveArrowDistanceColor(arrowDistance, settings));
    local chevronTint = GetColorU32(Color(settings, defaults, 'chevronColor'));
    local cx = pos.x;
    local cy = pos.y + (tonumber(offsetY) or 0) - 20;
    local scale = 1.0;
    local nameWidth = nil;

    DrawTargetDistance(drawList, ent, context, targetModuleLayout, cx, cy);

    if (ent ~= nil and ent.Name ~= nil and ent.Name ~= '') then
        local globalSettings = state.GetGlobalSettings(globalDefaults);
        local nameSettings = state.GetWidgetSettings(context.entityName, targetModuleLayout, 'Name', nameDefaults);
        local _, measuredWidth = gdiTextTexture.GetTexture(tostring(ent.Name), {
            fontFamily = fonts.GetRole(globalSettings, false),
            fontFlags = fonts.GetRoleFlags(globalSettings, false),
            fontSize = textScale.ToTextureFontSize(nameSettings.textSize, nameDefaults.textSize),
            color = nameSettings.color or { 1.0, 1.0, 1.0, 1.0 },
            outlineEnabled = nameSettings.outlineEnabled == true,
            outlineColor = nameSettings.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
            outlineSize = tonumber(nameSettings.outlineSize) or 0,
        });

        nameWidth = ((tonumber(measuredWidth) or 0) + math.abs(Number(nameSettings, 'offsetX', 0))) * scale * GetDistanceNameScale(ent);
    end

    local highlightInfo = nil;

    if (drawHighlight == true) then
        highlightInfo = DrawHighlight(drawList, index, context, settings, defaults, cx, cy, scale);
    end

    local autoPlaceArrow = settings.autoPlaceArrow ~= false;
    local arrowW = Clamp(settings.arrowWidth, 20, 1, 200) * scale;
    local arrowH = Clamp(settings.arrowHeight, 20, 1, 200) * scale;
    local overlayArrowMaxSize = 32 * scale;
    local arrowLargestSide = math.max(arrowW, arrowH);

    if (arrowLargestSide > overlayArrowMaxSize) then
        local arrowClampScale = overlayArrowMaxSize / arrowLargestSide;
        arrowW = arrowW * arrowClampScale;
        arrowH = arrowH * arrowClampScale;
    end

    local arrowOffsetX = Number(settings, 'arrowOffsetX', 0) * scale;
    local arrowOffsetY = Number(settings, 'arrowOffsetY', 0) * scale;
    local arrowX = cx - (arrowW * 0.5) + arrowOffsetX;
    local arrowY = cy - ((37 + Number(settings, 'arrowSpacing', 10)) * scale) + arrowOffsetY;
    local arrowAnchorRect = nil;

    if (autoPlaceArrow == true) then
        arrowAnchorRect = worldMarkerProbe.GetWidestPlateRect(index, context.targetType, { 'name' });

        if (
            arrowAnchorRect ~= nil and
            tonumber(arrowAnchorRect.x1) ~= nil and
            tonumber(arrowAnchorRect.y1) ~= nil and
            tonumber(arrowAnchorRect.x2) ~= nil and
            tonumber(arrowAnchorRect.x2) > tonumber(arrowAnchorRect.x1)
        ) then
            local arrowGap = math.max(0, Number(settings, 'arrowSpacing', 10)) * scale;

            arrowX = ((tonumber(arrowAnchorRect.x1) + tonumber(arrowAnchorRect.x2)) * 0.5) - (arrowW * 0.5) + arrowOffsetX;
            arrowY = tonumber(arrowAnchorRect.y1) - arrowGap - arrowH + arrowOffsetY;
        end
    end

    local arrowAnimated = settings.arrowEnabled ~= false and settings.arrowSprite == true and arrowAnimation.HasSpriteFrames(settings.arrowFile) == true;
    local arrowTextureId = settings.arrowEnabled ~= false and arrowAnimation.GetTextureId(settings.arrowFile, arrowAnimated, Number(settings, 'arrowAnimationSpeed', 12)) or nil;
    local showArrow = arrowTextureId ~= nil;

    if (showArrow == true) then
        DrawImage(drawList, arrowTextureId, arrowX, arrowY, arrowW, arrowH, arrowTint);
    end

    local chevronFile = settings.chevronEnabled == false and 'None' or settings.chevronFile;
    local textureId = GetTextureId('chevrons', chevronFile);
    local showChevrons = textureId ~= nil;
    local chevW = Clamp(settings.chevronWidth, 24, 1, 200) * scale;
    local chevH = Clamp(settings.chevronHeight, 32, 1, 200) * scale;
    local userSpacing = math.max(0, Number(settings, 'chevronSpacing', 80) * 0.05);
    local autoPlaceChevrons = settings.autoPlaceChevrons ~= false;
    local offsetX = autoPlaceChevrons == true and 0 or (Number(settings, 'chevronOffsetX', 0) * scale);
    local offsetY = autoPlaceChevrons == true and 0 or (Number(settings, 'chevronOffsetY', 0) * scale);
    local chevY = cy - (chevH * 0.5) + offsetY;
    local leftX = nil;
    local rightX = nil;
    local chevronAnchorRect = nil;

    if (autoPlaceChevrons == true) then
        chevronAnchorRect = worldMarkerProbe.GetWidestPlateRect(index, context.targetType, GetAutoPlaceAnchorKinds(settings.chevronAutoPlaceAnchor));

        if (chevronAnchorRect ~= nil) then
            local anchorY1 = tonumber(chevronAnchorRect.y1);
            local anchorY2 = tonumber(chevronAnchorRect.y2);

            if (anchorY1 ~= nil and anchorY2 ~= nil and anchorY2 > anchorY1) then
                chevY = ((anchorY1 + anchorY2) * 0.5) - (chevH * 0.5) + offsetY;
            end

            leftX = (tonumber(chevronAnchorRect.x1) or cx) - userSpacing - chevW + offsetX;
            rightX = (tonumber(chevronAnchorRect.x2) or cx) + userSpacing + offsetX;
        end
    end

    if (leftX == nil or rightX == nil) then
        local targetWidth = Number(settings, 'width', 220) * scale;
        local edgeSpacing = math.max(chevronMinEdgeSpacing, (targetWidth * 0.5) + userSpacing + (chevW * 0.5));
        edgeSpacing = math.min(edgeSpacing, chevronMaxEdgeSpacing);
        leftX = cx - edgeSpacing - (chevW * 0.5) + offsetX;
        rightX = cx + edgeSpacing - (chevW * 0.5) + offsetX;
    end

    if (showChevrons == true and DrawImage(drawList, textureId, leftX, chevY, chevW, chevH, chevronTint) == true) then
        DrawImage(drawList, textureId, rightX + chevW, chevY, -chevW, chevH, chevronTint);
    end

    if (IsUnknownRawObjectNpcContext(context) == true) then
        DrawFallbackTargetName(drawList, index, context, stateName, cx, cy, scale);
    end

    lastDebug = string.format(
        '%s index=%s entity=%s layout=%s partySlot=%s pos=%s,%s highlightFile=%s highlightEnabled=%s highlightTex=%s highlightAuto=%s highlightAnchor=%s highlightXYWH=%s,%s,%s,%s arrowFile=%s arrowEnabled=%s arrowTex=%s arrowAuto=%s arrowAnchor=%s arrowXY=%s,%s arrowWH=%s,%s chevronAuto=%s chevronAnchor=%s chevronXY=%s,%s|%s,%s',
        tostring(stateName),
        tostring(index),
        tostring(context.entityName),
        tostring(context.layoutStateName),
        tostring(context.partySlot),
        tostring(pos.x),
        tostring(pos.y),
        tostring(settings.backgroundFile),
        tostring(settings.backgroundEnabled ~= false),
        tostring(highlightInfo ~= nil and highlightInfo.textureId or nil),
        tostring(highlightInfo ~= nil and highlightInfo.auto or nil),
        (highlightInfo == nil or highlightInfo.anchor == nil) and 'nil' or (tostring(highlightInfo.anchor.x1) .. ',' .. tostring(highlightInfo.anchor.y1) .. '-' .. tostring(highlightInfo.anchor.x2) .. ',' .. tostring(highlightInfo.anchor.y2)),
        tostring(highlightInfo ~= nil and highlightInfo.x or nil),
        tostring(highlightInfo ~= nil and highlightInfo.y or nil),
        tostring(highlightInfo ~= nil and highlightInfo.w or nil),
        tostring(highlightInfo ~= nil and highlightInfo.h or nil),
        tostring(settings.arrowFile),
        tostring(settings.arrowEnabled ~= false),
        tostring(arrowTextureId),
        tostring(autoPlaceArrow),
        arrowAnchorRect == nil and 'nil' or (tostring(arrowAnchorRect.x1) .. ',' .. tostring(arrowAnchorRect.y1) .. '-' .. tostring(arrowAnchorRect.x2) .. ',' .. tostring(arrowAnchorRect.y2)),
        tostring(arrowX),
        tostring(arrowY),
        tostring(arrowW),
        tostring(arrowH),
        tostring(autoPlaceChevrons),
        chevronAnchorRect == nil and 'nil' or (tostring(chevronAnchorRect.x1) .. ',' .. tostring(chevronAnchorRect.y1) .. '-' .. tostring(chevronAnchorRect.x2) .. ',' .. tostring(chevronAnchorRect.y2)),
        tostring(leftX),
        tostring(chevY),
        tostring(rightX),
        tostring(chevY)
    );
end

local function CanDrawOne(index, stateName)
    local context = ResolveEntityContext(index);

    if (context.valid ~= true) then
        return false;
    end

    if (context.targetType == 'pet' and stateName == 'Subtarget') then
        return false;
    end

    if (context.targetType == 'pet') then
        local globalSettings = state.GetGlobalSettings(globalDefaults);
        local targetingSettings = globalSettings.targeting or {};

        if (targetingSettings.enablePetPlateTargeting == false) then
            return false;
        end
    end

    local targetModuleLayout = (
        tostring(context.entityName or '') == 'NPC' and
        (stateName == 'Target' or stateName == 'Subtarget')
    ) and 'Combat' or context.layoutStateName;
    local settings = targetModuleMarker.GetSettings(context.entityName, targetModuleLayout, stateName);
    arrowAnimation.UpgradeLegacySettings(settings);

    return targetModuleMarker.HasDrawableSettings(context.entityName, settings) == true;
end

local function DescribeCanDrawOne(index, stateName)
    local context = ResolveEntityContext(index);

    if (context.valid ~= true) then
        return false, string.format('%s:%s invalid', tostring(stateName), tostring(index));
    end

    if (context.targetType == 'pet' and stateName == 'Subtarget') then
        return false, string.format('%s:%s %s/%s pet-subtarget-disabled', tostring(stateName), tostring(index), tostring(context.entityName), tostring(context.targetType));
    end

    if (context.targetType == 'pet') then
        local globalSettings = state.GetGlobalSettings(globalDefaults);
        local targetingSettings = globalSettings.targeting or {};

        if (targetingSettings.enablePetPlateTargeting == false) then
            return false, string.format('%s:%s %s/%s pet-targeting-disabled', tostring(stateName), tostring(index), tostring(context.entityName), tostring(context.targetType));
        end
    end

    local targetModuleLayout = (
        tostring(context.entityName or '') == 'NPC' and
        (stateName == 'Target' or stateName == 'Subtarget')
    ) and 'Combat' or context.layoutStateName;
    local settings = targetModuleMarker.GetSettings(context.entityName, targetModuleLayout, stateName);
    arrowAnimation.UpgradeLegacySettings(settings);
    local drawable = targetModuleMarker.HasDrawableSettings(context.entityName, settings) == true;

    return drawable, string.format(
        '%s:%s %s/%s layout=%s enabled=%s arrow=%s chevron=%s background=%s drawable=%s',
        tostring(stateName),
        tostring(index),
        tostring(context.entityName),
        tostring(context.targetType),
        tostring(targetModuleLayout),
        tostring(settings ~= nil and settings.enabled),
        tostring(settings ~= nil and settings.arrowFile),
        tostring(settings ~= nil and settings.chevronFile),
        tostring(settings ~= nil and settings.backgroundFile),
        tostring(drawable)
    );
end

function targetOverlay.CanHideNativeTargetUi()
    if (overlaySuppression.IsSuppressed() == true) then
        lastNativeHideDebug = 'suppressed';
        return false;
    end

    local mainIndex, subIndex = GetTargets();
    local count = 0;
    local parts = {};

    if (mainIndex ~= nil) then
        count = count + 1;
        local canDraw, reason = DescribeCanDrawOne(mainIndex, 'Target');
        table.insert(parts, reason);

        if (canDraw ~= true) then
            lastNativeHideDebug = table.concat(parts, ' ');
            return false;
        end
    end

    if (mainIndex ~= nil and subIndex ~= nil) then
        count = count + 1;
        local canDraw, reason = DescribeCanDrawOne(subIndex, 'Subtarget');
        table.insert(parts, reason);

        if (canDraw ~= true) then
            lastNativeHideDebug = table.concat(parts, ' ');
            return false;
        end
    end

    lastNativeHideDebug = (#parts > 0) and table.concat(parts, ' ') or 'no-targets';
    return count > 0;
end

targetOverlay.CanReplaceNativeTargetUi = targetOverlay.CanHideNativeTargetUi;

function targetOverlay.Render()
    if (overlaySuppression.IsSuppressed() == true) then
        return;
    end

    local drawList = imgui.GetForegroundDrawList ~= nil and imgui.GetForegroundDrawList() or nil;

    if (drawList == nil) then
        return;
    end

    DrawAlwaysVisiblePlates(drawList);

    if (nativeUiPolicy.ShouldDrawLibraTargetingSystem() ~= true) then
        lastDebug = 'target overlay skipped: native targeting system active';
        return;
    end

    local mainIndex, subIndex = GetTargets();

    if (mainIndex ~= nil) then
        local context = ResolveEntityContext(mainIndex);
        local canDrawFallback = CanDrawDataBackedObjectFallback('Target', mainIndex);
        local needsFallback =
            canDrawFallback == true and
            context.valid == true and
            (context.targetType == 'npc' or context.targetType == 'object' or IsUnknownRawObjectNpcContext(context) == true) and
            HasNpcObjectWorldPlateRect(mainIndex) ~= true;

        if (needsFallback == true) then
            DrawOne(drawList, mainIndex, 'Target', 0, true);
        end

        if (canDrawFallback == true) then
            DrawObjectTargetInfo(drawList, mainIndex);
        end
    else
        objectFallbackTransitions.Target = nil;
    end

    if (mainIndex ~= nil and subIndex ~= nil and subIndex ~= mainIndex) then
        local context = ResolveEntityContext(subIndex);
        local canDrawFallback = CanDrawDataBackedObjectFallback('Subtarget', subIndex);
        local needsFallback =
            canDrawFallback == true and
            context.valid == true and
            (context.targetType == 'npc' or context.targetType == 'object' or IsUnknownRawObjectNpcContext(context) == true) and
            HasNpcObjectWorldPlateRect(subIndex) ~= true;

        if (needsFallback == true) then
            DrawOne(drawList, subIndex, 'Subtarget', -18, true);
        end

        if (canDrawFallback == true) then
            DrawObjectTargetInfo(drawList, subIndex);
        end
    else
        objectFallbackTransitions.Subtarget = nil;
    end
end

function targetOverlay.GetDebugStatus()
    return lastDebug;
end

function targetOverlay.GetNativeHideDebugStatus()
    return lastNativeHideDebug;
end

return targetOverlay;
