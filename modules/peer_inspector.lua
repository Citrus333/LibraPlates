local peerInspector = {};

local imgui = require('imgui');
local bit = require('bit');
local textureLoader = require('core.texture_loader');
local worldMarkerProbe = require('core.world_marker_probe');
local entities = require('core.entities');
local mobInfoData = require('core.mobinfo_data');
local adaptivePerformance = require('core.adaptive_performance');
local gameMode = require('core.game_mode');
local playerIndicators = require('core.player_indicators');
local state = require('core.state');
local globalDefaults = require('config.global');

local iconCache = {};
local selfElementIconCache = {};
local enemyInfoCache = {
    key = nil,
    info = nil,
    updated = 0,
};

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
    local w = 292;
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
    local w = 330;
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
    local w = 430;
    local h = 292;
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
    local blue = ColorU32({ 0.40, 0.70, 1.0, 1.0 });
    local good = ColorU32({ 0.44, 0.95, 0.70, 1.0 });
    local bad = ColorU32({ 1.0, 0.58, 0.50, 1.0 });
    local heading = ColorU32({ 1.0, 0.84, 0.0, 1.0 });
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
        DrawOutlinedText(drawList, labelX, y + 10, blue, levelJobText, outlineSize, outline);
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
        DrawTextRow(drawList, labelX, valueX, rowY, heading, text, 'Behavior', IconsToText(aggroIcons, 'Unknown'), outlineSize, outline);
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
    local w = 430;
    local h = 292;
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
    local blue = ColorU32({ 0.40, 0.70, 1.0, 1.0 });
    local good = ColorU32({ 0.44, 0.95, 0.70, 1.0 });
    local bad = ColorU32({ 1.0, 0.58, 0.50, 1.0 });
    local heading = ColorU32({ 1.0, 0.84, 0.0, 1.0 });
    local iconStyle = SanitizeIconStyle(peerSettings.iconStyle);
    local iconSize = math.max(18, math.min(30, tonumber(peerSettings.iconSize) or 22));
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
        DrawText(drawList, labelX, y + 10, blue, levelJobText);
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

    if (IsModifierActive(peerSettings) ~= true) then
        return;
    end

    local hoveredSelf = worldMarkerProbe.GetHoveredPlate('self');

    if (hoveredSelf ~= nil) then
        local layoutStateName = tostring(hoveredSelf.layoutStateName or 'Idle');
        local selfPeerSettings = state.GetWidgetSettings('Self', layoutStateName, 'Peer', { enabled = true });

        if (selfPeerSettings ~= nil and selfPeerSettings.enabled == true) then
            DrawSelfInspector(GetSelfPeerData(), peerSettings);
            return;
        end
    end

    local hoveredPlayer = worldMarkerProbe.GetHoveredPlate('pc');

    if (hoveredPlayer ~= nil and hoveredPlayer.targetIndex ~= nil) then
        local layoutStateName = tostring(hoveredPlayer.layoutStateName or 'Idle');
        local playerPeerSettings = state.GetWidgetSettings('PC', layoutStateName, 'Peer', { enabled = true });

        if (playerPeerSettings ~= nil and playerPeerSettings.enabled == true) then
            local player = GetPlayerPeerData(hoveredPlayer.targetIndex, peerSettings);

            if (player ~= nil) then
                DrawPlayerInspector(player, peerSettings);
                return;
            end
        end
    end

    local hovered = worldMarkerProbe.GetHoveredPlate('enemy');

    if (hovered == nil or hovered.targetIndex == nil) then
        return;
    end

    if (
        adaptivePerformance.ShouldThrottleBackground() == true and
        IsModifierActive(peerSettings) ~= true
    ) then
        return;
    end

    local enemy = entities.GetEnemy(hovered.targetIndex, true);

    if (enemy == nil) then
        return;
    end

    if ((tonumber(enemy.distance) or 0) > math.max(0.0, math.min(49.9, tonumber(peerSettings.maxRange) or 49.9))) then
        return;
    end

    local info = GetEnemyPeerMobInfo(enemy);

    if (info == nil) then
        return;
    end

    if (tostring(peerSettings.displayMode or 'Icons') == 'Text') then
        DrawEnemyTextInspector(enemy, info, peerSettings);
        return;
    end

    DrawEnemyInspector(enemy, info, peerSettings);
end

pcall(function()
    local ffi = require('ffi');
    ffi.cdef[[
        short __stdcall GetAsyncKeyState(int vKey);
    ]];
    peerInspector.user32 = ffi.load('user32');
end);

return peerInspector;
