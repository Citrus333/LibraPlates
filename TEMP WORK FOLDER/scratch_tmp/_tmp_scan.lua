local text = assert(io.open('data/npc_icons.lua','r')):read('*a')
local lines = {}
for line in text:gmatch('[^\r\n]*\r?\n?') do
  if line ~= '' then table.insert(lines, line) end
end
for i=1, #lines - 1 do
  local s = lines[i]
  local next = lines[i+1]
  if s:find('icon%s*=%s*\'') and not s:find('icon%s*=.*,%s*\'?') then
    if next:find('^%s*(zones|note)%s*=') then
      print(i, (s:gsub('\r','')))
    end
  end
end
