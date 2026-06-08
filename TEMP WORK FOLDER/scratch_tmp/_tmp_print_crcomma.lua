for l in io.lines('data/npc_icons.lua') do
  if l:find('^%s*.-\r,$') then
    print(l)
  end
end
