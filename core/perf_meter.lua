local perfMeter = {};

local imgui = require('imgui');

local overlayEnabled = false;
local detailEnabled = false;
local samples = {};
local counters = {};
local lastCounters = {};
local frameIndex = 0;
local smoothing = 0.10;

local displayOrder = {
    'total',
    'settings',
    'targeting',
    'native',
    'plates.total',
    'plates.self',
    'plates.enemy',
    'plates.pc',
    'plates.trust',
    'plates.pet',
    'plates.npc',
    'world.draw',
    'target.overlay',
    'peer',
    'quick.menu',
};

local detailOrder = {
    'native.hook',
    'target.marker.build',
    'npc.scan',
    'npc.resolve',
    'npc.fastCache',
    'npc.settings',
    'npc.signature',
    'npc.canvas',
    'npc.queue',
    'pc.scan',
    'pc.settings',
    'pc.icons',
    'pc.build',
    'pc.status',
    'pc.canvas',
    'pc.queue',
    'trust.scan',
    'trust.settings',
    'trust.build',
    'trust.canvas',
    'trust.queue',
    'enemy.scan',
    'enemy.settings',
    'enemy.build',
    'enemy.status',
    'enemy.canvas',
    'enemy.queue',
};

local labels = {
    ['total'] = 'Total',
    ['settings'] = 'Settings',
    ['targeting'] = 'Targeting',
    ['native'] = 'Native hide',
    ['plates.total'] = 'Plates',
    ['plates.self'] = '  Self',
    ['plates.enemy'] = '  Enemy',
    ['plates.pc'] = '  PC',
    ['plates.trust'] = '  Trust',
    ['plates.pet'] = '  Pet',
    ['plates.npc'] = '  NPC/Object',
    ['world.draw'] = 'World draw',
    ['target.overlay'] = 'Target overlay',
    ['peer'] = 'Peer',
    ['quick.menu'] = 'Quick menu',
    ['native.hook'] = 'Native hook',
    ['target.marker.build'] = 'Target build',
    ['npc.scan'] = 'NPC scan',
    ['npc.resolve'] = 'NPC resolve',
    ['npc.fastCache'] = 'NPC fast cache',
    ['npc.settings'] = 'NPC settings',
    ['npc.signature'] = 'NPC signature',
    ['npc.canvas'] = 'NPC canvas',
    ['npc.queue'] = 'NPC queue',
    ['pc.scan'] = 'PC scan',
    ['pc.settings'] = 'PC settings',
    ['pc.icons'] = 'PC icons',
    ['pc.build'] = 'PC build',
    ['pc.status'] = 'PC status',
    ['pc.canvas'] = 'PC canvas',
    ['pc.queue'] = 'PC queue',
    ['trust.scan'] = 'Trust scan',
    ['trust.settings'] = 'Trust settings',
    ['trust.build'] = 'Trust build',
    ['trust.canvas'] = 'Trust canvas',
    ['trust.queue'] = 'Trust queue',
    ['enemy.scan'] = 'Enemy scan',
    ['enemy.settings'] = 'Enemy settings',
    ['enemy.build'] = 'Enemy build',
    ['enemy.status'] = 'Enemy status',
    ['enemy.canvas'] = 'Enemy canvas',
    ['enemy.queue'] = 'Enemy queue',
};

local function FormatMs(value)
    return string.format('%.2f', tonumber(value) or 0);
end

local function Record(name, elapsedMs)
    if (name == nil or elapsedMs == nil) then
        return;
    end

    local key = tostring(name);
    local entry = samples[key];

    if (entry == nil) then
        entry = {
            last = elapsedMs,
            avg = elapsedMs,
            peak = elapsedMs,
            count = 0,
        };
        samples[key] = entry;
    end

    entry.last = elapsedMs;
    entry.avg = (entry.avg * (1.0 - smoothing)) + (elapsedMs * smoothing);
    entry.peak = math.max(entry.peak or 0, elapsedMs);
    entry.count = (entry.count or 0) + 1;
end

local function AddLine(lines, name)
    local entry = samples[name];

    if (entry == nil) then
        return;
    end

    lines[#lines + 1] = string.format(
        '%-14s %6sms avg  %6sms peak  %6sms last',
        labels[name] or name,
        FormatMs(entry.avg),
        FormatMs(entry.peak),
        FormatMs(entry.last)
    );
end

function perfMeter.BeginFrame()
    frameIndex = frameIndex + 1;
    lastCounters = counters;
    counters = {};
end

