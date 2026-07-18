local imgui = require('imgui');
local barTextures = require('core.bar_textures');
local barAnimations = require('core.bar_animations');
local canvasTexture = require('core.canvas_texture');
local entities = require('core.entities');
local gameMode = require('core.game_mode');
local statusIconTextures = require('core.status_icon_textures');
local statusTimerFormat = require('core.status_timer_format');
local jobIconTextures = require('core.job_icon_textures');
local textureLoader = require('core.texture_loader');
local iconPack = require('core.icon_pack');
local backgroundTextures = require('core.background_textures');
local targetModuleMarker = require('core.target_module_marker');
local aoeRangeVisuals = require('core.aoe_range_visuals');
local npcObjectInfo = require('core.npc_object_info');
local fishing = require('core.fishing');
local gathering = require('core.gathering');
local crafting = require('core.crafting');
local pupManeuvers = require('core.pup_maneuvers');
local fonts = require('core.fonts');
local textScale = require('core.text_scale');
local state = require('core.state');
local uiTooltip = require('core.ui_tooltip');
local globalDefaults = require('config.global');
local nameDefaults = require('config.widgets.name');
local backgroundDefaults = require('config.widgets.background');
local jobDefaults = require('config.widgets.job');
local levelDefaults = require('config.widgets.level');
local idDefaults = require('config.widgets.id');
local distanceDefaults = require('config.widgets.distance');
local typeLineDefaults = require('config.widgets.type_line');
local npcObjectIconDefaults = require('config.widgets.npc_object_icon');
local buffsDefaults = require('config.widgets.buffs');
local debuffsDefaults = require('config.widgets.debuffs');
local barDefaults = require('config.widgets.bar');
local mpBarDefaults = require('config.widgets.mp_bar');
local tpBarDefaults = require('config.widgets.tp_bar');
local castBarDefaults = require('config.widgets.cast_bar');
local maneuverDefaults = require('config.widgets.maneuvers');
local gameModeIconDefaults = require('config.widgets.game_mode_icon');
local bazaarIconDefaults = require('config.widgets.bazaar_icon');
local linkshellIconDefaults = require('config.widgets.linkshell_icon');
local enemyBehaviorIconDefaults = require('config.widgets.enemy_behavior_icon');
local enemyDetectsIconDefaults = require('config.widgets.enemy_detects_icon');
local enemyLinksIconDefaults = require('config.widgets.enemy_links_icon');
local enemySpecialIconDefaults = require('config.widgets.enemy_special_icon');
local awayIconDefaults = require('config.widgets.away_icon');
local disconnectIconDefaults = require('config.widgets.disconnect_icon');
local anonIconDefaults = require('config.widgets.anon_icon');
local followIconDefaults = require('config.widgets.follow_icon');
local partyLeaderIconDefaults = require('config.widgets.party_leader_icon');
local allianceLeaderIconDefaults = require('config.widgets.alliance_leader_icon');
local starsIconDefaults = require('config.widgets.stars_icon');
local levelSyncIconDefaults = require('config.widgets.level_sync_icon');
local newAdventurerIconDefaults = require('config.widgets.new_adventurer_icon');
local targetModuleDefaults = require('config.widgets.target_module');
local subtargetModuleDefaults = require('config.widgets.subtarget_module');
local aoeRangeDefaults = require('config.widgets.aoe_range');

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

local function GetPreviewPeerSettings(context)
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local peerSettings = CopyTable(globalSettings.peer or {});

    if (context ~= nil and tostring(context.widgetKey or '') == 'Peer') then
        local entityName = tostring(context.entityName or '');
        local stateName = tostring(context.stateName or '');

        if (entityName ~= '' and stateName ~= '') then
            local widgetSettings = state.GetWidgetSettings(entityName, stateName, 'Peer', { enabled = true });
            if (type(widgetSettings) == 'table') then
                for key, value in pairs(widgetSettings) do
                    peerSettings[key] = CopyTable(value);
                end
            end
        end
    end

    return peerSettings;
end

