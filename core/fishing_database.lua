require('common');

local database = {};
local loaded = false;
local lsbLoaded = false;
local gearLoaded = false;
local baitAffinityLoaded = false;
local fishRows = nil;
local lsbRows = nil;
local gearRows = nil;
local baitAffinityRows = nil;
local byFish = {};
local knownRods = {};
local knownBaits = {};
local rodNamesById = {
    [17011] = 'Ebisu Fishing Rod',
    [17012] = 'Judges Rod',
    [17013] = 'Goldfish Basket',
    [17014] = 'Hume Fishing Rod',
    [17015] = 'Halcyon Rod',
    [17380] = 'Mithran Fishing Rod',
    [17381] = 'Composite Fishing Rod',
    [17382] = 'Single Hook Fishing Rod',
    [17383] = 'Clothespole',
    [17384] = 'Carbon Fishing Rod',
    [17385] = 'Glass Fiber Fishing Rod',
    [17386] = "Lu Shang's Fishing Rod",
    [17387] = 'Tarutaru Fishing Rod',
    [17388] = 'Fastwater Fishing Rod',
    [17389] = 'Bamboo Fishing Rod',
    [17390] = 'Yew Fishing Rod',
    [17391] = 'Willow Fishing Rod',
    [19319] = 'Maze Monger Fishing Rod',
    [19320] = "Lu Shang's Fishing Rod +1",
    [19321] = 'Ebisu Fishing Rod +1',
};
local baitNamesById = {
    [16992] = 'Slice of Bluetail',
    [16993] = 'Peeled Crayfish',
    [16994] = 'Slice of Moat Carp',
    [16995] = 'Rotten Meat',
    [16996] = 'Ball of Sardine Paste',
    [16997] = 'Ball of Crayfish Paste',
    [16998] = 'Ball of Insect Paste',
    [16999] = 'Ball of Trout Paste',
    [17000] = 'Meatball',
    [17001] = 'Giant Shell Bug',
    [17002] = 'Robber Rig',
    [17003] = 'Super Scoop',
    [17004] = 'Judge Minnow',
    [17005] = 'Lufaise Fly',
    [17006] = 'Drill Calamary',
    [17007] = 'Dwarf Pugil',
    [17008] = 'Regular Maze Monger Ball',
    [17009] = 'Large Maze Monger Ball',
    [17010] = 'Goliath Worm',
    [17392] = 'Slice of Sardine',
    [17393] = 'Slice of Cod',
    [17394] = 'Peeled Lobster',
    [17395] = 'Lugworm',
    [17396] = 'Little Worm',
    [17397] = 'Shell Bug',
    [17398] = 'Rogue Rig',
    [17399] = 'Sabiki Rig',
    [17400] = 'Sinking Minnow',
    [17401] = 'Lizard Lure',
    [17402] = 'Shrimp Lure',
    [17403] = 'Frog Lure',
    [17404] = 'Worm Lure',
    [17405] = 'Fly Lure',
    [17406] = 'Judges Lure',
    [17407] = 'Minnow',
    [19323] = 'Maze Monger Minnow',
    [19324] = 'Dried Squid',
    [19325] = 'Judge Fly',
    [19326] = 'Sea Dragon Liver',
};

local ranks = {
    { min = 0, max = 10, name = 'Amateur' },
    { min = 11, max = 20, name = 'Recruit' },
    { min = 21, max = 30, name = 'Initiate' },
    { min = 31, max = 40, name = 'Novice' },
    { min = 41, max = 50, name = 'Apprentice' },
    { min = 51, max = 60, name = 'Journeyman' },
    { min = 61, max = 70, name = 'Craftsman' },
    { min = 71, max = 80, name = 'Artisan' },
    { min = 81, max = 90, name = 'Adept' },
    { min = 91, max = 100, name = 'Veteran' },
    { min = 101, max = 110, name = 'Expert' },
};

