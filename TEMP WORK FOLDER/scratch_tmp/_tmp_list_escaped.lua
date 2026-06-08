local f=assert(io.open('data/npc_icons.lua','r'))
local i=0
local lastKey=nil
for l in f:lines() do
  i=i+1
  local k = l:match('^%s*%[.:%s*([^"]+)')
  if not k then
    k = l:match('^%s*"([^"]+)"%s*=%s*{') or l:match("^%s*'([^']+)'%s*=%s*{")
  end
  if k then lastKey = k end
  if l:match('note%s*=') and l:match('\\n') then
    print(i, lastKey, l)
  end
end