function perfMeter.Start()
    return os.clock();
end

function perfMeter.Stop(name, startClock)
    if (startClock == nil) then
        return;
    end

    Record(name, (os.clock() - startClock) * 1000.0);
end

function perfMeter.Count(name, amount)
    if (name == nil) then
        return;
    end

    local key = tostring(name);
    counters[key] = (tonumber(counters[key]) or 0) + (tonumber(amount) or 1);
end

local function GetCounter(name)
    local key = tostring(name or '');
    local current = counters[key];

    if (current ~= nil) then
        return current;
    end

    return lastCounters[key] or 0;
end

function perfMeter.BeginDetail(name)
    if (detailEnabled ~= true) then
        return nil;
    end

    local key = tostring(name or 'detail');
    perfMeter.Count(key .. '.calls', 1);

    return {
        name = key,
        clock = os.clock(),
    };
end

function perfMeter.EndDetail(token)
    if (token == nil or token.clock == nil or token.name == nil) then
        return;
    end

    Record(token.name, (os.clock() - token.clock) * 1000.0);
end

function perfMeter.CountCanvasRender(plate, key)
    perfMeter.Count('canvasRenders', 1);

    if (detailEnabled ~= true) then
        return;
    end

    local canvasKey = tostring(key or 'self');
    local targetMarker = plate ~= nil and plate.targetMarker or nil;

    if (canvasKey:match('^enemy')) then
        perfMeter.Count('canvasEnemy', 1);
    elseif (canvasKey:match('^pc')) then
        perfMeter.Count('canvasPc', 1);
    elseif (canvasKey:match('^trust')) then
        perfMeter.Count('canvasTrust', 1);
    elseif (canvasKey:match('pet')) then
        perfMeter.Count('canvasPet', 1);
    elseif (canvasKey:match('^npc') or canvasKey:match('^object') or canvasKey:match('^npc%-cache')) then
        perfMeter.Count('canvasNpcObject', 1);
    else
        perfMeter.Count('canvasSelf', 1);
    end

    if (targetMarker ~= nil and targetMarker.enabled == true) then
        perfMeter.Count('canvasTargeted', 1);
    end
end

function perfMeter.SetCounter(name, value)
    if (name == nil) then
        return;
    end

    counters[tostring(name)] = tonumber(value) or 0;
end

function perfMeter.SetOverlayEnabled(value)
    overlayEnabled = value == true;
end

function perfMeter.GetOverlayEnabled()
    return overlayEnabled == true;
end

function perfMeter.SetDetailEnabled(value)
    detailEnabled = value == true;
end

function perfMeter.GetDetailEnabled()
    return detailEnabled == true;
end

function perfMeter.GetMetric(name)
    local entry = samples[tostring(name or '')];

    if (entry == nil) then
        return {
            avg = 0,
            peak = 0,
            last = 0,
        };
    end

    return {
        avg = tonumber(entry.avg) or 0,
        peak = tonumber(entry.peak) or 0,
        last = tonumber(entry.last) or 0,
    };
end

function perfMeter.GetCounterValue(name)
    return tonumber(GetCounter(name)) or 0;
end

