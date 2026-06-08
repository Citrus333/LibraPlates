local missingPath = arg[1] or 'TEMP WORK FOLDER/missing_npcs.txt';

function T(t)
    return t;
end

local sources = {
    { key = 'catseye_npc', path = 'data/catseye_npc_icons.lua' },
    { key = 'npc', path = 'data/npc_icons.lua' },
    { key = 'catseye_item', path = 'data/catseye_item_icons.lua' },
    { key = 'item', path = 'data/item_icons.lua' },
}

local function Normalize(text)
    text = tostring(text or '');
    text = text:gsub('\\', '');
    text = text:gsub('[`´’]', "'");
    text = text:gsub('%s+', ' ');
    text = text:gsub('^%s+', ''):gsub('%s+$', '');
    return text:lower();
end

local function GetEntryZones(entry)
    if (type(entry) ~= 'table') then
        return nil;
    end

    if (type(entry.zones) == 'table' and next(entry.zones) ~= nil) then
        return entry.zones;
    end

    if (entry.location ~= nil and tostring(entry.location) ~= '') then
        return { tostring(entry.location) };
    end

    return nil;
end

local function HasZone(entry, zone)
    local zones = GetEntryZones(entry);

    if (zones == nil) then
        return false;
    end

    local wanted = Normalize(zone);

    for _, value in pairs(zones) do
        if (Normalize(value) == wanted) then
            return true;
        end
    end

    return false;
end

local function LoadSource(source)
    local loader, err = loadfile(source.path);

    if (loader == nil) then
        error('Could not load ' .. source.path .. ': ' .. tostring(err));
    end

    source.data = loader();
end

local function FindEntry(name)
    for _, source in ipairs(sources) do
        local entry = source.data[name];

        if (entry ~= nil) then
            return source, entry;
        end
    end

    return nil, nil;
end

local function PrintTableSummary()
    print('Table zone coverage:');

    for _, source in ipairs(sources) do
        local total = 0;
        local withZones = 0;
        local withLocation = 0;
        local missing = 0;

        for _, entry in pairs(source.data) do
            total = total + 1;

            if (type(entry) == 'table' and type(entry.zones) == 'table' and next(entry.zones) ~= nil) then
                withZones = withZones + 1;
            elseif (type(entry) == 'table' and entry.location ~= nil and tostring(entry.location) ~= '') then
                withLocation = withLocation + 1;
            else
                missing = missing + 1;
            end
        end

        print(string.format('  %s total=%d zones=%d location=%d no_zone=%d',
            source.path, total, withZones, withLocation, missing));
    end
end

local function PrintDuplicateKeys()
    print('Duplicate key scan:');

    for _, source in ipairs(sources) do
        local seen = {};
        local duplicates = {};

        for line in io.lines(source.path) do
            local quote, name = line:match("^%s*%[%s*(['\"])(.-)%1%s*%]%s*=");

            if (quote ~= nil and name ~= nil) then
                name = name:gsub("\\'", "'"):gsub('\\"', '"');

                if (seen[name] ~= nil) then
                    duplicates[#duplicates + 1] = name;
                else
                    seen[name] = true;
                end
            end
        end

        table.sort(duplicates);

        if (#duplicates == 0) then
            print('  ' .. source.path .. ' duplicates=0');
        else
            print('  ' .. source.path .. ' duplicates=' .. tostring(#duplicates));
            for _, name in ipairs(duplicates) do
                print('    ' .. name);
            end
        end
    end
end

local function ReadMissingCaptures()
    local file = io.open(missingPath, 'r');

    if (file == nil) then
        return nil;
    end

    local captures = {};
    local seen = {};

    for line in file:lines() do
        local name, zone = line:match('^(.-)%s+|%s+(.+)$');

        if (name ~= nil and zone ~= nil) then
            name = name:gsub('^.*},', '');
            local key = name .. '|' .. zone;

            if (seen[key] ~= true) then
                seen[key] = true;
                captures[#captures + 1] = { name = name, zone = zone };
            end
        end
    end

    file:close();

    return captures;
end

local function PrintMissingAudit()
    local captures = ReadMissingCaptures();

    if (captures == nil) then
        print('Missing capture audit: skipped; file not found: ' .. missingPath);
        return;
    end

    local resolved = 0;
    local unresolved = {};
    local missingZone = {};

    for _, capture in ipairs(captures) do
        local source, entry = FindEntry(capture.name);

        if (source == nil) then
            unresolved[#unresolved + 1] = capture;
        elseif (HasZone(entry, capture.zone) ~= true) then
            missingZone[#missingZone + 1] = {
                name = capture.name,
                zone = capture.zone,
                source = source.key,
                path = source.path,
            };
        else
            resolved = resolved + 1;
        end
    end

    print('Missing capture audit:');
    print(string.format('  captures=%d resolved=%d add_entry=%d add_zone=%d',
        #captures, resolved, #unresolved, #missingZone));

    if (#unresolved > 0) then
        print('  Need new entries:');
        for _, capture in ipairs(unresolved) do
            print('    ' .. capture.name .. ' | ' .. capture.zone);
        end
    end

    if (#missingZone > 0) then
        print('  Need zones added to existing entries:');
        for _, capture in ipairs(missingZone) do
            print('    ' .. capture.name .. ' | ' .. capture.zone .. ' -> ' .. capture.path);
        end
    end
end

for _, source in ipairs(sources) do
    LoadSource(source);
end

PrintTableSummary();
PrintDuplicateKeys();
PrintMissingAudit();
