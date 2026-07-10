require('common');

local log = require('core.log');

local ephemeralBox = {};

local pending = nil;
local queue = {};
local cache = {
    categories = {},
    categoryOrder = {},
};
local cacheLoadedFor = nil;
local browseCategory = nil;
local debugEnabled = false;
local lastStatus = '';
local pendingExtracts = {};
local cacheDirty = false;
local CACHE_SCAN_VERSION = 2;
local QueueNextFullScanCategory = nil;
local suppressTellErrorUntil = 0;

local function SetStatus(message)
    lastStatus = tostring(message or '');
end

local function Now()
    return os.clock();
end

local function QueueAction(delay, fn)
    queue[#queue + 1] = {
        at = Now() + math.max(0, tonumber(delay) or 0),
        fn = fn,
    };
end

local function PacketStrings(data)
    local strings = {};
    local current = {};

    if (type(data) ~= 'string') then
        return strings;
    end

    for index = 1, #data do
        local byte = string.byte(data, index);
        if (byte ~= nil and byte >= 32 and byte <= 126) then
            current[#current + 1] = string.char(byte);
        elseif (#current > 0) then
            local text = table.concat(current):gsub('^%s+', ''):gsub('%s+$', '');
            if (text ~= '') then
                strings[#strings + 1] = text;
            end
            current = {};
        end
    end

    if (#current > 0) then
        local text = table.concat(current):gsub('^%s+', ''):gsub('%s+$', '');
        if (text ~= '') then
            strings[#strings + 1] = text;
        end
    end

    return strings;
end

local function CleanMenuText(value)
    return tostring(value or '')
        :gsub('^%s+', '')
        :gsub('%s+$', '')
        :gsub('^"+', '')
        :gsub('"+$', '')
        :gsub('^%s+', '')
        :gsub('%s+$', '');
end

local function NormalizeItemText(value)
    return tostring(value or ''):lower():gsub('[^%w]+', '');
end

local resolvedItemCache = {};
local resourceItemNameIndex = nil;

local function ReadResourceValue(resource, keys)
    if (resource == nil or type(keys) ~= 'table') then
        return nil;
    end

    for _, key in ipairs(keys) do
        local ok, value = pcall(function()
            local field = resource[key];
            if (type(field) == 'table') then
                return field[1] or field[0] or field.en or field.En or field.English or field.english;
            end
            return field;
        end);

        if (ok == true and value ~= nil and tostring(value) ~= '' and tostring(value):find('userdata:', 1, true) == nil) then
            return value;
        end
    end

    return nil;
end

local function GetResourceItemId(resource)
    return tonumber(ReadResourceValue(resource, { 'Id', 'ID', 'id', 'ItemId', 'itemId', 'item_id' })) or 0;
end

local function GetResourceItemCategory(resource)
    local category = ReadResourceValue(resource, { 'Category', 'category', 'Type', 'type', 'AHCategory', 'ahCategory', 'AuctionHouseCategory' });
    return category ~= nil and tostring(category) or '';
end

local function GetResourceItemDisplayName(resource, fallback)
    local name = ReadResourceValue(resource, {
        'Name',
        'NameSingular',
        'LogNameSingular',
        'En',
        'en',
        'English',
        'english',
        'DisplayName',
        'displayName',
    });

    name = CleanMenuText(name);
    if (name ~= '') then
        return name;
    end

    return CleanMenuText(fallback);
end

local function ResourceMatchesItemName(resource, itemName)
    local expected = NormalizeItemText(itemName);
    if (expected == '') then
        return false;
    end

    local candidates = {
        GetResourceItemDisplayName(resource, ''),
        ReadResourceValue(resource, { 'Name' }),
        ReadResourceValue(resource, { 'NameSingular' }),
        ReadResourceValue(resource, { 'LogNameSingular' }),
        ReadResourceValue(resource, { 'En', 'en', 'English', 'english' }),
    };

    for _, candidate in ipairs(candidates) do
        if (NormalizeItemText(candidate) == expected) then
            return true;
        end
    end

    return false;
end

local function AddResourceItemIndexName(index, resource, name)
    local key = NormalizeItemText(name);
    if (key == '' or index[key] ~= nil) then
        return;
    end

    local itemId = GetResourceItemId(resource);
    if (itemId <= 0) then
        return;
    end

    index[key] = {
        itemId = itemId,
        name = GetResourceItemDisplayName(resource, name),
        serverCategory = GetResourceItemCategory(resource),
    };
end

local function GetResourceItemNameIndex(resourceManager)
    if (resourceItemNameIndex ~= nil) then
        return resourceItemNameIndex;
    end

    local index = {};
    local getById = resourceManager ~= nil and resourceManager.GetItemById or nil;
    if (type(getById) ~= 'function') then
        resourceItemNameIndex = index;
        return resourceItemNameIndex;
    end

    for itemId = 1, 65535 do
        local ok, resource = pcall(function()
            return getById(resourceManager, itemId);
        end);
        if (ok == true and resource ~= nil and GetResourceItemId(resource) > 0) then
            AddResourceItemIndexName(index, resource, GetResourceItemDisplayName(resource, ''));
            AddResourceItemIndexName(index, resource, ReadResourceValue(resource, { 'Name' }));
            AddResourceItemIndexName(index, resource, ReadResourceValue(resource, { 'NameSingular' }));
            AddResourceItemIndexName(index, resource, ReadResourceValue(resource, { 'LogNameSingular' }));
            AddResourceItemIndexName(index, resource, ReadResourceValue(resource, { 'En', 'en', 'English', 'english' }));
        end
    end

    resourceItemNameIndex = index;
    return resourceItemNameIndex;
end

local function ResolveRealItem(itemName)
    itemName = CleanMenuText(itemName);
    if (itemName == '') then
        return nil;
    end

    local key = NormalizeItemText(itemName);
    if (resolvedItemCache[key] ~= nil) then
        return resolvedItemCache[key] ~= false and resolvedItemCache[key] or nil;
    end

    local resourceManager = nil;
    pcall(function()
        resourceManager = AshitaCore:GetResourceManager();
    end);

    if (resourceManager == nil) then
        resolvedItemCache[key] = false;
        return nil;
    end

    local candidates = {};
    local methods = {
        { 'GetItemByName', { itemName } },
        { 'GetItemByName', { itemName, 0 } },
        { 'GetItemByName', { itemName, 1 } },
        { 'GetItemByName', { itemName:lower() } },
    };

    for _, methodInfo in ipairs(methods) do
        local method = resourceManager[methodInfo[1]];
        if (type(method) == 'function') then
            local ok, resource = pcall(function()
                return method(resourceManager, unpack(methodInfo[2]));
            end);
            if (ok == true and resource ~= nil) then
                candidates[#candidates + 1] = resource;
            end
        end
    end

    for _, resource in ipairs(candidates) do
        if (ResourceMatchesItemName(resource, itemName) == true) then
            local itemId = GetResourceItemId(resource);
            if (itemId > 0) then
                local resolved = {
                    itemId = itemId,
                    name = GetResourceItemDisplayName(resource, itemName),
                    serverCategory = GetResourceItemCategory(resource),
                };
                resolvedItemCache[key] = resolved;
                return resolved;
            end
        end
    end

    local indexed = GetResourceItemNameIndex(resourceManager)[key];
    if (indexed ~= nil and tonumber(indexed.itemId) ~= nil and tonumber(indexed.itemId) > 0) then
        resolvedItemCache[key] = indexed;
        return indexed;
    end

    resolvedItemCache[key] = false;
    return nil;
end

local function GetCustomMenu(data)
    local strings = PacketStrings(data);
    local menuIndex = nil;

    local packedText = table.concat(strings, '|');
    local markerStart = packedText:find('_CUSTOM_MENU', 1, true);
    if (markerStart ~= nil) then
        local tail = packedText:sub(markerStart + #'_CUSTOM_MENU');
        tail = tail:gsub('^[%"|%s]+', '');

        local packedQuestion, packedRest = tail:match('^(.-)""(.*)$');
        if (packedQuestion ~= nil and packedQuestion ~= '') then
            local options = {};
            local rest = packedRest;

            while (rest ~= nil and rest ~= '') do
                local option, remaining = rest:match('^([^"]*)""(.*)$');
                if (option == nil) then
                    option = rest;
                    remaining = '';
                end

                option = CleanMenuText(option);
                if (option ~= '') then
                    options[#options + 1] = option;
                end

                rest = remaining;
            end

            return {
                question = CleanMenuText(packedQuestion),
                options = options,
            };
        end
    end

    for index, value in ipairs(strings) do
        if (value == '_CUSTOM_MENU') then
            menuIndex = index;
            break;
        end
    end

    if (menuIndex == nil or strings[menuIndex + 1] == nil) then
        for index, value in ipairs(strings) do
            if (value == 'Select a category:' or value == 'Select an item:') then
                local options = {};
                for optionIndex = index + 1, #strings do
                    local option = CleanMenuText(strings[optionIndex]);
                    if (option ~= '') then
                        options[#options + 1] = option;
                    end
                end

                return {
                    question = value,
                    options = options,
                };
            end
        end

        return nil;
    end

    local options = {};
    for index = menuIndex + 2, #strings do
        local option = CleanMenuText(strings[index]);
        if (option ~= '') then
            options[#options + 1] = option;
        end
    end

    return {
        question = CleanMenuText(strings[menuIndex + 1]),
        options = options,
    };
end

local function ParseCustomAnswer(data)
    local text = table.concat(PacketStrings(data), ' ');
    local question, result = text:match('Question%((.-)%)%: Result %((.*)%)');

    if (question == nil or result == nil) then
        return nil;
    end

    return {
        question = question,
        result = result,
    };
end

local function GetPlayerName()
    local name = nil;

    pcall(function()
        local party = AshitaCore:GetMemoryManager():GetParty();
        name = party ~= nil and party:GetMemberName(0) or nil;
    end);

    return tostring(name or '');
end

local function SanitizePathPart(value)
    value = tostring(value or '');
    value = value:gsub('[\\/:*?"<>|]', '_');
    value = value:gsub('%s+', '_');
    value = value:gsub('[^%w_%-]', '_');

    if (value == '') then
        return nil;
    end

    return value;
end

local function GetCharacterCacheKey()
    local name = nil;
    local serverId = nil;

    pcall(function()
        local memory = AshitaCore:GetMemoryManager();
        local party = memory ~= nil and memory:GetParty() or nil;
        if (party ~= nil) then
            name = party:GetMemberName(0);
            serverId = party:GetMemberServerId(0);
        end
    end);

    name = SanitizePathPart(name);
    serverId = tonumber(serverId) or 0;

    if (name == nil or serverId <= 0) then
        return nil;
    end

    return name .. '_' .. tostring(serverId);
end

local function EnsureFolder(folder)
    local exists = false;

    pcall(function()
        exists = ashita.fs.exists(folder);
    end);

    if (exists == true) then
        return true;
    end

    local ok = pcall(function()
        if (ashita.fs.create_dir ~= nil) then
            ashita.fs.create_dir(folder);
        elseif (ashita.fs.create_directory ~= nil) then
            ashita.fs.create_directory(folder);
        end
    end);

    return ok == true;
end

local function GetCacheFolder()
    local key = GetCharacterCacheKey();
    if (key == nil) then
        return nil, nil;
    end

    return AshitaCore:GetInstallPath() .. '\\config\\addons\\LibraPlates\\' .. key, key;
end

local function GetCachePath()
    local folder, key = GetCacheFolder();
    if (folder == nil) then
        return nil, nil;
    end

    return folder .. '\\ephemeral_box_cache.lua', key, folder;
end

local function BuildNpcPokePacket(serverId, targetIndex)
    return struct.pack(
        'bbbbihhhhfff',
        0x1A,
        0x07,
        0x00,
        0x00,
        tonumber(serverId) or 0,
        tonumber(targetIndex) or 0,
        0x00,
        0x00,
        0x00,
        0.0,
        0.0,
        0.0
    ):totable();
end

local function BuildCustomMenuPacket(question, result)
    local menuName = '_CUSTOM_MENU';
    local message = menuName .. string.char(0x00, 0x00, 0x00) .. 'GMTELL(' .. GetPlayerName() .. '): Question(' .. tostring(question or '') .. '): Result (' .. tostring(result or '') .. ')';
    local packetSize = 6 + #message + 1;
    if ((packetSize % 2) ~= 0) then
        packetSize = packetSize + 1;
    end

    local bytes = {
        0xB6,
        math.floor(packetSize / 2),
        0x00,
        0x00,
        0x03,
        0x00,
    };

    for index = 1, #message do
        bytes[#bytes + 1] = string.byte(message, index);
    end

    bytes[#bytes + 1] = 0x00;
    while (#bytes < packetSize) do
        bytes[#bytes + 1] = 0x00;
    end

    return bytes;
end

local function SendOutgoingPacket(id, packedData, description)
    if (packedData == nil) then
        return false;
    end

    local ok, err = pcall(function()
        AshitaCore:GetPacketManager():AddOutgoingPacket(id, packedData);
    end);

    if (ok ~= true) then
        log.Warn('Ephemeral Box packet failed ' .. tostring(description or '') .. ' id=0x' .. string.format('%03X', tonumber(id) or 0) .. ' err=' .. tostring(err));
        return false;
    end

    if (debugEnabled == true) then
        log.Info('Ephemeral Box sent packet ' .. tostring(description or '') .. ' id=0x' .. string.format('%03X', tonumber(id) or 0));
    end

    return true;
end

local function SendCustomAnswer(question, result, description)
    suppressTellErrorUntil = Now() + 10.0;
    return SendOutgoingPacket(0x0B6, BuildCustomMenuPacket(question, result), description);
end

local function ClearPendingAutomation()
    pending = nil;
    queue = {};
end

local function QueueCommand(command, mode)
    if (AshitaCore == nil or AshitaCore.GetChatManager == nil) then
        return;
    end

    AshitaCore:GetChatManager():QueueCommand(tonumber(mode) or 1, tostring(command or ''));
end

local function IsNavigationOption(option)
    local text = CleanMenuText(option):lower();
    return text == '(prev)' or text == '(next)' or text == 'prev' or text == 'next' or text == 'canceled.';
end

local function GetCategoryKey(category)
    return CleanMenuText(category):gsub('%s*%(%d+%)$', '');
end

local function IsNumericSuffix(value)
    return GetCategoryKey(value):match('^%d+$') ~= nil;
end

local function CleanFolderText(value)
    value = CleanMenuText(value);
    value = value:gsub('[%z\1-\31]', '');
    value = value:gsub('^%?+%s*', '');
    value = value:gsub('^[^%w]+%s*', '');
    value = value:gsub('^%s+', ''):gsub('%s+$', '');
    return value;
end

local function GetCategoryNativeCount(category)
    return tonumber(CleanMenuText(category):match('%((%d+)%)$'));
end

local function CategoryHasNativeCount(category)
    return CleanMenuText(category):match('%(%d+%)$') ~= nil;
end

local function CountMapEntries(value)
    local count = 0;
    if (type(value) ~= 'table') then
        return count;
    end

    for _, enabled in pairs(value) do
        if (enabled == true) then
            count = count + 1;
        end
    end

    return count;
end

local function GetSingleMapKey(value)
    local found = nil;
    if (type(value) ~= 'table') then
        return nil;
    end

    for key, enabled in pairs(value) do
        if (enabled == true) then
            if (found ~= nil) then
                return nil;
            end
            found = key;
        end
    end

    return found;
end

local function IsNestedStorageMenu(category, itemName)
    local categoryKey = GetCategoryKey(category):lower();
    local itemKey = CleanMenuText(itemName):lower();

    return categoryKey == 'ammo' and itemKey == 'thrown';
end

local function EnsureCategory(category)
    local displayName = CleanMenuText(category);
    local categoryKey = GetCategoryKey(displayName);
    if (categoryKey == '' or IsNavigationOption(displayName) == true) then
        return nil;
    end

    if (cache.categories[categoryKey] == nil) then
        cache.categories[categoryKey] = {
            name = displayName ~= '' and displayName or categoryKey,
            expectedCount = GetCategoryNativeCount(displayName),
            items = {},
            itemOrder = {},
        };
        cache.categoryOrder[#cache.categoryOrder + 1] = categoryKey;
        cacheDirty = true;
    elseif (CategoryHasNativeCount(displayName) == true and cache.categories[categoryKey].name ~= displayName) then
        cache.categories[categoryKey].name = displayName;
        cache.categories[categoryKey].expectedCount = GetCategoryNativeCount(displayName);
        cacheDirty = true;
    elseif (CategoryHasNativeCount(displayName) == true and cache.categories[categoryKey].expectedCount ~= GetCategoryNativeCount(displayName)) then
        cache.categories[categoryKey].expectedCount = GetCategoryNativeCount(displayName);
        cacheDirty = true;
    end

    return cache.categories[categoryKey];
end

local function MoveNumericNestedItemsToCategory(categoryKey)
    categoryKey = GetCategoryKey(categoryKey);
    if (categoryKey == '') then
        return;
    end

    local parentKey, numericSuffix = categoryKey:match('^(.-)%s+(%d+)$');
    parentKey = CleanMenuText(parentKey);
    if (parentKey == '' or numericSuffix == nil) then
        return;
    end

    local parent = cache.categories[parentKey];
    local target = cache.categories[categoryKey];
    if (parent == nil or target == nil or type(parent.items) ~= 'table') then
        return;
    end

    target.items = target.items or {};
    target.itemOrder = target.itemOrder or {};

    for index = #(parent.itemOrder or {}), 1, -1 do
        local itemName = parent.itemOrder[index];
        local item = parent.items[itemName];
        if (item ~= nil and GetCategoryKey(item.nestedMenu or '') == numericSuffix) then
            item.nestedMenu = '';
            if (target.items[itemName] == nil) then
                target.items[itemName] = item;
                target.itemOrder[#target.itemOrder + 1] = itemName;
            else
                target.items[itemName].total = item.total;
            end
            parent.items[itemName] = nil;
            table.remove(parent.itemOrder, index);
            cacheDirty = true;
        end
    end
end

local function ResolveStoredCategoryPath(category)
    local cleanCategory = CleanMenuText(category);
    if (cleanCategory == '') then
        return '', '';
    end

    local exactKey = GetCategoryKey(cleanCategory);
    if (cache.categories[exactKey] ~= nil) then
        return cache.categories[exactKey].name or exactKey, '';
    end

    local exactBase = GetCategoryKey(cleanCategory);
    local exactParent, exactSuffix = exactBase:match('^(.-)%s+(%d+)$');
    exactParent = CleanMenuText(exactParent);
    if (exactParent ~= '' and exactSuffix ~= nil) then
        return cleanCategory, '';
    end

    local bestParent = nil;
    local bestNested = '';
    for _, categoryName in ipairs(cache.categoryOrder or {}) do
        local parent = cache.categories[categoryName];
        local parentName = CleanMenuText(parent ~= nil and parent.name or categoryName);
        local parentKey = GetCategoryKey(parentName);
        for _, candidate in ipairs({ parentKey, parentName }) do
            candidate = CleanMenuText(candidate);
            if (candidate ~= '' and cleanCategory:sub(1, #candidate + 1) == candidate .. ' ') then
                local nested = CleanMenuText(cleanCategory:sub(#candidate + 2));
                if (nested ~= '' and IsNumericSuffix(nested) ~= true and (bestParent == nil or #candidate > #GetCategoryKey(bestParent))) then
                    bestParent = parentName ~= '' and parentName or parentKey;
                    bestNested = nested;
                end
            end
        end
    end

    return bestParent or cleanCategory, bestNested;
end

local function UpsertItem(category, itemName, total, nestedMenu)
    local resolvedCategory, resolvedNested = ResolveStoredCategoryPath(category);
    if (CleanMenuText(nestedMenu) == '' and resolvedNested ~= '') then
        nestedMenu = resolvedNested;
    end

    local categoryEntry = EnsureCategory(resolvedCategory);
    itemName = tostring(itemName or ''):gsub('^%s+', ''):gsub('%s+$', '');
    nestedMenu = CleanFolderText(nestedMenu);

    if (categoryEntry == nil or itemName == '') then
        return;
    end
    if (IsNestedStorageMenu(resolvedCategory, itemName) == true or (categoryEntry.nestedMenus ~= nil and categoryEntry.nestedMenus[itemName] == true)) then
        return;
    end

    local resolvedItem = ResolveRealItem(itemName);

    if (categoryEntry.items[itemName] == nil) then
        categoryEntry.items[itemName] = {
            itemId = resolvedItem ~= nil and resolvedItem.itemId or nil,
            name = resolvedItem ~= nil and resolvedItem.name ~= '' and resolvedItem.name or itemName,
            total = tonumber(total),
            nestedMenu = nestedMenu,
            serverCategory = resolvedItem ~= nil and resolvedItem.serverCategory or '',
            verified = resolvedItem ~= nil,
        };
        categoryEntry.itemOrder[#categoryEntry.itemOrder + 1] = itemName;
        cacheDirty = true;
    else
        local oldTotal = categoryEntry.items[itemName].total;
        categoryEntry.items[itemName].total = tonumber(total) or categoryEntry.items[itemName].total;
        if (nestedMenu ~= '' and categoryEntry.items[itemName].nestedMenu ~= nestedMenu) then
            categoryEntry.items[itemName].nestedMenu = nestedMenu;
            cacheDirty = true;
        end
        if (resolvedItem ~= nil and categoryEntry.items[itemName].itemId == nil and resolvedItem.itemId ~= nil) then
            categoryEntry.items[itemName].itemId = resolvedItem.itemId;
            cacheDirty = true;
        end
        if (resolvedItem ~= nil and categoryEntry.items[itemName].serverCategory ~= resolvedItem.serverCategory) then
            categoryEntry.items[itemName].serverCategory = resolvedItem.serverCategory;
            cacheDirty = true;
        end
        if (resolvedItem ~= nil) then
            categoryEntry.items[itemName].verified = true;
        end
        if (oldTotal ~= categoryEntry.items[itemName].total) then
            cacheDirty = true;
        end
    end
end

local function FindExistingParentCategory(categoryName)
    local cleanCategory = CleanMenuText(categoryName);
    local bestParent = nil;
    local bestNested = '';

    for _, parentKey in ipairs(cache.categoryOrder or {}) do
        if (parentKey ~= categoryName) then
            local parent = cache.categories[parentKey];
            local parentName = CleanMenuText(parent ~= nil and parent.name or parentKey);
            local parentBase = GetCategoryKey(parentName);
            for _, candidate in ipairs({ parentBase, parentName, parentKey }) do
                candidate = CleanMenuText(candidate);
                if (candidate ~= '' and cleanCategory:sub(1, #candidate + 1) == candidate .. ' ') then
                    local nested = CleanMenuText(cleanCategory:sub(#candidate + 2));
                    if (nested ~= '' and IsNumericSuffix(nested) ~= true and (bestParent == nil or #candidate > #GetCategoryKey(bestParent))) then
                        bestParent = parentName ~= '' and parentName or parentKey;
                        bestNested = nested;
                    end
                end
            end
        end
    end

    return bestParent, bestNested;
end

local function CollapseDerivedCategories()
    for _, categoryName in ipairs(cache.categoryOrder or {}) do
        local category = cache.categories[categoryName];
        if (category ~= nil) then
            local parent, nested = FindExistingParentCategory(categoryName);
            if (parent ~= nil and nested ~= '') then
                for _, itemName in ipairs(category.itemOrder or {}) do
                    local item = category.items ~= nil and category.items[itemName] or nil;
                    if (item ~= nil and (tonumber(item.total) or 0) > 0) then
                        UpsertItem(parent, item.name or itemName, item.total, nested);
                    end
                end
                cache.categories[categoryName] = nil;
                cacheDirty = true;
            end
        end
    end
end

local function PruneCache()
    CollapseDerivedCategories();

    local newOrder = {};
    local seen = {};
    for _, categoryName in ipairs(cache.categoryOrder or {}) do
        local cleanName = CleanMenuText(categoryName);
        local category = cache.categories[categoryName];
        local categoryKey = GetCategoryKey(cleanName);
        if (categoryKey ~= '' and IsNavigationOption(cleanName) ~= true and category ~= nil) then
            if (cache.categories[categoryKey] == nil) then
                cache.categories[categoryKey] = category;
                cache.categories[categoryName] = nil;
            elseif (categoryKey ~= categoryName) then
                local target = cache.categories[categoryKey];
                if (CategoryHasNativeCount(category.name) == true) then
                    target.name = category.name;
                end
                for _, itemName in ipairs(category.itemOrder or {}) do
                    if (target.items[itemName] == nil) then
                        target.items[itemName] = category.items[itemName];
                        target.itemOrder[#target.itemOrder + 1] = itemName;
                    end
                end
                cache.categories[categoryName] = nil;
            end

            local displayName = CleanMenuText(cache.categories[categoryKey].name);
            if (displayName == '') then
                cache.categories[categoryKey].name = categoryKey;
            end
            if (cache.categories[categoryKey].expectedCount == nil) then
                cache.categories[categoryKey].expectedCount = GetCategoryNativeCount(cache.categories[categoryKey].name);
            end
            if (type(cache.categories[categoryKey].nestedMenus) == 'table') then
                local cleanNestedMenus = {};
                for nestedName, enabled in pairs(cache.categories[categoryKey].nestedMenus) do
                    local cleanNested = CleanFolderText(nestedName);
                    if (enabled == true and cleanNested ~= '') then
                        cleanNestedMenus[cleanNested] = true;
                    end
                end
                cache.categories[categoryKey].nestedMenus = cleanNestedMenus;
            end
            for index = #(cache.categories[categoryKey].itemOrder or {}), 1, -1 do
                local itemName = cache.categories[categoryKey].itemOrder[index];
                local item = cache.categories[categoryKey].items[itemName];
                if (IsNestedStorageMenu(categoryKey, itemName) == true) then
                    cache.categories[categoryKey].nestedMenus = cache.categories[categoryKey].nestedMenus or {};
                    cache.categories[categoryKey].nestedMenus[itemName] = true;
                end
                if (item ~= nil) then
                    local cleanNested = CleanFolderText(item.nestedMenu or '');
                    if (item.nestedMenu ~= cleanNested) then
                        item.nestedMenu = cleanNested;
                        cacheDirty = true;
                    end
                end
                local resolvedItem = nil;
                if (item ~= nil and item.itemId == nil) then
                    resolvedItem = ResolveRealItem(itemName);
                    if (resolvedItem ~= nil) then
                        item.itemId = resolvedItem.itemId;
                        item.serverCategory = resolvedItem.serverCategory;
                        item.verified = true;
                        cacheDirty = true;
                    end
                end
                if (
                    item == nil or
                    (tonumber(item.total) or 0) <= 0 or
                    IsNestedStorageMenu(categoryKey, itemName) == true or
                    (cache.categories[categoryKey].nestedMenus ~= nil and cache.categories[categoryKey].nestedMenus[itemName] == true)
                ) then
                    cache.categories[categoryKey].items[itemName] = nil;
                    table.remove(cache.categories[categoryKey].itemOrder, index);
                    cacheDirty = true;
                end
            end
            if (seen[categoryKey] ~= true) then
                seen[categoryKey] = true;
                newOrder[#newOrder + 1] = categoryKey;
            end
        else
            cache.categories[categoryName] = nil;
        end
    end
    cache.categoryOrder = newOrder;
end

local function HydrateItemOrders()
    for _, categoryName in ipairs(cache.categoryOrder or {}) do
        local category = cache.categories[categoryName];
        if (category ~= nil and #(category.itemOrder or {}) <= 0 and type(category.items) == 'table') then
            local itemNames = {};
            for itemName, item in pairs(category.items) do
                local cleanItem = CleanMenuText(itemName);
                if (cleanItem ~= '' and type(item) == 'table' and (tonumber(item.total) or 0) > 0) then
                    if (type(item) == 'table') then
                        item.name = CleanMenuText(item.name);
                        if (item.name == '') then
                            item.name = cleanItem;
                        end
                    end
                    itemNames[#itemNames + 1] = cleanItem;
                end
            end

            table.sort(itemNames);
            category.itemOrder = itemNames;
        end
    end
end

local function QuoteLua(value)
    return string.format('%q', tostring(value or ''));
end

local function SaveCache()
    PruneCache();

    local path, key, folder = GetCachePath();
    if (path == nil or folder == nil) then
        SetStatus('E.Box cache save failed: character path unavailable.');
        log.Warn('Ephemeral Box cache save failed: character path unavailable.');
        return false;
    end

    EnsureFolder(AshitaCore:GetInstallPath() .. '\\config');
    EnsureFolder(AshitaCore:GetInstallPath() .. '\\config\\addons');
    EnsureFolder(AshitaCore:GetInstallPath() .. '\\config\\addons\\LibraPlates');
    local folderOk = EnsureFolder(folder);
    if (folderOk ~= true) then
        log.Warn('Ephemeral Box cache folder check failed, trying write anyway: ' .. tostring(folder));
    end

    local file = io.open(path, 'w');
    if (file == nil and folderOk ~= true) then
        EnsureFolder(folder);
        file = io.open(path, 'w');
    end

    if (file == nil) then
        SetStatus('E.Box cache save failed: ' .. tostring(path));
        log.Warn('Ephemeral Box cache save failed: ' .. tostring(path));
        return false;
    end

    file:write('return {\n');
    file:write('  version = 1,\n');
    file:write('  savedAt = ', tostring(os.time()), ',\n');
    file:write('  categoryOrder = {\n');
    for _, categoryName in ipairs(cache.categoryOrder or {}) do
        file:write('    ', QuoteLua(categoryName), ',\n');
    end
    file:write('  },\n');
    file:write('  categories = {\n');
    for _, categoryName in ipairs(cache.categoryOrder or {}) do
        local category = cache.categories[categoryName];
        if (category ~= nil) then
            file:write('    [', QuoteLua(categoryName), '] = {\n');
            file:write('      name = ', QuoteLua(category.name or categoryName), ',\n');
            file:write('      expectedCount = ', tostring(tonumber(category.expectedCount) or 0), ',\n');
            file:write('      scanVersion = ', tostring(tonumber(category.scanVersion) or 0), ',\n');
            file:write('      nestedMenus = {\n');
            if (type(category.nestedMenus) == 'table') then
                local nestedNames = {};
                for nestedName, enabled in pairs(category.nestedMenus) do
                    if (enabled == true) then
                        nestedNames[#nestedNames + 1] = nestedName;
                    end
                end
                table.sort(nestedNames);
                for _, nestedName in ipairs(nestedNames) do
                    local cleanNested = CleanFolderText(nestedName);
                    if (cleanNested ~= '') then
                        file:write('        [', QuoteLua(cleanNested), '] = true,\n');
                    end
                end
            end
            file:write('      },\n');
            file:write('      itemOrder = {\n');
            for _, itemName in ipairs(category.itemOrder or {}) do
                file:write('        ', QuoteLua(itemName), ',\n');
            end
            file:write('      },\n');
            file:write('      items = {\n');
            for _, itemName in ipairs(category.itemOrder or {}) do
                local item = category.items[itemName];
                if (item ~= nil) then
                    file:write(
                        '        [',
                        QuoteLua(itemName),
                        '] = { itemId = ',
                        tostring(math.max(0, tonumber(item.itemId) or 0)),
                        ', name = ',
                        QuoteLua(item.name or itemName),
                        ', total = ',
                        tostring(math.max(0, tonumber(item.total) or 0)),
                        ', nestedMenu = ',
                        QuoteLua(CleanFolderText(item.nestedMenu or '')),
                        ', serverCategory = ',
                        QuoteLua(item.serverCategory or ''),
                        ', verified = ',
                        (tonumber(item.itemId) ~= nil and tonumber(item.itemId) > 0 and 'true' or 'false'),
                        ' },\n'
                    );
                end
            end
            file:write('      },\n');
            file:write('    },\n');
        end
    end
    file:write('  },\n');
    file:write('}\n');
    file:close();

    cacheLoadedFor = key;
    cacheDirty = false;
    return true;
end

local function LoadCache()
    local path, key = GetCachePath();
    if (path == nil) then
        return false;
    end

    local loader = loadfile(path);
    if (loader == nil) then
        cacheLoadedFor = key;
        return false;
    end

    local ok, loaded = pcall(loader);
    if (ok ~= true or type(loaded) ~= 'table' or type(loaded.categories) ~= 'table') then
        cacheLoadedFor = key;
        return false;
    end

    cache = {
        categories = {},
        categoryOrder = {},
    };

    for _, categoryName in ipairs(loaded.categoryOrder or {}) do
        local cleanCategory = CleanMenuText(categoryName);
        local categoryKey = GetCategoryKey(cleanCategory);
        local loadedCategory = loaded.categories[categoryName] or loaded.categories[cleanCategory] or loaded.categories[categoryKey];
        if (categoryKey ~= '' and IsNavigationOption(cleanCategory) ~= true and type(loadedCategory) == 'table') then
            local displayName = CleanMenuText(loadedCategory.name);
            if (displayName == '') then
                displayName = cleanCategory;
            end

            local categoryEntry = EnsureCategory(displayName);
            if (categoryEntry ~= nil and CategoryHasNativeCount(displayName) ~= true and CategoryHasNativeCount(cleanCategory) == true) then
                categoryEntry.name = cleanCategory;
            end
            if (categoryEntry ~= nil) then
                categoryEntry.expectedCount = tonumber(loadedCategory.expectedCount) or GetCategoryNativeCount(categoryEntry.name);
                categoryEntry.scanVersion = tonumber(loadedCategory.scanVersion) or 0;
                categoryEntry.nestedMenus = {};
                if (type(loadedCategory.nestedMenus) == 'table') then
                    for nestedName, enabled in pairs(loadedCategory.nestedMenus) do
                        local cleanNested = CleanFolderText(nestedName);
                        if (enabled == true and cleanNested ~= '') then
                            categoryEntry.nestedMenus[cleanNested] = true;
                        end
                    end
                end
            end

            for _, itemName in ipairs(loadedCategory.itemOrder or {}) do
                local item = loadedCategory.items ~= nil and loadedCategory.items[itemName] or nil;
                local cleanItem = CleanMenuText(itemName);
                if (categoryEntry ~= nil and cleanItem ~= '' and type(item) == 'table' and (categoryEntry.nestedMenus == nil or categoryEntry.nestedMenus[cleanItem] ~= true)) then
                    local itemId = tonumber(item.itemId) or nil;
                    if (itemId ~= nil and itemId <= 0) then
                        itemId = nil;
                    end
                    local resolvedItem = nil;
                    if (itemId == nil) then
                        resolvedItem = ResolveRealItem(cleanItem);
                    end
                    if (categoryEntry.items[cleanItem] == nil) then
                        categoryEntry.items[cleanItem] = {
                            itemId = itemId or (resolvedItem ~= nil and resolvedItem.itemId or nil),
                            name = CleanMenuText(item.name) ~= '' and CleanMenuText(item.name) or (resolvedItem ~= nil and resolvedItem.name or cleanItem),
                            total = math.max(0, tonumber(item.total) or 0),
                            nestedMenu = CleanFolderText(item.nestedMenu),
                            serverCategory = CleanMenuText(item.serverCategory) ~= '' and CleanMenuText(item.serverCategory) or (resolvedItem ~= nil and resolvedItem.serverCategory or ''),
                            verified = itemId ~= nil or resolvedItem ~= nil,
                        };
                        categoryEntry.itemOrder[#categoryEntry.itemOrder + 1] = cleanItem;
                    else
                        categoryEntry.items[cleanItem].total = math.max(0, tonumber(item.total) or 0);
                        categoryEntry.items[cleanItem].nestedMenu = CleanFolderText(item.nestedMenu);
                        categoryEntry.items[cleanItem].itemId = itemId or categoryEntry.items[cleanItem].itemId or (resolvedItem ~= nil and resolvedItem.itemId or nil);
                        categoryEntry.items[cleanItem].serverCategory = CleanMenuText(item.serverCategory) ~= '' and CleanMenuText(item.serverCategory) or categoryEntry.items[cleanItem].serverCategory;
                        categoryEntry.items[cleanItem].verified = itemId ~= nil or resolvedItem ~= nil or categoryEntry.items[cleanItem].verified == true;
                    end
                end
            end
        end
    end

    cacheLoadedFor = key;
    HydrateItemOrders();
    for _, categoryName in ipairs(cache.categoryOrder or {}) do
        MoveNumericNestedItemsToCategory(categoryName);
    end
    PruneCache();
    cacheDirty = false;
    return true;
end

local function EnsureCacheLoaded()
    local _, key = GetCachePath();
    if (key == nil or cacheLoadedFor == key or pending ~= nil) then
        return;
    end

    LoadCache();
end

local function ResetCache()
    cache = {
        categories = {},
        categoryOrder = {},
    };
    cacheDirty = true;
end

local function AdjustItemTotal(category, itemName, delta)
    local categoryEntry = cache.categories[GetCategoryKey(category)];
    local item = categoryEntry ~= nil and categoryEntry.items[tostring(itemName or '')] or nil;
    if (item == nil or item.total == nil) then
        return;
    end

    local oldTotal = item.total;
    local newTotal = math.max(0, (tonumber(item.total) or 0) + (tonumber(delta) or 0));
    if (newTotal <= 0) then
        categoryEntry.items[tostring(itemName or '')] = nil;
        for index = #categoryEntry.itemOrder, 1, -1 do
            if (categoryEntry.itemOrder[index] == tostring(itemName or '')) then
                table.remove(categoryEntry.itemOrder, index);
            end
        end
        local expectedCount = tonumber(categoryEntry.expectedCount);
        if (expectedCount ~= nil and expectedCount > 0) then
            categoryEntry.expectedCount = math.max(0, expectedCount - 1);
            if (CategoryHasNativeCount(categoryEntry.name) == true) then
                categoryEntry.name = GetCategoryKey(categoryEntry.name) .. ' (' .. tostring(categoryEntry.expectedCount) .. ')';
            end
        end
    else
        item.total = newTotal;
    end

    if (oldTotal ~= newTotal) then
        cacheDirty = true;
    end
end

local function RemoveCachedItem(category, itemName)
    local categoryEntry = cache.categories[GetCategoryKey(category)];
    itemName = tostring(itemName or '');
    if (categoryEntry == nil or itemName == '') then
        return false;
    end

    local removed = false;
    if (categoryEntry.items[itemName] ~= nil) then
        categoryEntry.items[itemName] = nil;
        removed = true;
    end

    for index = #categoryEntry.itemOrder, 1, -1 do
        if (categoryEntry.itemOrder[index] == itemName) then
            table.remove(categoryEntry.itemOrder, index);
            removed = true;
        end
    end

    if (removed == true) then
        cacheDirty = true;
    end

    return removed;
end

local function MarkNestedStorageMenu(category, itemName)
    local categoryEntry = EnsureCategory(category);
    itemName = CleanFolderText(itemName);
    if (categoryEntry == nil or itemName == '' or IsNavigationOption(itemName) == true) then
        return false;
    end

    categoryEntry.nestedMenus = categoryEntry.nestedMenus or {};
    categoryEntry.nestedMenus[itemName] = true;
    local removed = RemoveCachedItem(category, itemName);
    if (removed ~= true) then
        cacheDirty = true;
    end

    return true;
end

local function ParseItemOption(option)
    local name, count = tostring(option or ''):match('^(.-)%s*%((%d+)%)$');
    if (name == nil) then
        return nil, nil;
    end

    name = name:gsub('^%s+', ''):gsub('%s+$', '');
    return name, tonumber(count);
end

local function LearnCategoryPage(menu)
    for _, option in ipairs(menu.options or {}) do
        if (IsNavigationOption(option) ~= true) then
            local category = EnsureCategory(option);
            if (category ~= nil) then
                MoveNumericNestedItemsToCategory(GetCategoryKey(category.name or option));
            end
        end
    end
end

local function BuildSmartScanCategories(seenCategories)
    local categoriesToScan = {};
    local newOrder = {};

    for _, categoryName in ipairs(cache.categoryOrder or {}) do
        local category = cache.categories[categoryName];
        if (category ~= nil and (seenCategories == nil or seenCategories[categoryName] == true)) then
            newOrder[#newOrder + 1] = categoryName;

            local expected = tonumber(category.expectedCount) or GetCategoryNativeCount(category.name);
            local cached = #(category.itemOrder or {});
            local verified = tonumber(category.scanVersion) == CACHE_SCAN_VERSION;
            if (
                verified ~= true or
                expected == nil or
                expected <= 0 or
                cached ~= expected
            ) then
                categoriesToScan[#categoriesToScan + 1] = category.name or categoryName;
            end
        elseif (seenCategories ~= nil) then
            cache.categories[categoryName] = nil;
            cacheDirty = true;
        end
    end

    cache.categoryOrder = newOrder;
    return categoriesToScan;
end

local function LearnItemPage(menu, category, nestedMenu)
    if (category == nil or tostring(category or '') == '') then
        return;
    end

    local categoryEntry = EnsureCategory(category);
    if (categoryEntry ~= nil) then
        categoryEntry.scanVersion = CACHE_SCAN_VERSION;
        cacheDirty = true;
    end

    for _, option in ipairs(menu.options or {}) do
        if (IsNavigationOption(option) ~= true) then
            local name, count = ParseItemOption(option);
            if (name ~= nil) then
                UpsertItem(category, name, count, nestedMenu);
            end
        end
    end
end

local function LearnNestedMenuPage(menu, category)
    if (category == nil or tostring(category or '') == '') then
        return {};
    end

    local categoryEntry = EnsureCategory(category);
    if (categoryEntry ~= nil) then
        categoryEntry.scanVersion = CACHE_SCAN_VERSION;
        cacheDirty = true;
    end

    local nestedMenus = {};
    for _, option in ipairs(menu.options or {}) do
        if (IsNavigationOption(option) ~= true) then
            local name = ParseItemOption(option);
            if (name ~= nil) then
                MarkNestedStorageMenu(category, name);
                nestedMenus[#nestedMenus + 1] = CleanFolderText(name);
            end
        end
    end

    return nestedMenus;
end

local function AddNestedScanMenus(active, names)
    if (active == nil or type(names) ~= 'table') then
        return;
    end

    active.nestedScanQueue = active.nestedScanQueue or {};
    active.seenNestedScanMenus = active.seenNestedScanMenus or {};

    for _, name in ipairs(names) do
        local cleanName = CleanFolderText(name);
        if (cleanName ~= '' and active.seenNestedScanMenus[cleanName] ~= true) then
            active.seenNestedScanMenus[cleanName] = true;
            active.nestedScanQueue[#active.nestedScanQueue + 1] = cleanName;
        end
    end
end

local function HasQueuedNestedScanMenus(active)
    return active ~= nil and type(active.nestedScanQueue) == 'table' and #active.nestedScanQueue > 0;
end

local function SelectNextNestedScanMenu(active, question, options)
    if (HasQueuedNestedScanMenus(active) ~= true) then
        return false;
    end

    local nestedMenu = table.remove(active.nestedScanQueue, 1);
    local result = nestedMenu;

    for _, option in ipairs(options or {}) do
        local optionName = ParseItemOption(option);
        if (optionName == nestedMenu) then
            result = option;
            break;
        end
    end

    active.nestedMenu = nestedMenu;
    active.firstSignature = nil;
    active.itemLoops = 0;
    active.state = (tostring(active.state or ''):find('scanAll', 1, true) ~= nil) and 'scanAllNestedItems' or 'scanNestedItems';

    QueueAction(0.08, function()
        SendCustomAnswer(question, result, 'select nested item menu');
    end);

    return true;
end

local function FinishItemScan(active)
    if (active.state == 'scanAllCategoryItems') then
        QueueNextFullScanCategory(active);
    else
        SaveCache();
        pending = nil;
    end
end

local function FinishNestedItemScan(active)
    active.state = (active.state == 'scanAllNestedItems') and 'scanAllNestedReturn' or 'scanNestedReturn';
    active.firstSignature = nil;
    active.itemLoops = 0;
end

local function ReopenCategoryForNextNestedMenu(active)
    if (active == nil or HasQueuedNestedScanMenus(active) ~= true) then
        return false;
    end

    active.state = (tostring(active.state or ''):find('scanAll', 1, true) ~= nil) and 'scanAllFindCategory' or 'scanCategoryFind';
    active.categoryLoops = 0;
    active.itemLoops = 0;
    active.firstSignature = nil;
    active.nestedMenu = nil;
    active.lastActivityAt = Now();

    QueueAction(0.14, function()
        SendOutgoingPacket(0x01A, BuildNpcPokePacket(active.targetId, active.targetIndex), 'scan next Ephemeral Box nested menu ' .. tostring(active.category));
    end);

    return true;
end

local function ParseStoredText(text)
    EnsureCacheLoaded();
    text = tostring(text or ''):gsub('[%z\1-\31]', ''):gsub('^%s+', ''):gsub('%s+$', '');

    local itemName, total, category = text:match('You store%s+(.-)%s+x%d+%s+%(Total:%s*(%d+)%)%s+(.+)$');

    if (itemName ~= nil and category ~= nil) then
        UpsertItem(category, itemName, tonumber(total));
        SaveCache();
        return true;
    end

    if (text:lower():find("don't recognize that item", 1, true) ~= nil and #pendingExtracts > 0) then
        local request = table.remove(pendingExtracts, #pendingExtracts);
        if (request ~= nil and RemoveCachedItem(request.category, request.itemName) == true) then
            SaveCache();
            SetStatus('Removed non-item E.Box row: ' .. tostring(request.itemName));
        end
        return true;
    end

    local obtainedText = text:match('^You obtain%s+(.+)!$') or text:match('^You obtain%s+(.+)$');
    if (obtainedText ~= nil and #pendingExtracts > 0) then
        local normalizedObtained = NormalizeItemText(obtainedText);

        for index = #pendingExtracts, 1, -1 do
            local request = pendingExtracts[index];
            local normalizedItem = NormalizeItemText(request.itemName);
            if (normalizedItem ~= '' and normalizedObtained:find(normalizedItem, 1, true) ~= nil) then
                local amount = tonumber(text:match('You obtain%s+(%d+)%s+')) or nil;
                if (amount == nil and (text:match('^You obtain%s+a%s+') ~= nil or text:match('^You obtain%s+an%s+') ~= nil)) then
                    amount = 1;
                end

                amount = math.max(1, math.floor(tonumber(amount) or tonumber(request.amount) or 1));
                AdjustItemTotal(request.category, request.itemName, -amount);
                table.remove(pendingExtracts, index);
                SaveCache();
                return true;
            end
        end
    end

    return false;
end

local function FindOption(options, expected)
    expected = tostring(expected or '');
    for _, option in ipairs(options or {}) do
        if (tostring(option or '') == expected) then
            return option;
        end
    end

    return nil;
end

local function FindItemOption(options, itemName)
    itemName = tostring(itemName or '');
    for _, option in ipairs(options or {}) do
        local name = ParseItemOption(option);
        if (name == itemName) then
            return option;
        end
    end

    return nil;
end

local function FindQuantityOption(options, requestedAmount)
    requestedAmount = tonumber(requestedAmount) or 1;
    local exact = 'x' .. tostring(requestedAmount);
    local fallback = nil;
    local fallbackAmount = 0;

    for _, option in ipairs(options or {}) do
        local amount = tostring(option or ''):match('^x(%d+)$');
        amount = tonumber(amount);
        if (amount ~= nil) then
            if (tostring(option) == exact) then
                return option;
            end

            if (amount <= requestedAmount and amount > fallbackAmount) then
                fallback = option;
                fallbackAmount = amount;
            end
        end
    end

    return fallback;
end

local function HasNext(options)
    return FindOption(options, '(Next)') or FindOption(options, 'Next');
end

local function PageSignature(options)
    local values = {};
    for _, option in ipairs(options or {}) do
        if (IsNavigationOption(option) ~= true) then
            values[#values + 1] = tostring(option or '');
        end
    end

    return table.concat(values, '|');
end

local function IsItemMenuQuestion(question, active)
    question = CleanMenuText(question);
    if (question == 'Select an item:') then
        return true;
    end

    local questionKey = GetCategoryKey(question:gsub(':$', ''));
    local activeKey = GetCategoryKey(active ~= nil and active.category or '');

    return questionKey ~= '' and activeKey ~= '' and questionKey == activeKey;
end

local function GetTargetIds(context)
    context = context or {};
    local targetIndex = tonumber(context.targetIndex) or 0;
    local targetId = tonumber(context.targetId) or 0;

    if (targetId <= 0 and targetIndex > 0) then
        pcall(function()
            targetId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(targetIndex);
        end);
    end

    return targetIndex, targetId;
end

local function StartFullScanCategory()
    if (pending == nil or pending.state ~= 'scanAllFindCategory') then
        return;
    end

    local category = pending.categories[pending.categoryIndex];
    if (category == nil) then
        SetStatus('E.Box scan complete.');
        SaveCache();
        pending = nil;
        return;
    end

    SetStatus('Scanning E.Box: ' .. tostring(category) .. ' (' .. tostring(tonumber(pending.categoryIndex) or 0) .. '/' .. tostring(#(pending.categories or {})) .. ')');
    pending.category = category;
    pending.categoryLoops = 0;
    pending.itemLoops = 0;
    pending.firstSignature = nil;
    pending.lastActivityAt = Now();
    SendOutgoingPacket(0x01A, BuildNpcPokePacket(pending.targetId, pending.targetIndex), 'scan Ephemeral Box category ' .. tostring(category));
end

QueueNextFullScanCategory = function(active)
    active.categoryIndex = (tonumber(active.categoryIndex) or 1) + 1;
    active.state = 'scanAllFindCategory';
    active.category = active.categories[active.categoryIndex];
    active.categoryLoops = 0;
    active.itemLoops = 0;
    active.firstSignature = nil;
    active.lastActivityAt = Now();

    if (active.category == nil) then
        QueueAction(0.80, function()
            SetStatus('E.Box scan complete.');
            SaveCache();
            pending = nil;
        end);
        return;
    end

    QueueAction(0.14, function()
        StartFullScanCategory();
    end);
end

function ephemeralBox.IsTarget(name, info)
    local text = tostring(name or ''):gsub('_', ' '):lower();
    if (text == 'ephemeral box') then
        return true;
    end

    if (info ~= nil) then
        return ephemeralBox.IsTarget(info.name) == true
            or ephemeralBox.IsTarget(info.displayName) == true
            or ephemeralBox.IsTarget(info.type) == true;
    end

    return false;
end

function ephemeralBox.StoreAll()
    EnsureCacheLoaded();
    ClearPendingAutomation();
    QueueCommand('!box store', 1);
end

function ephemeralBox.OpenNative(context)
    context = context or {};
    local targetIndex, targetId = GetTargetIds(context);

    if (targetIndex <= 0 or targetId <= 0) then
        log.Warn('Ephemeral Box failed: no valid target.');
        return false;
    end

    return SendOutgoingPacket(0x01A, BuildNpcPokePacket(targetId, targetIndex), 'poke Ephemeral Box');
end

function ephemeralBox.ScanCategories(context)
    local targetIndex, targetId = GetTargetIds(context);

    if (targetIndex <= 0 or targetId <= 0) then
        log.Warn('Ephemeral Box scan failed: no valid target.');
        return false;
    end

    pending = {
        state = 'scanCategories',
        targetIndex = targetIndex,
        targetId = targetId,
        startedAt = Now(),
        lastActivityAt = Now(),
        firstSignature = nil,
        loops = 0,
    };
    queue = {};

    return SendOutgoingPacket(0x01A, BuildNpcPokePacket(targetId, targetIndex), 'scan Ephemeral Box categories');
end

function ephemeralBox.ScanAll(context)
    local targetIndex, targetId = GetTargetIds(context);

    if (targetIndex <= 0 or targetId <= 0) then
        log.Warn('Ephemeral Box scan failed: no valid target.');
        return false;
    end

    EnsureCacheLoaded();
    cacheLoadedFor = GetCharacterCacheKey();
    browseCategory = nil;
    lastStatus = 'Checking E.Box categories...';

    pending = {
        state = 'scanAllCategories',
        targetIndex = targetIndex,
        targetId = targetId,
        startedAt = Now(),
        lastActivityAt = Now(),
        firstSignature = nil,
        loops = 0,
        categories = {},
        seenCategories = {},
        categoryIndex = 0,
    };
    queue = {};

    return SendOutgoingPacket(0x01A, BuildNpcPokePacket(targetId, targetIndex), 'scan all Ephemeral Box');
end

function ephemeralBox.ScanCategoryItems(category, context)
    context = context or {};
    local targetIndex, targetId = GetTargetIds(context);

    if (targetIndex <= 0 or targetId <= 0) then
        log.Warn('Ephemeral Box item scan failed: no valid target.');
        return false;
    end

    EnsureCacheLoaded();
    browseCategory = nil;
    pending = {
        state = 'scanCategoryFind',
        targetIndex = targetIndex,
        targetId = targetId,
        startedAt = Now(),
        lastActivityAt = Now(),
        category = tostring(category or ''),
        categoryLoops = 0,
        itemLoops = 0,
        firstSignature = nil,
    };
    queue = {};
    SetStatus('Scanning E.Box: ' .. tostring(category or ''));

    return SendOutgoingPacket(0x01A, BuildNpcPokePacket(targetId, targetIndex), 'scan Ephemeral Box category ' .. tostring(category or ''));
end

function ephemeralBox.RequestExtract(category, itemName, amount, context)
    context = context or {};
    category = tostring(category or '');
    itemName = CleanMenuText(itemName);
    amount = math.max(1, math.floor(tonumber(amount) or 1));

    if (itemName == '') then
        log.Warn('Ephemeral Box extract failed: no item name.');
        return false;
    end

    EnsureCacheLoaded();
    ClearPendingAutomation();
    pendingExtracts[#pendingExtracts + 1] = {
        category = category,
        itemName = itemName,
        amount = amount,
        requestedAt = Now(),
    };
    QueueCommand('!box ' .. tostring(amount) .. ' ' .. itemName, 1);
    return true;
end

function ephemeralBox.HandlePacketIn(e)
    local data = e ~= nil and (e.data_modified or e.data) or nil;
    if (pending ~= nil and debugEnabled == true and type(data) == 'string') then
        local packetId = tonumber(e ~= nil and e.id) or 0;
        if (packetId == 0x017 or packetId == 0x034 or packetId == 0x05C or packetId == 0x052) then
            local strings = PacketStrings(data);
            log.Info('Ephemeral Box scan saw incoming id=0x' .. string.format('%03X', packetId) .. ' strings=' .. table.concat(strings, '|'));
        end
    end

    if (e == nil or e.id ~= 0x017 or type(data) ~= 'string') then
        return;
    end

    ParseStoredText(table.concat(PacketStrings(data), ' '));

    local menu = GetCustomMenu(data);
    if (menu == nil) then
        return;
    end

    local question = tostring(menu.question or '');
    if (pending ~= nil and debugEnabled == true) then
        log.Info('Ephemeral Box scan menu question=' .. question .. ' options=' .. table.concat(menu.options or {}, '|'));
    end
    if (pending ~= nil) then
        pending.lastActivityAt = Now();
    end

    if (question == 'Select a category:') then
        LearnCategoryPage(menu);
        if (pending ~= nil and (pending.state == 'scanAllCategories' or pending.state == 'scanCategories')) then
            pending.seenCategories = pending.seenCategories or {};
            for _, option in ipairs(menu.options or {}) do
                if (IsNavigationOption(option) ~= true) then
                    local key = GetCategoryKey(option);
                    if (key ~= '') then
                        pending.seenCategories[key] = true;
                    end
                end
            end
        end
    elseif (question == 'Select an item:') then
        LearnItemPage(menu, pending ~= nil and pending.category or browseCategory, pending ~= nil and pending.nestedMenu or nil);
        if (pending ~= nil and (pending.state == 'scanCategoryItems' or pending.state == 'scanAllCategoryItems' or pending.state == 'scanAllMaybeCategoryDone')) then
            SaveCache();
        end
    end

    if (pending == nil) then
        return;
    end

    local active = pending;

    if ((active.state == 'scanCategories' or active.state == 'scanAllCategories') and question == 'Select a category:') then
        e.blocked = true;
        local signature = PageSignature(menu.options);

        if (active.firstSignature == nil) then
            active.firstSignature = signature;
        elseif (signature == active.firstSignature) then
            QueueAction(0.06, function()
                SendCustomAnswer(question, 'Canceled.', 'close category scan');
                if (active.state == 'scanAllCategories') then
                    active.categories = BuildSmartScanCategories(active.seenCategories);
                    SaveCache();
                    active.categoryIndex = 1;
                    active.category = active.categories[1];
                    if (active.category == nil) then
                        SetStatus('E.Box cache already current.');
                        pending = nil;
                    else
                        active.state = 'scanAllFindCategory';
                        SetStatus('Scanning changed E.Box categories...');
                        QueueAction(0.18, function()
                            StartFullScanCategory();
                        end);
                    end
                else
                    pending = nil;
                end
            end);
            return;
        end

        local nextOption = HasNext(menu.options);
        active.loops = (tonumber(active.loops) or 0) + 1;
        if (nextOption ~= nil and active.loops <= 16) then
            QueueAction(0.06, function()
                SendCustomAnswer(question, nextOption, 'next category scan page');
            end);
        else
            QueueAction(0.06, function()
                SendCustomAnswer(question, 'Canceled.', 'close category scan');
                if (active.state == 'scanAllCategories') then
                    active.categories = BuildSmartScanCategories(active.seenCategories);
                    SaveCache();
                    active.categoryIndex = 1;
                    active.category = active.categories[1];
                    if (active.category == nil) then
                        SetStatus('E.Box cache already current.');
                        pending = nil;
                    else
                        active.state = 'scanAllFindCategory';
                        SetStatus('Scanning changed E.Box categories...');
                        QueueAction(0.18, function()
                            StartFullScanCategory();
                        end);
                    end
                else
                    pending = nil;
                end
            end);
        end
        return;
    end

    if ((active.state == 'scanCategoryFind' or active.state == 'scanAllFindCategory') and question == 'Select a category:') then
        e.blocked = true;
        local match = FindOption(menu.options, active.category);
        if (match ~= nil) then
            active.state = (active.state == 'scanAllFindCategory') and 'scanAllCategoryItems' or 'scanCategoryItems';
            browseCategory = active.category;
            if (active.state == 'scanAllCategoryItems') then
                SetStatus('Scanning E.Box: ' .. tostring(active.category) .. ' (' .. tostring(tonumber(active.categoryIndex) or 0) .. '/' .. tostring(#(active.categories or {})) .. ')');
            end
            QueueAction(0.08, function()
                SendCustomAnswer(question, match, 'select scan category');
            end);
            return;
        end

        local nextOption = HasNext(menu.options);
        active.categoryLoops = (tonumber(active.categoryLoops) or 0) + 1;
        if (nextOption ~= nil and active.categoryLoops <= 16) then
            QueueAction(0.06, function()
                SendCustomAnswer(question, nextOption, 'next category scan find page');
            end);
        else
            log.Warn('Ephemeral Box item scan failed: category not found: ' .. tostring(active.category));
            if (active.state == 'scanAllFindCategory') then
                QueueNextFullScanCategory(active);
            else
                pending = nil;
            end
        end
        return;
    end

    if (
        (
            active.state == 'scanCategoryItems' or
            active.state == 'scanAllCategoryItems' or
            active.state == 'scanAllMaybeCategoryDone' or
            active.state == 'scanNestedItems' or
            active.state == 'scanAllNestedItems'
        ) and
        IsItemMenuQuestion(question, active) == true
    ) then
        e.blocked = true;
        if (active.state == 'scanAllMaybeCategoryDone') then
            active.state = 'scanAllCategoryItems';
        end
        if (active.state == 'scanAllCategoryItems') then
            SetStatus('Scanning E.Box: ' .. tostring(active.category) .. ' page ' .. tostring((tonumber(active.itemLoops) or 0) + 1) .. ' (' .. tostring(tonumber(active.categoryIndex) or 0) .. '/' .. tostring(#(active.categories or {})) .. ')');
        elseif (active.state == 'scanAllNestedItems') then
            SetStatus('Scanning E.Box: ' .. tostring(active.category) .. ' > ' .. tostring(active.nestedMenu) .. ' page ' .. tostring((tonumber(active.itemLoops) or 0) + 1) .. ' (' .. tostring(tonumber(active.categoryIndex) or 0) .. '/' .. tostring(#(active.categories or {})) .. ')');
        end
        if (question == 'Select an item:') then
            LearnItemPage(menu, active.category, active.nestedMenu);
        else
            AddNestedScanMenus(active, LearnNestedMenuPage(menu, active.category));
        end
        SaveCache();
        local signature = PageSignature(menu.options);

        if (active.firstSignature == nil) then
            active.firstSignature = signature;
        elseif (signature == active.firstSignature) then
            QueueAction(0.06, function()
                if (active.state == 'scanAllNestedItems' or active.state == 'scanNestedItems') then
                    SendCustomAnswer(question, 'Canceled.', 'close nested item scan');
                    FinishNestedItemScan(active);
                elseif (question ~= 'Select an item:' and SelectNextNestedScanMenu(active, question, menu.options) == true) then
                    return;
                else
                    SendCustomAnswer(question, 'Canceled.', 'close item scan');
                    FinishItemScan(active);
                end
            end);
            return;
        end

        local nextOption = HasNext(menu.options);
        active.itemLoops = (tonumber(active.itemLoops) or 0) + 1;
        if (nextOption ~= nil and active.itemLoops <= 40) then
            QueueAction(0.06, function()
                SendCustomAnswer(question, nextOption, 'next item scan page');
            end);
        else
            QueueAction(0.06, function()
                if (active.state == 'scanAllNestedItems' or active.state == 'scanNestedItems') then
                    SendCustomAnswer(question, 'Canceled.', 'close nested item scan');
                    FinishNestedItemScan(active);
                elseif (question ~= 'Select an item:' and SelectNextNestedScanMenu(active, question, menu.options) == true) then
                    return;
                else
                    SendCustomAnswer(question, 'Canceled.', 'close item scan');
                    FinishItemScan(active);
                end
            end);
        end
        return;
    end

    if (
        (active.state == 'scanNestedReturn' or active.state == 'scanAllNestedReturn') and
        IsItemMenuQuestion(question, active) == true and
        question ~= 'Select an item:'
    ) then
        e.blocked = true;
        AddNestedScanMenus(active, LearnNestedMenuPage(menu, active.category));
        SaveCache();

        QueueAction(0.06, function()
            if (SelectNextNestedScanMenu(active, question, menu.options) == true) then
                return;
            end

            SendCustomAnswer(question, 'Canceled.', 'close nested category scan');
            if (active.state == 'scanAllNestedReturn') then
                active.state = 'scanAllCategoryItems';
            else
                active.state = 'scanCategoryItems';
            end
            FinishItemScan(active);
        end);
        return;
    end

    if ((active.state == 'scanNestedReturn' or active.state == 'scanAllNestedReturn') and question == 'Select a category:') then
        e.blocked = true;
        QueueAction(0.06, function()
            SendCustomAnswer(question, 'Canceled.', 'close nested scan category return');
            if (ReopenCategoryForNextNestedMenu(active) == true) then
                return;
            end
            if (active.state == 'scanAllNestedReturn') then
                QueueNextFullScanCategory(active);
            else
                SaveCache();
                pending = nil;
            end
        end);
        return;
    end

    if (active.state == 'scanAllCategoryItems' and question == 'Select a category:') then
        e.blocked = true;
        active.state = 'scanAllMaybeCategoryDone';
        QueueAction(0.06, function()
            if (pending == active and active.state == 'scanAllMaybeCategoryDone') then
                SendCustomAnswer(question, 'Canceled.', 'close category bounce');
                QueueNextFullScanCategory(active);
            end
        end);
        return;
    end

    if (active.state == 'category' and question == 'Select a category:') then
        e.blocked = true;
        local match = FindOption(menu.options, active.category);
        if (match ~= nil) then
            active.state = 'item';
            browseCategory = active.category;
            QueueAction(0.08, function()
                SendCustomAnswer(question, match, 'select category');
            end);
            return;
        end

        local nextOption = HasNext(menu.options);
        active.categoryLoops = (tonumber(active.categoryLoops) or 0) + 1;
        if (nextOption ~= nil and active.categoryLoops <= 12) then
            QueueAction(0.06, function()
                SendCustomAnswer(question, nextOption, 'next category page');
            end);
        else
            log.Warn('Ephemeral Box extract failed: category not found: ' .. tostring(active.category));
            pending = nil;
        end
        return;
    end

    if (active.state == 'item' and IsItemMenuQuestion(question, active) == true) then
        e.blocked = true;
        if (question == 'Select an item:') then
            LearnItemPage(menu, active.category, active.nestedMenu);
        else
            LearnNestedMenuPage(menu, active.category);
            SaveCache();
            if (active.nestedMenu ~= nil and tostring(active.nestedMenu) ~= '') then
                local nestedMatch = FindItemOption(menu.options, active.nestedMenu);
                if (nestedMatch ~= nil) then
                    active.itemLoops = 0;
                    QueueAction(0.08, function()
                        SendCustomAnswer(question, nestedMatch, 'select nested category');
                    end);
                    return;
                end
            end
        end
        local match = FindItemOption(menu.options, active.itemName);
        if (match ~= nil) then
            active.state = 'quantity';
            QueueAction(0.08, function()
                SendCustomAnswer(question, match, 'select item');
            end);
            return;
        end

        local nextOption = HasNext(menu.options);
        active.itemLoops = (tonumber(active.itemLoops) or 0) + 1;
        if (nextOption ~= nil and active.itemLoops <= 30) then
            QueueAction(0.06, function()
                SendCustomAnswer(question, nextOption, 'next item page');
            end);
        else
            log.Warn('Ephemeral Box extract failed: item not found: ' .. tostring(active.itemName));
            pending = nil;
        end
        return;
    end

    if (active.state == 'quantity' and question:find(active.itemName, 1, true) ~= nil) then
        e.blocked = true;
        local quantity = FindQuantityOption(menu.options, active.amount);
        if (quantity == nil) then
            log.Warn('Ephemeral Box extract failed: quantity not available for ' .. tostring(active.itemName));
            pending = nil;
            return;
        end

        QueueAction(0.08, function()
            SendCustomAnswer(question, quantity, 'select quantity');
            active.state = 'cancelQuantity';
            active.sentAmount = tonumber(tostring(quantity):match('^x(%d+)$')) or active.amount;
            pendingExtracts[#pendingExtracts + 1] = {
                category = active.category,
                itemName = active.itemName,
                amount = active.sentAmount,
                requestedAt = Now(),
            };
        end);
        return;
    end

    if (active.state == 'cancelQuantity' and question:find(active.itemName, 1, true) ~= nil) then
        e.blocked = true;
        QueueAction(0.08, function()
            SendCustomAnswer(question, 'Canceled.', 'close quantity menu');
            pending = nil;
        end);
    end
end

function ephemeralBox.HandlePacketOut(e)
    if (e == nil or e.id ~= 0x0B6 or type(e.data) ~= 'string') then
        return;
    end

    local answer = ParseCustomAnswer(e.data_modified or e.data);
    if (answer == nil) then
        return;
    end

    if (answer.question == 'Select a category:' and IsNavigationOption(answer.result) ~= true) then
        browseCategory = answer.result;
    elseif (answer.question == 'Select an item:' and IsNavigationOption(answer.result) ~= true) then
        local name, count = ParseItemOption(answer.result);
        if (name ~= nil and browseCategory ~= nil) then
            UpsertItem(browseCategory, name, count);
            SaveCache();
        end
    end
end

function ephemeralBox.HandleTextIn(e)
    local raw = tostring((e ~= nil and (e.message or e.original or e.modified)) or '');
    local clean = raw:gsub(string.char(0x1E) .. '.', ''):gsub('[%z\1-\31]', ''):lower();
    if (
        Now() < (tonumber(suppressTellErrorUntil) or 0) and
        clean:find('your tell was not received', 1, true) ~= nil and
        clean:find('recipient is either offline or changing areas', 1, true) ~= nil
    ) then
        if (e ~= nil) then
            e.blocked = true;
        end
        return true;
    end

    return ParseStoredText(raw);
end

function ephemeralBox.Update()
    if (pending ~= nil) then
        local stateName = tostring(pending.state or 'request');
        local timeoutSeconds = (stateName:find('scanAll', 1, true) ~= nil) and 900.0 or 90.0;
        local idleSeconds = Now() - (tonumber(pending.lastActivityAt) or tonumber(pending.startedAt) or Now());

        if (stateName:find('scanAll', 1, true) == nil and stateName:find('scan', 1, true) ~= nil and idleSeconds > 8.0) then
            if (stateName == 'scanNestedReturn') then
                SaveCache();
                if (ReopenCategoryForNextNestedMenu(pending) == true) then
                    SetStatus('E.Box scan resumed: ' .. tostring(pending.category or 'category'));
                    return;
                end

                SetStatus('E.Box category scan complete.');
                pending = nil;
                queue = {};
                return;
            end

            SaveCache();
            SetStatus('E.Box scan stopped: no menu response.');
            log.Warn('Ephemeral Box ' .. stateName .. ' stopped after ' .. tostring(math.floor(idleSeconds)) .. 's idle.');
            pending = nil;
            queue = {};
            return;
        end

        if (stateName:find('scanAll', 1, true) ~= nil and stateName ~= 'scanAllCategories' and idleSeconds > 20.0) then
            local stalledCategory = tostring(pending.category or 'unknown');
            SaveCache();
            SetStatus('E.Box skipped stalled category: ' .. stalledCategory);
            if (debugEnabled == true) then
                log.Warn('Ephemeral Box scan skipped stalled category after ' .. tostring(math.floor(idleSeconds)) .. 's idle: ' .. stalledCategory);
            end
            QueueNextFullScanCategory(pending);
            return;
        end

        if ((Now() - (tonumber(pending.startedAt) or 0)) > timeoutSeconds) then
            if (cacheDirty == true or #(cache.categoryOrder or {}) > 0) then
                SaveCache();
            end

            SetStatus('E.Box scan timed out; partial cache saved.');
            log.Warn('Ephemeral Box ' .. stateName .. ' timed out waiting for menu. Partial cache saved if any data was available.');
            pending = nil;
            queue = {};
            return;
        end
    end

    for pendingIndex = #pendingExtracts, 1, -1 do
        local request = pendingExtracts[pendingIndex];
        if ((Now() - (tonumber(request.requestedAt) or 0)) > 12.0) then
            table.remove(pendingExtracts, pendingIndex);
        end
    end

    local now = Now();
    local index = 1;

    while index <= #queue do
        local action = queue[index];
        if (action ~= nil and now >= (tonumber(action.at) or 0)) then
            table.remove(queue, index);
            pcall(action.fn);
        else
            index = index + 1;
        end
    end
end

function ephemeralBox.GetCache()
    EnsureCacheLoaded();
    HydrateItemOrders();
    PruneCache();
    return cache;
end

function ephemeralBox.GetStatus()
    return lastStatus;
end

function ephemeralBox.GetProgress()
    if (pending == nil) then
        return {
            busy = false,
            status = lastStatus,
        };
    end

    local category = tostring(pending.category or '');
    local categoryEntry = category ~= '' and cache.categories[GetCategoryKey(category)] or nil;

    return {
        busy = true,
        status = lastStatus,
        state = tostring(pending.state or ''),
        category = category,
        categoryIndex = tonumber(pending.categoryIndex) or 0,
        categoryTotal = #(pending.categories or {}),
        itemPage = math.max(1, (tonumber(pending.itemLoops) or 0) + 1),
        itemCount = categoryEntry ~= nil and #(categoryEntry.itemOrder or {}) or 0,
        elapsed = math.max(0, Now() - (tonumber(pending.startedAt) or Now())),
        idle = math.max(0, Now() - (tonumber(pending.lastActivityAt) or tonumber(pending.startedAt) or Now())),
    };
end

function ephemeralBox.IsBusy()
    return pending ~= nil;
end

function ephemeralBox.SetDebugEnabled(value)
    debugEnabled = value == true;
end

return ephemeralBox;
