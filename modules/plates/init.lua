local plates = {};
local perfMeter = require('core.perf_meter');

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
    plates.self.Render();
    perfMeter.Stop('plates.self', selfStart);

    local enemyStart = perfMeter.Start();
    plates.enemy.Render(false);
    perfMeter.Stop('plates.enemy', enemyStart);

    local pcStart = perfMeter.Start();
    plates.pc.Render();
    perfMeter.Stop('plates.pc', pcStart);

    local trustStart = perfMeter.Start();
    plates.trust.Render();
    perfMeter.Stop('plates.trust', trustStart);

    local petStart = perfMeter.Start();
    plates.pet.Render();
    perfMeter.Stop('plates.pet', petStart);

    local npcStart = perfMeter.Start();
    plates.npc.Render();
    perfMeter.Stop('plates.npc', npcStart);
end

return plates;
