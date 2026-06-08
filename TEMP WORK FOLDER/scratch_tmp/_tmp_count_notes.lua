local f=assert(io.open('data/npc_icons.lua','r'))
local count=0
local total=0
for l in f:lines() do
  total=total+1
  if l:match('note%s*=%s*".*\\n') then count=count+1 end
end
f:close()
print('lines_with_escaped_n', count)
print('total_lines', total)
