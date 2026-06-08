for i,s in ipairs((function() local t={}; for l in io.lines('data/npc_icons.lua') do t[#t+1]=l end; return t end)()) do
  if s:find('Da') and s:find('Vhu') then
    print(i, s)
  end
end
