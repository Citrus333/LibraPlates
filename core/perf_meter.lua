local perfMeter = {};

local imgui = require('imgui');
local adaptivePerformance = require('core.adaptive_performance');

local overlayEnabled = false;
local compactOverlay = true;
local detailEnabled = false;
local timingSortColumn = 'avg';
local timingSortAscending = false;
local samples = {};
local counters = {};
local lastCounters = {};
local frameIndex = 0;
local smoothing = 0.10;
local lastReportStatus = '';
local recordingActive = false;
local recordingStartClock = 0;
local recordingEndClock = 0;
local recordingDuration = 0;
local recordingPreviousDetail = nil;
local recordingLastFrameClock = 0;
local recordingPeakFrameGapMs = 0;
local recordingPeakFrameGapAt = 0;
local eventTrail = {};
local maxEventTrail = 80;
local GetCounter = nil;
local IsTimingRowVisible = nil;

local displayOrder = {
    'present.frame',
    'total',
    'beginscene.frame',
    'endscene.frame',
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
    'event.command',
    'event.textIn',
    'event.packetIn',
    'event.packetOut',
    'event.mouse',
    'alerts.packet',
    'alerts.text',
    'command.actionRange',
    'command.aoe',
    'command.mounts',
    'command.other',
    'actionRange.resolveName',
    'actionRange.apply',
    'native.hook',
    'target.marker.build',
    'npc.scan',
    'npc.tactical.scan',
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
    ['present.frame'] = 'Present event',
    ['total'] = 'Total',
    ['beginscene.frame'] = 'BeginScene event',
    ['endscene.frame'] = 'EndScene event',
    ['settings'] = 'Settings',
    ['targeting'] = 'Targeting',
    ['native'] = 'Native hide',
    ['plates.total'] = 'Plates',
    ['plates.self'] = 'Self module',
    ['plates.enemy'] = 'Enemy module',
    ['plates.pc'] = 'PC module',
    ['plates.trust'] = 'Trust module',
    ['plates.pet'] = 'Pet module',
    ['plates.npc'] = 'NPC/Object module',
    ['world.draw'] = 'World draw',
    ['target.overlay'] = 'Target overlay module',
    ['peer'] = 'Peer module',
    ['quick.menu'] = 'Quick menu module',
    ['event.command'] = 'Command event',
    ['event.textIn'] = 'Text event',
    ['event.packetIn'] = 'Packet in event',
    ['event.packetOut'] = 'Packet out event',
    ['event.mouse'] = 'Mouse event',
    ['alerts.packet'] = 'Alerts packet',
    ['alerts.text'] = 'Alerts text',
    ['command.actionRange'] = 'Command action range',
    ['command.aoe'] = 'Command AOE',
    ['command.mounts'] = 'Command mounts',
    ['command.other'] = 'Command other',
    ['actionRange.resolveName'] = 'Action name resolve',
    ['actionRange.apply'] = 'Action apply',
    ['native.hook'] = 'Native hook',
    ['target.marker.build'] = 'Target build',
    ['npc.scan'] = 'NPC scan',
    ['npc.tactical.scan'] = 'NPC tactical scan',
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

local function GetTierColor(tier)
    local value = tostring(tier or ''):lower();

    if (value == 'stressed') then
        return { 1.0, 0.72, 0.34, 1.0 };
    end

    if (value == 'low') then
        return { 1.0, 0.84, 0.30, 1.0 };
    end

    if (value == 'fps2_stable' or value == 'highfps_under_load') then
        return { 0.86, 0.92, 0.72, 1.0 };
    end

    if (value == 'fps1_stable') then
        return { 0.56, 0.96, 0.70, 1.0 };
    end

    return { 0.92, 0.92, 0.90, 1.0 };
end

local function GetPlateCostColor(value)
    local ms = tonumber(value) or 0;

    if (ms >= 16.0) then
        return { 1.0, 0.42, 0.32, 1.0 };
    end

    if (ms >= 10.0) then
        return { 1.0, 0.72, 0.34, 1.0 };
    end

    if (ms >= 6.0) then
        return { 1.0, 0.84, 0.30, 1.0 };
    end

    if (ms >= 3.0) then
        return { 0.86, 0.92, 0.72, 1.0 };
    end

    return { 0.56, 0.96, 0.70, 1.0 };
end

local function GetLastCounter(name)
    local key = tostring(name or '');

    if (lastCounters[key] ~= nil) then
        return lastCounters[key];
    end

    return counters[key] or 0;
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

local function AddEvent(name, details)
    local now = os.clock();
    local at = now;
    if (recordingActive == true and recordingStartClock ~= nil and recordingStartClock > 0) then
        at = math.max(0, now - recordingStartClock);
    end

    eventTrail[#eventTrail + 1] = {
        at = at,
        name = tostring(name or ''),
        details = tostring(details or ''),
    };

    while (#eventTrail > maxEventTrail) do
        table.remove(eventTrail, 1);
    end
end

local function AddLine(lines, name)
    if (IsTimingRowVisible ~= nil and IsTimingRowVisible(name) ~= true) then
        return;
    end

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

local function HasCounterValue(...)
    local keys = { ... };

    for _, key in ipairs(keys) do
        if ((tonumber(GetCounter(key)) or 0) > 0) then
            return true;
        end
        if ((tonumber(GetLastCounter(key)) or 0) > 0) then
            return true;
        end
    end

    return false;
end

local function GetCanvasSizeBreakdown(category)
    local wanted = tostring(category or ''):lower();
    local prefix = wanted ~= '' and ('drawCanvas.size.' .. wanted .. '.') or 'drawCanvas.size.';
    local entries = {};

    for name, value in pairs(counters) do
        local text = tostring(name or '');
        if (string.sub(text, 1, #prefix) == prefix) then
            entries[#entries + 1] = {
                size = string.sub(text, #prefix + 1),
                count = tonumber(value) or 0,
            };
        end
    end

    for name, value in pairs(lastCounters) do
        local text = tostring(name or '');
        if (string.sub(text, 1, #prefix) == prefix and counters[text] == nil) then
            entries[#entries + 1] = {
                size = string.sub(text, #prefix + 1),
                count = tonumber(value) or 0,
            };
        end
    end

    table.sort(entries, function(left, right)
        if ((tonumber(left.count) or 0) ~= (tonumber(right.count) or 0)) then
            return (tonumber(left.count) or 0) > (tonumber(right.count) or 0);
        end

        return tostring(left.size or '') < tostring(right.size or '');
    end);

    local parts = {};
    for i = 1, math.min(5, #entries) do
        local entry = entries[i];
        if ((tonumber(entry.count) or 0) > 0) then
            parts[#parts + 1] = tostring(entry.size or '?') .. '=' .. tostring(math.floor((tonumber(entry.count) or 0) + 0.5));
        end
    end

    if (#parts == 0) then
        return 'none';
    end

    return table.concat(parts, ' ');
end

IsTimingRowVisible = function(name)
    local key = tostring(name or '');

    if (key == 'plates.enemy') then
        return HasCounterValue(
            'drawCanvas.enemy',
            'canvasEnemy',
            'enemyScanned',
            'enemyQueued',
            'enemyTracked',
            'enemyTargetQueued',
            'enemyBackgroundQueued'
        );
    end

    if (key == 'plates.self') then
        return HasCounterValue(
            'drawCanvas.self',
            'canvasSelf'
        );
    end

    if (key == 'plates.trust') then
        return HasCounterValue(
            'drawCanvas.trust',
            'canvasTrust',
            'trustQueued'
        );
    end

    if (key == 'plates.pet') then
        return HasCounterValue(
            'drawCanvas.pet',
            'canvasPet'
        );
    end

    if (key == 'target.overlay') then
        return HasCounterValue(
            'canvasTargeted',
            'target.marker.build.calls'
        );
    end

    return true;
end

local function BuildTimingRows()
    local rows = {};
    local order = {};

    for _, name in ipairs(displayOrder) do
        order[#order + 1] = name;
    end

    if (detailEnabled == true) then
        for _, name in ipairs(detailOrder) do
            order[#order + 1] = name;
        end
    end

    for index, name in ipairs(order) do
        local entry = samples[name];

        if (entry ~= nil and name ~= 'total' and IsTimingRowVisible(name) == true) then
            rows[#rows + 1] = {
                name = name,
                label = labels[name] or name,
                avg = tonumber(entry.avg) or 0,
                peak = tonumber(entry.peak) or 0,
                last = tonumber(entry.last) or 0,
                order = index,
            };
        end
    end

    table.sort(rows, function(left, right)
        local column = tostring(timingSortColumn or 'avg');

        if (column == 'name') then
            if (timingSortAscending == true) then
                return tostring(left.label) < tostring(right.label);
            end

            return tostring(left.label) > tostring(right.label);
        end

        if (column == 'order') then
            return (tonumber(left.order) or 0) < (tonumber(right.order) or 0);
        end

        local leftValue = tonumber(left[column]) or 0;
        local rightValue = tonumber(right[column]) or 0;

        if (leftValue == rightValue) then
            return (tonumber(left.order) or 0) < (tonumber(right.order) or 0);
        end

        if (timingSortAscending == true) then
            return leftValue < rightValue;
        end

        return leftValue > rightValue;
    end);

    return rows;
end

local function DrawSortHeader(label, column, tooltip)
    local selected = tostring(timingSortColumn or '') == tostring(column or '');
    local arrow = selected and (timingSortAscending == true and ' ^' or ' v') or '';

    if (imgui.Button(tostring(label or '') .. arrow .. '##PerfSort' .. tostring(column or ''))) then
        if (selected == true) then
            timingSortAscending = timingSortAscending ~= true;
        else
            timingSortColumn = tostring(column or 'avg');
            timingSortAscending = false;
        end
    end

    if (imgui.IsItemHovered ~= nil and imgui.IsItemHovered() == true) then
        if (imgui.SetTooltip ~= nil) then
            imgui.SetTooltip(tostring(tooltip));
        elseif (imgui.BeginTooltip ~= nil) then
            imgui.BeginTooltip();
            imgui.Text(tostring(tooltip));
            imgui.EndTooltip();
        end
    end
end

local function DrawTimingSortHeader()
    if (imgui.BeginTable == nil or imgui.TableSetupColumn == nil) then
        DrawSortHeader('Process', 'name', 'Part of LibraPlates being measured.');
        imgui.SameLine();
        DrawSortHeader('Avg', 'avg', 'Time the process is taking.');
        imgui.SameLine();
        DrawSortHeader('Peak', 'peak', 'Highest spike seen so far.');
        imgui.SameLine();
        DrawSortHeader('Last', 'last', 'Time from the most recent frame.');
        return;
    end

    if (imgui.BeginTable('##libraplates_perf_timing_header', 4, 0)) then
        imgui.TableSetupColumn('Process', 0, 168);
        imgui.TableSetupColumn('Avg', 0, 76);
        imgui.TableSetupColumn('Peak', 0, 76);
        imgui.TableSetupColumn('Last', 0, 76);
        imgui.TableNextRow();
        imgui.TableNextColumn();
        DrawSortHeader('Process', 'name', 'Part of LibraPlates being measured.');
        imgui.TableNextColumn();
        DrawSortHeader('Avg', 'avg', 'Time the process is taking.');
        imgui.TableNextColumn();
        DrawSortHeader('Peak', 'peak', 'Highest spike seen so far.');
        imgui.TableNextColumn();
        DrawSortHeader('Last', 'last', 'Time from the most recent frame.');
        imgui.EndTable();
    end
end

local function DrawTimingTable()
    if (imgui.BeginTable == nil or imgui.TableSetupColumn == nil) then
        return false;
    end

    if (imgui.BeginTable('##libraplates_perf_timing_table', 4, 0)) then
        imgui.TableSetupColumn('Process', 0, 168);
        imgui.TableSetupColumn('Avg', 0, 76);
        imgui.TableSetupColumn('Peak', 0, 76);
        imgui.TableSetupColumn('Last', 0, 76);

        for _, row in ipairs(BuildTimingRows()) do
            local rowColor = { 0.92, 0.92, 0.90, 1.0 };

            if (row.name == 'plates.total') then
                rowColor = GetPlateCostColor(row.avg);
            end

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(rowColor, tostring(row.label or ''));
            imgui.TableNextColumn();
            imgui.TextColored(rowColor, FormatMs(row.avg));
            imgui.TableNextColumn();
            imgui.TextColored(rowColor, FormatMs(row.peak));
            imgui.TableNextColumn();
            imgui.TextColored(rowColor, FormatMs(row.last));
        end

        imgui.EndTable();
    end

    return true;
end

local function DrawTotalSummaryLine()
    local total = samples.total or {};

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##libraplates_perf_total_footer', 4, 0)) then
            imgui.TableSetupColumn('Process', 0, 168);
            imgui.TableSetupColumn('Avg', 0, 76);
            imgui.TableSetupColumn('Peak', 0, 76);
            imgui.TableSetupColumn('Last', 0, 76);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, 'Total');
            imgui.TableNextColumn();
            imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, FormatMs(total.avg));
            imgui.TableNextColumn();
            imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, FormatMs(total.peak));
            imgui.TableNextColumn();
            imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, FormatMs(total.last));
            imgui.EndTable();
        end
        return;
    end

    imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, string.format('Total %s  peak %s  last %s', FormatMs(total.avg), FormatMs(total.peak), FormatMs(total.last)));
end

local function DrawAdaptiveStatusLine()
    local mode = tostring(adaptivePerformance.GetEffectiveMode());
    local fps = tonumber(adaptivePerformance.GetEstimatedFps()) or 0;
    local frameMs = tonumber(adaptivePerformance.GetAverageFrameMs()) or 0;
    local color = GetTierColor(adaptivePerformance.GetTier());

    imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, 'Adaptive Mode: ');
    imgui.SameLine();
    imgui.TextColored(color, mode);
    imgui.SameLine();
    imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, string.format('- FPS: %.1f  Frames: %.1fms', fps, frameMs));
end

local function EnsureFolder(path)
    local exists = false;

    pcall(function()
        exists = ashita.fs.exists(path);
    end);

    if (exists == true) then
        return true;
    end

    local ok = pcall(function()
        if (ashita.fs.create_dir ~= nil) then
            ashita.fs.create_dir(path);
        elseif (ashita.fs.create_directory ~= nil) then
            ashita.fs.create_directory(path);
        end
    end);

    return ok == true;
end

local function GetReportPath()
    local installPath = '.';

    pcall(function()
        installPath = AshitaCore:GetInstallPath();
    end);

    local folder = tostring(installPath) .. '\\config\\addons\\LibraPlates\\performance';
    EnsureFolder(tostring(installPath) .. '\\config');
    EnsureFolder(tostring(installPath) .. '\\config\\addons');
    EnsureFolder(tostring(installPath) .. '\\config\\addons\\LibraPlates');
    EnsureFolder(folder);

    local stamp = os.date('%Y%m%d-%H%M%S') or tostring(math.floor(os.clock() * 1000));
    return folder .. '\\LibraPlates-performance-' .. tostring(stamp) .. '.txt';
end

local function GetCacheStats()
    local cacheStats = nil;
    local cacheOk, canvasTexture = pcall(require, 'core.canvas_texture');
    if (cacheOk == true and canvasTexture ~= nil and canvasTexture.GetCacheStats ~= nil) then
        cacheStats = canvasTexture.GetCacheStats();
    end

    return cacheStats or { count = 0, max = 0, evictionsPerMinute = 0, evictions = 0 };
end

local function WritePerformanceReport()
    local path = GetReportPath();
    local file = io.open(path, 'w');

    if (file == nil) then
        lastReportStatus = 'Save failed';
        return false;
    end

    local cacheStats = GetCacheStats();

    file:write(recordingActive == true and 'LibraPlates Timed Performance Recording\n' or 'LibraPlates Performance Snapshot\n');
    file:write('Created: ' .. tostring(os.date('%Y-%m-%d %H:%M:%S') or '') .. '\n');
    if (recordingActive == true) then
        file:write(string.format(
            'Recording: duration=%.1fs elapsed=%.1fs frames=%s\n',
            tonumber(recordingDuration) or 0,
            math.max(0, os.clock() - (tonumber(recordingStartClock) or os.clock())),
            tostring(frameIndex)
        ));
        file:write(string.format(
            'Frame gap: peak=%.1fms at=%.1fs\n',
            tonumber(recordingPeakFrameGapMs) or 0,
            tonumber(recordingPeakFrameGapAt) or 0
        ));
    end
    file:write(string.format(
        'Adaptive: mode=%s fps=%.1f frameMs=%.1f tier=%s\n',
        tostring(adaptivePerformance.GetEffectiveMode()),
        tonumber(adaptivePerformance.GetEstimatedFps()) or 0,
        tonumber(adaptivePerformance.GetAverageFrameMs()) or 0,
        tostring(adaptivePerformance.GetTier())
    ));
    file:write('\nTiming\n');
    file:write('Process\tAvg\tPeak\tLast\n');

    for _, row in ipairs(BuildTimingRows()) do
        file:write(string.format(
            '%s\t%.2f\t%.2f\t%.2f\n',
            tostring(row.label or row.name or ''),
            tonumber(row.avg) or 0,
            tonumber(row.peak) or 0,
            tonumber(row.last) or 0
        ));
    end

    local total = samples.total or {};
    file:write(string.format('Total\t%.2f\t%.2f\t%.2f\n', tonumber(total.avg) or 0, tonumber(total.peak) or 0, tonumber(total.last) or 0));

    file:write('\nCounters\n');
    file:write(string.format(
        'queued=%s\ndrawn=%s\nclickRects=%s\ncanvasRenders=%s\n',
        tostring(GetCounter('queued')),
        tostring(GetCounter('drawn')),
        tostring(GetCounter('clickRects')),
        tostring(GetCounter('canvasRenders'))
    ));
    file:write('canvasSizesAll=' .. tostring(GetCanvasSizeBreakdown('')) .. '\n');
    file:write('canvasSizesPc=' .. tostring(GetCanvasSizeBreakdown('pc')) .. '\n');

    file:write('\nTexture Cache\n');
    file:write(string.format(
        'used=%s/%s\nevictionsPerMinute=%.1f\ntotalEvictions=%s\nlastRender=%s\nlastRenderSize=%s\nlastEvicted=%s\n',
        tostring(cacheStats.count),
        tostring(cacheStats.max),
        tonumber(cacheStats.evictionsPerMinute) or 0,
        tostring(cacheStats.evictions),
        tostring(cacheStats.lastRenderKey or ''),
        tostring(cacheStats.lastRenderSize or ''),
        tostring(cacheStats.lastEvictedKey or '')
    ));

    local nativeHookStatus = 'unknown';
    local okNative, nativeTargetArrow = pcall(require, 'core.native_target_arrow');
    if (okNative == true and nativeTargetArrow ~= nil and nativeTargetArrow.ShouldUseDrawHooks ~= nil) then
        nativeHookStatus = tostring(nativeTargetArrow.ShouldUseDrawHooks() == true);
    end
    file:write('\nNative Hooks\n');
    file:write('shouldUseDrawHooks=' .. tostring(nativeHookStatus) .. '\n');

    file:write('\nEvents\n');
    if (#eventTrail == 0) then
        file:write('none\n');
    else
        for _, event in ipairs(eventTrail) do
            file:write(string.format(
                '%.3fs\t%s\t%s\n',
                tonumber(event.at) or 0,
                tostring(event.name or ''),
                tostring(event.details or '')
            ));
        end
    end

    file:write('\nAll Counters\n');
    local names = {};
    for name, _ in pairs(counters) do
        names[#names + 1] = name;
    end
    table.sort(names);
    for _, name in ipairs(names) do
        file:write(tostring(name) .. '=' .. tostring(counters[name]) .. '\n');
    end

    file:close();
    lastReportStatus = 'Saved report';
    return true;
end

function perfMeter.WritePerformanceReport()
    return WritePerformanceReport();
end

function perfMeter.StartTimedReport(seconds)
    local duration = math.max(5, math.min(300, math.floor((tonumber(seconds) or 60) + 0.5)));

    perfMeter.Reset();
    recordingActive = true;
    recordingStartClock = os.clock();
    recordingEndClock = recordingStartClock + duration;
    recordingDuration = duration;
    recordingPreviousDetail = detailEnabled == true;
    recordingLastFrameClock = recordingStartClock;
    recordingPeakFrameGapMs = 0;
    recordingPeakFrameGapAt = 0;
    detailEnabled = true;
    lastReportStatus = 'Recording ' .. tostring(duration) .. 's';

    return duration;
end

function perfMeter.StopTimedReport(writeReport)
    if (recordingActive ~= true) then
        return false;
    end

    local shouldWrite = writeReport ~= false;
    if (shouldWrite == true) then
        WritePerformanceReport();
    else
        lastReportStatus = 'Recording cancelled';
    end

    recordingActive = false;
    if (recordingPreviousDetail ~= nil) then
        detailEnabled = recordingPreviousDetail == true;
    end
    recordingPreviousDetail = nil;
    recordingLastFrameClock = 0;
    return true;
end

function perfMeter.GetTimedReportStatus()
    if (recordingActive ~= true) then
        return 'inactive';
    end

    return string.format(
        'recording %.1fs remaining of %.1fs',
        math.max(0, (tonumber(recordingEndClock) or os.clock()) - os.clock()),
        tonumber(recordingDuration) or 0
    );
end

local function DrawReportButton()
    if (imgui.Button ~= nil and imgui.Button('Save report##LibraPlatesPerfReport')) then
        WritePerformanceReport();
    end

    if (lastReportStatus ~= '') then
        imgui.SameLine();
        imgui.TextColored({ 0.70, 0.90, 1.0, 1.0 }, tostring(lastReportStatus));
    end
end

local function DrawCountsLine()
    imgui.TextColored(
        { 1.0, 0.84, 0.30, 1.0 },
        string.format(
            'Counts: Qued=%s | Drawn=%s | ClickRects=%s | Canvas =%s',
            tostring(GetCounter('queued')),
            tostring(GetCounter('drawn')),
            tostring(GetCounter('clickRects')),
            tostring(GetCounter('canvasRenders'))
        )
    );
    imgui.TextColored(
        { 1.0, 0.84, 0.30, 1.0 },
        string.format(
            'Rebuilds: S=%s E=%s T=%s PC=%s Pet=%s N/O=%s Targeted=%s',
            tostring(GetLastCounter('canvasSelf')),
            tostring(GetLastCounter('canvasEnemy')),
            tostring(GetLastCounter('canvasTrust')),
            tostring(GetLastCounter('canvasPc')),
            tostring(GetLastCounter('canvasPet')),
            tostring(GetLastCounter('canvasNpcObject')),
            tostring(GetLastCounter('canvasTargeted'))
        )
    );
    imgui.TextColored(
        { 0.70, 0.90, 1.0, 1.0 },
        string.format(
            'Drawn canvases: %s | Large=%s | Pixels=%.1fM',
            tostring(GetLastCounter('drawCanvas.count')),
            tostring(GetLastCounter('drawCanvas.large')),
            (tonumber(GetLastCounter('drawCanvas.pixels')) or 0) / 1000000.0
        )
    );
    imgui.TextColored(
        { 0.70, 0.90, 1.0, 1.0 },
        string.format(
            'Canvas types: T=%s %.1fM | E=%s %.1fM | N/O=%s %.1fM',
            tostring(GetLastCounter('drawCanvas.trust')),
            (tonumber(GetLastCounter('drawCanvas.trustPixels')) or 0) / 1000000.0,
            tostring(GetLastCounter('drawCanvas.enemy')),
            (tonumber(GetLastCounter('drawCanvas.enemyPixels')) or 0) / 1000000.0,
            tostring(GetLastCounter('drawCanvas.npcObject')),
            (tonumber(GetLastCounter('drawCanvas.npcObjectPixels')) or 0) / 1000000.0
        )
    );
end

local function DrawTextureCacheLine()
    local cacheStats = nil;
    local cacheOk, canvasTexture = pcall(require, 'core.canvas_texture');
    if (cacheOk == true and canvasTexture ~= nil and canvasTexture.GetCacheStats ~= nil) then
        cacheStats = canvasTexture.GetCacheStats();
    end

    cacheStats = cacheStats or { count = 0, max = 0, evictionsPerMinute = 0, evictions = 0 };
    imgui.TextColored(
        { 0.92, 0.92, 0.90, 1.0 },
        string.format(
            'Texture Cache: Used=%s/%s | Evictions/min=%.1f | Total=%s',
            tostring(cacheStats.count),
            tostring(cacheStats.max),
            tonumber(cacheStats.evictionsPerMinute) or 0,
            tostring(cacheStats.evictions)
        )
    );
    imgui.TextColored(
        { 0.70, 0.90, 1.0, 1.0 },
        string.format(
            'Cache Detail: Last=%s | Size=%s | Evict=%s',
            tostring(cacheStats.lastRenderKey or ''),
            tostring(cacheStats.lastRenderSize or ''),
            tostring(cacheStats.lastEvictedKey or '')
        )
    );
end

local function DrawTimingTableScrollArea()
    if (imgui.BeginChild ~= nil and imgui.EndChild ~= nil) then
        imgui.BeginChild('##libraplates_perf_timing_scroll', { 0, -110 }, false);
        DrawTimingTable();
        imgui.EndChild();
        return;
    end

    DrawTimingTable();
end

local function PushMonitorStyle()
    if (imgui.PushStyleColor == nil) then
        return 0;
    end

    local pushed = 0;
    local function Push(colorId, color)
        if (colorId ~= nil) then
            imgui.PushStyleColor(colorId, color);
            pushed = pushed + 1;
        end
    end

    local panelColor = { 0.075, 0.085, 0.105, 0.86 };
    local titleColor = { 0.075, 0.085, 0.105, 0.92 };
    local titleActiveColor = { 0.10, 0.15, 0.16, 0.96 };
    local buttonColor = { 0.16, 0.48, 0.50, 0.70 };
    local buttonHoverColor = { 0.22, 0.62, 0.64, 0.85 };
    local scrollbarColor = { 0.16, 0.48, 0.50, 0.65 };
    local scrollbarHoverColor = { 0.22, 0.62, 0.64, 0.82 };

    Push(_G.ImGuiCol_WindowBg, panelColor);
    Push(_G.ImGuiCol_TitleBg, titleColor);
    Push(_G.ImGuiCol_TitleBgActive, titleActiveColor);
    Push(_G.ImGuiCol_TitleBgCollapsed, titleColor);
    Push(_G.ImGuiCol_Button, buttonColor);
    Push(_G.ImGuiCol_ButtonHovered, buttonHoverColor);
    Push(_G.ImGuiCol_ButtonActive, buttonColor);
    Push(_G.ImGuiCol_ScrollbarGrab, scrollbarColor);
    Push(_G.ImGuiCol_ScrollbarGrabHovered, scrollbarHoverColor);
    Push(_G.ImGuiCol_ScrollbarGrabActive, scrollbarHoverColor);

    return pushed;
end

local function PopMonitorStyle(count)
    if (imgui.PopStyleColor ~= nil and tonumber(count) ~= nil and count > 0) then
        imgui.PopStyleColor(count);
    end
end

function perfMeter.BeginFrame()
    local now = os.clock();

    if (recordingActive == true and recordingLastFrameClock > 0) then
        local gapMs = math.max(0, (now - recordingLastFrameClock) * 1000.0);
        if (gapMs > recordingPeakFrameGapMs) then
            recordingPeakFrameGapMs = gapMs;
            recordingPeakFrameGapAt = math.max(0, now - (tonumber(recordingStartClock) or now));
        end
    end

    recordingLastFrameClock = now;

    if (recordingActive == true and os.clock() >= (tonumber(recordingEndClock) or 0)) then
        perfMeter.StopTimedReport(true);
    end

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

function perfMeter.LogEvent(name, details)
    AddEvent(name, details);
end

GetCounter = function(name)
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

function perfMeter.CountDrawnCanvas(category, textureWidth, textureHeight, worldWidth, worldHeight)
    local key = tostring(category or 'unknown'):lower();
    local w = math.max(1, tonumber(textureWidth) or 1024);
    local h = math.max(1, tonumber(textureHeight) or 512);
    local pixels = w * h;
    local worldArea = math.max(0, tonumber(worldWidth) or 0) * math.max(0, tonumber(worldHeight) or 0);

    perfMeter.Count('drawCanvas.count', 1);
    perfMeter.Count('drawCanvas.pixels', pixels);
    perfMeter.Count('drawCanvas.worldArea1000', worldArea * 1000);
    perfMeter.Count('drawCanvas.size.' .. tostring(w) .. 'x' .. tostring(h), 1);
    perfMeter.Count('drawCanvas.size.' .. key .. '.' .. tostring(w) .. 'x' .. tostring(h), 1);

    if (pixels >= (1024 * 512)) then
        perfMeter.Count('drawCanvas.large', 1);
    end

    if (key == 'trust') then
        perfMeter.Count('drawCanvas.trust', 1);
        perfMeter.Count('drawCanvas.trustPixels', pixels);
    elseif (key == 'enemy') then
        perfMeter.Count('drawCanvas.enemy', 1);
        perfMeter.Count('drawCanvas.enemyPixels', pixels);
    elseif (key == 'npc' or key == 'object') then
        perfMeter.Count('drawCanvas.npcObject', 1);
        perfMeter.Count('drawCanvas.npcObjectPixels', pixels);
    elseif (key == 'pc') then
        perfMeter.Count('drawCanvas.pc', 1);
        perfMeter.Count('drawCanvas.pcPixels', pixels);
    elseif (key == 'self') then
        perfMeter.Count('drawCanvas.self', 1);
        perfMeter.Count('drawCanvas.selfPixels', pixels);
    elseif (key == 'pet') then
        perfMeter.Count('drawCanvas.pet', 1);
        perfMeter.Count('drawCanvas.petPixels', pixels);
    else
        perfMeter.Count('drawCanvas.other', 1);
        perfMeter.Count('drawCanvas.otherPixels', pixels);
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

function perfMeter.SetCompactOverlayEnabled(value)
    compactOverlay = value ~= false;
end

function perfMeter.GetCompactOverlayEnabled()
    return compactOverlay ~= false;
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
    local npcTacticalScan = perfMeter.GetMetric('npc.tactical.scan');
    local npcResolve = perfMeter.GetMetric('npc.resolve');
    local npcFastCache = perfMeter.GetMetric('npc.fastCache');
    local npcSettings = perfMeter.GetMetric('npc.settings');
    local npcSignature = perfMeter.GetMetric('npc.signature');
    local npcCanvas = perfMeter.GetMetric('npc.canvas');
    local npcQueue = perfMeter.GetMetric('npc.queue');
    local npcScanCalls = perfMeter.GetCounterValue('npc.scan.calls');
    local npcTacticalScanCalls = perfMeter.GetCounterValue('npc.tactical.scan.calls');
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
        'perf frame=%s overlay=%s detail=%s total_avg=%.3f total_last=%.3f total_peak=%.3f settings_avg=%.3f targeting_avg=%.3f native_avg=%.3f plates_avg=%.3f self_avg=%.3f self_cache_hits=%s self_cache_misses=%s pc_avg=%.3f pc_scan_avg=%.3f pc_scan_calls=%s pc_scan_cache_hits=%s pc_scan_cache_misses=%s pc_settings_avg=%.3f pc_settings_calls=%s pc_icons_avg=%.3f pc_icons_calls=%s pc_build_avg=%.3f pc_build_calls=%s pc_status_avg=%.3f pc_status_calls=%s pc_canvas_avg=%.3f pc_canvas_calls=%s pc_queue_avg=%.3f pc_queue_calls=%s pc_cache_hits=%s pc_cache_misses=%s npc_avg=%.3f npc_scan_avg=%.3f npc_scan_calls=%s npc_tactical_scan_avg=%.3f npc_tactical_scan_calls=%s npc_resolve_avg=%.3f npc_resolve_calls=%s npc_fast_avg=%.3f npc_fast_calls=%s npc_settings_avg=%.3f npc_settings_calls=%s npc_signature_avg=%.3f npc_signature_calls=%s npc_canvas_avg=%.3f npc_canvas_calls=%s npc_queue_avg=%.3f npc_queue_calls=%s trust_avg=%.3f trust_scan_avg=%.3f trust_scan_calls=%s trust_settings_avg=%.3f trust_settings_calls=%s trust_build_avg=%.3f trust_build_calls=%s trust_canvas_avg=%.3f trust_canvas_calls=%s trust_queue_avg=%.3f trust_queue_calls=%s trust_cache_hits=%s trust_cache_misses=%s pet_avg=%.3f enemy_avg=%.3f enemy_scan_avg=%.3f enemy_scan_calls=%s enemy_settings_avg=%.3f enemy_settings_calls=%s enemy_build_avg=%.3f enemy_build_calls=%s enemy_status_avg=%.3f enemy_status_calls=%s enemy_canvas_avg=%.3f enemy_canvas_calls=%s enemy_queue_avg=%.3f enemy_queue_calls=%s enemy_cache_hits=%s enemy_cache_misses=%s world_draw_avg=%.3f target_overlay_avg=%.3f peer_avg=%.3f quick_menu_avg=%.3f native_hook_avg=%.3f native_hook_calls=%s target_build_avg=%.3f target_build_calls=%s queued=%s drawn=%s clickRects=%s canvas=%s targetedCanvas=%s',
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
        npcTacticalScan.avg,
        tostring(npcTacticalScanCalls),
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
    eventTrail = {};
    frameIndex = 0;
end

function perfMeter.GetSummaryLines()
    local lines = {};

    lines[#lines + 1] = 'LibraPlates perf frame=' .. tostring(frameIndex) .. ' overlay=' .. tostring(overlayEnabled == true);
    lines[#lines + 1] = string.format(
        'Adaptive mode=%s fps=%.1f frame=%.1fms',
        tostring(adaptivePerformance.GetEffectiveMode()),
        tonumber(adaptivePerformance.GetEstimatedFps()) or 0,
        tonumber(adaptivePerformance.GetAverageFrameMs()) or 0
    );

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
    lines[#lines + 1] = string.format(
        'Canvas rebuild detail self=%s enemy=%s trust=%s pc=%s pet=%s npcObject=%s targeted=%s',
        tostring(GetCounter('canvasSelf')),
        tostring(GetCounter('canvasEnemy')),
        tostring(GetCounter('canvasTrust')),
        tostring(GetCounter('canvasPc')),
        tostring(GetCounter('canvasPet')),
        tostring(GetCounter('canvasNpcObject')),
        tostring(GetCounter('canvasTargeted'))
    );
    lines[#lines + 1] = string.format(
        'Entity scan detail enemyScanned=%s enemyQueued=%s enemyTracked=%s enemyBackground=%s enemyLimit=%s engaged=%s combatLike=%s targetQueued=%s npcScanned=%s npcTacticalScanned=%s npcCombatSkip=%s',
        tostring(GetCounter('enemyScanned')),
        tostring(GetCounter('enemyQueued')),
        tostring(GetCounter('enemyTracked')),
        tostring(GetCounter('enemyBackgroundQueued')),
        tostring(GetCounter('enemyBackgroundLimit')),
        tostring(GetCounter('enemyPlayerEngaged')),
        tostring(GetCounter('enemyCombatLike')),
        tostring(GetCounter('enemyTargetQueued')),
        tostring(GetCounter('npcScanned')),
        tostring(GetCounter('npcTacticalScanned')),
        tostring(GetCounter('npcCombatSkip'))
    );
    lines[#lines + 1] = string.format(
        'PC scan detail pcScanned=%s world=%s party=%s target=%s enmity=%s',
        tostring(GetCounter('pcScanned')),
        tostring(GetCounter('pcGateWorld')),
        tostring(GetCounter('pcGateParty')),
        tostring(GetCounter('pcGateTarget')),
        tostring(GetCounter('pcGateEnmity'))
    );
    lines[#lines + 1] = string.format(
        'Trust scan detail party=%s nearby=%s hiddenByGame=%s queued=%s',
        tostring(GetCounter('trustPartyScanned')),
        tostring(GetCounter('trustNearbyScanned')),
        tostring(GetCounter('trustHiddenByGame')),
        tostring(GetCounter('trustQueued'))
    );
    lines[#lines + 1] = string.format(
        'NPC/Object gate detail world=%s tactical=%s target=%s',
        tostring(GetCounter('npcGateWorld')),
        tostring(GetCounter('npcGateTactical')),
        tostring(GetCounter('npcGateTarget'))
    );
    lines[#lines + 1] = string.format(
        'Drawn canvases count=%s large=%s pixels=%.1fM worldArea=%.2f',
        tostring(GetLastCounter('drawCanvas.count')),
        tostring(GetLastCounter('drawCanvas.large')),
        (tonumber(GetLastCounter('drawCanvas.pixels')) or 0) / 1000000.0,
        (tonumber(GetLastCounter('drawCanvas.worldArea1000')) or 0) / 1000.0
    );
    lines[#lines + 1] = string.format(
        'Drawn canvas detail self=%s/%.1fM enemy=%s/%.1fM trust=%s/%.1fM pc=%s/%.1fM npcObject=%s/%.1fM pet=%s/%.1fM other=%s/%.1fM',
        tostring(GetLastCounter('drawCanvas.self')),
        (tonumber(GetLastCounter('drawCanvas.selfPixels')) or 0) / 1000000.0,
        tostring(GetLastCounter('drawCanvas.enemy')),
        (tonumber(GetLastCounter('drawCanvas.enemyPixels')) or 0) / 1000000.0,
        tostring(GetLastCounter('drawCanvas.trust')),
        (tonumber(GetLastCounter('drawCanvas.trustPixels')) or 0) / 1000000.0,
        tostring(GetLastCounter('drawCanvas.pc')),
        (tonumber(GetLastCounter('drawCanvas.pcPixels')) or 0) / 1000000.0,
        tostring(GetLastCounter('drawCanvas.npcObject')),
        (tonumber(GetLastCounter('drawCanvas.npcObjectPixels')) or 0) / 1000000.0,
        tostring(GetLastCounter('drawCanvas.pet')),
        (tonumber(GetLastCounter('drawCanvas.petPixels')) or 0) / 1000000.0,
        tostring(GetLastCounter('drawCanvas.other')),
        (tonumber(GetLastCounter('drawCanvas.otherPixels')) or 0) / 1000000.0
    );
    lines[#lines + 1] = string.format(
        'Canvas sizes all: %s',
        GetCanvasSizeBreakdown('')
    );
    lines[#lines + 1] = string.format(
        'Canvas sizes pc: %s',
        GetCanvasSizeBreakdown('pc')
    );

    if (detailEnabled == true) then
        local cacheStats = nil;
        local ok, canvasTexture = pcall(require, 'core.canvas_texture');
        if (ok == true and canvasTexture ~= nil and canvasTexture.GetCacheStats ~= nil) then
            cacheStats = canvasTexture.GetCacheStats();
        end
        cacheStats = cacheStats or { count = 0, max = 0, evictionsPerMinute = 0, evictions = 0 };
        lines[#lines + 1] = string.format(
            'Texture Cache: Used=%s/%s | Evictions/min=%.1f | Total=%s',
            tostring(cacheStats.count),
            tostring(cacheStats.max),
            tonumber(cacheStats.evictionsPerMinute) or 0,
            tostring(cacheStats.evictions)
        );
        lines[#lines + 1] = string.format(
            'Cache Detail: Last=%s | Size=%s | Evict=%s',
            tostring(cacheStats.lastRenderKey or ''),
            tostring(cacheStats.lastRenderSize or ''),
            tostring(cacheStats.lastEvictedKey or '')
        );
        lines[#lines + 1] = string.format(
            'Detail native=%s target=%s npcScan=%s npcTacticalScan=%s npcResolve=%s npcFast=%s',
            tostring(GetCounter('native.hook.calls')),
            tostring(GetCounter('target.marker.build.calls')),
            tostring(GetCounter('npc.scan.calls')),
            tostring(GetCounter('npc.tactical.scan.calls')),
            tostring(GetCounter('npc.resolve.calls')),
            tostring(GetCounter('npc.fastCache.calls'))
        );
        lines[#lines + 1] = string.format(
            'Detail npcSettings=%s npcSignature=%s npcCanvas=%s npcQueue=%s',
            tostring(GetCounter('npc.settings.calls')),
            tostring(GetCounter('npc.signature.calls')),
            tostring(GetCounter('npc.canvas.calls')),
            tostring(GetCounter('npc.queue.calls'))
        );
        lines[#lines + 1] = string.format(
            'Detail canvas self=%s enemy=%s pc=%s trust=%s',
            tostring(GetCounter('canvasSelf')),
            tostring(GetCounter('canvasEnemy')),
            tostring(GetCounter('canvasPc')),
            tostring(GetCounter('canvasTrust'))
        );
        lines[#lines + 1] = string.format(
            'Detail canvas pet=%s npc=%s targeted=%s',
            tostring(GetCounter('canvasPet')),
            tostring(GetCounter('canvasNpcObject')),
            tostring(GetCounter('canvasTargeted'))
        );
        lines[#lines + 1] = string.format(
            'Detail enemy cache hit=%s miss=%s skipState=%s skipCast=%s skipBuffs=%s skipDebuffs=%s skipConfig=%s skipHover=%s',
            tostring(GetCounter('enemy.cache.hit')),
            tostring(GetCounter('enemy.cache.miss')),
            tostring(GetCounter('enemy.cache.skip.state_Target') + GetCounter('enemy.cache.skip.state_Subtarget') + GetCounter('enemy.cache.skip.state_Tactical')),
            tostring(GetCounter('enemy.cache.skip.cast')),
            tostring(GetCounter('enemy.cache.skip.buffs')),
            tostring(GetCounter('enemy.cache.skip.debuffs')),
            tostring(GetCounter('enemy.cache.skip.config')),
            tostring(GetCounter('enemy.cache.skip.hover'))
        );
        lines[#lines + 1] = string.format(
            'Detail self cache hit=%s smooth=%s miss=%s skip=%s',
            tostring(GetCounter('self.cache.hit')),
            tostring(GetCounter('self.cache.smooth')),
            tostring(GetCounter('self.cache.miss')),
            tostring(GetCounter('self.cache.skip'))
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

    if (imgui.Begin == nil) then
        return;
    end

    local lines = nil;

    if (compactOverlay ~= false) then
        local total = perfMeter.GetMetric('total');
        local plates = perfMeter.GetMetric('plates.total');
        local worldDraw = perfMeter.GetMetric('world.draw');
        local mode = adaptivePerformance.GetEffectiveMode();
        local fps = adaptivePerformance.GetEstimatedFps();
        local frameMs = adaptivePerformance.GetAverageFrameMs();

        lines = {
            string.format('LibraPlates %.2fms  peak %.2fms', total.avg, total.peak),
            string.format('Plates %.2fms  World %.2fms', plates.avg, worldDraw.avg),
            string.format('Counts: Qued=%s | Drawn=%s | Canvas =%s',
                tostring(GetCounter('queued')),
                tostring(GetCounter('drawn')),
                tostring(GetCounter('canvasRenders'))
            ),
            string.format('Mode %s  FPS %.1f  Frame %.1fms', tostring(mode), tonumber(fps) or 0, tonumber(frameMs) or 0),
        };
    else
        lines = perfMeter.GetSummaryLines();
    end

    local windowOpen = { true };
    local flags = (_G.ImGuiWindowFlags_NoCollapse or 0) +
        (_G.ImGuiWindowFlags_NoSavedSettings or 0) +
        (_G.ImGuiWindowFlags_NoResize or 0) +
        (_G.ImGuiWindowFlags_NoScrollbar or 0);

    local width = compactOverlay ~= false and 410 or 560;
    local height = compactOverlay ~= false and math.max(138, (#lines * 18) + 46) or 430;

    if (imgui.SetNextWindowPos ~= nil) then
        imgui.SetNextWindowPos({ 18, 148 }, _G.ImGuiCond_FirstUseEver or 4);
    end

    if (imgui.SetNextWindowSize ~= nil) then
        imgui.SetNextWindowSize({ width, height }, _G.ImGuiCond_Always or 2);
    end

    local styleCount = PushMonitorStyle();
    local began = false;
    local ok = pcall(function()
        began = imgui.Begin('LibraPlates Performance Monitor', windowOpen, flags);

        if (windowOpen[1] ~= true) then
            overlayEnabled = false;
        end

        if (began ~= true) then
            return;
        end

        if (compactOverlay == false and imgui.BeginTable ~= nil) then
            DrawAdaptiveStatusLine();
            DrawReportButton();
            imgui.Separator();
            DrawTimingSortHeader();
            DrawTimingTableScrollArea();
            imgui.Separator();
            DrawTotalSummaryLine();
            DrawCountsLine();
            DrawTextureCacheLine();

            return;
        end

        DrawReportButton();

        for index, line in ipairs(lines) do
            local color = { 0.92, 0.92, 0.90, 1.0 };

            if (index == 1) then
                color = { 0.42, 0.91, 0.94, 1.0 };
            elseif (compactOverlay == false and string.find(tostring(line or ''), 'Plates', 1, true) ~= nil and string.find(tostring(line or ''), 'avg', 1, true) ~= nil) then
                color = GetPlateCostColor(perfMeter.GetMetric('plates.total').avg);
            elseif (compactOverlay ~= false and index == 2) then
                color = GetPlateCostColor(perfMeter.GetMetric('plates.total').avg);
            elseif (string.find(tostring(line or ''), 'Counts', 1, true) ~= nil) then
                color = { 1.0, 0.84, 0.30, 1.0 };
            elseif (string.find(tostring(line or ''), 'FPS', 1, true) ~= nil or string.find(tostring(line or ''), 'Adaptive mode=', 1, true) ~= nil) then
                color = GetTierColor(adaptivePerformance.GetTier());
            end

            imgui.TextColored(color, line);
        end
    end);

    if (began == true) then
        imgui.End();
    end
    PopMonitorStyle(styleCount);

    if (ok ~= true) then
        overlayEnabled = false;
    end
end

return perfMeter;
