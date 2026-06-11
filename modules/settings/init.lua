local settingsUi = {};
local imgui = require('imgui');
local unpackTable = table.unpack or unpack;
local state = require('core.state');
local widgets = require('modules.widgets.init');
local preview = require('modules.settings.preview');
local textureLoader = require('core.texture_loader');
local jobIconTextures = require('core.job_icon_textures');
local uiTooltip = require('core.ui_tooltip');
local arrowAnimation = require('core.target_arrow_animation');
local fonts = require('core.fonts');
local textScale = require('core.text_scale');
local targeting = require('core.targeting');
local mouseControls = require('core.mouse_controls');
local cursorOverlay = require('core.cursor_overlay');
local globalDefaults = require('config.global');
local backgroundDefaults = require('config.widgets.background');
local nameDefaults = require('config.widgets.name');
local aoeRangeDefaults = require('config.widgets.aoe_range');
local jobDefaults = require('config.widgets.job');
local levelDefaults = require('config.widgets.level');
local distanceDefaults = require('config.widgets.distance');
local idDefaults = require('config.widgets.id');
local buffsDefaults = require('config.widgets.buffs');
local debuffsDefaults = require('config.widgets.debuffs');
local gameModeIconDefaults = require('config.widgets.game_mode_icon');
local bazaarIconDefaults = require('config.widgets.bazaar_icon');
local linkshellIconDefaults = require('config.widgets.linkshell_icon');
local awayIconDefaults = require('config.widgets.away_icon');
local disconnectIconDefaults = require('config.widgets.disconnect_icon');
local anonIconDefaults = require('config.widgets.anon_icon');
local followIconDefaults = require('config.widgets.follow_icon');
local starsIconDefaults = require('config.widgets.stars_icon');
local levelSyncIconDefaults = require('config.widgets.level_sync_icon');
local newAdventurerIconDefaults = require('config.widgets.new_adventurer_icon');
local barDefaults = require('config.widgets.bar');
local mpBarDefaults = require('config.widgets.mp_bar');
local tpBarDefaults = require('config.widgets.tp_bar');
local castBarDefaults = require('config.widgets.cast_bar');
local maneuverDefaults = require('config.widgets.maneuvers');
local targetModuleDefaults = require('config.widgets.target_module');
local subtargetModuleDefaults = require('config.widgets.subtarget_module');
local fishing = require('core.fishing');
local crafting = require('core.crafting');
local settingsLabelColor = { 0.92, 0.92, 0.90, 1.0 };
local settingsHeaderColor = { 1.0, 0.84, 0.0, 1.0 };

local function DrawYellowHeader(label)
    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.18);
    end

    imgui.TextColored(settingsHeaderColor, tostring(label or ''));

    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.0);
    end
end
local settingsTableFlags = (_G.ImGuiTableFlags_SizingFixedFit or 0) + (_G.ImGuiTableFlags_BordersInnerH or 0);
local settingsWindowFlags = 0;
local targetAutoPlaceAnchorOptions = T{ 'Widest element', 'Name', 'HP Bar' };
local profileMainJobOptions = T{ 'BLM', 'BLU', 'BRD', 'BST', 'COR', 'DNC', 'DRG', 'DRK', 'GEO', 'MNK', 'NIN', 'PLD', 'PUP', 'RDM', 'RNG', 'RUN', 'SAM', 'SCH', 'SMN', 'THF', 'WAR', 'WHM' };
local profileSubJobOptions = T{ 'Any', 'BLM', 'BLU', 'BRD', 'BST', 'COR', 'DNC', 'DRG', 'DRK', 'GEO', 'MNK', 'NIN', 'PLD', 'PUP', 'RDM', 'RNG', 'RUN', 'SAM', 'SCH', 'SMN', 'THF', 'WAR', 'WHM' };
local settingsWindowNoMoveFlag = _G.ImGuiWindowFlags_NoMove or 0;
local settingsColorEditFlags = bit ~= nil and bit.bor ~= nil
    and bit.bor(_G.ImGuiColorEditFlags_NoAlpha or 0, _G.ImGuiColorEditFlags_NoInputs or 0)
    or ((_G.ImGuiColorEditFlags_NoAlpha or 0) + (_G.ImGuiColorEditFlags_NoInputs or 0));

local function GetProfileSubJobOptions(mainJob)
    local options = T{};
    mainJob = tostring(mainJob or '');

    for _, job in ipairs(profileSubJobOptions) do
        if (job == 'Any' or tostring(job) ~= mainJob) then
            options[#options + 1] = job;
        end
    end

    return options;
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
    color = { 0.90, 0.65, 0.25, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    offsetX = 0,
    offsetY = 28,
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
local petRewardBarDefaults = {
    enabled = true,
    width = 160,
    height = 6,
    texture = 'Solid',
    labelDisplayMode = 'Text',
    labelIconSize = 14,
    labelIconOffsetX = 0,
    labelIconOffsetY = 0,
    color = { 0.70, 0.90, 0.45, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    offsetX = 0,
    offsetY = 52,
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
local petWardBarDefaults = {
    enabled = true,
    width = 81,
    height = 12,
    texture = 'Solid',
    labelDisplayMode = 'Text',
    labelIconSize = 14,
    labelIconOffsetX = 0,
    labelIconOffsetY = 0,
    color = { 0.00, 0.75, 0.85, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    offsetX = -44,
    offsetY = 16,
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
local petRageBarDefaults = {
    enabled = true,
    width = 81,
    height = 12,
    texture = 'Solid',
    labelDisplayMode = 'Text',
    labelIconSize = 14,
    labelIconOffsetX = 0,
    labelIconOffsetY = 0,
    color = { 0.85, 0.20, 0.10, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    offsetX = 44,
    offsetY = 16,
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
    showText = false,
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
    showText = false,
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
    showText = false,
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

local windowOpen = { false };
local selectedTab = 'Plates';
local selectedEntity = 'Self';
local selectedState = 'World';
local selectedWidget = 'Name';
local selectedModuleEntity = 'Enemy';
local selectedModuleState = 'World';
local selectedModuleWidget = 'Target';
local selectedPeerEnemyInfo = 'Job';
local selectedGeneralSection = 'Font';
local selectedTargetingSection = 'Left Click';
local profileNewNameBuffer = { '' };
local profileCopyNameBuffer = { '' };
local profileRenameNameBuffer = { '' };
local profilePendingDelete = nil;
local profilePendingReset = nil;
local profileStatusMessage = '';
local profilePopupStatusMessage = '';
local openDropdown = nil;
local previewSplitRatio = 0.42;
local splitterArrowTextureId = nil;
local DrawSelectedEditor = nil;
local uiAccent = { 0.20, 0.65, 0.67, 1.0 };
local uiAccentHovered = { 0.25, 0.76, 0.78, 1.0 };
local uiAccentActive = { 0.16, 0.55, 0.57, 1.0 };
local heldButtonState = {};
local targetModulePendingReset = nil;
local maneuverPendingReset = nil;
local loadModeDrawn = false;

local tabs = T{ 'General', 'Targeting', 'Plates', 'Modules' };
local generalSections = T{ 'Profiles', 'Font', 'Native UI', 'Mouse', 'Scaling' };
local targetingSections = T{ 'Left Click', 'Right Click', 'Click Blocking' };
local entities = T{
    'Self',
    'Trust',
    'PC',
    'Enemy',
    'Pet (BST)',
    'Pet (SMN)',
    'Pet (DRG)',
    'Pet (PUP)',
    'NPC',
    'Object',
};
local states = T{ 'World', 'Tactical' };
local statesByEntity = {
    ['Self'] = T{ 'World', 'Tactical', 'Resting', 'Fishing', 'Crafting', 'Gathering' },
    ['Enemy'] = T{ 'World', 'Tactical' },
    ['PC'] = T{ 'World', 'Tactical' },
    ['Trust'] = T{ 'World', 'Tactical' },
    ['Pet (BST)'] = T{ 'Charmed Pet', 'Jug Pet' },
    ['Pet (SMN)'] = T{ 'Avatar', 'Spirit' },
    ['Pet (DRG)'] = T{ 'Wyvern' },
    ['Pet (PUP)'] = T{ 'Automaton' },
    ['NPC'] = T{ 'World' },
    ['Object'] = T{ 'World' },
};
local editWidgets = T{
    'Background',
    'Name',
    'Job',
    'HP Bar',
    'MP Bar',
    'TP Bar',
    'Buffs',
    'Debuffs',
    'Party leader icon',
    'Alliance leader icon',
    'Game mode icon',
    'Linkshell icon',
    'Bazaar icon',
    'Away icon',
    'Disconnect icon',
    'Anon icon',
    'Follow icon',
    'Stars icon',
    'Level sync icon',
    'New adventurer icon',
    'Quick Menu (module)',
    'Target (module)',
    'Subtarget (module)',
};
local selfIdleWidgets = T{
    'Background',
    'Name',
    'HP Bar',
    'MP Bar',
    'TP Bar',
    'Cast bar',
    'Buffs',
    'Debuffs',
    'Party leader icon',
    'Alliance leader icon',
    'Game mode icon',
    'Linkshell icon',
    'Bazaar icon',
    'Away icon',
    'Disconnect icon',
    'Stars icon',
    'New adventurer icon',
    'Quick Menu (module)',
    'Peer (module)',
    'Target (module)',
    'Subtarget (module)',
    'AOE range (module)',
};
local selfCombatWidgets = T{
    'Background',
    'Name',
    'HP Bar',
    'MP Bar',
    'TP Bar',
    'Cast bar',
    'Buffs',
    'Debuffs',
    'Party leader icon',
    'Alliance leader icon',
    'Game mode icon',
    'Linkshell icon',
    'Bazaar icon',
    'Away icon',
    'Disconnect icon',
    'Stars icon',
    'New adventurer icon',
    'Quick Menu (module)',
    'Peer (module)',
    'Target (module)',
    'Subtarget (module)',
    'AOE range (module)',
};
local selfRestingWidgets = T{
    'Background',
    'Name',
    'HP Bar',
    'MP Bar',
    'TP Bar',
    'Buffs',
    'Debuffs',
    'Resting (module)',
    'Quick Menu (module)',
    'Target (module)',
    'Subtarget (module)',
    'AOE range (module)',
};
local selfFishingWidgets = T{
    'Background',
    'Name',
    'HP Bar',
    'MP Bar',
    'TP Bar',
    'Buffs',
    'Debuffs',
    'Fishing (module)',
    'Quick Menu (module)',
    'Target (module)',
    'Subtarget (module)',
    'AOE range (module)',
};
local selfCraftingWidgets = T{
    'Background',
    'Name',
    'HP Bar',
    'MP Bar',
    'TP Bar',
    'Buffs',
    'Debuffs',
    'Crafting (module)',
    'Quick Menu (module)',
    'Target (module)',
    'Subtarget (module)',
    'AOE range (module)',
};
local selfGatheringWidgets = T{
    'Background',
    'Name',
    'HP Bar',
    'MP Bar',
    'TP Bar',
    'Buffs',
    'Debuffs',
    'Gathering (module)',
    'Quick Menu (module)',
    'Target (module)',
    'Subtarget (module)',
    'AOE range (module)',
};
local enemyIdleWidgets = T{
    'Background',
    'Name',
    'Job',
    'Level',
    'Distance',
    'HP Bar',
    'Buffs',
    'Debuffs',
    'ID',
    'Peer (module)',
    'Target (module)',
    'Subtarget (module)',
};
local enemyCombatWidgets = T{
    'Background',
    'Name',
    'Job',
    'Level',
    'Distance',
    'Lock-on icon',
    'HP Bar',
    'Buffs',
    'Debuffs',
    'ID',
    'Peer (module)',
    'Enmity (module)',
    'Target (module)',
    'Subtarget (module)',
    'Cast bar',
};
local pcIdleWidgets = T{
    'Background',
    'Name',
    'Distance',
    'HP Bar',
    'Game mode icon',
    'Linkshell icon',
    'Bazaar icon',
    'Away icon',
    'Disconnect icon',
    'Stars icon',
    'New adventurer icon',
    'Quick Menu (module)',
    'Peer (module)',
    'Subtarget',
    'Target',
};
local pcCombatWidgets = T{
    'Background',
    'Name',
    'Job',
    'Level',
    'Distance',
    'HP Bar',
    'MP Bar',
    'TP Bar',
    'Buffs',
    'Debuffs',
    'Party leader icon',
    'Alliance leader icon',
    'Game mode icon',
    'Linkshell icon',
    'Bazaar icon',
    'Away icon',
    'Disconnect icon',
    'Stars icon',
    'New adventurer icon',
    'Quick Menu (module)',
    'Peer (module)',
    'Enmity (module)',
    'Subtarget',
    'Target',
};
local trustIdleWidgets = T{
    'Background',
    'Name',
    'HP Bar',
    'MP Bar',
    'TP Bar',
    'Buffs',
    'Debuffs',
    'Quick Menu (module)',
    'Target (module)',
    'Subtarget (module)',
};
local trustCombatWidgets = T{
    'Background',
    'Name',
    'HP Bar',
    'MP Bar',
    'TP Bar',
    'Buffs',
    'Debuffs',
    'Quick Menu (module)',
    'Enmity (module)',
    'Target (module)',
    'Subtarget (module)',
};
local bstCharmedPetWidgets = T{
    'Background',
    'Name',
    'Pet timer',
    'Pet state',
    'HP Bar',
    'TP Bar',
    'Distance',
    'Sic',
    'Reward',
    'Enmity (module)',
    'Subtarget (module)',
    'Target (module)',
};
local bstJugPetWidgets = T{
    'Background',
    'Name',
    'Pet timer',
    'Pet state',
    'HP Bar',
    'TP Bar',
    'Distance',
    'Ready bar',
    'Reward',
    'Enmity (module)',
    'Subtarget (module)',
    'Target (module)',
};
local avatarEditWidgets = T{
    'Background',
    'Name',
    'Ward timer',
    'Rage timer',
    'HP Bar',
    'TP Bar',
    'Enmity (module)',
    'Subtarget (module)',
    'Target (module)',
};
local spiritEditWidgets = T{
    'Background',
    'Name',
    'HP Bar',
    'MP Bar',
    'Cast bar',
    'Enmity (module)',
    'Subtarget (module)',
    'Target (module)',
};
local wyvernEditWidgets = T{
    'Background',
    'Name',
    'Distance',
    'HP Bar',
    'TP Bar',
    'Enmity (module)',
    'Subtarget (module)',
    'Target (module)',
};
local automatonEditWidgets = T{
    'Background',
    'Name',
    'Distance',
    'HP Bar',
    'MP Bar',
    'TP Bar',
    'Maneuvers',
    'Enmity (module)',
    'Subtarget (module)',
    'Target (module)',
};
local npcEditWidgets = T{
    'Background',
    'Name',
    'Type line',
    'Distance',
    'Icon',
    'Peer (module)',
    'Quick Menu (module)',
    'Subtarget (module)',
    'Target (module)',
};
local objectEditWidgets = T{
    'Background',
    'Name',
    'Type line',
    'Distance',
    'Icon',
    'Peer (module)',
    'Gathering (module)',
    'Quick Menu (module)',
    'Subtarget (module)',
    'Target (module)',
};
local widgetKeys = {
    ['Name'] = 'Name',
    ['Type line'] = 'Type line',
    ['Icon'] = 'Icon',
    ['Background'] = 'Background',
    ['Game mode icon'] = 'Game mode icon',
    ['Bazaar icon'] = 'Bazaar icon',
    ['Linkshell icon'] = 'Linkshell icon',
    ['Away icon'] = 'Away icon',
    ['Disconnect icon'] = 'Disconnect icon',
    ['Anon icon'] = 'Anon icon',
    ['Follow icon'] = 'Follow icon',
    ['Party leader icon'] = 'Party leader icon',
    ['Alliance leader icon'] = 'Alliance leader icon',
    ['Stars icon'] = 'Stars icon',
    ['Level sync icon'] = 'Level sync icon',
    ['New adventurer icon'] = 'New adventurer icon',
    ['HP Bar'] = 'HP Bar',
    ['MP Bar'] = 'MP Bar',
    ['TP Bar'] = 'TP Bar',
    ['Cast bar'] = 'Cast bar',
    ['Job'] = 'Job',
    ['Level'] = 'Level',
    ['Distance'] = 'Distance',
    ['Lock-on icon'] = 'Target Module',
    ['ID'] = 'ID',
    ['Target arrow'] = 'Target arrow',
    ['Target Module'] = 'Target Module',
    ['Subtarget Module'] = 'Subtarget Module',
    ['Target'] = 'Target Module',
    ['Subtarget'] = 'Subtarget Module',
    ['Target (module)'] = 'Target Module',
    ['Subtarget (module)'] = 'Subtarget Module',
    ['Peer (module)'] = 'Peer',
    ['Enmity (module)'] = 'Enmity',
    ['Resting (module)'] = 'Resting',
    ['Quick Menu (module)'] = 'Quick Menu',
    ['AOE range (module)'] = 'AOE range',
    ['Mounted (module)'] = 'Mounted',
    ['Crafting (module)'] = 'Crafting',
    ['Fishing (module)'] = 'Fishing',
    ['Gathering (module)'] = 'Gathering',
    ['Death (module)'] = 'Death',
    ['NPC icon'] = 'NPC icon',
    ['Object icon'] = 'Object icon',
    ['Markers'] = 'Markers',
    ['Sic'] = 'Sic',
    ['Ready bar'] = 'Ready bar',
    ['Reward'] = 'Reward',
    ['Pet timer'] = 'Pet timer',
    ['Pet state'] = 'Pet state',
    ['Ward timer'] = 'Ward timer',
    ['Rage timer'] = 'Rage timer',
    ['Cast bar'] = 'Cast bar',
    ['Maneuvers'] = 'Maneuvers',
    ['Buffs'] = 'Buffs',
    ['Debuffs'] = 'Debuffs',
};
local moduleEntities = entities;

function NormalizeEntityName(entity)
    local entityName = tostring(entity or '');

    if (entityName == 'Wyvern') then
        return 'Pet (DRG)';
    end

    if (entityName == 'Automaton') then
        return 'Pet (PUP)';
    end

    if (entityName == 'Avatar' or entityName == 'Spirit') then
        return 'Pet (SMN)';
    end

    if (entityName == 'NPC/Object') then
        return 'Object';
    end

    return entityName;
end

function GetStorageEntity(entity)
    local entityName = NormalizeEntityName(entity or selectedEntity);

    if (entityName == 'Pet (DRG)') then
        return 'Wyvern';
    end

    if (entityName == 'Pet (PUP)') then
        return 'Automaton';
    end

    return entityName;
end

function NormalizeStateName(stateName)
    local name = tostring(stateName or '');

    if (name == 'Idle') then
        return 'World';
    end

    if (name == 'Combat') then
        return 'Tactical';
    end

    return name;
end

function GetStorageState(stateName)
    local name = NormalizeStateName(stateName or selectedState);

    if (name == 'World') then
        return 'Idle';
    end

    if (name == 'Tactical') then
        return 'Combat';
    end

    return name;
end

local GetEditWidgetsFor = nil;

function LibraPlatesSettingsCopyTable(value)
    if (type(value) ~= 'table') then
        return value;
    end

    local copy = {};

    for key, child in pairs(value) do
        copy[key] = LibraPlatesSettingsCopyTable(child);
    end

    return copy;
end

function LibraPlatesSettingsAddWidgetCopySource(sources, currentEntity, currentState, entity, stateName, widgetName)
    local storageEntity = GetStorageEntity(entity);
    local storageState = GetStorageState(stateName);
    local currentStorageEntity = GetStorageEntity(currentEntity);
    local currentStorageState = GetStorageState(currentState);
    local storageWidget = widgetKeys[tostring(widgetName or '')] or tostring(widgetName or '');
    local entityName = NormalizeEntityName(entity);
    local state = tostring(stateName or '');
    local entityStates = statesByEntity[entityName] or states;
    local hasState = false;

    if (storageWidget == nil or storageWidget == '') then
        return;
    end

    for _, item in ipairs(entityStates) do
        if (item == state) then
            hasState = true;
            break;
        end
    end

    if (storageEntity ~= nil and hasState ~= true) then
        return;
    end

    local targetWidgets = GetEditWidgetsFor(entity, stateName);
    local hasTargetWidget = false;

    for _, targetWidget in ipairs(targetWidgets) do
        local targetStorageWidget = widgetKeys[tostring(targetWidget or '')] or tostring(targetWidget or '');

        if (targetStorageWidget == storageWidget) then
            hasTargetWidget = true;
            break;
        end
    end

    if (hasTargetWidget ~= true) then
        return;
    end

    if (storageEntity == currentStorageEntity and storageState == currentStorageState) then
        return;
    end

    sources[#sources + 1] = {
        key = storageEntity .. '|' .. storageState .. '|' .. storageWidget,
        label = tostring(entity) .. ' > ' .. tostring(stateName),
        entity = storageEntity,
        state = storageState,
        widget = storageWidget,
    };
end

function LibraPlatesSettingsBuildWidgetCopySources(entity, stateName, widgetName)
    local sources = {};
    local storageWidget = widgetKeys[tostring(widgetName or '')] or tostring(widgetName or '');
    local normalizedState = NormalizeStateName(stateName);

    if (storageWidget == '' or storageWidget == nil) then
        return sources;
    end

    if (storageWidget == 'Target Module' or storageWidget == 'Subtarget Module') then
        for _, sourceEntity in ipairs(entities) do
            local sourceStates = statesByEntity[sourceEntity] or states;

            for _, sourceState in ipairs(sourceStates) do
                LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, sourceEntity, sourceState, storageWidget);
            end
        end

        return sources;
    end

    if (normalizedState == 'World') then
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, entity, 'Tactical', storageWidget);
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, 'Self', 'World', storageWidget);
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, 'Trust', 'World', storageWidget);
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, 'PC', 'World', storageWidget);
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, 'Enemy', 'World', storageWidget);
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, 'NPC', 'World', storageWidget);
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, 'Object', 'World', storageWidget);
    elseif (normalizedState == 'Tactical') then
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, entity, 'World', storageWidget);
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, 'Self', 'Tactical', storageWidget);
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, 'Trust', 'Tactical', storageWidget);
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, 'PC', 'Tactical', storageWidget);
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, 'Enemy', 'Tactical', storageWidget);
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, 'NPC', 'Tactical', storageWidget);
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, 'Object', 'Tactical', storageWidget);
    elseif (normalizedState == 'Resting' or normalizedState == 'Fishing' or normalizedState == 'Crafting' or normalizedState == 'Gathering') then
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, 'Self', 'World', storageWidget);
        LibraPlatesSettingsAddWidgetCopySource(sources, entity, stateName, 'Self', 'Tactical', storageWidget);
    end

    return sources;
end

function LibraPlatesSettingsBuildNameCopySources(entity, stateName)
    return LibraPlatesSettingsBuildWidgetCopySources(entity, stateName, 'Name');
end

function LibraPlatesSettingsCopySettingsFromSource(settings, source, defaults)
    if (settings == nil or source == nil) then
        return;
    end

    local sourceSettings = state.GetWidgetSettings(source.entity, source.state, source.widget, defaults or {});

    for key, _ in pairs(settings) do
        settings[key] = nil;
    end

    for key, value in pairs(sourceSettings) do
        settings[key] = LibraPlatesSettingsCopyTable(value);
    end

    state.Save();
end

function LibraPlatesSettingsCopyNameSettingsFromSource(settings, source)
    LibraPlatesSettingsCopySettingsFromSource(settings, source, nameDefaults);
end

function IsPetStorageEntity(entity)
    local entityName = tostring(entity or '');

    return (
        entityName == 'Pet (BST)' or
        entityName == 'Pet (SMN)' or
        entityName == 'Wyvern' or
        entityName == 'Automaton'
    );
end

function GetStates(entity)
    return statesByEntity[NormalizeEntityName(entity or selectedEntity)] or states;
end

function ListContains(list, value)
    for _, item in ipairs(list or {}) do
        if (item == value) then
            return true;
        end
    end

    return false;
end

GetEditWidgetsFor = function(entity, stateName)
    local entityName = NormalizeEntityName(entity or selectedEntity);
    local plateName = NormalizeStateName(stateName or selectedState);

    if (entityName == 'Self') then
        if (plateName == 'Tactical') then
            return selfCombatWidgets;
        end
        if (plateName == 'Resting') then
            return selfRestingWidgets;
        end
        if (plateName == 'Fishing') then
            return selfFishingWidgets;
        end
        if (plateName == 'Crafting') then
            return selfCraftingWidgets;
        end
        if (plateName == 'Gathering') then
            return selfGatheringWidgets;
        end

        return selfIdleWidgets;
    end

    if (entityName == 'Enemy') then
        if (plateName ~= 'World') then
            return enemyCombatWidgets;
        end

        return enemyIdleWidgets;
    end

    if (entityName == 'PC') then
        if (plateName ~= 'World') then
            return pcCombatWidgets;
        end

        return pcIdleWidgets;
    end

    if (entityName == 'Trust') then
        if (plateName ~= 'World') then
            return trustCombatWidgets;
        end

        return trustIdleWidgets;
    end

    if (entityName == 'Pet (BST)') then
        if (plateName == 'Jug Pet') then
            return bstJugPetWidgets;
        end

        return bstCharmedPetWidgets;
    end

    if (entityName == 'Pet (SMN)') then
        if (plateName == 'Spirit') then
            return spiritEditWidgets;
        end

        return avatarEditWidgets;
    end

    if (entityName == 'Pet (DRG)') then
        return wyvernEditWidgets;
    end

    if (entityName == 'Pet (PUP)') then
        return automatonEditWidgets;
    end

    if (entityName == 'NPC') then
        return npcEditWidgets;
    end

    if (entityName == 'Object') then
        return objectEditWidgets;
    end

    return editWidgets;
end

function GetEditWidgets()
    return GetEditWidgetsFor(selectedEntity, selectedState);
end

