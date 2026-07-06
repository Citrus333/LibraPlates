local log = require('core.log');
local targeting = require('core.targeting');
local perfMeter = require('core.perf_meter');

local nativeTargetArrow = {};
local uiPrimitiveEnabled = false;
local hideAllPrimitiveEnabled = false;
local targetPrimitiveHideAllowed = true;
local targetPrimitivePointer = 0;
local party0PrimitivePointer = 0;
local party1PrimitivePointer = 0;
local party2PrimitivePointer = 0;
local pointersResolved = false;
local traceEnabled = false;
local traceFrame = 0;
local tracePreviousHadTarget = false;
local tracePreviousSnapshot = nil;
local traceAfterTransitionFrames = 0;
local traceCandidateFrames = 0;
local traceCurrentTotal = 0;
local traceCurrentCounts = {};
local traceCapturePaused = false;
local drawBlockEnabled = false;
local drawBlockFrames = 0;
local drawBlockPreviousHadTarget = false;
local drawBlockHits = 0;
local drawBlockCurrentHits = 0;
local drawBlockCurrentRects = {};
local drawBlockPassedHits = 0;
local drawBlockPassedRects = {};
local partyTraceEnabled = false;
local partyTraceFrames = 0;
local partyTraceFrame = 0;
local partyTraceHits = 0;
local partyTraceRects = {};
local partyBlockEnabled = false;
local hardHideManualEnabled = false;
local hardHideBurstFrames = 0;
local hardHideEveryDrawWrites = 0;
local hardHideFrameWritten = false;
local primitiveVisibilityAddresses = {};
local targetWindowProbePrevious = nil;
local fishingBarCaptureEnabled = false;
local fishingBarFrame = 0;
local fishingBarRects = {};
local fishingBarFrameBackground = nil;
local fishingBarFrameFill = nil;
local fishingBarLastState = nil;
local fishingBarProbeUntil = 0;
local fishingBarProbeNextLog = 0;
local fishingBarProbePrimitiveHits = 0;
local fishingBarProbeIndexedHits = 0;
local fishingBarProbeLastText = 'not run';

local function SafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function ToNumber(value)
    local number = tonumber(value);

    if (number ~= nil) then
        return number;
    end

    local text = tostring(value or '');
    local hex = text:match('0x(%x+)');

    if (hex ~= nil) then
        return tonumber(hex, 16);
    end

    return nil;
end

local function RoundNumber(value)
    value = tonumber(value);

    if (value == nil) then
        return 0;
    end

    if (value >= 0) then
        return math.floor(value + 0.5);
    end

    return math.ceil(value - 0.5);
end

local function ReadFloat(pointer)
    return SafeCall(nil, function()
        return ashita.memory.read_float(pointer);
    end);
end

local function ReadUInt8(pointer)
    return SafeCall(nil, function()
        return ashita.memory.read_uint8(pointer);
    end);
end

local function ReadUInt16(pointer)
    return SafeCall(nil, function()
        return ashita.memory.read_uint16(pointer);
    end);
end

local function ReadInt16(pointer)
    local value = ReadUInt16(pointer);

    if (value == nil) then
        return nil;
    end

    if (value >= 0x8000) then
        return value - 0x10000;
    end

    return value;
end

local function ReadUInt32(pointer)
    return SafeCall(nil, function()
        return ashita.memory.read_uint32(pointer);
    end);
end

local function WriteUInt8(pointer, value)
    return SafeCall(false, function()
        ashita.memory.write_uint8(pointer, value);
        return true;
    end);
end

local function GetPrimitiveVertexCount(primitiveType, primitiveCount)
    primitiveType = tonumber(primitiveType) or 0;
    primitiveCount = tonumber(primitiveCount) or 0;

    if (primitiveType == 4) then
        return primitiveCount * 3;
    end

    if (primitiveType == 5) then
        return primitiveCount + 2;
    end

    return primitiveCount;
end

local function GetVertexRect(pointer, stride, primitiveType, primitiveCount)
    pointer = ToNumber(pointer);
    stride = tonumber(stride) or 0;

    if (pointer == nil or pointer == 0 or stride < 8 or stride > 128) then
        return nil;
    end

    local vertexCount = math.min(GetPrimitiveVertexCount(primitiveType, primitiveCount), 6);

    if (vertexCount <= 0) then
        return nil;
    end

    local minX = nil;
    local minY = nil;
    local maxX = nil;
    local maxY = nil;

    for index = 0, vertexCount - 1 do
        local base = pointer + (index * stride);
        local x = ReadFloat(base + 0x00);
        local y = ReadFloat(base + 0x04);

        if (x == nil or y == nil or x ~= x or y ~= y) then
            return nil;
        end

        if (x < -4096 or x > 8192 or y < -4096 or y > 8192) then
            return nil;
        end

        minX = minX == nil and x or math.min(minX, x);
        minY = minY == nil and y or math.min(minY, y);
        maxX = maxX == nil and x or math.max(maxX, x);
        maxY = maxY == nil and y or math.max(maxY, y);
    end

    if (minX == nil or minY == nil or maxX == nil or maxY == nil) then
        return nil;
    end

    return string.format(
        ' rect=%d,%d,%dx%d',
        RoundNumber(minX),
        RoundNumber(minY),
        RoundNumber(maxX - minX),
        RoundNumber(maxY - minY)
    );
end

local function ParseRect(rect)
    local x, y, width, height = tostring(rect or ''):match('rect=(%-?%d+),(%-?%d+),(%-?%d+)x(%-?%d+)');

    return tonumber(x), tonumber(y), tonumber(width), tonumber(height);
end

local function IsFishingBarCandidateRect(rect)
    local x, y, width, height = ParseRect(rect);

    if (x == nil or y == nil or width == nil or height == nil) then
        return false;
    end

    -- The native fish stamina bar is fixed in the upper UI area. Keeping capture
    -- here prevents tiny chat glyph quads from being mistaken for the final sliver.
    if (y < 20 or y > 320) then
        return false;
    end

    if (width < 1 or width > 240 or height < 2 or height > 18) then
        return false;
    end

    if (x < -20 or y < -20 or x > 4096 or y > 4096) then
        return false;
    end

    return width >= 1 and (width > (height * 5) or width <= 48);
end

local function IsFishingBarProbeActive()
    return os.clock() <= (tonumber(fishingBarProbeUntil) or 0);
end

local function IsKnownFishingBarRect(rect)
    if (fishingBarLastState == nil) then
        return false;
    end

    local x, y, width, height = ParseRect(rect);
    local knownX = tonumber(fishingBarLastState.x);
    local knownY = tonumber(fishingBarLastState.y);
    local knownWidth = tonumber(fishingBarLastState.width);
    local knownHeight = tonumber(fishingBarLastState.height);

    if (
        x == nil or y == nil or width == nil or height == nil or
        knownX == nil or knownY == nil or knownWidth == nil or knownHeight == nil
    ) then
        return false;
    end

    local age = os.clock() - (tonumber(fishingBarLastState.clock) or 0);
    if (age > 0.50) then
        return false;
    end

    -- The native "Fish" label is drawn just above the bar as small glyph quads,
    -- and the final low-stamina sliver can be only a few pixels wide. Use a
    -- learned local footprint around the real bar instead of a broad screen rule.
    local left = knownX - 24;
    local right = knownX + knownWidth + 24;
    local top = knownY - 28;
    local bottom = knownY + knownHeight + 12;

    return
        (x + width) >= left and
        x <= right and
        (y + height) >= top and
        y <= bottom;
