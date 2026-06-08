local path='data/npc_icons.lua'
local f=assert(io.open(path,'r'))
local src=f:read('*a')
f:close()

local start = src:find('%[%"%?%?%? Warmachine%"%]')
if not start then
  error('start not found')
end
local closePos = src:find('\n%s*},\r?\n', start)
if not closePos then
  error('close not found')
end

local replacement = [[    ["??? Warmachine"]                         = { type = 'Orc Warmachine', icon = 'Dialogue.png', zones = { "Bibiki Bay - Purgonorgo Isle", "Outland" },
        note = "Involved in Quests:\n* One Good Deed?\n\nInvolved in Missions:\n* Promathia Mission 5-3\n* Promathia Mission 8-4",
    },]]

local before = src:sub(1, start - 1)
local after = src:sub(closePos + 6) -- skip '\n    },\n' length 6 (\n + 4 + }, + newline)
src = before .. replacement .. after

local g=assert(io.open(path,'w'))
g:write(src)
g:close()