function GetModuleWidgets(entity, stateName)
    local list = T{};
    local seen = {};
    local names = {
        ['Peer (module)'] = 'Peer',
        ['Enmity (module)'] = 'Enmity',
        ['Resting (module)'] = 'Resting',
        ['Quick Menu (module)'] = 'Quick Menu',
        ['Mounted (module)'] = 'Mounted',
        ['Crafting (module)'] = 'Crafting',
        ['Fishing (module)'] = 'Fishing',
        ['Gathering (module)'] = 'Gathering',
        ['Death (module)'] = 'Death',
    };

    for _, widget in ipairs(GetEditWidgetsFor(entity, stateName)) do
        local moduleName = names[widget];

        if (moduleName ~= nil and seen[moduleName] ~= true) then
            seen[moduleName] = true;
            list[#list + 1] = moduleName;
        end
    end

    return list;
end

function IsAnchorableWidget(widgetName)
    widgetName = tostring(widgetName or '');

    if (widgetName == '' or widgetName == 'Target' or widgetName == 'Subtarget' or string.find(widgetName, '%(module%)') ~= nil) then
        return false;
    end

    if (widgetName == 'Maneuvers') then
        return false;
    end

    return true;
end

_G.LibraPlatesSettingsGetAnchorChoices = function(entityName, stateName, widgetName)
    local choices = { 'None' };

    for _, candidate in ipairs(GetEditWidgetsFor(entityName, stateName)) do
        if (candidate ~= widgetName and IsAnchorableWidget(candidate) == true) then
            choices[#choices + 1] = candidate;
        end
    end

    return choices;
end

function GetWidgetDefaults(widget)
    if (widget == 'Name') then return nameDefaults; end
    if (widget == 'AOE range (module)') then return aoeRangeDefaults; end
    if (widget == 'Background') then return backgroundDefaults; end
    if (widget == 'Job') then return jobDefaults; end
    if (widget == 'Level') then return levelDefaults; end
    if (widget == 'Distance') then return distanceDefaults; end
    if (widget == 'Type line') then return require('config.widgets.type_line'); end
    if (widget == 'Icon' or widget == 'NPC icon' or widget == 'Object icon') then return require('config.widgets.npc_object_icon'); end
    if (widget == 'ID') then return idDefaults; end
    if (widget == 'Buffs') then return buffsDefaults; end
    if (widget == 'Debuffs') then return debuffsDefaults; end
    if (widget == 'Game mode icon') then return gameModeIconDefaults; end
    if (widget == 'Bazaar icon') then return bazaarIconDefaults; end
    if (widget == 'Linkshell icon') then return linkshellIconDefaults; end
    if (widget == 'Away icon') then return awayIconDefaults; end
    if (widget == 'Disconnect icon') then return disconnectIconDefaults; end
    if (widget == 'Anon icon') then return anonIconDefaults; end
    if (widget == 'Follow icon') then return followIconDefaults; end
    if (widget == 'Party leader icon') then return require('config.widgets.party_leader_icon'); end
    if (widget == 'Alliance leader icon') then return require('config.widgets.alliance_leader_icon'); end
    if (widget == 'Stars icon') then return starsIconDefaults; end
    if (widget == 'Level sync icon') then return levelSyncIconDefaults; end
    if (widget == 'New adventurer icon') then return newAdventurerIconDefaults; end
    if (widget == 'HP Bar') then return barDefaults; end
    if (widget == 'MP Bar') then return mpBarDefaults; end
    if (widget == 'TP Bar') then return tpBarDefaults; end
    if (widget == 'Cast bar') then return castBarDefaults; end
    if (widget == 'Lock-on icon') then return targetModuleDefaults; end
    if (widget == 'Target' or widget == 'Target (module)') then return targetModuleDefaults; end
    if (widget == 'Subtarget' or widget == 'Subtarget (module)') then return subtargetModuleDefaults; end
    if (widget == 'Peer (module)') then return { enabled = true }; end
    if (widget == 'Quick Menu (module)') then return { enabled = true }; end
    if (widget == 'Pet timer') then return petTimerDefaults; end
    if (widget == 'Pet state') then return petStateDefaults; end
    if (widget == 'Ward timer') then return petWardBarDefaults; end
    if (widget == 'Rage timer') then return petRageBarDefaults; end
    if (widget == 'Sic' or widget == 'Ready bar') then return petReadyBarDefaults; end
    if (widget == 'Reward') then return petRewardBarDefaults; end
    if (widget == 'Maneuvers') then return maneuverDefaults; end

    return { enabled = false };
end

function GetChecklistActiveSettings(widget)
    local key = widgetKeys[widget];

    if (key == nil) then
        return nil;
    end

    if (widget == 'Enmity (module)') then
        local global = state.GetGlobalSettings(globalDefaults);
        global.enmity = global.enmity or {};
        if (global.enmity.enabled == nil) then global.enmity.enabled = true; end
        return global.enmity;
    end

    if (widget == 'Resting (module)') then
        local global = state.GetGlobalSettings(globalDefaults);
        global.resting = global.resting or {};
        if (global.resting.enabled == nil) then global.resting.enabled = true; end
        return global.resting;
    end
    if (widget == 'Fishing (module)') then
        local global = state.GetGlobalSettings(globalDefaults);
        global.fishing = global.fishing or {};
        if (global.fishing.enabled == nil) then global.fishing.enabled = true; end
        return global.fishing;
    end

    if (widget == 'Crafting (module)') then
        local global = state.GetGlobalSettings(globalDefaults);
        global.crafting = global.crafting or {};
        if (global.crafting.enabled == nil) then global.crafting.enabled = true; end
        return global.crafting;
    end

    if (widget == 'Quick Menu (module)') then
        return state.GetWidgetSettings(GetStorageEntity(selectedEntity), GetStorageState(selectedState), key, GetWidgetDefaults(widget));
    end

    return state.GetWidgetSettings(GetStorageEntity(selectedEntity), GetStorageState(selectedState), key, GetWidgetDefaults(widget));
end

function EnsureSelectedStateAllowed()
    local list = GetStates(selectedEntity);

    if (ListContains(list, selectedState) ~= true) then
        selectedState = list[1] or 'World';
    end
end

function EnsureSelectedWidgetAllowed()
    local list = GetEditWidgets();
    local entityName = NormalizeEntityName(selectedEntity);
    local stateName = NormalizeStateName(selectedState);

    if (ListContains(list, selectedWidget) ~= true) then
        selectedWidget = list[1] or 'Name';
    end
end

function EnsureSelectedModuleWidgetAllowed()
    local list = GetModuleWidgets(selectedModuleEntity, selectedModuleState);

    if (ListContains(list, selectedModuleWidget) ~= true) then
        selectedModuleWidget = list[1] or 'Target';
    end
end

function PersistUiSelection()
    local profile = state.GetProfile();

    profile.settingsUi = profile.settingsUi or {};
    profile.settingsUi.selectedTab = selectedTab;
    profile.settingsUi.selectedEntity = selectedEntity;
    profile.settingsUi.selectedState = selectedState;
    profile.settingsUi.selectedWidget = selectedWidget;
    profile.settingsUi.selectedModuleEntity = selectedModuleEntity;
    profile.settingsUi.selectedModuleState = selectedModuleState;
    profile.settingsUi.selectedModuleWidget = selectedModuleWidget;
    profile.settingsUi.selectedGeneralSection = selectedGeneralSection;
    profile.settingsUi.selectedTargetingSection = selectedTargetingSection;
end

function RestoreUiSelection()
    local profile = state.GetProfile();
    local saved = type(profile.settingsUi) == 'table' and profile.settingsUi or nil;

    if (saved == nil) then
        return;
    end

    if (ListContains(tabs, saved.selectedTab) == true) then
        selectedTab = saved.selectedTab;
    end

    if (ListContains(generalSections, saved.selectedGeneralSection) == true) then
        selectedGeneralSection = saved.selectedGeneralSection;
    end

    if (ListContains(targetingSections, saved.selectedTargetingSection) == true) then
        selectedTargetingSection = saved.selectedTargetingSection;
    end

    local savedEntity = NormalizeEntityName(saved.selectedEntity);

    if (ListContains(entities, savedEntity) == true) then
        selectedEntity = savedEntity;
    end

    local savedState = NormalizeStateName(saved.selectedState);

    if (ListContains(GetStates(selectedEntity), savedState) == true) then
        selectedState = savedState;
    end

    EnsureSelectedStateAllowed();

    if (ListContains(GetEditWidgets(), saved.selectedWidget) == true) then
        selectedWidget = saved.selectedWidget;
    end

    EnsureSelectedWidgetAllowed();

    local savedModuleEntity = NormalizeEntityName(saved.selectedModuleEntity);

    if (ListContains(moduleEntities, savedModuleEntity) == true) then
        selectedModuleEntity = savedModuleEntity;
    end

    local savedModuleState = NormalizeStateName(saved.selectedModuleState);

    if (ListContains(GetStates(selectedModuleEntity), savedModuleState) == true) then
        selectedModuleState = savedModuleState;
    else
        local moduleStates = GetStates(selectedModuleEntity);
        selectedModuleState = moduleStates[1] or 'World';
    end

    if (ListContains(GetModuleWidgets(selectedModuleEntity, selectedModuleState), saved.selectedModuleWidget) == true) then
        selectedModuleWidget = saved.selectedModuleWidget;
    end

    EnsureSelectedModuleWidgetAllowed();
end

function GetContentRegionAvail()
    if (imgui.GetContentRegionAvail == nil) then
        return 760, 420;
    end

    local availA, availB = imgui.GetContentRegionAvail();

    if (type(availA) == 'table') then
        return tonumber(availA.x or availA[1]) or 760, tonumber(availA.y or availA[2]) or 420;
    end

    return tonumber(availA) or 760, tonumber(availB) or 420;
end

function GetImguiColor(name)
    return rawget(_G, 'ImGuiCol_' .. name) or (imgui.Col ~= nil and imgui.Col[name]) or imgui['Col_' .. name];
end

function PushSettingsAccentStyle()
    if (imgui.PushStyleColor == nil) then
        return 0;
    end

    local count = 0;
function push(name, color)
        local colorId = GetImguiColor(name);

        if (colorId ~= nil) then
            local ok = pcall(imgui.PushStyleColor, colorId, color);

            if (ok == true) then
                count = count + 1;
            end
        end
    end

    push('TitleBg', { uiAccent[1], uiAccent[2], uiAccent[3], 0.75 });
    push('TitleBgActive', { uiAccent[1], uiAccent[2], uiAccent[3], 0.95 });
    push('TitleBgCollapsed', { uiAccent[1], uiAccent[2], uiAccent[3], 0.60 });
    push('Button', { uiAccent[1], uiAccent[2], uiAccent[3], 0.70 });
    push('ButtonHovered', { uiAccentHovered[1], uiAccentHovered[2], uiAccentHovered[3], 0.88 });
    push('ButtonActive', uiAccentActive);
    push('Tab', { uiAccent[1], uiAccent[2], uiAccent[3], 0.46 });
    push('TabHovered', { uiAccentHovered[1], uiAccentHovered[2], uiAccentHovered[3], 0.78 });
    push('TabActive', { uiAccentActive[1], uiAccentActive[2], uiAccentActive[3], 0.95 });
    push('TabUnfocused', { uiAccent[1], uiAccent[2], uiAccent[3], 0.28 });
    push('TabUnfocusedActive', { uiAccentActive[1], uiAccentActive[2], uiAccentActive[3], 0.70 });
    push('CheckMark', uiAccent);
    push('SliderGrab', uiAccent);
    push('SliderGrabActive', uiAccentHovered);
    push('FrameBgHovered', { uiAccent[1], uiAccent[2], uiAccent[3], 0.25 });
    push('FrameBgActive', { uiAccent[1], uiAccent[2], uiAccent[3], 0.35 });
    push('Header', { uiAccent[1], uiAccent[2], uiAccent[3], 0.38 });
    push('HeaderHovered', { uiAccentHovered[1], uiAccentHovered[2], uiAccentHovered[3], 0.55 });
    push('HeaderActive', { uiAccentActive[1], uiAccentActive[2], uiAccentActive[3], 0.72 });
    push('ScrollbarGrab', { uiAccent[1], uiAccent[2], uiAccent[3], 0.70 });
    push('ScrollbarGrabHovered', { uiAccentHovered[1], uiAccentHovered[2], uiAccentHovered[3], 0.86 });
    push('ScrollbarGrabActive', uiAccentActive);
    push('ResizeGrip', { uiAccent[1], uiAccent[2], uiAccent[3], 0.40 });
    push('ResizeGripHovered', { uiAccentHovered[1], uiAccentHovered[2], uiAccentHovered[3], 0.70 });
    push('ResizeGripActive', uiAccentActive);
    push('SeparatorHovered', uiAccentHovered);
    push('SeparatorActive', uiAccentActive);

    return count;
end

function PopSettingsAccentStyle(count)
    count = tonumber(count) or 0;

    if (count > 0 and imgui.PopStyleColor ~= nil) then
        pcall(imgui.PopStyleColor, count);
    end
end

function GetCursorScreenPos()
    if (imgui.GetCursorScreenPos == nil) then
        return 0, 0;
    end

    local posA, posB = imgui.GetCursorScreenPos();

    if (type(posA) == 'table') then
        return tonumber(posA.x or posA[1]) or 0, tonumber(posA.y or posA[2]) or 0;
    end

    return tonumber(posA) or 0, tonumber(posB) or 0;
end

function GetSplitterArrowTextureId()
    if (splitterArrowTextureId ~= nil) then
        return splitterArrowTextureId;
    end

    splitterArrowTextureId = textureLoader.ToTextureId(textureLoader.Load(addon.path .. '\\assets\\images\\up_down_arrows.png'));
    return splitterArrowTextureId;
end

-- ============================================================
-- Selection helpers
-- ============================================================

function DrawButtonList(items, selected, onSelect)
    for _, item in ipairs(items) do
        local label = tostring(item or '');
        local color = { 0.92, 0.92, 0.90, 1.0 };
        local isSelected = tostring(item or '') == tostring(selected or '');

        if (isSelected == true) then
            color = { 1.0, 1.0, 1.0, 1.0 };
        end

        if (DrawSelectableRow(label, isSelected, color, 'button_list_' .. label) == true) then
            onSelect(item);
        end
    end
end

function DrawSelectableRow(label, selected, color, id)
    local display = tostring(label or '');
    local itemId = tostring(id or display);
    local textColor = color or { 0.92, 0.92, 0.90, 1.0 };
    local pushed = 0;
    local clicked = false;

    if (imgui.Selectable ~= nil) then
        if (imgui.PushStyleColor ~= nil and GetImguiColor ~= nil) then
            local textIndex = GetImguiColor('Text');

            if (textIndex ~= nil) then
                imgui.PushStyleColor(textIndex, textColor);
                pushed = pushed + 1;
            end
        end

        clicked = imgui.Selectable(display .. '##' .. itemId, selected == true) == true;

        if (pushed > 0 and imgui.PopStyleColor ~= nil) then
            imgui.PopStyleColor(pushed);
        end

        return clicked;
    end

    imgui.TextColored(textColor, (selected == true and '> ' or '') .. display);

    return imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true;
end

function DrawCombo(label, items, selected, onSelect)
    DrawYellowHeader(label);
    imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, '[' .. selected .. ' v]');

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        if (openDropdown == label) then
            openDropdown = nil;
        else
            openDropdown = label;
        end
    end

    if (openDropdown == label) then
        for _, item in ipairs(items) do
            local isSelected = tostring(item or '') == tostring(selected or '');
            local itemLabel = tostring(item or '');
            local color = { 0.92, 0.92, 0.90, 1.0 };

            if (isSelected == true) then
                color = { 1.0, 1.0, 1.0, 1.0 };
            end

            if (DrawSelectableRow(itemLabel, isSelected, color, tostring(label) .. '_' .. itemLabel) == true) then
                onSelect(item);
                openDropdown = nil;
            end
        end
    end
end

function DrawInlineCombo(label, items, selected, onSelect)
    local current = tostring(selected or items[1] or 'Default');

    DrawYellowHeader(label);

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(242);
        end

        if (imgui.BeginCombo('##' .. label, current) == true) then
            for _, item in ipairs(items) do
                local isSelected = (item == current);

                if (imgui.Selectable(tostring(item), isSelected) == true) then
                    onSelect(item);
                end

                if (isSelected == true and imgui.SetItemDefaultFocus ~= nil) then
                    imgui.SetItemDefaultFocus();
                end
            end

            imgui.EndCombo();
        end

        if (imgui.PopItemWidth ~= nil) then
            imgui.PopItemWidth();
        end

        return;
    end

    DrawCombo(label, items, current, onSelect);
end

function DrawInlineComboRow(label, items, selected, onSelect, id, labelColorOverride, labelWidth)
    local current = tostring(selected or items[1] or 'Default');
    local comboId = '##' .. tostring(id or label or 'combo');

function DrawControl()
        if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
            if (imgui.PushItemWidth ~= nil) then
                imgui.PushItemWidth(260);
            end

            if (imgui.BeginCombo(comboId, current) == true) then
                for _, item in ipairs(items) do
                    local isSelected = (item == current);

                    if (imgui.Selectable(tostring(item), isSelected) == true) then
                        onSelect(item);
                    end

                    if (isSelected == true and imgui.SetItemDefaultFocus ~= nil) then
                        imgui.SetItemDefaultFocus();
                    end
                end

                imgui.EndCombo();
            end

            if (imgui.PopItemWidth ~= nil) then
                imgui.PopItemWidth();
            end

            return;
        end

        imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, '[' .. current .. ' v]');

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            if (openDropdown == comboId) then
                openDropdown = nil;
            else
                openDropdown = comboId;
            end
        end
    end

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##settings_combo_' .. tostring(id or label or 'combo'), 2, settingsTableFlags)) then
            imgui.TableSetupColumn('##label', 0, tonumber(labelWidth) or 78);
            imgui.TableSetupColumn('##control', 0, 260);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColorOverride or { 1.0, 0.84, 0.0, 1.0 }, label);
            imgui.TableNextColumn();
            DrawControl();
            imgui.EndTable();
        end
    else
        imgui.TextColored(labelColorOverride or { 1.0, 0.84, 0.0, 1.0 }, label);
        imgui.SameLine();
        DrawControl();
    end

    if (openDropdown == comboId) then
        for _, item in ipairs(items) do
            local isSelected = tostring(item or '') == tostring(current or '');
            local itemLabel = tostring(item or '');
            local color = { 0.92, 0.92, 0.90, 1.0 };

            if (isSelected == true) then
                color = { 1.0, 1.0, 1.0, 1.0 };
            end

            if (DrawSelectableRow(itemLabel, isSelected, color, tostring(comboId) .. '_' .. itemLabel) == true) then
                onSelect(item);
                openDropdown = nil;
            end
        end
    end
end

function DrawCheckbox(label, value, onChange)
    local ref = { value == true };

    if (imgui.Checkbox ~= nil) then
        if (imgui.Checkbox(label, ref) == true) then
            onChange(ref[1] == true);
        end

        return;
    end

    imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, '[' .. (value == true and 'x' or ' ') .. '] ' .. label);

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        onChange(value ~= true);
    end
end

function DrawSliderTenths(label, value, minTenths, maxTenths, onChange)
    local ref = { tonumber(value) or 0 };

    if (imgui.SliderFloat ~= nil) then
        if (imgui.SliderFloat(label, ref, (tonumber(minTenths) or 0) / 10, (tonumber(maxTenths) or 100) / 10, '%.1f') == true) then
            onChange(math.floor(((tonumber(ref[1]) or 0) * 10) + 0.5) / 10);
        end

        imgui.SameLine();
        imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, string.format('%.1f', tonumber(ref[1]) or 0));
        return;
    end

    imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, label .. ' ' .. string.format('%.1f', tonumber(value) or 0));
end

function LibraPlatesSettingsGetTieredSliderLabel(value, tiers)
    local number = tonumber(value) or 0;
    local fallback = nil;

    for _, tier in ipairs(tiers or {}) do
        fallback = tier;

        if (number <= (tonumber(tier.max) or number)) then
            return tostring(tier.label or ''), tier.color or { 0.92, 0.92, 0.90, 1.0 };
        end
    end

    if (fallback ~= nil) then
        return tostring(fallback.label or ''), fallback.color or { 0.92, 0.92, 0.90, 1.0 };
    end

    return '', { 0.92, 0.92, 0.90, 1.0 };
end

function LibraPlatesSettingsDrawTieredSliderTenths(label, value, minTenths, maxTenths, tiers, onChange)
    local ref = { tonumber(value) or 0 };

    if (
        imgui.SliderFloat == nil or
        imgui.GetWindowDrawList == nil or
        imgui.GetColorU32 == nil
    ) then
        DrawSliderTenths(label, value, minTenths, maxTenths, onChange);
        return;
    end

    imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, label);
    imgui.SameLine();

    local sliderWidth = 210;
    local x, y = GetCursorScreenPos();
    local drawList = imgui.GetWindowDrawList();
    local barY = y + 3;
    local barH = 14;
    local minValue = tonumber(minTenths) or 0;
    local maxValue = tonumber(maxTenths) or 100;
    local span = math.max(1, maxValue - minValue);

    for _, tier in ipairs(tiers or {}) do
        local tierMin = math.max(minValue, tonumber(tier.min) or minValue);
        local tierMax = math.min(maxValue, tonumber(tier.max) or maxValue);

        if (tierMax > tierMin) then
            local x1 = x + ((tierMin - minValue) / span) * sliderWidth;
            local x2 = x + ((tierMax - minValue) / span) * sliderWidth;
            drawList:AddRectFilled(
                { x1, barY },
                { x2, barY + barH },
                imgui.GetColorU32(tier.color or { 0.30, 0.80, 0.35, 0.55 })
            );
        end
    end

    if (imgui.PushItemWidth ~= nil) then
        imgui.PushItemWidth(sliderWidth);
    end

    if (imgui.SliderFloat('##' .. tostring(label):gsub('%s+', '_') .. '_tiered', ref, minValue / 10, maxValue / 10, '%.1f') == true) then
        onChange(math.floor(((tonumber(ref[1]) or 0) * 10) + 0.5) / 10);
    end

    if (imgui.PopItemWidth ~= nil) then
        imgui.PopItemWidth();
    end

    imgui.SameLine();
    imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, string.format('%.1f', tonumber(ref[1]) or 0));

    local tierLabel, tierColor = LibraPlatesSettingsGetTieredSliderLabel((tonumber(ref[1]) or 0) * 10, tiers);

    if (tierLabel ~= '') then
        imgui.SameLine();
        imgui.TextColored(tierColor, tierLabel);
    end
end

local DrawPlacementControl = nil;
local DrawPlacementSingle = nil;

function DrawSettingsColor(label, value, id)
    local color = value or { 1.0, 1.0, 1.0, 1.0 };
    local changed = false;

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##settings_color_' .. tostring(id or label), 2, settingsTableFlags)) then
            imgui.TableSetupColumn('##label', 0, 78);
            imgui.TableSetupColumn('##control', 0, 175);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, label);
            imgui.TableNextColumn();

            if (imgui.ColorEdit4 ~= nil) then
                changed = imgui.ColorEdit4('##' .. tostring(id or label), color, settingsColorEditFlags) == true;
            else
                imgui.TextColored(color, 'sample');
            end

            imgui.EndTable();
        end

        return color, changed;
    end

    imgui.TextColored(settingsLabelColor, label);
    imgui.SameLine();

    if (imgui.ColorEdit4 ~= nil) then
        changed = imgui.ColorEdit4('##' .. tostring(id or label), color, settingsColorEditFlags) == true;
    else
        imgui.TextColored(color, 'sample');
    end

    return color, changed;
end

function CopyColor(value, fallback)
    local source = value or fallback or { 1.0, 1.0, 1.0, 1.0 };

    return {
        tonumber(source[1]) or 1.0,
        tonumber(source[2]) or 1.0,
        tonumber(source[3]) or 1.0,
        tonumber(source[4]) or 1.0,
    };
end

function DrawInlineColorControl(value, id)
    local color = CopyColor(value);

    if (imgui.ColorEdit4 ~= nil) then
        return color, imgui.ColorEdit4('##' .. tostring(id or 'color'), color, settingsColorEditFlags) == true;
    end

    imgui.TextColored(color, 'sample');
    return color, false;
end

function DrawPeerFontRow(peer, prefix, label)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##peer_font_row_' .. tostring(label), 4, settingsTableFlags)) then
            imgui.TableSetupColumn('##font_size_label', 0, 112);
            imgui.TableSetupColumn('##font_size_control', 0, 160);
            imgui.TableSetupColumn('##font_color_label', 0, 112);
            imgui.TableSetupColumn('##font_color_control', 0, 60);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, 'Font size');
            imgui.TableNextColumn();
            local fontSize, fontSizeChanged = DrawPlacementControl(textScale.NormalizeSetting(peer[prefix .. 'FontSize'], 12), textScale.GetMinVisualSize(), textScale.GetMaxVisualSize(), 1, 'Peer' .. label .. 'FontSize');
            if (fontSizeChanged == true) then
                peer[prefix .. 'FontSize'] = fontSize;
                state.Save();
            end
            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, 'Font color');
            imgui.TableNextColumn();
            local textColor, textColorChanged = DrawInlineColorControl(peer[prefix .. 'Color'], 'Peer' .. label .. 'Color');
            peer[prefix .. 'Color'] = textColor;
            if (textColorChanged == true) then state.Save(); end
            imgui.EndTable();
        end

        return;
    end

    local fontSize, fontSizeChanged = DrawPlacementSingle('Font size', textScale.NormalizeSetting(peer[prefix .. 'FontSize'], 12), 'Peer' .. label .. 'FontSize', textScale.GetMinVisualSize(), textScale.GetMaxVisualSize(), 1);
    if (fontSizeChanged == true) then
        peer[prefix .. 'FontSize'] = fontSize;
        state.Save();
    end

    local textColor, textColorChanged = DrawSettingsColor('Font color', peer[prefix .. 'Color'], 'Peer' .. label .. 'Color');
    peer[prefix .. 'Color'] = textColor;
    if (textColorChanged == true) then state.Save(); end
end

function DrawPeerOutlineRow(peer, prefix, label)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##peer_outline_row_' .. tostring(label), 4, settingsTableFlags)) then
            imgui.TableSetupColumn('##outline_size_label', 0, 112);
            imgui.TableSetupColumn('##outline_size_control', 0, 160);
            imgui.TableSetupColumn('##outline_color_label', 0, 112);
            imgui.TableSetupColumn('##outline_color_control', 0, 60);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, 'Outline size');
            imgui.TableNextColumn();
            local outlineSize, outlineSizeChanged = DrawPlacementControl(peer[prefix .. 'OutlineSize'], 0, 12, 1, 'Peer' .. label .. 'OutlineSize');
            if (outlineSizeChanged == true) then
                peer[prefix .. 'OutlineSize'] = outlineSize;
                state.Save();
            end
            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, 'Outline color');
            imgui.TableNextColumn();
            local outlineColor, outlineColorChanged = DrawInlineColorControl(peer[prefix .. 'OutlineColor'], 'Peer' .. label .. 'OutlineColor');
            peer[prefix .. 'OutlineColor'] = outlineColor;
            if (outlineColorChanged == true) then state.Save(); end
            imgui.EndTable();
        end

        return;
    end

    local outlineSize, outlineSizeChanged = DrawPlacementSingle('Outline size', peer[prefix .. 'OutlineSize'], 'Peer' .. label .. 'OutlineSize', 0, 12, 1);
    if (outlineSizeChanged == true) then
        peer[prefix .. 'OutlineSize'] = outlineSize;
        state.Save();
    end

    local outlineColor, outlineColorChanged = DrawSettingsColor('Outline color', peer[prefix .. 'OutlineColor'], 'Peer' .. label .. 'OutlineColor');
    peer[prefix .. 'OutlineColor'] = outlineColor;
    if (outlineColorChanged == true) then state.Save(); end
end

function DrawColorAndPlacementRow(leftLabel, colorValue, colorId, rightLabel, rightValue, rightId, minValue, maxValue, step)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local colorResult = colorValue;
        local valueResult = rightValue;
        local colorChanged = false;
        local valueChanged = false;

        if (imgui.BeginTable('##settings_color_placement_' .. tostring(colorId) .. '_' .. tostring(rightId), 4, settingsTableFlags)) then
            imgui.TableSetupColumn('##color_label', 0, 112);
            imgui.TableSetupColumn('##color_control', 0, 60);
            imgui.TableSetupColumn('##value_label', 0, 112);
            imgui.TableSetupColumn('##value_control', 0, 160);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, leftLabel);
            imgui.TableNextColumn();
            colorResult, colorChanged = DrawInlineColorControl(colorValue, colorId);
            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, rightLabel);
            imgui.TableNextColumn();
            valueResult, valueChanged = DrawPlacementControl(rightValue, minValue, maxValue, step, rightId);
            imgui.EndTable();
        end

        return colorResult, colorChanged, valueResult, valueChanged;
    end

    local colorResult, colorChanged = DrawSettingsColor(leftLabel, colorValue, colorId);
    local valueResult, valueChanged = DrawPlacementSingle(rightLabel, rightValue, rightId, minValue, maxValue, step);

    return colorResult, colorChanged, valueResult, valueChanged;
end

function DrawPlacementAndColorRow(leftLabel, leftValue, leftId, minValue, maxValue, step, rightLabel, colorValue, colorId)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local valueResult = leftValue;
        local colorResult = colorValue;
        local valueChanged = false;
        local colorChanged = false;

        if (imgui.BeginTable('##settings_placement_color_' .. tostring(leftId) .. '_' .. tostring(colorId), 4, settingsTableFlags)) then
            imgui.TableSetupColumn('##value_label', 0, 122);
            imgui.TableSetupColumn('##value_control', 0, 124);
            imgui.TableSetupColumn('##color_label', 0, 112);
            imgui.TableSetupColumn('##color_control', 0, 60);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, leftLabel);
            imgui.TableNextColumn();
            valueResult, valueChanged = DrawPlacementControl(leftValue, minValue, maxValue, step, leftId, 58);
            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, rightLabel);
            imgui.TableNextColumn();
            colorResult, colorChanged = DrawInlineColorControl(colorValue, colorId);
            imgui.EndTable();
        end

        return valueResult, valueChanged, colorResult, colorChanged;
    end

    local valueResult, valueChanged = DrawPlacementSingle(leftLabel, leftValue, leftId, minValue, maxValue, step);
    local colorResult, colorChanged = DrawSettingsColor(rightLabel, colorValue, colorId);

    return valueResult, valueChanged, colorResult, colorChanged;
end

function ClickText(label, color)
    imgui.TextColored(color or { 0.92, 0.92, 0.90, 1.0 }, label);
    return imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true;
end

function DrawNumber(label, value, minValue, maxValue, step)
    local current = tonumber(value) or 0;
    local changed = false;
    step = tonumber(step) or 1;

    if (minValue ~= nil) then current = math.max(tonumber(minValue) or current, current); end
    if (maxValue ~= nil) then current = math.min(tonumber(maxValue) or current, current); end

    imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, label .. ' ' .. tostring(current));
    imgui.SameLine();

    if (ClickText('less', { 1.0, 0.84, 0.0, 1.0 }) == true) then
        current = current - step;
        changed = true;
    end

    imgui.SameLine();

    if (ClickText('more', { 1.0, 0.84, 0.0, 1.0 }) == true) then
        current = current + step;
        changed = true;
    end

    if (minValue ~= nil) then current = math.max(tonumber(minValue) or current, current); end
    if (maxValue ~= nil) then current = math.min(tonumber(maxValue) or current, current); end

    return current, changed;
end

function IsHeldButton(label)
    if (imgui.Button == nil) then
        return false;
    end

    local clicked = imgui.Button(label) == true;
    local active = imgui.IsItemActive ~= nil and imgui.IsItemActive() == true;
    local mouseDown = imgui.IsMouseDown == nil or imgui.IsMouseDown(0) == true;
    local now = os.clock();
    local key = tostring(label or '');

    if (active == true and mouseDown == true) then
        local itemClicked = (imgui.IsItemActivated ~= nil and imgui.IsItemActivated() == true)
            or (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true);
        local state = heldButtonState[key];

        if (state == nil) then
            state = { nextRepeat = now + 0.35, clicked = false };
            heldButtonState[key] = state;
        end

        if ((clicked == true or itemClicked == true) and state.clicked ~= true) then
            state.clicked = true;
            return true;
        end

        if (now >= (tonumber(state.nextRepeat) or now + 0.35)) then
            state.nextRepeat = now + 0.08;
            return true;
        end

        return false;
    end

    if (heldButtonState[key] ~= nil) then
        heldButtonState[key] = nil;
        return false;
    end

    return clicked;
end

function DrawPlacementNumber(label, value, minValue, maxValue, step, id)
    local current = tonumber(value) or 0;
    local original = current;
    local minimum = tonumber(minValue) or -1000;
    local maximum = tonumber(maxValue) or 1000;
    local amount = tonumber(step) or 1;

    current = math.max(minimum, math.min(maximum, current));

    local itemId = tostring(id or label);

    imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, label);
    imgui.SameLine();

    if (imgui.Button ~= nil and IsHeldButton('-##' .. itemId .. 'Minus') == true) then
        current = current - amount;
    elseif (imgui.Button == nil and ClickText('-', { 1.0, 0.84, 0.0, 1.0 }) == true) then
        current = current - amount;
    end

    imgui.SameLine();

    if (amount < 1 and imgui.SliderFloat ~= nil) then
        local ref = { current };
        if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(90); end
        if (imgui.SliderFloat('##' .. itemId, ref, minimum, maximum) == true) then
            current = tonumber(ref[1]) or current;
        end
        if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
    elseif (amount >= 1 and imgui.SliderInt ~= nil) then
        local ref = { math.floor(current + 0.5) };
        if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(90); end
        if (imgui.SliderInt('##' .. itemId, ref, minimum, maximum) == true) then
            current = tonumber(ref[1]) or current;
        end
        if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
    else
        imgui.TextColored({ 0.65, 0.90, 1.0, 1.0 }, tostring(current));
    end

    imgui.SameLine();

    if (imgui.Button ~= nil and IsHeldButton('+##' .. itemId .. 'Plus') == true) then
        current = current + amount;
    elseif (imgui.Button == nil and ClickText('+', { 1.0, 0.84, 0.0, 1.0 }) == true) then
        current = current + amount;
    end

    current = math.max(minimum, math.min(maximum, current));

    return current, current ~= original;
end

