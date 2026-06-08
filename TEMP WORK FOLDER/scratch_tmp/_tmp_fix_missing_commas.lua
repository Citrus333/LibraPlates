local path = 'data/npc_icons.lua'
local f = assert(io.open(path, 'r'))
local lines = {}
for line in f:lines() do
  table.insert(lines, line)
end
f:close()

local function is_target_next(line)
  return line:match('^%s*zones%s*=') ~= nil or line:match('^%s*note%s*=') ~= nil
end

local changed = 0
for i=1, #lines - 1 do
  local s = lines[i]
  local next = lines[i+1] or ''

  if s:find('= {') and not s:find(',%s*$') then
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
            local ch = afterEq:sub(j, j)
            if ch == '\\' then
              j = j + 2
            elseif ch == quote then
              local tail = afterEq:sub(j + 1)
              if tail:match('^%s*$') and is_target_next(next) then
                lines[i] = s .. ','
                changed = changed + 1
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

local g = assert(io.open(path, 'w'))
for i,line in ipairs(lines) do
  g:write(line)
  g:write('\n')
end
g:close()
print('fixed=' .. changed)
