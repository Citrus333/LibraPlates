local outputPath = arg[1] or 'TEMP WORK FOLDER/npc_type_audit.txt';
local csvPath = arg[2] or 'TEMP WORK FOLDER/npc_type_audit.csv';

local manifest = require('data.npc_object_zone_manifest');

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

local function AddFile(files, seen, fileName)
    fileName = tostring(fileName or '');

    if (fileName == '' or seen[fileName] == true) then
        return;
    end

    seen[fileName] = true;
    files[#files + 1] = fileName;
end

local function GetZoneFiles()
    local files = {};
    local seen = {};

    AddFile(files, seen, manifest.global);

    for _, fileName in pairs(manifest.zoneIds or {}) do
        AddFile(files, seen, fileName);
    end

    for _, fileName in pairs(manifest.zoneNames or {}) do
        AddFile(files, seen, fileName);
    end

    table.sort(files);
    return files;
end

local rows = {};
local seen = {};
local loadErrors = {};

for _, fileName in ipairs(GetZoneFiles()) do
    local data, err = LoadTable('data/npc_object_zones/' .. fileName);

    if (data == nil) then
        loadErrors[#loadErrors + 1] = fileName .. ': ' .. tostring(err);
    else
        for bucketName, bucket in pairs({ npcs = data.npcs or {}, objects = data.objects or {} }) do
            for name, entry in pairs(bucket) do
                if (type(entry) == 'table') then
                    local key = table.concat({
                        fileName,
                        bucketName,
                        tostring(name or ''),
                    }, '|');

                    if (seen[key] ~= true) then
                        seen[key] = true;
                        rows[#rows + 1] = {
                            zoneFile = fileName,
                            bucket = bucketName,
                            source = tostring(entry._source or (bucketName == 'objects' and 'item' or 'npc')),
                            name = tostring(name or ''),
                            typeName = tostring(entry.type or ''),
                            icon = tostring(entry.icon or ''),
                        };
                    end
                end
            end
        end
    end
end

table.sort(rows, function(a, b)
    if (a.zoneFile ~= b.zoneFile) then
        return a.zoneFile < b.zoneFile;
    end

    if (a.bucket ~= b.bucket) then
        return a.bucket < b.bucket;
    end

    return a.name < b.name;
end);

local function Csv(value)
    value = tostring(value or '');
    value = value:gsub('"', '""');
    return '"' .. value .. '"';
end

local out = assert(io.open(outputPath, 'w'));
out:write('Zone Type Audit\n');
out:write(string.format('entries=%d\n\n', #rows));

if (#loadErrors > 0) then
    out:write('Load errors:\n');
    for _, err in ipairs(loadErrors) do
        out:write('  ' .. err .. '\n');
    end
    out:write('\n');
end

for _, row in ipairs(rows) do
    out:write(string.format('%s | %s | %s | %s | %s\n',
        row.zoneFile,
        row.bucket,
        row.source,
        row.name,
        row.typeName
    ));
end
out:close();

local csv = assert(io.open(csvPath, 'w'));
csv:write('ZoneFile,Bucket,Source,Name,Type,Icon\n');
for _, row in ipairs(rows) do
    csv:write(table.concat({
        Csv(row.zoneFile),
        Csv(row.bucket),
        Csv(row.source),
        Csv(row.name),
        Csv(row.typeName),
        Csv(row.icon),
    }, ',') .. '\n');
end
csv:close();