DrawPlacementControl = function(value, minValue, maxValue, step, id, sliderWidth)
    local current = tonumber(value) or 0;
    local original = current;
    local minimum = tonumber(minValue) or -1000;
    local maximum = tonumber(maxValue) or 1000;
    local amount = tonumber(step) or 1;
    local itemId = tostring(id or 'placement');

    current = math.max(minimum, math.min(maximum, current));

    if (imgui.Button ~= nil and IsHeldButton('-##' .. itemId .. 'Minus') == true) then
        current = current - amount;
    elseif (imgui.Button == nil and ClickText('-', { 1.0, 0.84, 0.0, 1.0 }) == true) then
        current = current - amount;
    end

    imgui.SameLine();

    if (imgui.InputText ~= nil) then
        local ref = { amount < 1 and tostring(current) or tostring(math.floor(current + 0.5)) };
        if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(tonumber(sliderWidth) or 70); end
        if (imgui.InputText('##' .. itemId, ref, 16) == true) then
            current = tonumber(ref[1]) or current;
        end
        if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
    elseif (amount < 1 and imgui.SliderFloat ~= nil) then
        local ref = { current };
        if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(tonumber(sliderWidth) or 90); end
        if (imgui.SliderFloat('##' .. itemId, ref, minimum, maximum) == true) then
            current = tonumber(ref[1]) or current;
        end
        if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
    elseif (amount >= 1 and imgui.SliderInt ~= nil) then
        local ref = { math.floor(current + 0.5) };
        if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(tonumber(sliderWidth) or 90); end
        if (imgui.SliderInt('##' .. itemId, ref, minimum, maximum) == true) then
            current = tonumber(ref[1]) or current;
        end
        if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
    else
        imgui.TextColored({ 0.65, 0.90, 1.0, 1.0 }, tostring(current));
    end

    imgui.SameLine();

    if (imgui.Button ~= nil and IsHeldButton('+##' .. itemId .. 'Plus') == true) then
        current = current + amount;
    elseif (imgui.Button == nil and ClickText('+', { 1.0, 0.84, 0.0, 1.0 }) == true) then
        current = current + amount;
    end

    current = math.max(minimum, math.min(maximum, current));

    return current, current ~= original;
end

function DrawPlacementPair(leftLabel, leftValue, leftId, rightLabel, rightValue, rightId, minValue, maxValue, step)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local leftResult = leftValue;
        local rightResult = rightValue;
        local leftChanged = false;
        local rightChanged = false;

        if (imgui.BeginTable('##settings_placement_' .. tostring(leftId) .. '_' .. tostring(rightId), 4, settingsTableFlags)) then
            imgui.TableSetupColumn('##label_left', 0, 104);
            imgui.TableSetupColumn('##control_left', 0, 124);
            imgui.TableSetupColumn('##label_right', 0, 104);
            imgui.TableSetupColumn('##control_right', 0, 124);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, leftLabel);
            imgui.TableNextColumn();
            leftResult, leftChanged = DrawPlacementControl(leftValue, minValue, maxValue, step, leftId, 58);
            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, rightLabel);
            imgui.TableNextColumn();
            rightResult, rightChanged = DrawPlacementControl(rightValue, minValue, maxValue, step, rightId, 58);
            imgui.EndTable();
        end

        return leftResult, leftChanged, rightResult, rightChanged;
    end

    local value, changed = DrawPlacementNumber(leftLabel, leftValue, minValue, maxValue, step, leftId);
    imgui.SameLine();
    local secondValue, secondChanged = DrawPlacementNumber(rightLabel, rightValue, minValue, maxValue, step, rightId);

    return value, changed, secondValue, secondChanged;
end

DrawPlacementSingle = function(label, value, id, minValue, maxValue, step, labelWidth, controlWidth, sliderWidth)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local result = value;
        local changed = false;

        if (imgui.BeginTable('##settings_placement_' .. tostring(id), 2, settingsTableFlags)) then
            imgui.TableSetupColumn('##label', 0, tonumber(labelWidth) or 122);
            imgui.TableSetupColumn('##control', 0, tonumber(controlWidth) or 124);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, label);
            imgui.TableNextColumn();
            result, changed = DrawPlacementControl(value, minValue, maxValue, step, id, tonumber(sliderWidth) or 58);
            imgui.EndTable();
        end

        return result, changed;
    end

    return DrawPlacementNumber(label, value, minValue, maxValue, step, id);
end

function LibraPlatesSettingsDrawPlateClickBlocking(settings)
    DrawCheckbox('Prevent clicks behind addon UI', settings.blockPlateClicksWhenImguiCapturesMouse == true, function(value)
        settings.blockPlateClicksWhenImguiCapturesMouse = value == true;
    end);

    DrawCheckbox('Use screen no-go zones', settings.plateClickNoGoZonesEnabled == true, function(value)
        settings.plateClickNoGoZonesEnabled = value == true;
    end);

    DrawCheckbox('Show no-go zones', settings.plateClickNoGoZonesVisible == true, function(value)
        settings.plateClickNoGoZonesVisible = value == true;
    end);

    uiTooltip.Info('LibraPlates ignores plate clicks inside active screen rectangles so UI clicks do not target plates behind chat, bars, or menus.');

    if (type(settings.plateClickNoGoZones) ~= 'table') then
        settings.plateClickNoGoZones = {};
    end

    for index = 1, 4 do
        local zone = settings.plateClickNoGoZones[index];

        if (type(zone) ~= 'table') then
            zone = {};
            settings.plateClickNoGoZones[index] = zone;
        end

        local name = zone.name;
        if (name == nil) then
            name = ({ 'Chat', 'Bottom bar', 'Right UI', 'Left UI' })[index] or ('Zone ' .. tostring(index));
            zone.name = name;
        end

        if (zone.enabled == nil) then zone.enabled = false; end
        if (zone.x == nil) then zone.x = ({ 0, 760, 1920, 0 })[index] or 0; end
        if (zone.y == nil) then zone.y = ({ 960, 1160, 0, 0 })[index] or 0; end
        if (zone.width == nil) then zone.width = ({ 760, 1160, 640, 360 })[index] or 100; end
        if (zone.height == nil) then zone.height = ({ 480, 280, 1440, 960 })[index] or 100; end
        if (type(zone.color) ~= 'table') then
            zone.color = ({ { 1.0, 0.15, 0.15, 1.0 }, { 0.15, 0.75, 1.0, 1.0 }, { 1.0, 0.80, 0.10, 1.0 }, { 0.40, 1.0, 0.25, 1.0 } })[index] or { 1.0, 0.15, 0.15, 1.0 };
        end

        imgui.Separator();
        DrawCheckbox(tostring(name), zone.enabled == true, function(value)
            zone.enabled = value == true;
        end);

        imgui.TextColored(settingsLabelColor, 'Color');
        imgui.SameLine();
        local color, colorChanged = DrawInlineColorControl(zone.color, 'PlateClickNoGoColor' .. tostring(index));
        zone.color = color;
        zone.color[4] = 1.0;

        local prefix = 'PlateClickNoGo' .. tostring(index);
        local x, xChanged, y, yChanged = DrawPlacementPair('X', zone.x, prefix .. 'X', 'Y', zone.y, prefix .. 'Y', 0, 4000, 1);
        if (xChanged == true) then zone.x = x; end
        if (yChanged == true) then zone.y = y; end

        local width, widthChanged, height, heightChanged = DrawPlacementPair('Width', zone.width, prefix .. 'Width', 'Height', zone.height, prefix .. 'Height', 1, 4000, 1);
        if (widthChanged == true) then zone.width = width; end
        if (heightChanged == true) then zone.height = height; end
    end

    if (settings.plateClickNoGoZonesVisible == true and imgui.GetForegroundDrawList ~= nil) then
        local drawList = imgui.GetForegroundDrawList();

        if (drawList ~= nil) then
            for index = 1, 4 do
                local zone = settings.plateClickNoGoZones[index];

                if (type(zone) == 'table' and zone.enabled == true) then
                    local x = tonumber(zone.x) or 0;
                    local y = tonumber(zone.y) or 0;
                    local width = math.max(1, tonumber(zone.width) or 1);
                    local height = math.max(1, tonumber(zone.height) or 1);
                    local label = tostring(zone.name or ('Zone ' .. tostring(index)));
                    local color = zone.color or { 1.0, 0.15, 0.15, 1.0 };
                    local fillColor = imgui.GetColorU32 ~= nil and imgui.GetColorU32({ color[1] or 1.0, color[2] or 0.15, color[3] or 0.15, 0.42 }) or 0xAA0000FF;
                    local borderColor = imgui.GetColorU32 ~= nil and imgui.GetColorU32({ color[1] or 1.0, color[2] or 0.15, color[3] or 0.15, 1.0 }) or 0xFF0000FF;
                    local textColor = imgui.GetColorU32 ~= nil and imgui.GetColorU32({ 1.0, 1.0, 1.0, 1.0 }) or 0xFFFFFFFF;

                    drawList:AddRectFilled({ x, y }, { x + width, y + height }, fillColor);
                    drawList:AddRect({ x, y }, { x + width, y + height }, borderColor, 0, 0, 4);

                    if (drawList.AddText ~= nil) then
                        drawList:AddText({ x + 6, y + 6 }, textColor, label);
                    end
                end
            end
        end
    end
end

function LibraPlatesSettingsDrawPerformanceSafety(settings)
    DrawCheckbox('Performance safety mode', settings.performanceSafetyMode == true, function(value)
        settings.performanceSafetyMode = value == true;
    end);

    DrawCheckbox('Only while engaged', settings.performanceSafetyCombatOnly ~= false, function(value)
        settings.performanceSafetyCombatOnly = value == true;
    end);

    DrawCheckbox('Combat: target/subtarget/engaged enemies only', settings.performanceSafetyImportantEnemiesOnly == true, function(value)
        settings.performanceSafetyImportantEnemiesOnly = value == true;
    end);

    DrawCheckbox('Combat: hide NPC/object plates', settings.performanceSafetySkipNpc == true, function(value)
        settings.performanceSafetySkipNpc = value == true;
    end);

    uiTooltip.Info('Keeps self, party/player, trust, pet, target, subtarget, and engaged enemy plates visible. Drops idle nearby enemies and NPC/object plates while fighting.');
end

function LibraPlatesSettingsDefaultLoadMode(entityName, stateName, widgetName)
    local entity = tostring(entityName or '');
    local widget = tostring(widgetName or '');

    if (entity == 'PC') then
        local outOfCombat = {
            ['Job'] = true,
            ['Level'] = true,
            ['Distance'] = true,
            ['Game mode icon'] = true,
            ['Linkshell icon'] = true,
            ['Bazaar icon'] = true,
            ['Away icon'] = true,
            ['Disconnect icon'] = true,
            ['Stars icon'] = true,
            ['New adventurer icon'] = true,
            ['Quick Menu'] = true,
            ['Quick Menu (module)'] = true,
            ['Peer'] = true,
            ['Peer (module)'] = true,
        };

        if (outOfCombat[widget] == true) then
            return 'Out of combat';
        end
    end

    return 'Always';
end

function LibraPlatesSettingsNormalizeLoadMode(value, fallback)
    local mode = tostring(value or fallback or 'Always');

    if (mode == 'OutOfCombat') then return 'Out of combat'; end
    if (mode == 'InCombat') then return 'In combat'; end
    if (mode == 'Out of combat' or mode == 'In combat' or mode == 'Never') then return mode; end

    return 'Always';
end

function LibraPlatesSettingsGetWidgetLoadMode(settings, entityName, stateName, widgetName)
    local fallback = LibraPlatesSettingsDefaultLoadMode(entityName, stateName, widgetName);

    return LibraPlatesSettingsNormalizeLoadMode(settings ~= nil and settings.loadMode or nil, fallback);
end

function LibraPlatesSettingsGetLoadModeColor(mode)
    mode = LibraPlatesSettingsNormalizeLoadMode(mode, 'Always');

    if (mode == 'Out of combat') then
        return { 0.55, 0.85, 1.00, 1.00 };
    end

    if (mode == 'In combat') then
        return { 1.00, 0.74, 0.25, 1.00 };
    end

    if (mode == 'Never') then
        return { 0.45, 0.48, 0.52, 1.00 };
    end

    return { 0.92, 0.92, 0.90, 1.0 };
end

function LibraPlatesSettingsDrawWidgetLoadMode(settings, entityName, stateName, widgetName)
    if (settings == nil) then
        return;
    end

    if (settings.loadMode == nil) then
        settings.loadMode = LibraPlatesSettingsDefaultLoadMode(entityName, stateName, widgetName);
    else
        settings.loadMode = LibraPlatesSettingsNormalizeLoadMode(settings.loadMode, LibraPlatesSettingsDefaultLoadMode(entityName, stateName, widgetName));
    end

    DrawInlineComboRow('Load', T{ 'Always', 'Out of combat', 'In combat', 'Never' }, settings.loadMode, function(value)
        settings.loadMode = LibraPlatesSettingsNormalizeLoadMode(value, 'Always');
        state.Save();
    end, 'LoadMode' .. tostring(entityName) .. tostring(stateName) .. tostring(widgetName), { 1.0, 1.0, 1.0, 1.0 });

    loadModeDrawn = true;
end

_G.LibraPlatesSettingsDrawContextLoadMode = function(settings, context)
    if (settings == nil or context == nil) then
        return;
    end

    if (loadModeDrawn == true) then
        return;
    end

    LibraPlatesSettingsDrawWidgetLoadMode(settings, context.entity, context.state, context.widget);
end

function LibraPlatesSettingsDrawCurrentWidgetLoadMode()
    local loadWidgetKey = widgetKeys[selectedWidget];

    if (loadWidgetKey == nil) then
        return;
    end

    local loadSettings = state.GetWidgetSettings(GetStorageEntity(selectedEntity), GetStorageState(selectedState), loadWidgetKey, GetWidgetDefaults(selectedWidget));
    LibraPlatesSettingsDrawWidgetLoadMode(loadSettings, selectedEntity, selectedState, selectedWidget);
    imgui.Separator();
end

function DrawPlacementSectionHeader(title, active, onChange)
    local ref = { active == true };

    if (imgui.Checkbox ~= nil) then
        if (imgui.Checkbox('##' .. title .. 'Active', ref) == true) then
            onChange(ref[1] == true);
        end
    else
        imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, '[' .. (active == true and 'x' or ' ') .. ']');

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            onChange(active ~= true);
        end
    end

    imgui.SameLine();
    DrawYellowHeader(title .. ':');
end

function ClampOffsetToVisibleEdge(value, size, canvasSize, minVisible)
    local halfCanvas = (tonumber(canvasSize) or 0) * 0.5;
    local halfSize = (tonumber(size) or 0) * 0.5;
    local visible = math.max(1, tonumber(minVisible) or 24);
    local limit = math.max(0, halfCanvas + halfSize - visible);
    local current = tonumber(value) or 0;

    if (current < -limit) then
        return -limit;
    end

    if (current > limit) then
        return limit;
    end

    return current;
end

function CopyDefaults(settings, defaults)
    for key, value in pairs(defaults or {}) do
        settings[key] = type(value) == 'table' and { unpackTable(value) } or value;
    end
end

function ResetTargetModulePosition(settings, defaults)
    settings.backgroundOffsetX = defaults.backgroundOffsetX or 0;
    settings.backgroundOffsetY = defaults.backgroundOffsetY or 0;
    settings.arrowOffsetX = defaults.arrowOffsetX or 0;
    settings.arrowOffsetY = defaults.arrowOffsetY or 0;
    settings.chevronOffsetX = defaults.chevronOffsetX or 0;
    settings.chevronOffsetY = defaults.chevronOffsetY or 0;
    settings.backgroundSpacing = defaults.backgroundSpacing or 0;
    settings.arrowSpacing = defaults.arrowSpacing or 0;
    settings.chevronSpacing = defaults.chevronSpacing or 0;
    settings.backgroundAutoPlaceAnchor = defaults.backgroundAutoPlaceAnchor or 'Widest element';
    settings.chevronAutoPlaceAnchor = defaults.chevronAutoPlaceAnchor or 'Widest element';
end

function RequestTargetModuleReset(kind, label)
    targetModulePendingReset = {
        kind = kind,
        label = label,
    };

    if (imgui.OpenPopup ~= nil) then
        imgui.OpenPopup('Reset target module##libraplates_target_module_placement_reset_confirm');
    end
end

function DrawResetActionButton(label, id)
    local buttonLabel = label .. '##' .. tostring(id or label);

    if (imgui.Button ~= nil) then
        return imgui.Button(buttonLabel);
    end

    return ClickText(label, { 1.0, 0.84, 0.0, 1.0 });
end

function DrawTargetModuleResetConfirm(settings, defaults)
    if (targetModulePendingReset == nil) then
        return;
    end

    if (imgui.BeginPopupModal == nil) then
        imgui.TextColored(uiAccent, 'Reset ' .. targetModulePendingReset.label .. '?');

        if (ClickText('Cancel', uiAccent) == true) then
            targetModulePendingReset = nil;
        end

        imgui.SameLine();

        if (ClickText('Confirm reset', uiAccent) == true) then
            if (targetModulePendingReset.kind == 'position') then
                ResetTargetModulePosition(settings, defaults or {});
            else
                CopyDefaults(settings, defaults or {});
            end

            state.Save();
            targetModulePendingReset = nil;
        end

        return;
    end

    if (imgui.BeginPopupModal('Reset target module##libraplates_target_module_placement_reset_confirm')) then
        imgui.Text('Reset ' .. targetModulePendingReset.label .. '?');

        if (targetModulePendingReset.kind == 'position') then
            imgui.Text('This will reset placement offsets and spacing for this Target/Subtarget module.');
        else
            imgui.Text('This will reset all Target/Subtarget module placement settings.');
        end

        imgui.Separator();

        if (imgui.Button('Cancel##target_module_placement_reset_cancel')) then
            targetModulePendingReset = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.SameLine();

        if (imgui.Button('Reset##target_module_placement_reset_confirm')) then
            if (targetModulePendingReset.kind == 'position') then
                ResetTargetModulePosition(settings, defaults or {});
            else
                CopyDefaults(settings, defaults or {});
            end

            state.Save();
            targetModulePendingReset = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.EndPopup();
    end
end

function RequestManeuverReset(kind)
    maneuverPendingReset = { kind = kind };

    if (imgui.OpenPopup ~= nil) then
        imgui.OpenPopup('Reset maneuvers##libraplates_maneuvers_reset_confirm');
    end
end

function DrawManeuverResetConfirm(settings)
    if (maneuverPendingReset == nil) then
        return;
    end

    if (imgui.BeginPopupModal == nil) then
        imgui.TextColored(uiAccent, 'Reset Maneuvers?');

        if (ClickText('Cancel', uiAccent) == true) then
            maneuverPendingReset = nil;
        end

        imgui.SameLine();

        if (ClickText('Confirm reset', uiAccent) == true) then
            if (maneuverPendingReset.kind == 'position') then
                settings.offsetX = maneuverDefaults.offsetX;
                settings.offsetY = maneuverDefaults.offsetY;
            else
                CopyDefaults(settings, maneuverDefaults);
            end

            state.Save();
            maneuverPendingReset = nil;
        end

        return;
    end

    if (imgui.BeginPopupModal('Reset maneuvers##libraplates_maneuvers_reset_confirm')) then
        imgui.Text('Reset Maneuvers?');
        imgui.Text((maneuverPendingReset.kind == 'position')
            and 'This will reset only the Maneuvers position.'
            or 'This will reset all Maneuvers settings.');
        imgui.Separator();

        if (imgui.Button('Cancel##maneuvers_reset_cancel')) then
            maneuverPendingReset = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.SameLine();

        if (imgui.Button('Reset##maneuvers_reset_confirm')) then
            if (maneuverPendingReset.kind == 'position') then
                settings.offsetX = maneuverDefaults.offsetX;
                settings.offsetY = maneuverDefaults.offsetY;
            else
                CopyDefaults(settings, maneuverDefaults);
            end

            state.Save();
            maneuverPendingReset = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.EndPopup();
    end
end

function DrawPetTimerExtraSettings(settings)
    imgui.Separator();
    if (settings.displayMode == 'Icon + time') then
        settings.displayMode = 'Icon';
    end

    DrawInlineComboRow('Display', T{ 'None', 'Text', 'Icon' }, settings.displayMode or 'Text', function(value)
        settings.displayMode = value;
        state.Save();
    end, 'PetTimerDisplay');

    if (settings.displayMode == 'Text' or settings.displayMode == 'Icon') then
        local positionLabel = (settings.displayMode == 'Icon') and 'Icon' or 'Label';
        local labelX, labelXChanged, labelY, labelYChanged = DrawPlacementPair(positionLabel .. ' X', settings.labelOffsetX, 'PetTimerLabelX', positionLabel .. ' Y', settings.labelOffsetY, 'PetTimerLabelY', -400, 400, 1);

        if (labelXChanged == true) then settings.labelOffsetX = labelX; state.Save(); end
        if (labelYChanged == true) then settings.labelOffsetY = labelY; state.Save(); end
    end

    local timerX, timerXChanged, timerY, timerYChanged = DrawPlacementPair('Timer X', settings.textOffsetX, 'PetTimerTimerX', 'Timer Y', settings.textOffsetY, 'PetTimerTimerY', -400, 400, 1);
    if (timerXChanged == true) then settings.textOffsetX = timerX; state.Save(); end
    if (timerYChanged == true) then settings.textOffsetY = timerY; state.Save(); end

    if (settings.displayMode == 'Icon') then
        local value, changed = DrawPlacementSingle('Icon size', settings.iconSize, 'PetTimerIconSize', 6, 96, 1);
        if (changed == true) then settings.iconSize = value; state.Save(); end
    end
end

function DrawPetDisplayMode(settings, id)
    if (settings.displayMode == 'Icon + text') then
        settings.displayMode = 'Text';
    end

    DrawInlineComboRow('Display', T{ 'None', 'Text', 'Icon' }, settings.displayMode or 'Text', function(value)
        settings.displayMode = value;
        state.Save();
    end, id or 'PetDisplay');
end

function DrawPetStateExtraSettings(settings)
    imgui.Separator();
    DrawPetDisplayMode(settings, 'PetStateDisplay');

    local displayMode = tostring(settings.displayMode or 'Text');

    if (displayMode ~= 'Text' and displayMode ~= 'Icon') then
        return;
    end

    local positionLabel = (displayMode == 'Icon') and 'Icon' or 'Label';
    local labelX, labelXChanged, labelY, labelYChanged = DrawPlacementPair(positionLabel .. ' X', settings.labelOffsetX, 'PetStateLabelX', positionLabel .. ' Y', settings.labelOffsetY, 'PetStateLabelY', -400, 400, 1);
    if (labelXChanged == true) then settings.labelOffsetX = labelX; state.Save(); end
    if (labelYChanged == true) then settings.labelOffsetY = labelY; state.Save(); end

    if (displayMode == 'Icon') then
        local value, changed = DrawPlacementSingle('Icon size', settings.iconSize, 'PetStateIconSize', 6, 128, 1);
        if (changed == true) then settings.iconSize = value; state.Save(); end
    end
end

function DrawManeuverSettings(settings)
    DrawYellowHeader('Maneuver settings');

    local x, xChanged, y, yChanged = DrawPlacementPair('Position X', settings.offsetX, 'ManeuverX', 'Position Y', settings.offsetY, 'ManeuverY', -500, 500, 1);
    if (xChanged == true) then settings.offsetX = x; state.Save(); end
    if (yChanged == true) then settings.offsetY = y; state.Save(); end

    local iconSize, iconSizeChanged, spacing, spacingChanged = DrawPlacementPair('Icon size', settings.iconSize, 'ManeuverIconSize', 'Icon spacer', settings.iconSpacing, 'ManeuverIconSpacer', 0, 160, 1);
    if (iconSizeChanged == true) then settings.iconSize = math.max(1, iconSize); state.Save(); end
    if (spacingChanged == true) then settings.iconSpacing = math.max(0, spacing); state.Save(); end

    DrawCheckbox('Show timers', settings.showTimers == true, function(value)
        settings.showTimers = value == true;
        state.Save();
    end);

    if (settings.showTimers == true) then
        DrawCheckbox('Use small font', settings.timerUseSmallFont == true, function(value)
            settings.timerUseSmallFont = value == true;
            state.Save();
        end);
        uiTooltip.Info('When enabled, this uses the Small text font style configured in General > Font.');

        local fontSize, fontSizeChanged, timerY, timerYChanged = DrawPlacementPair('Font size', textScale.NormalizeSetting(settings.timerFontSize, maneuverDefaults.timerFontSize), 'ManeuverTimerFontSize', 'Timer Y', settings.timerOffsetY, 'ManeuverTimerY', -100, 100, 1);
        if (fontSizeChanged == true) then settings.timerFontSize = fontSize; state.Save(); end
        if (timerYChanged == true) then settings.timerOffsetY = timerY; state.Save(); end

        local textColor, textColorChanged, outlineSize, outlineSizeChanged = DrawColorAndPlacementRow('Font color', settings.timerTextColor, 'ManeuverTimerTextColor', 'Outline size', settings.timerTextOutlineSize, 'ManeuverTimerOutlineSize', 0, 12, 1);
        if (textColorChanged == true) then settings.timerTextColor = textColor; state.Save(); end
        if (outlineSizeChanged == true) then settings.timerTextOutlineSize = outlineSize; state.Save(); end

        imgui.TextColored(settingsLabelColor, 'Outline color');
        imgui.SameLine();
        local outlineColor = { unpackTable(settings.timerTextOutlineColor or maneuverDefaults.timerTextOutlineColor) };
        if (imgui.ColorEdit4('##ManeuverTimerOutlineColor', outlineColor, settingsColorEditFlags) == true) then
            settings.timerTextOutlineColor = outlineColor;
            state.Save();
        end
    end

    imgui.Separator();
    if (DrawResetActionButton('Reset Maneuvers position', 'maneuvers_position') == true) then
        RequestManeuverReset('position');
    end

    if (DrawResetActionButton('Reset Maneuvers settings', 'maneuvers_settings') == true) then
        RequestManeuverReset('settings');
    end

    DrawManeuverResetConfirm(settings);
end

local targetAssetFileCache = {};

function GetAddonPath()
    local ok, path = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and path ~= nil) then
        return tostring(path);
    end

    return '.\\';
end

