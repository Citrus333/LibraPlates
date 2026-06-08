local f = assert(io.open('data/npc_icons.lua','r'))
local lines = {}
for l in f:lines() do table.insert(lines,l) end
f:close()

for i=1,#lines-1 do
  local s = lines[i]
  local next = lines[i+1] or ''
  if s:find("= {") and not s:find(",%s*$") then
    local iconPos = s:find('icon')
    if iconPos then
      local eqPos = s:find('=', iconPos)
      if eqPos then
        local afterEq = s:sub(eqPos + 1):match('^%s*(.*)')
        local first = afterEq:sub(1,1)
        if first == '\'' or first == '"' then
          local quote = first
          local j = 2
          while true do
            local ch = afterEq:sub(j,j)
            if ch == '\\' then
              j = j + 2
            elseif ch == quote then
              local tail = afterEq:sub(j+1)
              local okNext = next:match('^%s*(zones|note)%s*=')
              if tail:match('^%s*$') and okNext then
                print('candidate', i, s)
                print('next', next)
                print('tail', '['..tail..']')
                print('eq', eqPos, 'iconPos', iconPos)
              end
              break
            elseif ch == '' then
              break
            else
              j = j + 1
            end
          end
        end
      end
    end
  end
end