end

local function AddFishingBarCandidate(rect, source)
    local x, y, width, height = ParseRect(rect);

    if (x == nil or y == nil or width == nil or height == nil) then
        return;
    end

    local candidate = {
        x = x,
        y = y,
        width = width,
        height = height,
        source = source or 'unknown',
    };

    if (source == 'indexed') then
        fishingBarProbeIndexedHits = fishingBarProbeIndexedHits + 1;
    else
        fishingBarProbePrimitiveHits = fishingBarProbePrimitiveHits + 1;
    end

    if (width >= 80) then
        fishingBarRects[#fishingBarRects + 1] = candidate;
        return;
    end

    local smallCount = 0;
    for _, existing in ipairs(fishingBarRects) do
        if ((tonumber(existing.width) or 0) < 80) then
            smallCount = smallCount + 1;
        end
    end

    if (smallCount < 32) then
        fishingBarRects[#fishingBarRects + 1] = candidate;
    end
end

local function UpdateFishingBarStateFromFrame()
    if (#fishingBarRects < 2) then
        fishingBarProbeLastText =
            'fishbar capture enabled=' .. tostring(fishingBarCaptureEnabled == true) ..
            ' frame=' .. tostring(fishingBarFrame) ..
            ' rects=' .. tostring(#fishingBarRects) ..
            ' primitive=' .. tostring(fishingBarProbePrimitiveHits) ..
            ' indexed=' .. tostring(fishingBarProbeIndexedHits) ..
            ' state=none';
        return;
    end

    local best = nil;
    local bestBackground = nil;
    local bestOrphanFill = nil;
    local backgroundCount = 0;
    local fillCount = 0;

    local knownX = fishingBarLastState ~= nil and tonumber(fishingBarLastState.x) or nil;
    local knownY = fishingBarLastState ~= nil and tonumber(fishingBarLastState.y) or nil;
    local knownWidth = fishingBarLastState ~= nil and tonumber(fishingBarLastState.width) or nil;
    local knownHeight = fishingBarLastState ~= nil and tonumber(fishingBarLastState.height) or nil;

    if (knownX ~= nil and knownY ~= nil and knownWidth ~= nil and knownHeight ~= nil) then
        for _, candidate in ipairs(fishingBarRects) do
            if (
                candidate.width < 80 and
                candidate.width >= 1 and
                candidate.height >= 2 and
                candidate.height <= (knownHeight + 2) and
                math.abs(candidate.x - knownX) <= 4 and
                math.abs(candidate.y - (knownY + 1)) <= 5
            ) then
                if (bestOrphanFill == nil or candidate.width > bestOrphanFill.width) then
                    bestOrphanFill = candidate;
                end
            end
        end
    end

    for _, background in ipairs(fishingBarRects) do
        if (background.width >= 80) then
            backgroundCount = backgroundCount + 1;
            if (bestBackground == nil or background.width > bestBackground.width) then
                bestBackground = background;
            end
            for _, fill in ipairs(fishingBarRects) do
                if (
                    fill ~= background and
                    fill.width < background.width and
                    fill.width >= 1 and
                    math.abs(fill.x - background.x) <= 3 and
                    math.abs(fill.y - background.y) <= 4 and
                    math.abs(fill.height - background.height) <= 6
                ) then
                    fillCount = fillCount + 1;
                    local progress = fill.width / math.max(1, background.width);
                    if (progress >= 0 and progress <= 1.05) then
                        local score = background.width - math.abs(fill.height - background.height);
                        if (best == nil or score > best.score) then
                            best = {
                                progress = math.max(0, math.min(1, progress)),
                                background = background,
                                fill = fill,
                                score = score,
                            };
                        end
                    end
                end
            end
        end
    end

    if (best ~= nil) then
        local background = best.background;
        local fill = best.fill;
        fishingBarLastState = {
            progress = best.progress * 100,
            text = tostring(math.floor((best.progress * 100) + 0.5)) .. '%',
            labelText = 'Fish stamina',
            x = background.x,
            y = background.y,
            width = background.width,
            height = background.height,
            fillWidth = fill.width,
            clock = os.clock(),
            source = 'native-geometry',
        };
        fishingBarProbeLastText =
            'fishbar capture enabled=' .. tostring(fishingBarCaptureEnabled == true) ..
            ' frame=' .. tostring(fishingBarFrame) ..
            ' rects=' .. tostring(#fishingBarRects) ..
            ' bg=' .. tostring(backgroundCount) ..
            ' fill=' .. tostring(fillCount) ..
            ' primitive=' .. tostring(fishingBarProbePrimitiveHits) ..
            ' indexed=' .. tostring(fishingBarProbeIndexedHits) ..
            ' progress=' .. tostring(math.floor((best.progress * 100) + 0.5)) ..
            ' bgRect=' .. tostring(background.x) .. ',' .. tostring(background.y) .. ',' .. tostring(background.width) .. 'x' .. tostring(background.height) ..
            ' fillRect=' .. tostring(fill.x) .. ',' .. tostring(fill.y) .. ',' .. tostring(fill.width) .. 'x' .. tostring(fill.height);
    elseif (bestOrphanFill ~= nil and knownWidth ~= nil and knownWidth > 0) then
        local fill = bestOrphanFill;
        fishingBarLastState = {
            progress = 0,
            text = '0%',
            labelText = 'Fish stamina',
            x = knownX,
            y = knownY,
            width = knownWidth,
            height = knownHeight,
            fillWidth = 0,
            clock = os.clock(),
            source = 'native-geometry-empty',
        };
        fishingBarProbeLastText =
            'fishbar capture enabled=' .. tostring(fishingBarCaptureEnabled == true) ..
            ' frame=' .. tostring(fishingBarFrame) ..
            ' rects=' .. tostring(#fishingBarRects) ..
            ' bg=' .. tostring(backgroundCount) ..
            ' fill=' .. tostring(fillCount) ..
            ' primitive=' .. tostring(fishingBarProbePrimitiveHits) ..
            ' indexed=' .. tostring(fishingBarProbeIndexedHits) ..
            ' progress=0' ..
            ' bgRect=last' ..
            ' orphanHidden=' .. tostring(fill.x) .. ',' .. tostring(fill.y) .. ',' .. tostring(fill.width) .. 'x' .. tostring(fill.height);
    elseif (bestBackground ~= nil) then
        local background = bestBackground;
        fishingBarLastState = {
            progress = 0,
            text = '0%',
            labelText = 'Fish stamina',
            x = background.x,
            y = background.y,
            width = background.width,
            height = background.height,
            fillWidth = 0,
            clock = os.clock(),
            source = 'native-geometry-empty',
        };
        fishingBarProbeLastText =
            'fishbar capture enabled=' .. tostring(fishingBarCaptureEnabled == true) ..
            ' frame=' .. tostring(fishingBarFrame) ..
            ' rects=' .. tostring(#fishingBarRects) ..
            ' bg=' .. tostring(backgroundCount) ..
            ' fill=' .. tostring(fillCount) ..
            ' primitive=' .. tostring(fishingBarProbePrimitiveHits) ..
            ' indexed=' .. tostring(fishingBarProbeIndexedHits) ..
            ' progress=0' ..
            ' bgRect=' .. tostring(background.x) .. ',' .. tostring(background.y) .. ',' .. tostring(background.width) .. 'x' .. tostring(background.height) ..
            ' fillRect=none';
    else
        fishingBarProbeLastText =
            'fishbar capture enabled=' .. tostring(fishingBarCaptureEnabled == true) ..
            ' frame=' .. tostring(fishingBarFrame) ..
            ' rects=' .. tostring(#fishingBarRects) ..
            ' bg=' .. tostring(backgroundCount) ..
            ' fill=' .. tostring(fillCount) ..
            ' primitive=' .. tostring(fishingBarProbePrimitiveHits) ..
            ' indexed=' .. tostring(fishingBarProbeIndexedHits) ..
            ' state=no-pair';
    end
end

local function BeginFishingBarFrame()
    fishingBarFrame = fishingBarFrame + 1;
    fishingBarRects = {};
    fishingBarFrameBackground = nil;
    fishingBarFrameFill = nil;
    fishingBarProbePrimitiveHits = 0;
    fishingBarProbeIndexedHits = 0;
end

local function HasFreshFishingBarState(maxAge)
    if (fishingBarLastState == nil) then
        return false;
    end

    maxAge = tonumber(maxAge) or 0.20;
    return (os.clock() - (tonumber(fishingBarLastState.clock) or 0)) <= maxAge;
end

local function IsBlockableUiRect(rect)
    local _, _, width, height = ParseRect(rect);

    if (width == nil or height == nil) then
        return false;
    end

    if (width <= 0 or height <= 0) then
        return false;
    end

    -- Let the full-screen native overlay draw; blocking it darkens the world.
    if (width >= 1000 and height >= 500) then
        return false;
    end

    return width <= 256 and height <= 256;
end

local function IsPartyWindowRect(rect)
    local x, _, width, height = ParseRect(rect);

    if (x == nil or width == nil or height == nil) then
        return false;
    end

    if (x >= -300 and x <= 900 and width >= 120 and width <= 380 and height >= 100 and height <= 420) then
        return true;
    end

    return x >= 900 and x <= 1100 and width >= 450 and width <= 900 and height >= 100 and height <= 420;
end

local function IsCandidateUiRect(rect)
    local width, height = tostring(rect or ''):match('rect=%-?%d+,%-?%d+,(%-?%d+)x(%-?%d+)');

    width = tonumber(width);
    height = tonumber(height);

    if (width == nil or height == nil or width <= 0 or height <= 0) then
        return false;
    end

    return width < 1000 and height < 500;
end

local function AddTraceKey(key)
    if (traceEnabled ~= true or traceCapturePaused == true) then
        return;
    end

    traceCurrentTotal = traceCurrentTotal + 1;
    traceCurrentCounts[key] = (traceCurrentCounts[key] or 0) + 1;
end

local function CopyTraceSnapshot()
    local counts = {};

    for key, value in pairs(traceCurrentCounts) do
        counts[key] = value;
    end

    return {
        frame = traceFrame,
        total = traceCurrentTotal,
        counts = counts,
    };
end

local function FormatTraceDiff(previous, current, limit)
    local rows = {};
    local previousCounts = previous ~= nil and previous.counts or {};

    for key, value in pairs(current.counts) do
        local delta = value - (previousCounts[key] or 0);

        if (delta > 0) then
            rows[#rows + 1] = {
                key = key,
                delta = delta,
            };
        end
    end

    table.sort(rows, function(left, right)
        if (left.delta ~= right.delta) then
            return left.delta > right.delta;
        end

        return left.key < right.key;
    end);

    local parts = {};

    for index = 1, math.min(#rows, limit or 18) do
        parts[#parts + 1] = '+' .. tostring(rows[index].delta) .. ' ' .. rows[index].key;
    end

    if (#parts == 0) then
        return '(no added draw shapes)';
    end

    return table.concat(parts, ' | ');
end

local function ResetTraceFrame()
    traceCurrentTotal = 0;
    traceCurrentCounts = {};
end

local function GetTraceFilePath()
    local ok, root = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and root ~= nil) then
        return tostring(root) .. 'TEMP WORK FOLDER\\native_arrow_trace.txt';
    end

    return 'TEMP WORK FOLDER\\native_arrow_trace.txt';
end

local function GetPartyTraceFilePath()
    local ok, root = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and root ~= nil) then
        return tostring(root) .. 'TEMP WORK FOLDER\\native_party_trace.txt';
    end

    return 'TEMP WORK FOLDER\\native_party_trace.txt';
end

local function GetTargetWindowProbeFilePath()
    local ok, root = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and root ~= nil) then
        return tostring(root) .. 'TEMP WORK FOLDER\\native_fishing_bar_probe.txt';
    end

    return 'TEMP WORK FOLDER\\native_fishing_bar_probe.txt';
end

local function WriteTraceLine(message)
    local file = io.open(GetTraceFilePath(), 'a');

    if (file == nil) then
        return;
    end

    file:write(tostring(message));
    file:write('\n');
    file:close();
end

local function WritePartyTraceLine(message)
    local file = io.open(GetPartyTraceFilePath(), 'a');

    if (file == nil) then
        return;
    end

    file:write(tostring(message));
    file:write('\n');
    file:close();
end

local function ResetTraceFile()
    local file = io.open(GetTraceFilePath(), 'w');

    if (file == nil) then
        return;
    end

    file:write('LibraPlates native arrow trace\n');
    file:close();
end

local function ResetPartyTraceFile()
    local file = io.open(GetPartyTraceFilePath(), 'w');

    if (file == nil) then
        return;
    end

    file:write('LibraPlates native party trace\n');
    file:close();
end

local function ResetDrawBlockFrame()
    drawBlockCurrentHits = 0;
    drawBlockCurrentRects = {};
    drawBlockPassedHits = 0;
    drawBlockPassedRects = {};
end

local function AddDrawBlockRect(rect)
    local key = tostring(rect or 'rect=?');

    drawBlockCurrentHits = drawBlockCurrentHits + 1;
    drawBlockCurrentRects[key] = (drawBlockCurrentRects[key] or 0) + 1;
end

local function AddDrawBlockPassedRect(rect)
    local key = tostring(rect or 'rect=?');

    drawBlockPassedHits = drawBlockPassedHits + 1;
    drawBlockPassedRects[key] = (drawBlockPassedRects[key] or 0) + 1;
end

local function ResetPartyTraceFrame()
    partyTraceHits = 0;
    partyTraceRects = {};
end

local function AddPartyTraceRect(rect)
    local key = tostring(rect or 'rect=?');

    partyTraceHits = partyTraceHits + 1;
    partyTraceRects[key] = (partyTraceRects[key] or 0) + 1;
end

local function FormatRectCounts(rects, limit)
    local rows = {};

    for key, value in pairs(rects) do
        rows[#rows + 1] = {
            key = key,
            value = value,
        };
    end

    table.sort(rows, function(left, right)
        if (left.value ~= right.value) then
            return left.value > right.value;
        end

        return left.key < right.key;
    end);

    local parts = {};

    for index = 1, math.min(#rows, limit or 20) do
        parts[#parts + 1] = tostring(rows[index].value) .. 'x ' .. rows[index].key;
    end

    if (#parts == 0) then
        return '(none)';
    end

    return table.concat(parts, ' | ');
end

local function FormatDrawBlockRects(limit)
    return FormatRectCounts(drawBlockCurrentRects, limit);
end

local function FormatDrawBlockPassedRects(limit)
    return FormatRectCounts(drawBlockPassedRects, limit);
end

local function HasAnyTargetSafe()
    return SafeCall(false, function()
        local targetIndex, subTargetIndex = targeting.GetCurrentTargetAndSubTargetIndexes();
        return targetIndex ~= nil or subTargetIndex ~= nil;
    end);
end

local function UpdateDrawBlockBurst()
    if (drawBlockEnabled ~= true) then
        return false;
    end

    local hasTarget = HasAnyTargetSafe();

    if (drawBlockPreviousHadTarget ~= true and hasTarget == true) then
        drawBlockFrames = 2;
    elseif (hasTarget ~= true) then
        drawBlockFrames = 0;
    end

    drawBlockPreviousHadTarget = hasTarget == true;
    return drawBlockFrames > 0;
end

local function UpdateTraceCandidateBurst()
    if (traceEnabled ~= true) then
        return false;
    end

    return traceCandidateFrames > 0;
end

local function ResolvePointers()
    if (pointersResolved == true) then
        return;
    end

    pointersResolved = true;

    if (ashita == nil or ashita.memory == nil or ashita.memory.find == nil) then
        return;
    end

    local ptr = SafeCall(0, function()
        return ashita.memory.find('FFXiMain.dll', 0, '66C78182000000????C7818C000000????????C781900000', 0, 0);
    end);

    if (ptr == 0) then
        ptr = SafeCall(0, function()
            return ashita.memory.find(0, 0, '66C78182000000????C7818C000000????????C781900000', 0, 0);
        end);
    end;

    if (ptr ~= 0) then
        party0PrimitivePointer = SafeCall(0, function()
            return ashita.memory.read_uint32(ptr + 0x19);
        end);
        targetPrimitivePointer = SafeCall(0, function()
            return ashita.memory.read_uint32(ptr + 0x23);
        end);
    end

    local alliancePtr = SafeCall(0, function()
        return ashita.memory.find('FFXiMain.dll', 0, 'A1????????8B0D????????89442424A1????????33DB89', 0, 0);
    end);

    if (alliancePtr ~= 0) then
        party1PrimitivePointer = SafeCall(0, function()
            return ashita.memory.read_uint32(alliancePtr + 0x01);
        end);
        party2PrimitivePointer = SafeCall(0, function()
            return ashita.memory.read_uint32(alliancePtr + 0x07);
        end);
    end
end

local function SetPrimitiveVisibility(pointer, visible)
    pointer = tonumber(pointer) or 0;

    if (pointer == 0 or ashita == nil or ashita.memory == nil) then
        return false;
    end

    return SafeCall(false, function()
        local ptr = ashita.memory.read_uint32(pointer);

        if (ptr == 0) then
            return false;
        end

        ptr = ashita.memory.read_uint32(ptr + 0x08);

        if (ptr == 0) then
            return false;
        end

        local value = visible == true and 1 or 0;
        ashita.memory.write_uint8(ptr + 0x69, value);
        ashita.memory.write_uint8(ptr + 0x6A, value);
        return true;
    end);
end

local function GetPrimitiveVisibilityAddress(pointer)
    pointer = tonumber(pointer) or 0;

    if (pointer == 0 or ashita == nil or ashita.memory == nil) then
        return 0;
    end

    return SafeCall(0, function()
        local ptr = ashita.memory.read_uint32(pointer);

        if (ptr == 0) then
            return 0;
        end

        ptr = ashita.memory.read_uint32(ptr + 0x08);

        if (ptr == 0) then
            return 0;
        end

        return ptr + 0x69;
    end);
end

local function RefreshPrimitiveVisibilityAddresses()
    primitiveVisibilityAddresses.party0 = GetPrimitiveVisibilityAddress(party0PrimitivePointer);
    primitiveVisibilityAddresses.party1 = GetPrimitiveVisibilityAddress(party1PrimitivePointer);
    primitiveVisibilityAddresses.party2 = GetPrimitiveVisibilityAddress(party2PrimitivePointer);
    primitiveVisibilityAddresses.target = GetPrimitiveVisibilityAddress(targetPrimitivePointer);
end

local function WriteHiddenVisibility(address)
    address = tonumber(address) or 0;

    if (address == 0) then
        return false;
    end

    local ok1 = WriteUInt8(address, 0);
    local ok2 = WriteUInt8(address + 1, 0);

    return ok1 == true or ok2 == true;
end

local function HardHidePrimitivesForDraw(allowAutomaticBurst)
    local automaticHardHideActive =
        allowAutomaticBurst == true and
        hardHideBurstFrames > 0;
    local hardHideActive =
        hardHideManualEnabled == true or
        automaticHardHideActive == true;

    if (hardHideActive ~= true) then
        return;
    end

    local hideTargetForDraw =
        targetPrimitiveHideAllowed == true and
        (uiPrimitiveEnabled == true or hideAllPrimitiveEnabled == true);
    local hidePartyForDraw = false;

    if (hideTargetForDraw ~= true and hidePartyForDraw ~= true) then
        return;
    end

    if (
        tonumber(primitiveVisibilityAddresses.target) == nil or
        primitiveVisibilityAddresses.target == 0 or
        (
            hidePartyForDraw == true and
            (tonumber(primitiveVisibilityAddresses.party0) == nil or primitiveVisibilityAddresses.party0 == 0)
        )
    ) then
        ResolvePointers();
        RefreshPrimitiveVisibilityAddresses();
    end

    if (hidePartyForDraw == true) then
        if (WriteHiddenVisibility(primitiveVisibilityAddresses.party0) == true) then
            hardHideEveryDrawWrites = hardHideEveryDrawWrites + 1;
        end

        if (hardHideManualEnabled == true) then
            WriteHiddenVisibility(primitiveVisibilityAddresses.party1);
            WriteHiddenVisibility(primitiveVisibilityAddresses.party2);
        end
    end

    if (hideTargetForDraw == true) then
        WriteHiddenVisibility(primitiveVisibilityAddresses.target);
    end

    if (hidePartyForDraw == true and hardHideManualEnabled ~= true) then
        hardHideFrameWritten = true;
    end
end

function nativeTargetArrow.Update()
    ResolvePointers();
    RefreshPrimitiveVisibilityAddresses();

    if (hideAllPrimitiveEnabled == true) then
        SetPrimitiveVisibility(party0PrimitivePointer, false);
        SetPrimitiveVisibility(party1PrimitivePointer, false);
        SetPrimitiveVisibility(party2PrimitivePointer, false);
        SetPrimitiveVisibility(targetPrimitivePointer, targetPrimitiveHideAllowed ~= true);
    elseif (uiPrimitiveEnabled == true) then
        SetPrimitiveVisibility(targetPrimitivePointer, targetPrimitiveHideAllowed ~= true);
    else
        SetPrimitiveVisibility(targetPrimitivePointer, true);
    end

end

function nativeTargetArrow.HideAllPrimitivesOnce()
    ResolvePointers();
    SetPrimitiveVisibility(party0PrimitivePointer, false);
    SetPrimitiveVisibility(party1PrimitivePointer, false);
    SetPrimitiveVisibility(party2PrimitivePointer, false);
    if (targetPrimitiveHideAllowed == true) then
        SetPrimitiveVisibility(targetPrimitivePointer, false);
    end
end

function nativeTargetArrow.HideTargetPrimitiveOnce()
    ResolvePointers();
    if (targetPrimitiveHideAllowed == true) then
        SetPrimitiveVisibility(targetPrimitivePointer, false);
    end
end

function nativeTargetArrow.RestoreAll()
    ResolvePointers();
    SetPrimitiveVisibility(party0PrimitivePointer, true);
    SetPrimitiveVisibility(party1PrimitivePointer, true);
    SetPrimitiveVisibility(party2PrimitivePointer, true);
    SetPrimitiveVisibility(targetPrimitivePointer, true);
end

function nativeTargetArrow.SetEnabled(value)
    uiPrimitiveEnabled = value == true;

    if (uiPrimitiveEnabled ~= true) then
        SetPrimitiveVisibility(targetPrimitivePointer, true);
    end
end

function nativeTargetArrow.GetEnabled()
    return uiPrimitiveEnabled == true;
end

function nativeTargetArrow.SetHideAllPrimitivesEnabled(value)
    local enabled = value == true;

    if (hideAllPrimitiveEnabled == enabled) then
        return;
    end

    hideAllPrimitiveEnabled = enabled;
    hardHideEveryDrawWrites = 0;

    if (hideAllPrimitiveEnabled ~= true) then
        ResolvePointers();
        primitiveVisibilityAddresses = {};
        SetPrimitiveVisibility(party0PrimitivePointer, true);
        SetPrimitiveVisibility(party1PrimitivePointer, true);
        SetPrimitiveVisibility(party2PrimitivePointer, true);
    else
        ResolvePointers();
        RefreshPrimitiveVisibilityAddresses();
    end
end

function nativeTargetArrow.GetHideAllPrimitivesEnabled()
    return hideAllPrimitiveEnabled == true;
end

function nativeTargetArrow.SetTargetPrimitiveHideAllowed(value)
    local allowed = value == true;

    if (targetPrimitiveHideAllowed == allowed) then
        return;
    end

    targetPrimitiveHideAllowed = allowed;

    if (targetPrimitiveHideAllowed ~= true) then
        ResolvePointers();
        SetPrimitiveVisibility(targetPrimitivePointer, true);
    end
end

function nativeTargetArrow.GetStatusText()
    return 'native target ui hide=' .. tostring(uiPrimitiveEnabled == true) ..
        ' hideAll=' .. tostring(hideAllPrimitiveEnabled == true) ..
        ' targetHideAllowed=' .. tostring(targetPrimitiveHideAllowed == true) ..
        ' targetPtr=0x' .. string.format('%X', tonumber(targetPrimitivePointer) or 0) ..
        ' party0Ptr=0x' .. string.format('%X', tonumber(party0PrimitivePointer) or 0) ..
        ' party1Ptr=0x' .. string.format('%X', tonumber(party1PrimitivePointer) or 0) ..
        ' party2Ptr=0x' .. string.format('%X', tonumber(party2PrimitivePointer) or 0);
end

local function FormatHex(value)
    return '0x' .. string.format('%X', tonumber(value) or 0);
end

local function GetTargetWindowCandidateStatus(label, targetWindowPointer)
    targetWindowPointer = tonumber(targetWindowPointer) or 0;

    local lockShapePointer = targetWindowPointer ~= 0 and (ReadUInt32(targetWindowPointer + 0x5C) or 0) or 0;
    local shapeCount = 0;
    local firstShapePointer = 0;
    local selectedShapePointer = 0;
    local ankNum = targetWindowPointer ~= 0 and (ReadUInt8(targetWindowPointer + 0xBA) or 0) or 0;

    if (targetWindowPointer ~= 0) then
        for index = 0, 15 do
            local shapePointer = ReadUInt32(targetWindowPointer + 0x78 + (index * 4)) or 0;

            if (shapePointer ~= 0) then
                shapeCount = shapeCount + 1;

                if (firstShapePointer == 0) then
                    firstShapePointer = shapePointer;
                end
            end

            if (index == ankNum) then
                selectedShapePointer = shapePointer;
            end
        end
    end

    return tostring(label) .. '=' .. FormatHex(targetWindowPointer) ..
        ' loaded=' .. tostring(targetWindowPointer ~= 0 and ReadUInt8(targetWindowPointer + 0x6C) or nil) ..
        ' lockShape=' .. FormatHex(lockShapePointer) ..
        ' ankShapes=' .. tostring(shapeCount) ..
        ' firstShape=' .. FormatHex(firstShapePointer) ..
        ' ankNum=' .. tostring(ankNum) ..
        ' selectedShape=' .. FormatHex(selectedShapePointer) ..
        ' sub=' .. tostring(targetWindowPointer ~= 0 and ReadUInt8(targetWindowPointer + 0xB8) or nil) ..
        ' ank=' .. tostring(targetWindowPointer ~= 0 and ReadInt16(targetWindowPointer + 0xBC) or nil) .. ',' ..
            tostring(targetWindowPointer ~= 0 and ReadInt16(targetWindowPointer + 0xBE) or nil) ..
        ' subAnk=' .. tostring(targetWindowPointer ~= 0 and ReadInt16(targetWindowPointer + 0xC0) or nil) .. ',' ..
            tostring(targetWindowPointer ~= 0 and ReadInt16(targetWindowPointer + 0xC2) or nil);
end

function nativeTargetArrow.GetTargetWindowStatusText()
    ResolvePointers();

    local refPointer = tonumber(targetPrimitivePointer) or 0;
    local level1Pointer = refPointer ~= 0 and (ReadUInt32(refPointer) or 0) or 0;
    local level2Pointer = level1Pointer ~= 0 and (ReadUInt32(level1Pointer + 0x08) or 0) or 0;
    local level3Pointer = level2Pointer ~= 0 and (ReadUInt32(level2Pointer + 0x08) or 0) or 0;

    return 'targetRef=' .. FormatHex(refPointer) ..
        ' | ' .. GetTargetWindowCandidateStatus('ref', refPointer) ..
        ' | ' .. GetTargetWindowCandidateStatus('level1', level1Pointer) ..
        ' | ' .. GetTargetWindowCandidateStatus('level2', level2Pointer) ..
        ' | ' .. GetTargetWindowCandidateStatus('level3', level3Pointer);
end

function nativeTargetArrow.WriteTargetWindowStatus(label)
    local line = (label or 'windowstatus') .. ' ' .. nativeTargetArrow.GetTargetWindowStatusText();

    WriteTraceLine(line);
    WritePartyTraceLine(line);
end

local function AddTargetWindowProbePointer(rows, seen, label, pointer)
    pointer = tonumber(pointer) or 0;

    if (pointer == 0 or seen[pointer] == true) then
        return;
    end

    seen[pointer] = true;
    rows[#rows + 1] = {
        label = label,
        pointer = pointer,
    };
end

local function CollectTargetWindowProbePointers()
    ResolvePointers();

    local rows = {};
    local seen = {};
    local refPointer = tonumber(targetPrimitivePointer) or 0;
    local level1Pointer = refPointer ~= 0 and (ReadUInt32(refPointer) or 0) or 0;
    local level2Pointer = level1Pointer ~= 0 and (ReadUInt32(level1Pointer + 0x08) or 0) or 0;
    local level3Pointer = level2Pointer ~= 0 and (ReadUInt32(level2Pointer + 0x08) or 0) or 0;
    local windows = {
        { label = 'ref', pointer = refPointer },
        { label = 'level1', pointer = level1Pointer },
        { label = 'level2', pointer = level2Pointer },
        { label = 'level3', pointer = level3Pointer },
    };

    for _, window in ipairs(windows) do
        AddTargetWindowProbePointer(rows, seen, window.label, window.pointer);

        local windowPointer = tonumber(window.pointer) or 0;
        if (windowPointer ~= 0) then
            AddTargetWindowProbePointer(rows, seen, window.label .. '.lock', ReadUInt32(windowPointer + 0x5C) or 0);

            for index = 0, 15 do
                AddTargetWindowProbePointer(
                    rows,
                    seen,
                    window.label .. '.shape' .. tostring(index),
                    ReadUInt32(windowPointer + 0x78 + (index * 4)) or 0
                );
            end
        end
    end

    return rows;
end

local function IsUsefulProbeFloat(value)
    value = tonumber(value);

    if (value == nil or value ~= value) then
        return false;
    end

    return value > -100000 and value < 100000;
end

local function CaptureTargetWindowProbeSnapshot(label)
    local snapshot = {
        label = tostring(label or 'probe'),
        clock = os.clock(),
        values = {},
    };
    local pointers = CollectTargetWindowProbePointers();

    for _, row in ipairs(pointers) do
        local pointer = tonumber(row.pointer) or 0;
        local baseKey = tostring(row.label) .. '@' .. FormatHex(pointer);

        snapshot.values[baseKey .. '.u8.6C'] = ReadUInt8(pointer + 0x6C);
        snapshot.values[baseKey .. '.u8.B8'] = ReadUInt8(pointer + 0xB8);
        snapshot.values[baseKey .. '.u8.BA'] = ReadUInt8(pointer + 0xBA);
        snapshot.values[baseKey .. '.i16.BC'] = ReadInt16(pointer + 0xBC);
        snapshot.values[baseKey .. '.i16.BE'] = ReadInt16(pointer + 0xBE);
        snapshot.values[baseKey .. '.i16.C0'] = ReadInt16(pointer + 0xC0);
        snapshot.values[baseKey .. '.i16.C2'] = ReadInt16(pointer + 0xC2);

        for offset = 0, 0x120, 4 do
            local floatValue = ReadFloat(pointer + offset);
            if (IsUsefulProbeFloat(floatValue) == true) then
                snapshot.values[baseKey .. '.f.' .. string.format('%03X', offset)] = tonumber(string.format('%.4f', floatValue));
            end

            local intValue = ReadUInt32(pointer + offset);
            if (intValue ~= nil and intValue ~= 0 and intValue < 0x01000000) then
                snapshot.values[baseKey .. '.u32.' .. string.format('%03X', offset)] = intValue;
            end
        end
    end

    return snapshot;
end

local function FormatProbeValue(value)
    if (value == nil) then
        return 'nil';
    end

    if (type(value) == 'number') then
        return tostring(value);
    end

    return tostring(value);
end

local function FormatTargetWindowProbeDiff(previous, current, limit)
    if (previous == nil) then
        return 'first sample';
    end

    local rows = {};

    for key, value in pairs(current.values or {}) do
        local oldValue = previous.values ~= nil and previous.values[key] or nil;
        if (oldValue ~= value) then
            rows[#rows + 1] = key .. ':' .. FormatProbeValue(oldValue) .. '>' .. FormatProbeValue(value);
        end
    end

    table.sort(rows);

    local parts = {};
    for index = 1, math.min(#rows, limit or 80) do
        parts[#parts + 1] = rows[index];
    end

    if (#rows > #parts) then
        parts[#parts + 1] = '...+' .. tostring(#rows - #parts) .. ' more';
    end

    if (#parts == 0) then
        return 'no changes';
    end

    return table.concat(parts, ' | ');
end

function nativeTargetArrow.WriteTargetWindowProbe(label)
    local snapshot = CaptureTargetWindowProbeSnapshot(label);
    local diff = FormatTargetWindowProbeDiff(targetWindowProbePrevious, snapshot, 120);
    local file = io.open(GetTargetWindowProbeFilePath(), targetWindowProbePrevious == nil and 'w' or 'a');

    if (file ~= nil) then
        if (targetWindowProbePrevious == nil) then
            file:write('LibraPlates native fishing bar probe\n');
        end

        file:write('sample=' .. tostring(snapshot.label) .. ' clock=' .. string.format('%.3f', snapshot.clock) .. '\n');
        file:write('status ' .. nativeTargetArrow.GetTargetWindowStatusText() .. '\n');
        file:write('diff ' .. diff .. '\n');
        file:close();
    end

    targetWindowProbePrevious = snapshot;
    return diff;
end

function nativeTargetArrow.GetTargetWindowProbeFilePath()
    return GetTargetWindowProbeFilePath();
end

function nativeTargetArrow.SetTraceEnabled(value)
    traceEnabled = value == true;
    traceFrame = 0;
    tracePreviousHadTarget = false;
    tracePreviousSnapshot = nil;
    traceAfterTransitionFrames = 0;
    traceCandidateFrames = traceEnabled == true and 300 or 0;
    ResetTraceFrame();

    if (traceEnabled == true) then
        ResetTraceFile();
    end
end

function nativeTargetArrow.GetTraceEnabled()
    return traceEnabled == true;
end

function nativeTargetArrow.GetTraceStatusText()
    return 'native draw trace=' .. tostring(traceEnabled == true) .. ' frame=' .. tostring(traceFrame) ..
        ' block=' .. tostring(drawBlockEnabled == true) ..
        ' partyBlock=' .. tostring(partyBlockEnabled == true) ..
        ' blockFrames=' .. tostring(drawBlockFrames) ..
        ' blockHits=' .. tostring(drawBlockHits);
end

function nativeTargetArrow.GetTraceFilePath()
    return GetTraceFilePath();
end

function nativeTargetArrow.SetPartyTraceEnabled(value)
    partyTraceEnabled = value == true;
    partyTraceFrames = partyTraceEnabled == true and 300 or 0;
    partyTraceFrame = 0;
    ResetPartyTraceFrame();

    if (partyTraceEnabled == true) then
        ResetPartyTraceFile();
    end
end

function nativeTargetArrow.GetPartyTraceEnabled()
    return partyTraceEnabled == true;
end

function nativeTargetArrow.GetPartyTraceStatusText()
    return 'native party trace=' .. tostring(partyTraceEnabled == true) ..
        ' frame=' .. tostring(partyTraceFrame) ..
        ' frames=' .. tostring(partyTraceFrames);
end

function nativeTargetArrow.GetPartyTraceFilePath()
    return GetPartyTraceFilePath();
end

function nativeTargetArrow.SetTraceCapturePaused(value)
    traceCapturePaused = value == true;
end

function nativeTargetArrow.SetDrawBlockEnabled(value)
    local enabled = value == true;

    if (drawBlockEnabled == enabled) then
        return;
    end

    drawBlockEnabled = enabled;
    drawBlockFrames = 0;
    drawBlockPreviousHadTarget = false;
    drawBlockHits = 0;
    ResetDrawBlockFrame();
end

function nativeTargetArrow.GetDrawBlockEnabled()
    return drawBlockEnabled == true;
end

function nativeTargetArrow.SetPartyBlockEnabled(value)
    partyBlockEnabled = value == true;
    ResetDrawBlockFrame();
end

function nativeTargetArrow.GetPartyBlockEnabled()
    return partyBlockEnabled == true;
end

function nativeTargetArrow.SetFishingBarCaptureEnabled(value)
    fishingBarCaptureEnabled = value == true;

    if (fishingBarCaptureEnabled ~= true) then
        fishingBarRects = {};
        fishingBarFrameBackground = nil;
        fishingBarFrameFill = nil;
        fishingBarLastState = nil;
    end
end

function nativeTargetArrow.GetFishingBarCaptureEnabled()
    return fishingBarCaptureEnabled == true;
end

function nativeTargetArrow.GetFishingBarState(maxAge)
    if (fishingBarLastState == nil) then
        return nil;
    end

    maxAge = tonumber(maxAge) or 0.35;
    if ((os.clock() - (tonumber(fishingBarLastState.clock) or 0)) > maxAge) then
        return nil;
    end

    return fishingBarLastState;
end

function nativeTargetArrow.StartFishingBarProbe(seconds)
    local duration = math.max(1, tonumber(seconds) or 15);
    fishingBarProbeUntil = os.clock() + duration;
    fishingBarProbeNextLog = 0;
    log.Info('Fishing bar probe started for ' .. tostring(duration) .. 's. Hook a fish now.');
end

function nativeTargetArrow.GetFishingBarProbeStatusText()
    local stateAge = fishingBarLastState ~= nil and (os.clock() - (tonumber(fishingBarLastState.clock) or 0)) or nil;

    return tostring(fishingBarProbeLastText) ..
        ' probeActive=' .. tostring(IsFishingBarProbeActive() == true) ..
        ' lastAge=' .. tostring(stateAge ~= nil and string.format('%.2f', stateAge) or 'nil');
end

function nativeTargetArrow.SetHardHideEveryDrawEnabled(value)
    hardHideManualEnabled = value == true;
    hardHideEveryDrawWrites = 0;
end

function nativeTargetArrow.GetHardHideEveryDrawEnabled()
    return hardHideManualEnabled == true;
end

function nativeTargetArrow.GetHardHideEveryDrawStatusText()
    return 'hardHideManual=' .. tostring(hardHideManualEnabled == true) ..
        ' hardHideBurst=' .. tostring(hardHideBurstFrames) ..
        ' autoPath=once-per-frame-party0-target' ..
        ' frameWritten=' .. tostring(hardHideFrameWritten == true) ..
        ' hardHideWrites=' .. tostring(hardHideEveryDrawWrites) ..
        ' party0Vis=0x' .. string.format('%X', tonumber(primitiveVisibilityAddresses.party0) or 0);
end

function nativeTargetArrow.ShouldUseDrawHooks()
    return traceEnabled == true or
        partyTraceEnabled == true or
        drawBlockFrames > 0 or
        partyBlockEnabled == true or
        fishingBarCaptureEnabled == true or
        hardHideManualEnabled == true or
        hardHideBurstFrames > 0;
end

function nativeTargetArrow.SetHardHideBurstFrames(frames)
    local value = math.max(0, math.floor(tonumber(frames) or 0));

    if (value > hardHideBurstFrames) then
        hardHideBurstFrames = value;
    end
end

function nativeTargetArrow.HandleDrawPrimitive(e)
    local perfToken = perfMeter.BeginDetail('native.hook');

    HardHidePrimitivesForDraw(true);

    if (traceEnabled ~= true or e == nil) then
        perfMeter.EndDetail(perfToken);
        return;
    end

    AddTraceKey(string.format(
        'dp pt=%s sv=%s pc=%s',
        tostring(e.primitive_type),
        tostring(e.start_vertex),
        tostring(e.primitive_count)
    ));

    perfMeter.EndDetail(perfToken);
end

function nativeTargetArrow.HandleDrawIndexedPrimitive(e)
    local perfToken = perfMeter.BeginDetail('native.hook');

    HardHidePrimitivesForDraw(true);

    if (traceEnabled ~= true or e == nil) then
        perfMeter.EndDetail(perfToken);
        return;
    end

    AddTraceKey(string.format(
        'dip pt=%s min=%s nv=%s si=%s pc=%s',
        tostring(e.primitive_type),
        tostring(e.min_index),
        tostring(e.num_vertices),
        tostring(e.start_index),
        tostring(e.prim_count)
    ));

    perfMeter.EndDetail(perfToken);
end

function nativeTargetArrow.HandleDrawPrimitiveUp(e)
    local perfToken = perfMeter.BeginDetail('native.hook');

    HardHidePrimitivesForDraw(true);

    local rect = nil;
    local shouldInspect =
        e ~= nil and
        traceCapturePaused ~= true and
        tonumber(e.primitive_type) == 5 and
        tonumber(e.primitive_count) == 2;

    local blockBurstActive = UpdateDrawBlockBurst();
    local traceBurstActive = UpdateTraceCandidateBurst();

    local stride = shouldInspect == true and tonumber(e.vertex_stream_zero_stride) or nil;
    local partyTraceActive =
        partyTraceEnabled == true and
        partyTraceFrames > 0;
    local partyBlockActive =
        partyBlockEnabled == true and
        (hideAllPrimitiveEnabled == true or fishingBarCaptureEnabled == true);

    if (shouldInspect == true and (blockBurstActive == true or partyBlockActive == true or traceBurstActive == true or partyTraceActive == true or fishingBarCaptureEnabled == true)) then
        rect = GetVertexRect(
            e.vertex_stream_zero_data,
            e.vertex_stream_zero_stride,
            e.primitive_type,
            e.primitive_count
        );

        local key = 'stride=' .. tostring(e.vertex_stream_zero_stride) .. ' ' .. tostring(rect or 'rect=?');

        local shouldBlock =
            (partyBlockActive == true and stride == 20 and IsCandidateUiRect(rect) == true) or
            (
                blockBurstActive == true and
                (
                    (stride == 28 and IsBlockableUiRect(rect) == true) or
                    (stride == 20 and IsPartyWindowRect(rect) == true)
                )
            );

        if (fishingBarCaptureEnabled == true and IsFishingBarCandidateRect(rect) == true) then
            AddFishingBarCandidate(rect, 'primitive');
            if (IsKnownFishingBarRect(rect) == true) then
                shouldBlock = true;
            end
        end

        if (partyTraceActive == true and stride == 20 and IsCandidateUiRect(rect) == true) then
            AddPartyTraceRect(
                (shouldBlock == true and 'blocked ' or 'passed ') ..
                'match=' .. tostring(IsPartyWindowRect(rect) == true) ..
                ' ' .. tostring(rect or 'rect=?')
            );
        end

        if (shouldBlock == true) then
            e.blocked = true;
            drawBlockHits = drawBlockHits + 1;
            AddDrawBlockRect(key);
        elseif (IsCandidateUiRect(rect) == true) then
            AddDrawBlockPassedRect(key);
        end
    end

    if (traceEnabled ~= true or e == nil) then
        perfMeter.EndDetail(perfToken);
        return;
    end

    rect = rect or GetVertexRect(
        e.vertex_stream_zero_data,
        e.vertex_stream_zero_stride,
        e.primitive_type,
        e.primitive_count
    );

    AddTraceKey(string.format(
        'dpup pt=%s pc=%s stride=%s%s',
        tostring(e.primitive_type),
        tostring(e.primitive_count),
        tostring(e.vertex_stream_zero_stride),
        rect or ''
    ));

    perfMeter.EndDetail(perfToken);
end

function nativeTargetArrow.HandleDrawIndexedPrimitiveUp(e)
    local perfToken = perfMeter.BeginDetail('native.hook');

    HardHidePrimitivesForDraw(true);

    if (e == nil) then
        perfMeter.EndDetail(perfToken);
        return;
    end

    local rect = GetVertexRect(
        e.vertex_stream_zero_data,
        e.vertex_stream_zero_stride,
        e.primitive_type,
        e.primitive_count
    );

    if (fishingBarCaptureEnabled == true and traceCapturePaused ~= true and IsFishingBarCandidateRect(rect) == true) then
        AddFishingBarCandidate(rect, 'indexed');
        if (IsKnownFishingBarRect(rect) == true) then
            e.blocked = true;
        end
    end

    if (traceEnabled ~= true) then
        perfMeter.EndDetail(perfToken);
        return;
    end

    AddTraceKey(string.format(
        'dipup pt=%s min=%s nv=%s pc=%s stride=%s%s',
        tostring(e.primitive_type),
        tostring(e.min_vertex_index),
        tostring(e.num_vertex_indices),
        tostring(e.primitive_count),
        tostring(e.vertex_stream_zero_stride),
        rect or ''
    ));

    perfMeter.EndDetail(perfToken);
end

function nativeTargetArrow.EndTraceFrame()
    hardHideFrameWritten = false;

    if (fishingBarCaptureEnabled == true) then
        UpdateFishingBarStateFromFrame();
        BeginFishingBarFrame();

        if (IsFishingBarProbeActive() == true and os.clock() >= (tonumber(fishingBarProbeNextLog) or 0)) then
            log.Info(fishingBarProbeLastText);
            fishingBarProbeNextLog = os.clock() + 1.0;
        end
    end

    if (hardHideBurstFrames > 0) then
        hardHideBurstFrames = hardHideBurstFrames - 1;
    end

    if (partyTraceEnabled == true and partyTraceHits > 0) then
        WritePartyTraceLine(
            'party frame=' .. tostring(partyTraceFrame) ..
            ' hits=' .. tostring(partyTraceHits) ..
            ' ' .. FormatRectCounts(partyTraceRects, 24)
        );
        ResetPartyTraceFrame();
    end

    if (partyTraceEnabled == true) then
        partyTraceFrame = partyTraceFrame + 1;
    end

    if (traceEnabled == true and drawBlockCurrentHits > 0) then
        WriteTraceLine('native block frame hits=' .. tostring(drawBlockCurrentHits) .. ' ' .. FormatDrawBlockRects(24));
    end

    if (traceEnabled == true and drawBlockPassedHits > 0) then
        WriteTraceLine('native pass frame hits=' .. tostring(drawBlockPassedHits) .. ' ' .. FormatDrawBlockPassedRects(24));
    end

    if (drawBlockCurrentHits > 0 or drawBlockPassedHits > 0) then
        ResetDrawBlockFrame();
    end

    if (drawBlockFrames > 0) then
        drawBlockFrames = drawBlockFrames - 1;
    end

    if (partyTraceFrames > 0) then
        partyTraceFrames = partyTraceFrames - 1;
    end

    if (traceCandidateFrames > 0) then
        traceCandidateFrames = traceCandidateFrames - 1;
    end

    if (traceEnabled ~= true) then
        return;
    end

    traceFrame = traceFrame + 1;

    local hasTarget = HasAnyTargetSafe();
    local snapshot = CopyTraceSnapshot();

    if (tracePreviousHadTarget ~= true and hasTarget == true) then
        WriteTraceLine('native trace target-acquire frame=' .. tostring(traceFrame) .. ' draws=' .. tostring(snapshot.total));
        WriteTraceLine('native trace added: ' .. FormatTraceDiff(tracePreviousSnapshot, snapshot, 24));
        traceAfterTransitionFrames = 2;
    elseif (traceAfterTransitionFrames > 0) then
        WriteTraceLine('native trace followup frame=' .. tostring(traceFrame) .. ' draws=' .. tostring(snapshot.total) .. ' added=' .. FormatTraceDiff(tracePreviousSnapshot, snapshot, 14));
        traceAfterTransitionFrames = traceAfterTransitionFrames - 1;
    end

    tracePreviousHadTarget = hasTarget == true;
    tracePreviousSnapshot = snapshot;
    ResetTraceFrame();
end

return nativeTargetArrow;