function AddTargetAssetFile(files, name)
    name = tostring(name or ''):gsub('^.*[\\/]', '');

    if (name == '' or string.lower(name):match('%.png$') == nil) then
        return;
    end

    for _, existing in ipairs(files) do
        if (existing == name) then
            return;
        end
    end

    files[#files + 1] = name;
end

function GetTargetAssetFiles(category)
    category = tostring(category or 'backgrounds');

    if (targetAssetFileCache[category] ~= nil) then
        return targetAssetFileCache[category];
    end

    local files = T{ 'None' };
    local folder = GetAddonPath() .. 'assets\\images\\target\\' .. category .. '\\';
    local pipe = io.popen('dir /b "' .. folder .. '*.png" 2>nul');

    if (pipe ~= nil) then
        for line in pipe:lines() do
            AddTargetAssetFile(files, line);
        end

        pipe:close();
    end

    table.sort(files, function(a, b)
        if (a == 'None') then return true; end
        if (b == 'None') then return false; end
        return string.lower(tostring(a)) < string.lower(tostring(b));
    end);

    targetAssetFileCache[category] = files;
    return files;
end

function DrawTargetModulePlacementSettings(settings, defaults, label, entityName)
    for key, value in pairs(defaults or {}) do
        if (settings[key] == nil) then
            settings[key] = value;
        end
    end

    local value, changed = nil, false;
    if (settings.enabled == nil) then
        settings.enabled = true;
    end

    if (IsPetStorageEntity(entityName) == true and tostring(label or '') ~= 'Subtarget (module)' and tostring(label or '') ~= 'Subtarget Module') then
        local targetingSettings = targeting.GetSettings();

        DrawCheckbox('Allow pet plate targeting', targetingSettings.enablePetPlateTargeting ~= false, function(nextValue)
            targetingSettings.enablePetPlateTargeting = nextValue == true;
            state.Save();
        end);
        uiTooltip.Info('When off, pet plates stay visible but LibraPlates will not target the pet from plate clicks and will suppress the pet Target module overlay.');

        if (targetingSettings.enablePetPlateTargeting == false) then
            return;
        end

        imgui.Separator();
    end

    local allowHighlight = tostring(entityName or '') ~= 'NPC';
    local hasArrowImage = tostring(settings.arrowFile or 'None') ~= 'None';
    local hasChevronImage = tostring(settings.chevronFile or 'None') ~= 'None';

    if (allowHighlight == true) then
        if (tostring(settings.backgroundFile or 'None') ~= 'None') then
            settings.backgroundEnabled = true;
            settings.showBackground = true;
        end

        local highlightEnabled = tostring(settings.backgroundFile or 'None') ~= 'None';

        DrawPlacementSectionHeader('Highlight', highlightEnabled == true, function(nextValue)
            settings.backgroundEnabled = nextValue;
            settings.showBackground = nextValue;
            if (nextValue ~= true) then
                settings.backgroundFile = 'None';
            end
            state.Save();
        end);

        DrawInlineComboRow('Highlight image', GetTargetAssetFiles('backgrounds'), settings.backgroundFile or 'None', function(value)
            settings.backgroundFile = value;
            settings.backgroundEnabled = tostring(value or 'None') ~= 'None';
            settings.showBackground = settings.backgroundEnabled;
            state.Save();
        end, 'TargetModuleHighlightImage');
    end;

    if (allowHighlight == true and tostring(settings.backgroundFile or 'None') ~= 'None' and (settings.backgroundEnabled ~= false or settings.showBackground == true)) then
        if (settings.autoPlaceBackground ~= false) then
            DrawInlineComboRow('Auto place by', targetAutoPlaceAnchorOptions, settings.backgroundAutoPlaceAnchor or 'Widest element', function(value)
                settings.backgroundAutoPlaceAnchor = value;
                state.Save();
            end, 'TargetModuleBackgroundAnchorMode');
            value, changed = DrawPlacementSingle('Size', settings.backgroundSpacing, 'TargetModuleBackgroundSpacing', 0, 300, 1);
            if (changed == true) then settings.backgroundSpacing = value; state.Save(); end
        else
            local backgroundHeight = tonumber(settings.backgroundHeight) or 90;
            local nextX, xChanged, nextY, yChanged = DrawPlacementPair(
                'Position X',
                settings.backgroundOffsetX,
                'TargetModuleBackgroundX',
                'Position Y',
                ClampOffsetToVisibleEdge(settings.backgroundOffsetY, backgroundHeight, 512, 24),
                'TargetModuleBackgroundY',
                -500,
                500,
                1
            );

            if (xChanged == true) then
                settings.backgroundOffsetX = math.max(-350, math.min(350, nextX));
                state.Save();
            end

            if (yChanged == true) then
                settings.backgroundOffsetY = ClampOffsetToVisibleEdge(nextY, backgroundHeight, 512, 24);
                state.Save();
            end

            local nextWidth, widthChanged, nextHeight, heightChanged = DrawPlacementPair(
                'Width',
                settings.backgroundWidth,
                'TargetModuleBackgroundWidth',
                'Height',
                settings.backgroundHeight,
                'TargetModuleBackgroundHeight',
                8,
                1000,
                5
            );

            if (widthChanged == true) then settings.backgroundWidth = nextWidth; state.Save(); end
            if (heightChanged == true) then settings.backgroundHeight = math.max(8, math.min(450, nextHeight)); state.Save(); end
        end

        local highlightColor, highlightColorChanged = DrawSettingsColor('Highlight tint', settings.backgroundColor, 'TargetModuleHighlightTint');
        if (highlightColorChanged == true) then settings.backgroundColor = highlightColor; state.Save(); end
    end

    if (allowHighlight == true) then
        imgui.Separator();
    end

    if (hasArrowImage == true) then
        DrawPlacementSectionHeader('Arrow', settings.arrowEnabled ~= false, function(nextValue)
            settings.arrowEnabled = nextValue;
            state.Save();
        end);
    end

    if (hasArrowImage == true and settings.arrowEnabled ~= false) then
        local nextX, xChanged, nextY, yChanged = DrawPlacementPair(
            'Position X',
            settings.arrowOffsetX,
            'TargetModuleArrowX',
            'Position Y',
            settings.arrowOffsetY,
            'TargetModuleArrowY',
            -500,
            500,
            1
        );

        if (xChanged == true) then settings.arrowOffsetX = math.max(-350, math.min(350, nextX)); state.Save(); end
        if (yChanged == true) then settings.arrowOffsetY = nextY; state.Save(); end

        local nextWidth, widthChanged, nextHeight, heightChanged = DrawPlacementPair(
            'Width',
            settings.arrowWidth,
            'TargetModuleArrowWidth',
            'Height',
            settings.arrowHeight,
            'TargetModuleArrowHeight',
            8,
            200,
            1
        );

        if (widthChanged == true) then settings.arrowWidth = nextWidth; state.Save(); end
        if (heightChanged == true) then settings.arrowHeight = nextHeight; state.Save(); end

        if (settings.arrowAnimation == 'Classic' or settings.arrowAnimation == 'Native shimmer') then
            settings.arrowSprite = true;
            settings.arrowAnimationSpeed = tonumber(settings.arrowAnimationSpeed) or 12;
        end
        settings.arrowAnimation = nil;

        if (arrowAnimation.HasSpriteFrames(settings.arrowFile) == true) then
            DrawCheckbox('Animate', settings.arrowSprite == true, function(nextValue)
                settings.arrowSprite = nextValue == true;
                state.Save();
            end);

            if (settings.arrowSprite == true) then
                value, changed = DrawPlacementSingle('Animation speed', settings.arrowAnimationSpeed, 'TargetModuleArrowAnimationSpeed', 1, 60, 1);
                if (changed == true) then settings.arrowAnimationSpeed = value; state.Save(); end
            end
        else
            settings.arrowSprite = false;
        end

        value, changed = DrawPlacementSingle('Spacing', settings.arrowSpacing, 'TargetModuleArrowSpacing', 0, 300, 1);
        if (changed == true) then settings.arrowSpacing = value; state.Save(); end
    end

    if (hasArrowImage == true) then
        imgui.Separator();
    end

    if (tostring(label or '') ~= 'Subtarget (module)' and tostring(label or '') ~= 'Subtarget Module') then
        DrawPlacementSectionHeader('Lock-on icon', settings.lockEnabled ~= false, function(nextValue)
            settings.lockEnabled = nextValue;
            state.Save();
        end);

        if (settings.lockEnabled ~= false) then
            local nextX, xChanged, nextY, yChanged = DrawPlacementPair(
                'Position X',
                settings.lockOffsetX,
                'TargetModuleLockX',
                'Position Y',
                settings.lockOffsetY,
                'TargetModuleLockY',
                -500,
                500,
                1
            );

            if (xChanged == true) then settings.lockOffsetX = math.max(-350, math.min(350, nextX)); state.Save(); end
            if (yChanged == true) then settings.lockOffsetY = nextY; state.Save(); end

            local nextWidth, widthChanged, nextHeight, heightChanged = DrawPlacementPair(
                'Width',
                settings.lockWidth,
                'TargetModuleLockWidth',
                'Height',
                settings.lockHeight,
                'TargetModuleLockHeight',
                1,
                200,
                1
            );

            if (widthChanged == true) then settings.lockWidth = nextWidth; state.Save(); end
            if (heightChanged == true) then settings.lockHeight = nextHeight; state.Save(); end

            local lockColor, lockColorChanged = DrawSettingsColor('Lock-on tint', settings.lockColor, 'TargetModuleLockColor');
            settings.lockColor = lockColor;
            if (lockColorChanged == true) then state.Save(); end
            uiTooltip.Info('Shown only while the current target is locked on.');
        end

        imgui.Separator();
    end

    if (hasChevronImage == true) then
        DrawPlacementSectionHeader('Chevrons', settings.chevronEnabled ~= false, function(nextValue)
            settings.chevronEnabled = nextValue;
            state.Save();
        end);
    end

    if (hasChevronImage == true and settings.chevronEnabled ~= false) then
        local nextX, xChanged, nextY, yChanged = DrawPlacementPair(
            'Position X',
            settings.chevronOffsetX,
            'TargetModuleChevronsX',
            'Position Y',
            settings.chevronOffsetY,
            'TargetModuleChevronsY',
            -500,
            500,
            1
        );

        if (xChanged == true) then settings.chevronOffsetX = math.max(-350, math.min(350, nextX)); state.Save(); end
        if (yChanged == true) then settings.chevronOffsetY = nextY; state.Save(); end

        local nextWidth, widthChanged, nextHeight, heightChanged = DrawPlacementPair(
            'Width',
            settings.chevronWidth,
            'TargetModuleChevronsWidth',
            'Height',
            settings.chevronHeight,
            'TargetModuleChevronsHeight',
            8,
            200,
            1
        );

        if (widthChanged == true) then settings.chevronWidth = nextWidth; state.Save(); end
        if (heightChanged == true) then settings.chevronHeight = nextHeight; state.Save(); end

        if (settings.autoPlaceChevrons ~= false) then
            DrawInlineComboRow('Auto place by', targetAutoPlaceAnchorOptions, settings.chevronAutoPlaceAnchor or 'Widest element', function(value)
                settings.chevronAutoPlaceAnchor = value;
                state.Save();
            end, 'TargetModuleChevronsAnchorMode');
            value, changed = DrawPlacementSingle('Spacing', settings.chevronSpacing, 'TargetModuleChevronsSpacing', 0, 900, 5);
            if (changed == true) then settings.chevronSpacing = value; state.Save(); end
        else
            value, changed = DrawPlacementSingle('Distance apart', settings.chevronSpacing, 'TargetModuleChevronsDistance', 20, 900, 5);
            if (changed == true) then settings.chevronSpacing = value; state.Save(); end
        end
    end

    imgui.Separator();

    if (DrawResetActionButton('Reset ' .. tostring(label or 'Target Module') .. ' position', 'target_module_position') == true) then
        RequestTargetModuleReset('position', tostring(label or 'Target Module') .. ' position');
    end

    if (DrawResetActionButton('Reset ' .. tostring(label or 'Target Module') .. ' settings', 'target_module_settings') == true) then
        RequestTargetModuleReset('settings', tostring(label or 'Target Module') .. ' settings');
    end

    DrawTargetModuleResetConfirm(settings, defaults or {});
end

_G.LibraPlatesSettingsDrawTargetModulePlacementSettings = DrawTargetModulePlacementSettings;

function DrawFontStatus(label, selected)
    local available, family = fonts.IsAvailable(selected);
    local selectedText = tostring(selected or 'Default');
    local familyText = tostring(family or '');

    if (familyText == '') then
        familyText = selectedText;
    end

    if (available == true) then
        imgui.TextColored({ 0.55, 1.0, 0.55, 1.0 }, label .. ': OK - ' .. familyText);
        return;
    end

    imgui.TextColored({ 0.20, 0.65, 0.67, 1.0 }, label .. ': not installed/available - ' .. familyText);
end

function DrawFontFolderButton(label, kind)
    if (imgui.Button ~= nil) then
        if (imgui.Button(label) == true) then
            fonts.OpenFolder(kind);
        end

        return;
    end

    imgui.TextColored({ 0.65, 0.90, 1.0, 1.0 }, label);

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        fonts.OpenFolder(kind);
    end
end

function DrawTopTabs()
    if (imgui.BeginTabBar ~= nil and imgui.BeginTabItem ~= nil and imgui.EndTabItem ~= nil and imgui.EndTabBar ~= nil) then
        if (imgui.BeginTabBar('##libraplates_top_tabs')) then
            for _, tab in ipairs(tabs) do
                local flags = (tab == selectedTab) and (_G.ImGuiTabItemFlags_SetSelected or 0) or 0;

                if (imgui.BeginTabItem(tab, nil, flags) == true) then
                    selectedTab = tab;
                    imgui.EndTabItem();
                end
            end

            imgui.EndTabBar();
        end

        return;
    end

    for i, tab in ipairs(tabs) do
        local selected = tab == selectedTab;
        local pushed = 0;

        if (imgui.PushStyleColor ~= nil and selected == true) then
            local buttonColor = GetImguiColor('Button');
            local buttonHovered = GetImguiColor('ButtonHovered');
            local buttonActive = GetImguiColor('ButtonActive');

            if (buttonColor ~= nil) then imgui.PushStyleColor(buttonColor, uiAccentActive); pushed = pushed + 1; end
            if (buttonHovered ~= nil) then imgui.PushStyleColor(buttonHovered, uiAccentHovered); pushed = pushed + 1; end
            if (buttonActive ~= nil) then imgui.PushStyleColor(buttonActive, uiAccent); pushed = pushed + 1; end
        end

        local clicked = false;
        if (imgui.Button ~= nil) then
            clicked = imgui.Button(tab) == true;
        else
            imgui.TextColored(selected and { 1.0, 0.84, 0.0, 1.0 } or { 0.92, 0.92, 0.90, 1.0 }, selected and ('> ' .. tab) or tab);
            clicked = imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true;
        end

        if (pushed > 0 and imgui.PopStyleColor ~= nil) then
            imgui.PopStyleColor(pushed);
        end

        if (clicked == true) then
            selectedTab = tab;
        end

        if (i < #tabs) then
            imgui.SameLine();
        end
    end
end

function DrawChild(name, size, border, render)
    local childError = nil;

    imgui.BeginChild(name, size, border);

    local ok, err = pcall(render);

    if (ok ~= true) then
        childError = err;
    end

    imgui.EndChild();

    if (childError ~= nil) then
        error(childError);
    end
end

function DrawPreviewSplitter(id, splitRatio, previewHeight, usableHeight, minPreviewHeight, maxPreviewHeight)
    local splitterWidth = select(1, GetContentRegionAvail());
    local splitterHeight = 18;

    if (splitterWidth < 1) then
        splitterWidth = 1;
    end

    local x, y = GetCursorScreenPos();

    if (imgui.InvisibleButton ~= nil) then
        imgui.InvisibleButton(id, { splitterWidth, splitterHeight });
    else
        imgui.Button(id, { splitterWidth, splitterHeight });
    end

    local color = { 0.25, 0.29, 0.36, 1.0 };

    if (imgui.IsItemActive ~= nil and imgui.IsItemActive() == true) then
        color = { 0.45, 0.50, 0.60, 1.0 };
    elseif (imgui.IsItemHovered ~= nil and imgui.IsItemHovered() == true) then
        color = { 0.35, 0.40, 0.50, 1.0 };
    end

    local drawList = imgui.GetWindowDrawList();

    if (drawList ~= nil and imgui.GetColorU32 ~= nil) then
        drawList:AddRectFilled(
            { x, y + 3 },
            { x + splitterWidth, y + splitterHeight - 3 },
            imgui.GetColorU32(color),
            2
        );

        local arrowTextureId = GetSplitterArrowTextureId();

        if (arrowTextureId ~= nil and drawList.AddImage ~= nil) then
            local iconWidth = 30;
            local iconHeight = 12;
            local iconX = x + math.floor((splitterWidth - iconWidth) * 0.5);
            local iconY = y + math.floor((splitterHeight - iconHeight) * 0.5);

            drawList:AddImage(
                arrowTextureId,
                { iconX, iconY },
                { iconX + iconWidth, iconY + iconHeight },
                { 0, 0 },
                { 1, 1 },
                imgui.GetColorU32({ 1.0, 1.0, 1.0, 0.95 })
            );
        end
    end

    if (
        imgui.IsItemActive ~= nil and
        imgui.IsItemActive() == true and
        imgui.GetMouseDragDelta ~= nil and
        imgui.ResetMouseDragDelta ~= nil
    ) then
        local dragA, dragB = imgui.GetMouseDragDelta(0);
        local dragY = 0;

        if (type(dragA) == 'table') then
            dragY = tonumber(dragA.y or dragA[2]) or 0;
        else
            dragY = tonumber(dragB) or 0;
        end

        if (dragY ~= 0 and usableHeight > 0) then
            local resizedPreviewHeight = math.max(minPreviewHeight, math.min(previewHeight + dragY, maxPreviewHeight));
            splitRatio = resizedPreviewHeight / usableHeight;
            imgui.ResetMouseDragDelta(0);
        end
    end

    return splitRatio;
end

function SelectPreviewElement(kind, context)
    local normalizedKind = tostring(kind or '');

    if (
        (context ~= nil and (context.widgetKey == 'Peer' or context.widgetKey == 'Peer (module)')) or
        (selectedTab == 'Modules' and selectedModuleWidget == 'Peer') or
        (selectedTab == 'Plates' and selectedWidget == 'Peer (module)')
    ) then
        local componentByKind = {
            background = 'Background',
            name = 'Name',
            hp = 'HP bar',
            job = 'Job',
            level = 'Level',
            id = 'ID',
            distance = 'Range',
            peerJob = 'Job',
            peerLevel = 'Level',
            peerId = 'ID',
            peerRange = 'Range',
            peerAggro = 'Behavior',
            peerDetection = 'Detection/link',
            peerImmunity = 'Immunities',
            peerModifiers = 'Damage modifiers',
        };
        local component = componentByKind[normalizedKind];

        if (component ~= nil) then
            selectedPeerEnemyInfo = component;

            if (selectedTab == 'Modules') then
                selectedModuleWidget = 'Peer';
            elseif (selectedTab == 'Plates' and ListContains(GetEditWidgets(), 'Peer (module)') == true) then
                selectedWidget = 'Peer (module)';
            end

            PersistUiSelection();
            return;
        end
    end

    local widgetByKind = {
        background = 'Background',
        name = 'Name',
        hp = 'HP Bar',
        mp = 'MP Bar',
        tp = 'TP Bar',
        cast = 'Cast bar',
        job = 'Job',
        level = 'Level',
        id = 'ID',
        distance = 'Distance',
        petTimer = 'Pet timer',
        petState = 'Pet state',
        ready = 'Ready bar',
        reward = 'Reward',
        sic = 'Sic',
        ward = 'Ward timer',
        rage = 'Rage timer',
        targetModuleBackground = ListContains(GetEditWidgets(), 'Target') == true and 'Target' or 'Target (module)',
        targetModuleArrow = ListContains(GetEditWidgets(), 'Target') == true and 'Target' or 'Target (module)',
        targetModuleChevron = ListContains(GetEditWidgets(), 'Target') == true and 'Target' or 'Target (module)',
        allianceLeaderIcon = 'Alliance leader icon',
        partyLeaderIcon = 'Party leader icon',
        gameModeIcon = 'Game mode icon',
        linkshellIcon = 'Linkshell icon',
        bazaarIcon = 'Bazaar icon',
        awayIcon = 'Away icon',
        disconnectIcon = 'Disconnect icon',
        anonIcon = 'Anon icon',
        followIcon = 'Follow icon',
        starsIcon = 'Stars icon',
        levelSyncIcon = 'Level sync icon',
        newAdventurerIcon = 'New adventurer icon',
        buffs = 'Buffs',
        debuffs = 'Debuffs',
    };
    local widget = widgetByKind[normalizedKind];

    if (widget == nil) then
        return;
    end

    if (selectedTab == 'Modules') then
        local widgetKey = context ~= nil and tostring(context.widgetKey or '') or '';

        if (normalizedKind == 'targetModuleBackground' or normalizedKind == 'targetModuleArrow' or normalizedKind == 'targetModuleChevron') then
            if (widgetKey == 'Subtarget Module') then
                selectedModuleWidget = 'Subtarget';
            else
                selectedModuleWidget = 'Target';
            end

            PersistUiSelection();
            return;
        end

        selectedTab = 'Plates';
        selectedEntity = selectedModuleEntity;
        selectedState = selectedModuleState;
        EnsureSelectedStateAllowed();
    end

    if (context ~= nil and context.widgetKey == 'Subtarget Module' and (widget == 'Target' or widget == 'Target (module)')) then
        widget = ListContains(GetEditWidgets(), 'Subtarget') == true and 'Subtarget' or 'Subtarget (module)';
    end

    if (selectedTab == 'Plates' and widget ~= nil and ListContains(GetEditWidgets(), widget) == true) then
        selectedWidget = widget;
        EnsureSelectedWidgetAllowed();
        PersistUiSelection();
    end
end

function RoundDragDelta(value)
    value = tonumber(value) or 0;

    if (value >= 0) then
        return math.floor(value + 0.5);
    end

    return math.ceil(value - 0.5);
end

function DragPeerPreviewElement(kind, dx, dy, context)
    local normalizedKind = tostring(kind or '');
    local deltaX = RoundDragDelta(dx);
    local deltaY = RoundDragDelta(dy);

    if (deltaX == 0 and deltaY == 0) then
        return;
    end

    local componentByKind = {
        background = { component = 'Background', prefix = 'background' },
        name = { component = 'Name', prefix = 'name' },
        hp = { component = 'HP bar', prefix = 'hpBar' },
        job = { component = 'Job', prefix = 'job' },
        level = { component = 'Level', prefix = 'level' },
        id = { component = 'ID', prefix = 'id' },
        distance = { component = 'Range', prefix = 'range' },
        peerJob = { component = 'Job', prefix = 'job' },
        peerLevel = { component = 'Level', prefix = 'level' },
        peerId = { component = 'ID', prefix = 'id' },
        peerRange = { component = 'Range', prefix = 'range' },
        peerAggro = { component = 'Behavior', prefix = 'aggro' },
        peerDetection = { component = 'Detection/link', prefix = 'detection' },
        peerImmunity = { component = 'Immunities', prefix = 'immunity' },
        peerModifiers = { component = 'Damage modifiers', prefix = 'modifier' },
    };
    local isPeerContext = (
        (context ~= nil and (context.widgetKey == 'Peer' or context.widgetKey == 'Peer (module)')) or
        (selectedTab == 'Modules' and selectedModuleWidget == 'Peer') or
        (selectedTab == 'Plates' and selectedWidget == 'Peer (module)')
    );
    local target = isPeerContext == true and componentByKind[normalizedKind] or nil;

    if (target ~= nil) then
        local global = state.GetGlobalSettings(globalDefaults);
        global.peer = global.peer or {};

        local xKey = target.prefix .. 'OffsetX';
        local yKey = target.prefix .. 'OffsetY';

        global.peer[xKey] = math.max(-500, math.min(500, (tonumber(global.peer[xKey]) or 0) + deltaX));
        global.peer[yKey] = math.max(-500, math.min(500, (tonumber(global.peer[yKey]) or 0) + deltaY));
        selectedPeerEnemyInfo = target.component;

        if (selectedTab == 'Modules') then
            selectedModuleWidget = 'Peer';
        elseif (selectedTab == 'Plates' and ListContains(GetEditWidgets(), 'Peer (module)') == true) then
            selectedWidget = 'Peer (module)';
        end

        state.Save();
        return;
    end

    local targetModuleByKind = {
        targetModuleBackground = { widget = 'Target (module)', autoKey = 'autoPlaceBackground', xKey = 'backgroundOffsetX', yKey = 'backgroundOffsetY' },
        targetModuleArrow = { widget = 'Target (module)', autoKey = 'autoPlaceArrow', xKey = 'arrowOffsetX', yKey = 'arrowOffsetY' },
        targetModuleChevron = { widget = 'Target (module)', autoKey = 'autoPlaceChevrons', xKey = 'chevronOffsetX', yKey = 'chevronOffsetY' },
    };
    local targetModuleTarget = targetModuleByKind[normalizedKind];

    if (targetModuleTarget ~= nil) then
        local widget = targetModuleTarget.widget;

        if (context ~= nil and context.widgetKey == 'Subtarget Module') then
            widget = 'Subtarget (module)';
        end

        if (selectedTab == 'Modules') then
            if (context ~= nil and context.widgetKey == 'Subtarget Module') then
                selectedModuleWidget = 'Subtarget';
            else
                selectedModuleWidget = 'Target';
            end
        elseif (selectedTab == 'Plates') then
            if (ListContains(GetEditWidgets(), widget) ~= true) then
                widget = (widget == 'Subtarget (module)') and 'Subtarget' or 'Target';
            end

            if (ListContains(GetEditWidgets(), widget) ~= true) then
                return;
            end
        end

        local storageEntity = context ~= nil and tostring(context.entityName or '') or GetStorageEntity(selectedEntity);
        local storageState = context ~= nil and tostring(context.stateName or '') or GetStorageState(selectedState);
        local widgetKey = (widget == 'Subtarget' or widget == 'Subtarget (module)') and 'Subtarget Module' or 'Target Module';
        local defaults = (widgetKey == 'Subtarget Module') and subtargetModuleDefaults or targetModuleDefaults;
        local settings = state.GetWidgetSettings(storageEntity, storageState, widgetKey, defaults);

        settings[targetModuleTarget.autoKey] = false;
        settings[targetModuleTarget.xKey] = math.max(-500, math.min(500, (tonumber(settings[targetModuleTarget.xKey]) or 0) + deltaX));
        settings[targetModuleTarget.yKey] = math.max(-500, math.min(500, (tonumber(settings[targetModuleTarget.yKey]) or 0) + deltaY));

        if (selectedTab == 'Plates') then
            selectedWidget = widget;
            EnsureSelectedWidgetAllowed();
        end

        PersistUiSelection();
        state.Save();
        return;
    end

    local widgetByKind = {
        background = 'Background',
        name = 'Name',
        hp = 'HP Bar',
        mp = 'MP Bar',
        tp = 'TP Bar',
        cast = 'Cast bar',
        job = 'Job',
        level = 'Level',
        id = 'ID',
        distance = 'Distance',
        petTimer = 'Pet timer',
        petState = 'Pet state',
        ready = 'Ready bar',
        reward = 'Reward',
        sic = 'Sic',
        ward = 'Ward timer',
        rage = 'Rage timer',
        allianceLeaderIcon = 'Alliance leader icon',
        partyLeaderIcon = 'Party leader icon',
        gameModeIcon = 'Game mode icon',
        linkshellIcon = 'Linkshell icon',
        bazaarIcon = 'Bazaar icon',
        awayIcon = 'Away icon',
        disconnectIcon = 'Disconnect icon',
        anonIcon = 'Anon icon',
        followIcon = 'Follow icon',
        starsIcon = 'Stars icon',
        levelSyncIcon = 'Level sync icon',
        newAdventurerIcon = 'New adventurer icon',
        buffs = 'Buffs',
        debuffs = 'Debuffs',
    };
    local widget = widgetByKind[normalizedKind];

    if (widget == nil or selectedTab ~= 'Plates' or ListContains(GetEditWidgets(), widget) ~= true) then
        return;
    end

    local storageEntity = GetStorageEntity(selectedEntity);
    local storageState = GetStorageState(selectedState);
    local widgetKey = widgetKeys[widget];

    if (widgetKey == nil) then
        return;
    end

    local rootWidget = widget;
    local visited = {};

    for _ = 1, 8 do
        local rootKey = widgetKeys[rootWidget];

        if (rootKey == nil or visited[rootWidget] == true) then
            break;
        end

        visited[rootWidget] = true;

        local rootSettings = state.GetWidgetSettings(storageEntity, storageState, rootKey, GetWidgetDefaults(rootWidget));
        local anchorTo = tostring(rootSettings.anchorTo or 'Plate');

        if (anchorTo == 'Plate' or widgetKeys[anchorTo] == nil or ListContains(GetEditWidgets(), anchorTo) ~= true) then
            break;
        end

        rootWidget = anchorTo;
    end

    local settings = state.GetWidgetSettings(storageEntity, storageState, widgetKeys[rootWidget], GetWidgetDefaults(rootWidget));

    settings.offsetX = math.max(-500, math.min(500, (tonumber(settings.offsetX) or 0) + deltaX));
    settings.offsetY = math.max(-500, math.min(500, (tonumber(settings.offsetY) or 0) + deltaY));
    selectedWidget = rootWidget;
    EnsureSelectedWidgetAllowed();
    PersistUiSelection();
    state.Save();
end

function AttachPreviewClickHandler(context)
    context = context or {};
    context.onElementClick = SelectPreviewElement;
    context.onElementDrag = DragPeerPreviewElement;
    return context;
end

function GetPreviewSelection()
    if (selectedTab == 'Modules') then
        local widgetKey = nil;
        local defaults = nil;
        local selectedModuleName = tostring(selectedModuleWidget or ''):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '');

        if (selectedModuleName == 'Target') then
            widgetKey = 'Target Module';
            defaults = targetModuleDefaults;
        elseif (selectedModuleName == 'Subtarget') then
            widgetKey = 'Subtarget Module';
            defaults = subtargetModuleDefaults;
        elseif (selectedModuleName == 'Peer') then
            widgetKey = 'Peer';
        elseif (selectedModuleName == 'Enmity') then
            widgetKey = 'Enmity';
        elseif (selectedModuleName == 'Resting') then
            widgetKey = 'Resting';
        elseif (selectedModuleName == 'Crafting') then
            widgetKey = 'Crafting';
        elseif (selectedModuleName == 'Fishing') then
            widgetKey = 'Fishing';
        end

        local entityName = selectedModuleEntity;
        local stateName = GetStorageState(selectedModuleState);

        if (selectedModuleName == 'Resting' or selectedModuleName == 'Fishing' or selectedModuleName == 'Crafting') then
            entityName = 'Self';
            stateName = 'Idle';
        end

        return entityName, stateName, AttachPreviewClickHandler({
            entityName = GetStorageEntity(entityName),
            stateName = stateName,
            widgetKey = widgetKey,
            defaults = defaults,
            previewFishingResult = selectedModuleName == 'Fishing',
            previewCraftingResult = selectedModuleName == 'Crafting',
        });
    end

    local context = {};

    if (selectedTab == 'Plates') then
        if (selectedWidget == 'Target' or selectedWidget == 'Target (module)' or selectedWidget == 'Lock-on icon') then
            context = {
                entityName = GetStorageEntity(selectedEntity),
                stateName = GetStorageState(selectedState),
                widgetKey = 'Target Module',
                defaults = targetModuleDefaults,
            };
        elseif (selectedWidget == 'Subtarget' or selectedWidget == 'Subtarget (module)') then
            context = {
                entityName = GetStorageEntity(selectedEntity),
                stateName = GetStorageState(selectedState),
                widgetKey = 'Subtarget Module',
                defaults = subtargetModuleDefaults,
            };
        elseif (selectedWidget == 'Peer (module)') then
            context = {
                entityName = GetStorageEntity(selectedEntity),
                stateName = GetStorageState(selectedState),
                widgetKey = 'Peer',
            };
        elseif (selectedWidget == 'Enmity (module)') then
            context = {
                entityName = GetStorageEntity(selectedEntity),
                stateName = GetStorageState(selectedState),
                widgetKey = 'Enmity',
            };
        elseif (selectedWidget == 'Resting (module)') then
            context = {
                entityName = 'Self',
                stateName = 'Idle',
                widgetKey = 'Resting',
            };
        elseif (selectedWidget == 'Fishing (module)') then
            context = {
                entityName = 'Self',
                stateName = 'Idle',
                widgetKey = 'Fishing',
                previewFishingResult = true,
            };
        elseif (selectedWidget == 'Crafting (module)') then
            context = {
                entityName = 'Self',
                stateName = 'Idle',
                widgetKey = 'Crafting',
                previewCraftingResult = true,
            };
        elseif (selectedWidget == 'Quick Menu (module)') then
            context = {
                entityName = GetStorageEntity(selectedEntity),
                stateName = GetStorageState(selectedState),
                widgetKey = 'Quick Menu',
                previewQuickMenu = true,
            };
        end

        if (selectedEntity == 'Self' and context.widgetKey == nil) then
            if (selectedState == 'Resting') then
                context = {
                    entityName = 'Self',
                    stateName = 'Resting',
                    widgetKey = 'Resting',
                };
            elseif (selectedState == 'Fishing') then
                context = {
                    entityName = 'Self',
                    stateName = 'Fishing',
                    widgetKey = 'Fishing',
                    previewFishingResult = true,
                };
            elseif (selectedState == 'Crafting') then
                context = {
                    entityName = 'Self',
                    stateName = 'Crafting',
                    widgetKey = 'Crafting',
                    previewCraftingResult = true,
                };
            end
        end
    end

    context.sourceEntity = selectedEntity;
    context.sourceState = selectedState;

    return selectedEntity, GetStorageState(selectedState), AttachPreviewClickHandler(context);
end

function DrawRightPanel()
    local rightWidth, rightHeight = GetContentRegionAvail();
    local splitterHeight = 18;
    local minPreviewHeight = 95;
    local minSettingsHeight = 145;
    local usableHeight = math.max(minPreviewHeight + minSettingsHeight + splitterHeight, rightHeight);
    local maxPreviewHeight = math.max(minPreviewHeight, usableHeight - minSettingsHeight - splitterHeight);
    local previewHeight = math.floor(usableHeight * previewSplitRatio);

    previewHeight = math.max(minPreviewHeight, math.min(previewHeight, maxPreviewHeight));

    DrawChild('##preview_panel', { 0, previewHeight }, true, function()
        local previewEntity, previewState, previewContext = GetPreviewSelection();
        preview.Draw(previewEntity, previewState, previewContext);
    end);

    previewSplitRatio = DrawPreviewSplitter(
        '##libraplates_preview_splitter',
        previewSplitRatio,
        previewHeight,
        usableHeight,
        minPreviewHeight,
        maxPreviewHeight
    );

    local settingsHeight = math.max(minSettingsHeight, rightHeight - previewHeight - splitterHeight);

    DrawChild('##settings_scroll_panel', { 0, settingsHeight }, true, function()
        DrawSelectedEditor();
    end);
end

function DrawPlatesSelector()
    DrawInlineCombo('Entity', entities, selectedEntity, function(entity)
        selectedEntity = entity;
        EnsureSelectedStateAllowed();
        EnsureSelectedWidgetAllowed();
    end);

    EnsureSelectedStateAllowed();
    DrawInlineCombo('Plate', GetStates(selectedEntity), selectedState, function(stateName)
        selectedState = stateName;
        EnsureSelectedWidgetAllowed();
    end);

    EnsureSelectedWidgetAllowed();
    imgui.Separator();
    DrawYellowHeader('Widgets');

    for index, widget in ipairs(GetEditWidgets()) do
        local settings = GetChecklistActiveSettings(widget);
        local globalSettings = state.GetGlobalSettings(globalDefaults);
        local nativeUiPolicy = require('core.native_ui_policy');
        local libraTargetingActive = nativeUiPolicy.ShouldDrawLibraTargetingSystem() == true;
        local protectedTargetModule = libraTargetingActive == true and (widget == 'Target' or widget == 'Subtarget' or widget == 'Target (module)' or widget == 'Subtarget (module)');

        if (protectedTargetModule == true and settings ~= nil and settings.enabled ~= true) then
            settings.enabled = true;
            state.Save();
        end

        local active = settings ~= nil and settings.enabled == true;
        local ref = { active };
        local checkboxId = '##plate_widget_' .. tostring(index) .. '_' .. tostring(widget);

        if (imgui.Checkbox ~= nil) then
            if (protectedTargetModule == true) then
                ref[1] = true;
            end

            local disabled = false;

            if (protectedTargetModule == true and imgui.BeginDisabled ~= nil) then
                imgui.BeginDisabled(true);
                disabled = true;
            end

            local changed = imgui.Checkbox(checkboxId, ref);

            if (disabled == true and imgui.EndDisabled ~= nil) then
                imgui.EndDisabled();
            end

            if (changed == true and settings ~= nil and protectedTargetModule ~= true) then
                settings.enabled = ref[1] == true;
                state.Save();
            end
            imgui.SameLine();
        else
            imgui.TextColored(protectedTargetModule == true and { 0.65, 0.90, 1.0, 0.85 } or { 0.92, 0.92, 0.90, 1.0 }, '[' .. ((active or protectedTargetModule) and 'x' or ' ') .. ']');
            if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true and settings ~= nil and protectedTargetModule ~= true) then
                settings.enabled = not active;
                state.Save();
            end
            imgui.SameLine();
        end

        local selected = widget == selectedWidget;
        local loadMode = LibraPlatesSettingsGetWidgetLoadMode(settings, selectedEntity, selectedState, widget);
        local loadColor = LibraPlatesSettingsGetLoadModeColor(loadMode);
        local labelColor = loadColor;

        if (selected == true) then
            labelColor = { 1.0, 1.0, 1.0, 1.0 };
        elseif (protectedTargetModule == true) then
            labelColor = { 0.65, 0.90, 1.0, 1.0 };
        elseif (active ~= true) then
            labelColor = { 0.58, 0.60, 0.64, 1.0 };
        end

        if (DrawSelectableRow(widget, selected, labelColor, 'plate_widget_select_' .. tostring(index) .. '_' .. tostring(widget)) == true) then
            selectedWidget = widget;
        end

        if (protectedTargetModule == true) then
            uiTooltip.Info('Required while LibraPlates is replacing the native targeting system.');
        end
    end
