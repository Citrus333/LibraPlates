local function read_file(path)
  local f = assert(io.open(path, 'r'))
  local c = f:read('*a')
  f:close()
  return c
end

local function write_file(path, data)
  local f = assert(io.open(path, 'w'))
  f:write(data)
  f:close()
end

local function load_table(path, varname)
  local src = read_file(path)
  src = src:gsub('local%s+' .. varname .. '%s*=%s*T%s*{', varname .. ' = {')
  src = 'local T = function(t) return t end\n' .. src
  local chunk, err = loadstring(src)
  if not chunk then
    return nil, err
  end
  local env = { T = function(t) return t end }
  setfenv(chunk, env)
  local ok, runErr = pcall(chunk)
  if not ok then
    return nil, runErr
  end
  return env[varname]
end

local function escape_lua_string(s)
  s = s:gsub('\\', '\\\\')
  s = s:gsub('"', '\\"')
  s = s:gsub('\r', '')
  s = s:gsub('\n', '\\n')
  s = s:gsub('\t', '\\t')
  return '"' .. s .. '"'
end

local function format_zones(zones)
  local parts = {}
  for _, z in ipairs(zones) do
    table.insert(parts, escape_lua_string(tostring(z)))
  end
  return '{ ' .. table.concat(parts, ', ') .. ' },'
end

local function parse_entry_key_from_line(line)
  local i = 1
  local n = #line
  while i <= n and line:sub(i, i):match('%s') do
    i = i + 1
  end
  if i > n or line:sub(i, i) ~= '[' then
    return nil
  end
  i = i + 1
  while i <= n and line:sub(i, i):match('%s') do
    i = i + 1
  end
  local quote = line:sub(i, i)
  if quote ~= '"' and quote ~= '\'' then
    return nil
  end
  local keyStart = i
  i = i + 1
  while i <= n do
    local ch = line:sub(i, i)
    if ch == '\\' then
      i = i + 2
    elseif ch == quote then
      break
    else
      i = i + 1
    end
  end
  if i > n then
    return nil
  end
  local keyExpr = line:sub(keyStart, i)
  local keyChunk = loadstring('return ' .. keyExpr)
  if not keyChunk then
    return nil
  end
  local ok, key = pcall(keyChunk)
  if not ok or type(key) ~= 'string' then
    return nil
  end

  i = i + 1
  while i <= n and line:sub(i, i):match('%s') do
    i = i + 1
  end
  if line:sub(i, i) ~= ']' then
    return nil
  end
  i = i + 1
  while i <= n and line:sub(i, i):match('%s') do
    i = i + 1
  end
  if line:sub(i, i) ~= '=' then
    return nil
  end
  i = i + 1
  while i <= n and line:sub(i, i):match('%s') do
    i = i + 1
  end
  if line:sub(i, i) ~= '{' then
    return nil
  end
  return key
end

local function find_matching_brace(src, openPos)
  local depth = 0
  local inSingle = false
  local inDouble = false
  local i = openPos
  while i <= #src do
    local ch = src:sub(i, i)

    if inSingle then
      if ch == '\\' then
        i = i + 2
      elseif ch == '\'' then
        inSingle = false
        i = i + 1
      else
        i = i + 1
      end
    elseif inDouble then
      if ch == '\\' then
        i = i + 2
      elseif ch == '"' then
        inDouble = false
        i = i + 1
      else
        i = i + 1
      end
    else
      if ch == '\'' then
        inSingle = true
        i = i + 1
      elseif ch == '"' then
        inDouble = true
        i = i + 1
      elseif ch == '{' then
        depth = depth + 1
        i = i + 1
      elseif ch == '}' then
        depth = depth - 1
        if depth == 0 then
          return i
        end
        i = i + 1
      else
        i = i + 1
      end
    end
  end
  return nil
end

local npcPath = 'C:\\catseyexi\\catseyexi-client\\Ashita\\addons\\LibraPlates\\data\\npc_icons.lua'
local legacyPath = 'C:\\catseyexi\\catseyexi-client\\Ashita\\addons\\LibraPlates\\data\\generated\\wiki_legacy_npcs.lua'

local npcIcons, err1 = load_table(npcPath, 'npcIcons')
if not npcIcons then
  error('Failed to load npc_icons: ' .. tostring(err1))
end
local legacy, err2 = load_table(legacyPath, 'legacyWikiNpcs')
if not legacy then
  error('Failed to load legacy: ' .. tostring(err2))
end

local updates = {}
for key, legacyEntry in pairs(legacy) do
  local npcEntry = npcIcons[key]
  if type(legacyEntry) == 'table' and type(npcEntry) == 'table' then
    local needZones = false
    local needNote = false
    if legacyEntry.zones then
      if not npcEntry.zones or (type(npcEntry.zones) == 'table' and #npcEntry.zones == 0) then
        needZones = true
      end
    end
    if legacyEntry.note then
      if not npcEntry.note or npcEntry.note == '' then
        needNote = true
      end
    end
    if needZones or needNote then
      updates[key] = { needZones = needZones, needNote = needNote }
    end
  end
end

local src = read_file(npcPath)
local positions = {}
local lineStart = 1

while lineStart <= #src do
  local nextNl = src:find('\n', lineStart)
  if not nextNl then nextNl = #src + 1 end
  local line = src:sub(lineStart, nextNl)
  local key = parse_entry_key_from_line(line)
  if key and updates[key] then
    local bracePosLocal = line:find('{', 1, true)
    if bracePosLocal then
      local openPos = lineStart + bracePosLocal - 1
      local closePos = find_matching_brace(src, openPos)
      if closePos then
        positions[#positions + 1] = {
          key = key,
          lineStart = lineStart,
          openPos = openPos,
          closePos = closePos,
          needZones = updates[key].needZones,
          needNote = updates[key].needNote
        }
      else
        print('WARN no matching brace for', key)
      end
    end
  end
  lineStart = nextNl + 1
end

if #positions == 0 then
  print('No entries require patching from legacy.')
  os.exit(0)
end

table.sort(positions, function(a, b)
  return a.closePos > b.closePos
end)

local patched = 0
for _, item in ipairs(positions) do
  local legacyEntry = legacy[item.key]
  local fields = {}

  local indent = '    '
  local headerLine = src:sub(item.lineStart):match('^[^\\n]*')
  if headerLine then
    local leading = headerLine:match('^(%s*)')
    if leading and #leading > 0 then
      indent = leading .. '    '
    end
  end

  if item.needZones and legacyEntry.zones then
    table.insert(fields, indent .. 'zones = ' .. format_zones(legacyEntry.zones))
  end
  if item.needNote and legacyEntry.note then
    local note = escape_lua_string(tostring(legacyEntry.note))
    table.insert(fields, indent .. 'note = ' .. note .. ',')
  end

  if #fields > 0 then
    local insertText = '\n' .. table.concat(fields, '\n') .. '\n'
    src = src:sub(1, item.closePos - 1) .. insertText .. src:sub(item.closePos)
    patched = patched + 1
  end
end

write_file(npcPath, src)
print('patched_entries=' .. patched)
print('positions=' .. #positions)

local ok = os.execute('luac -p "' .. npcPath .. '"')
if ok ~= 0 then
  os.exit(1)
end
