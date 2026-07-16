local backgroundDefaults = require('config.widgets.background');
local nameDefaults = require('config.widgets.name');
local barDefaults = require('config.widgets.bar');
local mpBarDefaults = require('config.widgets.mp_bar');
local tpBarDefaults = require('config.widgets.tp_bar');
local jobDefaults = require('config.widgets.job');
local buffsDefaults = require('config.widgets.buffs');
local debuffsDefaults = require('config.widgets.debuffs');
local aoeRangeDefaults = require('config.widgets.aoe_range');
local globalDefaults = require('config.global');
local trustJobs = require('data.trust_jobs');
local globalNpcObjectData = require('data.npc_object_zones.global');
local fonts = require('core.fonts');
local textScale = require('core.text_scale');
local canvasTexture = require('core.canvas_texture');
local barTextures = require('core.bar_textures');
local barAnimations = require('core.bar_animations');
local backgroundTextures = require('core.background_textures');
local statusIconTextures = require('core.status_icon_textures');
local jobIconTextures = require('core.job_icon_textures');
local entities = require('core.entities');
local state = require('core.state');
local trustStatusIcons = require('core.trust_status_icons');
local targetModuleMarker = require('core.target_module_marker');
local targeting = require('core.targeting');
local enmity = require('core.enmity');
local worldDepthPlate = require('core.world_depth_plate');
local worldMarkerProbe = require('core.world_marker_probe');
local aoeNameHighlight = require('core.aoe_name_highlight');
local aoeRangeVisuals = require('core.aoe_range_visuals');
local perfMeter = require('core.perf_meter');
local adaptivePerformance = require('core.adaptive_performance');

local trustPlate = {};
local plateCache = {};
local indexCache = {};
local maxPlateCacheEntries = 32;
local lastPlateCacheTrim = 0;
local wasConfigOpen = false;
local trustBuffDefaults = {};
local nearbyScanCache = {
    clock = 0,
    range = nil,
    trusts = nil,
};
local plateWorkGateCache = {
    clock = 0,
    result = true,
};
local nearbyTrustScanCacheSeconds = 0.20;
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

for key, value in pairs(buffsDefaults) do
    trustBuffDefaults[key] = value;
end

trustBuffDefaults.enabled = true;

local function ColorKey(color)
    color = color or {};

    return table.concat({
        string.format('%.3f', tonumber(color[1]) or 0),
        string.format('%.3f', tonumber(color[2]) or 0),
        string.format('%.3f', tonumber(color[3]) or 0),
        string.format('%.3f', tonumber(color[4]) or 0),
    }, ',');
end

local function BoolKey(value)
    return value == true and '1' or '0';
end

local function ClearPlateCache()
    for _, cached in pairs(plateCache) do
        if (cached ~= nil and cached.textureKey ~= nil) then
            canvasTexture.ReleaseKey(cached.textureKey);
        end
    end

    plateCache = {};
    indexCache = {};
    collectgarbage('step', 64);
end

local function TouchPlateCacheEntry(cached)
    if (cached == nil) then
        return;
    end

    cached.lastUsed = os.clock();

    if (cached.textureKey ~= nil) then
        canvasTexture.TouchKey(cached.textureKey);
    end
end