end

function DrawModulesSelector()
    EnsureSelectedModuleWidgetAllowed();

    DrawInlineCombo('Entity', moduleEntities, selectedModuleEntity, function(entity)
        selectedModuleEntity = entity;
        local moduleStates = GetStates(selectedModuleEntity);
        if (ListContains(moduleStates, selectedModuleState) ~= true) then
            selectedModuleState = moduleStates[1] or 'World';
        end
        EnsureSelectedModuleWidgetAllowed();
    end);

    DrawInlineCombo('Plate', GetStates(selectedModuleEntity), selectedModuleState, function(stateName)
        selectedModuleState = stateName;
        EnsureSelectedModuleWidgetAllowed();
    end);

    local widgets = GetModuleWidgets(selectedModuleEntity, selectedModuleState);

    DrawInlineCombo('Module', widgets, selectedModuleWidget, function(widget)
        selectedModuleWidget = widget;
    end);
end

function LibraPlatesSettingsDrawBreadcrumb(parts)
    local items = parts or {};
    local bgX, bgY = GetCursorScreenPos();
    local bgWidth = select(1, GetContentRegionAvail());
    local drawList = imgui.GetWindowDrawList ~= nil and imgui.GetWindowDrawList() or nil;

    if (drawList ~= nil and imgui.GetColorU32 ~= nil) then
        drawList:AddRectFilled(
            { bgX, bgY - 2 },
            { bgX + math.max(1, bgWidth), bgY + 22 },
            imgui.GetColorU32({ 0.0, 0.0, 0.0, 0.95 }),
            0
        );
    end

    imgui.TextColored({ 1.0, 1.0, 1.0, 1.0 }, 'Selected: ');

    if (imgui.SameLine ~= nil) then
        imgui.SameLine();
    end

    for i, part in ipairs(items) do
        local isCurrent = (i == #items);
        imgui.TextColored(isCurrent and { 1.0, 0.84, 0.0, 1.0 } or { 1.0, 1.0, 1.0, 1.0 }, tostring(part or ''));

        if (i < #items and imgui.SameLine ~= nil) then
            imgui.SameLine();
            imgui.TextColored({ 1.0, 1.0, 1.0, 1.0 }, '>');
            imgui.SameLine();
        end
    end
end

function GetPeerIconStyles()
    local styles = T{};
    local seen = {};
    local root = tostring(addon.path or '') .. '\\assets\\images\\peer-icons';

function addStyle(value)
        local name = tostring(value or ''):gsub('^.*[\\/]', '');

        if (name == '' or name == '.' or name == '..') then
            return;
        end

        if (seen[string.lower(name)] == true) then
            return;
        end

        local testPath = root .. '\\' .. name .. '\\AggroHQ.png';
        local ok, exists = pcall(function()
            return ashita.fs.exists(testPath);
        end);

        if (ok == true and exists == true) then
            seen[string.lower(name)] = true;
            styles[#styles + 1] = name;
        end
    end

    local ok, entries = pcall(function()
        if (ashita.fs.get_directory ~= nil) then
            return ashita.fs.get_directory(root, '.*');
        end

        if (ashita.fs.get_dir ~= nil) then
            return ashita.fs.get_dir(root, '.*');
        end

        return nil;
    end);

    if (ok == true and entries ~= nil) then
        for _, entry in ipairs(entries) do
            if (type(entry) == 'table') then
                addStyle(entry.name or entry.Name or entry.path or entry.Path);
            else
                addStyle(entry);
            end
        end
    end

    addStyle('round');
    addStyle('mobdb');
    table.sort(styles, function(a, b) return string.lower(tostring(a)) < string.lower(tostring(b)); end);

    return styles;
end

local peerEnemyInfoItems = T{
    'Background',
    'Name',
    'HP bar',
    'Job',
    'Level',
    'Range',
    'ID',
    'Aggro/passive',
    'Detection/link',
    'Immunities',
    'Damage modifiers',
};

function EnsurePeerTextDefaults(peer, prefix, offsetX, offsetY)
    if (peer[prefix .. 'OffsetX'] == nil) then peer[prefix .. 'OffsetX'] = offsetX; end
    if (peer[prefix .. 'OffsetY'] == nil) then peer[prefix .. 'OffsetY'] = offsetY; end
    if (peer[prefix .. 'FontSize'] == nil) then peer[prefix .. 'FontSize'] = 12; end
    if (peer[prefix .. 'Color'] == nil) then peer[prefix .. 'Color'] = { 1.0, 1.0, 1.0, 1.0 }; end
    if (peer[prefix .. 'OutlineSize'] == nil) then peer[prefix .. 'OutlineSize'] = 2; end
    if (peer[prefix .. 'OutlineColor'] == nil) then peer[prefix .. 'OutlineColor'] = { 0.0, 0.0, 0.0, 1.0 }; end
end

function EnsurePeerJobDefaults(peer)
    if (peer.showJob == nil) then peer.showJob = true; end
    if (peer.jobDisplay == nil) then peer.jobDisplay = 'Text'; end
    if (peer.jobIconTheme == nil) then peer.jobIconTheme = 'FFXI'; end
    if (peer.jobIconSize == nil) then peer.jobIconSize = 18; end
    EnsurePeerTextDefaults(peer, 'job', -190, -16);
end

function EnsurePeerLevelDefaults(peer)
    if (peer.showLevel == nil) then peer.showLevel = true; end
    EnsurePeerTextDefaults(peer, 'level', -145, -16);
    if (peer.levelDifficultyColorsEnabled == nil) then peer.levelDifficultyColorsEnabled = false; end
    if (peer.levelTwColor == nil) then peer.levelTwColor = { 0.55, 0.55, 0.55, 1.0 }; end
    if (peer.levelEpColor == nil) then peer.levelEpColor = { 0.45, 0.72, 1.0, 1.0 }; end
    if (peer.levelDcColor == nil) then peer.levelDcColor = { 0.40, 0.90, 0.45, 1.0 }; end
    if (peer.levelEmColor == nil) then peer.levelEmColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (peer.levelTColor == nil) then peer.levelTColor = { 1.0, 0.90, 0.35, 1.0 }; end
    if (peer.levelVtColor == nil) then peer.levelVtColor = { 1.0, 0.62, 0.25, 1.0 }; end
    if (peer.levelItColor == nil) then peer.levelItColor = { 1.0, 0.30, 0.30, 1.0 }; end
end

function EnsurePeerIconDefaults(peer, prefix, offsetX, offsetY)
    if (peer[prefix .. 'OffsetX'] == nil) then peer[prefix .. 'OffsetX'] = offsetX; end
    if (peer[prefix .. 'OffsetY'] == nil) then peer[prefix .. 'OffsetY'] = offsetY; end
    if (peer[prefix .. 'IconSize'] == nil) then peer[prefix .. 'IconSize'] = peer.iconSize or 18; end

    if (prefix == 'aggro') then
        if (peer[prefix .. 'FontSize'] == nil) then peer[prefix .. 'FontSize'] = 12; end
        if (peer[prefix .. 'Color'] == nil) then peer[prefix .. 'Color'] = { 1.0, 1.0, 1.0, 1.0 }; end
        if (peer[prefix .. 'OutlineSize'] == nil) then peer[prefix .. 'OutlineSize'] = 2; end
        if (peer[prefix .. 'OutlineColor'] == nil) then peer[prefix .. 'OutlineColor'] = { 0.0, 0.0, 0.0, 1.0 }; end
    end
end

function EnsurePeerHpBarDefaults(peer)
    if (peer.showHpBar == nil) then peer.showHpBar = true; end
    if (peer.hpBarOffsetX == nil) then peer.hpBarOffsetX = 0; end
    if (peer.hpBarOffsetY == nil) then peer.hpBarOffsetY = 0; end
    if (peer.hpBarWidth == nil) then peer.hpBarWidth = 437; end
    if (peer.hpBarHeight == nil) then peer.hpBarHeight = 16; end
    if (peer.hpBarColor == nil) then peer.hpBarColor = { 0.0, 0.75, 0.16, 1.0 }; end
    if (peer.hpBarBackgroundColor == nil) then peer.hpBarBackgroundColor = { 0.05, 0.05, 0.05, 0.85 }; end
    if (peer.hpBarBorderSize == nil) then peer.hpBarBorderSize = 0; end
    if (peer.hpBarBorderColor == nil) then peer.hpBarBorderColor = { 0.0, 0.0, 0.0, 1.0 }; end
    if (peer.showHpPercent == nil) then peer.showHpPercent = true; end
    if (peer.hpPercentOffsetX == nil) then peer.hpPercentOffsetX = 0; end
    if (peer.hpPercentOffsetY == nil) then peer.hpPercentOffsetY = 0; end
    if (peer.hpPercentFontSize == nil) then peer.hpPercentFontSize = 12; end
    if (peer.hpPercentColor == nil) then peer.hpPercentColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (peer.hpPercentOutlineSize == nil) then peer.hpPercentOutlineSize = 2; end
    if (peer.hpPercentOutlineColor == nil) then peer.hpPercentOutlineColor = { 0.0, 0.0, 0.0, 1.0 }; end
end

function EnsurePeerBackgroundDefaults(peer)
    peer.showBackground = true;
    if (peer.backgroundOffsetX == nil) then peer.backgroundOffsetX = 0; end
    if (peer.backgroundOffsetY == nil) then peer.backgroundOffsetY = 0; end
    if (peer.backgroundWidth == nil) then peer.backgroundWidth = 460; end
    if (peer.backgroundHeight == nil) then peer.backgroundHeight = 72; end
    if (peer.backgroundColor == nil) then peer.backgroundColor = { 0.0, 0.0, 0.0, 0.45 }; end
    if (peer.backgroundOpacity == nil) then peer.backgroundOpacity = math.floor(((tonumber(peer.backgroundColor[4]) or 0.45) * 100) + 0.5); end
    if (peer.backgroundBorderSize == nil) then peer.backgroundBorderSize = 0; end
    if (peer.backgroundBorderColor == nil) then peer.backgroundBorderColor = { 0.0, 0.0, 0.0, 1.0 }; end
end

function EnsurePeerNameDefaults(peer)
    if (peer.showName == nil) then peer.showName = true; end
    if (peer.nameOffsetX == nil) then peer.nameOffsetX = 0; end
    if (peer.nameOffsetY == nil) then peer.nameOffsetY = -54; end
    if (peer.nameFontSize == nil) then peer.nameFontSize = 32; end
    if (peer.nameColor == nil) then peer.nameColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (peer.nameOutlineSize == nil) then peer.nameOutlineSize = 3; end
    if (peer.nameOutlineColor == nil) then peer.nameOutlineColor = { 0.0, 0.0, 0.0, 1.0 }; end
end

function EnsurePeerIdDefaults(peer)
    if (peer.showId == nil) then peer.showId = false; end
    if (peer.idOffsetX == nil) then peer.idOffsetX = 0; end
    if (peer.idOffsetY == nil) then peer.idOffsetY = 24; end
    if (peer.idFontSize == nil) then peer.idFontSize = 7; end
    if (peer.idColor == nil) then peer.idColor = { 0.65, 0.90, 1.0, 1.0 }; end
    if (peer.idOutlineSize == nil) then peer.idOutlineSize = 2; end
    if (peer.idOutlineColor == nil) then peer.idOutlineColor = { 0.0, 0.0, 0.0, 1.0 }; end
    if (peer.idBoxEnabled == nil) then peer.idBoxEnabled = true; end
    if (peer.idBoxSize == nil) then peer.idBoxSize = 18; end
    if (peer.idBoxColor == nil) then peer.idBoxColor = { 0.45, 0.15, 0.15, 0.90 }; end
    if (peer.idBoxBorderSize == nil) then peer.idBoxBorderSize = 0; end
    if (peer.idBoxBorderColor == nil) then peer.idBoxBorderColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (peer.idCornerRadius == nil) then peer.idCornerRadius = 4; end
end

function DrawPeerActive(activeKey, settings)
    DrawCheckbox('Active', settings.peer[activeKey] == true, function(value)
        settings.peer[activeKey] = value == true;
        state.Save();
    end);
end

function DrawPeerTextComponentSettings(settings, activeKey, prefix, label)
    local peer = settings.peer;

    DrawPeerActive(activeKey, settings);

    if (peer[activeKey] ~= true) then
        return;
    end

    local x, xChanged, y, yChanged = DrawPlacementPair('Position X', peer[prefix .. 'OffsetX'], 'Peer' .. label .. 'X', 'Position Y', peer[prefix .. 'OffsetY'], 'Peer' .. label .. 'Y', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        peer[prefix .. 'OffsetX'] = x;
        peer[prefix .. 'OffsetY'] = y;
        state.Save();
    end

    DrawPeerFontRow(peer, prefix, label);
    DrawPeerOutlineRow(peer, prefix, label);
end

function DrawPeerDifficultyColorInline(peer, label, key, colorId, continueLine)
    imgui.TextColored(peer[key] or { 1.0, 1.0, 1.0, 1.0 }, label);
    imgui.SameLine();

    local nextColor, changed = DrawInlineColorControl(peer[key], colorId);
    peer[key] = nextColor;
    if (changed == true) then state.Save(); end

    if (continueLine == true) then
        imgui.SameLine();
    end
end

function DrawPeerLevelComponentSettings(settings)
    local peer = settings.peer;

    DrawPeerTextComponentSettings(settings, 'showLevel', 'level', 'Level');

    if (peer.showLevel ~= true) then
        return;
    end

    imgui.Separator();
    DrawYellowHeader('Difficulty colors');

    DrawCheckbox('Use difficulty colors', peer.levelDifficultyColorsEnabled == true, function(value)
        peer.levelDifficultyColorsEnabled = value == true;
        state.Save();
    end);

    if (peer.levelDifficultyColorsEnabled == true) then
        DrawPeerDifficultyColorInline(peer, 'TW', 'levelTwColor', 'PeerLevelTwColor', true);
        DrawPeerDifficultyColorInline(peer, 'EP', 'levelEpColor', 'PeerLevelEpColor', true);
        DrawPeerDifficultyColorInline(peer, 'DC', 'levelDcColor', 'PeerLevelDcColor', true);
        DrawPeerDifficultyColorInline(peer, 'EM', 'levelEmColor', 'PeerLevelEmColor', true);
        DrawPeerDifficultyColorInline(peer, 'T', 'levelTColor', 'PeerLevelTColor', true);
        DrawPeerDifficultyColorInline(peer, 'VT', 'levelVtColor', 'PeerLevelVtColor', true);
        DrawPeerDifficultyColorInline(peer, 'IT', 'levelItColor', 'PeerLevelItColor', false);
    end
end

function DrawSmallComboControl(id, items, selected, onSelect)
    local current = tostring(selected or items[1] or 'Default');
    local comboId = '##' .. tostring(id or 'combo');

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(124); end

        if (imgui.BeginCombo(comboId, current) == true) then
            for _, item in ipairs(items) do
                local isSelected = item == current;

                if (imgui.Selectable(tostring(item), isSelected) == true) then
                    onSelect(item);
                end

                if (isSelected == true and imgui.SetItemDefaultFocus ~= nil) then
                    imgui.SetItemDefaultFocus();
                end
            end

            imgui.EndCombo();
        end

        if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
        return;
    end

    imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, '[' .. current .. ' v]');

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        local nextIndex = 1;

        for i, item in ipairs(items) do
            if (item == current) then
                nextIndex = i + 1;
                break;
            end
        end

        if (nextIndex > #items) then nextIndex = 1; end
        onSelect(items[nextIndex]);
    end
end

function DrawPeerJobDisplayRow(peer)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local iconMode = tostring(peer.jobDisplay or 'Text') == 'Icon';
        local columnCount = iconMode == true and 4 or 2;

        if (imgui.BeginTable('##peer_job_display_row', columnCount, settingsTableFlags)) then
            imgui.TableSetupColumn('##display_label', 0, 104);
            imgui.TableSetupColumn('##display_control', 0, 124);

            if (iconMode == true) then
                imgui.TableSetupColumn('##theme_label', 0, 104);
                imgui.TableSetupColumn('##theme_control', 0, 124);
            end

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, 'Display');
            imgui.TableNextColumn();
            DrawSmallComboControl('PeerJobDisplay', T{ 'Text', 'Icon' }, peer.jobDisplay or 'Text', function(value)
                peer.jobDisplay = value;
                state.Save();
            end);

            if (iconMode == true) then
                imgui.TableNextColumn();
                imgui.TextColored(settingsLabelColor, 'Icon theme');
                imgui.TableNextColumn();
                DrawSmallComboControl('PeerJobIconTheme', jobIconTextures.GetThemeNames(), peer.jobIconTheme or 'FFXI', function(value)
                    peer.jobIconTheme = value;
                    state.Save();
                end);
            end

            imgui.EndTable();
        end

        return;
    end

    DrawInlineComboRow('Display', T{ 'Text', 'Icon' }, peer.jobDisplay or 'Text', function(value)
        peer.jobDisplay = value;
        state.Save();
    end, 'PeerJobDisplay');

    if (tostring(peer.jobDisplay or 'Text') == 'Icon') then
        DrawInlineComboRow('Icon theme', jobIconTextures.GetThemeNames(), peer.jobIconTheme or 'FFXI', function(value)
            peer.jobIconTheme = value;
            state.Save();
        end, 'PeerJobIconTheme');
    end
end

function DrawPeerJobComponentSettings(settings)
    local peer = settings.peer;

    DrawPeerActive('showJob', settings);

    if (peer.showJob ~= true) then
        return;
    end

    DrawPeerJobDisplayRow(peer);

    local x, xChanged, y, yChanged = DrawPlacementPair('Position X', peer.jobOffsetX, 'PeerJobX', 'Position Y', peer.jobOffsetY, 'PeerJobY', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        peer.jobOffsetX = x;
        peer.jobOffsetY = y;
        state.Save();
    end

    if (tostring(peer.jobDisplay or 'Text') == 'Icon') then
        local iconSize, iconSizeChanged = DrawPlacementSingle('Icon size', peer.jobIconSize, 'PeerJobIconSize', 6, 160, 1);
        if (iconSizeChanged == true) then
            peer.jobIconSize = iconSize;
            state.Save();
        end
    else
        DrawPeerFontRow(peer, 'job', 'Job');
        DrawPeerOutlineRow(peer, 'job', 'Job');
    end
end

function DrawPeerIconComponentSettings(settings, activeKey, prefix, label)
    local peer = settings.peer;

    DrawPeerActive(activeKey, settings);

    if (peer[activeKey] ~= true) then
        return;
    end

    local x, xChanged, y, yChanged = DrawPlacementPair('Position X', peer[prefix .. 'OffsetX'], 'Peer' .. label .. 'X', 'Position Y', peer[prefix .. 'OffsetY'], 'Peer' .. label .. 'Y', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        peer[prefix .. 'OffsetX'] = x;
        peer[prefix .. 'OffsetY'] = y;
        state.Save();
    end

    local iconSize, iconSizeChanged = DrawPlacementSingle('Icon size', peer[prefix .. 'IconSize'], 'Peer' .. label .. 'IconSize', 6, 64, 1, 104, 124, 58);
    if (iconSizeChanged == true) then
        peer[prefix .. 'IconSize'] = iconSize;
        state.Save();
    end

    if (prefix == 'aggro') then
        DrawPeerFontRow(peer, prefix, label);
        DrawPeerOutlineRow(peer, prefix, label);
    end
end

function DrawPeerHpBarComponentSettings(settings)
    local peer = settings.peer;

    DrawPeerActive('showHpBar', settings);

    if (peer.showHpBar ~= true) then
        return;
    end

    local x, xChanged, y, yChanged = DrawPlacementPair('HP bar X', peer.hpBarOffsetX, 'PeerHpBarX', 'HP bar Y', peer.hpBarOffsetY, 'PeerHpBarY', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        peer.hpBarOffsetX = x;
        peer.hpBarOffsetY = y;
        state.Save();
    end

    local width, widthChanged, height, heightChanged = DrawPlacementPair('Width', peer.hpBarWidth, 'PeerHpBarWidth', 'Height', peer.hpBarHeight, 'PeerHpBarHeight', 1, 900, 1);
    if (widthChanged == true or heightChanged == true) then
        peer.hpBarWidth = width;
        peer.hpBarHeight = height;
        state.Save();
    end

    local fillColor, fillChanged = DrawSettingsColor('Fill color', peer.hpBarColor, 'PeerHpBarColor');
    peer.hpBarColor = fillColor;
    if (fillChanged == true) then state.Save(); end

    local bgColor, bgChanged = DrawSettingsColor('Background color', peer.hpBarBackgroundColor, 'PeerHpBarBackgroundColor');
    peer.hpBarBackgroundColor = bgColor;
    if (bgChanged == true) then state.Save(); end

    local borderColor, borderChanged = DrawSettingsColor('Border color', peer.hpBarBorderColor, 'PeerHpBarBorderColor');
    peer.hpBarBorderColor = borderColor;
    if (borderChanged == true) then state.Save(); end

    local borderSize, borderSizeChanged = DrawPlacementSingle('Border size', peer.hpBarBorderSize, 'PeerHpBarBorderSize', 0, 24, 1);
    if (borderSizeChanged == true) then
        peer.hpBarBorderSize = borderSize;
        state.Save();
    end

    imgui.Separator();
    DrawYellowHeader('HP percent');

    DrawCheckbox('Active', peer.showHpPercent == true, function(value)
        peer.showHpPercent = value == true;
        state.Save();
    end);

    if (peer.showHpPercent == true) then
        local tx, txChanged, ty, tyChanged = DrawPlacementPair('Percent X', peer.hpPercentOffsetX, 'PeerHpPercentX', 'Percent Y', peer.hpPercentOffsetY, 'PeerHpPercentY', -500, 500, 1);
        if (txChanged == true or tyChanged == true) then
            peer.hpPercentOffsetX = tx;
            peer.hpPercentOffsetY = ty;
            state.Save();
        end

        local fontSize, fontSizeChanged = DrawPlacementSingle('Font size', textScale.NormalizeSetting(peer.hpPercentFontSize, 12), 'PeerHpPercentFontSize', textScale.GetMinVisualSize(), textScale.GetMaxVisualSize(), 1);
        if (fontSizeChanged == true) then
            peer.hpPercentFontSize = fontSize;
            state.Save();
        end

        local textColor, textColorChanged = DrawSettingsColor('Font color', peer.hpPercentColor, 'PeerHpPercentColor');
        peer.hpPercentColor = textColor;
        if (textColorChanged == true) then state.Save(); end

        local outlineColor, outlineColorChanged = DrawSettingsColor('Outline color', peer.hpPercentOutlineColor, 'PeerHpPercentOutlineColor');
        peer.hpPercentOutlineColor = outlineColor;
        if (outlineColorChanged == true) then state.Save(); end

        local outlineSize, outlineSizeChanged = DrawPlacementSingle('Outline size', peer.hpPercentOutlineSize, 'PeerHpPercentOutlineSize', 0, 12, 1);
        if (outlineSizeChanged == true) then
            peer.hpPercentOutlineSize = outlineSize;
            state.Save();
        end
    end
end

function DrawPeerBackgroundComponentSettings(settings)
    local peer = settings.peer;

    peer.showBackground = true;

    local width, widthChanged, height, heightChanged = DrawPlacementPair('Width', peer.backgroundWidth, 'PeerBackgroundWidth', 'Height', peer.backgroundHeight, 'PeerBackgroundHeight', 1, 900, 1);
    if (widthChanged == true or heightChanged == true) then
        peer.backgroundWidth = width;
        peer.backgroundHeight = height;
        state.Save();
    end

    local x, xChanged, y, yChanged = DrawPlacementPair('Position X', peer.backgroundOffsetX, 'PeerBackgroundX', 'Position Y', peer.backgroundOffsetY, 'PeerBackgroundY', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        peer.backgroundOffsetX = x;
        peer.backgroundOffsetY = y;
        state.Save();
    end

    local fillColor, fillChanged, opacity, opacityChanged = DrawColorAndPlacementRow('Fill color', peer.backgroundColor, 'PeerBackgroundColor', 'Opacity', peer.backgroundOpacity, 'PeerBackgroundOpacity', 0, 100, 1);
    fillColor[4] = 1.0;
    peer.backgroundColor = fillColor;
    if (fillChanged == true or opacityChanged == true) then
        peer.backgroundOpacity = opacity;
        state.Save();
    end

    local borderColor, borderChanged, borderSize, borderSizeChanged = DrawColorAndPlacementRow('Border color', peer.backgroundBorderColor, 'PeerBackgroundBorderColor', 'Border size', peer.backgroundBorderSize, 'PeerBackgroundBorderSize', 0, 24, 1);
    peer.backgroundBorderColor = borderColor;
    if (borderChanged == true or borderSizeChanged == true) then
        peer.backgroundBorderSize = borderSize;
        state.Save();
    end
end

function DrawPeerIdComponentSettings(settings)
    local peer = settings.peer;

    DrawPeerActive('showId', settings);

    if (peer.showId ~= true) then
        return;
    end

    local x, xChanged, y, yChanged = DrawPlacementPair('Position X', peer.idOffsetX, 'PeerIdX', 'Position Y', peer.idOffsetY, 'PeerIdY', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        peer.idOffsetX = x;
        peer.idOffsetY = y;
        state.Save();
    end

    DrawPeerFontRow(peer, 'id', 'Id');
    DrawPeerOutlineRow(peer, 'id', 'Id');

    imgui.Separator();
    DrawYellowHeader('ID box');

    DrawCheckbox('Active', peer.idBoxEnabled == true, function(value)
        peer.idBoxEnabled = value == true;
        state.Save();
    end);

    if (peer.idBoxEnabled == true) then
        local boxColor, boxColorChanged, boxSize, boxSizeChanged = DrawColorAndPlacementRow('Box color', peer.idBoxColor, 'PeerIdBoxColor', 'Box size', peer.idBoxSize, 'PeerIdBoxSize', 4, 160, 1);
        peer.idBoxColor = boxColor;
        if (boxColorChanged == true or boxSizeChanged == true) then
            peer.idBoxSize = boxSize;
            state.Save();
        end

        local borderColor, borderColorChanged, borderSize, borderSizeChanged = DrawColorAndPlacementRow('Border color', peer.idBoxBorderColor, 'PeerIdBoxBorderColor', 'Border size', peer.idBoxBorderSize, 'PeerIdBoxBorderSize', 0, 24, 1);
        peer.idBoxBorderColor = borderColor;
        if (borderColorChanged == true or borderSizeChanged == true) then
            peer.idBoxBorderSize = borderSize;
            state.Save();
        end

        local cornerRadius, cornerRadiusChanged = DrawPlacementSingle('Corner radius', peer.idCornerRadius, 'PeerIdCornerRadius', 0, 40, 1);
        if (cornerRadiusChanged == true) then
            peer.idCornerRadius = cornerRadius;
            state.Save();
        end
    end
end

function LibraPlatesSettingsEnsurePeerInspectorDefaults(peer)
    if (peer.displayMode == nil) then peer.displayMode = 'Text'; end
    if (peer.inspectorWidth == nil) then peer.inspectorWidth = 430; end
    if (peer.textFontSize == nil) then peer.textFontSize = 14; end
    if (peer.textColor == nil) then peer.textColor = { 0.94, 0.94, 0.90, 1.0 }; end
    if (peer.textOutlineSize == nil) then peer.textOutlineSize = 1; end
    if (peer.textOutlineColor == nil) then peer.textOutlineColor = { 0.0, 0.0, 0.0, 1.0 }; end
    if (peer.showName == nil) then peer.showName = true; end
    if (peer.showLevel == nil) then peer.showLevel = true; end
    if (peer.showHpValue == nil) then peer.showHpValue = true; end
    if (peer.showDistance == nil) then peer.showDistance = peer.showRange ~= false; end
    if (peer.showBehavior == nil) then peer.showBehavior = peer.showAggro ~= false; end
    if (peer.showDetects == nil) then peer.showDetects = peer.showDetection ~= false; end
    if (peer.showLinks == nil) then peer.showLinks = peer.showDetection ~= false; end
    if (peer.showWeakTo == nil) then peer.showWeakTo = peer.showModifiers ~= false; end
    if (peer.showResists == nil) then peer.showResists = peer.showModifiers ~= false; end
end

function LibraPlatesSettingsDrawPeerInspectorBackgroundSettings(peer)
    DrawYellowHeader('Background');

    local fillColor, fillChanged, opacity, opacityChanged = DrawColorAndPlacementRow('Fill color', peer.backgroundColor, 'PeerInspectorBackgroundColor', 'Opacity', peer.backgroundOpacity, 'PeerInspectorBackgroundOpacity', 0, 100, 1);
    fillColor[4] = 1.0;
    peer.backgroundColor = fillColor;
    if (fillChanged == true or opacityChanged == true) then
        peer.backgroundOpacity = opacity;
        state.Save();
    end

    local borderColor, borderChanged, borderSize, borderSizeChanged = DrawColorAndPlacementRow('Border color', peer.backgroundBorderColor, 'PeerInspectorBorderColor', 'Border size', peer.backgroundBorderSize, 'PeerInspectorBorderSize', 0, 12, 1);
    peer.backgroundBorderColor = borderColor;
    if (borderChanged == true or borderSizeChanged == true) then
        peer.backgroundBorderSize = borderSize;
        state.Save();
    end
end

function LibraPlatesSettingsDrawPeerSectionCheckbox(peer, label, key)
    DrawCheckbox(label, peer[key] ~= false, function(value)
        peer[key] = value == true;
        state.Save();
    end);
end

function LibraPlatesSettingsDrawPeerSectionList(peer)
    DrawYellowHeader('Sections');

    local rows = T{
        T{
            { label = 'Name', key = 'showName' },
            { label = 'Job', key = 'showJob' },
            { label = 'Level', key = 'showLevel' },
        },
        T{
            { label = 'Behavior', key = 'showBehavior' },
            { label = 'Detects', key = 'showDetects' },
            { label = 'Links', key = 'showLinks' },
        },
        T{
            { label = 'Weak To', key = 'showWeakTo' },
            { label = 'Resists', key = 'showResists' },
            { label = 'Immunities', key = 'showImmunities' },
        },
        T{
            { label = 'HP', key = 'showHpValue' },
            { label = 'Distance', key = 'showDistance' },
        },
    };

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##peer_sections', 3, settingsTableFlags)) then
            imgui.TableSetupColumn('##section_1', 0, 150);
            imgui.TableSetupColumn('##section_2', 0, 150);
            imgui.TableSetupColumn('##section_3', 0, 150);

            for _, row in ipairs(rows) do
                imgui.TableNextRow();

                for column = 1, 3 do
                    imgui.TableNextColumn();

                    local item = row[column];
                    if (item ~= nil) then
                        LibraPlatesSettingsDrawPeerSectionCheckbox(peer, item.label, item.key);
                    end
                end
            end

            imgui.EndTable();
        end

        return;
    end

    for _, row in ipairs(rows) do
        for _, item in ipairs(row) do
            LibraPlatesSettingsDrawPeerSectionCheckbox(peer, item.label, item.key);
        end
    end
end

function LibraPlatesSettingsDrawPeerModuleSettings(settings, options)
    options = options or {};
    settings.peer = settings.peer or {};

    if (settings.peer.activationModifier == nil) then settings.peer.activationModifier = 'Shift'; end
    if (settings.peer.maxRange == nil) then settings.peer.maxRange = 49.9; end
    if (settings.peer.zoom == nil) then settings.peer.zoom = settings.peer.minScale or 3.0; end
    if (settings.peer.iconStyle == nil) then settings.peer.iconStyle = 'round'; end
    if (settings.peer.iconSize == nil) then settings.peer.iconSize = 18; end
    if (settings.peer.iconOffsetX == nil) then settings.peer.iconOffsetX = -190; end
    if (settings.peer.iconOffsetY == nil) then settings.peer.iconOffsetY = -16; end
    EnsurePeerBackgroundDefaults(settings.peer);
    LibraPlatesSettingsEnsurePeerInspectorDefaults(settings.peer);
    EnsurePeerNameDefaults(settings.peer);
    EnsurePeerHpBarDefaults(settings.peer);
    EnsurePeerJobDefaults(settings.peer);
    EnsurePeerLevelDefaults(settings.peer);
    if (settings.peer.showRange == nil) then settings.peer.showRange = true; end
    EnsurePeerTextDefaults(settings.peer, 'range', 92, -54);
    EnsurePeerIdDefaults(settings.peer);
    if (settings.peer.showAggro == nil) then settings.peer.showAggro = true; end
    EnsurePeerIconDefaults(settings.peer, 'aggro', -95, -16);
    if (settings.peer.showDetection == nil) then settings.peer.showDetection = true; end
    EnsurePeerIconDefaults(settings.peer, 'detection', -55, -16);
    if (settings.peer.showImmunities == nil) then settings.peer.showImmunities = true; end
    EnsurePeerIconDefaults(settings.peer, 'immunity', 45, -16);
    if (settings.peer.showModifiers == nil) then settings.peer.showModifiers = true; end
    EnsurePeerIconDefaults(settings.peer, 'modifier', 120, -16);
    if (settings.peer.showModifierValues == nil) then settings.peer.showModifierValues = true; end
    if (settings.peer.modifierValueFontSize == nil) then settings.peer.modifierValueFontSize = 12; end
    if (settings.peer.modifierValueColor == nil) then settings.peer.modifierValueColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (settings.peer.modifierValueOutlineSize == nil) then settings.peer.modifierValueOutlineSize = 2; end
    if (settings.peer.modifierValueOutlineColor == nil) then settings.peer.modifierValueOutlineColor = { 0.0, 0.0, 0.0, 1.0 }; end

    DrawInlineComboRow('Modifier', T{ 'Shift', 'Ctrl', 'Alt', 'None' }, settings.peer.activationModifier, function(value)
        settings.peer.activationModifier = value;
        state.Save();
    end, 'PeerModifier');
    uiTooltip.Info('Peer opens while hovering a plate and holding this modifier. None means hover alone can open Peer.');

    local inspectorWidth, inspectorWidthChanged = DrawPlacementSingle('Window width', settings.peer.inspectorWidth, 'PeerInspectorWidth', 220, 800, 1, 104, 124, 58);
    if (inspectorWidthChanged == true) then
        settings.peer.inspectorWidth = inspectorWidth;
        state.Save();
    end

    if (options.hideDisplayMode ~= true) then
        DrawInlineComboRow('Display', T{ 'Text', 'Icons' }, settings.peer.displayMode, function(value)
            settings.peer.displayMode = value;
            state.Save();
        end, 'PeerDisplayMode');
    end

    imgui.Separator();

    if (options.hideDisplayMode == true) then
        -- Self Peer uses a fixed text layout with its own elemental icons.
    elseif (tostring(settings.peer.displayMode or 'Icons') == 'Text') then
        local textColor, textColorChanged = DrawSettingsColor('Font color', settings.peer.textColor, 'PeerTextColor');
        settings.peer.textColor = textColor;
        if (textColorChanged == true) then state.Save(); end

        local outlineSize, outlineSizeChanged, outlineColor, outlineColorChanged = DrawPlacementAndColorRow(
            'Outline size',
            settings.peer.textOutlineSize,
            'PeerTextOutlineSize',
            0,
            4,
            1,
            'Outline color',
            settings.peer.textOutlineColor,
            'PeerTextOutlineColor'
        );
        settings.peer.textOutlineColor = outlineColor;
        if (outlineSizeChanged == true or outlineColorChanged == true) then
            settings.peer.textOutlineSize = outlineSize;
            state.Save();
        end
    else
        DrawInlineComboRow('Icon pack', GetPeerIconStyles(), settings.peer.iconStyle, function(value)
            settings.peer.iconStyle = value;
            state.Save();
        end, 'PeerIconStyle');

        local iconSize, iconSizeChanged = DrawPlacementSingle('Icon size', settings.peer.iconSize, 'PeerInspectorIconSize', 6, 64, 1, 104, 124, 58);
        if (iconSizeChanged == true) then
            settings.peer.iconSize = iconSize;
            state.Save();
        end
    end

    imgui.Separator();
    LibraPlatesSettingsDrawPeerInspectorBackgroundSettings(settings.peer);

    if (options.hideSections ~= true) then
        imgui.Separator();
        LibraPlatesSettingsDrawPeerSectionList(settings.peer);
    end
end

function LibraPlatesSettingsDrawEnmityModuleSettings(settings, hideActive)
    settings.enmity = settings.enmity or {};

    if (settings.enmity.enabled == nil) then settings.enmity.enabled = true; end
    if (settings.enmity.mode == nil) then settings.enmity.mode = 'healer'; end
    if (settings.enmity.offsetX == nil) then settings.enmity.offsetX = -108; end
    if (settings.enmity.offsetY == nil) then settings.enmity.offsetY = -17; end
    if (settings.enmity.iconSize == nil) then settings.enmity.iconSize = 31; end

    if (hideActive ~= true) then
        DrawCheckbox('Active', settings.enmity.enabled == true, function(value)
            settings.enmity.enabled = value == true;
            state.Save();
        end);
    end

    if (settings.enmity.enabled ~= true and hideActive ~= true) then
        return;
    end

    local modeDisplay = (tostring(settings.enmity.mode or 'healer'):lower() == 'tank') and 'Tank' or 'Healer';
    DrawInlineComboRow('Mode', T{ 'Healer', 'Tank' }, modeDisplay, function(value)
        settings.enmity.mode = tostring(value or 'Healer'):lower();
        state.Save();
    end, 'EnmityMode');

    local x, xChanged, y, yChanged = DrawPlacementPair('Position X', settings.enmity.offsetX, 'EnmityIconX', 'Position Y', settings.enmity.offsetY, 'EnmityIconY', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        settings.enmity.offsetX = x;
        settings.enmity.offsetY = y;
        state.Save();
    end

    local iconSize, iconSizeChanged = DrawPlacementSingle('Icon size', settings.enmity.iconSize, 'EnmityIconSize', 6, 160, 1, 104, 124, 58);
    if (iconSizeChanged == true) then
        settings.enmity.iconSize = iconSize;
        state.Save();
    end
end

function LibraPlatesSettingsDrawRestingModuleSettings(settings, hideActive)
    settings.resting = settings.resting or {};

    if (settings.resting.enabled == nil) then settings.resting.enabled = true; end
    if (settings.resting.displayMode == nil) then settings.resting.displayMode = 'Bar'; end
    if (settings.resting.width == nil) then settings.resting.width = 180; end
    if (settings.resting.height == nil) then settings.resting.height = 12; end
    if (settings.resting.ringSize == nil) then settings.resting.ringSize = 88; end
    if (settings.resting.ringThickness == nil) then settings.resting.ringThickness = 10; end
    if (settings.resting.offsetX == nil) then settings.resting.offsetX = 0; end
    if (settings.resting.offsetY == nil) then settings.resting.offsetY = 38; end
    if (settings.resting.firstTickOffset == nil) then settings.resting.firstTickOffset = 1; end
    if (settings.resting.repeatTickOffset == nil) then settings.resting.repeatTickOffset = 0; end
    if (settings.resting.mpTickThreshold == nil) then settings.resting.mpTickThreshold = 12; end
    if (settings.resting.enableLogoutCountdown == nil) then settings.resting.enableLogoutCountdown = true; end
    if (settings.resting.color == nil) then settings.resting.color = { 0.55, 0.95, 0.35, 1.0 }; end
    if (settings.resting.backgroundColor == nil) then settings.resting.backgroundColor = { 0.10, 0.10, 0.10, 1.0 }; end
    if (settings.resting.borderColor == nil) then settings.resting.borderColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (settings.resting.borderSize == nil) then settings.resting.borderSize = 0; end
    if (settings.resting.fontSize == nil) then settings.resting.fontSize = 12; end
    if (settings.resting.textColor == nil) then settings.resting.textColor = { 0.0, 0.0, 0.0, 1.0 }; end
    if (settings.resting.textOutlineColor == nil) then settings.resting.textOutlineColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (settings.resting.textOutlineSize == nil) then settings.resting.textOutlineSize = 1; end

    if (hideActive ~= true) then
        DrawCheckbox('Active', settings.resting.enabled == true, function(value)
            settings.resting.enabled = value == true;
            state.Save();
        end);
    end

    if (settings.resting.enabled ~= true and hideActive ~= true) then
        return;
    end

    DrawInlineComboRow('Display', T{ 'Bar', 'Ring' }, settings.resting.displayMode or 'Bar', function(value)
        settings.resting.displayMode = value;
        state.Save();
    end, 'RestingDisplayMode');

    if (tostring(settings.resting.displayMode or 'Bar') == 'Ring') then
        local ringSize, ringSizeChanged, ringThickness, ringThicknessChanged = DrawPlacementPair('Ring size', settings.resting.ringSize, 'RestingRingSize', 'Ring thickness', settings.resting.ringThickness, 'RestingRingThickness', 1, 300, 1);
        if (ringSizeChanged == true or ringThicknessChanged == true) then
            settings.resting.ringSize = ringSize;
            settings.resting.ringThickness = ringThickness;
            state.Save();
        end
    else
        local width, widthChanged, height, heightChanged = DrawPlacementPair('Width', settings.resting.width, 'RestingWidth', 'Height', settings.resting.height, 'RestingHeight', 1, 900, 1);
        if (widthChanged == true or heightChanged == true) then
            settings.resting.width = width;
            settings.resting.height = height;
            state.Save();
        end
    end

    local x, xChanged, y, yChanged = DrawPlacementPair('Position X', settings.resting.offsetX, 'RestingX', 'Position Y', settings.resting.offsetY, 'RestingY', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        settings.resting.offsetX = x;
        settings.resting.offsetY = y;
        state.Save();
    end

    local fillColor, fillChanged = DrawSettingsColor('Fill color', settings.resting.color, 'RestingFillColor');
    if (fillChanged == true) then
        settings.resting.color = fillColor;
        state.Save();
    end

    local backgroundColor, backgroundChanged = DrawSettingsColor('Background color', settings.resting.backgroundColor, 'RestingBackgroundColor');
    if (backgroundChanged == true) then
        settings.resting.backgroundColor = backgroundColor;
        state.Save();
    end

    local borderColor, borderChanged, borderSize, borderSizeChanged = DrawColorAndPlacementRow(
        'Border color',
        settings.resting.borderColor,
        'RestingBorderColor',
        'Border size',
        settings.resting.borderSize,
        'RestingBorderSize',
        0,
        24,
        1
    );
    if (borderChanged == true or borderSizeChanged == true) then
        settings.resting.borderColor = borderColor;
        settings.resting.borderSize = borderSize;
        state.Save();
    end

    local firstOffset, firstChanged, repeatOffset, repeatChanged = DrawPlacementPair('First offset', settings.resting.firstTickOffset, 'RestingFirstOffset', 'Repeat offset', settings.resting.repeatTickOffset, 'RestingRepeatOffset', -10, 10, 1);
    if (firstChanged == true or repeatChanged == true) then
        settings.resting.firstTickOffset = firstOffset;
        settings.resting.repeatTickOffset = repeatOffset;
        state.Save();
    end

    local mpThreshold, mpThresholdChanged = DrawPlacementSingle('MP tick threshold', settings.resting.mpTickThreshold, 'RestingMpTickThreshold', 0, 100, 1, 154, 124, 58);
    if (mpThresholdChanged == true) then
        settings.resting.mpTickThreshold = mpThreshold;
        state.Save();
    end

    DrawCheckbox('Enable logout countdown', settings.resting.enableLogoutCountdown ~= false, function(value)
        settings.resting.enableLogoutCountdown = value == true;
        state.Save();
    end);

    DrawCheckbox('Hide at full HP', settings.resting.hideAtFullHp == true, function(value)
        settings.resting.hideAtFullHp = value == true;
        state.Save();
    end);

    DrawCheckbox('Hide at full MP', settings.resting.hideAtFullMp == true, function(value)
        settings.resting.hideAtFullMp = value == true;
        state.Save();
    end);

    local fontSize, fontSizeChanged, textColor, textColorChanged = DrawPlacementAndColorRow(
        'Text size',
        settings.resting.fontSize,
        'RestingFontSize',
        6,
        48,
        1,
        'Text color',
        settings.resting.textColor,
        'RestingTextColor'
    );
    if (fontSizeChanged == true or textColorChanged == true) then
        settings.resting.fontSize = fontSize;
        settings.resting.textColor = textColor;
        state.Save();
    end

    local outlineSize, outlineSizeChanged, outlineColor, outlineColorChanged = DrawPlacementAndColorRow(
        'Outline size',
        settings.resting.textOutlineSize,
        'RestingOutlineSize',
        0,
        12,
        1,
        'Outline color',
        settings.resting.textOutlineColor,
        'RestingOutlineColor'
    );
    if (outlineSizeChanged == true or outlineColorChanged == true) then
        settings.resting.textOutlineSize = outlineSize;
        settings.resting.textOutlineColor = outlineColor;
        settings.resting.textOutlineEnabled = outlineSize > 0;
        state.Save();
    end
end

function LibraPlatesSettingsDrawFishingModuleSettings(settings, hideActive)
    settings.fishing = settings.fishing or {};

    if (settings.fishing.enabled == nil) then settings.fishing.enabled = true; end
    if (settings.fishing.enableRightClickFish == nil) then settings.fishing.enableRightClickFish = true; end
    if (settings.fishing.enableRightClickGathering == nil) then settings.fishing.enableRightClickGathering = true; end
    if (settings.fishing.iconFile == nil) then settings.fishing.iconFile = 'fishing_01.png'; end
    if (settings.fishing.offsetX == nil) then settings.fishing.offsetX = 0; end
    if (settings.fishing.offsetY == nil) then settings.fishing.offsetY = 38; end
    if (settings.fishing.iconSize == nil) then settings.fishing.iconSize = 42; end
    if (settings.fishing.showLabel == nil) then settings.fishing.showLabel = true; end
    if (settings.fishing.labelFontSize == nil) then settings.fishing.labelFontSize = 12; end
    if (settings.fishing.labelOffsetY == nil) then settings.fishing.labelOffsetY = 0; end
    if (settings.fishing.labelColor == nil) then settings.fishing.labelColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (settings.fishing.labelOutlineColor == nil) then settings.fishing.labelOutlineColor = { 0.0, 0.0, 0.0, 1.0 }; end
    if (settings.fishing.labelOutlineSize == nil) then settings.fishing.labelOutlineSize = 2; end

    if (hideActive ~= true) then
        DrawCheckbox('Active', settings.fishing.enabled == true, function(value)
            settings.fishing.enabled = value == true;
            state.Save();
        end);
    end

    if (settings.fishing.enabled ~= true and hideActive ~= true) then
        return;
    end

    DrawCheckbox('Right-click fish with rod', settings.fishing.enableRightClickFish == true, function(value)
        settings.fishing.enableRightClickFish = value == true;
        state.Save();
    end);
    uiTooltip.Info('When a fishing rod is equipped in the ranged slot, right-clicking empty world space queues /fish. The game still decides whether you are close enough to fish.');

    DrawCheckbox('Right-click gathering actions', settings.fishing.enableRightClickGathering == true, function(value)
        settings.fishing.enableRightClickGathering = value == true;
        state.Save();
    end);
    uiTooltip.Info('Right-clicking known gathering object plates targets the object and uses the matching tool: Pickaxe, Hatchet, or Sickle.');

    DrawInlineComboRow('Icon', fishing.GetIconFiles(), settings.fishing.iconFile or 'fishing_01.png', function(value)
        settings.fishing.iconFile = value;
        state.Save();
    end, 'FishingIconFile');

    local x, xChanged, y, yChanged = DrawPlacementPair('Position X', settings.fishing.offsetX, 'FishingX', 'Position Y', settings.fishing.offsetY, 'FishingY', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        settings.fishing.offsetX = x;
        settings.fishing.offsetY = y;
        state.Save();
    end

    local iconSize, iconSizeChanged = DrawPlacementSingle('Icon size', settings.fishing.iconSize, 'FishingIconSize', 1, 200, 1, 154, 124, 58);
    if (iconSizeChanged == true) then
        settings.fishing.iconSize = iconSize;
        state.Save();
    end

    DrawCheckbox('Show result label', settings.fishing.showLabel ~= false, function(value)
        settings.fishing.showLabel = value == true;
        state.Save();
    end);

    if (settings.fishing.showLabel ~= false) then
        local labelSize, labelSizeChanged, labelOffsetY, labelOffsetYChanged = DrawPlacementPair('Label size', settings.fishing.labelFontSize, 'FishingLabelSize', 'Label Y', settings.fishing.labelOffsetY, 'FishingLabelY', -100, 100, 1);
        if (labelSizeChanged == true or labelOffsetYChanged == true) then
            settings.fishing.labelFontSize = labelSize;
            settings.fishing.labelOffsetY = labelOffsetY;
            state.Save();
        end

        local labelColor, labelColorChanged = DrawSettingsColor('Label color', settings.fishing.labelColor, 'FishingLabelColor');
        if (labelColorChanged == true) then
            settings.fishing.labelColor = labelColor;
            state.Save();
        end

        local outlineColor, outlineColorChanged, outlineSize, outlineSizeChanged = DrawColorAndPlacementRow('Outline color', settings.fishing.labelOutlineColor, 'FishingLabelOutlineColor', 'Outline size', settings.fishing.labelOutlineSize, 'FishingLabelOutlineSize', 0, 12, 1);
        if (outlineColorChanged == true or outlineSizeChanged == true) then
            settings.fishing.labelOutlineColor = outlineColor;
            settings.fishing.labelOutlineSize = outlineSize;
            state.Save();
        end
    end
end

function LibraPlatesSettingsDrawCraftingModuleSettings(settings, hideActive)
    settings.crafting = settings.crafting or {};

    if (settings.crafting.enabled == nil) then settings.crafting.enabled = true; end
    if (settings.crafting.displayMode == nil) then settings.crafting.displayMode = 'Icon'; end
    if (settings.crafting.previewResultName == nil) then settings.crafting.previewResultName = 'High-Quality'; end
    if (settings.crafting.offsetX == nil) then settings.crafting.offsetX = 0; end
    if (settings.crafting.offsetY == nil) then settings.crafting.offsetY = 38; end
    if (settings.crafting.iconSize == nil) then settings.crafting.iconSize = 42; end
    if (settings.crafting.showLabel == nil) then settings.crafting.showLabel = true; end
    if (settings.crafting.labelFontSize == nil) then settings.crafting.labelFontSize = 12; end
    if (settings.crafting.labelOffsetY == nil) then settings.crafting.labelOffsetY = 0; end
    if (settings.crafting.labelColor == nil) then settings.crafting.labelColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (settings.crafting.labelOutlineColor == nil) then settings.crafting.labelOutlineColor = { 0.0, 0.0, 0.0, 1.0 }; end
    if (settings.crafting.labelOutlineSize == nil) then settings.crafting.labelOutlineSize = 2; end
    if (settings.crafting.textFontSize == nil) then settings.crafting.textFontSize = 14; end
    if (settings.crafting.textColor == nil) then settings.crafting.textColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (settings.crafting.textOutlineColor == nil) then settings.crafting.textOutlineColor = { 0.0, 0.0, 0.0, 1.0 }; end
    if (settings.crafting.textOutlineSize == nil) then settings.crafting.textOutlineSize = 2; end

    if (hideActive ~= true) then
        DrawCheckbox('Active', settings.crafting.enabled == true, function(value)
            settings.crafting.enabled = value == true;
            state.Save();
        end);
    end

    if (settings.crafting.enabled ~= true and hideActive ~= true) then
        return;
    end

    DrawInlineComboRow('Display', T{ 'Icon', 'Text' }, settings.crafting.displayMode or 'Icon', function(value)
        settings.crafting.displayMode = value;
        state.Save();
    end, 'CraftingDisplayMode');

    DrawInlineComboRow('Preview result', crafting.GetResultChoices(), settings.crafting.previewResultName or 'High-Quality', function(value)
        settings.crafting.previewResultName = value;
        state.Save();
    end, 'CraftingPreviewResult');

    local x, xChanged, y, yChanged = DrawPlacementPair('Position X', settings.crafting.offsetX, 'CraftingX', 'Position Y', settings.crafting.offsetY, 'CraftingY', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        settings.crafting.offsetX = x;
        settings.crafting.offsetY = y;
        state.Save();
    end

    if (tostring(settings.crafting.displayMode or 'Icon') == 'Text') then
        local fontSize, fontSizeChanged, textColor, textColorChanged = DrawPlacementAndColorRow(
            'Text size',
            settings.crafting.textFontSize,
            'CraftingTextSize',
            6,
            64,
            1,
            'Text color',
            settings.crafting.textColor,
            'CraftingTextColor'
        );
        if (fontSizeChanged == true or textColorChanged == true) then
            settings.crafting.textFontSize = fontSize;
            settings.crafting.textColor = textColor;
            state.Save();
        end

        local outlineSize, outlineSizeChanged, outlineColor, outlineColorChanged = DrawPlacementAndColorRow(
            'Outline size',
            settings.crafting.textOutlineSize,
            'CraftingTextOutlineSize',
            0,
            12,
            1,
            'Outline color',
            settings.crafting.textOutlineColor,
            'CraftingTextOutlineColor'
        );
        if (outlineSizeChanged == true or outlineColorChanged == true) then
            settings.crafting.textOutlineSize = outlineSize;
            settings.crafting.textOutlineColor = outlineColor;
            state.Save();
        end

        return;
    end

    local iconSize, iconSizeChanged = DrawPlacementSingle('Icon size', settings.crafting.iconSize, 'CraftingIconSize', 1, 200, 1, 154, 124, 58);
    if (iconSizeChanged == true) then
        settings.crafting.iconSize = iconSize;
        state.Save();
    end

    DrawCheckbox('Show result label', settings.crafting.showLabel ~= false, function(value)
        settings.crafting.showLabel = value == true;
        state.Save();
    end);

    if (settings.crafting.showLabel ~= false) then
        local labelSize, labelSizeChanged, labelOffsetY, labelOffsetYChanged = DrawPlacementPair('Label size', settings.crafting.labelFontSize, 'CraftingLabelSize', 'Label Y', settings.crafting.labelOffsetY, 'CraftingLabelY', -100, 100, 1);
        if (labelSizeChanged == true or labelOffsetYChanged == true) then
            settings.crafting.labelFontSize = labelSize;
            settings.crafting.labelOffsetY = labelOffsetY;
            state.Save();
        end

        local labelColor, labelColorChanged = DrawSettingsColor('Label color', settings.crafting.labelColor, 'CraftingLabelColor');
        if (labelColorChanged == true) then
            settings.crafting.labelColor = labelColor;
            state.Save();
        end

        local outlineColor, outlineColorChanged, outlineSize, outlineSizeChanged = DrawColorAndPlacementRow('Outline color', settings.crafting.labelOutlineColor, 'CraftingLabelOutlineColor', 'Outline size', settings.crafting.labelOutlineSize, 'CraftingLabelOutlineSize', 0, 12, 1);
        if (outlineColorChanged == true or outlineSizeChanged == true) then
            settings.crafting.labelOutlineColor = outlineColor;
            settings.crafting.labelOutlineSize = outlineSize;
            state.Save();
        end
    end
end

local function DrawQuickMenuIconRow(menu)
    DrawCheckbox('Show icons', menu.iconsEnabled == true, function(value)
        menu.iconsEnabled = value == true;
        state.Save();
    end);

    if (menu.iconsEnabled == true) then
        imgui.SameLine();
        imgui.TextColored(settingsLabelColor, 'Icon size');
        imgui.SameLine();

        local iconSize, iconSizeChanged = DrawPlacementControl(menu.iconSize, 8, 64, 1, 'QuickMenuIconSize', 58);
        if (iconSizeChanged == true) then
            menu.iconSize = iconSize;
            state.Save();
        end
    end
end

local function DrawQuickMenuColorRow(menu)
    local function GetOpacity(color)
        color = color or {};
        return math.floor(((tonumber(color[4]) or 1.0) * 100) + 0.5);
    end

    local function SetOpacity(color, value)
        color = color or { 1.0, 1.0, 1.0, 1.0 };
        color[4] = math.max(0, math.min(100, tonumber(value) or 100)) / 100;
        return color;
    end

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local changed = false;

        if (imgui.BeginTable('##quick_menu_color_settings', 8, settingsTableFlags)) then
            imgui.TableSetupColumn('##background_label', 0, 92);
            imgui.TableSetupColumn('##background_control', 0, 62);
            imgui.TableSetupColumn('##header_label', 0, 72);
            imgui.TableSetupColumn('##header_control', 0, 62);
            imgui.TableSetupColumn('##text_label', 0, 54);
            imgui.TableSetupColumn('##text_control', 0, 62);
            imgui.TableSetupColumn('##link_label', 0, 50);
            imgui.TableSetupColumn('##link_control', 0, 62);
            imgui.TableNextRow();

            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, 'Background');
            imgui.TableNextColumn();
            if (imgui.ColorEdit4 ~= nil) then
                changed = (imgui.ColorEdit4('##QuickMenuBackground', menu.backgroundColor, settingsColorEditFlags) == true) or changed;
            else
                imgui.TextColored(menu.backgroundColor, 'sample');
            end

            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, 'Header');
            imgui.TableNextColumn();
            if (imgui.ColorEdit4 ~= nil) then
                changed = (imgui.ColorEdit4('##QuickMenuHeader', menu.headerColor, settingsColorEditFlags) == true) or changed;
            else
                imgui.TextColored(menu.headerColor, 'sample');
            end

            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, 'Text');
            imgui.TableNextColumn();
            if (imgui.ColorEdit4 ~= nil) then
                changed = (imgui.ColorEdit4('##QuickMenuText', menu.textColor, settingsColorEditFlags) == true) or changed;
            else
                imgui.TextColored(menu.textColor, 'sample');
            end

            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, 'Link');
            imgui.TableNextColumn();
            if (imgui.ColorEdit4 ~= nil) then
                changed = (imgui.ColorEdit4('##QuickMenuLink', menu.linkColor, settingsColorEditFlags) == true) or changed;
            else
                imgui.TextColored(menu.linkColor, 'sample');
            end

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, 'Opacity');
            imgui.TableNextColumn();
            local bgOpacity, bgOpacityChanged = DrawPlacementControl(GetOpacity(menu.backgroundColor), 0, 100, 1, 'QuickMenuBackgroundOpacity', 58);
            if (bgOpacityChanged == true) then
                menu.backgroundColor = SetOpacity(menu.backgroundColor, bgOpacity);
                changed = true;
            end

            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, 'Opacity');
            imgui.TableNextColumn();
            local headerOpacity, headerOpacityChanged = DrawPlacementControl(GetOpacity(menu.headerColor), 0, 100, 1, 'QuickMenuHeaderOpacity', 58);
            if (headerOpacityChanged == true) then
                menu.headerColor = SetOpacity(menu.headerColor, headerOpacity);
                changed = true;
            end

            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, 'Opacity');
            imgui.TableNextColumn();
            local textOpacity, textOpacityChanged = DrawPlacementControl(GetOpacity(menu.textColor), 0, 100, 1, 'QuickMenuTextOpacity', 58);
            if (textOpacityChanged == true) then
                menu.textColor = SetOpacity(menu.textColor, textOpacity);
                changed = true;
            end

            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, 'Opacity');
            imgui.TableNextColumn();
            local linkOpacity, linkOpacityChanged = DrawPlacementControl(GetOpacity(menu.linkColor), 0, 100, 1, 'QuickMenuLinkOpacity', 58);
            if (linkOpacityChanged == true) then
                menu.linkColor = SetOpacity(menu.linkColor, linkOpacity);
                changed = true;
            end

            imgui.EndTable();
        end

        if (changed == true) then
            state.Save();
        end

        return;
    end

    local bgColor, bgChanged = DrawSettingsColor('Background', menu.backgroundColor, 'QuickMenuBackground');
    local headerColor, headerChanged = DrawSettingsColor('Header', menu.headerColor, 'QuickMenuHeader');
    local textColor, textChanged = DrawSettingsColor('Text', menu.textColor, 'QuickMenuText');
    local linkColor, linkChanged = DrawSettingsColor('Link', menu.linkColor, 'QuickMenuLink');
    if (bgChanged == true or textChanged == true or headerChanged == true or linkChanged == true) then
        menu.backgroundColor = bgColor;
        menu.textColor = textColor;
        menu.headerColor = headerColor;
        menu.linkColor = linkColor;
        state.Save();
    end
end

function LibraPlatesSettingsDrawQuickMenuModuleSettings(settings, hideActive)
    settings.quickMenu = settings.quickMenu or {};
    local menu = settings.quickMenu;
    local scopedEntity = nil;

    if (menu.enabled == nil) then menu.enabled = true; end
    menu.openOnRightClick = true;
    if (menu.modifier == nil) then menu.modifier = 'None'; end
    if (menu.width == nil) then menu.width = 270; end
    if (menu.iconsEnabled == nil) then menu.iconsEnabled = true; end
    if (menu.iconSize == nil) then menu.iconSize = 22; end
    if (menu.backgroundColor == nil) then menu.backgroundColor = { 0.02, 0.02, 0.07, 0.96 }; end
    if (menu.borderColor == nil) then menu.borderColor = { 0.25, 0.25, 0.36, 1.0 }; end
    if (menu.borderSize == nil) then menu.borderSize = 1; end
    if (menu.textColor == nil) then menu.textColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (menu.headerColor == nil) then menu.headerColor = { 1.0, 0.84, 0.0, 1.0 }; end
    if (menu.linkColor == nil) then menu.linkColor = { 0.48, 0.82, 1.0, 1.0 }; end
    menu.pc = menu.pc or {};
    if (menu.pc.examine == nil) then menu.pc.examine = true; end
    if (menu.pc.catseyeProfile == nil) then menu.pc.catseyeProfile = true; end
    if (menu.pc.follow == nil) then menu.pc.follow = true; end
    if (menu.pc.inviteToParty == nil) then menu.pc.inviteToParty = true; end
    if (menu.pc.requestJoinParty == nil) then menu.pc.requestJoinParty = true; end
    if (menu.pc.invitePartyToAlliance == nil) then menu.pc.invitePartyToAlliance = true; end
    if (menu.pc.passPartyLeader == nil) then menu.pc.passPartyLeader = true; end
    if (menu.pc.passAllianceLeader == nil) then menu.pc.passAllianceLeader = true; end
    menu.self = menu.self or {};
    if (menu.self.acceptInvite == nil) then menu.self.acceptInvite = true; end
    if (menu.self.declineInvite == nil) then menu.self.declineInvite = true; end
    if (menu.self.leaveParty == nil) then menu.self.leaveParty = true; end
    if (menu.self.leaveAlliance == nil) then menu.self.leaveAlliance = true; end
    if (menu.self.cancelPartyRequest == nil) then menu.self.cancelPartyRequest = true; end
    if (menu.self.autogroup == nil) then menu.self.autogroup = (menu.self.autogroupOn ~= false or menu.self.autogroupOff ~= false); end
    if (menu.self.ignoreTrust == nil) then menu.self.ignoreTrust = (menu.self.ignoreTrustOn ~= false or menu.self.ignoreTrustOff ~= false); end
    if (menu.self.hideTrust == nil) then menu.self.hideTrust = (menu.self.hideTrustOn ~= false or menu.self.hideTrustOff ~= false); end
    if (menu.self.emoteTrust == nil) then menu.self.emoteTrust = (menu.self.emoteTrustOn ~= false or menu.self.emoteTrustOff ~= false); end
    menu.trust = menu.trust or {};
    if (menu.trust.dismiss == nil) then menu.trust.dismiss = true; end
    if (menu.trust.dismissAll == nil) then menu.trust.dismissAll = true; end
    if (menu.trust.confirmDismissAll == nil) then menu.trust.confirmDismissAll = true; end
    menu.npc = menu.npc or {};
    if (menu.npc.showType == nil) then menu.npc.showType = true; end
    if (menu.npc.showInfo == nil) then menu.npc.showInfo = true; end
    if (menu.npc.openLink == nil) then menu.npc.openLink = true; end

    if (selectedTab == 'Plates') then
        scopedEntity = GetStorageEntity(selectedEntity);
    end

    if (hideActive ~= true) then
        DrawCheckbox('Active', menu.enabled == true, function(value)
            menu.enabled = value == true;
            state.Save();
        end);
    end

    if (menu.enabled ~= true and hideActive ~= true) then
        return;
    end

    DrawInlineComboRow('Modifier', T{ 'None', 'Shift', 'Ctrl', 'Alt' }, menu.modifier or 'None', function(value)
        menu.modifier = value;
        state.Save();
    end, 'QuickMenuModifier');
    uiTooltip.Info('Controls whether right-click opens the quick menu. If a modifier is selected, hold that modifier and right-click. If the modifier is None, right-click opens the quick menu directly.');

    local width, widthChanged = DrawPlacementSingle('Menu width', menu.width, 'QuickMenuWidth', 160, 520, 1, 154, 124, 58);
    if (widthChanged == true) then
        menu.width = width;
        state.Save();
    end

    DrawQuickMenuIconRow(menu);

    local borderColor, borderChanged, borderSize, borderSizeChanged = DrawColorAndPlacementRow('Border color', menu.borderColor, 'QuickMenuBorder', 'Border size', menu.borderSize, 'QuickMenuBorderSize', 0, 12, 1);
    if (borderChanged == true or borderSizeChanged == true) then
        menu.borderColor = borderColor;
        menu.borderSize = borderSize;
        state.Save();
    end

    imgui.Separator();
    DrawYellowHeader('Color settings');
    DrawQuickMenuColorRow(menu);

    if (scopedEntity == nil or scopedEntity == 'PC') then
        imgui.Separator();
        DrawYellowHeader('PC actions');

    DrawCheckbox('Examine', menu.pc.examine == true, function(value)
        menu.pc.examine = value == true;
        state.Save();
    end);

    DrawCheckbox('Open Catseye Profile', menu.pc.catseyeProfile == true, function(value)
        menu.pc.catseyeProfile = value == true;
        state.Save();
    end);

    DrawCheckbox('Follow', menu.pc.follow == true, function(value)
        menu.pc.follow = value == true;
        state.Save();
    end);

    DrawCheckbox('Invite to Party', menu.pc.inviteToParty == true, function(value)
        menu.pc.inviteToParty = value == true;
        state.Save();
    end);

    DrawCheckbox('Request to Join Party', menu.pc.requestJoinParty == true, function(value)
        menu.pc.requestJoinParty = value == true;
        state.Save();
    end);

    DrawCheckbox('Invite Party to Alliance', menu.pc.invitePartyToAlliance == true, function(value)
        menu.pc.invitePartyToAlliance = value == true;
        state.Save();
    end);

    DrawCheckbox('Pass Party Leader', menu.pc.passPartyLeader == true, function(value)
        menu.pc.passPartyLeader = value == true;
        state.Save();
    end);

        DrawCheckbox('Pass Alliance Leader', menu.pc.passAllianceLeader == true, function(value)
            menu.pc.passAllianceLeader = value == true;
            state.Save();
        end);
    end

    if (scopedEntity == nil or scopedEntity == 'Self') then
        imgui.Separator();
        DrawYellowHeader('Self actions');

    DrawCheckbox('Invite responses', menu.self.acceptInvite == true or menu.self.declineInvite == true, function(value)
        menu.self.acceptInvite = value == true;
        menu.self.declineInvite = value == true;
        state.Save();
    end);

    DrawCheckbox('Leave Party', menu.self.leaveParty == true, function(value)
        menu.self.leaveParty = value == true;
        state.Save();
    end);

    DrawCheckbox('Leave Alliance', menu.self.leaveAlliance == true, function(value)
        menu.self.leaveAlliance = value == true;
        state.Save();
    end);

    DrawCheckbox('Cancel Party Request', menu.self.cancelPartyRequest == true, function(value)
        menu.self.cancelPartyRequest = value == true;
        state.Save();
    end);

    imgui.Separator();
    DrawYellowHeader('Trust filters');

    DrawCheckbox('Ignore other Trusts', menu.self.ignoreTrust == true, function(value)
        menu.self.ignoreTrust = value == true;
        state.Save();
    end);

    DrawCheckbox('Hide other Trusts', menu.self.hideTrust == true, function(value)
        menu.self.hideTrust = value == true;
        state.Save();
    end);

        DrawCheckbox('Emote Trust', menu.self.emoteTrust == true, function(value)
            menu.self.emoteTrust = value == true;
            state.Save();
        end);
    end

    if (scopedEntity == nil or scopedEntity == 'Trust') then
        imgui.Separator();
        DrawYellowHeader('Trust actions');

    DrawCheckbox('Dismiss This Trust', menu.trust.dismiss == true, function(value)
        menu.trust.dismiss = value == true;
        state.Save();
    end);

    DrawCheckbox('Dismiss All Trusts', menu.trust.dismissAll == true, function(value)
        menu.trust.dismissAll = value == true;
        state.Save();
    end);

        if (menu.trust.dismissAll == true) then
            DrawCheckbox('Confirm Dismiss All Trusts', menu.trust.confirmDismissAll == true, function(value)
                menu.trust.confirmDismissAll = value == true;
                state.Save();
            end);
        end
    end

    if (scopedEntity == nil or scopedEntity == 'NPC' or scopedEntity == 'Object') then
        imgui.Separator();
        DrawYellowHeader('NPC actions');

    DrawCheckbox('Show type', menu.npc.showType == true, function(value)
        menu.npc.showType = value == true;
        state.Save();
    end);

    DrawCheckbox('Show info', menu.npc.showInfo == true, function(value)
        menu.npc.showInfo = value == true;
        state.Save();
    end);

        DrawCheckbox('Open wiki link', menu.npc.openLink == true, function(value)
            menu.npc.openLink = value == true;
            state.Save();
        end);
    end
end

local function LibraPlatesSettingsToStorageStateName(value)
    local name = tostring(value or '');

    if (name == 'World') then
        return 'Idle';
    end

    if (name == 'Tactical') then
        return 'Combat';
    end

    return name;
end

local function DrawSectionSelector(sections, selected, setSelected)
    for _, section in ipairs(sections) do
        local isSelected = tostring(section) == tostring(selected);

        if (imgui.Selectable(tostring(section), isSelected) == true) then
            setSelected(section);
            PersistUiSelection();
        end
    end
end

local function DrawSettingsHeader(text)
    imgui.Spacing();
    imgui.Separator();

    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.30);
    end

    imgui.Text(tostring(text or ''));

    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.0);
    end

    imgui.Separator();
    imgui.Spacing();
end

local function DrawGeneralFontSection(global)
    LibraPlatesSettingsDrawBreadcrumb(T{ 'General', 'Font' });
    DrawSettingsHeader('Global font');

    if (global.font.largeFamily == nil) then
        global.font.largeFamily = global.font.family or 'Default';
    end

    if (global.font.smallFamily == nil) then
        global.font.smallFamily = global.font.family or 'Default';
    end

    DrawInlineCombo('Large text font', fonts.GetChoices('large'), global.font.largeFamily, function(fontFamily)
        global.font.largeFamily = fontFamily;
    end);

    DrawFontStatus('Large font', global.font.largeFamily);
    DrawFontFolderButton('Open large font folder', 'large');

    DrawInlineCombo('Small text font', fonts.GetChoices('small'), global.font.smallFamily, function(fontFamily)
        global.font.smallFamily = fontFamily;
    end);

    DrawFontStatus('Small font', global.font.smallFamily);
    DrawFontFolderButton('Open small font folder', 'small');

    imgui.TextColored({ 1.0, 0.70, 0.25, 1.0 }, 'After installing new fonts, reload LibraPlates before checking status.');
    imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, 'Large text is used for names. Small text is used by widgets with Use small font enabled.');
end

local function DrawGeneralNativeUiSection(settings)
    LibraPlatesSettingsDrawBreadcrumb(T{ 'General', 'Native UI' });
    DrawSettingsHeader('Native game UI');

    local nativeUiPolicy = require('core.native_ui_policy');
    local nativeUiForced = nativeUiPolicy.IsNativeUiForced() == true;
    local useNativePartyTargetUi =
        settings.hideNativePartyTargetUi ~= true and
        settings.hideNativeTargetArrow ~= true;
    local useNativeNames = settings.hideNativeNamesOnLoad ~= true;

    DrawCheckbox('Use native party/target UI', useNativePartyTargetUi == true, function(value)
        local useNative = value == true;
        settings.hideNativePartyTargetUi = useNative ~= true;
        settings.hideNativeTargetArrow = useNative ~= true;
    end);

    uiTooltip.Info('When off, LibraPlates replaces the native party/target UI and target arrow with Libra target/subtarget modules.');

    DrawCheckbox('Use native names', useNativeNames == true, function(value)
        settings.hideNativeNamesOnLoad = value ~= true;
        pcall(function()
            AshitaCore:GetChatManager():QueueCommand(1, value == true and '/names on' or '/names off');
        end);
    end);

    if (nativeUiForced == true) then
        imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, 'Mog House forces native targeting at runtime.');
    end

    uiTooltip.Info('When off, LibraPlates applies /names off immediately and again when it loads. This does not change LibraPlates plates.');
