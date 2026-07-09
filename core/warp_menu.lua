local imgui = require('imgui');
local state = require('core.state');
local globalDefaults = require('config.global');
local textureLoader = require('core.texture_loader');
local log = require('core.log');
local homePoints = require('data.warp.home_points');
local survivalGuides = require('data.warp.survival_guides');
local unityData = require('data.warp.unity');
local outpostData = require('data.warp.outpost_teleporters');
local campaignData = require('data.warp.campaign_arbiters');
local expGuideData = require('data.warp.exp_guides');
local fieldManualData = require('data.warp.field_manual');
local domenicData = require('data.warp.domenic');
local gameMode = require('core.game_mode');
local homePointWarp = require('core.home_point_warp');
local survivalGuideTeleport = require('core.survival_guide_teleport');
local unityTeleport = require('core.unity_teleport');
local outpostTeleport = require('core.outpost_teleport');
local campaignTeleport = require('core.campaign_teleport');
local expGuideTeleport = require('core.exp_guide_teleport');
local fieldManualSupport = require('core.field_manual_support');
local domenicTeleport = require('core.domenic_teleport');

local warpMenu = {};
local iconCache = {};
local missingIcon = {};
local warpIndexes = nil;
local campaignCaptureUntil = 0;
local expGuideCaptureUntil = 0;

