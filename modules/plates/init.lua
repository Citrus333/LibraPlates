local plates = {};
local perfMeter = require('core.perf_meter');
local log = require('core.log');

local renderWarnings = {};

-- ============================================================
-- Plate modules
-- ============================================================

plates.self = require('modules.plates.self');
plates.enemy = require('modules.plates.enemy');
plates.pc = require('modules.plates.pc');
plates.npc = require('modules.plates.npc');
plates.trust = require('modules.plates.trust');
plates.pet = require('modules.plates.pet');

-- ============================================================
-- Lifecycle
-- ============================================================

function plates.Load()
end

function plates.Unload()
end

-- ============================================================
-- Rendering
-- ============================================================

function plates.Render()
    local selfStart = perfMeter.Start();
    local ok, err = pcall(plates.self.Render);
    if (ok ~= true and renderWarnings.self ~= true) then
        renderWarnings.self = true;
        log.Warn('Self plates disabled after render error: ' .. tostring(err));
    end
    perfMeter.Stop('plates.self', selfStart);

    local enemyStart = perfMeter.Start();
    ok, err = pcall(plates.enemy.Render, false);
    if (ok ~= true and renderWarnings.enemy ~= true) then
        renderWarnings.enemy = true;
        log.Warn('Enemy plates disabled after render error: ' .. tostring(err));
    end
    perfMeter.Stop('plates.enemy', enemyStart);

    local pcStart = perfMeter.Start();
    ok, err = pcall(plates.pc.Render);
    if (ok ~= true and renderWarnings.pc ~= true) then
        renderWarnings.pc = true;
        log.Warn('PC plates disabled after render error: ' .. tostring(err));
    end
    perfMeter.Stop('plates.pc', pcStart);

    local trustStart = perfMeter.Start();
    ok, err = pcall(plates.trust.Render);
    if (ok ~= true and renderWarnings.trust ~= true) then
        renderWarnings.trust = true;
        log.Warn('Trust plates disabled after render error: ' .. tostring(err));
    end
    perfMeter.Stop('plates.trust', trustStart);

    local petStart = perfMeter.Start();
    ok, err = pcall(plates.pet.Render);
    if (ok ~= true and renderWarnings.pet ~= true) then
        renderWarnings.pet = true;
        log.Warn('Pet plates disabled after render error: ' .. tostring(err));
    end
    perfMeter.Stop('plates.pet', petStart);

    local npcStart = perfMeter.Start();
    ok, err = pcall(plates.npc.Render);
    if (ok ~= true and renderWarnings.npc ~= true) then
        renderWarnings.npc = true;
        log.Warn('NPC/Object plates disabled after render error: ' .. tostring(err));
    end
    perfMeter.Stop('plates.npc', npcStart);
end

return plates;