end

local function DrawGeneralMouseSection()
    LibraPlatesSettingsDrawBreadcrumb(T{ 'General', 'Mouse' });
    DrawSettingsHeader('Mouse controls');

    local cursorSettings = cursorOverlay.GetSettings();

    DrawCheckbox('Enable mouse adornment', cursorSettings.enabled == true, function(value)
        cursorOverlay.SetEnabled(value == true);
        state.Save();
    end);

    imgui.Text('Mouse shape');
    local cursorShapes = { 'Ring', 'Diamond', 'Corners', 'Dot Ring', 'Crosshair' };
    for index, shape in ipairs(cursorShapes) do
        if (index > 1) then
            imgui.SameLine();
        end

        local isSelected = tostring(cursorSettings.shape or 'Ring') == shape;
        local label = (isSelected == true and '[' .. shape .. ']' or shape) .. '##CursorShape' .. tostring(index);

        if (imgui.Button(label) == true) then
            cursorSettings.shape = shape;
            state.Save();
        end
    end

    local cursorRadius = { math.floor(tonumber(cursorSettings.radius) or 13) };
    if (imgui.SliderInt ~= nil) then
        if (imgui.SliderInt('Size', cursorRadius, 4, 48) == true) then
            cursorSettings.radius = math.max(4, math.min(48, tonumber(cursorRadius[1]) or 13));
            state.Save();
        end
    else
        imgui.TextColored(settingsLabelColor, 'Size ' .. tostring(cursorSettings.radius or 13));
    end

    local trailLagReduction = { math.floor(tonumber(cursorSettings.trailLagReduction) or 0) };
    if (imgui.SliderInt ~= nil) then
        if (imgui.SliderInt('Trail lag reduction', trailLagReduction, 0, 100) == true) then
            cursorSettings.trailLagReduction = math.max(0, math.min(100, tonumber(trailLagReduction[1]) or 0));
            state.Save();
        end
    else
        imgui.TextColored(settingsLabelColor, 'Trail lag reduction ' .. tostring(cursorSettings.trailLagReduction or 0));
    end

    imgui.Text('Elements');

    DrawCheckbox('Outer element', cursorSettings.outerEnabled == true, function(value)
        if (value ~= true and cursorSettings.innerEnabled ~= true and cursorSettings.centerEnabled ~= true) then
            cursorSettings.outerEnabled = true;
        else
            cursorSettings.outerEnabled = value == true;
        end
        state.Save();
    end);

    local ringColor = { unpackTable(cursorSettings.ringColor or globalDefaults.cursorOverlay.ringColor) };
    imgui.SameLine();
    if (imgui.ColorEdit4('##CursorRingColor', ringColor, settingsColorEditFlags) == true) then
        cursorSettings.ringColor = ringColor;
        state.Save();
    end

    DrawCheckbox('Inner element', cursorSettings.innerEnabled == true, function(value)
        if (value ~= true and cursorSettings.outerEnabled ~= true and cursorSettings.centerEnabled ~= true) then
            cursorSettings.innerEnabled = true;
        else
            cursorSettings.innerEnabled = value == true;
        end
        state.Save();
    end);

    local accentColor = { unpackTable(cursorSettings.accentColor or globalDefaults.cursorOverlay.accentColor) };
    imgui.SameLine();
    if (imgui.ColorEdit4('##CursorAccentColor', accentColor, settingsColorEditFlags) == true) then
        cursorSettings.accentColor = accentColor;
        state.Save();
    end

    DrawCheckbox('Center element', cursorSettings.centerEnabled == true, function(value)
        if (value ~= true and cursorSettings.outerEnabled ~= true and cursorSettings.innerEnabled ~= true) then
            cursorSettings.centerEnabled = true;
        else
            cursorSettings.centerEnabled = value == true;
            cursorSettings.showCenterMark = cursorSettings.centerEnabled == true;
        end
        state.Save();
    end);

    local centerColor = { unpackTable(cursorSettings.centerColor or globalDefaults.cursorOverlay.centerColor) };
    imgui.SameLine();
    if (imgui.ColorEdit4('##CursorCenterColor', centerColor, settingsColorEditFlags) == true) then
        cursorSettings.centerColor = centerColor;
        state.Save();
    end

    imgui.Separator();

    DrawCheckbox('Hold both mouse buttons to move forward', mouseControls.GetBothButtonForwardEnabled(), function(value)
        mouseControls.SetBothButtonForwardEnabled(value == true);
    end);