local petTimerDefaults = {
    enabled = true,
    displayMode = 'Text',
    iconSize = 18,
    labelOffsetX = 0,
    labelOffsetY = 0,
    textOffsetX = 0,
    textOffsetY = 0,
    textSize = 12,
    color = { 1.0, 1.0, 1.0, 1.0 },
    outlineEnabled = true,
    outlineColor = { 0.0, 0.0, 0.0, 1.0 },
    outlineSize = 2,
    offsetX = -52,
    offsetY = -52,
};
local petStateDefaults = {
    enabled = true,
    displayMode = 'Text',
    iconSize = 22,
    labelOffsetX = 0,
    labelOffsetY = 0,
    textSize = 12,
    color = { 1.0, 1.0, 1.0, 1.0 },
    outlineEnabled = true,
    outlineColor = { 0.0, 0.0, 0.0, 1.0 },
    outlineSize = 2,
    offsetX = 52,
    offsetY = -52,
};
local petReadyBarDefaults = {
    enabled = true,
    width = 160,
    height = 6,
    offsetX = 0,
    offsetY = 28,
    color = { 0.90, 0.65, 0.25, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    texture = 'Solid',
    color2 = { 0.80, 0.45, 1.0, 0.95 },
    color3 = { 0.35, 0.75, 1.0, 0.95 },
    segmented = true,
    segmentGap = 6,
    chargeSeconds = 30,
    labelDisplayMode = 'Text',
    labelIconSize = 14,
    labelIconOffsetX = 0,
    labelIconOffsetY = 0,
    showValue = false,
    showPercent = false,
    showAtPercent = 100,
    textOffsetX = 0,
    textOffsetY = 0,
    useSmallFont = true,
    fontSize = 7,
    textColor = { 1.0, 1.0, 1.0, 1.0 },
    textOutlineEnabled = true,
    textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
    textOutlineSize = 1,
};
local petRewardBarDefaults = {
    enabled = true,
    width = 160,
    height = 6,
    offsetX = 0,
    offsetY = 52,
    color = { 0.70, 0.90, 0.45, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    texture = 'Solid',
    labelDisplayMode = 'Text',
    labelIconSize = 14,
    labelIconOffsetX = 0,
    labelIconOffsetY = 0,
    showValue = false,
    showPercent = false,
    showAtPercent = 100,
    textOffsetX = 0,
    textOffsetY = 0,
    useSmallFont = true,
    fontSize = 7,
    textColor = { 1.0, 1.0, 1.0, 1.0 },
    textOutlineEnabled = true,
    textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
    textOutlineSize = 1,
};
local petWardBarDefaults = {
    enabled = true,
    width = 81,
    height = 12,
    offsetX = -44,
    offsetY = 16,
    color = { 0.00, 0.75, 0.85, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    texture = 'Solid',
    fillDirection = 'Left to right',
    labelDisplayMode = 'Text',
    labelIconSize = 14,
    labelIconOffsetX = 0,
    labelIconOffsetY = 0,
    showValue = false,
    showPercent = true,
    showAtPercent = 100,
    textOffsetX = 0,
    textOffsetY = 0,
    useSmallFont = true,
    fontSize = 7,
    textColor = { 1.0, 1.0, 1.0, 1.0 },
    textOutlineEnabled = true,
    textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
    textOutlineSize = 1,
};
local petRageBarDefaults = {
    enabled = true,
    width = 81,
    height = 12,
    offsetX = 44,
    offsetY = 16,
    color = { 0.85, 0.20, 0.10, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    texture = 'Solid',
    fillDirection = 'Left to right',
    labelDisplayMode = 'Text',
    labelIconSize = 14,
    labelIconOffsetX = 0,
    labelIconOffsetY = 0,
    showValue = false,
    showPercent = true,
    showAtPercent = 100,
    textOffsetX = 0,
    textOffsetY = 0,
    useSmallFont = true,
    fontSize = 7,
    textColor = { 1.0, 1.0, 1.0, 1.0 },
    textOutlineEnabled = true,
    textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
    textOutlineSize = 1,
};
local smnHpBarDefaults = {
    enabled = true,
    width = 170,
    height = 14,
    texture = 'Solid',
    color = { 0.95, 0.45, 0.45, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    offsetX = 0,
    offsetY = 0,
    showValue = false,
    showPercent = true,
    showAtPercent = 100,
    lowColorEnabled = false,
    lowColorPercent = 25,
    lowColor = { 1.0, 0.15, 0.10, 1.0 },
    lowAnimationEnabled = false,
    lowAnimation = 'Important',
    lowAnimationSpeed = 40,
    lowAnimationColor = { 1.0, 1.0, 1.0, 0.35 },
    textOffsetX = 0,
    textOffsetY = 0,
    useSmallFont = true,
    fontSize = 7,
    textColor = { 1.0, 1.0, 1.0, 1.0 },
    textOutlineEnabled = true,
    textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
    textOutlineSize = 1,
};
local smnMpBarDefaults = {
    enabled = true,
    width = 170,
    height = 12,
    texture = 'Solid',
    color = { 0.70, 0.90, 0.45, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    offsetX = 0,
    offsetY = 16,
    showValue = false,
    showPercent = true,
    showAtPercent = 100,
    lowColorEnabled = false,
    lowColorPercent = 25,
    lowColor = { 0.55, 0.25, 1.0, 1.0 },
    lowAnimationEnabled = false,
    lowAnimation = 'Important',
    lowAnimationSpeed = 40,
    lowAnimationColor = { 1.0, 1.0, 1.0, 0.35 },
    textOffsetX = 0,
    textOffsetY = 0,
    useSmallFont = true,
    fontSize = 7,
    textColor = { 1.0, 1.0, 1.0, 1.0 },
    textOutlineEnabled = true,
    textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
    textOutlineSize = 1,
};
local smnTpBarDefaults = {
    enabled = true,
    width = 170,
    height = 12,
    texture = 'Solid',
    color = { 0.0, 0.55, 0.95, 1.0 },
    color2 = { 0.80, 0.45, 1.0, 0.95 },
    color3 = { 0.35, 0.75, 1.0, 0.95 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    offsetX = 0,
    offsetY = 30,
    showValue = false,
    showPercent = false,
    showAtPercent = 300,
    lowColorEnabled = false,
    lowColorPercent = 25,
    lowColor = { 1.0, 0.30, 0.10, 1.0 },
    segmented = false,
    segmentGap = 6,
    textOffsetX = 0,
    textOffsetY = 0,
    useSmallFont = true,
    fontSize = 7,
    textColor = { 1.0, 1.0, 1.0, 1.0 },
    textOutlineEnabled = true,
    textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
    textOutlineSize = 1,
};
local smnCastBarDefaults = {
    enabled = true,
    width = 170,
    height = 10,
    texture = 'Solid',
    color = { 0.95, 0.75, 0.20, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    offsetX = 0,
    offsetY = 32,
    showSpellName = true,
    textOffsetX = 0,
    textOffsetY = 0,
    useSmallFont = true,
    fontSize = 8,
    textColor = { 1.0, 1.0, 1.0, 1.0 },
    textOutlineEnabled = true,
    textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
    textOutlineSize = 1,
};

local preview = {};
local iconCache = {};
local backgroundCache = {};
local petIconCache = {};
local quickMenuIconCache = {};
local quickMenuMissingIcons = {};
local trustBuffPreviewDefaults = {};
local previewInfoIconTextureId = nil;
local previewUiIconCache = {};
local luopanPreviewTextureId = nil;
local luopanPreviewTextureMissing = false;
local spiritPreviewTextureId = nil;
local spiritPreviewTextureMissing = false;
local selectedBackground = 'Light';
local selectedZoom = '1x';
local enemyPreviewNameMode = 'Long';
local dragEnabled = false;
local activeDragKind = nil;
local mouseInPreview = false;
local previewControlClickConsumed = false;
local backgroundOptions = T{ 'Light', 'Mid', 'Dark' };
local zoomOptions = T{ '1x', '2x' };
local backgroundFiles = {
    ['Light'] = 'bg_light.png',
    ['Mid'] = 'bg_mid.png',
    ['Dark'] = 'bg_dark.png',
};

for key, value in pairs(buffsDefaults) do
    trustBuffPreviewDefaults[key] = value;
end

trustBuffPreviewDefaults.enabled = true;

local function GetPreviewDifficultyColor(settings, defaults)
    if (settings == nil or settings.difficultyColorsEnabled ~= true) then
        return settings ~= nil and settings.color or defaults.color;
    end

    return settings.tColor or defaults.tColor or settings.color or defaults.color;
end

local function GetPreviewDifficultyOutlineColor(settings, defaults)
    if (settings == nil or settings.difficultyColorsEnabled ~= true) then
        return settings ~= nil and (settings.outlineColor or defaults.outlineColor) or defaults.outlineColor;
    end

    return settings.tOutlineColor or defaults.tOutlineColor or settings.outlineColor or defaults.outlineColor;
end

local function GetPreviewIdBoxColor(settings, defaults)
    if (settings == nil or settings.boxDifficultyColorsEnabled ~= true) then
        return settings ~= nil and settings.boxBackgroundColor or defaults.boxBackgroundColor;
    end

    return settings.boxTColor or defaults.boxTColor or settings.boxBackgroundColor or defaults.boxBackgroundColor;
end

local function ClampPercent(value, fallback)
    local percent = tonumber(value) or fallback or 100;

    if (percent < 0) then
        return 0;
    end

    if (percent > 100) then
        return 100;
    end

    return percent;
end

local function LoadWidgetIcon(fileName)
    local cacheKey = 'widget:' .. tostring(iconPack.GetRevision()) .. ':' .. tostring(fileName or '');

    if (iconCache[cacheKey] ~= nil) then
        return iconCache[cacheKey];
    end

    local path = iconPack.GetAssetPath('widget-icons', fileName);
    iconCache[cacheKey] = textureLoader.ToTextureId(textureLoader.Load(path));
    return iconCache[cacheKey];
end

local function LoadPreviewInfoIcon()
    if (previewInfoIconTextureId ~= nil) then
        return previewInfoIconTextureId;
    end

    previewInfoIconTextureId = textureLoader.ToTextureId(textureLoader.Load(addon.path .. '\\assets\\images\\ui-icons\\info.png'));
    return previewInfoIconTextureId;
end

local function LoadPreviewUiIcon(fileName)
    fileName = tostring(fileName or '');

    if (fileName == '') then
        return nil;
    end

    if (previewUiIconCache[fileName] ~= nil) then
        return previewUiIconCache[fileName];
    end

    previewUiIconCache[fileName] = textureLoader.ToTextureId(textureLoader.Load(addon.path .. '\\assets\\images\\ui-icons\\' .. fileName));
    return previewUiIconCache[fileName];
end

local function LoadPetIcon(fileName)
    if (petIconCache[fileName] ~= nil) then
        return petIconCache[fileName];
    end

    local path = addon.path .. '\\assets\\images\\pet\\' .. fileName;
    petIconCache[fileName] = textureLoader.ToTextureId(textureLoader.Load(path));
    return petIconCache[fileName];
end

local function LoadPetStateIcon(commandName)
    local iconName = tostring(commandName or ''):lower();

    if (iconName == 'sic') then
        iconName = 'ready';
    end

    local jobFolder = (iconName == 'ward' or iconName == 'rage') and 'smn' or 'bst';
    local key = jobFolder .. '/' .. iconName .. '.png';
    return LoadPetIcon(key);
end

local function SanitizePeerIconStyle(iconStyle)
    local style = tostring(iconStyle or 'round'):gsub('[\\/]', '');

    if (style == '') then
        return 'round';
    end

    return style;
end

local function LoadCatseyeIcon(fileName)
    local cacheKey = 'catseye:' .. tostring(iconPack.GetRevision()) .. ':' .. tostring(fileName or '');

    if (iconCache[cacheKey] ~= nil) then
        return iconCache[cacheKey];
    end

    local path = iconPack.GetAssetPath('catseye_icons', tostring(fileName or ''));
    iconCache[cacheKey] = textureLoader.ToTextureId(textureLoader.Load(path));
    return iconCache[cacheKey];
end

local function ResolveEnemyPreviewIconStyle(globalSettings, iconSettings)
    local style = tostring(iconSettings ~= nil and iconSettings.iconStyle or 'Use Settings theme default');

    if (style == '' or style == 'Use enemy default' or style == 'Use Settings theme default') then
        style = tostring(
            globalSettings ~= nil and globalSettings.enemyIconStyle or
            (globalSettings ~= nil and globalSettings.peer ~= nil and globalSettings.peer.iconStyle) or
            'round'
        );
    end

    return SanitizePeerIconStyle(style);
end

local function LoadPeerIcon(iconName, iconStyle)
    iconName = tostring(iconName or '');

    if (iconName == '') then
        return nil;
    end

    iconStyle = SanitizePeerIconStyle(iconStyle);

    local key = 'peer:' .. iconStyle .. ':' .. iconName;

    if (iconCache[key] ~= nil) then
        return iconCache[key];
    end

    local path = addon.path .. '\\assets\\images\\peer-icons\\' .. iconStyle .. '\\' .. iconName .. '.png';
    iconCache[key] = textureLoader.ToTextureId(textureLoader.Load(path));
    return iconCache[key];
end

local function LoadSelfElementIcon(iconName)
    iconName = tostring(iconName or '');

    if (iconName == '') then
        return nil;
    end

    local key = 'self-element:' .. tostring(iconPack.GetRevision()) .. ':' .. iconName;

    if (iconCache[key] ~= nil) then
        return iconCache[key];
    end

    local path = iconPack.GetAssetPath('self-peer', iconName .. '.png');
    iconCache[key] = textureLoader.ToTextureId(textureLoader.Load(path));
    return iconCache[key];
end

local function LoadBackground(name)
    local fileName = backgroundFiles[name] or backgroundFiles.Light;

    if (backgroundCache[fileName] ~= nil) then
        return backgroundCache[fileName];
    end

    local path = addon.path .. '\\assets\\images\\preview\\' .. fileName;
    backgroundCache[fileName] = textureLoader.ToTextureId(textureLoader.Load(path));
    return backgroundCache[fileName];
end

local function LoadLuopanPreviewTexture()
    if (luopanPreviewTextureId ~= nil or luopanPreviewTextureMissing == true) then
        return luopanPreviewTextureId;
    end

    local files = T{ 'Luopla.png', 'luopan.png' };

    for _, fileName in ipairs(files) do
        local path = addon.path .. '\\assets\\images\\geo-statuses\\' .. fileName;
        local textureId = textureLoader.ToTextureId(textureLoader.Load(path));

        if (textureId ~= nil) then
            luopanPreviewTextureId = textureId;
            return luopanPreviewTextureId;
        end
    end

    luopanPreviewTextureMissing = true;
    return nil;
end

local function LoadSpiritPreviewTexture()
    if (spiritPreviewTextureId ~= nil or spiritPreviewTextureMissing == true) then
        return spiritPreviewTextureId;
    end

    spiritPreviewTextureId = textureLoader.ToTextureId(textureLoader.Load(addon.path .. '\\assets\\images\\ui-icons\\light-spirit.png'));

    if (spiritPreviewTextureId == nil) then
        spiritPreviewTextureMissing = true;
    end

    return spiritPreviewTextureId;
end

local function LoadQuickMenuIcon(fileName)
    local name = tostring(fileName or '');
    local cacheKey = tostring(iconPack.GetRevision()) .. ':' .. name;

    if (name == '') then
        return nil;
    end

    if (quickMenuMissingIcons[cacheKey] == true) then
        return nil;
    end

    if (quickMenuIconCache[cacheKey] ~= nil) then
        return quickMenuIconCache[cacheKey];
    end

    local path = iconPack.GetAssetPath('quick-menu', name);
    local exists = false;

    pcall(function()
        exists = ashita.fs.exists(path);
    end);

    if (exists ~= true and name == 'emote-trusts-on.png') then
        return LoadQuickMenuIcon('emote-trusts-off.png');
    end

    if (exists ~= true) then
        quickMenuMissingIcons[cacheKey] = true;
        return nil;
    end

    local ok, texture = pcall(function()
        return textureLoader.Load(path);
    end);

    if ((ok ~= true or texture == nil) and name == 'emote-trusts-on.png') then
        return LoadQuickMenuIcon('emote-trusts-off.png');
    end

    if (ok ~= true or texture == nil) then
        quickMenuMissingIcons[cacheKey] = true;
        return nil;
    end

    quickMenuIconCache[cacheKey] = textureLoader.ToTextureId(texture);

    if (quickMenuIconCache[cacheKey] == nil and name == 'emote-trusts-on.png') then
        return LoadQuickMenuIcon('emote-trusts-off.png');
    end

    if (quickMenuIconCache[cacheKey] == nil) then
        quickMenuMissingIcons[cacheKey] = true;
    end

    return quickMenuIconCache[cacheKey];
end

local function Number(settings, key, fallback)
    local value = tonumber(settings ~= nil and settings[key]);

    if (value == nil) then
        return fallback;
    end

    return value;
end

local function BuildTargetMarker(context, hpBarSettings)
    if (context == nil or context.widgetKey == nil) then
        return nil;
    end

    if (context.widgetKey ~= 'Target Module' and context.widgetKey ~= 'Subtarget Module') then
        return nil;
    end

    local targetStateName = (context.widgetKey == 'Subtarget Module') and 'Subtarget' or 'Target';
    local marker = targetModuleMarker.Build(
        context.entityName,
        context.stateName,
        targetStateName,
        hpBarSettings,
        Number(context, 'distance', 0),
        {
            previewMode = true,
            previewLockOn = targetStateName == 'Target',
            suppressBackground = tostring(context.entityName or '') == 'NPC'
                and (tostring(context.sourceState or '') == 'World' or tostring(context.sourceState or '') == 'Idle'),
        }
    );

    if (marker ~= nil) then
        marker.anchorKinds = { 'name', 'hp' };
        marker.arrowAnchorKinds = { 'name' };
    end

    return marker;
end

local function BuildPreviewTargetMarker(entityName, stateName, context, hpBarSettings)
    local marker = BuildTargetMarker(context, hpBarSettings);

    if (marker ~= nil) then
        marker.anchorKinds = { 'name', 'hp' };
        marker.arrowAnchorKinds = { 'name' };
    end

    return marker;
end

local function DrawBackgroundSelector()
    for index, option in ipairs(backgroundOptions) do
        if (index > 1) then
            imgui.SameLine();
        end

        local label = option;
        local color = { 0.92, 0.92, 0.90, 1.0 };

        if (selectedBackground == option) then
            label = '> ' .. option;
            color = { 1.0, 0.84, 0.0, 1.0 };
        end

        imgui.TextColored(color, label);

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            selectedBackground = option;
        end
    end
end

local function DrawPreviewInfo(text)
    uiTooltip.Info(text, false);
    imgui.SameLine();
end

local function DrawPreviewButton(label, selected)
    local pushed = 0;

    if (imgui.PushStyleColor ~= nil) then
        local button = _G.ImGuiCol_Button;
        local hovered = _G.ImGuiCol_ButtonHovered;
        local active = _G.ImGuiCol_ButtonActive;
        local text = _G.ImGuiCol_Text;

        if (selected == true) then
            if (button ~= nil) then imgui.PushStyleColor(button, { 0.20, 0.65, 0.67, 1.0 }); pushed = pushed + 1; end
            if (hovered ~= nil) then imgui.PushStyleColor(hovered, { 0.28, 0.78, 0.80, 1.0 }); pushed = pushed + 1; end
            if (active ~= nil) then imgui.PushStyleColor(active, { 0.16, 0.52, 0.54, 1.0 }); pushed = pushed + 1; end
            if (text ~= nil) then imgui.PushStyleColor(text, { 1.0, 1.0, 1.0, 1.0 }); pushed = pushed + 1; end
        else
            if (button ~= nil) then imgui.PushStyleColor(button, { 0.18, 0.20, 0.25, 1.0 }); pushed = pushed + 1; end
            if (hovered ~= nil) then imgui.PushStyleColor(hovered, { 0.25, 0.29, 0.36, 1.0 }); pushed = pushed + 1; end
            if (active ~= nil) then imgui.PushStyleColor(active, { 0.20, 0.65, 0.67, 1.0 }); pushed = pushed + 1; end
            if (text ~= nil) then imgui.PushStyleColor(text, { 0.92, 0.92, 0.90, 1.0 }); pushed = pushed + 1; end
        end
    end

    local clicked = false;

    if (imgui.Button ~= nil) then
        clicked = imgui.Button(label) == true;
    else
        imgui.TextColored(selected and { 1.0, 0.84, 0.0, 1.0 } or { 0.92, 0.92, 0.90, 1.0 }, selected and ('> ' .. label) or label);
        clicked = imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true;
    end

    if (pushed > 0 and imgui.PopStyleColor ~= nil) then
        imgui.PopStyleColor(pushed);
    end

    return clicked;
end

local function DrawStyledBackgroundSelector()
    for index, option in ipairs(backgroundOptions) do
        if (index > 1) then
            imgui.SameLine();
        end

        if (DrawPreviewButton(option, selectedBackground == option) == true) then
            selectedBackground = option;
        end
    end
end

local function DrawStyledZoomSelector()
    for index, option in ipairs(zoomOptions) do
        if (index > 1) then
            imgui.SameLine();
        end

        if (DrawPreviewButton(option, selectedZoom == option) == true) then
            selectedZoom = option;
        end
    end
end

local function DrawStyledDragToggle()
    local label = dragEnabled == true and 'Enabled' or 'Disabled';

    if (DrawPreviewButton(label, dragEnabled == true) == true) then
        dragEnabled = dragEnabled ~= true;
        activeDragKind = nil;
    end
end

local function DrawStyledPreviewControls()
    DrawPreviewInfo('Use the controls inside the preview image to change lighting, zoom, and drag mode. These controls only affect the preview.');
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Preview');
end

local function DrawZoomSelector()
    imgui.SameLine();
    imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, 'Zoom');

    for _, option in ipairs(zoomOptions) do
        imgui.SameLine();

        local label = option;
        local color = { 0.92, 0.92, 0.90, 1.0 };

        if (selectedZoom == option) then
            label = '> ' .. option;
            color = { 1.0, 0.84, 0.0, 1.0 };
        end

        imgui.TextColored(color, label);

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            selectedZoom = option;
        end
    end

    imgui.SameLine();

    local dragLabel = dragEnabled == true and '> Drag enabled' or 'Drag disabled';
    local dragColor = dragEnabled == true and { 1.0, 0.84, 0.0, 1.0 } or { 0.92, 0.92, 0.90, 1.0 };
    imgui.TextColored(dragColor, dragLabel);

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        dragEnabled = dragEnabled ~= true;
        activeDragKind = nil;
    end
end

function preview.IsDragEnabled()
    return dragEnabled == true;
end

function preview.IsElementDragActive()
    return activeDragKind ~= nil;
end

function preview.ShouldLockSettingsWindowMove()
    return dragEnabled == true and mouseInPreview == true;
end

local function GetZoomUvs(entityName, stateName)
    local zoom = tonumber(tostring(selectedZoom or '1x'):match('(%d+)')) or 1;
    zoom = math.max(1, zoom);

    return { 0, 0 }, { 1, 1 }, zoom;
end

local function ClampTextureOffset(value, axisSize, minVisible)
    local halfAxis = (tonumber(axisSize) or 0) * 0.5;
    local visible = math.max(1, tonumber(minVisible) or 24);
    local limit = math.max(0, halfAxis - visible);
    local current = tonumber(value) or 0;

    if (current < -limit) then
        return -limit;
    end

    if (current > limit) then
        return limit;
    end

    return current;
end

local function ApplyNpcAnchorDefaults(settings, defaults, oldOffsetX, oldOffsetY)
    if (settings == nil or defaults == nil or settings.anchorTo ~= nil) then
        return;
    end

    settings.anchorTo = defaults.anchorTo;
    settings.anchorPoint = defaults.anchorPoint;

    if (
        tonumber(settings.offsetX) == tonumber(oldOffsetX) and
        tonumber(settings.offsetY) == tonumber(oldOffsetY)
    ) then
        settings.offsetX = defaults.offsetX;
        settings.offsetY = defaults.offsetY;
    end
end

local function BuildResourceText(settings, label, value, maxValue, percent)
    local parts = {};

    if (settings.showValue == true and value ~= nil) then
        if (maxValue ~= nil and tonumber(maxValue) ~= nil and tonumber(maxValue) > 0) then
            local prefix = (label == 'TP') and '' or (label .. ' ');
            table.insert(parts, prefix .. tostring(value) .. '/' .. tostring(maxValue));
        else
            table.insert(parts, tostring(value));
        end
    end

    if (settings.showPercent == true) then
        table.insert(parts, tostring(math.floor(ClampPercent(percent, 100) + 0.5)) .. '%');
    end

    return table.concat(parts, ' ');
end

local function BuildPercentFallbackResourceText(settings, label, value, maxValue, percent)
    local text = BuildResourceText(settings, label, value, maxValue, percent);

    if (text ~= '') then
        return text;
    end

    if (settings ~= nil and settings.showValue == true and percent ~= nil) then
        return tostring(math.floor(ClampPercent(percent, 100) + 0.5)) .. '%';
    end

    return text;
end

local function AddIcon(icons, settings, textureId, defaultX, defaultY, kind)
    if (settings == nil or settings.enabled ~= true or textureId == nil) then
        return;
    end

    local offsetX = tonumber(settings.offsetX) or defaultX;
    local offsetY = tonumber(settings.offsetY) or defaultY;

    table.insert(icons, {
        kind = kind,
        textureId = textureId,
        tint = kind == 'enmity' and settings.color or settings.tint,
        size = tonumber(settings.iconSize) or 16,
        offsetX = offsetX,
        offsetY = offsetY,
        anchorTo = settings.anchorTo,
        anchorPoint = settings.anchorPoint,
        anchorCollapse = settings.anchorCollapse,
        anchorSpacing = settings.anchorSpacing,
        anchorOrder = settings.anchorOrder,
    });
end

local function GetEnemyMobInfoPreviewIconSettings(storageEntityName, stateName)
    return {
        behavior = state.GetWidgetSettings(storageEntityName, stateName, 'Behavior icon', enemyBehaviorIconDefaults),
        detects = state.GetWidgetSettings(storageEntityName, stateName, 'Detects icon', enemyDetectsIconDefaults),
        links = state.GetWidgetSettings(storageEntityName, stateName, 'Links icon', enemyLinksIconDefaults),
        special = state.GetWidgetSettings(storageEntityName, stateName, 'Special icon', enemySpecialIconDefaults),
    };
end

local function GetPlayerPreviewIconSettings(storageEntityName, stateName)
    return {
        allianceLeader = state.GetWidgetSettings(storageEntityName, stateName, 'Alliance leader icon', allianceLeaderIconDefaults),
        partyLeader = state.GetWidgetSettings(storageEntityName, stateName, 'Party leader icon', partyLeaderIconDefaults),
        gameMode = state.GetWidgetSettings(storageEntityName, stateName, 'Game mode icon', gameModeIconDefaults),
        linkshell = state.GetWidgetSettings(storageEntityName, stateName, 'Linkshell icon', linkshellIconDefaults),
        bazaar = state.GetWidgetSettings(storageEntityName, stateName, 'Bazaar icon', bazaarIconDefaults),
        away = state.GetWidgetSettings(storageEntityName, stateName, 'Away icon', awayIconDefaults),
        disconnect = state.GetWidgetSettings(storageEntityName, stateName, 'Disconnect icon', disconnectIconDefaults),
        anon = state.GetWidgetSettings(storageEntityName, stateName, 'Anon icon', anonIconDefaults),
        stars = state.GetWidgetSettings(storageEntityName, stateName, 'Stars icon', starsIconDefaults),
        levelSync = state.GetWidgetSettings(storageEntityName, stateName, 'Level sync icon', levelSyncIconDefaults),
        newAdventurer = state.GetWidgetSettings(storageEntityName, stateName, 'New adventurer icon', newAdventurerIconDefaults),
    };
end

local function AddPlayerPreviewIcons(icons, playerIconSettings, entityName, stateName)
    if (entityName == 'Trust') then
        return;
    end

    if (entityName == 'Self' and stateName ~= 'Idle' and stateName ~= 'Combat') then
        return;
    end

    local pcWorldPreview = entityName == 'PC' and stateName ~= 'Combat';
    local worldPreview = pcWorldPreview == true;

    if (worldPreview ~= true) then
        AddIcon(icons, playerIconSettings.allianceLeader, LoadWidgetIcon('alliance_leader.png'), -120, -54, 'allianceLeaderIcon');
        AddIcon(icons, playerIconSettings.partyLeader, LoadWidgetIcon('party_leader.png'), -96, -54, 'partyLeaderIcon');
    end

    AddIcon(icons, playerIconSettings.gameMode, gameMode.GetIconTextureId('ACE'), -72, -54, 'gameModeIcon');
    AddIcon(icons, playerIconSettings.linkshell, LoadWidgetIcon('linkshell.png'), 48, -54, 'linkshellIcon');
    AddIcon(icons, playerIconSettings.bazaar, LoadWidgetIcon('bazaar.png'), 72, -54, 'bazaarIcon');
    AddIcon(icons, playerIconSettings.away, LoadWidgetIcon('away.png'), 120, -54, 'awayIcon');
    AddIcon(icons, playerIconSettings.disconnect, LoadWidgetIcon('dc.png'), 144, -54, 'disconnectIcon');
    AddIcon(icons, playerIconSettings.anon, LoadWidgetIcon('anon.png'), -120, -54, 'anonIcon');
    AddIcon(icons, playerIconSettings.stars, LoadWidgetIcon('stars.png'), -48, -54, 'starsIcon');

    if (worldPreview ~= true) then
        AddIcon(icons, playerIconSettings.levelSync, LoadWidgetIcon('lvsync.png'), -24, -54, 'levelSyncIcon');
    end

    AddIcon(icons, playerIconSettings.newAdventurer, LoadWidgetIcon('new_adventurer.png'), 24, -54, 'newAdventurerIcon');
end

local function AddEnemySpecialTargetPreviewIcon(icons, nameSettings, iconSettings, context)
    if (iconSettings == nil or iconSettings.enabled ~= true) then
        return;
    end

    local showTier3 = iconSettings.showTier3Incursion ~= false;
    local showAp = iconSettings.showActivityPoints ~= false;
    local editingSpecialTarget = context ~= nil and tostring(context.widgetKey or '') == 'Special icon';
    local iconName = nil;
    local autoScale = 3.70;

    if (editingSpecialTarget == true and showAp == true) then
        iconName = 'AP.png';
        autoScale = 2.2;
    elseif (showTier3 == true) then
        iconName = 'star.png';
    elseif (showAp == true) then
        iconName = 'AP.png';
        autoScale = 2.2;
    end

    if (iconName == nil) then
        return;
    end

    local textureId = LoadCatseyeIcon(iconName);

    if (textureId == nil) then
        return;
    end

    local nameSize = tonumber(nameSettings ~= nil and nameSettings.textSize) or tonumber(nameDefaults.textSize) or 24;
    local configuredSize = tonumber(iconSettings.iconSize) or 0;
    local iconSize = configuredSize > 0 and configuredSize or math.floor((nameSize * autoScale) + 0.5);
    iconSize = math.max(6, math.min(tonumber(iconSettings.maxIconSize) or enemySpecialIconDefaults.maxIconSize or 256, iconSize));

    icons[#icons + 1] = {
        kind = 'catseyeSpecialNameIcon',
        textureId = textureId,
        size = iconSize,
        offsetX = tonumber(iconSettings.offsetX) or enemySpecialIconDefaults.offsetX,
        offsetY = tonumber(iconSettings.offsetY) or enemySpecialIconDefaults.offsetY,
        anchorTo = iconSettings.anchorTo or enemySpecialIconDefaults.anchorTo,
        anchorPoint = iconSettings.anchorPoint or enemySpecialIconDefaults.anchorPoint,
        anchorCollapse = iconSettings.anchorCollapse,
        anchorSpacing = iconSettings.anchorSpacing,
        anchorOrder = iconSettings.anchorOrder,
    };
end

local function AddEnemyWorldMobInfoPreviewIcons(icons, globalSettings, widgetSettings, nameSettings, context)
    widgetSettings = widgetSettings or {};
    local behaviorSettings = widgetSettings.behavior;
    local detectsSettings = widgetSettings.detects;
    local linksSettings = widgetSettings.links;

    AddIcon(icons, behaviorSettings, LoadPeerIcon('AggroNQ', ResolveEnemyPreviewIconStyle(globalSettings, behaviorSettings)), -96, -34, 'Behavior icon');
    AddIcon(icons, detectsSettings, LoadPeerIcon('Sound', ResolveEnemyPreviewIconStyle(globalSettings, detectsSettings)), -72, -34, 'Detects icon');
    AddIcon(icons, linksSettings, LoadPeerIcon('Link', ResolveEnemyPreviewIconStyle(globalSettings, linksSettings)), -48, -34, 'Links icon');
    AddEnemySpecialTargetPreviewIcon(icons, nameSettings, widgetSettings.special, context);
end

local function BuildPreviewAnchorFallbackRects(definitions)
    local fallbacks = {};

    for _, definition in ipairs(definitions or {}) do
        local settings = definition.settings or {};
        local defaults = definition.defaults or {};
        local size = math.max(6, math.min(256, tonumber(settings.iconSize) or tonumber(defaults.iconSize) or 16));
        local offsetX = tonumber(settings.offsetX) or tonumber(definition.defaultX) or tonumber(defaults.offsetX) or 0;
        local offsetY = tonumber(settings.offsetY) or tonumber(definition.defaultY) or tonumber(defaults.offsetY) or 0;

        fallbacks[#fallbacks + 1] = {
            kind = definition.kind,
            x = 512 - (size * 0.5) + offsetX,
            y = 256 - (size * 0.5) + offsetY,
            w = size,
            h = size,
            padding = 4,
            layout = {
                anchorTo = settings.anchorTo or defaults.anchorTo,
                anchorPoint = settings.anchorPoint or defaults.anchorPoint,
                anchorCollapse = settings.anchorCollapse,
                anchorSpacing = settings.anchorSpacing,
                anchorOrder = settings.anchorOrder,
                offsetX = offsetX,
                offsetY = offsetY,
            },
        };
    end

    return fallbacks;
end

local function AddEnmityPreviewIcon(plateData, globalSettings, context)
    if (plateData == nil or context == nil or context.widgetKey ~= 'Enmity') then
        return;
    end

    globalSettings.enmity = globalSettings.enmity or {};

    if (globalSettings.enmity.enabled == false) then
        return;
    end

    local role = tostring(context.entityName or '') == 'Enemy' and 'enemy' or 'ally';
    local markerSettings = {};

    if (role == 'enemy') then
        markerSettings.enabled = true;
        markerSettings.iconSize = globalSettings.enmity.enemyIconSize or globalSettings.enmity.iconSize or 31;
        markerSettings.offsetX = globalSettings.enmity.enemyOffsetX or globalSettings.enmity.offsetX or -108;
        markerSettings.offsetY = globalSettings.enmity.enemyOffsetY or globalSettings.enmity.offsetY or -17;
        markerSettings.color = globalSettings.enmity.enemyColor or globalSettings.enmity.color or { 0.25, 0.85, 1.0, 1.0 };
        markerSettings.iconFile = globalSettings.enmity.enemyIconFile or 'shield-alert.png';
    else
        markerSettings.enabled = true;
        markerSettings.iconSize = globalSettings.enmity.allyIconSize or globalSettings.enmity.iconSize or 31;
        markerSettings.offsetX = globalSettings.enmity.allyOffsetX or globalSettings.enmity.offsetX or -108;
        markerSettings.offsetY = globalSettings.enmity.allyOffsetY or globalSettings.enmity.offsetY or -17;
        markerSettings.color = globalSettings.enmity.allyColor or globalSettings.enmity.color or { 1.0, 0.28, 0.20, 1.0 };
        markerSettings.iconFile = globalSettings.enmity.allyIconFile or 'warning-dimond.png';
    end

    local enmityIcons = require('core.enmity_icons');

    plateData.icons = plateData.icons or {};
    AddIcon(plateData.icons, markerSettings, enmityIcons.GetTextureId(markerSettings.iconFile), -108, -17, 'enmity');
end

local function AddFishingPreviewIcon(plateData, globalSettings, context)
    if (plateData == nil or context == nil or context.widgetKey ~= 'Fishing') then
        return;
    end

    globalSettings.fishing = globalSettings.fishing or {};

    if (globalSettings.fishing.enabled == false) then
        return;
    end

    local previewSettings = {};

    for key, value in pairs(globalSettings.fishing) do
        previewSettings[key] = value;
    end

    previewSettings.iconFile = previewSettings.iconFile or 'fishing_01.png';
    if (previewSettings.showLabel == nil) then
        previewSettings.showLabel = true;
    end
    previewSettings.previewResult = true;

    fishing.AddIcon(plateData, previewSettings);

    local icon = plateData.icons ~= nil and plateData.icons[#plateData.icons] or nil;
    if (icon ~= nil and previewSettings.showLabel ~= false) then
        icon.timerText = 'Easy catch';
    end
end

local function AddCraftingPreviewWidget(plateData, globalSettings, context)
    if (
        plateData == nil or
        context == nil or
        (context.widgetKey ~= 'Crafting' and context.previewCraftingResult ~= true)
    ) then
        return;
    end

    globalSettings.crafting = globalSettings.crafting or {};

    if (globalSettings.crafting.enabled == false) then
        return;
    end

    local previewSettings = {};

    for key, value in pairs(globalSettings.crafting) do
        previewSettings[key] = value;
    end

    previewSettings.previewResult = true;
    previewSettings.previewResultName = previewSettings.previewResultName or 'High-Quality';

    crafting.AddWidget(plateData, previewSettings);
end

local function AddGatheringPreviewWidget(plateData, globalSettings, context)
    if (plateData == nil or context == nil) then
        return;
    end

    globalSettings.gathering = globalSettings.gathering or {};

    if (globalSettings.gathering.enabled == false) then
        return;
    end

    local isGatheringPage = context.widgetKey == 'Gathering';
    local isSelfWorldPreview = tostring(context.entityName or '') == 'Self' and (
        tostring(context.stateName or '') == 'Idle' or
        tostring(context.stateName or '') == 'World'
    );

    if (isGatheringPage ~= true and isSelfWorldPreview ~= true) then
        return;
    end

    local previewSettings = {};

    for key, value in pairs(globalSettings.gathering) do
        previewSettings[key] = value;
    end

    previewSettings.previewResult = true;
    previewSettings.previewDisplay = {
        iconFile = previewSettings.iconFile or 'hatchet.png',
        count = 12,
    };
    previewSettings.displayMode = previewSettings.displayMode or 'Tool + count';
    if (previewSettings.showCount == nil) then
        previewSettings.showCount = true;
    end

    gathering.AddWidget(plateData, previewSettings);
end

local function AddRestingPreviewBar(plateData, globalSettings, context)
    if (plateData == nil or context == nil) then
        return;
    end

    local resting = globalSettings.resting or {};
    if (resting.enabled == false) then
        return;
    end

    local isRestingPage = context.widgetKey == 'Resting';
    local isSelfRestingPreview = tostring(context.entityName or '') == 'Self' and (
        tostring(context.stateName or '') == 'Idle' or
        tostring(context.stateName or '') == 'World' or
        tostring(context.stateName or '') == 'Resting'
    );

    if (isRestingPage ~= true and isSelfRestingPreview ~= true) then
        return;
    end

    plateData.extraBars = plateData.extraBars or {};
    plateData.extraBars[#plateData.extraBars + 1] = {
        kind = 'resting',
        enabled = true,
        displayMode = resting.displayMode or 'Bar',
        progress = 55,
        width = tonumber(resting.width) or 180,
        height = tonumber(resting.height) or 12,
        ringSize = tonumber(resting.ringSize) or 88,
        ringThickness = tonumber(resting.ringThickness) or 10,
        offsetX = tonumber(resting.offsetX) or 0,
        offsetY = tonumber(resting.offsetY) or 38,
        anchorTo = resting.anchorTo or 'Plate',
        anchorPoint = resting.anchorPoint,
        anchorCollapse = resting.anchorCollapse,
        anchorSpacing = resting.anchorSpacing,
        anchorOrder = resting.anchorOrder,
        color = resting.color or { 0.55, 0.95, 0.35, 1.0 },
        backgroundColor = resting.backgroundColor or { 0.10, 0.10, 0.10, 1.0 },
        borderColor = resting.borderColor or { 1.0, 1.0, 1.0, 1.0 },
        borderSize = tonumber(resting.borderSize) or 0,
        textureId = barTextures.GetTextureId(resting.texture or 'Solid'),
        text = '11s',
        textKind = 'restingText',
        textOffsetX = tonumber(resting.textOffsetX) or 0,
        textOffsetY = tonumber(resting.textOffsetY) or 0,
        fontFamily = fonts.GetRole(globalSettings, true),
        fontFlags = fonts.GetRoleFlags(globalSettings, true),
        fontSize = textScale.ToTextureFontSize(resting.fontSize, 12),
        textColor = resting.textColor or { 0.0, 0.0, 0.0, 1.0 },
        textOutlineEnabled = resting.textOutlineEnabled == true,
        textOutlineColor = resting.textOutlineColor or { 1.0, 1.0, 1.0, 1.0 },
        textOutlineSize = tonumber(resting.textOutlineSize) or 1,
    };

    if (resting.enableLogoutCountdown ~= false) then
        plateData.texts = plateData.texts or {};
        plateData.texts[#plateData.texts + 1] = {
            kind = 'restingCountdownText',
            text = 'Shutdown',
            offsetX = tonumber(resting.countdownTextOffsetX) or 0,
            offsetY = tonumber(resting.countdownTextOffsetY) or 0,
            align = 'center',
            fontFamily = fonts.GetRole(globalSettings, true),
            fontFlags = fonts.GetRoleFlags(globalSettings, true),
            fontSize = textScale.ToTextureFontSize(resting.countdownFontSize, 12),
            color = resting.countdownTextColor or { 1.0, 0.84, 0.0, 1.0 },
            outlineEnabled = resting.countdownTextOutlineEnabled ~= false,
            outlineColor = resting.countdownTextOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            outlineSize = tonumber(resting.countdownTextOutlineSize) or 2,
        };
    end
end

local function AddStatusPreviewIcons(icons, settings, statusIds, kind)
    if (settings == nil or settings.enabled ~= true or statusIds == nil or #statusIds == 0) then
        return;
    end

    local maxIcons = math.max(1, math.min(32, tonumber(settings.maxIcons) or 12));
    local iconsPerRow = math.max(1, math.min(24, tonumber(settings.iconsPerRow) or 6));
    local iconSize = math.max(6, math.min(256, tonumber(settings.iconSize) or 18));
    local spacing = math.max(0, math.min(24, tonumber(settings.iconSpacing) or 2));
    local rowSpacing = math.max(0, math.min(32, tonumber(settings.rowSpacing) or 2));
    local rowHeight = iconSize + rowSpacing;
    local growLeft = tostring(settings.growthDirection or 'Right') == 'Left';
    local anchored = tostring(settings.anchorTo or 'Plate') ~= 'Plate';

    if (settings.showTimers == true) then
        rowHeight = iconSize + math.max(rowSpacing, (tonumber(settings.timerFontSize) or 8) + math.max(0, tonumber(settings.timerOffsetY) or 0) + 2);
    end

    local baseX = tonumber(settings.offsetX) or 0;
    local baseY = tonumber(settings.offsetY) or 0;
    local visibleRows = {};
    local hideAboveSeconds = nil;

    if (settings.hideAboveDurationEnabled == true) then
        local minutes = tonumber(settings.hideAboveDurationMinutes) or 0;
        if (minutes > 0) then hideAboveSeconds = minutes * 60; end
    end

    for _, rowData in ipairs(statusIds) do
        local timerSeconds = type(rowData) == 'table' and tonumber(rowData.seconds) or nil;
        if (hideAboveSeconds == nil or timerSeconds == nil or timerSeconds <= hideAboveSeconds) then
            visibleRows[#visibleRows + 1] = rowData;
        end
    end

    local total = math.min(maxIcons, #visibleRows);

    for i = 1, total do
        local rowData = visibleRows[i];
        local statusId = type(rowData) == 'table' and rowData.id or rowData;
        local textureId = statusIconTextures.GetTextureId(statusId, settings.iconPack);

        if (textureId ~= nil) then
            local row = math.floor((i - 1) / iconsPerRow);
            local col = (i - 1) % iconsPerRow;
            local layoutRowCount = math.min(iconsPerRow, total);
            local rowWidth = (layoutRowCount * iconSize) + ((layoutRowCount - 1) * spacing);
            local iconOffsetX = baseX - (rowWidth * 0.5) + (iconSize * 0.5) + (col * (iconSize + spacing));
            local timerSeconds = type(rowData) == 'table' and tonumber(rowData.seconds) or nil;
            local timerText = nil;

            if (settings.showTimers == true and timerSeconds ~= nil) then
                timerText = statusTimerFormat.Format(timerSeconds);
            end

            if (anchored == true) then
                iconOffsetX = growLeft == true
                    and (baseX - rowWidth + (col * (iconSize + spacing)))
                    or (baseX + (col * (iconSize + spacing)));
            end

            icons[#icons + 1] = {
                kind = kind,
                textureId = textureId,
                size = iconSize,
                offsetX = iconOffsetX,
                offsetY = baseY + (row * rowHeight),
                anchorTo = settings.anchorTo,
                anchorPoint = settings.anchorPoint,
                anchorCollapse = settings.anchorCollapse,
                anchorSpacing = settings.anchorSpacing,
                anchorOrder = settings.anchorOrder,
                timerText = timerText,
                timerSeconds = timerSeconds,
                timerOffsetY = tonumber(settings.timerOffsetY) or 0,
                timerFontFamily = fonts.GetRole(state.GetGlobalSettings(globalDefaults), settings.timerUseSmallFont == true),
                timerFontFlags = fonts.GetRoleFlags(state.GetGlobalSettings(globalDefaults), settings.timerUseSmallFont == true),
                timerFontSize = textScale.ToTextureFontSize(settings.timerFontSize, 8),
                timerTextColor = settings.timerTextColor,
                timerTextOutline = settings.timerTextOutline,
                timerTextOutlineColor = settings.timerTextOutlineColor,
                timerTextOutlineSize = tonumber(settings.timerTextOutlineSize) or 1,
                timerBackground = settings.timerBackground == true,
                timerBackgroundPaddingX = tonumber(settings.timerBackgroundPaddingX) or 2,
                timerBackgroundPaddingY = tonumber(settings.timerBackgroundPaddingY) or 1,
                timerBackgroundColor = settings.timerBackgroundColor,
                timerBackgroundBorderSize = tonumber(settings.timerBackgroundBorderSize) or 0,
                timerBackgroundBorderColor = settings.timerBackgroundBorderColor,
                timerCornerRadius = tonumber(settings.timerCornerRadius) or 0,
                timerWarningEnabled = settings.timerWarningEnabled == true,
                timerWarningStage1Seconds = tonumber(settings.timerWarningStage1Seconds) or 10,
                timerWarningStage2Seconds = tonumber(settings.timerWarningStage2Seconds) or 8,
                timerWarningStage3Seconds = tonumber(settings.timerWarningStage3Seconds) or 5,
                timerWarningStage1Color = settings.timerWarningStage1Color,
                timerWarningStage2Color = settings.timerWarningStage2Color,
                timerWarningStage3Color = settings.timerWarningStage3Color,
                timerWarningTextColorEnabled = settings.timerWarningTextColorEnabled == true,
                timerWarningFontStage1Color = settings.timerWarningFontStage1Color,
                timerWarningFontStage2Color = settings.timerWarningFontStage2Color,
                timerWarningFontStage3Color = settings.timerWarningFontStage3Color,
                timerWarningOutlineColorEnabled = settings.timerWarningOutlineColorEnabled == true,
                timerWarningOutlineStage1Color = settings.timerWarningOutlineStage1Color,
                timerWarningOutlineStage2Color = settings.timerWarningOutlineStage2Color,
                timerWarningOutlineStage3Color = settings.timerWarningOutlineStage3Color,
                timerWarningBoxColorEnabled = settings.timerWarningBoxColorEnabled == true,
                timerWarningBoxStage1Color = settings.timerWarningBoxStage1Color,
                timerWarningBoxStage2Color = settings.timerWarningBoxStage2Color,
                timerWarningBoxStage3Color = settings.timerWarningBoxStage3Color,
                timerWarningBoxBorderEnabled = settings.timerWarningBoxBorderEnabled == true,
                timerWarningBoxBorderStage1Color = settings.timerWarningBoxBorderStage1Color,
                timerWarningBoxBorderStage2Color = settings.timerWarningBoxBorderStage2Color,
                timerWarningBoxBorderStage3Color = settings.timerWarningBoxBorderStage3Color,
                timerWarningBackgroundEnabled = settings.timerWarningBackgroundEnabled == true,
                timerWarningIconPadding = tonumber(settings.iconWarningPadding) or 6,
                timerWarningIconBackgroundStage1Color = settings.timerWarningIconBackgroundStage1Color,
                timerWarningIconBackgroundStage2Color = settings.timerWarningIconBackgroundStage2Color,
                timerWarningIconBackgroundStage3Color = settings.timerWarningIconBackgroundStage3Color,
                timerWarningBorderEnabled = settings.timerWarningBorderEnabled == true,
                timerWarningIconBorderStage1Color = settings.timerWarningIconBorderStage1Color,
                timerWarningIconBorderStage2Color = settings.timerWarningIconBorderStage2Color,
                timerWarningIconBorderStage3Color = settings.timerWarningIconBorderStage3Color,
                timerNormalSeconds = tonumber(settings.timerNormalSeconds) or 60,
                timerSoonSeconds = tonumber(settings.timerSoonSeconds) or 20,
                timerNormalBackgroundColor = settings.timerNormalBackgroundColor,
                timerSoonBackgroundColor = settings.timerSoonBackgroundColor,
                timerUrgentBackgroundColor = settings.timerUrgentBackgroundColor,
            };
        end
    end
end

local function AddPreviewTextBadge(plateData, text, settings, defaults, globalSettings, kind)
    if (settings == nil or settings.enabled ~= true or text == nil or tostring(text) == '') then
        return;
    end

    plateData.badges = plateData.badges or {};
    plateData.badges[#plateData.badges + 1] = {
        kind = kind or 'text',
        text = tostring(text),
        offsetX = tonumber(settings.offsetX) or defaults.offsetX,
        offsetY = tonumber(settings.offsetY) or defaults.offsetY,
        fontFamily = fonts.GetRole(globalSettings, true),
        fontFlags = fonts.GetRoleFlags(globalSettings, true),
        fontSize = textScale.ToTextureFontSize(settings.textSize, defaults.textSize),
        textColor = settings.color or defaults.color,
        textOutlineEnabled = settings.outlineEnabled == true,
        textOutlineColor = settings.outlineColor or defaults.outlineColor,
        textOutlineSize = tonumber(settings.outlineSize) or defaults.outlineSize,
        backgroundEnabled = false,
    };
end

local function AddPreviewPetTimerBadge(plateData, text, settings, globalSettings, labelName, iconName)
    if (settings == nil or settings.enabled ~= true or text == nil or tostring(text) == '') then
        return;
    end

    local badgeText = tostring(text);
    local labelText = '';
    local iconTextureId = nil;
    local displayMode = tostring(settings.displayMode or 'Text');
    local timerLabel = tostring(labelName or 'Jug');

    badgeText = badgeText:gsub('^Jug%s+', '');
    badgeText = badgeText:gsub('^Charmed%s+', '');

    if (displayMode == 'Text') then
        labelText = timerLabel;
    elseif (displayMode == 'Icon') then
        if (tostring(iconName or timerLabel):lower() == 'jug') then
            iconTextureId = LoadPetIcon('bst/jug.png');
        else
            iconTextureId = LoadPetStateIcon(iconName or timerLabel);
        end
    end

    plateData.badges = plateData.badges or {};
    plateData.badges[#plateData.badges + 1] = {
        kind = 'petTimer',
        text = badgeText,
        labelText = labelText,
        offsetX = tonumber(settings.offsetX) or petTimerDefaults.offsetX,
        offsetY = tonumber(settings.offsetY) or petTimerDefaults.offsetY,
        fontFamily = fonts.GetRole(globalSettings, true),
        fontFlags = fonts.GetRoleFlags(globalSettings, true),
        fontSize = textScale.ToTextureFontSize(settings.textSize, petTimerDefaults.textSize),
        textColor = settings.color or petTimerDefaults.color,
        textOutlineEnabled = settings.outlineEnabled == true,
        textOutlineColor = settings.outlineColor or petTimerDefaults.outlineColor,
        textOutlineSize = tonumber(settings.outlineSize) or petTimerDefaults.outlineSize,
        backgroundEnabled = false,
        iconTextureId = iconTextureId,
        iconSize = tonumber(settings.iconSize) or petTimerDefaults.iconSize,
        labelOffsetX = tonumber(settings.labelOffsetX) or 0,
        labelOffsetY = tonumber(settings.labelOffsetY) or 0,
        textOffsetX = tonumber(settings.textOffsetX) or 0,
        textOffsetY = tonumber(settings.textOffsetY) or 0,
        separateLabelOffsets = true,
    };
end

local function AddPreviewPetStateBadge(plateData, commandName, settings, globalSettings)
    if (settings == nil or settings.enabled ~= true or commandName == nil or tostring(commandName) == '') then
        return;
    end

    local displayMode = tostring(settings.displayMode or 'Text');
    local badgeText = '';
    local labelText = '';
    local iconTextureId = nil;

    if (displayMode == 'Text') then
        labelText = tostring(commandName);
    elseif (displayMode == 'Icon') then
        iconTextureId = LoadPetStateIcon(commandName);
    end

    plateData.badges = plateData.badges or {};
    plateData.badges[#plateData.badges + 1] = {
        kind = 'petState',
        text = badgeText,
        labelText = labelText,
        offsetX = tonumber(settings.offsetX) or petStateDefaults.offsetX,
        offsetY = tonumber(settings.offsetY) or petStateDefaults.offsetY,
        fontFamily = fonts.GetRole(globalSettings, true),
        fontFlags = fonts.GetRoleFlags(globalSettings, true),
        fontSize = textScale.ToTextureFontSize(settings.textSize, petStateDefaults.textSize),
        textColor = settings.color or petStateDefaults.color,
        textOutlineEnabled = settings.outlineEnabled == true,
        textOutlineColor = settings.outlineColor or petStateDefaults.outlineColor,
        textOutlineSize = tonumber(settings.outlineSize) or petStateDefaults.outlineSize,
        backgroundEnabled = false,
        iconTextureId = iconTextureId,
        iconSize = tonumber(settings.iconSize) or petStateDefaults.iconSize,
        labelOffsetX = tonumber(settings.labelOffsetX) or 0,
        labelOffsetY = tonumber(settings.labelOffsetY) or 0,
        separateLabelOffsets = true,
    };
end

local function BuildPreviewExtraBar(settings, defaults, progress, text, kind, iconName, globalSettings, labelText)
    if (settings == nil or settings.enabled ~= true) then
        return nil;
    end

    local displayMode = tostring(settings.labelDisplayMode or 'Text');
    local barText = tostring(text or '');
    local iconTextureId = nil;

    if (iconName ~= nil and displayMode == 'Icon') then
        iconTextureId = LoadPetStateIcon(iconName);
    end

    local segmented = settings.segmented == true;
    local barProgress = tonumber(progress) or 0;

    if (segmented == true) then
        barProgress = barProgress * 3;
    end

    return {
        kind = kind,
        enabled = true,
        progress = barProgress,
        width = tonumber(settings.width) or defaults.width,
        height = tonumber(settings.height) or defaults.height,
        offsetX = tonumber(settings.offsetX) or defaults.offsetX,
        offsetY = tonumber(settings.offsetY) or defaults.offsetY,
        anchorTo = settings.anchorTo or defaults.anchorTo,
        anchorPoint = settings.anchorPoint or defaults.anchorPoint,
        anchorCollapse = settings.anchorCollapse,
        anchorSpacing = settings.anchorSpacing,
        anchorOrder = settings.anchorOrder,
        color = settings.color or defaults.color,
        backgroundColor = settings.backgroundColor or defaults.backgroundColor,
        borderColor = settings.borderColor or defaults.borderColor,
        borderSize = tonumber(settings.borderSize) or defaults.borderSize,
        textureId = barTextures.GetTextureId(settings.texture),
        fillDirection = settings.fillDirection or defaults.fillDirection or 'Left to right',
        showAtPercent = segmented and 300 or (tonumber(settings.showAtPercent) or 100),
        segmented = segmented,
        segmentGap = tonumber(settings.segmentGap) or defaults.segmentGap,
        color2 = settings.color2 or defaults.color2,
        color3 = settings.color3 or defaults.color3,
        text = barText,
        labelText = tostring(labelText or ''),
        textOffsetX = tonumber(settings.textOffsetX) or 0,
        textOffsetY = tonumber(settings.textOffsetY) or 0,
        fontFamily = fonts.GetRole(globalSettings or globalDefaults, settings.useSmallFont == true),
        fontFlags = fonts.GetRoleFlags(globalSettings or globalDefaults, settings.useSmallFont == true),
        fontSize = textScale.ToTextureFontSize(settings.fontSize, defaults.fontSize),
        textColor = settings.textColor or defaults.textColor,
        textOutlineEnabled = settings.textOutlineEnabled == true,
        textOutlineColor = settings.textOutlineColor or defaults.textOutlineColor,
        textOutlineSize = tonumber(settings.textOutlineSize) or defaults.textOutlineSize,
        iconTextureId = iconTextureId,
        iconSize = tonumber(settings.labelIconSize) or defaults.labelIconSize,
        iconOffsetX = tonumber(settings.labelIconOffsetX) or 0,
        iconOffsetY = tonumber(settings.labelIconOffsetY) or 0,
        separateLabelOffsets = iconTextureId ~= nil or tostring(labelText or '') ~= '',
    };
end

local function CopySettingsWith(settings, overrides)
    local copy = {};

    for key, value in pairs(settings or {}) do
        copy[key] = value;
    end

    for key, value in pairs(overrides or {}) do
        copy[key] = value;
    end

    return copy;
end

local function ShouldShowDistancePreview(context, distanceSettings)
    return distanceSettings ~= nil and distanceSettings.enabled == true;
end

local function GetTpPreviewValue(tpBarSettings, context, fallbackValue)
    local value = tonumber(fallbackValue) or 1375;

    if (context ~= nil and context.widgetKey == 'TP Bar') then
        local threshold = math.max(0, math.min(300, tonumber(tpBarSettings ~= nil and tpBarSettings.showAtPercent) or 300));
        value = math.max(2600, threshold * 10);
    end

    return value;
end

local function GetTpPreviewThreshold(tpBarSettings, context, fallbackValue)
    if (context ~= nil and context.widgetKey == 'TP Bar') then
        return 0;
    end

    return tonumber(tpBarSettings ~= nil and tpBarSettings.showAtPercent) or tonumber(fallbackValue) or 300;
end

local function BuildPetPreviewPlate(stateName, nameSettings, backgroundSettings, hpBarSettings, tpBarSettings, globalSettings, context)
    local petTimerSettings = state.GetWidgetSettings('Pet (BST)', stateName, 'Pet timer', petTimerDefaults);
    local petStateSettings = state.GetWidgetSettings('Pet (BST)', stateName, 'Pet state', petStateDefaults);
    local sicSettings = state.GetWidgetSettings('Pet (BST)', stateName, 'Sic', petReadyBarDefaults);
    local readySettings = state.GetWidgetSettings('Pet (BST)', stateName, 'Ready bar', petReadyBarDefaults);
    local rewardSettings = state.GetWidgetSettings('Pet (BST)', stateName, 'Reward', petRewardBarDefaults);
    local hp = 985;
    local maxHp = 1074;
    local hpPercent = ClampPercent((hp / maxHp) * 100, 92);
    local tpValue = GetTpPreviewValue(tpBarSettings, context, 3000);
    local tpPercent = tpValue / 10;
    local hpColor = hpBarSettings.color or { 0.95, 0.45, 0.45, 1.0 };

    if (
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25)
    ) then
        hpColor = hpBarSettings.lowColor or hpColor;
    end

    local hpLowActive = (
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25)
    );

    local plateData = {
        hp = hpPercent,
        tp = tpPercent,
        targetMarker = BuildTargetMarker(context, hpBarSettings),
        background = {
            enabled = backgroundSettings.enabled == true,
            width = tonumber(backgroundSettings.width) or backgroundDefaults.width,
            height = tonumber(backgroundSettings.height) or backgroundDefaults.height,
            offsetX = tonumber(backgroundSettings.offsetX) or backgroundDefaults.offsetX,
            offsetY = tonumber(backgroundSettings.offsetY) or backgroundDefaults.offsetY,
            color = backgroundSettings.color or backgroundDefaults.color,
            borderColor = backgroundSettings.borderColor or backgroundDefaults.borderColor,
            borderSize = tonumber(backgroundSettings.borderSize) or backgroundDefaults.borderSize,
            texture = backgroundSettings.texture or backgroundDefaults.texture,
            textureId = backgroundTextures.GetTextureId(backgroundSettings.texture or backgroundDefaults.texture),
            imageOpacity = backgroundSettings.imageOpacity or backgroundDefaults.imageOpacity,
            anchorTo = backgroundSettings.anchorTo or backgroundDefaults.anchorTo,
            anchorPoint = backgroundSettings.anchorPoint or backgroundDefaults.anchorPoint,
            anchorCollapse = backgroundSettings.anchorCollapse,
            anchorSpacing = backgroundSettings.anchorSpacing,
            anchorOrder = backgroundSettings.anchorOrder,
        },
        name = (nameSettings.enabled == true) and ((stateName == 'Charmed Pet') and 'Desert Beetle' or 'CourierCarrie') or '',
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(nameSettings.textSize, nameDefaults.textSize),
        nameColor = nameSettings.color or { 1.0, 1.0, 1.0, 1.0 },
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = nameSettings.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = ClampTextureOffset(tonumber(nameSettings.offsetX) or -38, 1024, 24),
        nameOffsetY = ClampTextureOffset(tonumber(nameSettings.offsetY) or -34, 512, 24),
        nameAnchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
        nameAnchorCollapse = nameSettings.anchorCollapse,
        nameAnchorOrder = nameSettings.anchorOrder,
        hpBar = {
            enabled = hpBarSettings.enabled == true,
            width = tonumber(hpBarSettings.width) or 160,
            height = tonumber(hpBarSettings.height) or 14,
            offsetX = tonumber(hpBarSettings.offsetX) or 0,
            offsetY = tonumber(hpBarSettings.offsetY) or -16,
            color = hpColor,
            backgroundColor = hpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = hpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(hpBarSettings.borderSize) or 0,
            anchorTo = hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            anchorCollapse = hpBarSettings.anchorCollapse,
            anchorSpacing = hpBarSettings.anchorSpacing,
            anchorOrder = hpBarSettings.anchorOrder,
            textureId = barTextures.GetTextureId(hpBarSettings.texture),
            animationEnabled = hpLowActive == true and hpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(hpBarSettings.lowAnimation),
            animationSpeed = tonumber(hpBarSettings.lowAnimationSpeed) or 40,
            animationColor = hpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(hpBarSettings.showAtPercent) or 100,
            text = BuildPercentFallbackResourceText(hpBarSettings, 'HP', nil, nil, hpPercent),
            textOffsetX = tonumber(hpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(hpBarSettings.textOffsetY) or 0,
            fontFamily = fonts.GetRole(globalSettings, hpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, hpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(hpBarSettings.fontSize, barDefaults.fontSize),
            textColor = hpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = hpBarSettings.textOutlineEnabled == true,
            textOutlineColor = hpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(hpBarSettings.textOutlineSize) or 1,
        },
        mpBar = { enabled = false },
        tpBar = {
            enabled = tpBarSettings.enabled == true,
            width = tonumber(tpBarSettings.width) or 160,
            height = tonumber(tpBarSettings.height) or 6,
            offsetX = tonumber(tpBarSettings.offsetX) or 0,
            offsetY = tonumber(tpBarSettings.offsetY) or 4,
            color = tpBarSettings.color or { 0.0, 0.55, 0.95, 1.0 },
            backgroundColor = tpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = tpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(tpBarSettings.borderSize) or 0,
            anchorTo = tpBarSettings.anchorTo or tpBarDefaults.anchorTo,
            anchorPoint = tpBarSettings.anchorPoint or tpBarDefaults.anchorPoint,
            anchorCollapse = tpBarSettings.anchorCollapse,
            anchorSpacing = tpBarSettings.anchorSpacing,
            anchorOrder = tpBarSettings.anchorOrder,
            textureId = barTextures.GetTextureId(tpBarSettings.texture),
            color2 = tpBarSettings.color2 or tpBarDefaults.color2,
            color3 = tpBarSettings.color3 or tpBarDefaults.color3,
            showAtPercent = GetTpPreviewThreshold(tpBarSettings, context, 300),
            segmented = tpBarSettings.segmented ~= false,
            segmentGap = tonumber(tpBarSettings.segmentGap) or 6,
            text = BuildResourceText(tpBarSettings, 'TP', tpValue, 3000, tpPercent),
            textOffsetX = tonumber(tpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(tpBarSettings.textOffsetY) or 0,
            fontFamily = fonts.GetRole(globalSettings, tpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, tpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(tpBarSettings.fontSize, tpBarDefaults.fontSize),
            textColor = tpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = tpBarSettings.textOutlineEnabled == true,
            textOutlineColor = tpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(tpBarSettings.textOutlineSize) or 1,
        },
    };

    if (stateName == 'Jug Pet') then
        AddPreviewPetTimerBadge(plateData, 'Jug 90m', petTimerSettings, globalSettings, 'Jug', 'jug');
        AddPreviewPetStateBadge(plateData, 'Fight', petStateSettings, globalSettings);
        plateData.extraBars = plateData.extraBars or {};
        local readyCounterText = (readySettings.showPercent == true) and '3/3' or '';
        local readyLabelText = (tostring(readySettings.labelDisplayMode or 'Text') == 'Text') and 'Ready' or '';

        plateData.extraBars[#plateData.extraBars + 1] = BuildPreviewExtraBar(readySettings, petReadyBarDefaults, 100, readyCounterText, 'ready', 'ready', globalSettings, readyLabelText);
        plateData.extraBars[#plateData.extraBars + 1] = BuildPreviewExtraBar(rewardSettings, petRewardBarDefaults, 100, '', 'reward', 'reward', globalSettings, (tostring(rewardSettings.labelDisplayMode or 'Text') == 'Text') and 'Reward' or '');
    else
        AddPreviewPetTimerBadge(plateData, 'Charmed 4m', petTimerSettings, globalSettings, 'Charmed', 'charmed');
        AddPreviewPetStateBadge(plateData, 'Stay', petStateSettings, globalSettings);
        local sicLabelText = (tostring(sicSettings.labelDisplayMode or 'Text') == 'Text') and 'Sic' or '';
        local sicBar = BuildPreviewExtraBar(CopySettingsWith(sicSettings, { segmented = false, showPercent = false }), petReadyBarDefaults, 100, '', 'sic', 'sic', globalSettings, sicLabelText);

        if (sicBar ~= nil) then
            plateData.extraBars = plateData.extraBars or {};
            plateData.extraBars[#plateData.extraBars + 1] = sicBar;
        end

        plateData.extraBars = plateData.extraBars or {};
        plateData.extraBars[#plateData.extraBars + 1] = BuildPreviewExtraBar(rewardSettings, petRewardBarDefaults, 100, '', 'reward', 'reward', globalSettings, (tostring(rewardSettings.labelDisplayMode or 'Text') == 'Text') and 'Reward' or '');
    end

    AddEnmityPreviewIcon(plateData, globalSettings, context);

    return plateData;
end

local function BuildWyvernPreviewPlate(name, nameSettings, backgroundSettings, hpBarSettings, tpBarSettings, distanceSettings, globalSettings, context)
    local hpPercent = 92;
    local tpValue = GetTpPreviewValue(tpBarSettings, context, 3000);
    local tpPercent = tpValue / 10;
    local hpColor = hpBarSettings.color or barDefaults.color;
    local tpColor = tpBarSettings.color or tpBarDefaults.color;
    local previewStateName = context ~= nil and context.stateName or 'Wyvern';
    local playerIconSettings = GetPlayerPreviewIconSettings('Wyvern', previewStateName);
    local enemyMobInfoIconSettings = GetEnemyMobInfoPreviewIconSettings('Wyvern', previewStateName);

    local hpLowActive = (
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25)
    );
    local tpLowActive = (
        tpBarSettings.lowColorEnabled == true and
        tpPercent <= (tonumber(tpBarSettings.lowColorPercent) or 25)
    );

    if (hpLowActive == true) then
        hpColor = hpBarSettings.lowColor or hpColor;
    end

    if (tpLowActive == true) then
        tpColor = tpBarSettings.lowColor or tpColor;
    end

    local plateData = {
        hp = hpPercent,
        tp = tpPercent,
        targetMarker = BuildTargetMarker(context, hpBarSettings),
        background = {
            enabled = backgroundSettings.enabled == true,
            width = tonumber(backgroundSettings.width) or backgroundDefaults.width,
            height = tonumber(backgroundSettings.height) or backgroundDefaults.height,
            offsetX = tonumber(backgroundSettings.offsetX) or backgroundDefaults.offsetX,
            offsetY = tonumber(backgroundSettings.offsetY) or backgroundDefaults.offsetY,
            color = backgroundSettings.color or backgroundDefaults.color,
            borderColor = backgroundSettings.borderColor or backgroundDefaults.borderColor,
            borderSize = tonumber(backgroundSettings.borderSize) or backgroundDefaults.borderSize,
            texture = backgroundSettings.texture or backgroundDefaults.texture,
            textureId = backgroundTextures.GetTextureId(backgroundSettings.texture or backgroundDefaults.texture),
            imageOpacity = backgroundSettings.imageOpacity or backgroundDefaults.imageOpacity,
            anchorTo = backgroundSettings.anchorTo or backgroundDefaults.anchorTo,
            anchorPoint = backgroundSettings.anchorPoint or backgroundDefaults.anchorPoint,
            anchorCollapse = backgroundSettings.anchorCollapse,
            anchorSpacing = backgroundSettings.anchorSpacing,
            anchorOrder = backgroundSettings.anchorOrder,
        },
        name = (nameSettings.enabled == true) and tostring(name or 'Lumiere') or '',
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(nameSettings.textSize, nameDefaults.textSize),
        nameColor = nameSettings.color or nameDefaults.color,
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = nameSettings.outlineColor or nameDefaults.outlineColor,
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = ClampTextureOffset(tonumber(nameSettings.offsetX) or nameDefaults.offsetX, 1024, 24),
        nameOffsetY = ClampTextureOffset(tonumber(nameSettings.offsetY) or nameDefaults.offsetY, 512, 24),
        nameAnchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
        nameAnchorCollapse = nameSettings.anchorCollapse,
        nameAnchorOrder = nameSettings.anchorOrder,
        anchorFallbackRects = BuildPreviewAnchorFallbackRects({
            { kind = 'allianceLeaderIcon', settings = playerIconSettings.allianceLeader, defaults = allianceLeaderIconDefaults, defaultX = -120, defaultY = -54 },
            { kind = 'partyLeaderIcon', settings = playerIconSettings.partyLeader, defaults = partyLeaderIconDefaults, defaultX = -96, defaultY = -54 },
            { kind = 'gameModeIcon', settings = playerIconSettings.gameMode, defaults = gameModeIconDefaults, defaultX = -72, defaultY = -54 },
            { kind = 'linkshellIcon', settings = playerIconSettings.linkshell, defaults = linkshellIconDefaults, defaultX = 48, defaultY = -54 },
            { kind = 'bazaarIcon', settings = playerIconSettings.bazaar, defaults = bazaarIconDefaults, defaultX = 72, defaultY = -54 },
            { kind = 'awayIcon', settings = playerIconSettings.away, defaults = awayIconDefaults, defaultX = 120, defaultY = -54 },
            { kind = 'disconnectIcon', settings = playerIconSettings.disconnect, defaults = disconnectIconDefaults, defaultX = 144, defaultY = -54 },
            { kind = 'starsIcon', settings = playerIconSettings.stars, defaults = starsIconDefaults, defaultX = -48, defaultY = -54 },
            { kind = 'levelSyncIcon', settings = playerIconSettings.levelSync, defaults = levelSyncIconDefaults, defaultX = -24, defaultY = -54 },
            { kind = 'newAdventurerIcon', settings = playerIconSettings.newAdventurer, defaults = newAdventurerIconDefaults, defaultX = 24, defaultY = -54 },
            { kind = 'Behavior icon', settings = enemyMobInfoIconSettings.behavior, defaults = enemyBehaviorIconDefaults, defaultX = -96, defaultY = -34 },
            { kind = 'Detects icon', settings = enemyMobInfoIconSettings.detects, defaults = enemyDetectsIconDefaults, defaultX = -72, defaultY = -34 },
            { kind = 'Links icon', settings = enemyMobInfoIconSettings.links, defaults = enemyLinksIconDefaults, defaultX = -48, defaultY = -34 },
        }),
        hpBar = {
            enabled = hpBarSettings.enabled == true,
            width = tonumber(hpBarSettings.width) or barDefaults.width,
            height = tonumber(hpBarSettings.height) or barDefaults.height,
            offsetX = tonumber(hpBarSettings.offsetX) or barDefaults.offsetX,
            offsetY = tonumber(hpBarSettings.offsetY) or barDefaults.offsetY,
            color = hpColor,
            backgroundColor = hpBarSettings.backgroundColor or barDefaults.backgroundColor,
            borderColor = hpBarSettings.borderColor or barDefaults.borderColor,
            borderSize = tonumber(hpBarSettings.borderSize) or barDefaults.borderSize,
            anchorTo = hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            anchorCollapse = hpBarSettings.anchorCollapse,
            anchorSpacing = hpBarSettings.anchorSpacing,
            anchorOrder = hpBarSettings.anchorOrder,
            texture = hpBarSettings.texture or barDefaults.texture,
            textureId = barTextures.GetTextureId(hpBarSettings.texture or barDefaults.texture),
            animationEnabled = hpLowActive == true and hpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(hpBarSettings.lowAnimation),
            animationSpeed = tonumber(hpBarSettings.lowAnimationSpeed) or barDefaults.lowAnimationSpeed,
            animationColor = hpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(hpBarSettings.showAtPercent) or barDefaults.showAtPercent,
            text = BuildPercentFallbackResourceText(hpBarSettings, 'HP', nil, nil, hpPercent),
            textOffsetX = tonumber(hpBarSettings.textOffsetX) or barDefaults.textOffsetX,
            textOffsetY = tonumber(hpBarSettings.textOffsetY) or barDefaults.textOffsetY,
            fontFamily = fonts.GetRole(globalSettings, hpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, hpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(hpBarSettings.fontSize, barDefaults.fontSize),
            textColor = hpBarSettings.textColor or barDefaults.textColor,
            textOutlineEnabled = hpBarSettings.textOutlineEnabled == true,
            textOutlineColor = hpBarSettings.textOutlineColor or barDefaults.textOutlineColor,
            textOutlineSize = tonumber(hpBarSettings.textOutlineSize) or barDefaults.textOutlineSize,
        },
        mpBar = {
            enabled = false,
        },
        tpBar = {
            enabled = tpBarSettings.enabled == true,
            width = tonumber(tpBarSettings.width) or tpBarDefaults.width,
            height = tonumber(tpBarSettings.height) or tpBarDefaults.height,
            offsetX = tonumber(tpBarSettings.offsetX) or tpBarDefaults.offsetX,
            offsetY = tonumber(tpBarSettings.offsetY) or tpBarDefaults.offsetY,
            color = tpColor,
            backgroundColor = tpBarSettings.backgroundColor or tpBarDefaults.backgroundColor,
            borderColor = tpBarSettings.borderColor or tpBarDefaults.borderColor,
            borderSize = tonumber(tpBarSettings.borderSize) or tpBarDefaults.borderSize,
            anchorTo = tpBarSettings.anchorTo or tpBarDefaults.anchorTo,
            anchorPoint = tpBarSettings.anchorPoint or tpBarDefaults.anchorPoint,
            anchorCollapse = tpBarSettings.anchorCollapse,
            anchorSpacing = tpBarSettings.anchorSpacing,
            anchorOrder = tpBarSettings.anchorOrder,
            texture = tpBarSettings.texture or tpBarDefaults.texture,
            textureId = barTextures.GetTextureId(tpBarSettings.texture or tpBarDefaults.texture),
            animationEnabled = tpLowActive == true and tpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(tpBarSettings.lowAnimation),
            animationSpeed = tonumber(tpBarSettings.lowAnimationSpeed) or tpBarDefaults.lowAnimationSpeed,
            animationColor = tpBarSettings.lowAnimationColor,
            color2 = tpBarSettings.color2 or tpBarDefaults.color2,
            color3 = tpBarSettings.color3 or tpBarDefaults.color3,
            showAtPercent = GetTpPreviewThreshold(tpBarSettings, context, tpBarDefaults.showAtPercent),
            segmented = tpBarSettings.segmented ~= false,
            segmentGap = tonumber(tpBarSettings.segmentGap) or tpBarDefaults.segmentGap,
            text = BuildResourceText(tpBarSettings, 'TP', tpValue, 3000, tpPercent),
            textOffsetX = tonumber(tpBarSettings.textOffsetX) or tpBarDefaults.textOffsetX,
            textOffsetY = tonumber(tpBarSettings.textOffsetY) or tpBarDefaults.textOffsetY,
            fontFamily = fonts.GetRole(globalSettings, tpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, tpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(tpBarSettings.fontSize, tpBarDefaults.fontSize),
            textColor = tpBarSettings.textColor or tpBarDefaults.textColor,
            textOutlineEnabled = tpBarSettings.textOutlineEnabled == true,
            textOutlineColor = tpBarSettings.textOutlineColor or tpBarDefaults.textOutlineColor,
            textOutlineSize = tonumber(tpBarSettings.textOutlineSize) or tpBarDefaults.textOutlineSize,
        },
    };

    if (ShouldShowDistancePreview(context, distanceSettings) == true and distanceSettings ~= nil) then
        plateData.badges = plateData.badges or {};
        plateData.badges[#plateData.badges + 1] = {
            kind = 'distance',
            text = tostring(distanceSettings.prefix or '') .. '12.4',
            offsetX = tonumber(distanceSettings.offsetX) or distanceDefaults.offsetX,
            offsetY = tonumber(distanceSettings.offsetY) or distanceDefaults.offsetY,
            fontFamily = fonts.GetRole(globalSettings, distanceSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, distanceSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(distanceSettings.textSize, distanceDefaults.textSize),
            textColor = distanceSettings.color or distanceDefaults.color,
            textOutlineEnabled = distanceSettings.outlineEnabled == true,
            textOutlineColor = distanceSettings.outlineColor or distanceDefaults.outlineColor,
            textOutlineSize = tonumber(distanceSettings.outlineSize) or distanceDefaults.outlineSize,
            anchorTo = distanceSettings.anchorTo or distanceDefaults.anchorTo,
            anchorPoint = distanceSettings.anchorPoint or distanceDefaults.anchorPoint,
            anchorCollapse = distanceSettings.anchorCollapse,
            anchorSpacing = distanceSettings.anchorSpacing,
            anchorOrder = distanceSettings.anchorOrder,
            backgroundEnabled = false,
        };
    end

    AddEnmityPreviewIcon(plateData, globalSettings, context);

    return plateData;
end

local function BuildSmnPetPreviewPlate(stateName, nameSettings, backgroundSettings, hpBarSettings, mpBarSettings, tpBarSettings, castBarSettings, globalSettings, context)
    local isSpirit = stateName == 'Spirit';
    local wardSettings = state.GetWidgetSettings('Pet (SMN)', stateName, 'Ward timer', petWardBarDefaults);
    local rageSettings = state.GetWidgetSettings('Pet (SMN)', stateName, 'Rage timer', petRageBarDefaults);
    local hp = isSpirit and 742 or 985;
    local maxHp = isSpirit and 886 or 1074;
    local mp = 612;
    local maxMp = 886;
    local tpValue = GetTpPreviewValue(tpBarSettings, context, 3000);
    local hpPercent = ClampPercent((hp / maxHp) * 100, 92);
    local mpPercent = ClampPercent((mp / maxMp) * 100, 69);
    local tpPercent = tpValue / 10;
    local hpColor = hpBarSettings.color or { 0.95, 0.45, 0.45, 1.0 };
    local mpColor = mpBarSettings.color or { 0.70, 0.90, 0.45, 1.0 };
    local tpColor = tpBarSettings.color or { 0.0, 0.55, 0.95, 1.0 };
    local hpLowActive = (
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25)
    );
    local mpLowActive = (
        mpBarSettings.lowColorEnabled == true and
        mpPercent <= (tonumber(mpBarSettings.lowColorPercent) or 25)
    );
    local tpLowActive = (
        tpBarSettings.lowColorEnabled == true and
        tpPercent <= (tonumber(tpBarSettings.lowColorPercent) or 25)
    );

    if (hpLowActive == true) then hpColor = hpBarSettings.lowColor or hpColor; end
    if (mpLowActive == true) then mpColor = mpBarSettings.lowColor or mpColor; end
    if (tpLowActive == true) then tpColor = tpBarSettings.lowColor or tpColor; end

    local plateData = {
        hp = hpPercent,
        mp = mpPercent,
        tp = tpPercent,
        cast = isSpirit and 62 or 0,
        targetMarker = BuildTargetMarker(context, hpBarSettings),
        background = {
            enabled = backgroundSettings.enabled == true,
            width = tonumber(backgroundSettings.width) or backgroundDefaults.width,
            height = tonumber(backgroundSettings.height) or backgroundDefaults.height,
            offsetX = tonumber(backgroundSettings.offsetX) or backgroundDefaults.offsetX,
            offsetY = tonumber(backgroundSettings.offsetY) or backgroundDefaults.offsetY,
            color = backgroundSettings.color or backgroundDefaults.color,
            borderColor = backgroundSettings.borderColor or backgroundDefaults.borderColor,
            borderSize = tonumber(backgroundSettings.borderSize) or backgroundDefaults.borderSize,
            texture = backgroundSettings.texture or backgroundDefaults.texture,
            textureId = backgroundTextures.GetTextureId(backgroundSettings.texture or backgroundDefaults.texture),
            imageOpacity = backgroundSettings.imageOpacity or backgroundDefaults.imageOpacity,
            anchorTo = backgroundSettings.anchorTo or backgroundDefaults.anchorTo,
            anchorPoint = backgroundSettings.anchorPoint or backgroundDefaults.anchorPoint,
            anchorCollapse = backgroundSettings.anchorCollapse,
            anchorSpacing = backgroundSettings.anchorSpacing,
            anchorOrder = backgroundSettings.anchorOrder,
        },
        name = (nameSettings.enabled == true) and (isSpirit and 'LightSpirit' or 'Carbuncle') or '',
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(nameSettings.textSize, nameDefaults.textSize),
        nameColor = nameSettings.color or { 1.0, 1.0, 1.0, 1.0 },
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = nameSettings.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = ClampTextureOffset(tonumber(nameSettings.offsetX) or -38, 1024, 24),
        nameOffsetY = ClampTextureOffset(tonumber(nameSettings.offsetY) or -34, 512, 24),
        nameAnchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
        nameAnchorCollapse = nameSettings.anchorCollapse,
        nameAnchorOrder = nameSettings.anchorOrder,
        hpBar = {
            enabled = hpBarSettings.enabled == true,
            width = tonumber(hpBarSettings.width) or 160,
            height = tonumber(hpBarSettings.height) or 14,
            offsetX = tonumber(hpBarSettings.offsetX) or 0,
            offsetY = tonumber(hpBarSettings.offsetY) or -16,
            color = hpColor,
            backgroundColor = hpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = hpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(hpBarSettings.borderSize) or 0,
            anchorTo = hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            anchorCollapse = hpBarSettings.anchorCollapse,
            anchorSpacing = hpBarSettings.anchorSpacing,
            anchorOrder = hpBarSettings.anchorOrder,
            textureId = barTextures.GetTextureId(hpBarSettings.texture),
            animationEnabled = hpLowActive == true and hpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(hpBarSettings.lowAnimation),
            animationSpeed = tonumber(hpBarSettings.lowAnimationSpeed) or 40,
            animationColor = hpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(hpBarSettings.showAtPercent) or 100,
            text = pupPreview == true and BuildPercentFallbackResourceText(hpBarSettings, 'HP', nil, nil, hpPercent) or BuildResourceText(hpBarSettings, 'HP', hp, maxHp, hpPercent),
            textOffsetX = tonumber(hpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(hpBarSettings.textOffsetY) or 0,
            fontFamily = fonts.GetRole(globalSettings, hpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, hpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(hpBarSettings.fontSize, barDefaults.fontSize),
            textColor = hpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = hpBarSettings.textOutlineEnabled == true,
            textOutlineColor = hpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(hpBarSettings.textOutlineSize) or 1,
        },
        mpBar = {
            enabled = isSpirit and mpBarSettings.enabled == true,
            width = tonumber(mpBarSettings.width) or 170,
            height = tonumber(mpBarSettings.height) or 12,
            offsetX = tonumber(mpBarSettings.offsetX) or 0,
            offsetY = tonumber(mpBarSettings.offsetY) or 16,
            color = mpColor,
            backgroundColor = mpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = mpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(mpBarSettings.borderSize) or 0,
            anchorTo = mpBarSettings.anchorTo or mpBarDefaults.anchorTo,
            anchorPoint = mpBarSettings.anchorPoint or mpBarDefaults.anchorPoint,
            anchorCollapse = mpBarSettings.anchorCollapse,
            anchorSpacing = mpBarSettings.anchorSpacing,
            anchorOrder = mpBarSettings.anchorOrder,
            textureId = barTextures.GetTextureId(mpBarSettings.texture),
            animationEnabled = mpLowActive == true and mpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(mpBarSettings.lowAnimation),
            animationSpeed = tonumber(mpBarSettings.lowAnimationSpeed) or 40,
            animationColor = mpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(mpBarSettings.showAtPercent) or 100,
            text = pupPreview == true and BuildPercentFallbackResourceText(mpBarSettings, 'MP', mp, maxMp, mpPercent) or BuildResourceText(mpBarSettings, 'MP', mp, maxMp, mpPercent),
            textOffsetX = tonumber(mpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(mpBarSettings.textOffsetY) or 0,
            fontFamily = fonts.GetRole(globalSettings, mpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, mpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(mpBarSettings.fontSize, mpBarDefaults.fontSize),
            textColor = mpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = mpBarSettings.textOutlineEnabled == true,
            textOutlineColor = mpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(mpBarSettings.textOutlineSize) or 1,
        },
        tpBar = {
            enabled = (not isSpirit) and tpBarSettings.enabled == true,
            width = tonumber(tpBarSettings.width) or 170,
            height = tonumber(tpBarSettings.height) or 12,
            offsetX = tonumber(tpBarSettings.offsetX) or 0,
            offsetY = tonumber(tpBarSettings.offsetY) or 30,
            color = tpColor,
            backgroundColor = tpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = tpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(tpBarSettings.borderSize) or 0,
            anchorTo = tpBarSettings.anchorTo or tpBarDefaults.anchorTo,
            anchorPoint = tpBarSettings.anchorPoint or tpBarDefaults.anchorPoint,
            anchorCollapse = tpBarSettings.anchorCollapse,
            anchorSpacing = tpBarSettings.anchorSpacing,
            anchorOrder = tpBarSettings.anchorOrder,
            textureId = barTextures.GetTextureId(tpBarSettings.texture),
            color2 = tpBarSettings.color2 or tpBarDefaults.color2,
            color3 = tpBarSettings.color3 or tpBarDefaults.color3,
            showAtPercent = GetTpPreviewThreshold(tpBarSettings, context, 300),
            segmented = tpBarSettings.segmented ~= false,
            segmentGap = tonumber(tpBarSettings.segmentGap) or 6,
            text = BuildResourceText(tpBarSettings, 'TP', tpValue, 3000, tpPercent),
            textOffsetX = tonumber(tpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(tpBarSettings.textOffsetY) or 0,
            fontFamily = fonts.GetRole(globalSettings, tpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, tpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(tpBarSettings.fontSize, tpBarDefaults.fontSize),
            textColor = tpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = tpBarSettings.textOutlineEnabled == true,
            textOutlineColor = tpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(tpBarSettings.textOutlineSize) or 1,
        },
        castBar = {
            enabled = isSpirit and castBarSettings.enabled == true,
            width = tonumber(castBarSettings.width) or castBarDefaults.width,
            height = tonumber(castBarSettings.height) or castBarDefaults.height,
            offsetX = tonumber(castBarSettings.offsetX) or castBarDefaults.offsetX,
            offsetY = tonumber(castBarSettings.offsetY) or castBarDefaults.offsetY,
            color = castBarSettings.color or castBarDefaults.color,
            backgroundColor = castBarSettings.backgroundColor or castBarDefaults.backgroundColor,
            borderColor = castBarSettings.borderColor or castBarDefaults.borderColor,
            borderSize = tonumber(castBarSettings.borderSize) or castBarDefaults.borderSize,
            anchorTo = castBarSettings.anchorTo or castBarDefaults.anchorTo,
            anchorPoint = castBarSettings.anchorPoint or castBarDefaults.anchorPoint,
            anchorCollapse = castBarSettings.anchorCollapse,
            anchorSpacing = castBarSettings.anchorSpacing,
            anchorOrder = castBarSettings.anchorOrder,
            textureId = barTextures.GetTextureId(castBarSettings.texture),
            text = (castBarSettings.showSpellName ~= false) and 'Stone III' or '',
            textOffsetX = tonumber(castBarSettings.textOffsetX) or castBarDefaults.textOffsetX,
            textOffsetY = tonumber(castBarSettings.textOffsetY) or castBarDefaults.textOffsetY,
            fontFamily = fonts.GetRole(globalSettings, castBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, castBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(castBarSettings.fontSize, castBarDefaults.fontSize),
            textColor = castBarSettings.textColor or castBarDefaults.textColor,
            textOutlineEnabled = castBarSettings.textOutlineEnabled == true,
            textOutlineColor = castBarSettings.textOutlineColor or castBarDefaults.textOutlineColor,
            textOutlineSize = tonumber(castBarSettings.textOutlineSize) or castBarDefaults.textOutlineSize,
            separateLabelOffsets = true,
            iconTextureId = castBarSettings.showSpellIcon == true
                and require('core.spell_icon_textures').GetTextureId(145)
                or nil,
            iconSize = tonumber(castBarSettings.spellIconSize) or castBarDefaults.spellIconSize,
            iconOffsetX = tonumber(castBarSettings.spellIconOffsetX) or castBarDefaults.spellIconOffsetX,
            iconOffsetY = tonumber(castBarSettings.spellIconOffsetY) or castBarDefaults.spellIconOffsetY,
            iconGap = 4,
        },
    };

    if (isSpirit ~= true) then
        plateData.extraBars = plateData.extraBars or {};
        plateData.extraBars[#plateData.extraBars + 1] = BuildPreviewExtraBar(wardSettings, petWardBarDefaults, 72, (wardSettings.showPercent ~= false) and '17' or '', 'ward', 'ward', globalSettings, (tostring(wardSettings.labelDisplayMode or 'Text') == 'Text') and 'Ward' or '');
        plateData.extraBars[#plateData.extraBars + 1] = BuildPreviewExtraBar(rageSettings, petRageBarDefaults, 100, '', 'rage', 'rage', globalSettings, (tostring(rageSettings.labelDisplayMode or 'Text') == 'Text') and 'Rage' or '');
    end

    AddEnmityPreviewIcon(plateData, globalSettings, context);

    return plateData;
end

local AddPeerPreview = nil;

local function BuildPlate(entityName, stateName, context)
    entityName = tostring(entityName or 'Self');
    stateName = tostring(stateName or 'Idle');
    local storageEntityName = (entityName == 'NPC/Object') and 'NPC' or ((entityName == 'Pet (PUP)') and 'Automaton' or ((entityName == 'Pet (DRG)') and 'Wyvern' or entityName));
    local hpDefaults = (entityName == 'Pet (SMN)') and smnHpBarDefaults or barDefaults;
    local mpDefaults = (entityName == 'Pet (SMN)') and smnMpBarDefaults or mpBarDefaults;
    local tpDefaults = (entityName == 'Pet (SMN)') and smnTpBarDefaults or tpBarDefaults;
    local castDefaults = (entityName == 'Pet (SMN)') and smnCastBarDefaults or castBarDefaults;

    local nameSettings = state.GetWidgetSettings(storageEntityName, stateName, 'Name', nameDefaults);
    local backgroundSettings = state.GetWidgetSettings(storageEntityName, stateName, 'Background', backgroundDefaults);
    local hpBarSettings = state.GetWidgetSettings(storageEntityName, stateName, 'HP Bar', hpDefaults);
    local jobSettings = state.GetWidgetSettings(storageEntityName, stateName, 'Job', jobDefaults);
    local levelSettings = state.GetWidgetSettings(storageEntityName, stateName, 'Level', levelDefaults);
    local idSettings = state.GetWidgetSettings(storageEntityName, stateName, 'ID', idDefaults);
    local distanceSettings = state.GetWidgetSettings(storageEntityName, stateName, 'Distance', distanceDefaults);
    local typeLineSettings = state.GetWidgetSettings(storageEntityName, stateName, 'Type line', typeLineDefaults);
    local iconSettings = state.GetWidgetSettings(storageEntityName, stateName, 'Icon', npcObjectIconDefaults);
    local buffsSettings = state.GetWidgetSettings(storageEntityName, stateName, 'Buffs', entityName == 'Trust' and trustBuffPreviewDefaults or buffsDefaults);
    local debuffsSettings = state.GetWidgetSettings(storageEntityName, stateName, 'Debuffs', debuffsDefaults);
    local mpBarSettings = state.GetWidgetSettings(storageEntityName, stateName, 'MP Bar', mpDefaults);
    local tpBarSettings = state.GetWidgetSettings(storageEntityName, stateName, 'TP Bar', tpDefaults);
    local castBarSettings = state.GetWidgetSettings(storageEntityName, stateName, 'Cast bar', castDefaults);
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local aoeRangeSettings = nil;
    if (context ~= nil and context.widgetKey == 'AOE range' and stateName == 'Combat') then
        aoeRangeSettings = state.GetWidgetSettings((entityName == 'Enemy') and 'Enemy' or 'Self', 'Combat', 'AOE range', aoeRangeDefaults);
    end
    local playerIconSettings = GetPlayerPreviewIconSettings(storageEntityName, stateName);
    local enemyMobInfoIconSettings = GetEnemyMobInfoPreviewIconSettings(storageEntityName, stateName);
    local anonIconSettings = state.GetWidgetSettings(storageEntityName, stateName, 'Anon icon', anonIconDefaults);
    local followIconSettings = state.GetWidgetSettings(storageEntityName, stateName, 'Follow icon', followIconDefaults);
    local levelSyncIconSettings = state.GetWidgetSettings(storageEntityName, stateName, 'Level sync icon', levelSyncIconDefaults);
    local maneuverSettings = state.GetWidgetSettings(storageEntityName, stateName, 'Maneuvers', maneuverDefaults);

    if (entityName == 'NPC' or entityName == 'Object' or entityName == 'NPC/Object') then
        ApplyNpcAnchorDefaults(iconSettings, npcObjectIconDefaults, -28, -30);
        ApplyNpcAnchorDefaults(typeLineSettings, typeLineDefaults, 0, -30);
    end

    local hp = 985;
    local maxHp = 1074;
    local mp = 612;
    local maxMp = 886;
    local tp = 1375;
    local tpBarDemoPreview = context ~= nil and context.widgetKey == 'TP Bar';
    local pupPreview = (entityName == 'Pet (PUP)');

    if (pupPreview == true) then
        hp = nil;
        maxHp = nil;
        mp = nil;
        maxMp = nil;
        tp = 3000;
    end
    tp = GetTpPreviewValue(tpBarSettings, context, tp);
    local previewNames = {
        ['PC'] = 'Libra',
        ['Enemy'] = (enemyPreviewNameMode == 'Short') and 'Puk' or 'Sabotender Enamorado',
        ['Trust'] = 'Kupipi',
        ['Pet (BST)'] = (stateName == 'Charmed Pet') and 'Desert Beetle' or 'CourierCarrie',
        ['Pet (DRG)'] = 'Lumiere',
        ['Pet (PUP)'] = 'Lobo',
        ['Luopan'] = 'Luopan',
        ['NPC'] = (stateName == 'Combat') and 'Lhu Mhakaracca' or 'Hunter',
        ['Object'] = 'Mining Point',
        ['NPC/Object'] = 'Hunter',
    };
    local previewName = previewNames[entityName] or 'Player';
    local self = nil;

    if (entityName == 'Self') then
        pcall(function()
            self = entities.GetSelf();
        end);

        if (self ~= nil and self.name ~= nil and tostring(self.name) ~= '') then
            previewName = tostring(self.name);
        end

    end

    local hpPercent = pupPreview == true and 100 or ClampPercent((hp / maxHp) * 100, 92);
    local mpPercent = pupPreview == true and 0 or ClampPercent((mp / maxMp) * 100, 69);
    local tpPercent = math.max(0, math.min(300, (math.max(0, math.min(3000, tp)) / 10)));

    local npcObjectPreview = (entityName == 'NPC' or entityName == 'Object' or entityName == 'NPC/Object');
    local npcTacticalPreview = entityName == 'NPC' and stateName == 'Combat';

    local hpColor = hpBarSettings.color or { 0.20, 0.95, 0.34, 0.95 };
    local mpColor = mpBarSettings.color or { 0.25, 0.45, 1.0, 0.95 };
    local tpColor = tpBarSettings.color or { 1.0, 0.70, 0.18, 0.95 };
    local tpColor2 = tpBarSettings.color2 or tpBarDefaults.color2;
    local tpColor3 = tpBarSettings.color3 or tpBarDefaults.color3;
    local icons = {};
    local previewAoeActive = (
        stateName == 'Combat' and
        context ~= nil and
        context.widgetKey == 'AOE range' and
        aoeRangeSettings ~= nil and
        aoeRangeSettings.enabled == true
    );
    local previewNameSize = nameSettings.textSize;
    local previewNameColor = (entityName == 'Enemy') and (nameSettings.claimUnclaimedColor or nameDefaults.claimUnclaimedColor or nameSettings.color or nameDefaults.color) or (nameSettings.color or { 1.0, 1.0, 1.0, 1.0 });
    local previewNameOutlineColor = (entityName == 'Enemy') and (nameSettings.claimUnclaimedOutlineColor or nameDefaults.claimUnclaimedOutlineColor or nameSettings.outlineColor or nameDefaults.outlineColor) or (nameSettings.outlineColor or { 0.0, 0.0, 0.0, 1.0 });

    if (previewAoeActive == true) then
        previewNameSize = math.max(tonumber(nameSettings.textSize) or nameDefaults.textSize, tonumber(aoeRangeSettings.fontSize) or aoeRangeDefaults.fontSize);
        previewNameColor = aoeRangeSettings.fontColor or aoeRangeDefaults.fontColor;
    end

    if (
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25)
    ) then
        hpColor = hpBarSettings.lowColor or hpColor;
    end

    if (
        mpBarSettings.lowColorEnabled == true and
        mpPercent <= (tonumber(mpBarSettings.lowColorPercent) or 25)
    ) then
        mpColor = mpBarSettings.lowColor or mpColor;
    end

    if (
        tpBarSettings.lowColorEnabled == true and
        tpPercent <= (tonumber(tpBarSettings.lowColorPercent) or 25)
    ) then
        tpColor = tpBarSettings.lowColor or tpColor;
    end


    if (tpPercent >= 100 and tpBarDemoPreview ~= true) then
        tpColor = tpBarSettings.fullColor or tpBarDefaults.fullColor or tpColor;
        tpColor2 = tpColor;
        tpColor3 = tpColor;
    end

    if (entityName == 'Pet (BST)') then
        return BuildPetPreviewPlate(
            stateName,
            nameSettings,
            backgroundSettings,
            hpBarSettings,
            tpBarSettings,
            globalSettings,
            context
        );
    end

    if (entityName == 'Pet (SMN)') then
        return BuildSmnPetPreviewPlate(
            stateName,
            nameSettings,
            backgroundSettings,
            hpBarSettings,
            mpBarSettings,
            tpBarSettings,
            castBarSettings,
            globalSettings,
            context
        );
    end

    if (entityName == 'Pet (DRG)') then
        return BuildWyvernPreviewPlate(
            previewName,
            nameSettings,
            backgroundSettings,
            hpBarSettings,
            tpBarSettings,
            distanceSettings,
            globalSettings,
            context
        );
    end

    if (entityName == 'Self' or entityName == 'PC' or entityName == 'Trust') then
        AddPlayerPreviewIcons(icons, playerIconSettings, entityName, stateName);
    end

    if ((entityName == 'Enemy' or entityName == 'Self' or entityName == 'Trust' or (entityName == 'PC' and stateName == 'Combat')) and (context == nil or context.widgetKey ~= 'Peer')) then
        local buffRows = T{};
        local buffStatusIds = {
            27, 33, 35, 36, 37, 39, 40, 41,
            42, 43, 48, 84, 85, 93, 94, 101,
            107, 113, 189, 199, 327, 328, 539, 541,
            160, 161, 0, 69, 70, 71, 574, 585,
        };
        local buffDurations = {
            2, 4, 9, 20, 36, 58,
            60, 120, 300, 360, 540, 720,
            840, 960, 1320, 1440, 1500, 2040,
            3120, 3600, 14400, 21600, 28800, 36000,
            43200, 50400, 57600, 64800, 72000, 75600,
            79200, 82800,
        };
        for index, statusId in ipairs(buffStatusIds) do
            buffRows[#buffRows + 1] = {
                id = statusId,
                seconds = buffDurations[index],
            };
        end

        local debuffRows = T{};
        local debuffStatusIds = {
            4, 13, 134, 2, 3, 5, 6, 7,
            8, 9, 10, 11, 12, 14, 15, 16,
            17, 18, 19, 20, 21, 22, 23, 24,
            25, 26, 27, 28, 29, 30, 31, 32,
        };
        for index, statusId in ipairs(debuffStatusIds) do
            debuffRows[#debuffRows + 1] = {
                id = statusId,
                seconds = buffDurations[index],
            };
        end

        AddStatusPreviewIcons(icons, buffsSettings, buffRows, 'buffs');
        AddStatusPreviewIcons(icons, debuffsSettings, debuffRows, 'debuffs');
    end

    if (
        entityName == 'Enemy' and
        (
            stateName == 'Idle' or
            stateName == 'World' or
            stateName == 'Combat' or
            stateName == 'Tactical'
        )
    ) then
        AddEnemyWorldMobInfoPreviewIcons(icons, globalSettings, enemyMobInfoIconSettings, nameSettings, context);
    end

    local plateData = {
        hp = hpPercent,
        mp = mpPercent,
        tp = tpPercent,
        name = (nameSettings.enabled == true) and previewName or '',
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(previewNameSize, nameDefaults.textSize),
        nameColor = previewNameColor,
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = previewNameOutlineColor,
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = tonumber(nameSettings.offsetX) or 0,
        nameOffsetY = tonumber(nameSettings.offsetY) or -54,
        nameAnchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
        nameAnchorOrder = nameSettings.anchorOrder,
        aoeNameActive = previewAoeActive == true,
        anchorMap = {
            ['Background'] = 'background',
            ['Name'] = 'name',
            ['HP Bar'] = 'hp',
            ['MP Bar'] = 'mp',
            ['TP Bar'] = 'tp',
            ['Cast bar'] = 'cast',
            ['Job'] = 'job',
            ['Level'] = 'level',
            ['ID'] = 'id',
            ['Icon'] = 'npc_object_icon',
            ['Game mode icon'] = 'gameModeIcon',
            ['Linkshell icon'] = 'linkshellIcon',
            ['Behavior icon'] = 'Behavior icon',
            ['Detects icon'] = 'Detects icon',
            ['Links icon'] = 'Links icon',
            ['Special icon'] = 'catseyeSpecialNameIcon',
            ['Bazaar icon'] = 'bazaarIcon',
            ['Away icon'] = 'awayIcon',
            ['Disconnect icon'] = 'disconnectIcon',
            ['Anon icon'] = 'anonIcon',
            ['Follow icon'] = 'followIcon',
            ['Party leader icon'] = 'partyLeaderIcon',
            ['Alliance leader icon'] = 'allianceLeaderIcon',
            ['Stars icon'] = 'starsIcon',
            ['Level sync icon'] = 'levelSyncIcon',
            ['New adventurer icon'] = 'newAdventurerIcon',
            ['Buffs'] = 'buffs',
            ['Debuffs'] = 'debuffs',
            ['Type line'] = 'type',
            ['Distance'] = 'distance',
        },
        hpBar = {
            enabled = (npcObjectPreview ~= true or npcTacticalPreview == true) and hpBarSettings.enabled == true,
            width = tonumber(hpBarSettings.width) or 180,
            height = tonumber(hpBarSettings.height) or 12,
            offsetX = tonumber(hpBarSettings.offsetX) or 0,
            offsetY = tonumber(hpBarSettings.offsetY) or 0,
            color = hpColor,
            backgroundColor = hpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = hpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(hpBarSettings.borderSize) or 0,
            anchorTo = hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            anchorCollapse = hpBarSettings.anchorCollapse,
            anchorSpacing = hpBarSettings.anchorSpacing,
            anchorOrder = hpBarSettings.anchorOrder,
            textureId = barTextures.GetTextureId(hpBarSettings.texture),
            animationEnabled = (
                hpBarSettings.lowColorEnabled == true and
                hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25) and
                hpBarSettings.lowAnimationEnabled == true
            ),
            animationTextureId = barAnimations.GetTextureId(hpBarSettings.lowAnimation),
            animationSpeed = tonumber(hpBarSettings.lowAnimationSpeed) or 40,
            animationColor = hpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(hpBarSettings.showAtPercent) or 100,
            text = BuildResourceText(hpBarSettings, 'HP', hp, maxHp, hpPercent),
            textOffsetX = tonumber(hpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(hpBarSettings.textOffsetY) or 0,
            fontFamily = fonts.GetRole(globalSettings, hpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, hpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(hpBarSettings.fontSize, barDefaults.fontSize),
            textColor = hpBarSettings.textColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineEnabled = hpBarSettings.textOutlineEnabled == true,
            textOutlineColor = hpBarSettings.textOutlineColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineSize = tonumber(hpBarSettings.textOutlineSize) or 1,
        },
        mpBar = {
            enabled = npcObjectPreview ~= true and mpBarSettings.enabled == true,
            width = tonumber(mpBarSettings.width) or 180,
            height = tonumber(mpBarSettings.height) or 8,
            offsetX = tonumber(mpBarSettings.offsetX) or 0,
            offsetY = tonumber(mpBarSettings.offsetY) or 16,
            color = mpColor,
            backgroundColor = mpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = mpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(mpBarSettings.borderSize) or 0,
            anchorTo = mpBarSettings.anchorTo or mpBarDefaults.anchorTo,
            anchorPoint = mpBarSettings.anchorPoint or mpBarDefaults.anchorPoint,
            anchorCollapse = mpBarSettings.anchorCollapse,
            anchorSpacing = mpBarSettings.anchorSpacing,
            anchorOrder = mpBarSettings.anchorOrder,
            textureId = barTextures.GetTextureId(mpBarSettings.texture),
            animationEnabled = (
                mpBarSettings.lowColorEnabled == true and
                mpPercent <= (tonumber(mpBarSettings.lowColorPercent) or 25) and
                mpBarSettings.lowAnimationEnabled == true
            ),
            animationTextureId = barAnimations.GetTextureId(mpBarSettings.lowAnimation),
            animationSpeed = tonumber(mpBarSettings.lowAnimationSpeed) or 40,
            animationColor = mpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(mpBarSettings.showAtPercent) or 100,
            text = pupPreview == true and BuildPercentFallbackResourceText(mpBarSettings, 'MP', nil, nil, mpPercent) or BuildResourceText(mpBarSettings, 'MP', mp, maxMp, mpPercent),
            textOffsetX = tonumber(mpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(mpBarSettings.textOffsetY) or 0,
            fontFamily = fonts.GetRole(globalSettings, mpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, mpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(mpBarSettings.fontSize, mpBarDefaults.fontSize),
            textColor = mpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = mpBarSettings.textOutlineEnabled == true,
            textOutlineColor = mpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(mpBarSettings.textOutlineSize) or 1,
        },
        tpBar = {
            enabled = npcObjectPreview ~= true and tpBarSettings.enabled == true,
            width = tonumber(tpBarSettings.width) or 180,
            height = tonumber(tpBarSettings.height) or 6,
            offsetX = tonumber(tpBarSettings.offsetX) or 0,
            offsetY = tonumber(tpBarSettings.offsetY) or 28,
            color = tpColor,
            backgroundColor = tpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = tpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(tpBarSettings.borderSize) or 0,
            anchorTo = tpBarSettings.anchorTo or tpBarDefaults.anchorTo,
            anchorPoint = tpBarSettings.anchorPoint or tpBarDefaults.anchorPoint,
            anchorCollapse = tpBarSettings.anchorCollapse,
            anchorSpacing = tpBarSettings.anchorSpacing,
            anchorOrder = tpBarSettings.anchorOrder,
            textureId = barTextures.GetTextureId(tpBarSettings.texture),
            color2 = tpColor2,
            color3 = tpColor3,
            showAtPercent = tpBarDemoPreview == true and 0 or (tonumber(tpBarSettings.showAtPercent) or 300),
            segmented = tpBarSettings.segmented ~= false,
            segmentGap = tonumber(tpBarSettings.segmentGap) or 3,
            text = BuildResourceText(tpBarSettings, 'TP', tp, 3000, tpPercent),
            textOffsetX = tonumber(tpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(tpBarSettings.textOffsetY) or 0,
            fontFamily = fonts.GetRole(globalSettings, tpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, tpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(tpBarSettings.fontSize, tpBarDefaults.fontSize),
            textColor = tpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = tpBarSettings.textOutlineEnabled == true,
            textOutlineColor = tpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(tpBarSettings.textOutlineSize) or 1,
        },
        cast = 62,
        castBar = {
            enabled = npcObjectPreview ~= true and castBarSettings.enabled == true,
            width = tonumber(castBarSettings.width) or 155,
            height = tonumber(castBarSettings.height) or 6,
            offsetX = tonumber(castBarSettings.offsetX) or 0,
            offsetY = tonumber(castBarSettings.offsetY) or 24,
            color = castBarSettings.color or { 0.65, 0.35, 1.0, 0.95 },
            backgroundColor = castBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = castBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(castBarSettings.borderSize) or 0,
            anchorTo = castBarSettings.anchorTo or castBarDefaults.anchorTo,
            anchorPoint = castBarSettings.anchorPoint or castBarDefaults.anchorPoint,
            anchorCollapse = castBarSettings.anchorCollapse,
            anchorSpacing = castBarSettings.anchorSpacing,
            anchorOrder = castBarSettings.anchorOrder,
            textureId = barTextures.GetTextureId(castBarSettings.texture),
            text = (castBarSettings.showSpellName ~= false) and 'Stonega III' or '',
            textOffsetX = tonumber(castBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(castBarSettings.textOffsetY) or 0,
            fontFamily = fonts.GetRole(globalSettings, castBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, castBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(castBarSettings.fontSize, castBarDefaults.fontSize),
            textColor = castBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = castBarSettings.textOutlineEnabled == true,
            textOutlineColor = castBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(castBarSettings.textOutlineSize) or 1,
            separateLabelOffsets = true,
            iconTextureId = castBarSettings.showSpellIcon == true
                and require('core.spell_icon_textures').GetTextureId(145)
                or nil,
            iconSize = tonumber(castBarSettings.spellIconSize) or castBarDefaults.spellIconSize,
            iconOffsetX = tonumber(castBarSettings.spellIconOffsetX) or castBarDefaults.spellIconOffsetX,
            iconOffsetY = tonumber(castBarSettings.spellIconOffsetY) or castBarDefaults.spellIconOffsetY,
            iconGap = 4,
        },
        icons = icons,
        targetMarker = BuildPreviewTargetMarker(entityName, stateName, context, hpBarSettings),
        background = {
            enabled = backgroundSettings.enabled == true,
            width = tonumber(backgroundSettings.width) or backgroundDefaults.width,
            height = tonumber(backgroundSettings.height) or backgroundDefaults.height,
            offsetX = tonumber(backgroundSettings.offsetX) or backgroundDefaults.offsetX,
            offsetY = tonumber(backgroundSettings.offsetY) or backgroundDefaults.offsetY,
            color = backgroundSettings.color or backgroundDefaults.color,
            borderColor = backgroundSettings.borderColor or backgroundDefaults.borderColor,
            borderSize = tonumber(backgroundSettings.borderSize) or backgroundDefaults.borderSize,
            texture = backgroundSettings.texture or backgroundDefaults.texture,
            textureId = backgroundTextures.GetTextureId(backgroundSettings.texture or backgroundDefaults.texture),
            imageOpacity = backgroundSettings.imageOpacity or backgroundDefaults.imageOpacity,
            anchorTo = backgroundSettings.anchorTo or backgroundDefaults.anchorTo,
            anchorPoint = backgroundSettings.anchorPoint or backgroundDefaults.anchorPoint,
        },
    };

    AddEnmityPreviewIcon(plateData, globalSettings, context);
    AddFishingPreviewIcon(plateData, globalSettings, context);
    AddCraftingPreviewWidget(plateData, globalSettings, context);
    AddGatheringPreviewWidget(plateData, globalSettings, context);
    AddRestingPreviewBar(plateData, globalSettings, context);

    if (previewAoeActive == true) then
        aoeRangeVisuals.Apply(plateData, aoeRangeSettings);
    end

    if (entityName == 'Pet (PUP)') then
        pupManeuvers.AddIcons(plateData, maneuverSettings, globalSettings, pupManeuvers.GetPreviewState());
    end

    if ((entityName == 'Enemy' or ((entityName == 'PC' or entityName == 'Trust') and stateName == 'Combat')) and jobSettings ~= nil and jobSettings.enabled == true) then
        local jobText = 'BLM';

        if ((tonumber(jobSettings.displayModeIndex) or 1) == 2) then
            local textureId = jobIconTextures.GetTextureId(jobText, jobSettings.iconTheme);

            if (textureId ~= nil) then
                plateData.icons[#plateData.icons + 1] = {
                    kind = 'job',
                    textureId = textureId,
                    size = math.max(8, math.min(256, tonumber(jobSettings.iconSize) or 16)),
                    offsetX = tonumber(jobSettings.offsetX) or 0,
                    offsetY = tonumber(jobSettings.offsetY) or -54,
                    anchorTo = jobSettings.anchorTo or jobDefaults.anchorTo,
                    anchorPoint = jobSettings.anchorPoint or jobDefaults.anchorPoint,
                    anchorCollapse = jobSettings.anchorCollapse,
                    anchorSpacing = jobSettings.anchorSpacing,
                    anchorOrder = jobSettings.anchorOrder,
                };
            end
        else
            plateData.jobText = jobText;
            plateData.jobFontFamily = fonts.GetRole(globalSettings, true);
            plateData.jobFontFlags = fonts.GetRoleFlags(globalSettings, true);
            plateData.jobFontSize = textScale.ToTextureFontSize(jobSettings.textSize, jobDefaults.textSize);
            plateData.jobColor = jobSettings.color or jobDefaults.color;
            plateData.jobOutlineEnabled = (entityName == 'Enemy') and ((tonumber(jobSettings.outlineSize) or 0) > 0) or (jobSettings.outlineEnabled == true);
            plateData.jobOutlineColor = jobSettings.outlineColor or jobDefaults.outlineColor;
            plateData.jobOutlineSize = tonumber(jobSettings.outlineSize) or jobDefaults.outlineSize;
            plateData.jobOffsetX = tonumber(jobSettings.offsetX) or 0;
            plateData.jobOffsetY = tonumber(jobSettings.offsetY) or -54;
            plateData.jobAnchorTo = jobSettings.anchorTo or jobDefaults.anchorTo;
            plateData.jobAnchorPoint = jobSettings.anchorPoint or jobDefaults.anchorPoint;
            plateData.jobAnchorCollapse = jobSettings.anchorCollapse;
            plateData.jobAnchorOrder = jobSettings.anchorOrder;
        end
    end

    if ((entityName == 'Enemy' or (entityName == 'PC' and stateName == 'Combat')) and levelSettings ~= nil and levelSettings.enabled == true) then
        local levelText = '72-75';

        plateData.badges = plateData.badges or {};
        plateData.badges[#plateData.badges + 1] = {
            kind = 'level',
            text = levelText,
            offsetX = tonumber(levelSettings.offsetX) or 0,
            offsetY = tonumber(levelSettings.offsetY) or -54,
            fontFamily = fonts.GetRole(globalSettings, true),
            fontFlags = fonts.GetRoleFlags(globalSettings, true),
            fontSize = textScale.ToTextureFontSize(levelSettings.textSize, levelDefaults.textSize),
            textColor = GetPreviewDifficultyColor(levelSettings, levelDefaults),
            textOutlineEnabled = levelSettings.outlineEnabled == true,
            textOutlineColor = GetPreviewDifficultyOutlineColor(levelSettings, levelDefaults),
            textOutlineSize = tonumber(levelSettings.outlineSize) or levelDefaults.outlineSize,
            anchorTo = levelSettings.anchorTo or levelDefaults.anchorTo,
            anchorPoint = levelSettings.anchorPoint or levelDefaults.anchorPoint,
            anchorCollapse = levelSettings.anchorCollapse,
            anchorSpacing = levelSettings.anchorSpacing,
            anchorOrder = levelSettings.anchorOrder,
            backgroundEnabled = false,
        };
    end

    if (entityName == 'Enemy' and idSettings ~= nil and idSettings.enabled == true) then
        local boxSize = tonumber(idSettings.boxSize) or idDefaults.boxSize;

        plateData.badges = plateData.badges or {};
        plateData.badges[#plateData.badges + 1] = {
            kind = 'id',
            text = '32',
            offsetX = tonumber(idSettings.offsetX) or 0,
            offsetY = tonumber(idSettings.offsetY) or 24,
            fontFamily = fonts.GetRole(globalSettings, idSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, idSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(idSettings.textSize, idDefaults.textSize),
            textColor = idSettings.color or idDefaults.color,
            textOutlineEnabled = (tonumber(idSettings.outlineSize) or 0) > 0,
            textOutlineColor = idSettings.outlineColor or idDefaults.outlineColor,
            textOutlineSize = tonumber(idSettings.outlineSize) or idDefaults.outlineSize,
            anchorTo = idSettings.anchorTo or idDefaults.anchorTo,
            anchorPoint = idSettings.anchorPoint or idDefaults.anchorPoint,
            anchorCollapse = idSettings.anchorCollapse,
            anchorSpacing = idSettings.anchorSpacing,
            anchorOrder = idSettings.anchorOrder,
            backgroundEnabled = idSettings.boxEnabled == true,
            backgroundColor = GetPreviewIdBoxColor(idSettings, idDefaults),
            borderColor = idSettings.boxBorderColor or idDefaults.boxBorderColor,
            borderSize = tonumber(idSettings.boxBorderSize) or idDefaults.boxBorderSize,
            paddingX = 0,
            paddingY = 0,
            minWidth = boxSize,
            minHeight = boxSize,
            cornerRadius = tonumber(idSettings.cornerRadius) or idDefaults.cornerRadius,
        };
    end

    if (
        ShouldShowDistancePreview(context, distanceSettings) == true and
        (entityName == 'Enemy' or entityName == 'PC' or entityName == 'NPC' or entityName == 'Object' or entityName == 'NPC/Object') and
        distanceSettings ~= nil
    ) then
        plateData.badges = plateData.badges or {};
        plateData.badges[#plateData.badges + 1] = {
            kind = 'distance',
            text = tostring(distanceSettings.prefix or '') .. '12.4',
            offsetX = tonumber(distanceSettings.offsetX) or distanceDefaults.offsetX,
            offsetY = tonumber(distanceSettings.offsetY) or distanceDefaults.offsetY,
            fontFamily = fonts.GetRole(globalSettings, distanceSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, distanceSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(distanceSettings.textSize, distanceDefaults.textSize),
            textColor = distanceSettings.color or distanceDefaults.color,
            textOutlineEnabled = distanceSettings.outlineEnabled == true,
            textOutlineColor = distanceSettings.outlineColor or distanceDefaults.outlineColor,
            textOutlineSize = tonumber(distanceSettings.outlineSize) or distanceDefaults.outlineSize,
            anchorTo = distanceSettings.anchorTo or distanceDefaults.anchorTo,
            anchorPoint = distanceSettings.anchorPoint or distanceDefaults.anchorPoint,
            anchorCollapse = distanceSettings.anchorCollapse,
            anchorSpacing = distanceSettings.anchorSpacing,
            anchorOrder = distanceSettings.anchorOrder,
            backgroundEnabled = false,
        };
    end

    if (entityName == 'NPC' or entityName == 'NPC/Object') then
        local iconTextureId = npcObjectInfo.GetTextureId(previewName, 'NPC', { ignoreZone = true });

        if (iconSettings ~= nil and iconSettings.enabled == true and iconTextureId ~= nil) then
            plateData.icons = plateData.icons or {};
            plateData.icons[#plateData.icons + 1] = {
                kind = 'npc_object_icon',
                textureId = iconTextureId,
                size = tonumber(iconSettings.iconSize) or npcObjectIconDefaults.iconSize,
                offsetX = tonumber(iconSettings.offsetX) or npcObjectIconDefaults.offsetX,
                offsetY = tonumber(iconSettings.offsetY) or npcObjectIconDefaults.offsetY,
                anchorTo = iconSettings.anchorTo or npcObjectIconDefaults.anchorTo,
                anchorPoint = iconSettings.anchorPoint or npcObjectIconDefaults.anchorPoint,
                anchorCollapse = iconSettings.anchorCollapse,
                anchorSpacing = iconSettings.anchorSpacing,
                anchorOrder = iconSettings.anchorOrder,
            };
        end
    elseif (entityName == 'Object') then
        local iconTextureId = npcObjectInfo.GetTextureId(previewName, 'Object', { ignoreZone = true });

        if (iconSettings ~= nil and iconSettings.enabled == true and iconTextureId ~= nil) then
            plateData.icons = plateData.icons or {};
            plateData.icons[#plateData.icons + 1] = {
                kind = 'npc_object_icon',
                textureId = iconTextureId,
                size = tonumber(iconSettings.iconSize) or npcObjectIconDefaults.iconSize,
                offsetX = tonumber(iconSettings.offsetX) or npcObjectIconDefaults.offsetX,
                offsetY = tonumber(iconSettings.offsetY) or npcObjectIconDefaults.offsetY,
                anchorTo = iconSettings.anchorTo or npcObjectIconDefaults.anchorTo,
                anchorPoint = iconSettings.anchorPoint or npcObjectIconDefaults.anchorPoint,
                anchorCollapse = iconSettings.anchorCollapse,
                anchorSpacing = iconSettings.anchorSpacing,
                anchorOrder = iconSettings.anchorOrder,
            };
        end
    end

    if (
        (entityName == 'NPC' or entityName == 'Object' or entityName == 'NPC/Object') and
        typeLineSettings ~= nil and
        typeLineSettings.enabled == true
    ) then
        local previewTypeText = npcObjectInfo.GetType(previewName, entityName, { ignoreZone = true }) or ((entityName == 'Object') and 'Mining Point' or 'Weekly Hunt');

        plateData.texts = plateData.texts or {};
        plateData.texts[#plateData.texts + 1] = {
            kind = 'type',
            text = previewTypeText,
            align = 'center',
            offsetX = tonumber(typeLineSettings.offsetX) or typeLineDefaults.offsetX,
            offsetY = tonumber(typeLineSettings.offsetY) or typeLineDefaults.offsetY,
            anchorTo = typeLineSettings.anchorTo or typeLineDefaults.anchorTo,
            anchorPoint = typeLineSettings.anchorPoint or typeLineDefaults.anchorPoint,
            anchorCollapse = typeLineSettings.anchorCollapse,
            anchorSpacing = typeLineSettings.anchorSpacing,
            anchorOrder = typeLineSettings.anchorOrder,
            fontFamily = fonts.GetRole(globalSettings, typeLineSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, typeLineSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(typeLineSettings.textSize, typeLineDefaults.textSize),
            color = typeLineSettings.color or typeLineDefaults.color,
            outlineEnabled = typeLineSettings.outlineEnabled == true,
            outlineColor = typeLineSettings.outlineColor or typeLineDefaults.outlineColor,
            outlineSize = tonumber(typeLineSettings.outlineSize) or typeLineDefaults.outlineSize,
        };
    end

    return plateData;
end

local function GetContentRegionAvail()
    if (imgui.GetContentRegionAvail == nil) then
        return 360, 180;
    end

    local availA, availB = imgui.GetContentRegionAvail();

    if (type(availA) == 'table') then
        return tonumber(availA.x or availA[1]) or 360, tonumber(availA.y or availA[2]) or 180;
    end

    return tonumber(availA) or 360, tonumber(availB) or 180;
end

local function GetMousePos()
    if (imgui.GetMousePos == nil) then
        return nil, nil;
    end

    local posA, posB = imgui.GetMousePos();

    if (type(posA) == 'table') then
        return tonumber(posA.x or posA[1]), tonumber(posA.y or posA[2]);
    end

    return tonumber(posA), tonumber(posB);
end

local function WasPreviewClicked()
    if (previewControlClickConsumed == true) then
        return false;
    end

    if (imgui.IsMouseClicked ~= nil) then
        return imgui.IsMouseClicked(0) == true;
    end

    if (imgui.IsMouseReleased ~= nil) then
        return imgui.IsMouseReleased(0) == true;
    end

    return false;
end

local function GetPreviewElementAtMouse(plate, textureWidth, textureHeight, zoomX, zoomY, zoomWidth, zoomHeight)
    local mouseX, mouseY = GetMousePos();

    if (mouseX == nil or mouseY == nil) then
        return nil;
    end

    local rects = plate._elementRects or canvasTexture.GetElementRects(plate);
    local sourceW = math.max(1, tonumber(textureWidth) or 1024);
    local sourceH = math.max(1, tonumber(textureHeight) or 512);

    for index = #rects, 1, -1 do
        local rect = rects[index];
        if (rect.anchorOnly ~= true) then
            local x1 = zoomX + ((tonumber(rect.x1) or 0) / sourceW) * zoomWidth;
            local y1 = zoomY + ((tonumber(rect.y1) or 0) / sourceH) * zoomHeight;
            local x2 = zoomX + ((tonumber(rect.x2) or 0) / sourceW) * zoomWidth;
            local y2 = zoomY + ((tonumber(rect.y2) or 0) / sourceH) * zoomHeight;

            if (mouseX >= x1 and mouseX <= x2 and mouseY >= y1 and mouseY <= y2) then
                return tostring(rect.kind or '');
            end
        end
    end

    return nil;
end

local function HandlePreviewElementClick(plate, textureWidth, textureHeight, zoomX, zoomY, zoomWidth, zoomHeight, context)
    if (context == nil or type(context.onElementClick) ~= 'function' or WasPreviewClicked() ~= true) then
        return;
    end

    local kind = GetPreviewElementAtMouse(plate, textureWidth, textureHeight, zoomX, zoomY, zoomWidth, zoomHeight);

    if (kind ~= nil) then
        context.onElementClick(kind, context);
    end
end

local function HandlePreviewElementDrag(plate, textureWidth, textureHeight, zoomX, zoomY, zoomWidth, zoomHeight, context)
    if (
        dragEnabled ~= true or
        context == nil or
        type(context.onElementDrag) ~= 'function' or
        imgui.GetMouseDragDelta == nil or
        imgui.IsMouseDown == nil
    ) then
        activeDragKind = nil;
        return;
    end

    if (imgui.IsMouseDown(0) ~= true) then
        activeDragKind = nil;
        return;
    end

    if (activeDragKind == nil) then
        activeDragKind = GetPreviewElementAtMouse(plate, textureWidth, textureHeight, zoomX, zoomY, zoomWidth, zoomHeight);
    end

    if (activeDragKind == nil) then
        return;
    end

    local dragA, dragB = imgui.GetMouseDragDelta(0);
    local dragX, dragY = 0, 0;

    if (type(dragA) == 'table') then
        dragX = tonumber(dragA.x or dragA[1]) or 0;
        dragY = tonumber(dragA.y or dragA[2]) or 0;
    else
        dragX = tonumber(dragA) or 0;
        dragY = tonumber(dragB) or 0;
    end

    if (math.abs(dragX) < 0.5 and math.abs(dragY) < 0.5) then
        return;
    end

    local sourceW = math.max(1, tonumber(textureWidth) or 1024);
    local sourceH = math.max(1, tonumber(textureHeight) or 512);
    local dx = dragX * (sourceW / math.max(1, zoomWidth));
    local dy = dragY * (sourceH / math.max(1, zoomHeight));

    context.onElementDrag(activeDragKind, dx, dy, context);

    if (imgui.ResetMouseDragDelta ~= nil) then
        imgui.ResetMouseDragDelta(0);
    end
end

local function DrawPreviewInfoOverlay(drawList, x, y)
    local size = 28;
    local pad = 8;
    local iconX = x + pad;
    local iconY = y + pad;
    local textureId = LoadPreviewInfoIcon();

    if (textureId ~= nil and drawList ~= nil and drawList.AddImage ~= nil) then
        drawList:AddImage(textureId, { iconX, iconY }, { iconX + size, iconY + size }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
    elseif (drawList ~= nil and drawList.AddText ~= nil) then
        drawList:AddText({ iconX, iconY }, 0xFFFFFFFF, '(?)');
    end

    local mouseX, mouseY = GetMousePos();

    if (mouseX == nil or mouseY == nil) then
        return;
    end

    if (mouseX < iconX or mouseX > (iconX + size) or mouseY < iconY or mouseY > (iconY + size)) then
        return;
    end

    local text = 'Click any element in the preview window to open its settings.';

    if (imgui.BeginTooltip ~= nil and imgui.EndTooltip ~= nil) then
        imgui.BeginTooltip();

        if (imgui.PushTextWrapPos ~= nil) then
            imgui.PushTextWrapPos(360);
        end

        if (imgui.TextWrapped ~= nil) then
            imgui.TextWrapped(text);
        else
            imgui.Text(text);
        end

        if (imgui.PopTextWrapPos ~= nil) then
            imgui.PopTextWrapPos();
        end

        imgui.EndTooltip();
    elseif (imgui.SetTooltip ~= nil) then
        imgui.SetTooltip(text);
    end
end

local function ShowPreviewTooltip(text)
    if (imgui.BeginTooltip ~= nil and imgui.EndTooltip ~= nil) then
        imgui.BeginTooltip();

        if (imgui.PushTextWrapPos ~= nil) then
            imgui.PushTextWrapPos(360);
        end

        if (imgui.TextWrapped ~= nil) then
            imgui.TextWrapped(tostring(text or ''));
        else
            imgui.Text(tostring(text or ''));
        end

        if (imgui.PopTextWrapPos ~= nil) then
            imgui.PopTextWrapPos();
        end

        imgui.EndTooltip();
    elseif (imgui.SetTooltip ~= nil) then
        imgui.SetTooltip(tostring(text or ''));
    end
end

local function DrawPreviewCornerIconButton(drawList, id, textureId, x, y, size, tint, tooltip)
    if (textureId ~= nil and drawList ~= nil and drawList.AddImage ~= nil) then
        drawList:AddImage(textureId, { x, y }, { x + size, y + size }, { 0, 0 }, { 1, 1 }, tint or 0xFFFFFFFF);
    elseif (drawList ~= nil and drawList.AddRectFilled ~= nil) then
        drawList:AddRectFilled({ x, y }, { x + size, y + size }, 0xAA20242C);
    end

    if (imgui.SetCursorScreenPos == nil or imgui.InvisibleButton == nil) then
        return false;
    end

    imgui.SetCursorScreenPos({ x, y });
    local clicked = imgui.InvisibleButton(id, { size, size }) == true;

    if (imgui.IsItemHovered ~= nil and imgui.IsItemHovered() == true) then
        ShowPreviewTooltip(tooltip);
    end

    if (clicked == true) then
        previewControlClickConsumed = true;
    end

    return clicked;
end

local function DrawPreviewCornerControls(drawList, x, y, previewWidth, previewHeight)
    local size = 32;
    local pad = 10;
    local gap = 6;
    local bottomY = y + previewHeight - size - pad;
    local zoomed = selectedZoom == '2x';
    local idleTint = selectedBackground == 'Light' and 0xFF000000 or 0xFFFFFFFF;
    local idleOffTint = selectedBackground == 'Light' and 0x99000000 or 0x99FFFFFF;
    local enabledTint = 0xFF00B850;
    local zoomIcon = zoomed == true and 'zoom-out.png' or 'zoom-in.png';
    local zoomText = zoomed == true
        and 'Zoom out to 1x preview.'
        or 'Zoom in to 2x preview.';
    local dragText = dragEnabled == true
        and 'Drag enabled. Click to disable preview dragging.'
        or 'Drag disabled. Click to enable preview dragging.';
    local backgroundIcon = string.lower(tostring(selectedBackground or 'Light')) .. '.png';
    local backgroundText = 'Preview background: ' .. tostring(selectedBackground or 'Light') .. '. Click to cycle Light, Mid, Dark.';

    if (DrawPreviewCornerIconButton(
        drawList,
        '##preview_zoom_corner',
        LoadPreviewUiIcon(zoomIcon),
        x + pad,
        bottomY,
        size,
        idleTint,
        zoomText
    ) == true) then
        selectedZoom = zoomed == true and '1x' or '2x';
    end

    if (DrawPreviewCornerIconButton(
        drawList,
        '##preview_background_cycle',
        LoadPreviewUiIcon(backgroundIcon),
        x + pad + size + gap,
        bottomY,
        size,
        idleTint,
        backgroundText
    ) == true) then
        if (selectedBackground == 'Light') then
            selectedBackground = 'Mid';
        elseif (selectedBackground == 'Mid') then
            selectedBackground = 'Dark';
        else
            selectedBackground = 'Light';
        end
    end

    if (DrawPreviewCornerIconButton(
        drawList,
        '##preview_drag_corner',
        LoadPreviewUiIcon('drag.png'),
        x + previewWidth - size - pad,
        bottomY,
        size,
        dragEnabled == true and enabledTint or idleOffTint,
        dragText
    ) == true) then
        dragEnabled = dragEnabled ~= true;
        activeDragKind = nil;
    end
end

local function DrawEnemyPreviewNameModeControl(drawList, x, y, previewWidth)
    local size = 32;
    local pad = 10;
    local longMode = enemyPreviewNameMode ~= 'Short';
    local idleTint = selectedBackground == 'Light' and 0xFF000000 or 0xFFFFFFFF;
    local iconName = longMode == true and 'long.png' or 'short.png';
    local tooltip = longMode == true
        and 'Enemy preview name: long. Click to use short name.'
        or 'Enemy preview name: short. Click to use long name.';

    if (DrawPreviewCornerIconButton(
        drawList,
        '##preview_enemy_name_mode',
        LoadPreviewUiIcon(iconName),
        x + previewWidth - size - pad,
        y + pad,
        size,
        idleTint,
        tooltip
    ) == true) then
        enemyPreviewNameMode = longMode == true and 'Short' or 'Long';
    end
end

local function DrawLuopanPreviewActor(drawList, x, y, previewWidth, previewHeight)
    local textureId = LoadLuopanPreviewTexture();

    if (textureId == nil or drawList == nil or drawList.AddImage == nil) then
        return;
    end

    local size = math.max(58, math.min(previewWidth * 0.24, previewHeight * 0.42));
    local centerX = x + (previewWidth * 0.5);
    local centerY = y + (previewHeight * 0.85);
    local left = centerX - (size * 0.5);
    local top = centerY - (size * 0.5);

    drawList:AddImage(textureId, { left, top }, { left + size, top + size }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
end

local function DrawSpiritPreviewActor(drawList, x, y, previewWidth, previewHeight)
    local textureId = LoadSpiritPreviewTexture();

    if (textureId == nil or drawList == nil or drawList.AddImage == nil) then
        return;
    end

    local size = math.max(52, math.min(previewWidth * 0.20, previewHeight * 0.34));
    local centerX = x + (previewWidth * 0.50);
    local centerY = y + (previewHeight * 0.72);
    local left = centerX - (size * 0.5);
    local top = centerY - (size * 0.5);

    drawList:AddImage(textureId, { left, top }, { left + size, top + size }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
end

local function RemoveBadgeKind(plateData, kind)
    if (plateData == nil or plateData.badges == nil) then
        return;
    end

    local keep = {};

    for _, badge in ipairs(plateData.badges) do
        if (badge.kind ~= kind) then
            keep[#keep + 1] = badge;
        end
    end

    plateData.badges = keep;
end

local function RemovePeerReplacedNormalElements(plateData)
    if (plateData == nil) then
        return;
    end

    plateData.jobText = '';
    RemoveBadgeKind(plateData, 'level');
    RemoveBadgeKind(plateData, 'id');
    RemoveBadgeKind(plateData, 'distance');
end

local function AddPeerPreviewText(plateData, text, x, y, globalSettings, peerSettings, prefix, kind)
    if (text == nil or tostring(text) == '') then
        return;
    end

    plateData.texts = plateData.texts or {};
    plateData.texts[#plateData.texts + 1] = {
        text = tostring(text),
        offsetX = tonumber(x) or 0,
        offsetY = tonumber(y) or 0,
        fontFamily = fonts.GetRole(globalSettings, true),
        fontFlags = fonts.GetRoleFlags(globalSettings, true),
        fontSize = textScale.ToTextureFontSize(peerSettings[prefix .. 'FontSize'], 12),
        color = peerSettings[prefix .. 'Color'] or { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = (tonumber(peerSettings[prefix .. 'OutlineSize']) or 0) > 0,
        outlineColor = peerSettings[prefix .. 'OutlineColor'] or { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = tonumber(peerSettings[prefix .. 'OutlineSize']) or 2,
        kind = kind or ('peer' .. prefix),
    };
end

local function AddPeerPreviewIconRow(plateData, iconNames, peerSettings, prefix)
    if (iconNames == nil or #iconNames == 0) then
        return;
    end

    plateData.icons = plateData.icons or {};

    local iconStyle = SanitizePeerIconStyle(peerSettings.iconStyle);
    local iconSize = math.max(6, math.min(256, tonumber(peerSettings[prefix .. 'IconSize']) or tonumber(peerSettings.iconSize) or 18));
    local x = tonumber(peerSettings[prefix .. 'OffsetX']) or tonumber(peerSettings.iconOffsetX) or -190;
    local y = tonumber(peerSettings[prefix .. 'OffsetY']) or tonumber(peerSettings.iconOffsetY) or -16;
    local maxX = x + 395;

    for _, iconName in ipairs(iconNames) do
        if (x > maxX) then break; end

        local textureId = LoadPeerIcon(iconName, iconStyle);

        if (textureId ~= nil) then
            plateData.icons[#plateData.icons + 1] = {
                kind = ({
                    aggro = 'peerAggro',
                    detection = 'peerDetection',
                    immunity = 'peerImmunity',
                    modifier = 'peerModifiers',
                })[prefix] or 'peer',
                textureId = textureId,
                size = iconSize,
                offsetX = x,
                offsetY = y,
            };

            x = x + iconSize + 3;
        end
    end
end

local function ApplyPeerPreviewHpBar(plateData, peerSettings, hpPercent, globalSettings)
    if (peerSettings.showHpBar == false) then
        plateData.hpBar.enabled = false;
        return;
    end

    plateData.hpBar.enabled = true;
    plateData.hpBar.width = tonumber(peerSettings.hpBarWidth) or 437;
    plateData.hpBar.height = tonumber(peerSettings.hpBarHeight) or 16;
    plateData.hpBar.offsetX = tonumber(peerSettings.hpBarOffsetX) or 0;
    plateData.hpBar.offsetY = tonumber(peerSettings.hpBarOffsetY) or 0;
    plateData.hpBar.color = peerSettings.hpBarColor or { 0.0, 0.75, 0.16, 1.0 };
    plateData.hpBar.backgroundColor = peerSettings.hpBarBackgroundColor or { 0.05, 0.05, 0.05, 0.85 };
    plateData.hpBar.borderColor = peerSettings.hpBarBorderColor or { 0.0, 0.0, 0.0, 1.0 };
    plateData.hpBar.borderSize = tonumber(peerSettings.hpBarBorderSize) or 0;
    plateData.hpBar.text = (peerSettings.showHpPercent ~= false) and (tostring(math.floor((tonumber(hpPercent) or 0) + 0.5)) .. '%') or '';
    plateData.hpBar.textOffsetX = tonumber(peerSettings.hpPercentOffsetX) or 0;
    plateData.hpBar.textOffsetY = tonumber(peerSettings.hpPercentOffsetY) or 0;
    plateData.hpBar.fontFamily = fonts.GetRole(globalSettings, true);
    plateData.hpBar.fontFlags = fonts.GetRoleFlags(globalSettings, true);
    plateData.hpBar.fontSize = textScale.ToTextureFontSize(peerSettings.hpPercentFontSize, 12);
    plateData.hpBar.textColor = peerSettings.hpPercentColor or { 1.0, 1.0, 1.0, 1.0 };
    plateData.hpBar.textOutlineEnabled = (tonumber(peerSettings.hpPercentOutlineSize) or 0) > 0;
    plateData.hpBar.textOutlineColor = peerSettings.hpPercentOutlineColor or { 0.0, 0.0, 0.0, 1.0 };
    plateData.hpBar.textOutlineSize = tonumber(peerSettings.hpPercentOutlineSize) or 2;
end

local function ApplyPeerPreviewBackground(plateData, peerSettings)
    plateData.background = plateData.background or {};
    plateData.background.enabled = peerSettings.showBackground == true;

    if (plateData.background.enabled ~= true) then
        return;
    end

    plateData.background.width = tonumber(peerSettings.backgroundWidth) or 460;
    plateData.background.height = tonumber(peerSettings.backgroundHeight) or 72;
    plateData.background.offsetX = tonumber(peerSettings.backgroundOffsetX) or 0;
    plateData.background.offsetY = tonumber(peerSettings.backgroundOffsetY) or 0;
    local color = peerSettings.backgroundColor or { 0.0, 0.0, 0.0, 0.45 };
    plateData.background.color = {
        tonumber(color[1]) or 0.0,
        tonumber(color[2]) or 0.0,
        tonumber(color[3]) or 0.0,
        math.max(0.0, math.min(1.0, (tonumber(peerSettings.backgroundOpacity) or ((tonumber(color[4]) or 0.45) * 100)) / 100)),
    };
    plateData.background.borderColor = peerSettings.backgroundBorderColor or { 0.0, 0.0, 0.0, 1.0 };
    plateData.background.borderSize = tonumber(peerSettings.backgroundBorderSize) or 0;
end

local function ApplyPeerPreviewName(plateData, peerSettings, globalSettings)
    if (peerSettings.showName == false) then
        plateData.name = '';
        return;
    end

    plateData.nameFontFamily = fonts.GetRole(globalSettings, false);
    plateData.nameFontFlags = fonts.GetRoleFlags(globalSettings, false);
    plateData.nameFontSize = textScale.ToNameTextureFontSize(peerSettings.nameFontSize, 32);
    plateData.nameColor = peerSettings.nameColor or { 1.0, 1.0, 1.0, 1.0 };
    plateData.nameOutlineEnabled = (tonumber(peerSettings.nameOutlineSize) or 0) > 0;
    plateData.nameOutlineColor = peerSettings.nameOutlineColor or { 0.0, 0.0, 0.0, 1.0 };
    plateData.nameOutlineSize = tonumber(peerSettings.nameOutlineSize) or 3;
    plateData.nameOffsetX = tonumber(peerSettings.nameOffsetX) or 0;
    plateData.nameOffsetY = tonumber(peerSettings.nameOffsetY) or -54;
end

local function AddPeerPreviewId(plateData, peerSettings, globalSettings)
    if (peerSettings.showId ~= true) then
        return;
    end

    local boxSize = tonumber(peerSettings.idBoxSize) or 18;

    plateData.badges = plateData.badges or {};
    plateData.badges[#plateData.badges + 1] = {
        kind = 'peerId',
        text = '32',
        offsetX = tonumber(peerSettings.idOffsetX) or 0,
        offsetY = tonumber(peerSettings.idOffsetY) or 24,
        fontFamily = fonts.GetRole(globalSettings, true),
        fontFlags = fonts.GetRoleFlags(globalSettings, true),
        fontSize = textScale.ToTextureFontSize(peerSettings.idFontSize, 7),
        textColor = peerSettings.idColor or { 0.65, 0.90, 1.0, 1.0 },
        textOutlineEnabled = (tonumber(peerSettings.idOutlineSize) or 0) > 0,
        textOutlineColor = peerSettings.idOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
        textOutlineSize = tonumber(peerSettings.idOutlineSize) or 2,
        backgroundEnabled = peerSettings.idBoxEnabled == true,
        backgroundColor = peerSettings.idBoxColor or { 0.45, 0.15, 0.15, 0.90 },
        borderColor = peerSettings.idBoxBorderColor or { 1.0, 1.0, 1.0, 1.0 },
        borderSize = tonumber(peerSettings.idBoxBorderSize) or 0,
        paddingX = 0,
        paddingY = 0,
        minWidth = boxSize,
        minHeight = boxSize,
        cornerRadius = tonumber(peerSettings.idCornerRadius) or 4,
    };
end

AddPeerPreview = function(plateData, globalSettings)
    local peerSettings = globalSettings.peer or {};

    RemovePeerReplacedNormalElements(plateData);
    ApplyPeerPreviewBackground(plateData, peerSettings);
    ApplyPeerPreviewName(plateData, peerSettings, globalSettings);
    ApplyPeerPreviewHpBar(plateData, peerSettings, plateData.hp, globalSettings);
    AddPeerPreviewId(plateData, peerSettings, globalSettings);

    if (peerSettings.showJob ~= false) then
        if (tostring(peerSettings.jobDisplay or 'Text') == 'Icon') then
            local textureId = jobIconTextures.GetTextureId('BLM', peerSettings.jobIconTheme);

            if (textureId ~= nil) then
                plateData.icons = plateData.icons or {};
                plateData.icons[#plateData.icons + 1] = {
                    kind = 'peerJob',
                    textureId = textureId,
                    size = math.max(6, math.min(256, tonumber(peerSettings.jobIconSize) or 18)),
                    offsetX = tonumber(peerSettings.jobOffsetX) or -190,
                    offsetY = tonumber(peerSettings.jobOffsetY) or -16,
                };
            end
        else
            AddPeerPreviewText(
                plateData,
                'BLM',
                tonumber(peerSettings.jobOffsetX) or -190,
                tonumber(peerSettings.jobOffsetY) or -16,
                globalSettings,
                peerSettings,
                'job',
                'peerJob'
            );
        end
    end

    if (peerSettings.showLevel ~= false) then
        local originalLevelColor = peerSettings.levelColor;

        if (peerSettings.levelDifficultyColorsEnabled == true) then
            peerSettings.levelColor = peerSettings.levelTColor or peerSettings.levelColor;
        end

        AddPeerPreviewText(
            plateData,
            '70-73',
            tonumber(peerSettings.levelOffsetX) or -145,
            tonumber(peerSettings.levelOffsetY) or -16,
            globalSettings,
            peerSettings,
            'level',
            'peerLevel'
        );

        peerSettings.levelColor = originalLevelColor;
    end

    if (peerSettings.showRange ~= false) then
        AddPeerPreviewText(
            plateData,
            '44.9',
            tonumber(peerSettings.rangeOffsetX) or 92,
            tonumber(peerSettings.rangeOffsetY) or -54,
            globalSettings,
            peerSettings,
            'range',
            'peerRange'
        );
    end

    if (peerSettings.showAggro ~= false) then
        AddPeerPreviewIconRow(plateData, T{ 'AggroNQ' }, peerSettings, 'aggro');
        AddPeerPreviewText(
            plateData,
            'Aggro',
            (tonumber(peerSettings.aggroOffsetX) or -95) + math.max(6, math.min(256, tonumber(peerSettings.aggroIconSize) or tonumber(peerSettings.iconSize) or 18)) + 4,
            tonumber(peerSettings.aggroOffsetY) or -16,
            globalSettings,
            peerSettings,
            'aggro',
            'peerAggroText'
        );
    end

    if (peerSettings.showDetection ~= false) then
        AddPeerPreviewIconRow(plateData, T{ 'Sight', 'Sound', 'Magic', 'Link' }, peerSettings, 'detection');
    end

    if (peerSettings.showImmunities ~= false) then
        AddPeerPreviewIconRow(plateData, T{ 'ImmuneSleep', 'ImmuneSilence', 'ImmuneGravity' }, peerSettings, 'immunity');
    end

    if (peerSettings.showModifiers ~= false) then
        plateData.icons = plateData.icons or {};

        local iconStyle = SanitizePeerIconStyle(peerSettings.iconStyle);
        local iconSize = math.max(6, math.min(256, tonumber(peerSettings.modifierIconSize) or tonumber(peerSettings.iconSize) or 18));
        local x = tonumber(peerSettings.modifierOffsetX) or 120;
        local y = tonumber(peerSettings.modifierOffsetY) or -16;
        local modifierIcons = T{
            { icon = 'Slashing', value = '-50%' },
            { icon = 'Fire', value = '+25%' },
        };

        for _, modifier in ipairs(modifierIcons) do
            local textureId = LoadPeerIcon(modifier.icon, iconStyle);

            if (textureId ~= nil) then
                plateData.icons[#plateData.icons + 1] = {
                    kind = 'peerModifiers',
                    textureId = textureId,
                    size = iconSize,
                    offsetX = x,
                    offsetY = y,
                };

                if (peerSettings.showModifierValues ~= false) then
                    plateData.texts = plateData.texts or {};
                    plateData.texts[#plateData.texts + 1] = {
                        text = modifier.value,
                        offsetX = x,
                        offsetY = y + (iconSize * 0.5) + 1,
                        fontFamily = fonts.GetRole(globalSettings, true),
                        fontFlags = fonts.GetRoleFlags(globalSettings, true),
                        fontSize = textScale.ToTextureFontSize(peerSettings.modifierValueFontSize, 12),
                        color = peerSettings.modifierValueColor or { 1.0, 1.0, 1.0, 1.0 },
                        outlineEnabled = (tonumber(peerSettings.modifierValueOutlineSize) or 0) > 0,
                        outlineColor = peerSettings.modifierValueOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
                        outlineSize = tonumber(peerSettings.modifierValueOutlineSize) or 2,
                        kind = 'peerModifiers',
                        align = 'center',
                    };
                end

                x = x + iconSize + 3;
            end
        end
    end
end

local function ColorToU32(color, fallback)
    local c = color or fallback or { 1.0, 1.0, 1.0, 1.0 };
    local r = math.floor((tonumber(c[1]) or 1.0) * 255 + 0.5);
    local g = math.floor((tonumber(c[2]) or 1.0) * 255 + 0.5);
    local b = math.floor((tonumber(c[3]) or 1.0) * 255 + 0.5);
    local a = math.floor((tonumber(c[4]) or 1.0) * 255 + 0.5);

    if (r < 0) then r = 0 elseif (r > 255) then r = 255 end
    if (g < 0) then g = 0 elseif (g > 255) then g = 255 end
    if (b < 0) then b = 0 elseif (b > 255) then b = 255 end
    if (a < 0) then a = 0 elseif (a > 255) then a = 255 end

    return (a * 0x1000000) + (b * 0x10000) + (g * 0x100) + r;
end

local function QuickMenuColorLuma(color)
    color = color or {};

    return
        (0.2126 * (tonumber(color[1]) or 0)) +
        (0.7152 * (tonumber(color[2]) or 0)) +
        (0.0722 * (tonumber(color[3]) or 0));
end

local function GetQuickMenuReadableTextColor(menu)
    local textColor = menu ~= nil and menu.textColor or nil;
    local backgroundColor = menu ~= nil and menu.backgroundColor or nil;

    if (type(textColor) ~= 'table') then
        return { 0.92, 0.92, 0.90, 1.0 };
    end

    local textAlpha = tonumber(textColor[4]) or 1.0;
    local bgAlpha = tonumber(backgroundColor ~= nil and backgroundColor[4]) or 1.0;
    local contrast = math.abs(QuickMenuColorLuma(textColor) - QuickMenuColorLuma(backgroundColor));

    if (bgAlpha > 0.35 and (textAlpha < 0.65 or contrast < 0.28)) then
        if (QuickMenuColorLuma(backgroundColor) < 0.5) then
            return { 0.92, 0.92, 0.90, 1.0 };
        end

        return { 0.08, 0.08, 0.10, 1.0 };
    end

    return textColor;
end

local function GetQuickMenuPreviewRows(entityName, menu)
    local entity = tostring(entityName or '');
    menu = menu or {};
    menu.pc = menu.pc or {};
    menu.self = menu.self or {};
    menu.trust = menu.trust or {};
    menu.npc = menu.npc or {};
    menu.presets = menu.presets or {};
    menu.presets.entries = menu.presets.entries or {};
    if (menu.presets.iconTheme == nil) then menu.presets.iconTheme = 'FFXI'; end

    if (entity == 'Self') then
        local rows = {};

        if (menu.self.acceptInvite == true) then rows[#rows + 1] = { 'Accept Invite', 'accept-invite.png' }; end
        if (menu.self.declineInvite == true) then rows[#rows + 1] = { 'Decline Invite', 'decline-invite.png' }; end
        if (menu.self.leaveParty == true) then rows[#rows + 1] = { 'Leave Party', 'LeaveParty.png' }; end
        if (menu.self.leaveAlliance == true) then rows[#rows + 1] = { 'Leave Alliance', 'LeaveAlliance.png' }; end
        if (menu.self.cancelPartyRequest == true) then rows[#rows + 1] = { 'Cancel Party Request', 'cancel-party-request.png' }; end
        if (menu.self.aceTownMog == true) then rows[#rows + 1] = { 'Job Change', 'catseye.png' }; end
        if (menu.self.mount == true) then rows[#rows + 1] = { 'Mount/Dismount', 'mount.png' }; end
        if (menu.self.ignoreTrust == true) then rows[#rows + 1] = { 'Ignore Other Trusts', 'ignore-trust-on.png' }; end
        if (menu.self.hideTrust == true) then rows[#rows + 1] = { 'Hide Other Trusts', 'hide-other-trusts-on.png' }; end
        if (menu.self.emoteTrust == true) then rows[#rows + 1] = { 'Emote Trust', 'emote-trusts-on.png' }; end

        return 'Libra', 'Player.png', rows;
    end

    if (entity == 'Trust') then
        local rows = {};

        if (menu.trust.dismiss == true) then rows[#rows + 1] = { 'Dismiss This Trust', 'DismissTrust.png' }; end
        if (menu.trust.dismissAll == true) then rows[#rows + 1] = { 'Dismiss All Trusts', 'DismissAllTrusts.png' }; end

        return 'Curilla', 'Player.png', rows;
    end

    if (entity == 'NPC' or entity == 'Object') then
        local rows = {};
        local presetRows = {};

        if (entity == 'NPC') then
            for _, entry in ipairs(menu.presets.entries) do
                local mainJob = tostring(entry.mainJob or 'None');
                local subJob = tostring(entry.subJob or 'None');
                local lockstyleSet = math.max(0, math.min(999, math.floor((tonumber(entry.lockstyleSet) or 0) + 0.5)));
                local macroBook = math.max(0, math.min(20, math.floor((tonumber(entry.macroBook) or 0) + 0.5)));
                local macroPage = math.max(0, math.min(10, math.floor((tonumber(entry.macroPage) or 0) + 0.5)));

                if (mainJob ~= 'None' and subJob ~= 'None' and mainJob ~= subJob) then
                    presetRows[#presetRows + 1] = {
                        mainJob .. '/' .. subJob .. (lockstyleSet > 0 and ('  LS ' .. string.format('%03d', lockstyleSet)) or '') .. ((macroBook > 0 or macroPage > 0) and ('  M ' .. tostring(macroBook) .. '/' .. tostring(macroPage)) or ''),
                        nil,
                        jobIconTextures.GetTextureId(mainJob, menu.presets.iconTheme),
                    };
                end
            end
        end

        local hideInfoForJobPresets = entity == 'NPC' and #presetRows > 0 and menu.presets.hideInfo == true;
        local isJobPresetPreview = entity == 'NPC' and #presetRows > 0;

        if (hideInfoForJobPresets ~= true and menu.npc.showType == true) then
            rows[#rows + 1] = {
                (entity == 'Object') and 'Mining Point' or (isJobPresetPreview == true and 'MHMU worker' or 'Weekly Hunt'),
                nil,
                nil,
                kind = 'text',
            };
        end

        if (hideInfoForJobPresets ~= true and menu.npc.showInfo == true) then
            if (entity == 'Object') then
                rows[#rows + 1] = { 'Gathering point info...', nil, nil, kind = 'text' };
            else
                local sampleInfo = {
                    { 'Starts Quests:', 'header' },
                    { 'Mandragora-Mad', 'link', true },
                };

                for _, line in ipairs(sampleInfo) do
                    rows[#rows + 1] = {
                        line[1],
                        nil,
                        nil,
                        kind = line[2],
                        bullet = line[3] == true,
                    };
                end
            end
        end

        if (hideInfoForJobPresets ~= true and menu.npc.openLink == true and #presetRows == 0) then
            rows[#rows + 1] = { 'Open Wiki Page', 'catseye.png' };
        end

        for _, row in ipairs(presetRows) do
            rows[#rows + 1] = row;
        end

        return (entity == 'Object') and 'Mining Point' or (isJobPresetPreview == true and 'Moogle' or 'Hunter'), nil, rows;
    end

    local rows = {};

    if (menu.pc.examine == true) then rows[#rows + 1] = { 'Examine', 'Examine.png' }; end
    if (menu.pc.catseyeProfile == true) then rows[#rows + 1] = { 'Open Catseye Profile', 'catseye.png' }; end
    if (menu.pc.follow == true) then rows[#rows + 1] = { 'Follow', 'Follow.png' }; end
    if (menu.pc.inviteToParty == true) then rows[#rows + 1] = { 'Invite to Party', 'InviteToParty.png' }; end
    if (menu.pc.requestJoinParty == true) then rows[#rows + 1] = { 'Request to Join Party', 'request-to-join-party.png' }; end
    if (menu.pc.invitePartyToAlliance == true) then rows[#rows + 1] = { 'Invite Party to Alliance', 'InviteToParty.png' }; end
    if (menu.pc.passPartyLeader == true) then rows[#rows + 1] = { 'Pass Party Leader', 'Player.png' }; end
    if (menu.pc.passAllianceLeader == true) then rows[#rows + 1] = { 'Pass Alliance Leader', 'Player.png' }; end
    if (menu.pc.blacklist == true) then rows[#rows + 1] = { 'Add to blacklist', 'blacklist.png' }; end

    return 'Libranya', 'Player.png', rows;
end

local function DrawQuickMenuPreview(drawList, x, y, previewWidth, previewHeight, entityName)
    if (drawList == nil or drawList.AddRectFilled == nil or drawList.AddText == nil) then
        return;
    end

    local settings = state.GetGlobalSettings(globalDefaults);
    local menu = settings.quickMenu or {};
    local title, titleIcon, rows = GetQuickMenuPreviewRows(entityName, menu);
    local iconSize = tonumber(menu.iconSize) or 22;
    local width = math.max(220, math.min(tonumber(menu.width) or 270, previewWidth - 28));
    local rowHeight = math.max(24, iconSize + 4);
    local textRowHeight = 17;
    local height = 44;
    local actionRowCount = 0;

    for _, row in ipairs(rows) do
        if (row.kind ~= 'spacer') then
            actionRowCount = actionRowCount + 1;
        end
    end

    if (actionRowCount > 0 and (height + (actionRowCount * rowHeight)) > (previewHeight - 16)) then
        rowHeight = math.max(20, math.floor((previewHeight - 60) / actionRowCount));
    end

    for _, row in ipairs(rows) do
        height = height + (row.kind == 'spacer' and 8 or ((row[2] ~= nil or row[3] ~= nil) and rowHeight or textRowHeight));
    end
    local menuX = x + math.max(12, math.floor((previewWidth - width) * 0.5));
    local preferredTop = math.max(32, math.floor((previewHeight - height) * 0.5));
    local maxTop = math.max(8, previewHeight - height - 10);
    local menuY = y + math.max(8, math.min(preferredTop, maxTop));
    local bgColor = ColorToU32(menu.backgroundColor, { 0.02, 0.02, 0.07, 0.96 });
    local borderColor = ColorToU32(menu.borderColor, { 0.25, 0.25, 0.36, 1.0 });
    local textColor = ColorToU32(GetQuickMenuReadableTextColor(menu), { 1.0, 1.0, 1.0, 1.0 });
    local headerColor = ColorToU32(menu.headerColor, { 1.0, 0.84, 0.0, 1.0 });
    local linkColor = ColorToU32(menu.linkColor, { 0.48, 0.82, 1.0, 1.0 });

    drawList:AddRectFilled({ menuX, menuY }, { menuX + width, menuY + height }, bgColor);

    if (drawList.AddRect ~= nil and (tonumber(menu.borderSize) or 1) > 0) then
        drawList:AddRect({ menuX, menuY }, { menuX + width, menuY + height }, borderColor, 0, 0, tonumber(menu.borderSize) or 1);
    end

    local headerX = menuX + 12;
    local headerY = menuY + 10;

    if (menu.iconsEnabled ~= false and titleIcon ~= nil and drawList.AddImage ~= nil) then
        local textureId = LoadQuickMenuIcon(titleIcon);

        if (textureId ~= nil) then
            drawList:AddImage(textureId, { headerX, headerY }, { headerX + iconSize, headerY + iconSize }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
            headerX = headerX + iconSize + 8;
        end
    end

    drawList:AddText({ headerX, headerY + 2 }, headerColor, title);

    if (drawList.AddLine ~= nil) then
        drawList:AddLine({ menuX + 12, menuY + 36 }, { menuX + width - 12, menuY + 36 }, borderColor, 1);
    end

    local rowY = menuY + 42;

    for _, row in ipairs(rows) do
        local label = row[1];
        local iconFile = row[2];
        local textureId = row[3];
        local isBullet = row.bullet == true;
        local labelX = menuX + 12 + (isBullet and 12 or 0);
        local currentRowHeight = (iconFile ~= nil or textureId ~= nil) and rowHeight or textRowHeight;

        if (row.kind == 'spacer') then
            rowY = rowY + 8;
        else

        if (menu.iconsEnabled ~= false and drawList.AddImage ~= nil and (iconFile ~= nil or textureId ~= nil)) then
            textureId = textureId or LoadQuickMenuIcon(iconFile);

            if (textureId ~= nil) then
                drawList:AddImage(textureId, { labelX, rowY }, { labelX + iconSize, rowY + iconSize }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
                labelX = labelX + iconSize + 8;
            end
        end

        if (isBullet == true and drawList.AddCircleFilled ~= nil) then
            drawList:AddCircleFilled({ menuX + 18, rowY + 10 }, 2.5, linkColor, 8);
        end

        local rowColor = textColor;
        if (row.kind == 'header') then
            rowColor = headerColor;
        elseif (row.kind == 'link') then
            rowColor = linkColor;
        end

        drawList:AddText({ labelX, rowY + 2 }, rowColor, label);
        rowY = rowY + currentRowHeight;
        end
    end
end

local function DrawPreviewText(drawList, x, y, color, text, outlineSize, outlineColor)
    outlineSize = math.max(0, math.min(4, tonumber(outlineSize) or 0));

    if (outlineSize > 0) then
        for ox = -outlineSize, outlineSize do
            for oy = -outlineSize, outlineSize do
                if (ox ~= 0 or oy ~= 0) then
                    drawList:AddText({ x + ox, y + oy }, outlineColor, tostring(text or ''));
                end
            end
        end
    end

    drawList:AddText({ x, y }, color, tostring(text or ''));
end

local function DrawPreviewPeerTextRow(drawList, labelX, valueX, y, labelColor, valueColor, label, value, outlineSize, outlineColor)
    DrawPreviewText(drawList, labelX, y, labelColor, label, outlineSize, outlineColor);
    DrawPreviewText(drawList, valueX, y, valueColor, tostring(value or ''), outlineSize, outlineColor);
end

local function DrawPreviewPeerIconRow(drawList, x, y, iconNames, peerSettings, iconSize, maxWidth)
    local cursorX = x;
    local iconStyle = SanitizePeerIconStyle(peerSettings.iconStyle);

    for _, iconName in ipairs(iconNames or {}) do
        if ((cursorX + iconSize) > (x + maxWidth)) then
            break;
        end

        local textureId = LoadPeerIcon(iconName, iconStyle);

        if (textureId ~= nil) then
            drawList:AddImage(textureId, { cursorX, y }, { cursorX + iconSize, y + iconSize }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
            cursorX = cursorX + iconSize + 5;
        end
    end
end

local function DrawPreviewPeerPanelBox(drawList, x, y, w, h, peerSettings)
    local bgColor = peerSettings.backgroundColor or { 0.0, 0.0, 0.0, 0.45 };
    local opacity = math.max(0.0, math.min(1.0, (tonumber(peerSettings.backgroundOpacity) or 45) / 100));
    local borderSize = math.max(0, math.min(12, tonumber(peerSettings.backgroundBorderSize) or 0));

    drawList:AddRectFilled({ x, y }, { x + w, y + h }, ColorToU32({
        bgColor[1] or 0.0,
        bgColor[2] or 0.0,
        bgColor[3] or 0.0,
        opacity,
    }));

    if (borderSize > 0 and drawList.AddRect ~= nil) then
        local borderColor = ColorToU32(peerSettings.backgroundBorderColor, { 0.78, 0.12, 0.10, 0.88 });
        for i = 0, borderSize - 1 do
            drawList:AddRect({ x + i, y + i }, { x + w - i, y + h - i }, borderColor);
        end
    end
end

local function GetPreviewPeerInspectorWidth(peerSettings, entityName)
    local width = tonumber(peerSettings ~= nil and peerSettings.inspectorWidth) or 430;
    return math.max(120, math.min(800, width));
end

local function GetPreviewPeerPanelPosition(previewX, previewY, previewWidth, previewHeight, panelW, panelH)
    local x = previewX + math.floor((previewWidth - panelW) * 0.5);
    local y = previewY + math.floor((previewHeight - panelH) * 0.5);
    local rightLimit = previewX + previewWidth - 12;
    local bottomLimit = previewY + previewHeight - 12;

    if ((y + panelH) > bottomLimit) then
        y = bottomLimit - panelH;
    end

    x = math.max(previewX + 12, x);
    y = math.max(previewY + 12, y);

    return x, y;
end

local function GetPreviewSelfPeerPanelPosition(previewX, previewY, previewWidth, previewHeight, panelW, panelH)
    local x = previewX + math.floor((previewWidth - panelW) * 0.5);
    local y = previewY + math.floor((previewHeight - panelH) * 0.5);
    local bottomLimit = previewY + previewHeight - 24;

    if ((y + panelH) > bottomLimit) then
        y = bottomLimit - panelH;
    end

    x = math.max(previewX + 12, x);
    y = math.max(previewY + 12, y);

    return x, y;
end

local function GetPreviewEnemyPeerTextInspectorHeight(peerSettings)
    local h = 56;

    if (peerSettings.showHpValue ~= false) then h = h + 28; end
    if (peerSettings.showBehavior ~= false) then h = h + 28; end
    if (peerSettings.showDetects ~= false) then h = h + 28; end
    if (peerSettings.showLinks ~= false) then h = h + 32; end
    if (peerSettings.showWeakTo ~= false) then h = h + 28; end
    if (peerSettings.showResists ~= false) then h = h + 28; end
    if (peerSettings.showImmunities ~= false) then h = h + 28; end

    return math.max(84, h + 22);
end

local function GetPreviewEnemyPeerIconInspectorHeight(peerSettings)
    local h = 56;

    if (peerSettings.showHpValue ~= false) then h = h + 30; end
    if (peerSettings.showBehavior ~= false) then h = h + 30; end
    if (peerSettings.showDetects ~= false) then h = h + 30; end
    if (peerSettings.showLinks ~= false) then h = h + 36; end
    if (peerSettings.showWeakTo ~= false) then h = h + 56; end
    if (peerSettings.showResists ~= false) then h = h + 56; end
    if (peerSettings.showImmunities ~= false) then h = h + 34; end

    return math.max(84, h + 22);
end

local function DrawPeerInspectorPreview(drawList, x, y, previewWidth, previewHeight, context)
    if (drawList == nil or drawList.AddText == nil or drawList.AddRectFilled == nil) then
        return;
    end

    local peerSettings = GetPreviewPeerSettings(context);
    local panelW = math.max(320, math.min(GetPreviewPeerInspectorWidth(peerSettings, 'Enemy'), previewWidth - 36));
    local panelH = math.min(
        (tostring(peerSettings.displayMode or 'Text') == 'Text') and GetPreviewEnemyPeerTextInspectorHeight(peerSettings) or GetPreviewEnemyPeerIconInspectorHeight(peerSettings),
        previewHeight - 36
    );
    local panelX = x + math.floor((previewWidth - panelW) * 0.5);
    local panelY = y + math.floor((previewHeight - panelH) * 0.5);
    local textColor = ColorToU32(peerSettings.textColor, { 0.94, 0.94, 0.90, 1.0 });
    local outlineColor = ColorToU32(peerSettings.textOutlineColor, { 0.0, 0.0, 0.0, 1.0 });
    local outlineSize = tonumber(peerSettings.textOutlineSize) or 0;
    local muted = ColorToU32({ 0.68, 0.72, 0.74, 1.0 });
    local blue = ColorToU32({ 0.40, 0.70, 1.0, 1.0 });
    local good = ColorToU32({ 0.44, 0.95, 0.70, 1.0 });
    local bad = ColorToU32({ 1.0, 0.58, 0.50, 1.0 });
    local heading = ColorToU32({ 1.0, 0.84, 0.0, 1.0 });
    local labelX = panelX + 14;
    local valueX = panelX + 118;
    local rowY = panelY + 52;
    local levelJobText = '';

    DrawPreviewPeerPanelBox(drawList, panelX, panelY, panelW, panelH, peerSettings);

    if (peerSettings.showLevel ~= false) then
        levelJobText = 'Lv. 70-73';
    end

    if (peerSettings.showJob ~= false) then
        levelJobText = (levelJobText ~= '' and (levelJobText .. ' ') or '') .. 'PLD';
    end

    if (levelJobText ~= '') then
        DrawPreviewText(drawList, labelX, panelY + 10, blue, levelJobText, outlineSize, outlineColor);
    end

    if (peerSettings.showName ~= false) then
        DrawPreviewText(drawList, panelX + 142, panelY + 10, textColor, 'Sabotender Enamorado', outlineSize + 1, outlineColor);
    end

    if (peerSettings.showDistance ~= false) then
        DrawPreviewText(drawList, panelX + panelW - 54, panelY + 10, muted, '44.9', outlineSize, outlineColor);
    end

    if (tostring(peerSettings.displayMode or 'Text') == 'Text') then
        if (peerSettings.showHpValue ~= false) then
            DrawPreviewPeerTextRow(drawList, labelX, valueX, rowY, heading, textColor, 'HP', '87%', outlineSize, outlineColor);
            rowY = rowY + 28;
        end
        if (peerSettings.showBehavior ~= false) then
            DrawPreviewPeerTextRow(drawList, labelX, valueX, rowY, heading, textColor, 'Behavior', 'Aggro', outlineSize, outlineColor);
            rowY = rowY + 28;
        end
        if (peerSettings.showDetects ~= false) then
            DrawPreviewPeerTextRow(drawList, labelX, valueX, rowY, heading, textColor, 'Detects', 'Sight, Sound, Magic', outlineSize, outlineColor);
            rowY = rowY + 28;
        end
        if (peerSettings.showLinks ~= false) then
            DrawPreviewPeerTextRow(drawList, labelX, valueX, rowY, heading, textColor, 'Links', 'Yes', outlineSize, outlineColor);
            rowY = rowY + 32;
        end
        if (peerSettings.showWeakTo ~= false) then
            DrawPreviewPeerTextRow(drawList, labelX, valueX, rowY, heading, good, 'Weak To', 'Fire +25%, Wind +25%', outlineSize, outlineColor);
            rowY = rowY + 28;
        end
        if (peerSettings.showResists ~= false) then
            DrawPreviewPeerTextRow(drawList, labelX, valueX, rowY, heading, bad, 'Resists', 'Earth -50%, Dark -50%', outlineSize, outlineColor);
            rowY = rowY + 28;
        end
        if (peerSettings.showImmunities ~= false) then
            DrawPreviewPeerTextRow(drawList, labelX, valueX, rowY, heading, muted, 'Immunities', 'Sleep, Silence', outlineSize, outlineColor);
        end
        return;
    end

    local iconSize = math.max(6, math.min(256, tonumber(peerSettings.iconSize) or 22));
    local contentX = panelX + 142;
    local contentW = panelW - 156;

    if (peerSettings.showHpValue ~= false) then
        drawList:AddText({ labelX, rowY }, heading, 'HP');
        drawList:AddText({ contentX, rowY }, textColor, '87%');
        rowY = rowY + 30;
    end
    if (peerSettings.showBehavior ~= false) then
        drawList:AddText({ labelX, rowY }, heading, 'Behavior');
        DrawPreviewPeerIconRow(drawList, contentX, rowY - 3, T{ 'AggroNQ' }, peerSettings, iconSize, contentW);
        rowY = rowY + 30;
    end
    if (peerSettings.showDetects ~= false) then
        drawList:AddText({ labelX, rowY }, heading, 'Detects');
        DrawPreviewPeerIconRow(drawList, contentX, rowY - 3, T{ 'Sight', 'Sound', 'Magic' }, peerSettings, iconSize, contentW);
        rowY = rowY + 30;
    end
    if (peerSettings.showLinks ~= false) then
        drawList:AddText({ labelX, rowY }, heading, 'Links');
        DrawPreviewPeerIconRow(drawList, contentX, rowY - 3, T{ 'Link' }, peerSettings, iconSize, contentW);
        rowY = rowY + 36;
    end
    if (peerSettings.showWeakTo ~= false) then
        drawList:AddText({ labelX, rowY }, heading, 'Weak To');
        DrawPreviewPeerIconRow(drawList, contentX, rowY - 3, T{ 'Fire', 'Wind' }, peerSettings, iconSize, contentW);
        rowY = rowY + 34;
    end
    if (peerSettings.showResists ~= false) then
        drawList:AddText({ labelX, rowY }, heading, 'Resists');
        DrawPreviewPeerIconRow(drawList, contentX, rowY - 3, T{ 'Earth', 'Dark' }, peerSettings, iconSize, contentW);
        rowY = rowY + 34;
    end
    if (peerSettings.showImmunities ~= false) then
        drawList:AddText({ labelX, rowY }, heading, 'Immunities');
        DrawPreviewPeerIconRow(drawList, contentX, rowY - 3, T{ 'ImmuneSleep', 'ImmuneSilence' }, peerSettings, iconSize, contentW);
    end
end

local function DrawSelfPeerPreview(drawList, x, y, previewWidth, previewHeight, context)
    if (drawList == nil or drawList.AddText == nil or drawList.AddRectFilled == nil) then
        return;
    end

    local peerSettings = GetPreviewPeerSettings(context);
    local showName = peerSettings.showName ~= false;
    local showJobLine = peerSettings.showJob ~= false or peerSettings.showLevel ~= false;
    local showStats = peerSettings.showHpValue ~= false;
    local showAttackDefense = peerSettings.showWeakTo ~= false;
    local showResists = peerSettings.showResists ~= false;
    local rowStep = 20;
    local attackDefenseStep = 24;
    local resistRowStep = 19;
    local panelHeight = 12 +
        (showName and rowStep or 0) +
        (showJobLine and rowStep or 0) +
        (showStats and (7 * rowStep) or 0) +
        ((showAttackDefense or showResists) and 14 or 0) +
        (showAttackDefense and attackDefenseStep or 0) +
        (showResists and ((2 * resistRowStep) + 18) or 0) +
        12;
    local panelW = math.min(GetPreviewPeerInspectorWidth(peerSettings, 'Self'), previewWidth - 36);
    local panelH = math.min(math.max(52, panelHeight + 18), previewHeight - 24);
    local panelX, panelY = GetPreviewSelfPeerPanelPosition(x, y, previewWidth, previewHeight, panelW, panelH);
    local textColor = ColorToU32(peerSettings.textColor, { 0.94, 0.94, 0.90, 1.0 });
    local outlineColor = ColorToU32(peerSettings.textOutlineColor, { 0.0, 0.0, 0.0, 1.0 });
    local outlineSize = tonumber(peerSettings.textOutlineSize) or 0;
    local muted = ColorToU32({ 0.68, 0.72, 0.74, 1.0 });
    local blue = ColorToU32({ 0.62, 0.80, 1.0, 1.0 });
    local green = ColorToU32({ 0.35, 1.0, 0.45, 1.0 });
    local heading = ColorToU32({ 1.0, 0.84, 0.0, 1.0 });
    local labelX = panelX + 14;
    local valueX = panelX + 84;
    local rowY = panelY + 12;

    DrawPreviewPeerPanelBox(drawList, panelX, panelY, panelW, panelH, peerSettings);

    if (showName == true) then
        DrawPreviewText(drawList, labelX, rowY, textColor, 'Libra', outlineSize + 1, outlineColor);
        rowY = rowY + rowStep;
    end

    if (showJobLine == true) then
        local mainJob = peerSettings.showJob ~= false and 'WHM' or '';
        local subJob = peerSettings.showJob ~= false and 'BLM' or '';
        local mainText = '';
        local subText = '';

        if (peerSettings.showLevel ~= false) then
            mainText = 'Lv75';
            subText = 'Lv37';
        end

        if (mainJob ~= '') then
            mainText = (mainText ~= '' and (mainText .. ' ') or '') .. mainJob;
            subText = (subText ~= '' and (subText .. ' ') or '') .. subJob;
        end

        DrawPreviewText(drawList, labelX, rowY, blue, mainText .. ' / ' .. subText, outlineSize, outlineColor);
        rowY = rowY + rowStep;
    end

    local statRows = T{
        T{ 'STR', '64', '+8' },
        T{ 'DEX', '63', '+12' },
        T{ 'VIT', '65', '+2' },
        T{ 'AGI', '67', '+3' },
        T{ 'INT', '68', '+1' },
        T{ 'MND', '66', '' },
        T{ 'CHR', '69', '' },
    };

    if (showStats == true) then
        for _, stat in ipairs(statRows) do
            DrawPreviewText(drawList, labelX, rowY, heading, stat[1], outlineSize, outlineColor);
            DrawPreviewText(drawList, valueX, rowY, textColor, stat[2], outlineSize, outlineColor);
            if (stat[3] ~= '') then
                DrawPreviewText(drawList, valueX + 42, rowY, green, stat[3], outlineSize, outlineColor);
            end
            rowY = rowY + rowStep;
        end
    end

    if (showAttackDefense == true or showResists == true) then
        rowY = rowY + 4;
        if (drawList.AddLine ~= nil) then
            drawList:AddLine({ panelX + 10, rowY }, { panelX + panelW - 10, rowY }, ColorToU32({ 0.62, 0.67, 0.72, 0.55 }), 1);
        end
        rowY = rowY + 10;
    end

    if (showAttackDefense == true) then
        DrawPreviewText(drawList, labelX, rowY, textColor, 'Attack 278', outlineSize, outlineColor);
        DrawPreviewText(drawList, labelX + 126, rowY, textColor, 'Defense 326', outlineSize, outlineColor);
        rowY = rowY + attackDefenseStep;
    end

    local iconSize = 15;
    local elements = T{
        T{ icon = 'Fire', label = 'Fire' },
        T{ icon = 'Ice', label = 'Ice' },
        T{ icon = 'Wind', label = 'Wind' },
        T{ icon = 'Earth', label = 'Earth' },
        T{ icon = 'Lightning', label = 'Lightning' },
        T{ icon = 'Water', label = 'Water' },
        T{ icon = 'Light', label = 'Light' },
        T{ icon = 'Dark', label = 'Dark' },
    };
    local startX = labelX;

    if (showResists == true) then
        for i, element in ipairs(elements) do
            local col = (i - 1) % 4;
            local row = math.floor((i - 1) / 4);
            local iconX = startX + (col * 58);
            local iconY = rowY + (row * resistRowStep);
            local textureId = LoadSelfElementIcon(element.icon);
            local valueXOffset = iconSize + 4;

            if (textureId ~= nil and drawList.AddImage ~= nil) then
                drawList:AddImage(textureId, { iconX, iconY }, { iconX + iconSize, iconY + iconSize }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
            else
                DrawPreviewText(drawList, iconX, iconY - 1, muted, string.sub(element.label, 1, 1), outlineSize, outlineColor);
                valueXOffset = 14;
            end
            DrawPreviewText(drawList, iconX + valueXOffset, iconY - 1, muted, '0', outlineSize, outlineColor);
        end
    end
end

local function DrawPcPeerPreview(drawList, x, y, previewWidth, previewHeight, context)
    if (drawList == nil or drawList.AddText == nil or drawList.AddRectFilled == nil) then
        return;
    end

    local peerSettings = GetPreviewPeerSettings(context);
    local panelW = math.min(GetPreviewPeerInspectorWidth(peerSettings, 'PC'), previewWidth - 36);
    local panelH = math.min(136, previewHeight - 8);
    local panelX, panelY = GetPreviewPeerPanelPosition(x, y, previewWidth, previewHeight, panelW, panelH);
    local textColor = ColorToU32(peerSettings.textColor, { 0.94, 0.94, 0.90, 1.0 });
    local outlineColor = ColorToU32(peerSettings.textOutlineColor, { 0.0, 0.0, 0.0, 1.0 });
    local outlineSize = tonumber(peerSettings.textOutlineSize) or 0;
    local blue = ColorToU32({ 0.62, 0.80, 1.0, 1.0 });
    local heading = ColorToU32({ 1.0, 0.84, 0.0, 1.0 });
    local labelX = panelX + 14;
    local valueX = panelX + 104;
    local rightX = panelX + 204;
    local rowY = panelY + 12;
    local rowStep = 24;

    DrawPreviewPeerPanelBox(drawList, panelX, panelY, panelW, panelH, peerSettings);

    DrawPreviewText(drawList, labelX, rowY, textColor, 'Libra', outlineSize + 1, outlineColor);
    DrawPreviewText(drawList, rightX, rowY, heading, 'Distance', outlineSize, outlineColor);
    DrawPreviewText(drawList, rightX + 74, rowY, textColor, '12.4', outlineSize, outlineColor);
    rowY = rowY + rowStep;

    DrawPreviewText(drawList, labelX, rowY, heading, 'HP', outlineSize, outlineColor);
    DrawPreviewText(drawList, valueX, rowY, textColor, '89%', outlineSize, outlineColor);
    rowY = rowY + rowStep;

    DrawPreviewText(drawList, labelX, rowY, heading, 'Mode', outlineSize, outlineColor);
    DrawPreviewText(drawList, valueX, rowY, textColor, 'ACE', outlineSize, outlineColor);
    rowY = rowY + rowStep;

    DrawPreviewText(drawList, labelX, rowY, heading, 'Target', outlineSize, outlineColor);
    DrawPreviewText(drawList, valueX, rowY, textColor, 'Wild Rabbit', outlineSize, outlineColor);
end

function preview.BuildPlateData(entityName, stateName, context)
    return BuildPlate(entityName, stateName, context);
end

function preview.Draw(entityName, stateName, context)
    mouseInPreview = false;
    previewControlClickConsumed = false;

    local quickMenuOnlyPreview = context ~= nil and context.previewQuickMenu == true;
    local plate = quickMenuOnlyPreview ~= true and BuildPlate(entityName, stateName, context) or nil;
    local plateTexture = nil;
    local textureWidth = 1024;
    local textureHeight = 512;
    local plateTextureId = nil;

    if (quickMenuOnlyPreview ~= true) then
        plateTexture, textureWidth, textureHeight = canvasTexture.Render(plate, 'settings-preview');
        plateTextureId = canvasTexture.GetTextureId(plateTexture);
        textureWidth = 1024;
        textureHeight = 512;
    end

    local availWidth, availHeight = GetContentRegionAvail();
    local labelHeight = 42;
    local previewWidth = math.max(240, math.min(availWidth - 12, 720));
    local previewHeight = math.floor(previewWidth * (textureHeight / textureWidth));
    local maxPreviewHeight = math.max(60, availHeight - labelHeight - 8);
    local isSelfPeerContext = entityName == 'Self' and context ~= nil and context.widgetKey == 'Peer';

    if (previewHeight > maxPreviewHeight) then
        previewHeight = maxPreviewHeight;
        previewWidth = math.floor(previewHeight * (textureWidth / textureHeight));
    end

    DrawStyledPreviewControls();

    if (plateTextureId == nil and quickMenuOnlyPreview ~= true) then
        imgui.TextColored({ 0.65, 0.90, 1.0, 1.0 }, 'Preview unavailable.');
        return;
    end

    local drawList = imgui.GetWindowDrawList();

    if (drawList == nil or drawList.AddImage == nil or imgui.GetCursorScreenPos == nil) then
        if (imgui.Image ~= nil) then
            imgui.Image(plateTextureId, { previewWidth, previewHeight }, { 0, 0 }, { 1, 1 });
            return;
        end

        imgui.TextColored({ 0.65, 0.90, 1.0, 1.0 }, 'Preview image unavailable.');
        return;
    end

    local x, y = imgui.GetCursorScreenPos();
    local previewCursorY = imgui.GetCursorPosY ~= nil and imgui.GetCursorPosY() or nil;
    local backgroundTextureId = LoadBackground(selectedBackground);
    local uv1, uv2, plateZoom = GetZoomUvs(entityName, stateName);
    local mouseX, mouseY = GetMousePos();
    local isPeerContext = context ~= nil and context.widgetKey == 'Peer';
    local isEnemyPeerPreview = entityName == 'Enemy' and isPeerContext == true;
    local isSelfPeerPreview = isSelfPeerContext == true;
    local isPcPeerPreview = entityName == 'PC' and isPeerContext == true;
    local isPeerPreview = isEnemyPeerPreview == true or isSelfPeerPreview == true or isPcPeerPreview == true;

    mouseInPreview = (
        mouseX ~= nil and
        mouseY ~= nil and
        mouseX >= x and
        mouseX <= (x + previewWidth) and
        mouseY >= y and
        mouseY <= (y + previewHeight)
    );

    if (backgroundTextureId ~= nil) then
        drawList:AddImage(backgroundTextureId, { x, y }, { x + previewWidth, y + previewHeight }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
    else
        drawList:AddRectFilled({ x, y }, { x + previewWidth, y + previewHeight }, 0xFF30343A);
    end

    if (drawList.PushClipRect ~= nil and drawList.PopClipRect ~= nil) then
        drawList:PushClipRect({ x, y }, { x + previewWidth, y + previewHeight }, true);
    end

    local zoomWidth = previewWidth * plateZoom;
    local zoomHeight = previewHeight * plateZoom;
    local zoomX = x + ((previewWidth - zoomWidth) * 0.5);
    local zoomY = y + ((previewHeight - zoomHeight) * 0.5);

    if (entityName == 'Luopan' and isPeerPreview ~= true and quickMenuOnlyPreview ~= true) then
        DrawLuopanPreviewActor(drawList, x, y, previewWidth, previewHeight);
    end

    if (entityName == 'Pet (SMN)' and stateName == 'Spirit' and isPeerPreview ~= true and quickMenuOnlyPreview ~= true) then
        DrawSpiritPreviewActor(drawList, x, y, previewWidth, previewHeight);
    end

    if (isPeerPreview ~= true and quickMenuOnlyPreview ~= true) then
        drawList:AddImage(plateTextureId, { zoomX, zoomY }, { zoomX + zoomWidth, zoomY + zoomHeight }, uv1, uv2, 0xFFFFFFFF);
    end

    if (context ~= nil and context.previewQuickMenu == true) then
        DrawQuickMenuPreview(drawList, x, y, previewWidth, previewHeight, entityName);
    end

    if (isEnemyPeerPreview == true) then
        DrawPeerInspectorPreview(drawList, x, y, previewWidth, previewHeight, context);
    elseif (isSelfPeerPreview == true) then
        DrawSelfPeerPreview(drawList, x, y, previewWidth, previewHeight, context);
    elseif (isPcPeerPreview == true) then
        DrawPcPeerPreview(drawList, x, y, previewWidth, previewHeight, context);
    end

    if (drawList.PushClipRect ~= nil and drawList.PopClipRect ~= nil) then
        drawList:PopClipRect();
    end

    DrawPreviewInfoOverlay(drawList, x, y);
    DrawPreviewCornerControls(drawList, x, y, previewWidth, previewHeight);

    if (entityName == 'Enemy' and isPeerPreview ~= true and quickMenuOnlyPreview ~= true) then
        DrawEnemyPreviewNameModeControl(drawList, x, y, previewWidth);
    end

    if (isPeerPreview ~= true and quickMenuOnlyPreview ~= true) then
        HandlePreviewElementDrag(plate, textureWidth, textureHeight, zoomX, zoomY, zoomWidth, zoomHeight, context);
        HandlePreviewElementClick(plate, textureWidth, textureHeight, zoomX, zoomY, zoomWidth, zoomHeight, context);
    end

    if (previewCursorY ~= nil and imgui.SetCursorPosY ~= nil) then
        imgui.SetCursorPosY(previewCursorY + previewHeight);
    else
        imgui.SetCursorPosY(imgui.GetCursorPosY() + previewHeight);
    end
end

return preview;