local function CleanName(value)
    return tostring(value or ''):gsub('\170', ''):gsub('%c', ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local function NormalizeName(value)
    local text = CleanName(value):lower();
    text = text:gsub('fbr%.', 'fiber');
    text = text:gsub('fbr', 'fiber');
    text = text:gsub('f%.%s*rod', 'fishing rod');
    text = text:gsub('fish%.', 'fishing');
    text = text:gsub('comp%.', 'composite');
    text = text:gsub('l%.shang', 'lu shang');
    text = text:gsub('%s*%b()%s*', ' ');
    text = text:gsub('[%*%?]', '');
    text = text:gsub('%.', '');
    text = text:gsub('%s+', ' ');
    return text:gsub('^%s+', ''):gsub('%s+$', '');
end

local function AddKnownName(target, entry)
    local name = CleanName(type(entry) == 'table' and entry.name or entry);
    local key = NormalizeName(name);
    if (key ~= '' and target[key] == nil) then
        target[key] = name;
    end
end

local function FirstNames(list, limit)
    local names = {};
    local maxCount = math.max(1, tonumber(limit) or 4);

    for _, entry in ipairs(list or {}) do
        local name = CleanName(type(entry) == 'table' and entry.name or entry);
        if (name ~= '') then
            names[#names + 1] = name;
            if (#names >= maxCount) then
                break;
            end
        end
    end

    if (#names == 0 and type(list) == 'table') then
        for _, entry in pairs(list) do
            local name = CleanName(type(entry) == 'table' and entry.name or entry);
            if (name ~= '') then
                names[#names + 1] = name;
            end
        end

        table.sort(names, function(left, right)
            return tostring(left):lower() < tostring(right):lower();
        end);

        while (#names > maxCount) do
            names[#names] = nil;
        end
    end

    return names;
end

local function Load()
    if (loaded == true) then
        return gearRows ~= nil;
    end

    loaded = true;
    local ok, rows = pcall(require, 'data.Fishing.lsb_gear');
    if (ok ~= true or type(rows) ~= 'table') then
        fishRows = nil;
        gearRows = nil;
        return false;
    end

    gearRows = rows;
    fishRows = {};
    byFish = {};
    knownRods = {};
    knownBaits = {};

    for itemId, rod in pairs(gearRows.rods or {}) do
        if (type(rod) == 'table' and rod.name ~= nil) then
            rodNamesById[tonumber(itemId) or 0] = CleanName(rod.name);
            AddKnownName(knownRods, rod.name);
        end
    end

    for itemId, bait in pairs(gearRows.baits or {}) do
        if (type(bait) == 'table' and bait.name ~= nil) then
            baitNamesById[tonumber(itemId) or 0] = CleanName(bait.name);
            AddKnownName(knownBaits, bait.name);
        end
    end

    for fishId, fish in pairs(gearRows.fish or {}) do
        local row = {
            fish = CleanName(type(fish) == 'table' and fish.name or ''),
            id = tonumber(fishId),
            level = tonumber(type(fish) == 'table' and fish.level) or 0,
            rank = database.GetRankForLevel ~= nil and database.GetRankForLevel(tonumber(type(fish) == 'table' and fish.level) or 0) or nil,
        };
        fishRows[#fishRows + 1] = row;
        local key = NormalizeName(row.fish);
        if (key ~= '') then
            byFish[key] = row;
        end
    end

    return true;
end

local function LoadGear()
    if (gearLoaded == true) then
        return gearRows ~= nil;
    end

    gearLoaded = true;
    return Load();
end

local function LoadLsb()
    if (lsbLoaded == true) then
        return lsbRows ~= nil;
    end

    lsbLoaded = true;
    local ok, rows = pcall(require, 'data.Fishing.lsb');
    if (ok ~= true or type(rows) ~= 'table') then
        lsbRows = nil;
        return false;
    end

    lsbRows = rows;
    return true;
end

local function LoadBaitAffinity()
    if (baitAffinityLoaded == true) then
        return baitAffinityRows ~= nil;
    end

    baitAffinityLoaded = true;
    local ok, rows = pcall(require, 'data.Fishing.lsb_bait_affinity');
    if (ok ~= true or type(rows) ~= 'table') then
        baitAffinityRows = nil;
        return false;
    end

    baitAffinityRows = rows;
    return true;
end

local function GetFishNameById(fishId)
    if (LoadLsb() ~= true) then
        return nil;
    end

    local fish = lsbRows.fish ~= nil and lsbRows.fish[tonumber(fishId) or 0] or nil;
    return fish ~= nil and CleanName(fish.name) or nil;
end

local function GetFishIdByName(fishName)
    if (LoadLsb() ~= true) then
        return nil;
    end

    local needle = NormalizeName(fishName);
    if (needle == '') then
        return nil;
    end

    for fishId, fish in pairs(lsbRows.fish or {}) do
        if (NormalizeName(type(fish) == 'table' and fish.name or '') == needle) then
            return tonumber(fishId);
        end
    end

    return nil;
end

local function AddAffinityBaits(target, fishName, fishId)
    if (LoadBaitAffinity() ~= true) then
        return false;
    end

    fishId = tonumber(fishId) or GetFishIdByName(fishName);
    local rows = fishId ~= nil and baitAffinityRows[fishId] or nil;
    if (type(rows) ~= 'table' or #rows == 0) then
        return false;
    end

    for _, row in ipairs(rows) do
        local name = baitNamesById[tonumber(row.bait) or 0];
        local key = NormalizeName(name);
        if (name ~= nil and key ~= '' and target[key] == nil) then
            target[key] = name;
        end
    end

    return true;
end

local function GetGearFish(fishName, fishId)
    if (LoadGear() ~= true) then
        return nil, nil;
    end

    fishId = tonumber(fishId) or GetFishIdByName(fishName);
    if (fishId == nil) then
        return nil, nil;
    end

    return gearRows.fish ~= nil and gearRows.fish[fishId] or nil, fishId;
end

local function AddRodSuggestions(target, fishName, fishId)
    local fish = nil;
    fish, fishId = GetGearFish(fishName, fishId);
    if (fish == nil or type(gearRows.rods) ~= 'table') then
        return false;
    end

    local fishSize = tonumber(fish.sizeType) or 0;
    local fishRank = tonumber(fish.ranking) or 0;
    local legendary = tonumber(fish.legendary) == 1;
    local scored = {};

    for rodId, rod in pairs(gearRows.rods) do
        local name = CleanName(type(rod) == 'table' and rod.name or '');
        local flags = tonumber(type(rod) == 'table' and rod.flags) or 0;
        local isScoop = bit ~= nil and bit.band(flags, 0x08) ~= 0;

        if (name ~= '' and isScoop ~= true) then
            local rodSize = tonumber(rod.sizeType) or 0;
            local minRank = tonumber(rod.minRank) or 0;
            local maxRank = tonumber(rod.maxRank) or 0;
            local rodLegendary = tonumber(rod.legendary) == 1;
            local score = 0;

            if (legendary == true) then
                score = score + (rodLegendary and 100 or -100);
            end

            if (rodLegendary == true) then
                score = score + 25;
            elseif (fishSize > rodSize) then
                score = score - 45;
            elseif (fishSize < rodSize) then
                score = score - 12;
            else
                score = score + 20;
            end

            if (fishRank >= minRank and fishRank <= maxRank) then
                score = score + 45;
            elseif (fishRank > maxRank) then
                score = score - ((fishRank - maxRank) * 12);
            else
                score = score - math.min(30, (minRank - fishRank) * 4);
            end

            score = score + (tonumber(rod.rating) or 0);
            scored[#scored + 1] = {
                name = name,
                key = NormalizeName(name),
                score = score,
                id = tonumber(rodId) or 0,
            };
        end
    end

    table.sort(scored, function(left, right)
        if (left.score ~= right.score) then
            return left.score > right.score;
        end

        return tostring(left.name):lower() < tostring(right.name):lower();
    end);

    local added = 0;
    for _, row in ipairs(scored) do
        if (row.score >= 40 and row.key ~= '' and target[row.key] == nil) then
            target[row.key] = row.name;
            added = added + 1;
        end

        if (added >= 8) then
            break;
        end
    end

    return added > 0;
end

local function GetAreaFish(zoneId, areaId)
    local result = {};
    local seen = {};

    if (LoadLsb() ~= true) then
        return result;
    end

    local zoneCatches = lsbRows.catches ~= nil and lsbRows.catches[tonumber(zoneId) or 0] or nil;
    local groups = zoneCatches ~= nil and zoneCatches[tonumber(areaId) or 0] or nil;

    for _, groupId in ipairs(groups or {}) do
        for _, row in ipairs((lsbRows.groups ~= nil and lsbRows.groups[tonumber(groupId) or 0]) or {}) do
            local fishId = tonumber(row.fish) or 0;
            local fish = lsbRows.fish ~= nil and lsbRows.fish[fishId] or nil;
            local name = fish ~= nil and CleanName(fish.name) or '';

            if (
                name ~= '' and
                seen[name:lower()] ~= true and
                tonumber(fish.disabled) ~= 1 and
                tonumber(fish.questOnly) ~= 1 and
                tonumber(fish.item) ~= 1
            ) then
                seen[name:lower()] = true;
                result[#result + 1] = {
                    id = fishId,
                    name = name,
                    level = tonumber(fish.level) or 0,
                    rarity = tonumber(row.rarity) or 0,
                    item = tonumber(fish.item) or 0,
                };
            end
        end
    end

    table.sort(result, function(left, right)
        if ((tonumber(left.item) or 0) ~= (tonumber(right.item) or 0)) then
            return (tonumber(left.item) or 0) < (tonumber(right.item) or 0);
        end

        if ((tonumber(left.level) or 0) ~= (tonumber(right.level) or 0)) then
            return (tonumber(left.level) or 0) < (tonumber(right.level) or 0);
        end

        return tostring(left.name):lower() < tostring(right.name):lower();
    end);

    return result;
end

local function GetZoneFish(zoneId)
    local result = {};
    local seen = {};

    if (LoadLsb() ~= true) then
        return result;
    end

    local zoneCatches = lsbRows.catches ~= nil and lsbRows.catches[tonumber(zoneId) or 0] or nil;
    if (type(zoneCatches) ~= 'table') then
        return result;
    end

    for areaId, _ in pairs(zoneCatches) do
        for _, option in ipairs(GetAreaFish(zoneId, areaId)) do
            local key = CleanName(option.name):lower();
            if (key ~= '' and seen[key] ~= true) then
                seen[key] = true;
                result[#result + 1] = option;
            end
        end
    end

    table.sort(result, function(left, right)
        if ((tonumber(left.item) or 0) ~= (tonumber(right.item) or 0)) then
            return (tonumber(left.item) or 0) < (tonumber(right.item) or 0);
        end

        if ((tonumber(left.level) or 0) ~= (tonumber(right.level) or 0)) then
            return (tonumber(left.level) or 0) < (tonumber(right.level) or 0);
        end

        return tostring(left.name):lower() < tostring(right.name):lower();
    end);

    return result;
end

function database.GetFishNameById(fishId)
    return GetFishNameById(fishId);
end

function database.GetFishingArea(zoneId, position)
    if (LoadLsb() ~= true) then
        return nil;
    end

    zoneId = tonumber(zoneId) or 0;
    local areas = lsbRows.areas ~= nil and lsbRows.areas[zoneId] or nil;
    if (type(areas) ~= 'table') then
        return nil;
    end

    local x = tonumber(position ~= nil and position.x);
    local y = tonumber(position ~= nil and position.y);
    local z = tonumber(position ~= nil and position.z);
    local wholeZone = nil;
    local best = nil;

    for _, area in ipairs(areas) do
        if (tonumber(area.boundType) == 0) then
            wholeZone = wholeZone or area;
        elseif (tonumber(area.boundType) == 1 and x ~= nil and y ~= nil and z ~= nil) then
            local radius = tonumber(area.radius) or 0;
            local height = tonumber(area.height) or 0;
            local dx = x - (tonumber(area.centerX) or 0);
            local dz = z - (tonumber(area.centerZ) or 0);
            local dy = math.abs(y - (tonumber(area.centerY) or 0));
            local distance = math.sqrt((dx * dx) + (dz * dz));

            if (radius > 0 and distance <= radius and (height <= 0 or dy <= height)) then
                if (best == nil or radius < (tonumber(best.radius) or 999999)) then
                    best = area;
                end
            end
        end
    end

    return best or wholeZone;
end

function database.GetTargetFishOptions(zoneId, position, selectedName)
    local area = database.GetFishingArea(zoneId, position);
    local options = {};
    local fallback = false;

    if (area ~= nil) then
        options = GetAreaFish(zoneId, area.area);
    else
        options = GetZoneFish(zoneId);
        fallback = #options > 0;
        if (fallback == true) then
            area = {
                area = 0,
                name = 'Zone',
                fallback = true,
            };
        end
    end

    local selectedKey = CleanName(selectedName):lower();
    for _, option in ipairs(options) do
        option.selected = selectedKey ~= '' and CleanName(option.name):lower() == selectedKey;
    end

    return {
        zoneId = tonumber(zoneId) or 0,
        area = area,
        fallback = fallback,
        options = options,
    };
end

local function ReadFishingSkillBase()
    local okPlayer, player = pcall(function()
        return AshitaCore:GetMemoryManager():GetPlayer();
    end);

    if (okPlayer ~= true or player == nil or type(player.GetCraftSkill) ~= 'function') then
        return nil;
    end

    local okCraft, craftSkill = pcall(function()
        return player:GetCraftSkill(0);
    end);

    if (okCraft ~= true or craftSkill == nil or type(craftSkill.GetSkill) ~= 'function') then
        return nil;
    end

    local okSkill, skill = pcall(function()
        return craftSkill:GetSkill();
    end);

    if (okSkill ~= true or type(skill) ~= 'number') then
        return nil;
    end

    return skill;
end

function database.GetFishingSkill()
    local base = ReadFishingSkillBase();
    if (base == nil) then
        return nil;
    end

    local level = math.min(110, math.max(0, math.floor((tonumber(base) or 0) + 0.0001)));
    local rank = 'Amateur';

    for _, row in ipairs(ranks) do
        if (level >= row.min and level <= row.max) then
            rank = row.name;
            break;
        end
    end

    return {
        level = level,
        cap = 110,
        rank = rank,
    };
end

function database.FindFish(fishName)
    if (Load() ~= true) then
        return nil;
    end

    return byFish[NormalizeName(fishName)];
end

function database.GetKnownGearNames(kind)
    if (Load() ~= true) then
        return {};
    end

    return tostring(kind or '') == 'bait' and knownBaits or knownRods;
end

function database.IsKnownGear(kind, name)
    local set = database.GetKnownGearNames(kind);
    return set[NormalizeName(name)] ~= nil;
end

function database.GetGearNameById(kind, itemId)
    if (LoadGear() == true) then
        local rows = tostring(kind or '') == 'rod' and gearRows.rods or gearRows.baits;
        local row = rows ~= nil and rows[tonumber(itemId) or 0] or nil;
        if (row ~= nil and CleanName(row.name) ~= '') then
            return CleanName(row.name);
        end
    end

    if (tostring(kind or '') == 'rod') then
        return rodNamesById[tonumber(itemId) or 0];
    end

    if (tostring(kind or '') == 'bait') then
        return baitNamesById[tonumber(itemId) or 0];
    end

    return nil;
end

function database.IsKnownGearById(kind, itemId)
    return database.GetGearNameById(kind, itemId) ~= nil;
end

function database.GetSuggestedGear(zoneName, fishName, fishId)
    local result = {
        zone = CleanName(zoneName),
        fish = CleanName(fishName),
        rods = {},
        baits = {},
    };

    if (LoadGear() ~= true) then
        return result;
    end

    local fish, resolvedFishId = GetGearFish(fishName, fishId);
    if (fish ~= nil or tonumber(fishId) ~= nil) then
        result.rodSource = 'lsb';
        AddRodSuggestions(result.rods, fishName, resolvedFishId or fishId);

        result.baitSource = 'affinity';
        AddAffinityBaits(result.baits, fishName, resolvedFishId or fishId);
    end

    return result;
end

function database.GetCanonicalGearName(kind, name)
    local set = database.GetKnownGearNames(kind);
    return set[NormalizeName(name)] or CleanName(name);
end

function database.GetCanonicalGearNameById(kind, itemId, fallbackName)
    return database.GetGearNameById(kind, itemId) or database.GetCanonicalGearName(kind, fallbackName);
end

function database.GetRecommendation(fishName, rodName, baitName)
    local fish, fishId = GetGearFish(fishName, nil);
    if (fish == nil) then
        return nil;
    end

    local rod = CleanName(rodName);
    local bait = CleanName(baitName);
    local rodMatch = nil;
    local baitMatch = nil;
    local rods = {};
    local baits = {};
    AddRodSuggestions(rods, fishName, fishId);
    AddAffinityBaits(baits, fishName, fishId);

    if (rod ~= '' and rod ~= 'None') then
        rodMatch = rods[NormalizeName(rod)] ~= nil;
    end

    if (bait ~= '' and bait ~= 'None') then
        baitMatch = baits[NormalizeName(bait)] ~= nil;
    end

    return {
        found = true,
        fish = CleanName(fish.name),
        level = tonumber(fish.level) or 0,
        band = nil,
        rank = nil,
        rodMatch = rodMatch,
        baitMatch = baitMatch,
        rods = FirstNames(rods, 4),
        baits = FirstNames(baits, 4),
    };
end

return database;
