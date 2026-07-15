local peerInspector = {};

local imgui = require('imgui');
local bit = require('bit');
local textureLoader = require('core.texture_loader');
local worldMarkerProbe = require('core.world_marker_probe');
local entities = require('core.entities');
local mobInfoData = require('core.mobinfo_data');
local npcObjectInfo = require('core.npc_object_info');
local adaptivePerformance = require('core.adaptive_performance');
local gameMode = require('core.game_mode');
local playerIndicators = require('core.player_indicators');
local state = require('core.state');
local targeting = require('core.targeting');
local globalDefaults = require('config.global');

local iconCache = {};
local selfElementIconCache = {};
local enemyInfoCache = {
    key = nil,
    info = nil,
    updated = 0,
};

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

local function MergePeerSettings(globalPeerSettings, widgetPeerSettings)
    local merged = CopyTable(globalPeerSettings or {});

    if (type(widgetPeerSettings) == 'table') then
        for key, value in pairs(widgetPeerSettings) do
            merged[key] = CopyTable(value);
        end
    end

    return merged;
end

local function IsVirtualKeyDown(vk)
    if (peerInspector.user32 == nil) then
        return false;
    end

    local ok, keyState = pcall(function()
        return peerInspector.user32.GetAsyncKeyState(vk);
    end);

    if (ok ~= true) then
        return false;
    end

    return bit.band(tonumber(keyState) or 0, 0x8000) ~= 0;
end

local function IsModifierActive(peerSettings)
    local modifier = tostring(peerSettings ~= nil and peerSettings.activationModifier or 'Shift');

    if (modifier == 'None') then
        return true;
    end

    if (modifier == 'Ctrl') then
        return IsVirtualKeyDown(0x11);
    end

    if (modifier == 'Alt') then
        return IsVirtualKeyDown(0x12);
    end

    return IsVirtualKeyDown(0x10);
end

local function NormalizeLoadMode(value)
    local mode = tostring(value or 'Always');

    if (mode == 'OutOfCombat') then return 'Out of combat'; end
    if (mode == 'InCombat') then return 'In combat'; end
    if (mode == 'Always' or mode == 'Out of combat' or mode == 'In combat' or mode == 'Never') then return mode; end

    return 'Always';
end

local function PeerWidgetLoads(peerWidgetSettings)
    if (peerWidgetSettings == nil or peerWidgetSettings.enabled ~= true) then
        return false;
    end

    local mode = NormalizeLoadMode(peerWidgetSettings.loadMode);

    if (mode == 'Never') then
        return false;
    end

    local isEngaged = targeting.IsPlayerEngaged() == true;

    if (mode == 'Out of combat') then
        return isEngaged ~= true;
    end

    if (mode == 'In combat') then
        return isEngaged == true;
    end

    return true;
end

local function SanitizeIconStyle(style)
    style = tostring(style or 'round');

    if (style == '') then
        return 'round';
    end

    return style;
end

local function GetIconTextureId(iconName, iconStyle)
    iconName = tostring(iconName or '');
    iconStyle = SanitizeIconStyle(iconStyle);

    if (iconName == '') then
        return nil;
    end

    local cacheKey = iconStyle .. ':' .. iconName;

    if (iconCache[cacheKey] ~= nil) then
        return iconCache[cacheKey];
    end

    local path = tostring(addon.path or '') .. '\\assets\\images\\peer-icons\\' .. iconStyle .. '\\' .. iconName .. '.png';
    iconCache[cacheKey] = textureLoader.ToTextureId(textureLoader.Load(path));
    return iconCache[cacheKey];
end

local function GetSelfElementIconTextureId(iconName)
    iconName = tostring(iconName or '');

    if (iconName == '') then
        return nil;
    end

    if (selfElementIconCache[iconName] ~= nil) then
        return selfElementIconCache[iconName];
    end

    local path = tostring(addon.path or '') .. '\\assets\\images\\self-peer\\' .. iconName .. '.png';
    selfElementIconCache[iconName] = textureLoader.ToTextureId(textureLoader.Load(path));
    return selfElementIconCache[iconName];
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

local function GetDisplaySize()
    if (imgui.GetIO == nil) then
        return 1280, 720;
    end

    local ok, io = pcall(function()
        return imgui.GetIO();
    end);

    if (ok ~= true or io == nil or io.DisplaySize == nil) then
        return 1280, 720;
    end

    return tonumber(io.DisplaySize.x or io.DisplaySize[1]) or 1280, tonumber(io.DisplaySize.y or io.DisplaySize[2]) or 720;
end

local function ColorU32(color)
    color = color or { 1.0, 1.0, 1.0, 1.0 };

    local r = math.max(0, math.min(255, math.floor((tonumber(color[1]) or 1) * 255 + 0.5)));
    local g = math.max(0, math.min(255, math.floor((tonumber(color[2]) or 1) * 255 + 0.5)));
    local b = math.max(0, math.min(255, math.floor((tonumber(color[3]) or 1) * 255 + 0.5)));
    local a = math.max(0, math.min(255, math.floor((tonumber(color[4]) or 1) * 255 + 0.5)));

    return (a * 0x1000000) + (b * 0x10000) + (g * 0x100) + r;
end

local function FormatModifierPercent(potency)
    potency = tonumber(potency) or 1;

    if (potency > 1) then
        return '+' .. tostring(math.floor(((potency - 1) * 100) + 0.5)) .. '%';
    end

    return '-' .. tostring(math.floor(((1 - potency) * 100) + 0.5)) .. '%';
end

local function DrawText(drawList, x, y, color, text)
    if (drawList ~= nil and drawList.AddText ~= nil) then
        drawList:AddText({ x, y }, color, tostring(text or ''));
    end
end

local function DrawOutlinedText(drawList, x, y, color, text, outlineSize, outlineColor)
    outlineSize = math.max(0, math.min(4, tonumber(outlineSize) or 0));

    if (outlineSize > 0) then
        for ox = -outlineSize, outlineSize do
            for oy = -outlineSize, outlineSize do
                if (ox ~= 0 or oy ~= 0) then
                    DrawText(drawList, x + ox, y + oy, outlineColor, text);
                end
            end
        end
    end

    DrawText(drawList, x, y, color, text);
end

