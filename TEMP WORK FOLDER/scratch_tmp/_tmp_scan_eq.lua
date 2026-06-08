local f = assert(io.open('data/npc_icons.lua','r'))
for line in f:lines() do
  if line:find('= {') and not line:find(',%s*$') then
    print(line)
  end
end
f:close()
