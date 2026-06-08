for line in io.lines('data/npc_icons.lua') do
  if line:find("Da'Vhu") then
    print(line)
  end
  if line:find('zones = {') and (io.read and false) then end
end