end

local function DrawProfileNamePopup(popupName, inputLabel, buttonLabel, buffer, action)
    if (imgui.BeginPopupModal == nil) then
        return;
    end

    if (imgui.SetNextWindowSize ~= nil) then
        imgui.SetNextWindowSize({ 430, 180 }, _G.ImGuiCond_Appearing or 8);
    end

    if (imgui.BeginPopupModal(popupName)) then
        imgui.Text(inputLabel);

        if (imgui.InputText ~= nil) then
            if (imgui.PushItemWidth ~= nil) then
                imgui.PushItemWidth(330);
            end

            imgui.InputText('##' .. popupName .. '_name', buffer, 64);

            if (imgui.PopItemWidth ~= nil) then
                imgui.PopItemWidth();
            end
        end

        if (profilePopupStatusMessage ~= nil and profilePopupStatusMessage ~= '') then
            imgui.TextColored({ 1.0, 0.35, 0.25, 1.0 }, profilePopupStatusMessage);
        end

        if (imgui.Button('Cancel##' .. popupName .. '_cancel')) then
            profilePopupStatusMessage = '';
            imgui.CloseCurrentPopup();
        end

        imgui.SameLine();

        if (imgui.Button(buttonLabel .. '##' .. popupName .. '_confirm')) then
            local ok, message = action(tostring(buffer[1] or ''));
            if (ok == true) then
                profileStatusMessage = '';
                profilePopupStatusMessage = '';
                buffer[1] = '';
                imgui.CloseCurrentPopup();
            else
                profilePopupStatusMessage = tostring(message or 'Profile action failed.');
            end
        end

        imgui.EndPopup();
    end
end

local function DrawGeneralProfilesSection()
    LibraPlatesSettingsDrawBreadcrumb(T{ 'General', 'Profiles' });
    DrawSettingsHeader('Profiles');

    local names = state.GetProfileNames();
    local activeName = state.GetActiveProfileName();

    DrawInlineComboRow('Current profile', names, activeName, function(value)
        local ok, message = state.SetActiveProfile(value);
        profileStatusMessage = ok == true and '' or tostring(message or 'Profile switch failed.');
    end, 'ProfileCurrent', nil, 118);

    if (profileStatusMessage ~= nil and profileStatusMessage ~= '') then
        imgui.TextColored({ 1.0, 0.35, 0.25, 1.0 }, profileStatusMessage);
    end

    if (imgui.Button('New##ProfileNew')) then
        profileNewNameBuffer[1] = '';
        profilePopupStatusMessage = '';
        if (imgui.OpenPopup ~= nil) then imgui.OpenPopup('New profile##libraplates_profile_new'); end
    end

    imgui.SameLine();
    if (imgui.Button('Copy##ProfileCopy')) then
        profileCopyNameBuffer[1] = tostring(activeName or 'Default') .. ' Copy';
        profilePopupStatusMessage = '';
        if (imgui.OpenPopup ~= nil) then imgui.OpenPopup('Copy profile##libraplates_profile_copy'); end
    end

    imgui.SameLine();
    if (imgui.Button('Rename##ProfileRename')) then
        profileRenameNameBuffer[1] = tostring(activeName or 'Default');
        profilePopupStatusMessage = '';
        if (imgui.OpenPopup ~= nil) then imgui.OpenPopup('Rename profile##libraplates_profile_rename'); end
    end

    imgui.SameLine();
    if (imgui.Button('Delete##ProfileDelete')) then
        profilePendingDelete = activeName;
        if (imgui.OpenPopup ~= nil) then imgui.OpenPopup('Delete profile##libraplates_profile_delete'); end
    end

    imgui.SameLine();
    if (imgui.Button('Reset##ProfileReset')) then
        profilePendingReset = activeName;
        if (imgui.OpenPopup ~= nil) then imgui.OpenPopup('Reset profile##libraplates_profile_reset'); end
    end

    uiTooltip.Info('Profiles are stored per character.\nNew profiles start from defaults.\nCopy duplicates the current profile.\nDelete and reset make backups first.');

    DrawProfileNamePopup('New profile##libraplates_profile_new', 'Profile Name:', 'Create', profileNewNameBuffer, function(name)
        return state.CreateProfile(name, false);
    end);

    DrawProfileNamePopup('Copy profile##libraplates_profile_copy', 'New Name:', 'Copy', profileCopyNameBuffer, function(name)
        return state.CopyProfile(activeName, name);
    end);

    DrawProfileNamePopup('Rename profile##libraplates_profile_rename', 'New Name:', 'Rename', profileRenameNameBuffer, function(name)
        return state.RenameProfile(activeName, name);
    end);

    imgui.Separator();
    DrawYellowHeader('Auto switch');

    local assignment = state.GetProfileAssignment(activeName);

    DrawCheckbox('Auto switch profile', assignment.enabled == true, function(value)
        state.SetProfileAssignment(activeName, value == true, assignment.mainJob or 'WAR', assignment.subJob or 'Any');
    end);

    if (assignment.enabled == true) then
        local assignedMainJob = assignment.mainJob or 'WAR';
        local assignedSubJob = assignment.subJob or 'Any';

        if (assignedSubJob == assignedMainJob) then
            assignedSubJob = 'Any';
        end

        DrawInlineComboRow('Main job', profileMainJobOptions, assignment.mainJob or 'WAR', function(value)
            local subJob = assignment.subJob or 'Any';
            if (subJob == value) then
                subJob = 'Any';
            end

            state.SetProfileAssignment(activeName, true, value, subJob);
        end, 'ProfileAutoMainJob', nil, 94);

        DrawInlineComboRow('Sub job', GetProfileSubJobOptions(assignedMainJob), assignedSubJob, function(value)
            state.SetProfileAssignment(activeName, true, assignedMainJob, value);
        end, 'ProfileAutoSubJob', nil, 94);

        uiTooltip.Info('Any sub job matches all subjobs and also matches when no subjob is set.');
    end

    if (imgui.SetNextWindowSize ~= nil) then
        imgui.SetNextWindowSize({ 390, 145 }, _G.ImGuiCond_Appearing or 8);
    end

    if (imgui.BeginPopupModal ~= nil and imgui.BeginPopupModal('Delete profile##libraplates_profile_delete')) then
        imgui.Text('Delete profile "' .. tostring(profilePendingDelete or activeName or '') .. '"?');
        imgui.TextColored({ 1.0, 0.35, 0.25, 1.0 }, 'A backup will be created first.');

        if (imgui.Button('Cancel##ProfileDeleteCancel')) then
            profilePendingDelete = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.SameLine();

        if (imgui.Button('Delete##ProfileDeleteConfirm')) then
            local ok, message = state.DeleteProfile(profilePendingDelete);
            profileStatusMessage = ok == true and '' or tostring(message or 'Profile delete failed.');
            profilePendingDelete = nil;
            if (ok == true) then imgui.CloseCurrentPopup(); end
        end

        imgui.EndPopup();
    end

    if (imgui.SetNextWindowSize ~= nil) then
        imgui.SetNextWindowSize({ 390, 145 }, _G.ImGuiCond_Appearing or 8);
    end

    if (imgui.BeginPopupModal ~= nil and imgui.BeginPopupModal('Reset profile##libraplates_profile_reset')) then
        imgui.Text('Reset profile "' .. tostring(profilePendingReset or activeName or '') .. '" to defaults?');
        imgui.TextColored({ 1.0, 0.35, 0.25, 1.0 }, 'A backup will be created first.');

        if (imgui.Button('Cancel##ProfileResetCancel')) then
            profilePendingReset = nil;
            imgui.CloseCurrentPopup();
        end

        imgui.SameLine();

        if (imgui.Button('Reset##ProfileResetConfirm')) then
            local ok, message = state.ResetProfile(profilePendingReset);
            profileStatusMessage = ok == true and '' or tostring(message or 'Profile reset failed.');
            profilePendingReset = nil;
            if (ok == true) then imgui.CloseCurrentPopup(); end
        end

        imgui.EndPopup();
    end
end

local function DrawGeneralScalingSection(settings)
    LibraPlatesSettingsDrawBreadcrumb(T{ 'General', 'Scaling' });
    DrawSettingsHeader('Global distance scaling');

    DrawSliderTenths('Start distance', settings.pcDistanceScaleStart, 0, 200, function(value)
        settings.pcDistanceScaleStart = math.max(0.0, math.min(20.0, tonumber(value) or 2.0));
        if ((tonumber(settings.pcDistanceScaleEnd) or 8.0) <= settings.pcDistanceScaleStart) then
            settings.pcDistanceScaleEnd = math.min(40.0, settings.pcDistanceScaleStart + 1.0);
        end
    end);

    DrawSliderTenths('Max distance', settings.pcDistanceScaleEnd, 10, 400, function(value)
        settings.pcDistanceScaleEnd = math.max(1.0, math.min(40.0, tonumber(value) or 8.0));
        if (settings.pcDistanceScaleEnd <= (tonumber(settings.pcDistanceScaleStart) or 2.0)) then
            settings.pcDistanceScaleStart = math.max(0.0, settings.pcDistanceScaleEnd - 1.0);
        end
    end);

    LibraPlatesSettingsDrawTieredSliderTenths('Max scale', settings.pcDistanceScaleMax, 10, 60, {
        { min = 10, max = 25, label = 'Normal', color = { 0.25, 0.85, 0.35, 0.55 } },
        { min = 25, max = 35, label = 'Large', color = { 0.95, 0.84, 0.25, 0.55 } },
        { min = 35, max = 45, label = 'Huge', color = { 1.0, 0.55, 0.20, 0.55 } },
        { min = 45, max = 60, label = 'Extreme', color = { 1.0, 0.22, 0.18, 0.55 } },
    }, function(value)
        settings.pcDistanceScaleMax = math.max(1.0, math.min(6.0, tonumber(value) or 2.65));
    end);

    DrawSettingsHeader('Entity distance scaling');

    if (type(settings.plateDistanceScales) ~= 'table') then
        settings.plateDistanceScales = {};
    end

    local function DrawEntityScale(label, key)
        if (type(settings.plateDistanceScales[key]) ~= 'table') then
            settings.plateDistanceScales[key] = {
                start = tonumber(settings.pcDistanceScaleStart) or 2.0,
                finish = tonumber(settings.pcDistanceScaleEnd) or 8.0,
                max = tonumber(settings.pcDistanceScaleMax) or 2.65,
            };
        end

        local scale = settings.plateDistanceScales[key];
        DrawSettingsHeader(label);
        DrawSliderTenths('Start distance', scale.start, 0, 200, function(value)
            scale.start = math.max(0.0, math.min(20.0, tonumber(value) or 2.0));
            if ((tonumber(scale.finish) or 8.0) <= scale.start) then
                scale.finish = math.min(40.0, scale.start + 1.0);
            end
        end);

        DrawSliderTenths('Max distance', scale.finish, 10, 400, function(value)
            scale.finish = math.max(1.0, math.min(40.0, tonumber(value) or 8.0));
            if (scale.finish <= (tonumber(scale.start) or 2.0)) then
                scale.start = math.max(0.0, scale.finish - 1.0);
            end
        end);

        LibraPlatesSettingsDrawTieredSliderTenths('Max scale', scale.max, 10, 60, {
            { min = 10, max = 25, label = 'Normal', color = { 0.25, 0.85, 0.35, 0.55 } },
            { min = 25, max = 35, label = 'Large', color = { 0.95, 0.84, 0.25, 0.55 } },
            { min = 35, max = 45, label = 'Huge', color = { 1.0, 0.55, 0.20, 0.55 } },
            { min = 45, max = 60, label = 'Extreme', color = { 1.0, 0.22, 0.18, 0.55 } },
        }, function(value)
            scale.max = math.max(1.0, math.min(6.0, tonumber(value) or 2.65));
        end);
    end

    DrawEntityScale('Self', 'self');
    DrawEntityScale('PC', 'pc');
    DrawEntityScale('Trust', 'trust');
    DrawEntityScale('Enemy', 'enemy');
    DrawEntityScale('NPC', 'npc');
    DrawEntityScale('Object', 'object');
    DrawEntityScale('Pet', 'pet');

    DrawSettingsHeader('Global plate position');
    local globalOffsetX, globalOffsetXChanged, globalOffsetY, globalOffsetYChanged = DrawPlacementPair(
        'Plate X',
        settings.globalPlateOffsetX,
        'GlobalPlateOffsetX',
        'Plate Y',
        settings.globalPlateOffsetY,
        'GlobalPlateOffsetY',
        -100,
        100,
        1
    );
    if (globalOffsetXChanged == true) then
        settings.globalPlateOffsetX = math.max(-100, math.min(100, math.floor((tonumber(globalOffsetX) or 0) + 0.5)));
    end
    if (globalOffsetYChanged == true) then
        settings.globalPlateOffsetY = math.max(-100, math.min(100, math.floor((tonumber(globalOffsetY) or 0) + 0.5)));
    end

    DrawSettingsHeader('Entity plate position');
    if (type(settings.platePositionOffsets) ~= 'table') then
        settings.platePositionOffsets = {};
    end

    local function DrawEntityOffset(label, key)
        if (type(settings.platePositionOffsets[key]) ~= 'table') then
            settings.platePositionOffsets[key] = { x = 0, y = 0 };
        end

        local offsets = settings.platePositionOffsets[key];
        local offsetX, offsetXChanged, offsetY, offsetYChanged = DrawPlacementPair(
            label .. ' X',
            offsets.x,
            'PlateOffset' .. label .. 'X',
            label .. ' Y',
            offsets.y,
            'PlateOffset' .. label .. 'Y',
            -100,
            100,
            1
        );
        if (offsetXChanged == true) then
            offsets.x = math.max(-100, math.min(100, math.floor((tonumber(offsetX) or 0) + 0.5)));
        end
        if (offsetYChanged == true) then
            offsets.y = math.max(-100, math.min(100, math.floor((tonumber(offsetY) or 0) + 0.5)));
        end
    end

    DrawEntityOffset('Self', 'self');
    DrawEntityOffset('PC', 'pc');
    DrawEntityOffset('Trust', 'trust');
    DrawEntityOffset('Enemy', 'enemy');
    DrawEntityOffset('NPC', 'npc');
    DrawEntityOffset('Object', 'object');
    DrawEntityOffset('Pet', 'pet');
