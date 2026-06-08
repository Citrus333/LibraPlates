local function read_lines(path)
  local t={}
  local f=assert(io.open(path,'r'))
  for l in f:lines() do t[#t+1]=l end
  f:close()
  return t
end

local a = read_lines('data/npc_icons.lua')
local b = read_lines('_rollback_safety_20260606-173500-npc-icons-final-step1-step2-wholefile.lua')

local min = math.min(#a,#b)
local count = 0
for i=1,min do
  if a[i] ~= b[i] then
    count = count + 1
    if count <= 40 then
      print('diff', i)
      print('cur: '..a[i])
      print('old: '..b[i])
    end
  end
end
print('total_diff_lines', count)
print('len', #a, #b)
