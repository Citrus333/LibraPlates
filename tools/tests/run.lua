-- Standalone LibraPlates regression tests.
-- Run from the addon root with: lua tools/tests/run.lua
-- This file is never required by LibraPlates during gameplay.

package.path = '.\\?.lua;.\\?\\init.lua;' .. package.path;

local passed = 0;
local failed = 0;

local function Fail(message)
    error(tostring(message or 'assertion failed'), 2);
end

local function AssertTrue(value, message)
    if (value ~= true) then
        Fail(message or ('expected true, got ' .. tostring(value)));
    end
end

local function AssertEqual(actual, expected, message)
    if (actual ~= expected) then
        Fail(
            tostring(message or 'values differ') ..
            ': expected=' .. tostring(expected) ..
            ' actual=' .. tostring(actual)
        );
    end
end

local function Test(name, callback)
    io.write('[TEST] ' .. tostring(name) .. ' ... ');
    local ok, err = pcall(callback);

    if (ok == true) then
        passed = passed + 1;
        print('PASS');
    else
        failed = failed + 1;
        print('FAIL');
        print('       ' .. tostring(err));
    end
end

local function ReadAll(path)
    local file = assert(io.open(path, 'rb'));
    local value = file:read('*a');
    file:close();
    return value;
end

Test('error boundary isolates failures and preserves return values', function()
    local warnings = {};
    package.loaded['core.error_boundary'] = nil;
    package.loaded['core.log'] = nil;
    package.preload['core.log'] = function()
        return {
            Warn = function(message)
                warnings[#warnings + 1] = tostring(message);
            end,
        };
    end;

    local boundary = require('core.error_boundary');
    boundary.Reset();

    local ok = boundary.Call('broken', 'Broken subsystem', function()
        error('deliberate failure');
    end);
    AssertEqual(ok, false, 'failing subsystem must be caught');

    local good, first, second = boundary.Call('healthy', 'Healthy subsystem', function()
        return 'continued', 42;
    end);
    AssertEqual(good, true, 'following subsystem must still run');
    AssertEqual(first, 'continued', 'first return value must survive');
    AssertEqual(second, 42, 'second return value must survive');
    AssertEqual(#warnings, 1, 'first continuous failure should log once');

    boundary.Call('broken', 'Broken subsystem', function()
        error('same continuous failure');
    end);
    AssertEqual(#warnings, 1, 'continuous repeat should not flood the log');

    package.preload['core.log'] = nil;
    package.loaded['core.log'] = nil;
    package.loaded['core.error_boundary'] = nil;
end);

Test('shared entity resolver scans once and reuses the snapshot', function()
    local bit = require('bit');
    local serverIds = {};
    local reads = 0;

    serverIds[120] = 500120;
    serverIds[640] = 700640;

    local entityManager = {
        GetServerId = function(_, index)
            reads = reads + 1;
            return serverIds[index] or 0;
        end,
    };
    local memoryManager = {
        GetEntity = function()
            return entityManager;
        end,
    };

    _G.AshitaCore = {
        GetMemoryManager = function()
            return memoryManager;
        end,
    };

    package.loaded['core.entity_resolver'] = nil;
    package.loaded['bit'] = bit;
    local resolver = require('core.entity_resolver');
    resolver.Reset();

    AssertEqual(resolver.GetIndex(500120), 120, 'first server ID should resolve');
    local readsAfterFirstLookup = reads;
    AssertTrue(readsAfterFirstLookup >= 0x8FF, 'first unresolved ID should build one snapshot');

    AssertEqual(resolver.GetIndex(700640), 640, 'second server ID should use shared snapshot');
    AssertEqual(reads, readsAfterFirstLookup + 1, 'cached lookup should only validate its slot');
    AssertEqual(resolver.GetServerId(120), 500120, 'index lookup should share the same resolver');

    package.loaded['core.entity_resolver'] = nil;
    _G.AshitaCore = nil;
end);

Test('anchor geometry attaches each child to its resolved parent', function()
    package.loaded['core.anchor_geometry'] = nil;
    local geometry = require('core.anchor_geometry');
    local anchorMap = {
        ['HP Bar'] = 'hp',
        ['MP Bar'] = 'mp',
        ['TP Bar'] = 'tp',
    };
    local bounds = {
        hp = { x = 100, y = 100, width = 180, height = 12 },
    };

    local mp = geometry.ResolveAnchoredRect(
        { anchorTo = 'HP Bar', anchorPoint = 'Bottom', offsetX = 0, offsetY = 2 },
        'mp',
        { x = 0, y = 0, width = 180, height = 8 },
        bounds,
        anchorMap
    );
    bounds.mp = mp;

    local tp = geometry.ResolveAnchoredRect(
        { anchorTo = 'MP Bar', anchorPoint = 'Bottom', offsetX = 0, offsetY = 2 },
        'tp',
        { x = 0, y = 0, width = 180, height = 6 },
        bounds,
        anchorMap
    );

    AssertEqual(mp.y, 114, 'MP should follow HP bottom');
    AssertEqual(tp.y, 124, 'TP should follow the already-resolved MP bottom');
end);

Test('atomic profile writer keeps validation before replacement', function()
    local source = ReadAll('core\\state.lua');
    local tempPosition = assert(source:find("local temporaryPath = path .. '.tmp'", 1, true));
    local validationPosition = assert(source:find('local loaded = LoadLuaTableFile(temporaryPath)', 1, true));
    local replacePosition = assert(source:find('ReplaceFileAtomically(temporaryPath, path)', 1, true));

    AssertTrue(tempPosition < validationPosition, 'temporary file must be written before validation');
    AssertTrue(validationPosition < replacePosition, 'validation must happen before replacement');
    AssertTrue(source:find('MOVEFILE_REPLACE_EXISTING', 1, true) ~= nil, 'replacement must overwrite atomically');
    AssertTrue(source:find('MOVEFILE_WRITE_THROUGH', 1, true) ~= nil, 'replacement must be flushed through');
end);

Test('NPC/object manifest references loadable Lua tables', function()
    local manifest = assert(dofile('data\\npc_object_zone_manifest.lua'));
    local files = {};

    local function Add(name)
        if (type(name) == 'string' and name ~= '') then
            files[name] = true;
        end
    end

    Add(manifest.global);
    for _, name in pairs(manifest.zoneIds or {}) do Add(name); end
    for _, name in pairs(manifest.zoneNames or {}) do Add(name); end

    local count = 0;
    for fileName in pairs(files) do
        local data = assert(dofile('data\\npc_object_zones\\' .. fileName));
        AssertEqual(type(data), 'table', fileName .. ' must return a table');
        count = count + 1;
    end

    AssertTrue(count > 0, 'manifest must reference at least one zone file');
end);

Test('shutdown countdown clears only on resting status transition', function()
    package.loaded['core.resting_tick'] = nil;
    package.loaded['core.alert_sounds'] = nil;
    package.loaded['core.state'] = nil;
    package.loaded['config.global'] = nil;
    local logoutSoundCount = 0;
    package.preload['core.alert_sounds'] = function()
        return {
            Play = function()
                logoutSoundCount = logoutSoundCount + 1;
            end,
        };
    end;
    package.preload['core.state'] = function()
        return {
            GetGlobalSettings = function()
                return { resting = { logoutSoundEnabled = true } };
            end,
        };
    end;
    package.preload['config.global'] = function()
        return { resting = {} };
    end;

    local restingTick = require('core.resting_tick');
    local countdownSettings = {
        enabled = true,
        enableLogoutCountdown = true,
    };

    restingTick.ResetAll();
    restingTick.HandlePlayerStatus(33);
    restingTick.HandleTextIn({ message = 'Executing shutdown in 30 seconds.' });
    AssertEqual(logoutSoundCount, 1, 'shutdown message must play sound once');
    AssertEqual(restingTick.IsLogoutActive(countdownSettings), true, 'shutdown announcement must start countdown');

    restingTick.HandlePlayerStatus(33);
    AssertEqual(restingTick.IsLogoutActive(countdownSettings), true, 'remaining resting must keep countdown active');

    restingTick.HandlePlayerStatus(0);
    AssertEqual(restingTick.IsLogoutActive(countdownSettings), false, 'resting to non-resting transition must clear countdown');

    restingTick.HandleTextIn({ message = 'Executing shutdown in 20 seconds.' });
    AssertEqual(logoutSoundCount, 2, 'a new shutdown attempt after standing up may play sound once');

    restingTick.ResetAll();
    package.preload['core.alert_sounds'] = nil;
    package.preload['core.state'] = nil;
    package.preload['config.global'] = nil;
    package.loaded['core.resting_tick'] = nil;
    package.loaded['core.alert_sounds'] = nil;
    package.loaded['core.state'] = nil;
    package.loaded['config.global'] = nil;
end);

print(string.format('\nResult: %d passed, %d failed', passed, failed));

if (failed > 0) then
    os.exit(1);
end