end

local function DrawTargetingLeftClickSection(settings)
    LibraPlatesSettingsDrawBreadcrumb(T{ 'Targeting', 'Left Click' });
    DrawSettingsHeader('Left click');

    DrawCheckbox('Left-click enemy target out of combat', settings.enableLeftClickEnemyTargetIdle == true, function(value)
        settings.enableLeftClickEnemyTargetIdle = value == true;
    end);

    DrawSettingsHeader('Enemy detail range');

    DrawSliderTenths('Enemy plate range', settings.enemyPlateRange, 50, 644, function(value)
        settings.enemyPlateRange = math.max(5.0, math.min(64.4, tonumber(value) or 49.9));
    end);

    DrawSliderTenths('Enemy active detail range', settings.enemyActiveDetailRange, 100, 499, function(value)
        settings.enemyActiveDetailRange = math.max(10.0, math.min(49.9, tonumber(value) or 25.0));
    end);

    local range = tonumber(settings.enemyActiveDetailRange) or 25.0;
    local tierLabel = 'Balanced';
    local tierColor = { 0.55, 0.85, 1.0, 1.0 };

    if (range <= 15.0) then
        tierLabel = 'Performance';
        tierColor = { 0.35, 1.0, 0.55, 1.0 };
    elseif (range <= 25.0) then
        tierLabel = 'Balanced';
        tierColor = { 0.55, 0.85, 1.0, 1.0 };
    elseif (range <= 35.0) then
        tierLabel = 'High';
        tierColor = { 1.0, 0.84, 0.30, 1.0 };
    else
        tierLabel = 'Ultra';
        tierColor = { 1.0, 0.48, 0.35, 1.0 };
    end

    imgui.TextColored(tierColor, 'Detail mode: ' .. tierLabel);
    uiTooltip.Info('Idle enemies beyond this range keep static identity only. Target, subtarget, engaged, casting, and hovered enemies still use full detail.');
end

local function DrawTargetingRightClickSection(settings)
    LibraPlatesSettingsDrawBreadcrumb(T{ 'Targeting', 'Right Click' });
    DrawSettingsHeader('Right click');

    DrawCheckbox('Right-click attack', settings.enableRightClickAttack == true, function(value)
        settings.enableRightClickAttack = value == true;
    end);

    DrawSliderTenths('Right-click attack range', settings.rightClickAttackRange, 30, 299, function(value)
        settings.rightClickAttackRange = math.max(3.0, math.min(29.9, tonumber(value) or 4.5));
    end);

    imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, 'Range includes a small hitbox allowance, matching the old addon behavior.');
end

local function DrawTargetingClickBlockingSection(settings)
    LibraPlatesSettingsDrawBreadcrumb(T{ 'Targeting', 'Click Blocking' });
    DrawSettingsHeader('Plate click blocking');
    LibraPlatesSettingsDrawPlateClickBlocking(settings);
end

local function DrawSelectedEditorGeneral()
    if (selectedTab == 'General') then
        local global = state.GetGlobalSettings(globalDefaults);
        local settings = targeting.GetSettings();

        if (selectedGeneralSection == 'Profiles') then
            DrawGeneralProfilesSection();
        elseif (selectedGeneralSection == 'Native UI') then
            DrawGeneralNativeUiSection(settings);
        elseif (selectedGeneralSection == 'Mouse') then
            DrawGeneralMouseSection();
        elseif (selectedGeneralSection == 'Scaling') then
            DrawGeneralScalingSection(settings);
        else
            DrawGeneralFontSection(global);
        end

        return;
    end
end

local function DrawSelectedEditorTargeting()
    if (selectedTab == 'Targeting') then
        local settings = targeting.GetSettings();

        if (selectedTargetingSection == 'Right Click') then
            DrawTargetingRightClickSection(settings);
        elseif (selectedTargetingSection == 'Click Blocking') then
            DrawTargetingClickBlockingSection(settings);
        else
            DrawTargetingLeftClickSection(settings);
        end

        return;
    end
end

local function DrawSelectedEditorModules()
if (selectedTab == 'Modules') then
        local selectedModuleName = tostring(selectedModuleWidget or ''):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '');

        LibraPlatesSettingsDrawBreadcrumb(T{ 'Modules', selectedModuleEntity, selectedModuleState, selectedModuleWidget });
        imgui.Separator();

        if (selectedModuleName == 'Target' or selectedModuleName == 'Subtarget') then
            local widgetKey = (selectedModuleName == 'Subtarget') and 'Subtarget Module' or 'Target Module';
            local defaults = (selectedModuleName == 'Subtarget') and subtargetModuleDefaults or targetModuleDefaults;
            local settings = state.GetWidgetSettings(GetStorageEntity(selectedModuleEntity), LibraPlatesSettingsToStorageStateName(selectedModuleState), widgetKey, defaults);

            widgets.targetModule.DrawSettings(settings, {
                tab = selectedTab,
                entity = GetStorageEntity(selectedModuleEntity),
                state = LibraPlatesSettingsToStorageStateName(selectedModuleState),
                widget = widgetKey,
                defaults = defaults,
            });
            return;
        end

        if (selectedModuleName == 'Peer') then
            LibraPlatesSettingsDrawPeerModuleSettings(state.GetGlobalSettings(globalDefaults));
            return;
        end

        if (selectedModuleName == 'Enmity') then
            LibraPlatesSettingsDrawEnmityModuleSettings(state.GetGlobalSettings(globalDefaults));
            return;
        end

        if (selectedModuleName == 'Resting') then
            LibraPlatesSettingsDrawRestingModuleSettings(state.GetGlobalSettings(globalDefaults));
            return;
        end

    if (selectedModuleName == 'Crafting') then
        LibraPlatesSettingsDrawCraftingModuleSettings(state.GetGlobalSettings(globalDefaults));
        return;
    end

        if (selectedModuleName == 'Fishing') then
            LibraPlatesSettingsDrawFishingModuleSettings(state.GetGlobalSettings(globalDefaults));
            return;
        end

        if (selectedModuleName == 'Quick Menu') then
            LibraPlatesSettingsDrawQuickMenuModuleSettings(state.GetGlobalSettings(globalDefaults));
            return;
        end

        DrawYellowHeader(selectedModuleWidget .. ' module');
        imgui.TextColored({ 0.65, 0.90, 1.0, 1.0 }, 'Not built yet.');
        return;
    end

    
end

local function DrawSelectedEditorPlatesTargetWidgets()
    if (
        selectedWidget ~= 'Target' and
        selectedWidget ~= 'Subtarget' and
        selectedWidget ~= 'Target (module)' and
        selectedWidget ~= 'Subtarget (module)' and
        selectedWidget ~= 'Lock-on icon'
    ) then
        return;
    end

    local widgetKey = selectedWidget == 'Lock-on icon' and 'Target Module' or widgetKeys[selectedWidget];
    local defaults = (selectedWidget == 'Subtarget' or selectedWidget == 'Subtarget (module)') and subtargetModuleDefaults or targetModuleDefaults;
    local settings = state.GetWidgetSettings(GetStorageEntity(selectedEntity), LibraPlatesSettingsToStorageStateName(selectedState), widgetKey, defaults);

    widgets.targetModule.DrawSettings(settings, {
        tab = selectedTab,
        entity = GetStorageEntity(selectedEntity),
        state = LibraPlatesSettingsToStorageStateName(selectedState),
        widget = selectedWidget,
        defaults = defaults,
        lockOnly = selectedWidget == 'Lock-on icon',
    });
end

local function DrawSelectedEditorPlatesModules()
    if (selectedWidget == 'Peer (module)') then
        local storageEntity = GetStorageEntity(selectedEntity);
        LibraPlatesSettingsDrawPeerModuleSettings(state.GetGlobalSettings(globalDefaults), {
            hideDisplayMode = storageEntity == 'Self' or storageEntity == 'PC',
            hideSections = storageEntity == 'Self' or storageEntity == 'PC',
        });
        return;
    end

    if (selectedWidget == 'Enmity (module)') then
        LibraPlatesSettingsDrawEnmityModuleSettings(state.GetGlobalSettings(globalDefaults), true);
        return;
    end

    if (selectedWidget == 'Resting (module)') then
        LibraPlatesSettingsDrawRestingModuleSettings(state.GetGlobalSettings(globalDefaults), true);
        return;
    end

    if (selectedWidget == 'Crafting (module)') then
        LibraPlatesSettingsDrawCraftingModuleSettings(state.GetGlobalSettings(globalDefaults), true);
        return;
    end

    if (selectedWidget == 'Fishing (module)') then
        LibraPlatesSettingsDrawFishingModuleSettings(state.GetGlobalSettings(globalDefaults), true);
        return;
    end

    if (selectedWidget == 'Quick Menu (module)') then
        LibraPlatesSettingsDrawQuickMenuModuleSettings(state.GetGlobalSettings(globalDefaults), true);
        return;
    end

    if (selectedWidget == 'AOE range (module)') then
        local settings = state.GetWidgetSettings(GetStorageEntity(selectedEntity), LibraPlatesSettingsToStorageStateName(selectedState), widgetKeys[selectedWidget], aoeRangeDefaults);

        widgets.aoeRange.DrawSettings(settings, {
            tab = selectedTab,
            entity = GetStorageEntity(selectedEntity),
            state = LibraPlatesSettingsToStorageStateName(selectedState),
            widget = selectedWidget,
            defaults = aoeRangeDefaults,
        });
        return;
    end
end

local function DrawSelectedEditorPlatesName()
    if (selectedWidget ~= 'Name') then
        return;
    end

    local storageEntity = GetStorageEntity(selectedEntity);
    local settings = state.GetWidgetSettings(storageEntity, LibraPlatesSettingsToStorageStateName(selectedState), widgetKeys[selectedWidget], nameDefaults);

    if (storageEntity == 'Pet (BST)') then
        local nextOffsetX = ClampOffsetToVisibleEdge(settings.offsetX, 1, 1024, 24);
        local nextOffsetY = ClampOffsetToVisibleEdge(settings.offsetY, 1, 512, 24);

        if (nextOffsetX ~= settings.offsetX or nextOffsetY ~= settings.offsetY) then
            settings.offsetX = nextOffsetX;
            settings.offsetY = nextOffsetY;
            state.Save();
        end
    end

    widgets.name.DrawSettings(settings, {
        tab = selectedTab,
        entity = storageEntity,
        state = LibraPlatesSettingsToStorageStateName(selectedState),
        widget = selectedWidget,
        defaults = nameDefaults,
        anchorChoices = _G.LibraPlatesSettingsGetAnchorChoices(selectedEntity, selectedState, selectedWidget),
        hideActive = true,
    });
end

local function DrawSelectedEditorPlatesWidgetWithStorageDefaults(widgetName, defaults, drawFn, extras)
    if (selectedWidget ~= widgetName) then
        return;
    end

    local settings = state.GetWidgetSettings(GetStorageEntity(selectedEntity), LibraPlatesSettingsToStorageStateName(selectedState), widgetKeys[selectedWidget], defaults);
    local payload = {
        tab = selectedTab,
        entity = GetStorageEntity(selectedEntity),
        state = LibraPlatesSettingsToStorageStateName(selectedState),
        widget = selectedWidget,
        defaults = defaults,
    };

    if (extras ~= nil) then
        if (extras.showSmallFontToggle ~= nil) then
            payload.showSmallFontToggle = extras.showSmallFontToggle;
        end

        if (extras.resourceName ~= nil) then
            payload.resourceName = extras.resourceName;
        end

        if (extras.showValueControl ~= nil) then
            payload.showValueControl = extras.showValueControl;
        end

        if (extras.labelIconOptions ~= nil) then
            payload.labelIconOptions = extras.labelIconOptions;
        end

        if (extras.extraBeforeReset ~= nil) then
            payload.extraBeforeReset = extras.extraBeforeReset;
        end
        payload.hideActive = true;
    else
        payload.anchorChoices = _G.LibraPlatesSettingsGetAnchorChoices(selectedEntity, selectedState, selectedWidget);
        payload.hideActive = true;
    end

    payload.anchorChoices = _G.LibraPlatesSettingsGetAnchorChoices(selectedEntity, selectedState, selectedWidget);
    payload.hideActive = true;

    drawFn(settings, payload);
end

local function DrawSelectedEditorPlatesPetDefaultsWidget(widgetName, defaults, resourceName)
    if (selectedWidget ~= widgetName) then
        return;
    end

    local storageEntity = GetStorageEntity(selectedEntity);
    local settings = state.GetWidgetSettings(storageEntity, LibraPlatesSettingsToStorageStateName(selectedState), widgetKeys[selectedWidget], defaults);

    widgets.bar.DrawSettings(settings, {
        tab = selectedTab,
        entity = storageEntity,
        state = LibraPlatesSettingsToStorageStateName(selectedState),
        widget = selectedWidget,
        resourceName = resourceName,
        defaults = defaults,
        anchorChoices = _G.LibraPlatesSettingsGetAnchorChoices(selectedEntity, selectedState, selectedWidget),
        hideActive = true,
    });
end

local function DrawSelectedEditorPlates()
    if (selectedTab ~= 'Plates') then
        LibraPlatesSettingsDrawBreadcrumb(T{ selectedTab });
        imgui.Separator();
        imgui.TextColored({ 0.65, 0.90, 1.0, 1.0 }, 'Not built yet.');
        return;
    end

    loadModeDrawn = false;
    LibraPlatesSettingsDrawBreadcrumb(T{ selectedTab, selectedEntity, selectedState, selectedWidget });
    LibraPlatesSettingsDrawCurrentWidgetLoadMode();
    imgui.Separator();

    DrawSelectedEditorPlatesTargetWidgets();
    DrawSelectedEditorPlatesModules();
    DrawSelectedEditorPlatesName();
    DrawSelectedEditorPlatesWidgetWithStorageDefaults('Background', backgroundDefaults, widgets.background.DrawSettings);
    DrawSelectedEditorPlatesWidgetWithStorageDefaults('Job', jobDefaults, widgets.job.DrawSettings);
    DrawSelectedEditorPlatesWidgetWithStorageDefaults('Level', levelDefaults, widgets.level.DrawSettings);
    DrawSelectedEditorPlatesWidgetWithStorageDefaults('ID', idDefaults, widgets.id.DrawSettings);
    DrawSelectedEditorPlatesWidgetWithStorageDefaults('Distance', distanceDefaults, widgets.text.DrawSettings, { showSmallFontToggle = true });
    DrawSelectedEditorPlatesWidgetWithStorageDefaults('Type line', require('config.widgets.type_line'), widgets.text.DrawSettings, { showSmallFontToggle = true });
    DrawSelectedEditorPlatesWidgetWithStorageDefaults(
        'Buffs',
        buffsDefaults,
        widgets.statusIcons.DrawSettings
    );
    DrawSelectedEditorPlatesWidgetWithStorageDefaults(
        'Debuffs',
        debuffsDefaults,
        widgets.statusIcons.DrawSettings
    );
    if (selectedWidget == 'Game mode icon') then
        DrawSelectedEditorPlatesWidgetWithStorageDefaults('Game mode icon', gameModeIconDefaults, widgets.gameModeIcon.DrawSettings);
    end
    if (
        selectedWidget == 'Bazaar icon' or
        selectedWidget == 'Linkshell icon' or
        selectedWidget == 'Away icon' or
        selectedWidget == 'Disconnect icon' or
        selectedWidget == 'Anon icon' or
        selectedWidget == 'Follow icon' or
        selectedWidget == 'Party leader icon' or
        selectedWidget == 'Alliance leader icon' or
        selectedWidget == 'Stars icon' or
        selectedWidget == 'Level sync icon' or
        selectedWidget == 'New adventurer icon'
    ) then
        local defaults = bazaarIconDefaults;
        if (selectedWidget == 'Linkshell icon') then
            defaults = linkshellIconDefaults;
        elseif (selectedWidget == 'Away icon') then
            defaults = awayIconDefaults;
        elseif (selectedWidget == 'Disconnect icon') then
            defaults = disconnectIconDefaults;
        elseif (selectedWidget == 'Anon icon') then
            defaults = anonIconDefaults;
        elseif (selectedWidget == 'Follow icon') then
            defaults = followIconDefaults;
        elseif (selectedWidget == 'Party leader icon') then
            defaults = require('config.widgets.party_leader_icon');
        elseif (selectedWidget == 'Alliance leader icon') then
            defaults = require('config.widgets.alliance_leader_icon');
        elseif (selectedWidget == 'Stars icon') then
            defaults = starsIconDefaults;
        elseif (selectedWidget == 'Level sync icon') then
            defaults = levelSyncIconDefaults;
        elseif (selectedWidget == 'New adventurer icon') then
            defaults = newAdventurerIconDefaults;
        end
        DrawSelectedEditorPlatesWidgetWithStorageDefaults(selectedWidget, defaults, widgets.plateIcon.DrawSettings);
    end
    if (selectedWidget == 'Icon' or selectedWidget == 'NPC icon' or selectedWidget == 'Object icon') then
        DrawSelectedEditorPlatesWidgetWithStorageDefaults(selectedWidget, require('config.widgets.npc_object_icon'), widgets.plateIcon.DrawSettings);
    end

    if (selectedWidget == 'HP Bar' or selectedWidget == 'MP Bar' or selectedWidget == 'TP Bar') then
        local storageEntity = GetStorageEntity(selectedEntity);
        local defaults = barDefaults;
        local resourceName = 'TP';
        local showValue = true;

        if (selectedWidget == 'HP Bar') then
            if (storageEntity == 'Pet (SMN)') then
                defaults = smnHpBarDefaults;
            end
            resourceName = 'HP';
            showValue = storageEntity ~= 'Pet (BST)' and storageEntity ~= 'Automaton';
        elseif (selectedWidget == 'MP Bar') then
            if (storageEntity == 'Pet (SMN)') then
                defaults = smnMpBarDefaults;
            end
            resourceName = 'MP';
            showValue = storageEntity ~= 'Automaton';
        elseif (selectedWidget == 'TP Bar') then
            if (storageEntity == 'Pet (SMN)') then
                defaults = smnTpBarDefaults;
            end
            resourceName = 'TP';
        end

        widgets.bar.DrawSettings(state.GetWidgetSettings(storageEntity, LibraPlatesSettingsToStorageStateName(selectedState), widgetKeys[selectedWidget], defaults), {
            tab = selectedTab,
            entity = storageEntity,
            state = LibraPlatesSettingsToStorageStateName(selectedState),
            widget = selectedWidget,
            resourceName = resourceName,
            defaults = defaults,
            showValueControl = showValue,
            anchorChoices = _G.LibraPlatesSettingsGetAnchorChoices(selectedEntity, selectedState, selectedWidget),
            hideActive = true,
        });
    end

    if (selectedWidget == 'Cast bar') then
        local storageEntity = GetStorageEntity(selectedEntity);
        local defaults = castBarDefaults;
        if (storageEntity == 'Pet (SMN)') then
            defaults = smnCastBarDefaults;
        end
        DrawSelectedEditorPlatesWidgetWithStorageDefaults(selectedWidget, defaults, widgets.castBar.DrawSettings);
    end

    if (selectedWidget == 'Pet timer' or selectedWidget == 'Pet state') then
        local defaults = petStateDefaults;
        local extraBeforeReset = nil;
        if (selectedWidget == 'Pet timer') then
            defaults = petTimerDefaults;
            extraBeforeReset = DrawPetTimerExtraSettings;
        else
            defaults = petStateDefaults;
            extraBeforeReset = DrawPetStateExtraSettings;
        end
        local settings = state.GetWidgetSettings(GetStorageEntity(selectedEntity), LibraPlatesSettingsToStorageStateName(selectedState), widgetKeys[selectedWidget], defaults);
        widgets.text.DrawSettings(settings, {
            tab = selectedTab,
            entity = GetStorageEntity(selectedEntity),
            state = LibraPlatesSettingsToStorageStateName(selectedState),
            widget = selectedWidget,
            defaults = defaults,
            anchorChoices = _G.LibraPlatesSettingsGetAnchorChoices(selectedEntity, selectedState, selectedWidget),
            extraBeforeReset = extraBeforeReset,
            hideActive = true,
        });
    end

    if (selectedWidget == 'Ward timer' or selectedWidget == 'Rage timer') then
        local storageEntity = GetStorageEntity(selectedEntity);
        local defaults = petWardBarDefaults;
        local resourceName = 'Ward';
        if (selectedWidget == 'Rage timer') then
            defaults = petRageBarDefaults;
            resourceName = 'Rage';
        end

        local settings = state.GetWidgetSettings(storageEntity, LibraPlatesSettingsToStorageStateName(selectedState), widgetKeys[selectedWidget], defaults);
        widgets.bar.DrawSettings(settings, {
            tab = selectedTab,
            entity = storageEntity,
            state = LibraPlatesSettingsToStorageStateName(selectedState),
            widget = selectedWidget,
            resourceName = resourceName,
            defaults = defaults,
            labelIconOptions = true,
            anchorChoices = _G.LibraPlatesSettingsGetAnchorChoices(selectedEntity, selectedState, selectedWidget),
            hideActive = true,
        });
    end

    if (selectedWidget == 'Sic' or selectedWidget == 'Ready bar' or selectedWidget == 'Reward') then
        local storageEntity = GetStorageEntity(selectedEntity);
        local defaults = petReadyBarDefaults;
        local resourceName = 'Ready';
        local labelIconOptions = true;
        if (selectedWidget == 'Reward') then
            defaults = petRewardBarDefaults;
            resourceName = 'Reward';
        end

        local settings = state.GetWidgetSettings(storageEntity, LibraPlatesSettingsToStorageStateName(selectedState), widgetKeys[selectedWidget], defaults);
        widgets.bar.DrawSettings(settings, {
            tab = selectedTab,
            entity = storageEntity,
            state = LibraPlatesSettingsToStorageStateName(selectedState),
            widget = selectedWidget,
            resourceName = resourceName,
            defaults = defaults,
            labelIconOptions = labelIconOptions,
            anchorChoices = _G.LibraPlatesSettingsGetAnchorChoices(selectedEntity, selectedState, selectedWidget),
            hideActive = true,
        });
    end

    if (selectedWidget == 'Maneuvers') then
        local defaults = require('config.widgets.maneuvers');
        local settings = state.GetWidgetSettings(GetStorageEntity(selectedEntity), LibraPlatesSettingsToStorageStateName(selectedState), widgetKeys[selectedWidget], defaults);
        DrawManeuverSettings(settings);
    end

    if (selectedWidget == 'Name' or selectedWidget == 'Background' or selectedWidget == 'Job' or selectedWidget == 'Level' or selectedWidget == 'ID' or selectedWidget == 'Distance' or selectedWidget == 'Type line' or selectedWidget == 'Buffs' or selectedWidget == 'Debuffs' or selectedWidget == 'Game mode icon' or selectedWidget == 'Bazaar icon' or selectedWidget == 'Linkshell icon' or selectedWidget == 'Away icon' or selectedWidget == 'Disconnect icon' or selectedWidget == 'Anon icon' or selectedWidget == 'Follow icon' or selectedWidget == 'Party leader icon' or selectedWidget == 'Alliance leader icon' or selectedWidget == 'Stars icon' or selectedWidget == 'Level sync icon' or selectedWidget == 'New adventurer icon' or selectedWidget == 'Icon' or selectedWidget == 'NPC icon' or selectedWidget == 'Object icon' or selectedWidget == 'HP Bar' or selectedWidget == 'MP Bar' or selectedWidget == 'TP Bar' or selectedWidget == 'Cast bar' or selectedWidget == 'Pet timer' or selectedWidget == 'Pet state' or selectedWidget == 'Ward timer' or selectedWidget == 'Rage timer' or selectedWidget == 'Sic' or selectedWidget == 'Ready bar' or selectedWidget == 'Reward' or selectedWidget == 'Maneuvers' or selectedWidget == 'Target' or selectedWidget == 'Subtarget' or selectedWidget == 'Target (module)' or selectedWidget == 'Subtarget (module)' or selectedWidget == 'Peer (module)' or selectedWidget == 'Enmity (module)' or selectedWidget == 'Resting (module)' or selectedWidget == 'Crafting (module)' or selectedWidget == 'Fishing (module)' or selectedWidget == 'Quick Menu (module)' or selectedWidget == 'AOE range (module)') then
        if (loadModeDrawn ~= true) then
            LibraPlatesSettingsDrawCurrentWidgetLoadMode();
        end
        return;
    end

    DrawYellowHeader(selectedWidget .. ' settings');
    imgui.TextColored({ 0.65, 0.90, 1.0, 1.0 }, 'Not built yet.');
end

DrawSelectedEditor = function()
    if (selectedTab == 'General') then
        DrawSelectedEditorGeneral();
        return;
    end

    if (selectedTab == 'Targeting') then
        DrawSelectedEditorTargeting();
        return;
    end

    if (selectedTab == 'Modules') then
        DrawSelectedEditorModules();
        return;
    end

    DrawSelectedEditorPlates();
end
function settingsUi.Load()
    RestoreUiSelection();
end

function settingsUi.Unload()
    PersistUiSelection();
end

-- ============================================================
-- Rendering
-- ============================================================

function settingsUi.Render()
    if (state.GetConfigOpen() ~= true) then
        return;
    end

    windowOpen[1] = true;

    local renderError = nil;

    if (imgui.SetNextWindowSize ~= nil) then
        imgui.SetNextWindowSize({ 1100, 720 }, _G.ImGuiCond_FirstUseEver or 4);
    end

    local styleCount = PushSettingsAccentStyle();
    local windowFlags = settingsWindowFlags;

    if (preview.ShouldLockSettingsWindowMove ~= nil and preview.ShouldLockSettingsWindowMove() == true) then
        windowFlags = windowFlags + settingsWindowNoMoveFlag;
    end

    local began = imgui.Begin('LibraPlates Settings', windowOpen, windowFlags);

    if (began) then
        local ok, err = pcall(function()
            DrawTopTabs();
            imgui.Separator();

            if (selectedTab == 'General' or selectedTab == 'Targeting' or selectedTab == 'Plates' or selectedTab == 'Modules') then
                local availWidth, availHeight = GetContentRegionAvail();
                local selectorWidth = (selectedTab == 'Plates') and 260 or 190;

                DrawChild('##selector_panel', { selectorWidth, math.max(260, availHeight - 24) }, true, function()
                    if (selectedTab == 'Modules') then
                        DrawModulesSelector();
                    elseif (selectedTab == 'General') then
                        DrawSectionSelector(generalSections, selectedGeneralSection, function(section)
                            selectedGeneralSection = section;
                        end);
                    elseif (selectedTab == 'Targeting') then
                        DrawSectionSelector(targetingSections, selectedTargetingSection, function(section)
                            selectedTargetingSection = section;
                        end);
                    else
                        DrawPlatesSelector();
                    end
                end);

                imgui.SameLine();

                DrawChild('##right_panel', { math.max(420, availWidth - selectorWidth - 12), math.max(260, availHeight - 24) }, false, function()
                    if (selectedTab == 'General' or selectedTab == 'Targeting') then
                        DrawSelectedEditor();
                    else
                        DrawRightPanel();
                    end
                end);
            else
                DrawSelectedEditor();
            end

            DrawYellowHeader('Close');

            if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
                windowOpen[1] = false;
            end
        end);

        if (ok ~= true) then
            renderError = err;
        end
    end

    imgui.End();
    PopSettingsAccentStyle(styleCount);

    if (windowOpen[1] ~= true) then
        state.SetConfigOpen(false);
    end

    if (renderError ~= nil) then
        error(renderError);
    end

    PersistUiSelection();
    state.SaveThrottled(1.0);
end

return settingsUi;