local function TrimPlateCache()
    local now = os.clock();

    if ((now - lastPlateCacheTrim) < 5.0) then
        return;
    end

    lastPlateCacheTrim = now;

    local entries = {};

    for key, cached in pairs(plateCache) do
        entries[#entries + 1] = {
            key = key,
            lastUsed = tonumber(cached ~= nil and cached.lastUsed) or 0,
            textureKey = cached ~= nil and cached.textureKey or nil,
        };
    end

    if (#entries <= maxPlateCacheEntries) then
        return;
    end

    table.sort(entries, function(left, right)
        return (tonumber(left.lastUsed) or 0) < (tonumber(right.lastUsed) or 0);
    end);

    for i = 1, (#entries - maxPlateCacheEntries) do
        local entry = entries[i];

        plateCache[entry.key] = nil;

        if (entry.textureKey ~= nil) then
            canvasTexture.ReleaseKey(entry.textureKey);
        end

        for index, indexed in pairs(indexCache) do
            if (indexed ~= nil and indexed.cacheKey == entry.key) then
                indexCache[index] = nil;
            end
        end
    end

    collectgarbage('step', 64);
end

local function SettingKey(settings, fields)
    local parts = {};

    settings = settings or {};

    for _, field in ipairs(fields) do
        local value = settings[field];

        if (type(value) == 'table') then
            parts[#parts + 1] = field .. '=' .. ColorKey(value);
        elseif (type(value) == 'boolean') then
            parts[#parts + 1] = field .. '=' .. BoolKey(value);
        else
            parts[#parts + 1] = field .. '=' .. tostring(value);
        end
    end

    return table.concat(parts, ';');
end

local function NumberKey(value)
    local number = tonumber(value);

    if (number == nil) then
        return tostring(value);
    end

    return string.format('%.3f', number);
end

local function CleanTrustName(name)
    return tostring(name or ''):gsub('\170', ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local trustIconAliases = nil;
local trustJobAliases = nil;
local trustEntriesByName = nil;
local trustOffsetNameAliases = {
    aaev = 'arkev',
    aagk = 'arkgk',
    aahm = 'arkhm',
    aamr = 'arkmr',
    aatt = 'arktt',
    arkmk = 'aamr',
    arkangelev = 'aaev',
    arkev = 'aaev',
    arkangelgk = 'aagk',
    arkgk = 'aagk',
    arkangelhm = 'aahm',
    arkhm = 'aahm',
    arkangelmk = 'aamr',
    arkangelmr = 'aamr',
    arkmr = 'aamr',
    arkangeltt = 'aatt',
    arktt = 'aatt',
    dominashantotto = 'dshantotto',
    ferreouscoffi = 'ferreouscoffin',
    ishielduc = 'invincibleshielduc',
    jakohuc = 'jakohwahcondalouc',
    kayeel = 'kayeelpayeel',
    makki = 'makkichebukki',
    najauc = 'najasalaheemuc',
    pieujeuc = 'pieujeuc',
};

local function NormalizeTrustLookupName(name)
    return CleanTrustName(name):lower():gsub('[^%w]', '');
end

local function GetTrustEntriesByName()
    if (trustEntriesByName ~= nil) then
        return trustEntriesByName;
    end

    trustEntriesByName = {};

    local npcs = type(globalNpcObjectData) == 'table' and globalNpcObjectData.npcs or nil;

    if (type(npcs) ~= 'table') then
        return trustEntriesByName;
    end

    for key, entry in pairs(npcs) do
        local trustName = tostring(key or ''):match('^Trust:%s*(.+)$');

        if (trustName ~= nil and trustName ~= '') then
            trustEntriesByName[CleanTrustName(trustName)] = entry;
        end
    end

    return trustEntriesByName;
end

local function GetTrustIconAliases()
    if (trustIconAliases ~= nil) then
        return trustIconAliases;
    end

    trustIconAliases = {};

    for trustName, entry in pairs(GetTrustEntriesByName()) do
        if (trustName ~= nil and trustName ~= '') then
            trustIconAliases[NormalizeTrustLookupName(trustName)] = entry;
            if (type(entry) == 'table') and (type(entry.aliases) == 'table') then
                for _, alias in pairs(entry.aliases) do
                    local normalizedAlias = NormalizeTrustLookupName(alias);
                    if (normalizedAlias ~= '') then
                        trustIconAliases[normalizedAlias] = entry;
                    end
                end
            end
        end
    end

    return trustIconAliases;
end

local function GetTrustJobAliases()
    if (trustJobAliases ~= nil) then
        return trustJobAliases;
    end

    trustJobAliases = {};

    for key, entry in pairs(trustJobs or {}) do
        trustJobAliases[NormalizeTrustLookupName(key)] = entry;
    end

    return trustJobAliases;
end

local function ResolveTrustAliasEntry(aliases, normalizedName)
    if (aliases == nil or normalizedName == nil) then
        return nil;
    end

    local entry = aliases[normalizedName];

    if (entry ~= nil) then
        return entry;
    end

    local aliasName = trustOffsetNameAliases[normalizedName];

    if (aliasName ~= nil) then
        entry = aliases[aliasName];

        if (entry ~= nil) then
            return entry;
        end

        local secondAliasName = trustOffsetNameAliases[aliasName];

        if (secondAliasName ~= nil) then
            return aliases[secondAliasName];
        end
    end

    return nil;
end

local function ResolveTrustIconEntry(name)
    local cleanName = CleanTrustName(name);
    local entry = GetTrustEntriesByName()[cleanName];

    if (entry == nil) then
        local normalizedName = NormalizeTrustLookupName(cleanName);
        local aliases = GetTrustIconAliases();

        entry = ResolveTrustAliasEntry(aliases, normalizedName);
    end

    return entry;
end

local function ResolveTrustPlateWorldOffsetY(name)
    local entry = ResolveTrustIconEntry(name);
    local offsetY = tonumber(entry ~= nil and entry.worldOffsetY);

    return offsetY or 0.50;
end

local function GetJobText(job)
    local jobId = tonumber(job);

    if (jobId == nil) then
        return tostring(job or ''):upper();
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

local function ResolveTrustJobText(name)
    local entry = ResolveTrustIconEntry(name);
    local normalizedName = NormalizeTrustLookupName(name);
    local jobAliases = GetTrustJobAliases();
    local jobEntry = trustJobs[CleanTrustName(name)] or ResolveTrustAliasEntry(jobAliases, normalizedName);

    if (entry == nil and jobEntry == nil) then
        return '';
    end

    return GetJobText((entry ~= nil and (entry.job or entry.mainJob)) or (jobEntry ~= nil and (jobEntry.job or jobEntry.mainJob)));
end

local function AddJobToPlate(plateData, jobText, jobSettings, globalSettings)
    if (jobSettings == nil or jobSettings.enabled ~= true or jobText == nil or tostring(jobText) == '') then
        return;
    end

    if ((tonumber(jobSettings.displayModeIndex) or 1) == 2) then
        local textureId = jobIconTextures.GetTextureId(jobText, jobSettings.iconTheme);

        if (textureId ~= nil) then
            plateData.icons = plateData.icons or {};
            plateData.icons[#plateData.icons + 1] = {
                kind = 'job',
                textureId = textureId,
                size = math.max(8, math.min(256, tonumber(jobSettings.iconSize) or 16)),
                offsetX = tonumber(jobSettings.offsetX) or 0,
                offsetY = tonumber(jobSettings.offsetY) or -54,
                anchorTo = jobSettings.anchorTo or jobDefaults.anchorTo,
                anchorPoint = jobSettings.anchorPoint or jobDefaults.anchorPoint,
            };

            return;
        end
    end

    plateData.jobText = tostring(jobText);
    plateData.jobFontFamily = fonts.GetRole(globalSettings, true);
    plateData.jobFontFlags = fonts.GetRoleFlags(globalSettings, true);
    plateData.jobFontSize = textScale.ToTextureFontSize(jobSettings.textSize, jobDefaults.textSize);
    plateData.jobColor = jobSettings.color or jobDefaults.color;
    plateData.jobOutlineEnabled = (tonumber(jobSettings.outlineSize) or 0) > 0;
    plateData.jobOutlineColor = jobSettings.outlineColor or jobDefaults.outlineColor;
    plateData.jobOutlineSize = tonumber(jobSettings.outlineSize) or jobDefaults.outlineSize;
    plateData.jobOffsetX = tonumber(jobSettings.offsetX) or 0;
    plateData.jobOffsetY = tonumber(jobSettings.offsetY) or -54;
    plateData.jobAnchorTo = jobSettings.anchorTo or jobDefaults.anchorTo;
    plateData.jobAnchorPoint = jobSettings.anchorPoint or jobDefaults.anchorPoint;
end

local function BuildTargetMarkerKey(marker)
    if (marker == nil or marker.enabled ~= true) then
        return 'target=off';
    end

    return table.concat({
        'target=on',
        'bg=' .. BoolKey(marker.showBackground == true),
        'arrow=' .. BoolKey(marker.showArrow == true),
        'chev=' .. BoolKey(marker.showChevrons == true),
        'arrowFile=' .. tostring(marker.arrowFile or ''),
        'arrowAnimated=' .. BoolKey(marker.arrowAnimated == true),
        'arrowAnimationSpeed=' .. NumberKey(marker.arrowAnimationSpeed),
        'chevFile=' .. tostring(marker.chevronFile or ''),
        'bgFile=' .. tostring(marker.backgroundFile or ''),
        'arrowW=' .. NumberKey(marker.arrowWidth),
        'arrowH=' .. NumberKey(marker.arrowHeight),
        'arrowX=' .. NumberKey(marker.arrowOffsetX),
        'arrowY=' .. NumberKey(marker.arrowOffsetY),
        'arrowSpacing=' .. NumberKey(marker.arrowSpacing),
        'chevW=' .. NumberKey(marker.chevronWidth),
        'chevH=' .. NumberKey(marker.chevronHeight),
        'chevX=' .. NumberKey(marker.chevronOffsetX),
        'chevY=' .. NumberKey(marker.chevronOffsetY),
        'chevSpacing=' .. NumberKey(marker.chevronSpacing),
        'bgW=' .. NumberKey(marker.backgroundWidth),
        'bgH=' .. NumberKey(marker.backgroundHeight),
        'bgX=' .. NumberKey(marker.backgroundOffsetX),
        'bgY=' .. NumberKey(marker.backgroundOffsetY),
        'anchorArrow=' .. BoolKey(marker.arrowAnchorToName == true),
        'anchorChev=' .. BoolKey(marker.chevronAnchorToPlate == true),
        'anchorBg=' .. BoolKey(marker.backgroundAnchorToPlate == true),
        'anchorChevKinds=' .. table.concat(marker.chevronAnchorKinds or {}, ','),
        'anchorBgKinds=' .. table.concat(marker.backgroundAnchorKinds or {}, ','),
        'color=' .. ColorKey(marker.color),
        'arrowColor=' .. ColorKey(marker.arrowColor),
        'chevColor=' .. ColorKey(marker.chevronColor),
        'bgColor=' .. ColorKey(marker.backgroundColor),
    }, ';');
end

local function ClampPercent(percent, fallback)
    percent = tonumber(percent) or fallback or 0;

    if (percent < 0) then
        return 0;
    end

    if (percent > 100) then
        return 100;
    end

    return percent;
end

local function ClampTp(value)
    local tp = tonumber(value) or 0;

    if (tp < 0) then
        return 0;
    end

    if (tp > 3000) then
        return 3000;
    end

    return tp;
end

local function ShortenName(name, maxLength)
    local text = tostring(name or '');
    local limit = tonumber(maxLength) or 0;

    if (limit > 0 and string.len(text) > limit) then
        return string.sub(text, 1, limit);
    end

    return text;
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

local function BuildStatusRowsKey(rows)
    if (rows == nil or #rows == 0) then
        return 'none';
    end

    local parts = {};

    for _, row in ipairs(rows) do
        parts[#parts + 1] = tostring(type(row) == 'table' and row.id or row);
    end

    return table.concat(parts, ',');
end

local function AddStatusIconsToPlate(plateData, statusRows, iconSettings, isEngaged, globalSettings, kind)
    if (
        iconSettings == nil or
        iconSettings.enabled ~= true or
        (iconSettings.hideOutOfCombat == true and ((tostring(iconSettings.hideCombatMode or 'Out of combat') == 'Out of combat' and isEngaged ~= true) or (tostring(iconSettings.hideCombatMode or 'Out of combat') == 'In combat' and isEngaged == true))) or
        statusRows == nil or
        #statusRows == 0
    ) then
        return;
    end

    local maxIcons = math.max(1, math.min(32, tonumber(iconSettings.maxIcons) or 12));
    local iconsPerRow = math.max(1, math.min(24, tonumber(iconSettings.iconsPerRow) or 6));
    local iconSize = math.max(6, math.min(256, tonumber(iconSettings.iconSize) or 18));
    local spacing = math.max(0, math.min(24, tonumber(iconSettings.iconSpacing) or 2));
    local rowSpacing = math.max(0, math.min(32, tonumber(iconSettings.rowSpacing) or 2));
    local growLeft = tostring(iconSettings.growthDirection or 'Right') == 'Left';
    local anchored = tostring(iconSettings.anchorTo or 'Plate') ~= 'Plate';
    local rowHeight = iconSize + rowSpacing;
    local baseX = tonumber(iconSettings.offsetX) or 0;
    local baseY = tonumber(iconSettings.offsetY) or 0;
    local total = math.min(maxIcons, #statusRows);

    plateData.icons = plateData.icons or {};

    for i = 1, total do
        local rowData = statusRows[i];
        local statusId = type(rowData) == 'table' and rowData.id or rowData;
        local textureId = statusIconTextures.GetTextureId(statusId, iconSettings.iconPack);

        if (textureId ~= nil) then
            local row = math.floor((i - 1) / iconsPerRow);
            local col = (i - 1) % iconsPerRow;
            local layoutRowCount = math.min(iconsPerRow, total);
            local rowWidth = (layoutRowCount * iconSize) + ((layoutRowCount - 1) * spacing);
            local iconOffsetX = baseX - (rowWidth * 0.5) + (iconSize * 0.5) + (col * (iconSize + spacing));

            if (anchored == true) then
                iconOffsetX = growLeft == true
                    and (baseX - rowWidth + (col * (iconSize + spacing)))
                    or (baseX + (col * (iconSize + spacing)));
            end

            plateData.icons[#plateData.icons + 1] = {
                kind = kind or 'status',
                textureId = textureId,
                size = iconSize,
                offsetX = iconOffsetX,
                offsetY = baseY + (row * rowHeight),
                anchorTo = iconSettings.anchorTo,
                anchorPoint = iconSettings.anchorPoint,
                timerText = nil,
                timerFontFamily = fonts.GetRole(globalSettings, iconSettings.timerUseSmallFont == true),
                timerFontFlags = fonts.GetRoleFlags(globalSettings, iconSettings.timerUseSmallFont == true),
                timerFontSize = textScale.ToTextureFontSize(iconSettings.timerFontSize, 8),
            };
        end
    end
end

local function GetLayoutStateName(trust, targetStateName)
    if (targetStateName == 'Target' or targetStateName == 'Subtarget') then
        return 'Combat';
    end

    if (
        trust ~= nil and
        (trust.slot ~= nil or targetStateName ~= 'Idle') and
        tonumber(trust.status) == 1
    ) then
        return 'Combat';
    end

    return 'Idle';
end

local function ResolveFriendlyAoeRangeSettings()
    return state.GetWidgetSettings('Self', 'Combat', 'AOE range', aoeRangeDefaults);
end

local function QueueCachedTrust(trust, cached, targetStateName, layoutStateName, hpPercent, mpPercent, tpValue, useTargetOverlay)
    if (cached == nil or cached.texture == nil) then
        return false;
    end

    TouchPlateCacheEntry(cached);

    local plateTextureId = canvasTexture.GetTextureId(cached.texture);

    if (plateTextureId == nil) then
        return false;
    end

    local queueTimer = perfMeter.BeginDetail('trust.queue');
    worldMarkerProbe.QueuePlate({
        targetIndex = trust.index,
        serverId = trust.serverId,
        distance = trust.distance,
        hp = hpPercent,
        mp = mpPercent,
        tp = tpValue,
        name = '',
        isSelf = false,
        trustIsMine = trust.slot ~= nil,
        stateName = targetStateName,
        clickTargetType = 'trust',
        worldMarker = targeting.ApplyPlateScalingSettings({
            hpBar = { enabled = false },
            plateTextureId = plateTextureId,
            plateAlwaysOnTop = useTargetOverlay == true,
            plateTacticalOverlayOnly = useTargetOverlay == true,
            plateWorldWidth = cached.plateWorldWidth,
            plateWorldHeight = cached.plateWorldHeight,
            plateWorldOffsetY = cached.plateWorldOffsetY,
            plateDistanceScaleOffsetY = 0.28,
            plateTextureWidth = cached.textureWidth,
            plateTextureHeight = cached.textureHeight,
            plateClickRects = cached.elementRects,
            clickTargetType = 'trust',
            clickName = trust.name,
            layoutStateName = layoutStateName,
        }, 'trust', 0, cached.plateWorldOffsetY),
    });
    perfMeter.EndDetail(queueTimer);

    return true;
end

local function QueueTrust(trust)
    local targetStateName = targeting.GetTargetStateName(trust.index);
    local layoutStateName = GetLayoutStateName(trust, targetStateName);
    local useTargetOverlay = layoutStateName == 'Combat' or targetStateName ~= 'Idle';
    local isProtectedPlate = useTargetOverlay == true;

    local suppressExpensiveWorldWidgets = adaptivePerformance.ShouldDisableExpensiveWorldWidgets(isProtectedPlate);
    local settingsTimer = perfMeter.BeginDetail('trust.settings');
    local nameSettings = state.GetWidgetSettings('Trust', layoutStateName, 'Name', nameDefaults);
    local backgroundSettings = state.GetWidgetSettings('Trust', layoutStateName, 'Background', backgroundDefaults);
    local hpBarSettings = state.GetWidgetSettings('Trust', layoutStateName, 'HP Bar', barDefaults);
    local mpBarSettings = state.GetWidgetSettings('Trust', layoutStateName, 'MP Bar', mpBarDefaults);
    local tpBarSettings = state.GetWidgetSettings('Trust', layoutStateName, 'TP Bar', tpBarDefaults);
    local jobSettings = state.GetWidgetSettings('Trust', layoutStateName, 'Job', jobDefaults);
    local buffsSettings = state.GetWidgetSettings('Trust', layoutStateName, 'Buffs', trustBuffDefaults);
    local debuffsSettings = state.GetWidgetSettings('Trust', layoutStateName, 'Debuffs', debuffsDefaults);
    local aoeRangeSettings = ResolveFriendlyAoeRangeSettings();
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local hpPercent = ClampPercent(trust.hpPercent, 100);
    local mpPercent = ClampPercent(trust.mpPercent, 100);
    local tpValue = tonumber(trust.tp) or 0;
    local tpPercent = ClampTp(tpValue) / 10;
    local hpColor = hpBarSettings.color or { 0.90, 0.20, 0.20, 1.0 };
    local mpColor = mpBarSettings.color or { 0.20, 0.45, 0.95, 1.0 };

    if (
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25)
    ) then
        hpColor = hpBarSettings.lowColor or hpColor;
    end

    local hpLowActive =
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25);

    if (
        mpBarSettings.lowColorEnabled == true and
        mpPercent <= (tonumber(mpBarSettings.lowColorPercent) or 25)
    ) then
        mpColor = mpBarSettings.lowColor or mpColor;
    end

    local mpLowActive =
        mpBarSettings.lowColorEnabled == true and
        mpPercent <= (tonumber(mpBarSettings.lowColorPercent) or 25);
    local targetMarker = targetModuleMarker.Build('Trust', layoutStateName, targetStateName, hpBarSettings, trust.distance);
    local enmityEnabled = enmity.ShouldDrawAlly(trust, globalSettings) == true;
    local buffRows = suppressExpensiveWorldWidgets ~= true and trustStatusIcons.GetRows(trust.serverId, 'buff') or {};
    local debuffRows = suppressExpensiveWorldWidgets ~= true and trustStatusIcons.GetRows(trust.serverId, 'debuff') or {};
    local plateWorldOffsetY = ResolveTrustPlateWorldOffsetY(trust.name);
    local jobText = ResolveTrustJobText(trust.name);
    local jobLoads = layoutStateName == 'Combat' and suppressExpensiveWorldWidgets ~= true and jobSettings.enabled == true and jobText ~= '';
    local cacheEligible = state.GetConfigOpen() ~= true;
    local cacheKey = nil;
    local signature = nil;

    if (cacheEligible == true) then
        cacheKey = 'trust:' .. tostring(trust.index);
        signature = table.concat({
            'v=1',
            'policy=' .. canvasTexture.GetRenderPolicyKey(),
            'statusIconPack=' .. tostring(globalSettings ~= nil and globalSettings.statusIcons ~= nil and globalSettings.statusIcons.iconPack or ''),
            'name=' .. tostring(trust.name or ''),
            'layout=' .. tostring(layoutStateName or ''),
            'status=' .. tostring(trust.status or ''),
            'target=' .. tostring(targetStateName or ''),
            'plateWorldOffsetY=' .. NumberKey(plateWorldOffsetY),
            'jobText=' .. tostring(jobText or ''),
            'hp=' .. tostring(hpPercent),
            'mp=' .. tostring(mpPercent),
            'tp=' .. tostring(tpValue),
            'enmity=' .. BoolKey(enmityEnabled),
            'aoe=' .. (aoeRangeSettings.enabled == true and aoeNameHighlight.GetSignature(trust.index, 'trust') or 'aoe-name:0'),
            'aoeSettings=' .. SettingKey(aoeRangeSettings, { 'enabled', 'fontSize', 'fontColor', 'highlightFile', 'highlightClickable', 'highlightAutoPlace', 'highlightAutoPlaceBy', 'highlightSpacing', 'highlightOffsetX', 'highlightOffsetY', 'highlightWidth', 'highlightHeight', 'highlightColor', 'highlightOpacity', 'iconEnabled', 'iconFile', 'iconSize', 'iconOffsetX', 'iconOffsetY' }),
            'bg:' .. SettingKey(backgroundSettings, { 'enabled', 'width', 'height', 'offsetX', 'offsetY', 'texture', 'imageOpacity', 'color', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint' }),
            'name:' .. SettingKey(nameSettings, { 'enabled', 'shortenName', 'textSize', 'color', 'outlineSize', 'outlineColor', 'offsetX', 'offsetY', 'anchorTo', 'anchorPoint' }),
            'job:' .. SettingKey(jobSettings, { 'enabled', 'displayModeIndex', 'iconTheme', 'iconSize', 'textSize', 'color', 'outlineEnabled', 'outlineColor', 'outlineSize', 'offsetX', 'offsetY', 'anchorTo', 'anchorPoint' }),
            'hp:' .. SettingKey(hpBarSettings, { 'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color', 'backgroundColor', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint', 'texture', 'textureStrength', 'showValue', 'showPercent', 'fontSize', 'textColor', 'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize', 'lowColorEnabled', 'lowColorPercent', 'lowColor', 'lowAnimationEnabled', 'lowAnimation', 'lowAnimationSpeed', 'lowAnimationColor' }),
            'mp:' .. SettingKey(mpBarSettings, { 'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color', 'backgroundColor', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint', 'texture', 'textureStrength', 'showValue', 'showPercent', 'fontSize', 'textColor', 'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize', 'lowColorEnabled', 'lowColorPercent', 'lowColor', 'lowAnimationEnabled', 'lowAnimation', 'lowAnimationSpeed', 'lowAnimationColor' }),
            'tp:' .. SettingKey(tpBarSettings, { 'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color', 'color2', 'color3', 'backgroundColor', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint', 'texture', 'textureStrength', 'showValue', 'showPercent', 'fontSize', 'textColor', 'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize', 'segmented', 'segmentGap' }),
            'buffs:' .. SettingKey(buffsSettings, { 'enabled', 'iconPack', 'iconSize', 'offsetX', 'offsetY', 'iconSpacing', 'rowSpacing', 'iconsPerRow', 'maxIcons', 'hideOutOfCombat', 'hideCombatMode', 'anchorTo', 'anchorPoint', 'growthDirection' }) .. ':' .. BuildStatusRowsKey(buffRows),
            'debuffs:' .. SettingKey(debuffsSettings, { 'enabled', 'iconPack', 'iconSize', 'offsetX', 'offsetY', 'iconSpacing', 'rowSpacing', 'iconsPerRow', 'maxIcons', 'hideOutOfCombat', 'hideCombatMode', 'anchorTo', 'anchorPoint', 'growthDirection' }) .. ':' .. BuildStatusRowsKey(debuffRows),
            'targetMarker:' .. BuildTargetMarkerKey(targetMarker),
        }, '\n');

        local indexed = indexCache[tonumber(trust.index) or 0];
        local cached = indexed ~= nil and indexed.signature == signature and plateCache[indexed.cacheKey] or nil;

        if (QueueCachedTrust(trust, cached, targetStateName, layoutStateName, hpPercent, mpPercent, tpValue, useTargetOverlay) == true) then
            perfMeter.Count('trust.cache.hit', 1);
            perfMeter.EndDetail(settingsTimer);
            return;
        end

        perfMeter.Count('trust.cache.miss', 1);
    end
    perfMeter.EndDetail(settingsTimer);

    local buildTimer = perfMeter.BeginDetail('trust.build');
    local nameAoeActive = aoeRangeSettings.enabled == true and aoeNameHighlight.IsHighlighted(trust.index, 'trust') == true;
    local nameTextSize = nameAoeActive == true and math.max(tonumber(nameSettings.textSize) or nameDefaults.textSize, tonumber(aoeRangeSettings.fontSize) or aoeRangeDefaults.fontSize) or nameSettings.textSize;
    local plateData = {
        hp = hpPercent,
        mp = mpPercent,
        tp = tpPercent,
        targetMarker = targetMarker,
        aoeNameActive = nameAoeActive == true,
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
        name = (nameSettings.enabled == true) and ShortenName(trust.name, nameSettings.shortenName) or '',
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(nameTextSize, nameDefaults.textSize),
        nameColor = (nameAoeActive == true and aoeRangeSettings.fontColor) or nameSettings.color or { 1.0, 1.0, 1.0, 1.0 },
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = nameSettings.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = tonumber(nameSettings.offsetX) or 0,
        nameOffsetY = tonumber(nameSettings.offsetY) or -54,
        nameAnchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
        hpBar = {
            enabled = hpBarSettings.enabled == true,
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
            texture = hpBarSettings.texture or 'Solid',
            textureStrength = tonumber(hpBarSettings.textureStrength) or 100,
            textureId = barTextures.GetTextureId(hpBarSettings.texture),
            animationEnabled = hpLowActive == true and hpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(hpBarSettings.lowAnimation),
            animationSpeed = tonumber(hpBarSettings.lowAnimationSpeed) or 40,
            animationColor = hpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(hpBarSettings.showAtPercent) or 100,
            text = BuildResourceText(hpBarSettings, 'HP', trust.hp, trust.maxHp, hpPercent),
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
            enabled = mpBarSettings.enabled == true,
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
            texture = mpBarSettings.texture or 'Solid',
            textureStrength = tonumber(mpBarSettings.textureStrength) or 100,
            textureId = barTextures.GetTextureId(mpBarSettings.texture),
            animationEnabled = mpLowActive == true and mpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(mpBarSettings.lowAnimation),
            animationSpeed = tonumber(mpBarSettings.lowAnimationSpeed) or 40,
            animationColor = mpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(mpBarSettings.showAtPercent) or 100,
            text = BuildResourceText(mpBarSettings, 'MP', trust.mp, trust.maxMp, mpPercent),
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
            enabled = tpBarSettings.enabled == true,
            width = tonumber(tpBarSettings.width) or 180,
            height = tonumber(tpBarSettings.height) or 6,
            offsetX = tonumber(tpBarSettings.offsetX) or 0,
            offsetY = tonumber(tpBarSettings.offsetY) or 28,
            color = tpBarSettings.color or { 0.95, 0.55, 0.05, 1.0 },
            backgroundColor = tpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = tpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(tpBarSettings.borderSize) or 0,
            anchorTo = tpBarSettings.anchorTo or tpBarDefaults.anchorTo,
            anchorPoint = tpBarSettings.anchorPoint or tpBarDefaults.anchorPoint,
            texture = tpBarSettings.texture or 'Solid',
            textureStrength = tonumber(tpBarSettings.textureStrength) or 100,
            textureId = barTextures.GetTextureId(tpBarSettings.texture),
            color2 = tpBarSettings.color2 or tpBarDefaults.color2,
            color3 = tpBarSettings.color3 or tpBarDefaults.color3,
            showAtPercent = tonumber(tpBarSettings.showAtPercent) or 100,
            segmented = tpBarSettings.segmented ~= false,
            segmentGap = tonumber(tpBarSettings.segmentGap) or 3,
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

    if (enmityEnabled == true) then
        enmity.AddIcon(plateData, globalSettings.enmity, 'ally');
    end

    if (suppressExpensiveWorldWidgets ~= true) then
        AddStatusIconsToPlate(plateData, buffRows, buffsSettings, layoutStateName == 'Combat', globalSettings, 'buffs');
        AddStatusIconsToPlate(plateData, debuffRows, debuffsSettings, layoutStateName == 'Combat', globalSettings, 'debuffs');
    end
    if (plateData.aoeNameActive == true) then
        aoeRangeVisuals.Apply(plateData, aoeRangeSettings, hpBarSettings);
    end
    if (jobLoads == true) then
        AddJobToPlate(plateData, jobText, jobSettings, globalSettings);
    end
    perfMeter.EndDetail(buildTimer);

    local canvasTimer = perfMeter.BeginDetail('trust.canvas');
    local textureKey = 'trust-' .. tostring(trust.index) .. (plateData.canvasWidth ~= nil and '-aoe' or '');
    local plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, textureKey);
    local plateTextureId = canvasTexture.GetTextureId(plateTexture);
    perfMeter.EndDetail(canvasTimer);

    if (plateTextureId == nil) then
        indexCache[tonumber(trust.index) or 0] = nil;
        return;
    end

    local plateClickRects = plateData._elementRects or canvasTexture.GetElementRects(plateData);
    local plateWorldWidth, plateWorldHeight = canvasTexture.GetWorldSize(2.35, 1.18, textureWidth, textureHeight);

    if (cacheEligible == true and cacheKey ~= nil and signature ~= nil) then
        plateCache[cacheKey] = {
            signature = signature,
            texture = plateTexture,
            textureKey = textureKey,
            lastUsed = os.clock(),
            textureWidth = textureWidth,
            textureHeight = textureHeight,
            elementRects = plateClickRects,
            plateWorldWidth = plateWorldWidth,
            plateWorldHeight = plateWorldHeight,
            plateWorldOffsetY = plateWorldOffsetY,
        };
        indexCache[tonumber(trust.index) or 0] = {
            cacheKey = cacheKey,
            signature = signature,
        };
    end

    local queueTimer = perfMeter.BeginDetail('trust.queue');
    worldMarkerProbe.QueuePlate({
        targetIndex = trust.index,
        serverId = trust.serverId,
        distance = trust.distance,
        hp = hpPercent,
        mp = mpPercent,
        tp = tpValue,
        name = '',
        isSelf = false,
        trustIsMine = trust.slot ~= nil,
        stateName = targetStateName,
        clickTargetType = 'trust',
        worldMarker = targeting.ApplyPlateScalingSettings({
            hpBar = { enabled = false },
            plateTextureId = plateTextureId,
            plateAlwaysOnTop = useTargetOverlay == true,
            plateTacticalOverlayOnly = useTargetOverlay == true,
            plateWorldWidth = plateWorldWidth,
            plateWorldHeight = plateWorldHeight,
            plateWorldOffsetY = plateWorldOffsetY,
            plateDistanceScaleOffsetY = 0.28,
            plateTextureWidth = textureWidth,
            plateTextureHeight = textureHeight,
            plateClickRects = plateClickRects,
            clickTargetType = 'trust',
            clickName = trust.name,
            layoutStateName = layoutStateName,
        }, 'trust', 0, plateWorldOffsetY),
    });
    perfMeter.EndDetail(queueTimer);
end

function trustPlate.Build()
    return nil;
end

local function TrustWidgetEnabled(layoutStateName, widgetName, defaults)
    local settings = state.GetWidgetSettings('Trust', layoutStateName, widgetName, defaults);
    return settings ~= nil and settings.enabled == true;
end

local function AnyTrustWidgetCanLoadForState(layoutStateName)
    return
        TrustWidgetEnabled(layoutStateName, 'Background', backgroundDefaults) == true or
        TrustWidgetEnabled(layoutStateName, 'Name', nameDefaults) == true or
        (layoutStateName == 'Combat' and TrustWidgetEnabled(layoutStateName, 'Job', jobDefaults) == true) or
        TrustWidgetEnabled(layoutStateName, 'HP Bar', barDefaults) == true or
        TrustWidgetEnabled(layoutStateName, 'MP Bar', mpBarDefaults) == true or
        TrustWidgetEnabled(layoutStateName, 'TP Bar', tpBarDefaults) == true or
        TrustWidgetEnabled(layoutStateName, 'Buffs', trustBuffDefaults) == true or
        TrustWidgetEnabled(layoutStateName, 'Debuffs', debuffsDefaults) == true;
end

local function AnyTrustPlateWorkCanLoad()
    local now = os.clock();

    if ((now - (tonumber(plateWorkGateCache.clock) or 0)) < 0.50) then
        return plateWorkGateCache.result == true;
    end

    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local enmitySettings = globalSettings ~= nil and globalSettings.enmity or nil;
    local targetSettings = targetModuleMarker.GetSettings('Trust', 'Combat', 'Target');
    local subtargetSettings = targetModuleMarker.GetSettings('Trust', 'Combat', 'Subtarget');
    local result =
        AnyTrustWidgetCanLoadForState('Idle') == true or
        AnyTrustWidgetCanLoadForState('Combat') == true or
        TrustWidgetEnabled('Combat', 'AOE range', aoeRangeDefaults) == true or
        targetModuleMarker.HasDrawableSettings('Trust', targetSettings) == true or
        targetModuleMarker.HasDrawableSettings('Trust', subtargetSettings) == true or
        (enmitySettings ~= nil and enmitySettings.enabled == true);

    plateWorkGateCache.clock = now;
    plateWorkGateCache.result = result == true;

    return result == true;
end

function trustPlate.Render()
    if (state.GetWorldEnabled() ~= true) then
        return;
    end

    local configOpen = state.GetConfigOpen() == true;

    if (configOpen == true and wasConfigOpen ~= true) then
        ClearPlateCache();
    end
    wasConfigOpen = configOpen;

    TrimPlateCache();

    if (worldDepthPlate.IsEnabled() == true) then
        return;
    end

    if (worldMarkerProbe.GetEnabled() ~= true or worldMarkerProbe.GetReplacePlates() ~= true) then
        return;
    end

    if (AnyTrustPlateWorkCanLoad() ~= true) then
        nearbyScanCache.trusts = nil;
        return;
    end

    local range = targeting.GetWorldPlateRange();
    local now = os.clock();
    local nearbyTrusts = nil;
    local scanTimer = perfMeter.BeginDetail('trust.scan');
    local trusts = entities.GetPartyTrusts(range);

    if (
        nearbyScanCache.trusts ~= nil and
        nearbyScanCache.range == range and
        (now - (tonumber(nearbyScanCache.clock) or 0)) < nearbyTrustScanCacheSeconds
    ) then
        nearbyTrusts = nearbyScanCache.trusts;
    else
        nearbyTrusts = entities.GetNearbyTrusts(range);
        nearbyScanCache.clock = now;
        nearbyScanCache.range = range;
        nearbyScanCache.trusts = nearbyTrusts;
    end

    perfMeter.EndDetail(scanTimer);
    local queued = {};
    local queuedCount = 0;

    for _, trust in ipairs(trusts) do
        queued[tonumber(trust.index) or 0] = true;
        queuedCount = queuedCount + 1;
        QueueTrust(trust);
    end

    for _, trust in ipairs(nearbyTrusts) do
        if (queued[tonumber(trust.index) or 0] ~= true) then
            queued[tonumber(trust.index) or 0] = true;
            queuedCount = queuedCount + 1;
            QueueTrust(trust);
        end
    end

    perfMeter.SetCounter('trustQueued', queuedCount);
end

return trustPlate;
