local outputPath = arg[1] or 'TEMP WORK FOLDER/missing_icons.txt';
local csvPath = arg[2] or 'TEMP WORK FOLDER/missing_icons.csv';

function T(t)
    return t;
end

local addonRoot = '.';

local sources = {
    { key = 'catseye_npc', path = 'data/catseye_npc_icons.lua', folder = 'assets/images/catseye_icons' },
    { key = 'npc', path = 'data/npc_icons.lua', folder = 'assets/images/npc_icons' },
    { key = 'catseye_item', path = 'data/catseye_item_icons.lua', folder = 'assets/images/catseye_icons' },
    { key = 'item', path = 'data/item_icons.lua', folder = 'assets/images/item_icons' },
    { key = 'legacy_wiki', path = 'data/generated/wiki_legacy_npcs.lua', folder = 'assets/images/npc_icons' },
    { key = 'current_wiki', path = 'data/generated/wiki_current_npcs.lua', folder = 'assets/images/npc_icons' },
};

local function IsAbsolutePath(path)
    path = tostring(path or '');
    return path:match('^%a:[/\\]') ~= nil or path:match('^[/\\][/\\]') ~= nil;
end

local function JoinPath(left, right)
    left = tostring(left or ''):gsub('\\', '/'):gsub('/+$', '');
    right = tostring(right or ''):gsub('\\', '/'):gsub('^/+', '');

    if (left == '' or left == '.') then
        return right;
    end

    return left .. '/' .. right;
end

local function FileExists(path)
    local file = io.open(path, 'rb');

    if (file ~= nil) then
        file:close();
        return true;
    end

    return false;
end

local function LoadTable(path)
    local loader, err = loadfile(path);

    if (loader == nil) then
        return nil, err;
    end

    local ok, data = pcall(loader);

    if (ok ~= true or type(data) ~= 'table') then
        return nil, data;
    end

    return data, nil;
end

local function AddIcon(rows, sourceKey, sourcePath, folder, name, entry)
    if (type(entry) ~= 'table') then
        return;
    end

    local icon = tostring(entry.icon or '');

    if (icon == '') then
        return;
    end

    local expectedPath = icon:gsub('\\', '/');

    if (IsAbsolutePath(expectedPath) ~= true) then
        expectedPath = JoinPath(folder, expectedPath);
    end

    rows[#rows + 1] = {
        source = sourceKey,
        sourcePath = sourcePath,
        name = tostring(name or ''),
        typeName = tostring(entry.type or ''),
        icon = icon,
        expectedPath = expectedPath,
        exists = FileExists(expectedPath),
    };
end

local rows = {};
local loadErrors = {};

for _, source in ipairs(sources) do
    local data, err = LoadTable(source.path);

    if (data == nil) then
        loadErrors[#loadErrors + 1] = source.path .. ': ' .. tostring(err);
    else
        for name, entry in pairs(data) do
            AddIcon(rows, source.key, source.path, source.folder, name, entry);
        end
    end
end

local staffData, staffErr = LoadTable('data/staff_players.lua');
if (staffData == nil) then
    loadErrors[#loadErrors + 1] = 'data/staff_players.lua: ' .. tostring(staffErr);
else
    if (type(staffData.names) == 'table') then
        for name, entry in pairs(staffData.names) do
            AddIcon(rows, 'staff_names', 'data/staff_players.lua', 'assets/images/staff', name, entry);
        end
    end

    if (type(staffData.serverIds) == 'table') then
        for serverId, entry in pairs(staffData.serverIds) do
            local name = tostring(entry.name or serverId);
            AddIcon(rows, 'staff_serverIds', 'data/staff_players.lua', 'assets/images/staff', name, entry);
        end
    end
end

local missingByIcon = {};
local total = 0;
local missingTotal = 0;

for _, row in ipairs(rows) do
    total = total + 1;

    if (row.exists ~= true) then
        missingTotal = missingTotal + 1;
        local key = row.source .. '|' .. row.icon .. '|' .. row.expectedPath;
        local bucket = missingByIcon[key];

        if (bucket == nil) then
            bucket = {
                source = row.source,
                icon = row.icon,
                expectedPath = row.expectedPath,
                count = 0,
                examples = {},
                types = {},
            };
            missingByIcon[key] = bucket;
        end

        bucket.count = bucket.count + 1;
        bucket.types[row.typeName] = true;

        if (#bucket.examples < 12) then
            bucket.examples[#bucket.examples + 1] = row.name .. ' (' .. row.source .. ')';
        end
    end
end

local missing = {};
for _, bucket in pairs(missingByIcon) do
    local types = {};
    for typeName, _ in pairs(bucket.types) do
        if (typeName ~= '') then
            types[#types + 1] = typeName;
        end
    end
    table.sort(types);
    bucket.typeList = table.concat(types, '; ');
    missing[#missing + 1] = bucket;
end

table.sort(missing, function(a, b)
    if (a.count ~= b.count) then
        return a.count > b.count;
    end

    if (a.source ~= b.source) then
        return a.source < b.source;
    end

    return a.icon < b.icon;
end);

local function Csv(value)
    value = tostring(value or '');
    value = value:gsub('"', '""');
    return '"' .. value .. '"';
end

local out = assert(io.open(outputPath, 'w'));
out:write('Missing Icon Audit\n');
out:write(string.format('icon refs=%d missing refs=%d missing unique=%d\n\n', total, missingTotal, #missing));

if (#loadErrors > 0) then
    out:write('Load errors:\n');
    for _, err in ipairs(loadErrors) do
        out:write('  ' .. err .. '\n');
    end
    out:write('\n');
end

for _, bucket in ipairs(missing) do
    out:write(string.format('%s | source=%s | refs=%d\n', bucket.icon, bucket.source, bucket.count));
    out:write('  expected: ' .. bucket.expectedPath .. '\n');
    if (bucket.typeList ~= '') then
        out:write('  types: ' .. bucket.typeList .. '\n');
    end
    out:write('  examples: ' .. table.concat(bucket.examples, '; ') .. '\n\n');
end
out:close();

local csv = assert(io.open(csvPath, 'w'));
csv:write('Icon,Source,Count,ExpectedPath,Types,Examples\n');
for _, bucket in ipairs(missing) do
    csv:write(table.concat({
        Csv(bucket.icon),
        Csv(bucket.source),
        tostring(bucket.count),
        Csv(bucket.expectedPath),
        Csv(bucket.typeList),
        Csv(table.concat(bucket.examples, '; ')),
    }, ',') .. '\n');
end
csv:close();

print(string.format('Wrote %s', outputPath));
print(string.format('Wrote %s', csvPath));
print(string.format('icon refs=%d missing refs=%d missing unique=%d', total, missingTotal, #missing));
