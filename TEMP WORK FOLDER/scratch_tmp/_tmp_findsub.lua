local txt=assert(io.open('data/npc_icons.lua','r')):read('*a')
local pos=1
while true do
  local p = txt:find("Da\\'Vhu", pos, true)
  if not p then break end
  print(p)
  local lineStart = txt:sub(1,p):match('.*()\n') or 1
  if lineStart==1 and txt:sub(1,1)~='\n' then lineStart = 1 end
  local lineEnd = txt:find('\n', p) or #txt+1
  print('line:', txt:sub(lineStart, lineEnd-1))
  pos = p+1
end