function perfMeter.GetDiagnosticLine()
    local total = perfMeter.GetMetric('total');
    local settings = perfMeter.GetMetric('settings');
    local targetingMetric = perfMeter.GetMetric('targeting');
    local nativeMetric = perfMeter.GetMetric('native');
    local plates = perfMeter.GetMetric('plates.total');
    local self = perfMeter.GetMetric('plates.self');
    local selfCacheHits = perfMeter.GetCounterValue('self.cache.hit');
    local selfCacheMisses = perfMeter.GetCounterValue('self.cache.miss');
    local pc = perfMeter.GetMetric('plates.pc');
    local pcScan = perfMeter.GetMetric('pc.scan');
    local pcSettings = perfMeter.GetMetric('pc.settings');
    local pcIcons = perfMeter.GetMetric('pc.icons');
    local pcBuild = perfMeter.GetMetric('pc.build');
    local pcStatus = perfMeter.GetMetric('pc.status');
    local pcCanvas = perfMeter.GetMetric('pc.canvas');
    local pcQueue = perfMeter.GetMetric('pc.queue');
    local pcScanCalls = perfMeter.GetCounterValue('pc.scan.calls');
    local pcSettingsCalls = perfMeter.GetCounterValue('pc.settings.calls');
    local pcIconsCalls = perfMeter.GetCounterValue('pc.icons.calls');
    local pcBuildCalls = perfMeter.GetCounterValue('pc.build.calls');
    local pcStatusCalls = perfMeter.GetCounterValue('pc.status.calls');
    local pcCanvasCalls = perfMeter.GetCounterValue('pc.canvas.calls');
    local pcQueueCalls = perfMeter.GetCounterValue('pc.queue.calls');
    local pcCacheHits = perfMeter.GetCounterValue('pc.cache.hit');
    local pcCacheMisses = perfMeter.GetCounterValue('pc.cache.miss');
    local pcScanCacheHits = perfMeter.GetCounterValue('pc.scan.cacheHit');
    local pcScanCacheMisses = perfMeter.GetCounterValue('pc.scan.cacheMiss');
    local native = perfMeter.GetMetric('native.hook');
    local targetBuild = perfMeter.GetMetric('target.marker.build');
    local worldDraw = perfMeter.GetMetric('world.draw');
    local targetOverlay = perfMeter.GetMetric('target.overlay');
    local peer = perfMeter.GetMetric('peer');
    local quickMenu = perfMeter.GetMetric('quick.menu');
    local npc = perfMeter.GetMetric('plates.npc');
    local npcScan = perfMeter.GetMetric('npc.scan');
    local npcResolve = perfMeter.GetMetric('npc.resolve');
    local npcFastCache = perfMeter.GetMetric('npc.fastCache');
    local npcSettings = perfMeter.GetMetric('npc.settings');
    local npcSignature = perfMeter.GetMetric('npc.signature');
    local npcCanvas = perfMeter.GetMetric('npc.canvas');
    local npcQueue = perfMeter.GetMetric('npc.queue');
    local npcScanCalls = perfMeter.GetCounterValue('npc.scan.calls');
    local npcResolveCalls = perfMeter.GetCounterValue('npc.resolve.calls');
    local npcFastCacheCalls = perfMeter.GetCounterValue('npc.fastCache.calls');
    local npcSettingsCalls = perfMeter.GetCounterValue('npc.settings.calls');
    local npcSignatureCalls = perfMeter.GetCounterValue('npc.signature.calls');
    local npcCanvasCalls = perfMeter.GetCounterValue('npc.canvas.calls');
    local npcQueueCalls = perfMeter.GetCounterValue('npc.queue.calls');
    local trust = perfMeter.GetMetric('plates.trust');
    local trustScan = perfMeter.GetMetric('trust.scan');
    local trustSettings = perfMeter.GetMetric('trust.settings');
    local trustBuild = perfMeter.GetMetric('trust.build');
    local trustCanvas = perfMeter.GetMetric('trust.canvas');
    local trustQueue = perfMeter.GetMetric('trust.queue');
    local trustScanCalls = perfMeter.GetCounterValue('trust.scan.calls');
    local trustSettingsCalls = perfMeter.GetCounterValue('trust.settings.calls');
    local trustBuildCalls = perfMeter.GetCounterValue('trust.build.calls');
    local trustCanvasCalls = perfMeter.GetCounterValue('trust.canvas.calls');
    local trustQueueCalls = perfMeter.GetCounterValue('trust.queue.calls');
    local trustCacheHits = perfMeter.GetCounterValue('trust.cache.hit');
    local trustCacheMisses = perfMeter.GetCounterValue('trust.cache.miss');
    local pet = perfMeter.GetMetric('plates.pet');
    local enemy = perfMeter.GetMetric('plates.enemy');
    local enemyScan = perfMeter.GetMetric('enemy.scan');
    local enemySettings = perfMeter.GetMetric('enemy.settings');
    local enemyBuild = perfMeter.GetMetric('enemy.build');
    local enemyStatus = perfMeter.GetMetric('enemy.status');
    local enemyCanvas = perfMeter.GetMetric('enemy.canvas');
    local enemyQueue = perfMeter.GetMetric('enemy.queue');
    local enemyScanCalls = perfMeter.GetCounterValue('enemy.scan.calls');
    local enemySettingsCalls = perfMeter.GetCounterValue('enemy.settings.calls');
    local enemyBuildCalls = perfMeter.GetCounterValue('enemy.build.calls');
    local enemyStatusCalls = perfMeter.GetCounterValue('enemy.status.calls');
    local enemyCanvasCalls = perfMeter.GetCounterValue('enemy.canvas.calls');
    local enemyQueueCalls = perfMeter.GetCounterValue('enemy.queue.calls');
    local enemyCacheHits = perfMeter.GetCounterValue('enemy.cache.hit');
    local enemyCacheMisses = perfMeter.GetCounterValue('enemy.cache.miss');

    return string.format(
        'perf frame=%s overlay=%s detail=%s total_avg=%.3f total_last=%.3f total_peak=%.3f settings_avg=%.3f targeting_avg=%.3f native_avg=%.3f plates_avg=%.3f self_avg=%.3f self_cache_hits=%s self_cache_misses=%s pc_avg=%.3f pc_scan_avg=%.3f pc_scan_calls=%s pc_scan_cache_hits=%s pc_scan_cache_misses=%s pc_settings_avg=%.3f pc_settings_calls=%s pc_icons_avg=%.3f pc_icons_calls=%s pc_build_avg=%.3f pc_build_calls=%s pc_status_avg=%.3f pc_status_calls=%s pc_canvas_avg=%.3f pc_canvas_calls=%s pc_queue_avg=%.3f pc_queue_calls=%s pc_cache_hits=%s pc_cache_misses=%s npc_avg=%.3f npc_scan_avg=%.3f npc_scan_calls=%s npc_resolve_avg=%.3f npc_resolve_calls=%s npc_fast_avg=%.3f npc_fast_calls=%s npc_settings_avg=%.3f npc_settings_calls=%s npc_signature_avg=%.3f npc_signature_calls=%s npc_canvas_avg=%.3f npc_canvas_calls=%s npc_queue_avg=%.3f npc_queue_calls=%s trust_avg=%.3f trust_scan_avg=%.3f trust_scan_calls=%s trust_settings_avg=%.3f trust_settings_calls=%s trust_build_avg=%.3f trust_build_calls=%s trust_canvas_avg=%.3f trust_canvas_calls=%s trust_queue_avg=%.3f trust_queue_calls=%s trust_cache_hits=%s trust_cache_misses=%s pet_avg=%.3f enemy_avg=%.3f enemy_scan_avg=%.3f enemy_scan_calls=%s enemy_settings_avg=%.3f enemy_settings_calls=%s enemy_build_avg=%.3f enemy_build_calls=%s enemy_status_avg=%.3f enemy_status_calls=%s enemy_canvas_avg=%.3f enemy_canvas_calls=%s enemy_queue_avg=%.3f enemy_queue_calls=%s enemy_cache_hits=%s enemy_cache_misses=%s world_draw_avg=%.3f target_overlay_avg=%.3f peer_avg=%.3f quick_menu_avg=%.3f native_hook_avg=%.3f native_hook_calls=%s target_build_avg=%.3f target_build_calls=%s queued=%s drawn=%s clickRects=%s canvas=%s targetedCanvas=%s',
        tostring(frameIndex),
        tostring(overlayEnabled == true),
        tostring(detailEnabled == true),
        total.avg,
        total.last,
        total.peak,
        settings.avg,
        targetingMetric.avg,
        nativeMetric.avg,
        plates.avg,
        self.avg,
        tostring(selfCacheHits),
        tostring(selfCacheMisses),
        pc.avg,
        pcScan.avg,
        tostring(pcScanCalls),
        tostring(pcScanCacheHits),
        tostring(pcScanCacheMisses),
        pcSettings.avg,
        tostring(pcSettingsCalls),
        pcIcons.avg,
        tostring(pcIconsCalls),
        pcBuild.avg,
        tostring(pcBuildCalls),
        pcStatus.avg,
        tostring(pcStatusCalls),
        pcCanvas.avg,
        tostring(pcCanvasCalls),
        pcQueue.avg,
        tostring(pcQueueCalls),
        tostring(pcCacheHits),
        tostring(pcCacheMisses),
        npc.avg,
        npcScan.avg,
        tostring(npcScanCalls),
        npcResolve.avg,
        tostring(npcResolveCalls),
        npcFastCache.avg,
        tostring(npcFastCacheCalls),
        npcSettings.avg,
        tostring(npcSettingsCalls),
        npcSignature.avg,
        tostring(npcSignatureCalls),
        npcCanvas.avg,
        tostring(npcCanvasCalls),
        npcQueue.avg,
        tostring(npcQueueCalls),
        trust.avg,
        trustScan.avg,
        tostring(trustScanCalls),
        trustSettings.avg,
        tostring(trustSettingsCalls),
        trustBuild.avg,
        tostring(trustBuildCalls),
        trustCanvas.avg,
        tostring(trustCanvasCalls),
        trustQueue.avg,
        tostring(trustQueueCalls),
        tostring(trustCacheHits),
        tostring(trustCacheMisses),
        pet.avg,
        enemy.avg,
        enemyScan.avg,
        tostring(enemyScanCalls),
        enemySettings.avg,
        tostring(enemySettingsCalls),
        enemyBuild.avg,
        tostring(enemyBuildCalls),
        enemyStatus.avg,
        tostring(enemyStatusCalls),
        enemyCanvas.avg,
        tostring(enemyCanvasCalls),
        enemyQueue.avg,
        tostring(enemyQueueCalls),
        tostring(enemyCacheHits),
        tostring(enemyCacheMisses),
        worldDraw.avg,
        targetOverlay.avg,
        peer.avg,
        quickMenu.avg,
        native.avg,
        tostring(perfMeter.GetCounterValue('native.hook.calls')),
        targetBuild.avg,
        tostring(perfMeter.GetCounterValue('target.marker.build.calls')),
        tostring(perfMeter.GetCounterValue('queued')),
        tostring(perfMeter.GetCounterValue('drawn')),
        tostring(perfMeter.GetCounterValue('clickRects')),
        tostring(perfMeter.GetCounterValue('canvasRenders')),
        tostring(perfMeter.GetCounterValue('canvasTargeted'))
    );