local function LimitText(text, maxChars)
    text = tostring(text or '');
    maxChars = tonumber(maxChars) or 48;

    if (#text <= maxChars) then
        return text;
    end

    return string.sub(text, 1, math.max(1, maxChars - 3)) .. '...';
end

local DrawTextRow = nil;
local DrawPeerPanelBox = nil;
local GetPeerInspectorWidth = nil;
local GetEnemyPeerTextInspectorHeight = nil;
local GetEnemyPeerIconInspectorHeight = nil;

local iconText = {
    AggroHQ = 'Aggro',
    AggroNQ = 'Aggro',
    PassiveHQ = 'Passive',
    PassiveNQ = 'Passive',
    Link = 'Yes',
    TrueSight = 'True sight',
    Sight = 'Sight',
    Sound = 'Sound',
    Scent = 'Scent',
    Magic = 'Magic',
    JA = 'Job ability',
    Blood = 'Low HP',
    ImmuneSleep = 'Sleep',
    ImmuneGravity = 'Gravity',
    ImmuneBind = 'Bind',
    ImmuneStun = 'Stun',
    ImmuneSilence = 'Silence',
    ImmuneParalyze = 'Paralyze',
    ImmuneBlind = 'Blind',
    ImmuneSlow = 'Slow',
    ImmunePoison = 'Poison',
    ImmuneElegy = 'Elegy',
    ImmuneRequiem = 'Requiem',
    ImmuneLightSleep = 'Light sleep',
    ImmuneDarkSleep = 'Dark sleep',
    ImmunePetrify = 'Petrify',
};

local jobNames = {
    [1] = 'Warrior',
    [2] = 'Monk',
    [3] = 'White Mage',
    [4] = 'Black Mage',
    [5] = 'Red Mage',
    [6] = 'Thief',
    [7] = 'Paladin',
    [8] = 'Dark Knight',
    [9] = 'Beastmaster',
    [10] = 'Bard',
    [11] = 'Ranger',
    [12] = 'Samurai',
    [13] = 'Ninja',
    [14] = 'Dragoon',
    [15] = 'Summoner',
    [16] = 'Blue Mage',
    [17] = 'Corsair',
    [18] = 'Puppetmaster',
    [19] = 'Dancer',
    [20] = 'Scholar',
    [21] = 'Geomancer',
    [22] = 'Rune Fencer',
};

local jobAbbreviations = {
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

local selfStatRows = T{
    T{ label = 'STR', id = 0 },
    T{ label = 'DEX', id = 1 },
    T{ label = 'VIT', id = 2 },
    T{ label = 'AGI', id = 3 },
    T{ label = 'INT', id = 4 },
    T{ label = 'MND', id = 5 },
    T{ label = 'CHR', id = 6 },
};

local selfElementRows = T{
    T{ icon = 'Fire', id = 0 },
    T{ icon = 'Ice', id = 1 },
    T{ icon = 'Wind', id = 2 },
    T{ icon = 'Earth', id = 3 },
    T{ icon = 'Lightning', id = 4 },
    T{ icon = 'Water', id = 5 },
    T{ icon = 'Light', id = 6 },
    T{ icon = 'Dark', id = 7 },
};

local function SafeNumber(fallback, fn)
    local ok, value = pcall(fn);

    if (ok ~= true or value == nil) then
        return fallback;
    end

    return tonumber(value) or fallback;
end

local function FormatSigned(value)
    value = tonumber(value) or 0;

    if (value > 0) then
        return '+' .. tostring(value);
    elseif (value < 0) then
        return tostring(value);
    end

    return '';
end

local function GetJobName(jobId)
    jobId = tonumber(jobId);

    if (jobId == nil or jobId <= 0) then
        return '';
    end

    local text = nil;

    pcall(function()
        text = AshitaCore:GetResourceManager():GetString('jobs.names', jobId);
    end);

    text = tostring(text or '');

    if (text == '' or text == 'nil') then
        text = jobNames[jobId] or '';
    end

    return text;
end

local function GetJobAbbreviation(jobId)
    jobId = tonumber(jobId);

    if (jobId == nil or jobId <= 0) then
        return '';
    end

    local text = nil;

    pcall(function()
        text = AshitaCore:GetResourceManager():GetString('jobs.names_abbr', jobId);
    end);

    text = tostring(text or '');

    if (text == '' or text == 'nil') then
        text = jobAbbreviations[jobId] or '';
    end

    return text;
end

local function FormatCurrentMax(current, max)
    current = tonumber(current);
    max = tonumber(max);

    if (current ~= nil and max ~= nil and max > 0) then
        return tostring(current) .. '/' .. tostring(max);
    end

    if (current ~= nil) then
        return tostring(current);
    end

    return '0';
end

local function ShouldShowSelfJobLine(peerSettings)
    return peerSettings.showJob ~= false or peerSettings.showLevel ~= false;
end

local function FormatSelfJobPart(level, job, peerSettings)
    local parts = {};

    if (peerSettings.showLevel ~= false) then
        parts[#parts + 1] = 'Lv' .. tostring(level or 0);
    end

    if (peerSettings.showJob ~= false and job ~= '') then
        parts[#parts + 1] = job;
    end

    return table.concat(parts, ' ');
end

local function GetSelfPeerPanelHeight(peerSettings)
    local height = 12;

    if (peerSettings.showName ~= false) then
        height = height + 22;
    end

    if (ShouldShowSelfJobLine(peerSettings) == true) then
        height = height + 22;
    end

    if (peerSettings.showHpValue ~= false) then
        height = height + (7 * 22);
    end

    if (peerSettings.showWeakTo ~= false or peerSettings.showResists ~= false) then
        height = height + 16;
    end

    if (peerSettings.showWeakTo ~= false) then
        height = height + 26;
    end

    if (peerSettings.showResists ~= false) then
        height = height + 46;
    end

    return math.max(52, height + 12);
end

local function GetSelfPeerData()
    local memory = AshitaCore:GetMemoryManager();
    local party = memory:GetParty();
    local player = memory:GetPlayer();
    local self = entities.GetSelf() or {};
    local data = {
        name = tostring(self.name or 'Self'),
        hp = self.hp,
        maxHp = self.maxHp,
        mp = self.mp,
        maxMp = self.maxMp,
        tp = self.tp,
        stats = {},
        resists = {},
    };

    pcall(function()
        local memberName = party:GetMemberName(0);
        if (memberName ~= nil and tostring(memberName) ~= '') then
            data.name = tostring(memberName);
        end
    end);

    data.mainJob = SafeNumber(0, function() return player:GetMainJob(); end);
    data.mainJobLevel = SafeNumber(0, function() return player:GetMainJobLevel(); end);
    data.subJob = SafeNumber(0, function() return player:GetSubJob(); end);
    data.subJobLevel = SafeNumber(0, function() return player:GetSubJobLevel(); end);
    data.suLevel = SafeNumber(0, function() return player:GetSuLevel(); end);
    data.attack = SafeNumber(0, function() return player:GetAttack(); end);
    data.defense = SafeNumber(0, function() return player:GetDefense(); end);

    if (data.maxHp == nil or tonumber(data.maxHp) == nil or tonumber(data.maxHp) <= 0) then
        data.maxHp = SafeNumber(0, function() return player:GetHPMax(); end);
    end

    if (data.maxMp == nil or tonumber(data.maxMp) == nil or tonumber(data.maxMp) <= 0) then
        data.maxMp = SafeNumber(0, function() return player:GetMPMax(); end);
    end

    for _, stat in ipairs(selfStatRows) do
        data.stats[#data.stats + 1] = {
            label = stat.label,
            value = SafeNumber(0, function() return player:GetStat(stat.id); end),
            modifier = SafeNumber(0, function() return player:GetStatModifier(stat.id); end),
        };
    end

    for _, element in ipairs(selfElementRows) do
        data.resists[#data.resists + 1] = {
            icon = element.icon,
            value = SafeNumber(0, function() return player:GetResist(element.id); end),
        };
    end

    return data;
end

local function DrawSelfInspector(data, peerSettings)
    local drawList = imgui.GetForegroundDrawList ~= nil and imgui.GetForegroundDrawList() or imgui.GetWindowDrawList();

    if (drawList == nil) then
        return;
    end

    local mouseX, mouseY = GetMousePos();

    if (mouseX == nil or mouseY == nil) then
        return;
    end

    local displayW, displayH = GetDisplaySize();
    local w = GetPeerInspectorWidth(peerSettings, 292);
    local h = GetSelfPeerPanelHeight(peerSettings);
    local x = mouseX + 22;
    local y = mouseY + 18;

    if ((x + w) > (displayW - 12)) then
        x = mouseX - w - 22;
    end

    if ((y + h) > (displayH - 12)) then
        y = displayH - h - 12;
    end

    x = math.max(12, x);
    y = math.max(12, y);

    local text = ColorU32(peerSettings.textColor or { 0.94, 0.94, 0.90, 1.0 });
    local outline = ColorU32(peerSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 });
    local outlineSize = tonumber(peerSettings.textOutlineSize) or 0;
    local muted = ColorU32({ 0.68, 0.72, 0.74, 1.0 });
    local blue = ColorU32({ 0.62, 0.80, 1.0, 1.0 });
    local green = ColorU32({ 0.35, 1.0, 0.45, 1.0 });
    local heading = ColorU32({ 1.0, 0.84, 0.0, 1.0 });
    local labelX = x + 14;
    local valueX = x + 84;
    local rowY = y + 12;
    local rowStep = 22;
    local mainJob = GetJobAbbreviation(data.mainJob);
    local subJob = GetJobAbbreviation(data.subJob);

    DrawPeerPanelBox(drawList, x, y, w, h, peerSettings);

    if (peerSettings.showName ~= false) then
        DrawOutlinedText(drawList, labelX, rowY, text, LimitText(data.name, 24), outlineSize + 1, outline);
        rowY = rowY + rowStep;
    end

    if (ShouldShowSelfJobLine(peerSettings) == true and (mainJob ~= '' or subJob ~= '')) then
        local jobText = '';
        if (mainJob ~= '') then
            jobText = FormatSelfJobPart(data.mainJobLevel, mainJob, peerSettings);
        end
        if (subJob ~= '') then
            jobText = (jobText ~= '' and (jobText .. ' / ') or '') .. FormatSelfJobPart(data.subJobLevel, subJob, peerSettings);
        end
        DrawOutlinedText(drawList, labelX, rowY, blue, jobText, outlineSize, outline);
        rowY = rowY + rowStep;
    end

    if (peerSettings.showHpValue ~= false) then
        for _, stat in ipairs(data.stats or {}) do
            DrawOutlinedText(drawList, labelX, rowY, heading, stat.label, outlineSize, outline);
            DrawOutlinedText(drawList, valueX, rowY, text, tostring(stat.value or 0), outlineSize, outline);

            local modifier = FormatSigned(stat.modifier);
            if (modifier ~= '') then
                DrawOutlinedText(drawList, valueX + 42, rowY, green, modifier, outlineSize, outline);
            end

            rowY = rowY + rowStep;
        end
    end

    if (peerSettings.showWeakTo ~= false or peerSettings.showResists ~= false) then
        rowY = rowY + 4;
        if (drawList.AddLine ~= nil) then
            drawList:AddLine({ x + 10, rowY }, { x + w - 10, rowY }, ColorU32({ 0.62, 0.67, 0.72, 0.55 }), 1);
        end
        rowY = rowY + 12;
    end

    if (peerSettings.showWeakTo ~= false) then
        DrawOutlinedText(drawList, labelX, rowY, text, 'Attack ' .. tostring(data.attack or 0), outlineSize, outline);
        DrawOutlinedText(drawList, labelX + 126, rowY, text, 'Defense ' .. tostring(data.defense or 0), outlineSize, outline);
        rowY = rowY + 26;
    end

    local iconSize = 15;

    if (peerSettings.showResists ~= false) then
        for i, row in ipairs(data.resists or {}) do
            local col = (i - 1) % 4;
            local rowIndex = math.floor((i - 1) / 4);
            local iconX = labelX + (col * 58);
            local iconY = rowY + (rowIndex * 23);
            local textureId = GetSelfElementIconTextureId(row.icon);

            if (textureId ~= nil and drawList.AddImage ~= nil) then
                drawList:AddImage(textureId, { iconX, iconY }, { iconX + iconSize, iconY + iconSize }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
            end

            DrawOutlinedText(drawList, iconX + iconSize + 4, iconY - 1, muted, tostring(row.value or 0), outlineSize, outline);
        end
    end
end

local function GetEntityField(entity, fieldNames)
    for _, fieldName in ipairs(fieldNames or {}) do
        local value = entity ~= nil and entity[fieldName] or nil;

        if (value ~= nil and tostring(value) ~= '') then
            return value;
        end
    end

    return nil;
end

local function GetPlayerTargetName(index)
    local entityManager = entities.GetEntityManager();
    local targetIndex = nil;

    if (entityManager ~= nil and entityManager.GetTargetedIndex ~= nil) then
        targetIndex = SafeNumber(nil, function()
            return entityManager:GetTargetedIndex(index);
        end);
    end

    if (targetIndex == nil or targetIndex == 0) then
        local ent = entities.GetEntity(index);
        targetIndex = tonumber(GetEntityField(ent, T{ 'TargetIndex', 'TargetID', 'TargetId', 'Target' }));
    end

    if (targetIndex == nil or targetIndex == 0) then
        return '';
    end

    local target = entities.GetEntity(targetIndex);
    return tostring(target ~= nil and target.Name or '');
end

local function BuildPlayerModeText(index)
    return tostring(gameMode.Resolve(index, false) or '');
end

local function GetPlayerPeerData(index, peerSettings)
    local result = nil;
    local maxRange = math.max(0.0, math.min(49.9, tonumber(peerSettings.maxRange) or 49.9));

    for _, player in ipairs(entities.GetNearbyPlayers(maxRange)) do
        if (tonumber(player.index) == tonumber(index)) then
            result = player;
            break;
        end
    end

    local ent = entities.GetEntity(index);

    if (result == nil and ent ~= nil) then
        result = {
            index = index,
            name = ent.Name,
            status = ent.Status,
            distance = ent.Distance ~= nil and math.sqrt(tonumber(ent.Distance) or 0) or nil,
            hpPercent = ent.HPPercent,
        };
    end

    if (result == nil) then
        return nil;
    end

    result.modeText = BuildPlayerModeText(index);
    result.targetName = GetPlayerTargetName(index);

    return result;
end

local function DrawPlayerInspector(player, peerSettings)
    local drawList = imgui.GetForegroundDrawList ~= nil and imgui.GetForegroundDrawList() or imgui.GetWindowDrawList();

    if (drawList == nil) then
        return;
    end

    local mouseX, mouseY = GetMousePos();

    if (mouseX == nil or mouseY == nil) then
        return;
    end

    local displayW, displayH = GetDisplaySize();
    local w = GetPeerInspectorWidth(peerSettings, 330);
    local rowStep = 24;
    local hasMode = tostring(player.modeText or '') ~= '';
    local hasTarget = tostring(player.targetName or '') ~= '';
    local h = 52 + (player.hpPercent ~= nil and rowStep or 0) + (hasMode and rowStep or 0) + (hasTarget and rowStep or 0);
    local x = mouseX + 22;
    local y = mouseY + 18;

    if ((x + w) > (displayW - 12)) then
        x = mouseX - w - 22;
    end

    if ((y + h) > (displayH - 12)) then
        y = displayH - h - 12;
    end

    x = math.max(12, x);
    y = math.max(12, y);

    local text = ColorU32(peerSettings.textColor or { 0.94, 0.94, 0.90, 1.0 });
    local outline = ColorU32(peerSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 });
    local outlineSize = tonumber(peerSettings.textOutlineSize) or 0;
    local muted = ColorU32({ 0.68, 0.72, 0.74, 1.0 });
    local blue = ColorU32({ 0.62, 0.80, 1.0, 1.0 });
    local heading = ColorU32({ 1.0, 0.84, 0.0, 1.0 });
    local labelX = x + 14;
    local rightX = x + 204;
    local valueX = x + 104;
    local rowY = y + 12;

    DrawPeerPanelBox(drawList, x, y, w, h, peerSettings);

    DrawOutlinedText(drawList, labelX, rowY, text, LimitText(player.name, 22), outlineSize + 1, outline);
    if (player.distance ~= nil) then
        DrawOutlinedText(drawList, rightX, rowY, heading, 'Distance', outlineSize, outline);
        DrawOutlinedText(drawList, rightX + 74, rowY, text, string.format('%.1f', tonumber(player.distance) or 0), outlineSize, outline);
    end

    rowY = rowY + rowStep;
    if (player.hpPercent ~= nil) then
        DrawOutlinedText(drawList, labelX, rowY, heading, 'HP', outlineSize, outline);
        DrawOutlinedText(drawList, valueX, rowY, text, tostring(math.floor((tonumber(player.hpPercent) or 0) + 0.5)) .. '%', outlineSize, outline);
        rowY = rowY + rowStep;
    end

    if (hasMode == true) then
        DrawOutlinedText(drawList, labelX, rowY, heading, 'Mode', outlineSize, outline);
        DrawOutlinedText(drawList, valueX, rowY, text, LimitText(player.modeText, 34), outlineSize, outline);
        rowY = rowY + rowStep;
    end

    if (hasTarget == true) then
        DrawOutlinedText(drawList, labelX, rowY, heading, 'Target', outlineSize, outline);
        DrawOutlinedText(drawList, valueX, rowY, text, LimitText(player.targetName, 30), outlineSize, outline);
    end
end

local function IconsToText(icons, fallback)
    local values = {};

    for _, iconName in ipairs(icons or {}) do
        values[#values + 1] = iconText[tostring(iconName)] or tostring(iconName);
    end

    if (#values == 0) then
        return fallback or 'None known';
    end

    return table.concat(values, ', ');
end

local function ModifierRowsToText(rows, fallback)
    local values = {};

    for _, row in ipairs(rows or {}) do
        values[#values + 1] = tostring(row.icon or '') .. ' ' .. FormatModifierPercent(row.potency);
    end

    if (#values == 0) then
        return fallback or 'None known';
    end

    return table.concat(values, ', ');
end

local function FormatHpValue(enemy)
    local hpPercent = tonumber(enemy ~= nil and enemy.hpPercent);

    if (hpPercent == nil) then
        return 'Unknown';
    end

    return tostring(math.floor(hpPercent + 0.5)) .. '%';
end

local function DrawIconRow(drawList, x, y, icons, iconStyle, iconSize, maxWidth)
    local cursorX = x;
    local count = 0;

    for _, iconName in ipairs(icons or {}) do
        if ((cursorX + iconSize) > (x + maxWidth)) then
            break;
        end

        local textureId = GetIconTextureId(iconName, iconStyle);

        if (textureId ~= nil and drawList.AddImage ~= nil) then
            drawList:AddImage(textureId, { cursorX, y }, { cursorX + iconSize, y + iconSize }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
            cursorX = cursorX + iconSize + 5;
            count = count + 1;
        end
    end

    return count;
end

local function DrawModifierRow(drawList, x, y, rows, iconStyle, iconSize, maxWidth, valueColor)
    local cursorX = x;
    local count = 0;

    for _, modifier in ipairs(rows or {}) do
        if ((cursorX + iconSize) > (x + maxWidth)) then
            break;
        end

        local textureId = GetIconTextureId(modifier.icon, iconStyle);

        if (textureId ~= nil and drawList.AddImage ~= nil) then
            drawList:AddImage(textureId, { cursorX, y }, { cursorX + iconSize, y + iconSize }, { 0, 0 }, { 1, 1 }, 0xFFFFFFFF);
            DrawText(drawList, cursorX - 1, y + iconSize + 1, valueColor, FormatModifierPercent(modifier.potency));
            cursorX = cursorX + iconSize + 20;
            count = count + 1;
        end
    end

    return count;
end

local function SplitModifierRows(info)
    local weak = {};
    local resist = {};

    for _, row in ipairs(mobInfoData.GetModifierRows(info)) do
        if ((tonumber(row.potency) or 1) > 1) then
            weak[#weak + 1] = row;
        elseif ((tonumber(row.potency) or 1) < 1) then
            resist[#resist + 1] = row;
        end
    end

    return weak, resist;
end

local function BuildThreatRows(info)
    local aggro = {};
    local detection = {};
    local links = {};

    for _, iconName in ipairs(mobInfoData.GetFlags(info)) do
        if (
            iconName == 'AggroHQ' or
            iconName == 'AggroNQ' or
            iconName == 'PassiveHQ' or
            iconName == 'PassiveNQ'
        ) then
            aggro[#aggro + 1] = iconName;
        elseif (iconName == 'Link') then
            links[#links + 1] = iconName;
        else
            detection[#detection + 1] = iconName;
        end
    end

    return aggro, detection, links;
end

local function GetPeerViewerLevel()
    local level = 0;

    pcall(function()
        level = AshitaCore:GetMemoryManager():GetParty():GetMemberMainJobLevel(0);
    end);

    return tonumber(level) or 0;
end

local function GetPeerDifficultyKey(info)
    local viewerLevel = GetPeerViewerLevel();
    local mobLevel = info ~= nil and (info.MaxLevel or info.Level or info.MinLevel) or nil;

    viewerLevel = tonumber(viewerLevel) or 0;
    mobLevel = tonumber(mobLevel);

    if (viewerLevel <= 0 or mobLevel == nil) then
        return nil;
    end

    local delta = mobLevel - viewerLevel;

    if (delta <= -21) then return 'tw'; end
    if (delta <= -8) then return 'ep'; end
    if (delta <= -1) then return 'dc'; end
    if (delta == 0) then return 'em'; end
    if (delta <= 6) then return 't'; end
    if (delta == 7) then return 'vt'; end
    return 'it';
end

local function GetPeerLevelColor(peerSettings, info)
    if (peerSettings == nil or peerSettings.levelDifficultyColorsEnabled ~= true) then
        return peerSettings ~= nil and peerSettings.levelColor or { 0.40, 0.70, 1.0, 1.0 };
    end

    local key = GetPeerDifficultyKey(info);

    if (key == 'tw') then return peerSettings.levelTwColor or peerSettings.levelColor; end
    if (key == 'ep') then return peerSettings.levelEpColor or peerSettings.levelColor; end
    if (key == 'dc') then return peerSettings.levelDcColor or peerSettings.levelColor; end
    if (key == 'em') then return peerSettings.levelEmColor or peerSettings.levelColor; end
    if (key == 't') then return peerSettings.levelTColor or peerSettings.levelColor; end
    if (key == 'vt') then return peerSettings.levelVtColor or peerSettings.levelColor; end
    if (key == 'it') then return peerSettings.levelItColor or peerSettings.levelColor; end

    return peerSettings.levelColor or { 0.40, 0.70, 1.0, 1.0 };
end

local function GetEnemyPeerDisplayName(enemy)
    local rawName = enemy ~= nil and enemy.name or '';
    local cleanName = mobInfoData.GetLookupName(rawName);

    if (mobInfoData.HasActivityPointMarker(rawName) == true) then
        return 'AP - ' .. tostring(cleanName or '');
    end

    return tostring(cleanName or rawName or '');
end

local function GetEnemyPeerMobInfo(enemy)
    if (enemy == nil) then
        return nil;
    end

    local key = tostring(enemy.index or '') .. ':' .. tostring(enemy.name or '');

    if (adaptivePerformance.ShouldThrottleBackground() == true) then
        local now = os.clock();

        if (
            enemyInfoCache.key == key and
            (now - (tonumber(enemyInfoCache.updated) or 0)) < 0.25
        ) then
            return enemyInfoCache.info;
        end

        enemyInfoCache.key = key;
        enemyInfoCache.info = mobInfoData.GetMobInfo(enemy.name, enemy.index);
        enemyInfoCache.updated = now;
        return enemyInfoCache.info;
    end

    return mobInfoData.GetMobInfo(enemy.name, enemy.index);
end

DrawTextRow = function(drawList, labelX, valueX, y, labelColor, valueColor, label, value, outlineSize, outlineColor)
    DrawOutlinedText(drawList, labelX, y, labelColor, label, outlineSize, outlineColor);
    DrawOutlinedText(drawList, valueX, y, valueColor, LimitText(value, 44), outlineSize, outlineColor);
end

local function GetPeerBackgroundColor(peerSettings)
    local color = peerSettings.backgroundColor or { 0.015, 0.018, 0.024, 1.0 };
    local opacity = math.max(0, math.min(100, tonumber(peerSettings.backgroundOpacity) or 92)) / 100;

    return ColorU32({ color[1] or 0.015, color[2] or 0.018, color[3] or 0.024, opacity });
end

GetPeerInspectorWidth = function(peerSettings, fallback)
    local width = tonumber(peerSettings ~= nil and peerSettings.inspectorWidth) or tonumber(fallback) or 430;
    return math.max(120, math.min(800, width));
end

GetEnemyPeerTextInspectorHeight = function(peerSettings)
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

GetEnemyPeerIconInspectorHeight = function(peerSettings)
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

DrawPeerPanelBox = function(drawList, x, y, w, h, peerSettings)
    local bg = GetPeerBackgroundColor(peerSettings);
    local border = ColorU32(peerSettings.backgroundBorderColor or { 0.78, 0.12, 0.10, 0.88 });
    local borderSize = math.max(0, math.min(12, tonumber(peerSettings.backgroundBorderSize) or 0));

    drawList:AddRectFilled({ x, y }, { x + w, y + h }, bg);

    if (borderSize > 0) then
        for i = 0, borderSize - 1 do
            drawList:AddRect({ x + i, y + i }, { x + w - i, y + h - i }, border);
        end
    end
end

local function WrapInspectorText(value, maxChars, maxLines)
    local text = tostring(value or ''):gsub('\r', '');
    local lines = {};
    maxChars = math.max(12, tonumber(maxChars) or 48);
    maxLines = math.max(1, tonumber(maxLines) or 8);

    for paragraph in (text .. '\n'):gmatch('(.-)\n') do
        local line = '';

        for word in paragraph:gmatch('%S+') do
            local candidate = line == '' and word or (line .. ' ' .. word);

            if (#candidate > maxChars and line ~= '') then
                lines[#lines + 1] = line;
                line = word;

                if (#lines >= maxLines) then
                    break;
                end
            else
                line = candidate;
            end
        end

        if (#lines >= maxLines) then
            break;
        end

        if (line ~= '') then
            lines[#lines + 1] = line;
        end

        if (#lines >= maxLines) then
            break;
        end
    end

    if (#lines == maxLines and #text > 0) then
        lines[#lines] = LimitText(lines[#lines], math.max(4, maxChars - 1));
    end

    return lines;
end

local function DrawNpcObjectInspector(hovered, entityName, peerSettings)
    local drawList = imgui.GetForegroundDrawList ~= nil and imgui.GetForegroundDrawList() or imgui.GetWindowDrawList();

    if (drawList == nil) then
        return;
    end

    local mouseX, mouseY = GetMousePos();

    if (mouseX == nil or mouseY == nil) then
        return;
    end

    local displayName = tostring(hovered.name or hovered.rawName or ''):gsub('\170', ''):gsub('%c', '');
    local resolvedEntityName, info = npcObjectInfo.ResolveKind(displayName, entityName, {
        targetIndex = hovered.targetIndex,
    });
    local typeText = tostring(info ~= nil and info.type or resolvedEntityName or entityName);
    local noteLines = WrapInspectorText(info ~= nil and info.note or '', 54, 8);
    local displayW, displayH = GetDisplaySize();
    local w = math.max(320, GetPeerInspectorWidth(peerSettings, 430));
    local h = 64 + (#noteLines * 18);

    if (typeText ~= '') then
        h = h + 26;
    end

    local x = mouseX + 22;
    local y = mouseY + 18;

    if ((x + w) > (displayW - 12)) then
        x = mouseX - w - 22;
    end

    if ((y + h) > (displayH - 12)) then
        y = displayH - h - 12;
    end

    x = math.max(12, x);
    y = math.max(12, y);

    local text = ColorU32(peerSettings.textColor or { 0.94, 0.94, 0.90, 1.0 });
    local outline = ColorU32(peerSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 });
    local outlineSize = tonumber(peerSettings.textOutlineSize) or 0;
    local muted = ColorU32({ 0.68, 0.72, 0.74, 1.0 });
    local heading = ColorU32({ 1.0, 0.84, 0.0, 1.0 });

    DrawPeerPanelBox(drawList, x, y, w, h, peerSettings);

    if (peerSettings.showName ~= false) then
        DrawOutlinedText(drawList, x + 14, y + 10, text, LimitText(displayName, 36), outlineSize + 1, outline);
    end

    if (peerSettings.showDistance ~= false) then
        DrawOutlinedText(
            drawList,
            x + w - 54,
            y + 10,
            muted,
            string.format('%.1f', tonumber(hovered.distance) or 0):gsub(',', '.'),
            outlineSize,
            outline
        );
    end

    local rowY = y + 42;

    if (typeText ~= '') then
        DrawOutlinedText(drawList, x + 14, rowY, heading, 'Type', outlineSize, outline);
        DrawOutlinedText(drawList, x + 86, rowY, text, LimitText(typeText, 42), outlineSize, outline);
        rowY = rowY + 26;
    end

    if (#noteLines > 0) then
        DrawOutlinedText(drawList, x + 14, rowY, heading, 'Notes', outlineSize, outline);
        rowY = rowY + 20;

        for _, line in ipairs(noteLines) do
            DrawOutlinedText(drawList, x + 14, rowY, text, line, outlineSize, outline);
            rowY = rowY + 18;
        end
    end
end

local function DrawEnemyTextInspector(enemy, info, peerSettings)
    local drawList = imgui.GetForegroundDrawList ~= nil and imgui.GetForegroundDrawList() or imgui.GetWindowDrawList();

    if (drawList == nil) then
        return;
    end

    local mouseX, mouseY = GetMousePos();

    if (mouseX == nil or mouseY == nil) then
        return;
    end

    local displayW, displayH = GetDisplaySize();
    local w = math.max(320, GetPeerInspectorWidth(peerSettings, 430));
    local h = GetEnemyPeerTextInspectorHeight(peerSettings);
    local x = mouseX + 22;
    local y = mouseY + 18;

    if ((x + w) > (displayW - 12)) then
        x = mouseX - w - 22;
    end

    if ((y + h) > (displayH - 12)) then
        y = displayH - h - 12;
    end

    x = math.max(12, x);
    y = math.max(12, y);

    local text = ColorU32(peerSettings.textColor or { 0.94, 0.94, 0.90, 1.0 });
    local outline = ColorU32(peerSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 });
    local outlineSize = tonumber(peerSettings.textOutlineSize) or 0;
    local muted = ColorU32({ 0.68, 0.72, 0.74, 1.0 });
    local levelColor = ColorU32(GetPeerLevelColor(peerSettings, info));
    local good = ColorU32({ 0.44, 0.95, 0.70, 1.0 });
    local bad = ColorU32({ 1.0, 0.58, 0.50, 1.0 });
    local heading = ColorU32({ 1.0, 0.84, 0.0, 1.0 });
    local iconStyle = SanitizeIconStyle(peerSettings.iconStyle);
    local behaviorIconSize = math.max(14, math.min(24, tonumber(peerSettings.iconSize) or 18));
    local labelX = x + 14;
    local valueX = x + 118;
    local rowStep = 28;
    local levelText = mobInfoData.GetLevelString(info);
    local jobText = mobInfoData.GetJobString(info);
    local levelJobText = '';
    local displayName = GetEnemyPeerDisplayName(enemy);
    local weakRows, resistRows = SplitModifierRows(info);
    local aggroIcons, detectionIcons, linkIcons = BuildThreatRows(info);
    local immunityIcons = mobInfoData.GetImmunityFlags(info);

    DrawPeerPanelBox(drawList, x, y, w, h, peerSettings);

    if (peerSettings.showLevel ~= false) then
        levelJobText = 'Lv. ' .. (levelText ~= '' and levelText or '?');
    end

    if (peerSettings.showJob ~= false and jobText ~= '') then
        levelJobText = (levelJobText ~= '' and (levelJobText .. ' ') or '') .. jobText;
    end

    if (levelJobText ~= '') then
        DrawOutlinedText(drawList, labelX, y + 10, levelColor, levelJobText, outlineSize, outline);
    end

    if (peerSettings.showName ~= false) then
        DrawOutlinedText(drawList, x + 142, y + 10, text, LimitText(displayName, 24), outlineSize + 1, outline);
    end

    if (peerSettings.showDistance ~= false) then
        DrawOutlinedText(drawList, x + w - 54, y + 10, muted, string.format('%.1f', tonumber(enemy.distance) or 0), outlineSize, outline);
    end

    local rowY = y + 52;
    if (peerSettings.showHpValue ~= false) then
        DrawTextRow(drawList, labelX, valueX, rowY, heading, text, 'HP', FormatHpValue(enemy), outlineSize, outline);
        rowY = rowY + rowStep;
    end

    if (peerSettings.showBehavior ~= false) then
        DrawOutlinedText(drawList, labelX, rowY, heading, 'Behavior', outlineSize, outline);

        local iconCount = DrawIconRow(drawList, valueX, rowY - 2, aggroIcons, iconStyle, behaviorIconSize, 32);
        local behaviorTextX = valueX;

        if (iconCount > 0) then
            behaviorTextX = valueX + behaviorIconSize + 8;
        end

        DrawOutlinedText(drawList, behaviorTextX, rowY, text, IconsToText(aggroIcons, 'Unknown'), outlineSize, outline);
        rowY = rowY + rowStep;
    end
    if (peerSettings.showDetects ~= false) then
        DrawTextRow(drawList, labelX, valueX, rowY, heading, text, 'Detects', IconsToText(detectionIcons, 'None known'), outlineSize, outline);
        rowY = rowY + rowStep;
    end
    if (peerSettings.showLinks ~= false) then
        DrawTextRow(drawList, labelX, valueX, rowY, heading, text, 'Links', #linkIcons > 0 and 'Yes' or 'No', outlineSize, outline);
        rowY = rowY + rowStep + 4;
    end
    if (peerSettings.showWeakTo ~= false) then
        DrawTextRow(drawList, labelX, valueX, rowY, heading, good, 'Weak To', ModifierRowsToText(weakRows, 'None known'), outlineSize, outline);
        rowY = rowY + rowStep;
    end
    if (peerSettings.showResists ~= false) then
        DrawTextRow(drawList, labelX, valueX, rowY, heading, bad, 'Resists', ModifierRowsToText(resistRows, 'None known'), outlineSize, outline);
        rowY = rowY + rowStep;
    end
    if (peerSettings.showImmunities ~= false) then
        DrawTextRow(drawList, labelX, valueX, rowY, heading, muted, 'Immunities', IconsToText(immunityIcons, 'None known'), outlineSize, outline);
    end
end

local function DrawEnemyInspector(enemy, info, peerSettings)
    local drawList = imgui.GetForegroundDrawList ~= nil and imgui.GetForegroundDrawList() or imgui.GetWindowDrawList();

    if (drawList == nil) then
        return;
    end

    local mouseX, mouseY = GetMousePos();

    if (mouseX == nil or mouseY == nil) then
        return;
    end

    local displayW, displayH = GetDisplaySize();
    local w = math.max(320, GetPeerInspectorWidth(peerSettings, 430));
    local h = GetEnemyPeerIconInspectorHeight(peerSettings);
    local x = mouseX + 22;
    local y = mouseY + 18;

    if ((x + w) > (displayW - 12)) then
        x = mouseX - w - 22;
    end

    if ((y + h) > (displayH - 12)) then
        y = displayH - h - 12;
    end

    x = math.max(12, x);
    y = math.max(12, y);

    local text = ColorU32({ 0.94, 0.94, 0.90, 1.0 });
    local muted = ColorU32({ 0.68, 0.72, 0.74, 1.0 });
    local levelColor = ColorU32(GetPeerLevelColor(peerSettings, info));
    local good = ColorU32({ 0.44, 0.95, 0.70, 1.0 });
    local bad = ColorU32({ 1.0, 0.58, 0.50, 1.0 });
    local heading = ColorU32({ 1.0, 0.84, 0.0, 1.0 });
    local iconStyle = SanitizeIconStyle(peerSettings.iconStyle);
    local iconSize = math.max(6, math.min(256, tonumber(peerSettings.iconSize) or 22));
    local labelX = x + 14;
    local contentX = x + 142;
    local contentW = w - 156;
    local levelText = mobInfoData.GetLevelString(info);
    local jobText = mobInfoData.GetJobString(info);
    local levelJobText = '';
    local displayName = GetEnemyPeerDisplayName(enemy);
    local weakRows, resistRows = SplitModifierRows(info);
    local aggroIcons, detectionIcons, linkIcons = BuildThreatRows(info);
    local immunityIcons = mobInfoData.GetImmunityFlags(info);

    DrawPeerPanelBox(drawList, x, y, w, h, peerSettings);

    if (peerSettings.showLevel ~= false) then
        levelJobText = 'Lv. ' .. (levelText ~= '' and levelText or '?');
    end

    if (peerSettings.showJob ~= false and jobText ~= '') then
        levelJobText = (levelJobText ~= '' and (levelJobText .. ' ') or '') .. jobText;
    end

    if (levelJobText ~= '') then
        DrawText(drawList, labelX, y + 10, levelColor, levelJobText);
    end

    if (peerSettings.showName ~= false) then
        DrawText(drawList, x + 142, y + 10, text, displayName);
    end

    if (peerSettings.showDistance ~= false) then
        DrawText(drawList, x + w - 54, y + 10, muted, string.format('%.1f', tonumber(enemy.distance) or 0));
    end

    local rowY = y + 52;
    if (peerSettings.showHpValue ~= false) then
        DrawText(drawList, labelX, rowY, heading, 'HP');
        DrawText(drawList, contentX, rowY, text, FormatHpValue(enemy));
        rowY = rowY + 30;
    end

    if (peerSettings.showBehavior ~= false) then
        DrawText(drawList, labelX, rowY, heading, 'Behavior');
        DrawIconRow(drawList, contentX, rowY - 3, aggroIcons, iconStyle, iconSize, contentW);
        rowY = rowY + 30;
    end

    if (peerSettings.showDetects ~= false) then
        DrawText(drawList, labelX, rowY, heading, 'Detects');
        DrawIconRow(drawList, contentX, rowY - 3, detectionIcons, iconStyle, iconSize, contentW);
        rowY = rowY + 30;
    end

    if (peerSettings.showLinks ~= false) then
        DrawText(drawList, labelX, rowY, heading, 'Links');
        if (#linkIcons > 0) then
            DrawIconRow(drawList, contentX, rowY - 3, linkIcons, iconStyle, iconSize, contentW);
        else
            DrawText(drawList, contentX, rowY, muted, 'No');
        end
        rowY = rowY + 36;
    end

    if (peerSettings.showWeakTo ~= false) then
        DrawText(drawList, labelX, rowY, heading, 'Weak To');
        if (#weakRows > 0) then
            DrawModifierRow(drawList, contentX, rowY - 6, weakRows, iconStyle, iconSize, contentW, good);
        else
            DrawText(drawList, contentX, rowY, muted, 'None known');
        end
        rowY = rowY + 56;
    end

    if (peerSettings.showResists ~= false) then
        DrawText(drawList, labelX, rowY, heading, 'Resists');
        if (#resistRows > 0) then
            DrawModifierRow(drawList, contentX, rowY - 6, resistRows, iconStyle, iconSize, contentW, bad);
        else
            DrawText(drawList, contentX, rowY, muted, 'None known');
        end
        rowY = rowY + 56;
    end

    if (peerSettings.showImmunities ~= false) then
        DrawText(drawList, labelX, rowY, heading, 'Immunities');
        if (#immunityIcons > 0) then
            DrawIconRow(drawList, contentX, rowY - 5, immunityIcons, iconStyle, iconSize, contentW);
        else
            DrawText(drawList, contentX, rowY, muted, 'None known');
        end
    end
end

function peerInspector.Render()
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local peerSettings = globalSettings.peer or {};

    if (peerSettings.enabled == false) then
        return;
    end

    local hovered = worldMarkerProbe.GetHoveredPlate();

    if (hovered == nil or hovered.targetIndex == nil) then
        return;
    end

    local targetType = tostring(hovered.targetType or '');

    if (targetType == 'self') then
        local layoutStateName = tostring(hovered.layoutStateName or 'Idle');
        local selfPeerSettings = state.GetWidgetSettings('Self', layoutStateName, 'Peer', { enabled = true });

        if (PeerWidgetLoads(selfPeerSettings) == true) then
            local activePeerSettings = MergePeerSettings(peerSettings, selfPeerSettings);
            if (IsModifierActive(activePeerSettings) ~= true) then
                return;
            end

            DrawSelfInspector(GetSelfPeerData(), activePeerSettings);
        end

        return;
    end

    if (targetType == 'pc') then
        local layoutStateName = tostring(hovered.layoutStateName or 'Idle');
        local playerPeerSettings = state.GetWidgetSettings('PC', layoutStateName, 'Peer', { enabled = true });

        if (PeerWidgetLoads(playerPeerSettings) == true) then
            local activePeerSettings = MergePeerSettings(peerSettings, playerPeerSettings);
            if (IsModifierActive(activePeerSettings) ~= true) then
                return;
            end

            local player = GetPlayerPeerData(hovered.targetIndex, activePeerSettings);

            if (player ~= nil) then
                DrawPlayerInspector(player, activePeerSettings);
            end
        end

        return;
    end

    if (targetType == 'npc' or targetType == 'object') then
        local entityName = targetType == 'object' and 'Object' or 'NPC';
        local layoutStateName = tostring(hovered.layoutStateName or 'Idle');
        local npcObjectPeerSettings = state.GetWidgetSettings(entityName, layoutStateName, 'Peer', { enabled = true });

        if (PeerWidgetLoads(npcObjectPeerSettings) == true) then
            local activePeerSettings = MergePeerSettings(peerSettings, npcObjectPeerSettings);

            if (IsModifierActive(activePeerSettings) == true) then
                DrawNpcObjectInspector(hovered, entityName, activePeerSettings);
            end
        end

        return;
    end

    if (targetType ~= 'enemy') then
        return;
    end

    local layoutStateName = tostring(hovered.layoutStateName or 'Combat');
    local enemyPeerSettings = state.GetWidgetSettings('Enemy', layoutStateName, 'Peer', { enabled = true });

    if (PeerWidgetLoads(enemyPeerSettings) ~= true) then
        return;
    end

    local enemy = entities.GetEnemy(hovered.targetIndex, true);

    if (enemy == nil) then
        return;
    end

    local info = GetEnemyPeerMobInfo(enemy);

    if (info == nil) then
        return;
    end

    local activePeerSettings = MergePeerSettings(peerSettings, enemyPeerSettings);

    if (IsModifierActive(activePeerSettings) ~= true) then
        return;
    end

    if (
        adaptivePerformance.ShouldThrottleBackground() == true and
        IsModifierActive(activePeerSettings) ~= true
    ) then
        return;
    end

    if ((tonumber(enemy.distance) or 0) > math.max(0.0, math.min(49.9, tonumber(activePeerSettings.maxRange) or 49.9))) then
        return;
    end

    if (tostring(activePeerSettings.displayMode or 'Icons') == 'Text') then
        DrawEnemyTextInspector(enemy, info, activePeerSettings);
        return;
    end

    DrawEnemyInspector(enemy, info, activePeerSettings);
end

pcall(function()
    local ffi = require('ffi');
    ffi.cdef[[
        short __stdcall GetAsyncKeyState(int vKey);
    ]];
    peerInspector.user32 = ffi.load('user32');
end);

return peerInspector;
