local plates = {};
local perfMeter = require('core.perf_meter');
local log = require('core.log');

local renderWarnings = {};
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
    local ok, err = true, nil;
    if (perfIsolation.self ~= true) then
        ok, err = pcall(plates.self.Render);
    end
    if (ok ~= true and renderWarnings.self ~= true) then
        renderWarnings.self = true;
        log.Warn('Self plates disabled after render error: ' .. tostring(err));
    end
    perfMeter.Stop('plates.self', selfStart);

    local enemyStart = perfMeter.Start();
    ok, err = true, nil;
    if (perfIsolation.enemy ~= true) then
        ok, err = pcall(plates.enemy.Render, false);
    end
    if (ok ~= true and renderWarnings.enemy ~= true) then
        renderWarnings.enemy = true;
        log.Warn('Enemy plates disabled after render error: ' .. tostring(err));
    end
    perfMeter.Stop('plates.enemy', enemyStart);

    local pcStart = perfMeter.Start();
    ok, err = true, nil;
    if (perfIsolation.pc ~= true) then
        ok, err = pcall(plates.pc.Render);
    end
    if (ok ~= true and renderWarnings.pc ~= true) then
        renderWarnings.pc = true;
        log.Warn('PC plates disabled after render error: ' .. tostring(err));
    end
    perfMeter.Stop('plates.pc', pcStart);

    local trustStart = perfMeter.Start();
    ok, err = true, nil;
    if (perfIsolation.trust ~= true) then
        ok, err = pcall(plates.trust.Render);
    end
    if (ok ~= true and renderWarnings.trust ~= true) then
        renderWarnings.trust = true;
        log.Warn('Trust plates disabled after render error: ' .. tostring(err));
    end
    perfMeter.Stop('plates.trust', trustStart);

    local petStart = perfMeter.Start();
    ok, err = true, nil;
    if (perfIsolation.pet ~= true) then
        ok, err = pcall(plates.pet.Render);
    end
    if (ok ~= true and renderWarnings.pet ~= true) then
        renderWarnings.pet = true;
        log.Warn('Pet plates disabled after render error: ' .. tostring(err));
    end
    perfMeter.Stop('plates.pet', petStart);

    local npcStart = perfMeter.Start();
    ok, err = true, nil;
    if (perfIsolation.npc ~= true) then
        ok, err = pcall(plates.npc.Render);
    end
    if (ok ~= true and renderWarnings.npc ~= true) then
        renderWarnings.npc = true;
        log.Warn('NPC/Object plates disabled after render error: ' .. tostring(err));
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
