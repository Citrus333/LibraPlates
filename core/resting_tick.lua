local restingTick = {};

local tickState = {
    active = false,
    cycleStart = nil,
    cycleLength = 20,
    displayLength = 20,
    lastMp = nil,
};

local function Reset()
    tickState.active = false;
    tickState.cycleStart = nil;
    tickState.cycleLength = 20;
    tickState.displayLength = 20;
    tickState.lastMp = nil;
end

local function IsResting(status)
    return tonumber(status) == 33;
end

local function ResyncFromObservedMpTick(now, settings)
    local elapsed = now - (tickState.cycleStart or now);
    local expectedLength = math.max(1, tonumber(tickState.cycleLength) or 10);
    local overrun = math.max(0, elapsed - expectedLength);
    local repeatLength = math.max(1, 10 + (tonumber(settings.repeatTickOffset) or 0) - overrun);

    tickState.active = true;
    tickState.cycleStart = now;
    tickState.cycleLength = repeatLength;
    tickState.displayLength = repeatLength;
end

function restingTick.Reset()
    Reset();
end

function restingTick.IsResting(status)
    return IsResting(status);
end

function restingTick.Get(status, hp, mp, maxMp, settings)
    if (type(maxMp) == 'table' and settings == nil) then
        settings = maxMp;
        maxMp = nil;
    end

    settings = settings or {};

    if (settings.enabled == false or IsResting(status) ~= true) then
        Reset();
        return nil;
    end

    local now = os.clock();
    local mpValue = tonumber(mp);
    local maxMpValue = tonumber(maxMp);
    local canDetectFullMp = maxMpValue ~= nil and maxMpValue > 0;
    local mpIsFull = canDetectFullMp == true and mpValue ~= nil and mpValue >= maxMpValue;
    local mpTickThreshold = tonumber(settings.mpTickThreshold) or 12;

    if (tickState.active ~= true or tickState.cycleStart == nil) then
        tickState.active = true;
        tickState.cycleStart = now;
        tickState.cycleLength = math.max(1, 20 + (tonumber(settings.firstTickOffset) or 1));
        tickState.displayLength = 20;
    elseif (mpValue ~= nil and tickState.lastMp ~= nil and (mpValue - tickState.lastMp) > mpTickThreshold) then
        ResyncFromObservedMpTick(now, settings);
    end

    tickState.lastMp = mpValue;

    local elapsed = now - tickState.cycleStart;

    if (elapsed >= tickState.cycleLength) then
        if (canDetectFullMp == true and mpIsFull ~= true) then
            return {
                progress = 0,
                text = '0s',
            };
        end

        while (elapsed >= tickState.cycleLength) do
            elapsed = elapsed - tickState.cycleLength;
            tickState.cycleStart = now - elapsed;
            tickState.cycleLength = math.max(1, 10 + (tonumber(settings.repeatTickOffset) or 0));
            tickState.displayLength = 10;
        end
    end

    local remaining = math.max(0, tickState.cycleLength - elapsed);
    local progress = (remaining / tickState.cycleLength) * 100;
    local displayRemaining = math.max(0, math.ceil((remaining / tickState.cycleLength) * tickState.displayLength));

    return {
        progress = progress,
        text = tostring(displayRemaining) .. 's',
    };
end

return restingTick;
