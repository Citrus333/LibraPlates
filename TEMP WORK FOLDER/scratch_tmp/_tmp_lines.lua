local function read_file(path)
  local f=assert(io.open(path,'r'))
  local src=f:read('*a')
  f:close()
  return src
end

local src = read_file('C:\\catseyexi\\catseyexi-client\\Ashita\\addons\\LibraPlates\\data\\npc_icons.lua')
src = src:gsub('local%s+npcIcons%s*=\\s*T%s*{', 'npcIcons = {')
src = src:gsub('local%s+npcIcons%s*=%s*T%s*{', 'npcIcons = {')
src = 'local T = function(t) return t end\n' .. src

local i=1
for line in src:gmatch('(.-)\n') do
  if i>=2955 and i<=2970 then
    print(i .. ':' .. line)
  end
  i=i+1
end
print('total='..i)
