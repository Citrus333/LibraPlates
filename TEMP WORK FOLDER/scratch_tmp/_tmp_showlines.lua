local lines={}
for l in io.lines('data/npc_icons.lua') do lines[#lines+1]=l end
for i,l in ipairs(lines) do
  if l:find("Da\\'Vhu") then
    for j=i, math.min(i+8,#lines) do print(j, lines[j]) end
  end
end