local function FormatPacketString(data, maxBytes)
    if (type(data) ~= 'string') then
        return '';
    end

    local output = {};
    local count = math.min(#data, math.max(1, tonumber(maxBytes) or 48));

    for index = 1, count do
        output[#output + 1] = string.format('%02X', string.byte(data, index));
    end

    if (#data > count) then
        output[#output + 1] = '...';
    end

    return table.concat(output, ' ');
end

local function PacketPrintableText(data)
    if (type(data) ~= 'string') then
        return '';
    end

    local output = {};
    for index = 1, #data do
        local byte = string.byte(data, index);
        if (byte ~= nil and byte >= 32 and byte <= 126) then
            output[#output + 1] = string.char(byte);
        else
            output[#output + 1] = ' ';
        end
    end

    return table.concat(output):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '');
end

local function SplitCustomMenuIncoming(data)
    if (type(data) ~= 'string') then
        return nil;
    end

    local markerStart, markerEnd = data:find('_CUSTOM_MENU', 1, true);
    if (markerStart == nil) then
        return nil;
    end

    local strings = {};
    local current = {};
    for index = markerEnd + 1, #data do
        local byte = string.byte(data, index);
        if (byte ~= nil and byte >= 32 and byte <= 126) then
            current[#current + 1] = string.char(byte);
        else
            if (#current > 0) then
                local text = table.concat(current):gsub('^%s+', ''):gsub('%s+$', '');
                if (text ~= '') then
                    strings[#strings + 1] = text;
                end
                current = {};
            end
        end
    end

    if (#current > 0) then
        local text = table.concat(current):gsub('^%s+', ''):gsub('%s+$', '');
        if (text ~= '') then
            strings[#strings + 1] = text;
        end
    end

    if (#strings <= 0) then
        return nil;
    end

    local question = strings[1];
    local options = {};
    for index = 2, #strings do
        options[#options + 1] = strings[index];
    end

    return 'question="' .. tostring(question) .. '" options="' .. table.concat(options, '" | "') .. '"';
end

local function SplitCustomMenuOutgoing(data)
    local text = PacketPrintableText(data);
    local question, result = text:match('Question%((.-)%)%: Result %((.*)%)');
    if (question ~= nil and result ~= nil) then
        return 'question="' .. tostring(question) .. '" result="' .. tostring(result) .. '"';
    end

    return nil;
end

local function ReadU16LE(data, offset)
    local a = string.byte(data or '', offset + 1) or 0;
    local b = string.byte(data or '', offset + 2) or 0;

    return a + (b * 0x100);
end

local function PacketHasCampaignEvent(data)
    if (type(data) ~= 'string') then
        return false;
    end

    for offset = 4, math.max(4, #data - 1) do
        local value = ReadU16LE(data, offset);
        if (value == 453) then
            return true;
        end

        for _, eventId in pairs(campaignData.eventIds or {}) do
            if (value == tonumber(eventId)) then
                return true;
            end
        end
    end

    return false;
end

local function CampaignCaptureActive()
    if (campaignCaptureUntil <= 0) then
        return false;
    end

    if (os.clock() > campaignCaptureUntil) then
        campaignCaptureUntil = 0;
        log.Info('Campaign Arbiter packet capture ended.');
        return false;
    end

    return true;
end

local function ExpGuideCaptureActive()
    if (expGuideCaptureUntil <= 0) then
        return false;
    end

    if (os.clock() > expGuideCaptureUntil) then
        expGuideCaptureUntil = 0;
        log.Info('EXP Guide packet capture ended.');
        return false;
    end

    return true;
end

local noteLabels = {
    E = 'Entrance',
    A = 'Auction',
    M = 'Mog',
};

local zoneIdToZoneName = {
    [5] = 'Uleguerand Range',
    [7] = 'Attohwa Chasm',
    [9] = "Pso'Xja",
    [12] = 'Newton Movalpolos',
    [25] = 'Misareaux Coast',
    [26] = 'Tavnazian Safehold',
    [29] = 'Riverne - Site #B01',
    [30] = 'Riverne - Site #A01',
    [33] = "Al'Taieu",
    [34] = "Grand Palace of Hu'Xzoi",
    [35] = "Garden of Ru'Hmet",
    [50] = 'Aht Urhgan Whitegate',
    [52] = 'Bhaflau Thickets',
    [53] = 'Nashmau',
    [61] = 'Mount Zhayolm',
    [79] = 'Caedarva Mire',
    [80] = "Southern San d'Oria [S]",
    [87] = 'Bastok Markets [S]',
    [94] = 'Windurst Waters [S]',
    [113] = 'Cape Teriggan',
    [126] = 'Qufim Island',
    [130] = "Ru'Aun Gardens",
    [137] = 'Xarcabard [S]',
    [142] = 'Yughott Grotto',
    [143] = 'Palborough Mines',
    [145] = 'Giddeus',
    [153] = 'The Boyahda Tree',
    [155] = 'Castle Zvahl Keep [S]',
    [158] = "Upper Delkfutt's Tower",
    [160] = 'Den of Rancor',
    [162] = 'Castle Zvahl Keep',
    [169] = 'Toraimarai Canal',
    [178] = "The Shrine of Ru'Avitau",
    [204] = "Fei'Yin",
    [205] = "Ifrit's Cauldron",
    [208] = 'Quicksand Caves',
    [230] = "Southern San d'Oria",
    [231] = "Northern San d'Oria",
    [232] = "Port San d'Oria",
    [234] = 'Bastok Mines',
    [235] = 'Bastok Markets',
    [236] = 'Port Bastok',
    [237] = 'Metalworks',
    [238] = 'Windurst Waters',
    [239] = 'Windurst Walls',
    [240] = 'Port Windurst',
    [241] = 'Windurst Woods',
    [243] = "Ru'Lude Gardens",
    [244] = 'Upper Jeuno',
    [245] = 'Lower Jeuno',
    [246] = 'Port Jeuno',
    [247] = 'Rabao',
    [248] = 'Selbina',
    [249] = 'Mhaura',
    [250] = 'Kazham',
    [252] = 'Norg',
    [256] = 'Western Adoulin',
    [257] = 'Eastern Adoulin',
    [261] = 'Ceizak Battlegrounds',
    [262] = 'Foret de Hennetiel',
    [263] = 'Yorcia Weald',
    [265] = 'Morimar Basalt Fields',
    [266] = 'Marjami Ravine',
    [267] = 'Kamihr Drifts',
    [276] = "Ra'Kaznar Inner Court",
    [281] = 'Leafallia',
};

local expansionOrder = {
    'Original Areas',
    'Rise of the Zilart',
    'Chains of Promathia',
    'Treasures of Aht Urhgan',
    'Wings of the Goddess',
    'Seekers of Adoulin',
    'Other',
};

warpIndexes = {
    ["Southern San d'Oria"] = { [1] = 0, [2] = 1, [3] = 2, [4] = 97 },
    ["Northern San d'Oria"] = { [1] = 3, [2] = 4, [3] = 5, [4] = 98 },
    ["Port San d'Oria"] = { [1] = 6, [2] = 7, [3] = 8 },
    ['Bastok Mines'] = { [1] = 9, [2] = 10, [3] = 99 },
    ['Bastok Markets'] = { [1] = 11, [2] = 12, [3] = 13, [4] = 100 },
    ['Port Bastok'] = { [1] = 14, [2] = 15, [3] = 101 },
    ['Metalworks'] = { [1] = 16, [2] = 102 },
    ['Windurst Waters'] = { [1] = 17, [2] = 18, [3] = 103, [4] = 118 },
    ['Windurst Walls'] = { [1] = 19, [2] = 20, [3] = 21 },
    ['Port Windurst'] = { [1] = 22, [2] = 23, [3] = 24 },
    ['Windurst Woods'] = { [1] = 25, [2] = 26, [3] = 27, [4] = 28, [5] = 119 },
    ["Ru'Lude Gardens"] = { [1] = 29, [2] = 30, [3] = 31 },
    ['Upper Jeuno'] = { [1] = 32, [2] = 33, [3] = 34 },
    ['Lower Jeuno'] = { [1] = 35, [2] = 36 },
    ['Port Jeuno'] = { [1] = 37, [2] = 38 },
    ['Kazham'] = { [1] = 39 },
    ['Mhaura'] = { [1] = 40 },
    ['Norg'] = { [1] = 41, [2] = 104 },
    ['Rabao'] = { [1] = 42, [2] = 105 },
    ['Selbina'] = { [1] = 43 },
    ['Western Adoulin'] = { [1] = 44, [2] = 109 },
    ['Eastern Adoulin'] = { [1] = 45, [2] = 110 },
    ['Ceizak Battlegrounds'] = { [1] = 46 },
    ['Foret de Hennetiel'] = { [1] = 47 },
    ['Morimar Basalt Fields'] = { [1] = 48 },
    ['Yorcia Weald'] = { [1] = 49 },
    ['Marjami Ravine'] = { [1] = 50 },
    ['Kamihr Drifts'] = { [1] = 51 },
    ['Yughott Grotto'] = { [1] = 52 },
    ['Palborough Mines'] = { [1] = 53 },
    ['Giddeus'] = { [1] = 54 },
    ["Fei'Yin"] = { [1] = 55, [2] = 94 },
    ['Quicksand Caves'] = { [1] = 56, [2] = 96 },
    ['Den of Rancor'] = { [1] = 57, [2] = 93 },
    ['Castle Zvahl Keep'] = { [1] = 58 },
    ["Ru'Aun Gardens"] = { [1] = 59, [2] = 60, [3] = 61, [4] = 62, [5] = 63 },
    ['Tavnazian Safehold'] = { [1] = 64, [2] = 120, [3] = 121 },
    ['Aht Urhgan Whitegate'] = { [1] = 65, [2] = 106, [3] = 107, [4] = 108 },
    ['Nashmau'] = { [1] = 66 },
    ["Southern San d'Oria [S]"] = { [1] = 68 },
    ['Bastok Markets [S]'] = { [1] = 69 },
    ['Windurst Waters [S]'] = { [1] = 70 },
    ["Upper Delkfutt's Tower"] = { [1] = 71 },
    ["The Shrine of Ru'Avitau"] = { [1] = 72 },
    ['Riverne - Site #B01'] = { [1] = 73 },
    ['Bhaflau Thickets'] = { [1] = 74 },
    ['Caedarva Mire'] = { [1] = 75 },
    ['Uleguerand Range'] = { [1] = 76, [2] = 77, [3] = 78, [4] = 79, [5] = 80 },
    ['Attohwa Chasm'] = { [1] = 81 },
    ["Pso'Xja"] = { [1] = 82 },
    ['Newton Movalpolos'] = { [1] = 83 },
    ['Riverne - Site #A01'] = { [1] = 84 },
    ["Al'Taieu"] = { [1] = 85, [2] = 86, [3] = 87 },
    ["Grand Palace of Hu'Xzoi"] = { [1] = 88 },
    ["Garden of Ru'Hmet"] = { [1] = 89 },
    ['Mount Zhayolm'] = { [1] = 90 },
    ['Cape Teriggan'] = { [1] = 91 },
    ['The Boyahda Tree'] = { [1] = 92 },
    ["Ifrit's Cauldron"] = { [1] = 95 },
    ['Xarcabard [S]'] = { [1] = 111 },
    ['Leafallia'] = { [1] = 112 },
    ['Castle Zvahl Keep [S]'] = { [1] = 113 },
    ['Qufim Island'] = { [1] = 114 },
    ['Toraimarai Canal'] = { [1] = 115 },
    ["Ra'Kaznar Inner Court"] = { [1] = 116 },
    ['Misareaux Coast'] = { [1] = 117 },
};

local function GetCursorPos()
    local x = imgui.GetCursorPosX ~= nil and (tonumber(imgui.GetCursorPosX()) or 0) or 0;
    local y = imgui.GetCursorPosY ~= nil and (tonumber(imgui.GetCursorPosY()) or 0) or 0;

    return x, y;
end

local function SetCursorPos(x, y)
    if (imgui.SetCursorPosX ~= nil) then
        imgui.SetCursorPosX(tonumber(x) or 0);
    end

    if (imgui.SetCursorPosY ~= nil) then
        imgui.SetCursorPosY(tonumber(y) or 0);
    end
end

local function GetSettings()
    local global = state.GetGlobalSettings(globalDefaults);
    global.quickMenu = global.quickMenu or {};
    global.quickMenu.warp = global.quickMenu.warp or {};
    local settings = global.quickMenu.warp;

    if (settings.enabled == nil) then settings.enabled = true; end
    if (settings.grouping == nil) then settings.grouping = 'Region'; end
    if (settings.showNotes == nil) then settings.showNotes = true; end
    if (settings.hideUnknown == nil) then settings.hideUnknown = false; end
    if (settings.confirmBeforeWarp == nil) then settings.confirmBeforeWarp = false; end
    if (settings.debug == nil) then settings.debug = false; end
    if (settings.packetDebug == nil) then settings.packetDebug = false; end
    if (settings.favoriteDisplay == nil) then settings.favoriteDisplay = 'Short'; end
    settings.favorites = settings.favorites or {};

    return settings;
end

local function GetIcon(name)
    name = tostring(name or '');

    if (name == '') then
        return nil;
    end

    if (missingIcon[name] == true) then
        return nil;
    end

    if (iconCache[name] ~= nil) then
        return iconCache[name];
    end

    local path = addon.path .. '\\data\\warp\\' .. name;
    local exists = false;

    pcall(function()
        exists = ashita.fs.exists(path);
    end);

    if (exists ~= true) then
        missingIcon[name] = true;
        return nil;
    end

    local ok, texture = pcall(function()
        return textureLoader.Load(path);
    end);

    if (ok ~= true or texture == nil) then
        missingIcon[name] = true;
        return nil;
    end

    iconCache[name] = textureLoader.ToTextureId(texture);

    if (iconCache[name] == nil) then
        missingIcon[name] = true;
    end

    return iconCache[name];
end

local function GetHomePointNumber(value)
    local text = tostring(value or ''):lower();
    text = text:gsub('\170', '');
    text = text:gsub('[`´’]', "'");

    return text:match('home[%s_]*point[%s_]*#?[%s_]*(%d+)')
        or text:match('homepoint[%s_]*#?[%s_]*(%d+)')
        or text:match('home[%s_]*point.-(%d+)');
end

local function IsSurvivalGuideName(value)
    local text = tostring(value or ''):lower();
    text = text:gsub('_', ' ');

    return text:match('survival%s+guide') ~= nil;
end

local function IsUnityName(value)
    local text = tostring(value or ''):gsub('_', ' ');
    if (unityData.npcs ~= nil and unityData.npcs[text] == true) then
        return true;
    end

    local lower = text:lower();
    return lower == 'unity master' or lower == 'unitymaster';
end

local function IsOutpostTeleporterName(value)
    local text = tostring(value or ''):gsub('_', ' ');
    if (outpostData.npcs ~= nil and outpostData.npcs[text] == true) then
        return true;
    end

    return false;
end

local function IsCampaignArbiterName(value)
    local text = tostring(value or ''):gsub('_', ' ');
    if (campaignData.npcs ~= nil and campaignData.npcs[text] == true) then
        return true;
    end

    return false;
end

local function GetExpGuideMode(value)
    local text = tostring(value or ''):gsub('_', ' ');
    if (expGuideData.npcs ~= nil and expGuideData.npcs[text] ~= nil) then
        return expGuideData.npcs[text];
    end

    return nil;
end

local function IsFieldManualName(value)
    local text = tostring(value or ''):gsub('_', ' '):lower();
    return text == 'field manual';
end

local function IsDomenicName(value)
    local text = tostring(value or ''):gsub('_', ' ');
    return domenicData.npcs ~= nil and domenicData.npcs[text] == true;
end

local function GetCurrentZoneId()
    local zoneId = nil;

    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    return tonumber(zoneId) or 0;
end

local function GetSelfGameMode()
    local selfIndex = nil;

    pcall(function()
        selfIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
    end);

    return gameMode.Resolve(selfIndex, false);
end

local function IsAceMode(mode)
    return tostring(mode or GetSelfGameMode()) == 'ACE';
end

local function IsEraMode(mode)
    local value = tostring(mode or GetSelfGameMode());
    return value == 'CW' or value == 'UCW' or value == 'WEW';
end

local function IsExpGuideModeAllowed(modeName, playerMode)
    modeName = tostring(modeName or '');
    playerMode = tostring(playerMode or GetSelfGameMode());

    if (modeName == 'cw_emilia') then
        return playerMode == 'CW' or playerMode == 'UCW';
    end

    if (modeName == 'present') then
        return playerMode == 'ACE' or playerMode == 'WEW';
    end

    if (modeName == 'past') then
        return playerMode == 'ACE' or playerMode == 'CW' or playerMode == 'UCW' or playerMode == 'WEW';
    end

    return true;
end

local function PrepareContext(context)
    context = context or {};

    if (context.currentWarpIndex ~= nil) then
        return context;
    end

    local zoneName = zoneIdToZoneName[GetCurrentZoneId()];
    local hpNumber = tonumber(GetHomePointNumber(context.homePointNumber));
    if (zoneName ~= nil and hpNumber ~= nil and warpIndexes[zoneName] ~= nil) then
        context.currentWarpIndex = warpIndexes[zoneName][hpNumber];
    end

    return context;
end

local function FavoriteKey(zoneName, pointId)
    return tostring(zoneName or '') .. ':' .. tostring(tonumber(pointId) or pointId or '');
end

local function IsFavorite(settings, destination)
    return settings.favorites[FavoriteKey(destination.zone, destination.id)] == true;
end

local function ToggleFavorite(settings, destination)
    local key = FavoriteKey(destination.zone, destination.id);
    settings.favorites[key] = settings.favorites[key] ~= true and true or nil;
    state.Save();
end

local function GetUnlockState(unlockSnapshot, destination)
    if (type(unlockSnapshot) ~= 'table' or unlockSnapshot.known ~= true or unlockSnapshot.reliable ~= true) then
        return nil;
    end

    return unlockSnapshot.status ~= nil and unlockSnapshot.status[tonumber(destination.warpIndex) or -1] == true;
end

local function IsDestinationHidden(settings, destination, unlockSnapshot)
    local unlockState = GetUnlockState(unlockSnapshot, destination);

    return settings.hideUnknown == true and unlockState == false;
end

local function NoteText(note)
    local value = tostring(note or '');

    if (value == '') then
        return '';
    end

    return noteLabels[value] or value;
end

local function InferExpansion(category, zoneName)
    category = tostring(category or '');
    zoneName = tostring(zoneName or '');

    if (category == 'Aht Urhgan' or zoneName == 'Nashmau' or zoneName == 'Mount Zhayolm' or zoneName == 'Caedarva Mire' or zoneName == 'Bhaflau Thickets') then
        return 'Treasures of Aht Urhgan';
    end

    if (category == 'Adoulin' or zoneName:find('Adoulin', 1, true) ~= nil or zoneName == 'Ceizak Battlegrounds' or zoneName == 'Foret de Hennetiel' or zoneName == 'Morimar Basalt Fields' or zoneName == 'Yorcia Weald' or zoneName == 'Marjami Ravine' or zoneName == 'Kamihr Drifts' or zoneName == 'Leafallia' or zoneName == "Ra'Kaznar Inner Court") then
        return 'Seekers of Adoulin';
    end

    if (category == 'Tavnazia' or zoneName == 'Misareaux Coast' or zoneName:find('Riverne', 1, true) ~= nil or zoneName == "Al'Taieu" or zoneName == "Grand Palace of Hu'Xzoi" or zoneName == "Garden of Ru'Hmet") then
        return 'Chains of Promathia';
    end

    if (zoneName:find('%[S%]') ~= nil) then
        return 'Wings of the Goddess';
    end

    if (zoneName == 'Kazham' or zoneName == 'Norg' or zoneName == 'Rabao' or zoneName == "Ru'Aun Gardens" or zoneName == "The Shrine of Ru'Avitau" or zoneName == 'Cape Teriggan' or zoneName == "Ifrit's Cauldron" or zoneName == 'Den of Rancor' or zoneName == 'Quicksand Caves') then
        return 'Rise of the Zilart';
    end

    if (category == 'Field & Dungeon') then
        return 'Original Areas';
    end

    return 'Original Areas';
end

local function BuildDestinations()
    local rows = {};

    for _, category in ipairs(homePoints or {}) do
        for _, zone in ipairs(category.zones or {}) do
            for _, point in ipairs(zone.points or {}) do
                rows[#rows + 1] = {
                    category = tostring(category.category or 'Other'),
                    region = tostring(zone.region or category.category or 'Other'),
                    expansion = tostring(zone.expansion or InferExpansion(category.category, zone.name)),
                    zone = tostring(zone.name or ''),
                    id = tonumber(point.id) or 0,
                    label = tostring(point.label or ('Home Point #' .. tostring(point.id or ''))),
                    note = point.note,
                    aliases = point.aliases,
                    available = point.available ~= false,
                    warpIndex = point.warpIndex or (warpIndexes[tostring(zone.name or '')] ~= nil and warpIndexes[tostring(zone.name or '')][tonumber(point.id) or 0] or nil),
                };
            end
        end
    end

    return rows;
end

local function BuildTree(settings, destinations, unlockSnapshot)
    local grouping = tostring(settings.grouping or 'Region');
    local groups = {};
    local ordered = {};

    for _, destination in ipairs(destinations) do
        if (IsDestinationHidden(settings, destination, unlockSnapshot) ~= true) then
            local groupName = grouping == 'Expansion' and destination.expansion or destination.region;

            if (groups[groupName] == nil) then
                groups[groupName] = { name = groupName, zones = {}, zoneOrder = {} };
                ordered[#ordered + 1] = groups[groupName];
            end

            local group = groups[groupName];
            if (group.zones[destination.zone] == nil) then
                group.zones[destination.zone] = { name = destination.zone, points = {} };
                group.zoneOrder[#group.zoneOrder + 1] = group.zones[destination.zone];
            end

            group.zones[destination.zone].points[#group.zones[destination.zone].points + 1] = destination;
        end
    end

    if (grouping == 'Expansion') then
        local rank = {};
        for index, name in ipairs(expansionOrder) do
            rank[name] = index;
        end

        table.sort(ordered, function(a, b)
            return (rank[a.name] or 99) < (rank[b.name] or 99);
        end);
    end

    return ordered;
end

local function BuildSurvivalGuideTree(settings, destinations, unlockSnapshot)
    local grouping = tostring(settings.grouping or 'Region');
    local groups = {};
    local ordered = {};

    for _, destination in ipairs(destinations) do
        local unlockState = nil;
        if (type(unlockSnapshot) == 'table' and unlockSnapshot.known == true and unlockSnapshot.reliable == true) then
            unlockState = unlockSnapshot.status ~= nil and unlockSnapshot.status[tonumber(destination.index) or -1] == true;
        end

        if (settings.hideUnknown ~= true or unlockState ~= false) then
            local groupName = grouping == 'Expansion' and destination.expansion or destination.region;

            if (groups[groupName] == nil) then
                groups[groupName] = { name = groupName, destinations = {} };
                ordered[#ordered + 1] = groups[groupName];
            end

            groups[groupName].destinations[#groups[groupName].destinations + 1] = destination;
        end
    end

    if (grouping == 'Expansion') then
        local rank = {};
        for index, name in ipairs(expansionOrder) do
            rank[name] = index;
        end

        table.sort(ordered, function(a, b)
            return (rank[a.name] or 99) < (rank[b.name] or 99);
        end);
    end

    return ordered;
end

local function RequestHomePointWarp(destination, context)
    return homePointWarp.Request(destination, context);
end

local function RequestSurvivalGuideTeleport(destination, context)
    return survivalGuideTeleport.Request(destination, context);
end

local function RequestUnityTeleport(destination, context)
    return unityTeleport.Request(destination, context);
end

local function RequestOutpostTeleport(destination, context, payment)
    return outpostTeleport.Request(destination, context, payment);
end

local function RequestCampaignTeleport(destination, context)
    return campaignTeleport.Request(destination, context);
end

local function RequestExpGuideTeleport(destination, context, withBuff)
    return expGuideTeleport.Request(destination, context, withBuff);
end

local function DestinationLabel(settings, destination, favorite)
    local note = settings.showNotes == true and NoteText(destination.note) or '';
    local label = '';

    if (favorite == true and tostring(settings.favoriteDisplay or 'Short') == 'Full path') then
        label = destination.region .. ' > ' .. destination.zone .. ' > #' .. tostring(destination.id);
    else
        label = destination.zone .. ' #' .. tostring(destination.id);
    end

    if (note ~= '') then
        label = label .. '  ' .. note;
    end

    return label;
end

local function DrawDestination(settings, destination, favoriteRow, context, unlockSnapshot)
    local unlockState = GetUnlockState(unlockSnapshot, destination);

    if (IsDestinationHidden(settings, destination, unlockSnapshot) == true) then
        return false;
    end

    local favorite = IsFavorite(settings, destination);
    local icon = GetIcon(favorite and 'fav-on.png' or 'fav-off.png');
    local label = DestinationLabel(settings, destination, favoriteRow);
    local unavailable = destination.available == false;
    local labelColor = (unavailable == true or unlockState == false) and { 0.55, 0.55, 0.58, 1.0 } or nil;
    local rowStartX, rowStartY = GetCursorPos();
    local rowHeight = 22;
    local rowWidth = math.max(220, (#label * 8) + 46);

    if (icon ~= nil and imgui.Image ~= nil) then
        imgui.Image(icon, { 16, 16 }, { 0, 0 }, { 1, 1 });

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            ToggleFavorite(settings, destination);
            return;
        end

        imgui.SameLine();
    else
        imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, favorite and '[*]' or '[ ]');

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            ToggleFavorite(settings, destination);
            return;
        end

        imgui.SameLine();
    end

    if (imgui.InvisibleButton ~= nil) then
        local textX, textY = GetCursorPos();
        local clicked = imgui.InvisibleButton('##warp_dest_' .. FavoriteKey(destination.zone, destination.id), { rowWidth, rowHeight }) == true;
        SetCursorPos(textX, textY + 2);
        if (labelColor ~= nil) then
            imgui.TextColored(labelColor, label);
        else
            imgui.Text(label);
        end
        SetCursorPos(rowStartX, rowStartY + rowHeight);

        if (clicked == true) then
            RequestHomePointWarp(destination, context);

            if (imgui.CloseCurrentPopup ~= nil) then
                imgui.CloseCurrentPopup();
            end
        end

        return;
    end

    if (labelColor ~= nil) then
        imgui.TextColored(labelColor, label);
    else
        imgui.Text(label);
    end

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        RequestHomePointWarp(destination, context);

        if (imgui.CloseCurrentPopup ~= nil) then
            imgui.CloseCurrentPopup();
        end
    end

    return true;
end

local function DrawFavorites(settings, destinations, context, unlockSnapshot)
    local count = 0;

    for _, destination in ipairs(destinations) do
        if (IsFavorite(settings, destination) == true and IsDestinationHidden(settings, destination, unlockSnapshot) ~= true) then
            if (DrawDestination(settings, destination, true, context, unlockSnapshot) ~= false) then
                count = count + 1;
            end
        end
    end

    if (count == 0) then
        imgui.TextColored({ 0.72, 0.72, 0.72, 1.0 }, 'No favorites yet');
    end
end

local function SurvivalGuideFavoriteKey(destination)
    return 'survival:' .. tostring(tonumber(destination.index) or destination.name or '');
end

local function IsSurvivalGuideFavorite(settings, destination)
    settings.survivalGuideFavorites = settings.survivalGuideFavorites or {};

    return settings.survivalGuideFavorites[SurvivalGuideFavoriteKey(destination)] == true;
end

local function ToggleSurvivalGuideFavorite(settings, destination)
    settings.survivalGuideFavorites = settings.survivalGuideFavorites or {};
    local key = SurvivalGuideFavoriteKey(destination);
    settings.survivalGuideFavorites[key] = settings.survivalGuideFavorites[key] ~= true and true or nil;
    state.Save();
end

local function DrawSurvivalGuideDestination(settings, destination, context, unlockSnapshot)
    local unlockState = nil;
    if (type(unlockSnapshot) == 'table' and unlockSnapshot.known == true and unlockSnapshot.reliable == true) then
        unlockState = unlockSnapshot.status ~= nil and unlockSnapshot.status[tonumber(destination.index) or -1] == true;
    end

    if (settings.hideUnknown == true and unlockState == false) then
        return false;
    end

    local favorite = IsSurvivalGuideFavorite(settings, destination);
    local icon = GetIcon(favorite and 'fav-on.png' or 'fav-off.png');
    local label = tostring(destination.name or '');
    local labelColor = unlockState == false and { 0.55, 0.55, 0.58, 1.0 } or nil;
    local rowStartX, rowStartY = GetCursorPos();
    local rowHeight = 22;
    local rowWidth = math.max(220, (#label * 8) + 46);

    if (icon ~= nil and imgui.Image ~= nil) then
        imgui.Image(icon, { 16, 16 }, { 0, 0 }, { 1, 1 });

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            ToggleSurvivalGuideFavorite(settings, destination);
            return;
        end

        imgui.SameLine();
    else
        imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, favorite and '[*]' or '[ ]');

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            ToggleSurvivalGuideFavorite(settings, destination);
            return;
        end

        imgui.SameLine();
    end

    if (imgui.InvisibleButton ~= nil) then
        local textX, textY = GetCursorPos();
        local clicked = imgui.InvisibleButton('##survival_guide_dest_' .. tostring(destination.index or label), { rowWidth, rowHeight }) == true;
        SetCursorPos(textX, textY + 2);
        if (labelColor ~= nil) then
            imgui.TextColored(labelColor, label);
        else
            imgui.Text(label);
        end
        SetCursorPos(rowStartX, rowStartY + rowHeight);

        if (clicked == true) then
            RequestSurvivalGuideTeleport(destination, context);

            if (imgui.CloseCurrentPopup ~= nil) then
                imgui.CloseCurrentPopup();
            end
        end

        return true;
    end

    if (labelColor ~= nil) then
        imgui.TextColored(labelColor, label);
    else
        imgui.Text(label);
    end

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        RequestSurvivalGuideTeleport(destination, context);

        if (imgui.CloseCurrentPopup ~= nil) then
            imgui.CloseCurrentPopup();
        end
    end

    return true;
end

local function DrawSurvivalGuideFavorites(settings, destinations, context, unlockSnapshot)
    local count = 0;

    for _, destination in ipairs(destinations) do
        if (IsSurvivalGuideFavorite(settings, destination) == true) then
            if (DrawSurvivalGuideDestination(settings, destination, context, unlockSnapshot) ~= false) then
                count = count + 1;
            end
        end
    end

    if (count == 0) then
        imgui.TextColored({ 0.72, 0.72, 0.72, 1.0 }, 'No favorites yet');
    end
end

local function UnityFavoriteKey(destination)
    return 'unity:' .. tostring(tonumber(destination.index) or destination.name or '');
end

local function IsUnityFavorite(settings, destination)
    settings.unityFavorites = settings.unityFavorites or {};

    return settings.unityFavorites[UnityFavoriteKey(destination)] == true;
end

local function ToggleUnityFavorite(settings, destination)
    settings.unityFavorites = settings.unityFavorites or {};
    local key = UnityFavoriteKey(destination);
    settings.unityFavorites[key] = settings.unityFavorites[key] ~= true and true or nil;
    state.Save();
end

local function DrawUnityDestination(settings, destination, context)
    local favorite = IsUnityFavorite(settings, destination);
    local icon = GetIcon(favorite and 'fav-on.png' or 'fav-off.png');
    local label = tostring(destination.name or '');
    local rowStartX, rowStartY = GetCursorPos();
    local rowHeight = 22;
    local rowWidth = math.max(220, (#label * 8) + 46);

    if (icon ~= nil and imgui.Image ~= nil) then
        imgui.Image(icon, { 16, 16 }, { 0, 0 }, { 1, 1 });

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            ToggleUnityFavorite(settings, destination);
            return;
        end

        imgui.SameLine();
    else
        imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, favorite and '[*]' or '[ ]');

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            ToggleUnityFavorite(settings, destination);
            return;
        end

        imgui.SameLine();
    end

    if (imgui.InvisibleButton ~= nil) then
        local textX, textY = GetCursorPos();
        local clicked = imgui.InvisibleButton('##unity_dest_' .. tostring(destination.index or label), { rowWidth, rowHeight }) == true;
        SetCursorPos(textX, textY + 2);
        imgui.Text(label);
        SetCursorPos(rowStartX, rowStartY + rowHeight);

        if (clicked == true) then
            RequestUnityTeleport(destination, context);

            if (imgui.CloseCurrentPopup ~= nil) then
                imgui.CloseCurrentPopup();
            end
        end

        return true;
    end

    imgui.Text(label);

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        RequestUnityTeleport(destination, context);

        if (imgui.CloseCurrentPopup ~= nil) then
            imgui.CloseCurrentPopup();
        end
    end

    return true;
end

local function BuildUnityTree(settings)
    local grouping = tostring(settings.grouping or 'Region');
    local groups = {};
    local ordered = {};

    for _, destination in ipairs(unityData.destinations or {}) do
        local groupName = grouping == 'Expansion' and destination.expansion or destination.region;

        if (groups[groupName] == nil) then
            groups[groupName] = { name = groupName, destinations = {} };
            ordered[#ordered + 1] = groups[groupName];
        end

        groups[groupName].destinations[#groups[groupName].destinations + 1] = destination;
    end

    if (grouping == 'Expansion') then
        local rank = {};
        for index, name in ipairs(expansionOrder) do
            rank[name] = index;
        end

        table.sort(ordered, function(a, b)
            return (rank[a.name] or 99) < (rank[b.name] or 99);
        end);
    end

    return ordered;
end

local function DrawUnityFavorites(settings, context)
    local count = 0;

    for _, destination in ipairs(unityData.destinations or {}) do
        if (IsUnityFavorite(settings, destination) == true) then
            if (DrawUnityDestination(settings, destination, context) ~= false) then
                count = count + 1;
            end
        end
    end

    if (count == 0) then
        imgui.TextColored({ 0.72, 0.72, 0.72, 1.0 }, 'No favorites yet');
    end
end

local function OutpostFavoriteKey(destination)
    return 'outpost:' .. tostring(tonumber(destination.region) or destination.name or '');
end

local function IsOutpostFavorite(settings, destination)
    settings.outpostFavorites = settings.outpostFavorites or {};

    return settings.outpostFavorites[OutpostFavoriteKey(destination)] == true;
end

local function ToggleOutpostFavorite(settings, destination)
    settings.outpostFavorites = settings.outpostFavorites or {};
    local key = OutpostFavoriteKey(destination);
    settings.outpostFavorites[key] = settings.outpostFavorites[key] ~= true and true or nil;
    state.Save();
end

local function OutpostRegionLabel(destination)
    local name = tostring(destination.name or '');

    if (name == '') then
        return 'Unknown region';
    end

    return 'The ' .. name .. ' Region.';
end

local function DrawOutpostDestination(settings, destination, context)
    local favorite = IsOutpostFavorite(settings, destination);
    local icon = GetIcon(favorite and 'fav-on.png' or 'fav-off.png');
    local label = OutpostRegionLabel(destination);

    local rowStartX, rowStartY = GetCursorPos();
    local rowHeight = 22;
    local rowWidth = math.max(220, (#label * 8) + 46);

    if (icon ~= nil and imgui.Image ~= nil) then
        imgui.Image(icon, { 16, 16 }, { 0, 0 }, { 1, 1 });

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            ToggleOutpostFavorite(settings, destination);
            return;
        end

        imgui.SameLine();
    else
        imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, favorite and '[*]' or '[ ]');

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            ToggleOutpostFavorite(settings, destination);
            return;
        end

        imgui.SameLine();
    end

    if (imgui.BeginMenu ~= nil and imgui.EndMenu ~= nil) then
        if (imgui.BeginMenu(label) == true) then
            if (imgui.Selectable('Pay with gil ' .. tostring(destination.gil or '?')) == true) then
                RequestOutpostTeleport(destination, context, 'gil');
                if (imgui.CloseCurrentPopup ~= nil) then
                    imgui.CloseCurrentPopup();
                end
            end

            if (imgui.Selectable('Pay with points ' .. tostring(math.floor((tonumber(destination.gil) or 0) / 10))) == true) then
                RequestOutpostTeleport(destination, context, 'cp');
                if (imgui.CloseCurrentPopup ~= nil) then
                    imgui.CloseCurrentPopup();
                end
            end

            imgui.EndMenu();
        end

        return true;
    end

    if (imgui.InvisibleButton ~= nil) then
        local textX, textY = GetCursorPos();
        local clicked = imgui.InvisibleButton('##outpost_dest_' .. tostring(destination.region or label), { rowWidth, rowHeight }) == true;
        SetCursorPos(textX, textY + 2);
        imgui.Text(label);
        SetCursorPos(rowStartX, rowStartY + rowHeight);

        if (clicked == true) then
            RequestOutpostTeleport(destination, context, 'gil');
            if (imgui.CloseCurrentPopup ~= nil) then
                imgui.CloseCurrentPopup();
            end
        end

        return true;
    else
        imgui.Text(label);

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            RequestOutpostTeleport(destination, context, 'gil');
            if (imgui.CloseCurrentPopup ~= nil) then
                imgui.CloseCurrentPopup();
            end
        end
    end

    return true;
end

local function BuildOutpostTree(settings)
    local grouping = tostring(settings.grouping or 'Region');
    local groups = {};
    local ordered = {};

    for _, destination in ipairs(outpostData.destinations or {}) do
        local groupName = grouping == 'Expansion' and destination.expansion or 'Outposts';

        if (groups[groupName] == nil) then
            groups[groupName] = { name = groupName, destinations = {} };
            ordered[#ordered + 1] = groups[groupName];
        end

        groups[groupName].destinations[#groups[groupName].destinations + 1] = destination;
    end

    if (grouping == 'Expansion') then
        local rank = {};
        for index, name in ipairs(expansionOrder) do
            rank[name] = index;
        end

        table.sort(ordered, function(a, b)
            return (rank[a.name] or 99) < (rank[b.name] or 99);
        end);
    end

    return ordered;
end

local function DrawOutpostFavorites(settings, context)
    local count = 0;

    for _, destination in ipairs(outpostData.destinations or {}) do
        if (IsOutpostFavorite(settings, destination) == true) then
            if (DrawOutpostDestination(settings, destination, context) ~= false) then
                count = count + 1;
            end
        end
    end

    if (count == 0) then
        imgui.TextColored({ 0.72, 0.72, 0.72, 1.0 }, 'No favorites yet');
    end
end

local function CampaignFavoriteKey(destination)
    return 'campaign:' .. tostring(tonumber(destination.index) or destination.name or '');
end

local function IsCampaignFavorite(settings, destination)
    settings.campaignFavorites = settings.campaignFavorites or {};

    return settings.campaignFavorites[CampaignFavoriteKey(destination)] == true;
end

local function ToggleCampaignFavorite(settings, destination)
    settings.campaignFavorites = settings.campaignFavorites or {};
    local key = CampaignFavoriteKey(destination);
    settings.campaignFavorites[key] = settings.campaignFavorites[key] ~= true and true or nil;
    state.Save();
end

local function DrawCampaignDestination(settings, destination, context)
    local favorite = IsCampaignFavorite(settings, destination);
    local icon = GetIcon(favorite and 'fav-on.png' or 'fav-off.png');
    local label = tostring(destination.name or 'Unknown destination');
    local rowStartX, rowStartY = GetCursorPos();
    local rowHeight = 22;
    local rowWidth = math.max(220, (#label * 8) + 46);

    if (icon ~= nil and imgui.Image ~= nil) then
        imgui.Image(icon, { 16, 16 }, { 0, 0 }, { 1, 1 });

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            ToggleCampaignFavorite(settings, destination);
            return;
        end

        imgui.SameLine();
    else
        imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, favorite and '[*]' or '[ ]');

        if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
            ToggleCampaignFavorite(settings, destination);
            return;
        end

        imgui.SameLine();
    end

    if (imgui.InvisibleButton ~= nil) then
        local textX, textY = GetCursorPos();
        local clicked = imgui.InvisibleButton('##campaign_dest_' .. tostring(destination.index or label), { rowWidth, rowHeight }) == true;
        SetCursorPos(textX, textY + 2);
        imgui.Text(label);
        SetCursorPos(rowStartX, rowStartY + rowHeight);

        if (clicked == true) then
            RequestCampaignTeleport(destination, context);
            if (imgui.CloseCurrentPopup ~= nil) then
                imgui.CloseCurrentPopup();
            end
        end

        return true;
    end

    imgui.Text(label);

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        RequestCampaignTeleport(destination, context);
        if (imgui.CloseCurrentPopup ~= nil) then
            imgui.CloseCurrentPopup();
        end
    end

    return true;
end

local function DrawCampaignFavorites(settings, context)
    local count = 0;

    for _, destination in ipairs(campaignData.destinations or {}) do
        if (IsCampaignFavorite(settings, destination) == true) then
            if (DrawCampaignDestination(settings, destination, context) ~= false) then
                count = count + 1;
            end
        end
    end

    if (count == 0) then
        imgui.TextColored({ 0.72, 0.72, 0.72, 1.0 }, 'No favorites yet');
    end
end

local function DrawFieldManualService(service, context)
    local baseLabel = tostring(service.label or 'Support');
    local label = baseLabel;
    local cost = tonumber(service.cost);
    if (cost ~= nil) then
        label = label .. '  ' .. tostring(cost) .. ' tabs';
    end

    if (service.disabled == true) then
        imgui.TextColored({ 0.55, 0.55, 0.55, 1.0 }, label);
        if (service.disabledReason ~= nil) then
            imgui.TextColored({ 0.55, 0.55, 0.55, 1.0 }, tostring(service.disabledReason));
        end
        return;
    end

    if (type(service.stats) == 'table' and #service.stats > 0 and imgui.BeginMenu ~= nil and imgui.EndMenu ~= nil) then
        if (imgui.BeginMenu(label) == true) then
            for _, stat in ipairs(service.stats) do
                imgui.TextColored({ 0.72, 0.72, 0.72, 1.0 }, tostring(stat));
            end

            imgui.Separator();

            local useLabel = 'Use';
            if (cost ~= nil) then
                useLabel = useLabel .. '  ' .. tostring(cost) .. ' tabs';
            end

            if (imgui.Selectable(useLabel) == true) then
                fieldManualSupport.Request(service, context or {});
                if (imgui.CloseCurrentPopup ~= nil) then
                    imgui.CloseCurrentPopup();
                end
            end

            imgui.EndMenu();
        end

        return;
    end

    if (imgui.Selectable(label) == true) then
        fieldManualSupport.Request(service, context or {});
        if (imgui.CloseCurrentPopup ~= nil) then
            imgui.CloseCurrentPopup();
        end
    end
end

local function DrawFieldManualRegime(regime, context)
    local page = tonumber(regime.page) or 0;
    local label = 'Page ' .. tostring(page);
    local low = tonumber(regime.low);
    local high = tonumber(regime.high);

    if (low ~= nil and high ~= nil) then
        label = label .. '  Lv ' .. tostring(low) .. '-' .. tostring(high);
    end

    if (imgui.BeginMenu(label) == true) then
        if (low ~= nil and high ~= nil) then
            imgui.TextColored({ 0.72, 0.72, 0.72, 1.0 }, 'Level range: ' .. tostring(low) .. '-' .. tostring(high));
        end

        if (regime.reward ~= nil) then
            imgui.TextColored({ 0.72, 0.72, 0.72, 1.0 }, 'Reward: ' .. tostring(regime.reward) .. ' exp/gil/tabs');
        end

        if (regime.regimeId ~= nil and GetSettings().debug == true) then
            imgui.TextColored({ 0.72, 0.72, 0.72, 1.0 }, 'Regime ID: ' .. tostring(regime.regimeId));
        end

        if (type(regime.objectives) == 'table' and #regime.objectives > 0) then
            imgui.Separator();
            for _, objective in ipairs(regime.objectives) do
                local targets = {};
                if (type(objective.targets) == 'table') then
                    for _, target in ipairs(objective.targets) do
                        targets[#targets + 1] = tostring(target);
                    end
                end

                if (#targets > 0) then
                    local shown = {};
                    local maxTargets = 5;
                    for index, target in ipairs(targets) do
                        if (index <= maxTargets) then
                            shown[#shown + 1] = target;
                        end
                    end

                    local text = tostring(objective.count or 0) .. ' x ' .. table.concat(shown, ' / ');
                    if (#targets > maxTargets) then
                        text = text .. ' / +' .. tostring(#targets - maxTargets) .. ' more';
                    end

                    imgui.TextColored({ 0.85, 0.85, 0.85, 1.0 }, text);
                end
            end
        end

        imgui.Separator();

        if (imgui.Selectable('Start training regime') == true) then
            fieldManualSupport.Request({
                label = 'Training regime page ' .. tostring(page),
                option = regime.option,
                page = page,
                regimeId = regime.regimeId,
            }, context or {});

            if (imgui.CloseCurrentPopup ~= nil) then
                imgui.CloseCurrentPopup();
            end
        end

        if (imgui.Selectable('Start training regime, repeat') == true) then
            fieldManualSupport.Request({
                label = 'Training regime page ' .. tostring(page) .. ' repeat',
                option = regime.option,
                page = page,
                regimeId = regime.regimeId,
                repeatEnabled = true,
            }, context or {});

            if (imgui.CloseCurrentPopup ~= nil) then
                imgui.CloseCurrentPopup();
            end
        end

        imgui.EndMenu();
    end
end

local function DrawDomenicDestination(destination, context)
    local label = tostring(destination.name or 'Destination') .. '  ' .. tostring(destination.gil or '?') .. ' gil';

    if (imgui.Selectable(label) == true) then
        domenicTeleport.Request(destination, context or {});
        if (imgui.CloseCurrentPopup ~= nil) then
            imgui.CloseCurrentPopup();
        end
    end
end

function warpMenu.IsHomePointTarget(name, info)
    if (GetHomePointNumber(name) ~= nil) then
        return true;
    end

    if (info ~= nil and (
        GetHomePointNumber(info.name) ~= nil or
        GetHomePointNumber(info.displayName) ~= nil or
        GetHomePointNumber(info.type) ~= nil
    )) then
        return true;
    end

    return false;
end

function warpMenu.IsSurvivalGuideTarget(name, info)
    if (IsSurvivalGuideName(name) == true) then
        return true;
    end

    if (info ~= nil and (
        IsSurvivalGuideName(info.name) == true or
        IsSurvivalGuideName(info.displayName) == true or
        IsSurvivalGuideName(info.type) == true
    )) then
        return true;
    end

    return false;
end

function warpMenu.IsUnityTarget(name, info)
    if (IsUnityName(name) == true) then
        return true;
    end

    if (info ~= nil and (
        IsUnityName(info.name) == true or
        IsUnityName(info.displayName) == true or
        IsUnityName(info.type) == true
    )) then
        return true;
    end

    return false;
end

function warpMenu.IsOutpostTeleporterTarget(name, info)
    if (IsOutpostTeleporterName(name) == true) then
        return true;
    end

    if (info ~= nil and (
        IsOutpostTeleporterName(info.name) == true or
        IsOutpostTeleporterName(info.displayName) == true or
        IsOutpostTeleporterName(info.type) == true
    )) then
        return true;
    end

    return false;
end

function warpMenu.IsCampaignArbiterTarget(name, info)
    if (IsCampaignArbiterName(name) == true) then
        return true;
    end

    if (info ~= nil and (
        IsCampaignArbiterName(info.name) == true or
        IsCampaignArbiterName(info.displayName) == true or
        IsCampaignArbiterName(info.type) == true
    )) then
        return true;
    end

    return false;
end

function warpMenu.IsExpGuideTarget(name, info)
    local modeName = GetExpGuideMode(name);
    if (modeName ~= nil and IsExpGuideModeAllowed(modeName) == true) then
        return true;
    end

    if (info ~= nil) then
        modeName = GetExpGuideMode(info.name) or GetExpGuideMode(info.displayName) or GetExpGuideMode(info.type);
        if (modeName ~= nil and IsExpGuideModeAllowed(modeName) == true) then
            return true;
        end
    end

    return false;
end

function warpMenu.IsFieldManualTarget(name, info)
    if (IsFieldManualName(name) == true) then
        return true;
    end

    if (info ~= nil and (
        IsFieldManualName(info.name) == true or
        IsFieldManualName(info.displayName) == true or
        IsFieldManualName(info.type) == true
    )) then
        return true;
    end

    return false;
end

function warpMenu.IsDomenicTarget(name, info)
    if (IsDomenicName(name) == true) then
        return true;
    end

    if (info ~= nil and (
        IsDomenicName(info.name) == true or
        IsDomenicName(info.displayName) == true or
        IsDomenicName(info.type) == true
    )) then
        return true;
    end

    return false;
end

function warpMenu.RenderHomePointMenu(context)
    if (IsAceMode() ~= true) then
        imgui.Separator();
        imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Home Point teleportation');
        imgui.TextColored({ 0.72, 0.72, 0.72, 1.0 }, 'Not available.');
        return false;
    end

    local settings = GetSettings();
    context = PrepareContext(context);
    homePointWarp.SetDebugEnabled(settings.packetDebug == true);

    if (settings.enabled ~= true) then
        if (settings.debug == true) then
            imgui.Separator();
            imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Home Point teleportation');
            imgui.TextColored({ 0.85, 0.85, 0.85, 1.0 }, 'Disabled in Quick Menu settings.');
        end

        return false;
    end

    imgui.Separator();
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Home Point teleportation');

    if (imgui.BeginMenu == nil or imgui.EndMenu == nil or imgui.Selectable == nil) then
        imgui.TextColored({ 0.85, 0.85, 0.85, 1.0 }, 'Flyout menus are not available in this ImGui build.');
        return true;
    end

    local destinations = BuildDestinations();
    local unlockSnapshot = homePointWarp.GetUnlockSnapshot ~= nil and homePointWarp.GetUnlockSnapshot() or homePointWarp.GetUnlockSummary();

    if (imgui.BeginMenu('Favorites') == true) then
        DrawFavorites(settings, destinations, context, unlockSnapshot);
        imgui.EndMenu();
    end

    imgui.Separator();

    for _, group in ipairs(BuildTree(settings, destinations, unlockSnapshot)) do
        if (imgui.BeginMenu(group.name) == true) then
            for _, zone in ipairs(group.zoneOrder) do
                if (imgui.BeginMenu(zone.name) == true) then
                    for _, destination in ipairs(zone.points) do
                        DrawDestination(settings, destination, false, context, unlockSnapshot);
                    end
                    imgui.EndMenu();
                end
            end
            imgui.EndMenu();
        end
    end

    return true;
end

function warpMenu.RenderSurvivalGuideMenu(context)
    if (IsAceMode() ~= true) then
        imgui.Separator();
        imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Survival Guide teleportation');
        imgui.TextColored({ 0.72, 0.72, 0.72, 1.0 }, 'Not available.');
        return false;
    end

    local settings = GetSettings();
    survivalGuideTeleport.SetDebugEnabled(settings.packetDebug == true);

    if (settings.enabled ~= true) then
        if (settings.debug == true) then
            imgui.Separator();
            imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Survival Guide teleportation');
            imgui.TextColored({ 0.85, 0.85, 0.85, 1.0 }, 'Disabled in Quick Menu settings.');
        end

        return false;
    end

    imgui.Separator();
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Survival Guide teleportation');

    if (imgui.BeginMenu == nil or imgui.EndMenu == nil or imgui.Selectable == nil) then
        imgui.TextColored({ 0.85, 0.85, 0.85, 1.0 }, 'Flyout menus are not available in this ImGui build.');
        return true;
    end

    local unlockSnapshot = survivalGuideTeleport.GetUnlockSnapshot();

    if (imgui.BeginMenu('Favorites') == true) then
        DrawSurvivalGuideFavorites(settings, survivalGuides, context or {}, unlockSnapshot);
        imgui.EndMenu();
    end

    imgui.Separator();

    for _, group in ipairs(BuildSurvivalGuideTree(settings, survivalGuides, unlockSnapshot)) do
        if (imgui.BeginMenu(group.name) == true) then
            for _, destination in ipairs(group.destinations) do
                DrawSurvivalGuideDestination(settings, destination, context or {}, unlockSnapshot);
            end
            imgui.EndMenu();
        end
    end

    return true;
end

function warpMenu.RenderUnityMenu(context)
    if (IsAceMode() ~= true) then
        imgui.Separator();
        imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Unity teleportation');
        imgui.TextColored({ 0.72, 0.72, 0.72, 1.0 }, 'Not available.');
        return false;
    end

    local settings = GetSettings();
    unityTeleport.SetDebugEnabled(settings.packetDebug == true);

    if (settings.enabled ~= true) then
        if (settings.debug == true) then
            imgui.Separator();
            imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Unity teleportation');
            imgui.TextColored({ 0.85, 0.85, 0.85, 1.0 }, 'Disabled in Quick Menu settings.');
        end

        return false;
    end

    imgui.Separator();
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Unity teleportation');

    if (imgui.BeginMenu == nil or imgui.EndMenu == nil or imgui.Selectable == nil) then
        imgui.TextColored({ 0.85, 0.85, 0.85, 1.0 }, 'Flyout menus are not available in this ImGui build.');
        return true;
    end

    if (imgui.BeginMenu('Favorites') == true) then
        DrawUnityFavorites(settings, context or {});
        imgui.EndMenu();
    end

    imgui.Separator();

    for _, group in ipairs(BuildUnityTree(settings)) do
        if (imgui.BeginMenu(group.name) == true) then
            for _, destination in ipairs(group.destinations) do
                DrawUnityDestination(settings, destination, context or {});
            end
            imgui.EndMenu();
        end
    end

    imgui.TextColored({ 0.72, 0.72, 0.72, 1.0 }, '100 accolades');

    return true;
end

function warpMenu.RenderOutpostMenu(context)
    local settings = GetSettings();
    outpostTeleport.SetDebugEnabled(settings.packetDebug == true);

    if (settings.enabled ~= true) then
        if (settings.debug == true) then
            imgui.Separator();
            imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Outpost teleportation');
            imgui.TextColored({ 0.85, 0.85, 0.85, 1.0 }, 'Disabled in Quick Menu settings.');
        end

        return false;
    end

    imgui.Separator();
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Outpost teleportation');

    if (imgui.BeginMenu == nil or imgui.EndMenu == nil or imgui.Selectable == nil) then
        imgui.TextColored({ 0.85, 0.85, 0.85, 1.0 }, 'Flyout menus are not available in this ImGui build.');
        return true;
    end

    local favoriteCount = 0;
    for _, destination in ipairs(outpostData.destinations or {}) do
        if (IsOutpostFavorite(settings, destination) == true) then
            favoriteCount = favoriteCount + 1;
        end
    end

    if (favoriteCount > 0) then
        imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Favorites');
        DrawOutpostFavorites(settings, context or {});
        imgui.Separator();
    end

    for _, destination in ipairs(outpostData.destinations or {}) do
        DrawOutpostDestination(settings, destination, context or {});
    end

    return true;
end

function warpMenu.RenderCampaignMenu(context)
    local settings = GetSettings();
    campaignTeleport.SetDebugEnabled(settings.packetDebug == true);

    if (settings.enabled ~= true) then
        if (settings.debug == true) then
            imgui.Separator();
            imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Campaign teleportation');
            imgui.TextColored({ 0.85, 0.85, 0.85, 1.0 }, 'Disabled in Quick Menu settings.');
        end

        return false;
    end

    imgui.Separator();
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Campaign teleportation');

    local favoriteCount = 0;
    for _, destination in ipairs(campaignData.destinations or {}) do
        if (IsCampaignFavorite(settings, destination) == true) then
            favoriteCount = favoriteCount + 1;
        end
    end

    if (favoriteCount > 0) then
        imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Favorites');
        DrawCampaignFavorites(settings, context or {});
        imgui.Separator();
    end

    for _, destination in ipairs(campaignData.destinations or {}) do
        DrawCampaignDestination(settings, destination, context or {});
    end

    return true;
end

function warpMenu.RenderDomenicMenu(context)
    local settings = GetSettings();
    domenicTeleport.SetDebugEnabled(settings.packetDebug == true);

    if (settings.enabled ~= true) then
        if (settings.debug == true) then
            imgui.Separator();
            imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'BCNM teleportation');
            imgui.TextColored({ 0.85, 0.85, 0.85, 1.0 }, 'Disabled in Quick Menu settings.');
        end

        return false;
    end

    imgui.Separator();
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'BCNM teleportation');

    for _, destination in ipairs(domenicData.destinations or {}) do
        DrawDomenicDestination(destination, context or {});
    end

    return true;
end

function warpMenu.RenderExpGuideMenu(context)
    local settings = GetSettings();
    context = context or {};
    expGuideTeleport.SetDebugEnabled(settings.packetDebug == true);

    local modeName = GetExpGuideMode(context.name) or GetExpGuideMode(context.rawName) or 'past';
    local mode = expGuideData.modes[modeName];

    if (mode == nil or IsExpGuideModeAllowed(modeName) ~= true) then
        return false;
    end

    if (settings.enabled ~= true) then
        if (settings.debug == true) then
            imgui.Separator();
            imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, tostring(mode.title or 'EXP Guide teleportation'));
            imgui.TextColored({ 0.85, 0.85, 0.85, 1.0 }, 'Disabled in Quick Menu settings.');
        end

        return false;
    end

    imgui.Separator();
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, tostring(mode.title or 'EXP Guide teleportation'));

    if (imgui.BeginMenu == nil or imgui.EndMenu == nil or imgui.Selectable == nil) then
        imgui.TextColored({ 0.85, 0.85, 0.85, 1.0 }, 'Flyout menus are not available in this ImGui build.');
        return true;
    end

    local groups = {};
    local order = {};
    for _, destination in ipairs(mode.destinations or {}) do
        local region = tostring(destination.region or 'Destinations');
        if (groups[region] == nil) then
            groups[region] = {};
            order[#order + 1] = region;
        end
        destination.mode = modeName;
        groups[region][#groups[region] + 1] = destination;
    end

    for _, region in ipairs(order) do
        if (mode.flatList == true) then
            for _, destination in ipairs(groups[region]) do
                local label = tostring(destination.label or destination.result or 'Destination');
                if (mode.directList == true) then
                    if (imgui.Selectable(label) == true) then
                        RequestExpGuideTeleport(destination, context, false);
                        if (imgui.CloseCurrentPopup ~= nil) then
                            imgui.CloseCurrentPopup();
                        end
                    end
                elseif (imgui.BeginMenu(label) == true) then
                    local paymentOptions = destination.paymentOptions or mode.paymentOptions;
                    if (paymentOptions ~= nil and #paymentOptions > 0 and destination.noPayment ~= true) then
                        for _, paymentOption in ipairs(paymentOptions) do
                            if (imgui.Selectable(tostring(paymentOption.label or paymentOption.result or 'Pay')) == true) then
                                RequestExpGuideTeleport(destination, context, paymentOption);
                                if (imgui.CloseCurrentPopup ~= nil) then
                                    imgui.CloseCurrentPopup();
                                end
                            end
                        end
                    else
                        if (imgui.Selectable('Teleport') == true) then
                            RequestExpGuideTeleport(destination, context, false);
                            if (imgui.CloseCurrentPopup ~= nil) then
                                imgui.CloseCurrentPopup();
                            end
                        end

                        if (mode.buffQuestion ~= nil and tostring(mode.buffQuestion) ~= '') then
                            if (imgui.Selectable('Teleport + ' .. tostring(mode.buffName or 'Buff')) == true) then
                                RequestExpGuideTeleport(destination, context, true);
                                if (imgui.CloseCurrentPopup ~= nil) then
                                    imgui.CloseCurrentPopup();
                                end
                            end
                        end
                    end

                    imgui.EndMenu();
                end
            end
        else
            if (imgui.BeginMenu(region) == true) then
                for _, destination in ipairs(groups[region]) do
                    local label = tostring(destination.label or destination.result or 'Destination');
                    if (imgui.BeginMenu(label) == true) then
                        local paymentOptions = destination.paymentOptions or mode.paymentOptions;
                        if (paymentOptions ~= nil and #paymentOptions > 0 and destination.noPayment ~= true) then
                            for _, paymentOption in ipairs(paymentOptions) do
                                if (imgui.Selectable(tostring(paymentOption.label or paymentOption.result or 'Pay')) == true) then
                                    RequestExpGuideTeleport(destination, context, paymentOption);
                                    if (imgui.CloseCurrentPopup ~= nil) then
                                        imgui.CloseCurrentPopup();
                                    end
                                end
                            end
                        else
                            if (imgui.Selectable('Teleport') == true) then
                                RequestExpGuideTeleport(destination, context, false);
                                if (imgui.CloseCurrentPopup ~= nil) then
                                    imgui.CloseCurrentPopup();
                                end
                            end

                            if (mode.buffQuestion ~= nil and tostring(mode.buffQuestion) ~= '') then
                                if (imgui.Selectable('Teleport + ' .. tostring(mode.buffName or 'Buff')) == true) then
                                    RequestExpGuideTeleport(destination, context, true);
                                    if (imgui.CloseCurrentPopup ~= nil) then
                                        imgui.CloseCurrentPopup();
                                    end
                                end
                            end
                        end

                        imgui.EndMenu();
                    end
                end
                imgui.EndMenu();
            end
        end
    end

    return true;
end

function warpMenu.RenderFieldManualMenu(context)
    local settings = GetSettings();
    context = context or {};
    fieldManualSupport.SetDebugEnabled(settings.packetDebug == true);

    if (settings.enabled ~= true) then
        if (settings.debug == true) then
            imgui.Separator();
            imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Field Manual support');
            imgui.TextColored({ 0.85, 0.85, 0.85, 1.0 }, 'Disabled in Quick Menu settings.');
        end

        return false;
    end

    imgui.Separator();
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Field Manual support');

    if (imgui.BeginMenu == nil or imgui.EndMenu == nil or imgui.Selectable == nil) then
        imgui.TextColored({ 0.85, 0.85, 0.85, 1.0 }, 'Flyout menus are not available in this ImGui build.');
        return true;
    end

    local groups = { 'Training regimes', 'Support effects', 'Field recipes', 'Teleportation' };

    for _, groupName in ipairs(groups) do
        if (imgui.BeginMenu(groupName) == true) then
            if (groupName == 'Training regimes') then
                local zoneId = GetCurrentZoneId();
                local regimes = (fieldManualData.trainingRegimes or {})[zoneId] or {};
                if (#regimes == 0) then
                    imgui.TextColored({ 0.72, 0.72, 0.72, 1.0 }, 'No training pages for this zone.');
                else
                    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Starting a page may replace your current regime.');
                    imgui.Separator();
                    for _, regime in ipairs(regimes) do
                        DrawFieldManualRegime(regime, context);
                    end
                end
            else
                for _, service in ipairs(fieldManualData.support or {}) do
                    if (service.group == groupName) then
                        DrawFieldManualService(service, context);
                    end
                end
            end

            imgui.EndMenu();
        end
    end

    return true;
end

function warpMenu.ClearTextureCache()
    iconCache = {};
    missingIcon = {};
end

function warpMenu.StartCampaignCapture(seconds)
    campaignCaptureUntil = os.clock() + math.max(1, tonumber(seconds) or 30);
    log.Info('Campaign Arbiter packet capture active for ' .. tostring(math.floor(campaignCaptureUntil - os.clock())) .. 's. Use the native Campaign Arbiter menu now.');
end

function warpMenu.StopCampaignCapture()
    campaignCaptureUntil = 0;
    log.Info('Campaign Arbiter packet capture stopped.');
end

function warpMenu.StartExpGuideCapture(seconds)
    expGuideCaptureUntil = os.clock() + math.max(1, tonumber(seconds) or 30);
    log.Info('EXP Guide packet capture active for ' .. tostring(math.floor(expGuideCaptureUntil - os.clock())) .. 's. Use the native EXP Guide menu now.');
end

function warpMenu.StopExpGuideCapture()
    expGuideCaptureUntil = 0;
    log.Info('EXP Guide packet capture stopped.');
end

function warpMenu.HandlePacketIn(e)
    if (CampaignCaptureActive() == true and e ~= nil and type(e.data) == 'string') then
        local data = e.data_modified or e.data;
        if (e.id == 0x032 or e.id == 0x034 or e.id == 0x05C or e.id == 0x052) then
            if (PacketHasCampaignEvent(data) == true or e.id == 0x05C or e.id == 0x052) then
                log.Info('Campaign capture incoming id=0x' .. string.format('%03X', tonumber(e.id) or 0) .. ' size=' .. tostring(e.size or #data) .. ' bytes=' .. FormatPacketString(data, 64));
            end
        end
    end

    if (ExpGuideCaptureActive() == true and e ~= nil and type(e.data) == 'string') then
        local data = e.data_modified or e.data;
        if (e.id == 0x017 or e.id == 0x028 or e.id == 0x052) then
            local summary = SplitCustomMenuIncoming(data);
            if (summary ~= nil) then
                log.Info('EXP Guide capture incoming id=0x' .. string.format('%03X', tonumber(e.id) or 0) .. ' ' .. summary);
            else
                log.Info('EXP Guide capture incoming id=0x' .. string.format('%03X', tonumber(e.id) or 0) .. ' size=' .. tostring(e.size or #data) .. ' text="' .. PacketPrintableText(data) .. '" bytes=' .. FormatPacketString(data, 80));
            end
        end
    end

    homePointWarp.HandlePacketIn(e);
    survivalGuideTeleport.HandlePacketIn(e);
    unityTeleport.HandlePacketIn(e);
    outpostTeleport.HandlePacketIn(e);
    campaignTeleport.HandlePacketIn(e);
    expGuideTeleport.HandlePacketIn(e);
    fieldManualSupport.HandlePacketIn(e);
    domenicTeleport.HandlePacketIn(e);
end

function warpMenu.HandlePacketOut(e)
    if (CampaignCaptureActive() == true and e ~= nil and type(e.data) == 'string') then
        if (e.id == 0x01A or e.id == 0x05B or e.id == 0x05C or e.id == 0x016 or e.id == 0x114) then
            local data = e.data_modified or e.data;
            log.Info('Campaign capture outgoing id=0x' .. string.format('%03X', tonumber(e.id) or 0) .. ' size=' .. tostring(e.size or #data) .. ' bytes=' .. FormatPacketString(data, 64));
        end
    end

    if (ExpGuideCaptureActive() == true and e ~= nil and type(e.data) == 'string') then
        local data = e.data_modified or e.data;
        if (e.id == 0x01A or e.id == 0x0B6) then
            local summary = SplitCustomMenuOutgoing(data);
            if (summary ~= nil) then
                log.Info('EXP Guide capture outgoing id=0x' .. string.format('%03X', tonumber(e.id) or 0) .. ' ' .. summary);
            else
                log.Info('EXP Guide capture outgoing id=0x' .. string.format('%03X', tonumber(e.id) or 0) .. ' size=' .. tostring(e.size or #data) .. ' text="' .. PacketPrintableText(data) .. '" bytes=' .. FormatPacketString(data, 80));
            end
        end
    end

    homePointWarp.HandlePacketOut(e);
    survivalGuideTeleport.HandlePacketOut(e);
    unityTeleport.HandlePacketOut(e);
    outpostTeleport.HandlePacketOut(e);
    campaignTeleport.HandlePacketOut(e);
    expGuideTeleport.HandlePacketOut(e);
    fieldManualSupport.HandlePacketOut(e);
    domenicTeleport.HandlePacketOut(e);
end

function warpMenu.Update()
    homePointWarp.Update();
    survivalGuideTeleport.Update();
    unityTeleport.Update();
    outpostTeleport.Update();
    campaignTeleport.Update();
    expGuideTeleport.Update();
    fieldManualSupport.Update();
    domenicTeleport.Update();
end

return warpMenu;
