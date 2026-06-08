local path = arg[1] or 'TEMP WORK FOLDER\\staff_players.txt';
local bitlib = bit or bit32;

if (bitlib == nil) then
    local ok, loaded = pcall(require, 'bit');
    if (ok == true) then
        bitlib = loaded;
    end
end

if (bitlib == nil) then
    local ok, loaded = pcall(require, 'bit32');
    if (ok == true) then
        bitlib = loaded;
    end
end

local function parse_hex(value)
    if (value == nil) then
        return 0;
    end

    value = tostring(value):gsub('^0x', ''):gsub('^0X', '');
    return tonumber(value, 16) or tonumber(value) or 0;
end

local function parse_line(line)
    local row = {
        name = tostring(line):match('^([^|]+)') or '',
        flags = {},
    };

    row.name = row.name:gsub('^%s+', ''):gsub('%s+$', '');

    for key, value in tostring(line):gmatch('|%s*([^=|]+)=([^|]+)') do
        key = tostring(key):gsub('^%s+', ''):gsub('%s+$', '');
        value = tostring(value):gsub('^%s+', ''):gsub('%s+$', '');

        if (key == 'label') then
            row.label = value:lower();
        elseif (key == 'serverId') then
            row.serverId = tonumber(value);
        elseif (key == 'spawn') then
            row.spawn = parse_hex(value);
        else
            local flagIndex = key:match('^render(%d+)$') or key:match('^renderFlags(%d+)$');
            if (flagIndex ~= nil) then
                row.flags[tonumber(flagIndex)] = parse_hex(value);
            end
        end
    end

    return row;
end

local function band(left, right)
    if (bitlib ~= nil and bitlib.band ~= nil) then
        return bitlib.band(left, right);
    end

    local result = 0;
    local bitValue = 1;
    left = tonumber(left) or 0;
    right = tonumber(right) or 0;

    while (left > 0 or right > 0) do
        local leftBit = left % 2;
        local rightBit = right % 2;

        if (leftBit == 1 and rightBit == 1) then
            result = result + bitValue;
        end

        left = math.floor(left / 2);
        right = math.floor(right / 2);
        bitValue = bitValue * 2;
    end

    return result;
end

local function bor(left, right)
    if (bitlib ~= nil and bitlib.bor ~= nil) then
        return bitlib.bor(left, right);
    end

    local result = 0;
    local bitValue = 1;
    left = tonumber(left) or 0;
    right = tonumber(right) or 0;

    while (left > 0 or right > 0) do
        local leftBit = left % 2;
        local rightBit = right % 2;

        if (leftBit == 1 or rightBit == 1) then
            result = result + bitValue;
        end

        left = math.floor(left / 2);
        right = math.floor(right / 2);
        bitValue = bitValue * 2;
    end

    return result;
end

local function bnot(value)
    if (bitlib ~= nil and bitlib.bnot ~= nil) then
        return bitlib.bnot(value);
    end

    return 0xFFFFFFFF - (tonumber(value) or 0);
end

local rows = {};
local file = io.open(path, 'r');

if (file == nil) then
    print('No capture file: ' .. tostring(path));
    os.exit(1);
end

for line in file:lines() do
    if (line ~= '') then
        rows[#rows + 1] = parse_line(line);
    end
end

file:close();

local gmRows = {};
local normalRows = {};

for _, row in ipairs(rows) do
    local hasFlags = false;
    for flagIndex = 0, 7 do
        if ((row.flags[flagIndex] or 0) ~= 0) then
            hasFlags = true;
            break;
        end
    end

    if (hasFlags == true and (row.label == 'gm' or row.name == 'Mod' or row.name == 'Sky')) then
        gmRows[#gmRows + 1] = row;
    elseif (hasFlags == true and row.label == 'normal') then
        normalRows[#normalRows + 1] = row;
    end
end

print(string.format('captures=%d gm=%d normal=%d', #rows, #gmRows, #normalRows));

for _, row in ipairs(gmRows) do
    print(string.format('GM %-16s serverId=%s', row.name, tostring(row.serverId)));
end

if (#gmRows == 0) then
    os.exit(0);
end

for flagIndex = 0, 7 do
    local common = 0xFFFFFFFF;

    for _, row in ipairs(gmRows) do
        common = band(common, row.flags[flagIndex] or 0);
    end

    local normalAny = 0;
    for _, row in ipairs(normalRows) do
        normalAny = bor(normalAny, row.flags[flagIndex] or 0);
    end

    local gmOnly = band(common, bnot(normalAny));

    print(string.format(
        'render%d gm_common=0x%X normal_any=0x%X gm_only=0x%X',
        flagIndex,
        common,
        normalAny,
        gmOnly
    ));
end