end

function perfMeter.Reset()
    samples = {};
    counters = {};
    lastCounters = {};
    frameIndex = 0;
end

function perfMeter.GetSummaryLines()
    local lines = {};

    lines[#lines + 1] = 'LibraPlates perf frame=' .. tostring(frameIndex) .. ' overlay=' .. tostring(overlayEnabled == true);

    for _, name in ipairs(displayOrder) do
        AddLine(lines, name);
    end

    if (detailEnabled == true) then
        for _, name in ipairs(detailOrder) do
            AddLine(lines, name);
        end
    end

    lines[#lines + 1] = string.format(
        'Counts         queued=%s drawn=%s clickRects=%s canvas=%s',
        tostring(GetCounter('queued')),
        tostring(GetCounter('drawn')),
        tostring(GetCounter('clickRects')),
        tostring(GetCounter('canvasRenders'))
    );

    if (detailEnabled == true) then
        lines[#lines + 1] = string.format(
            'Detail counts  nativeCalls=%s targetBuilds=%s npcScan=%s npcResolve=%s npcFast=%s npcSettings=%s npcSignature=%s npcCanvas=%s npcQueue=%s self=%s enemy=%s pc=%s trust=%s pet=%s npc=%s targeted=%s',
            tostring(GetCounter('native.hook.calls')),
            tostring(GetCounter('target.marker.build.calls')),
            tostring(GetCounter('npc.scan.calls')),
            tostring(GetCounter('npc.resolve.calls')),
            tostring(GetCounter('npc.fastCache.calls')),
            tostring(GetCounter('npc.settings.calls')),
            tostring(GetCounter('npc.signature.calls')),
            tostring(GetCounter('npc.canvas.calls')),
            tostring(GetCounter('npc.queue.calls')),
            tostring(GetCounter('canvasSelf')),
            tostring(GetCounter('canvasEnemy')),
            tostring(GetCounter('canvasPc')),
            tostring(GetCounter('canvasTrust')),
            tostring(GetCounter('canvasPet')),
            tostring(GetCounter('canvasNpcObject')),
            tostring(GetCounter('canvasTargeted'))
        );
    end

    if (#lines == 2) then
        lines[#lines + 1] = 'No samples yet. Turn the overlay on and let one frame render.';
    end

    return lines;
end

function perfMeter.RenderOverlay()
    if (overlayEnabled ~= true) then
        return;
    end

    local drawList = (imgui.GetForegroundDrawList ~= nil) and imgui.GetForegroundDrawList() or nil;

    if (drawList == nil or drawList.AddText == nil or drawList.AddRectFilled == nil) then
        return;
    end

    local lines = perfMeter.GetSummaryLines();
    local x = 18;
    local y = 148;
    local lineHeight = 15;
    local width = 430;
    local height = (#lines * lineHeight) + 12;

    drawList:AddRectFilled({ x - 8, y - 7 }, { x + width, y + height }, 0xD8191F26);

    for index, line in ipairs(lines) do
        local color = 0xFFFFFFFF;

        if (index == 1) then
            color = 0xFF6FE8F0;
        elseif (line:find('Counts', 1, true) ~= nil) then
            color = 0xFFFFD84D;
        end

        drawList:AddText({ x, y + ((index - 1) * lineHeight) }, color, line);
    end
end

return perfMeter;
