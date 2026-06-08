local lines = {}
local f=io.open('data/npc_icons.lua','r')
for line in f:lines() do table.insert(lines,line) end
f:close()
for i=1,#lines-1 do
  local s=lines[i]
  local next=lines[i+1] or ''
  if s:find('=%s*{') then
    local cond1 = s:match(',%s*$') and 'yes' or 'no'
    local cond2 = (s:match('icon%s*=') ~= nil) and 'yes' or 'no'
    local cond3 = (s:match('icon%s*=\s*\'.-\'\s*$') ~= nil) and 'sq' or (s:match('icon%s*=\s*\".-\"\s*$') and 'dq' or 'no')
    local cond4 = next:match('^%s*(zones|note)%s*=') and 'yes' or 'no'
    if cond1=='no' and cond2=='yes' and cond4=='yes' then
      print(i, cond1, cond2, cond3, cond4, s)
    end
  end
end
