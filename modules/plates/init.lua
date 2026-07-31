local plates = {};
local perfMeter = require('core.perf_meter');
local errorBoundary = require('core.error_boundary');

local perfIsolation = {
    self = false,
    enemy = false,
    pc = false,
    trust = false,
    pet = false,
    npc = false,
};

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
-- Rendering
-- ============================================================

function plates.Render()
    local selfStart = perfMeter.Start();
    if (perfIsolation.self ~= true) then
        errorBoundary.Call('render.plates.self', 'Self plate render', plates.self.Render);
    end
    perfMeter.Stop('plates.self', selfStart);

    local enemyStart = perfMeter.Start();
    if (perfIsolation.enemy ~= true) then
        errorBoundary.Call('render.plates.enemy', 'Enemy plate render', plates.enemy.Render, false);
    end
    perfMeter.Stop('plates.enemy', enemyStart);

    local pcStart = perfMeter.Start();
    if (perfIsolation.pc ~= true) then
        errorBoundary.Call('render.plates.pc', 'PC plate render', plates.pc.Render);
    end
    perfMeter.Stop('plates.pc', pcStart);

    local trustStart = perfMeter.Start();
    if (perfIsolation.trust ~= true) then
        errorBoundary.Call('render.plates.trust', 'Trust plate render', plates.trust.Render);
    end
    perfMeter.Stop('plates.trust', trustStart);

    local petStart = perfMeter.Start();
    if (perfIsolation.pet ~= true) then
        errorBoundary.Call('render.plates.pet', 'Pet plate render', plates.pet.Render);
    end
    perfMeter.Stop('plates.pet', petStart);

    local npcStart = perfMeter.Start();
    if (perfIsolation.npc ~= true) then
        errorBoundary.Call('render.plates.npc', 'NPC/Object plate render', plates.npc.Render);
    end
    perfMeter.Stop('plates.npc', npcStart);
end

function plates.SetPerfIsolation(name, value)
    name = tostring(name or ''):lower();

    if (name == 'allplates' or name == 'plates') then
        local enabled = value == true;
        for key, _ in pairs(perfIsolation) do
            perfIsolation[key] = enabled;
        end
        return true;
    end

    if (perfIsolation[name] == nil) then
        return false;
    end

    perfIsolation[name] = value == true;
    return true;
end

function plates.GetPerfIsolation(name)
    name = tostring(name or ''):lower();
    return perfIsolation[name] == true;
end

function plates.GetPerfIsolationStatus()
    return 'self=' .. tostring(perfIsolation.self == true) ..
        ' enemy=' .. tostring(perfIsolation.enemy == true) ..
        ' pc=' .. tostring(perfIsolation.pc == true) ..
        ' trust=' .. tostring(perfIsolation.trust == true) ..
        ' pet=' .. tostring(perfIsolation.pet == true) ..
        ' npc=' .. tostring(perfIsolation.npc == true);
end

return plates;
