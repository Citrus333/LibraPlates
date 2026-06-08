local lines={}
for l in io.lines('data/npc_icons.lua') do table.insert(lines,l) end
local i=3699
local s=lines[i]
local next=lines[i+1]
print('s=' .. s)
print('not comma', tostring(not s:find(',%s*$')))
print('next=' .. tostring(next))
print('nextmatch=' .. tostring(next:match('^%s*(zones|note)%s*=')))
local iconPos=s:find('icon')
print('iconPos', iconPos)
if iconPos then
  local eq=s:find('=',iconPos)
  print('eq',eq)
  local afterEq=s:sub(eq+1):match('^%s*(.*)')
  print('afterEq', afterEq)
  local first=afterEq:sub(1,1)
  print('first', first)
  local j=2
  while true do
    local ch=afterEq:sub(j,j)
    print('scan',j,ch)
    if ch=='' then break end
    if ch=='\\' then
      j=j+2
    elseif ch=="'" then
      print('found close', j)
      local tail=afterEq:sub(j+1)
      print('tail', '['..tail..']')
      print('tailBlank', tostring(tail:match('^%s*$')))
      break
    else
      j=j+1
    end
  end
end
