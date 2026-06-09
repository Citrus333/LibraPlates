local restingTick = {};

local tickState = {
    active = false,
    cycleStart = nil,
    cycleLength = 20,
    displayLength = 20,
    lastMp = nil,
};
local logoutState = {
    active = false,
    startClock = nil,
    endClock = nil,
    duration = 30,
    seenResting = false,
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

local function StripControlCodes(text)
    return tostring(text or ''):gsub(string.char(0x1E) .. '.', ''):gsub('[%z\1-\31]', '');
end

local function ClearLogout()
    logoutState.active = false;
    logoutState.startClock = nil;
    logoutState.endClock = nil;
    logoutState.duration = 30;
    logoutState.seenResting = false;
end

local function ShouldPreserveLogoutTransition()
    if (logoutState.active ~= true or logoutState.startClock == nil) then
        return false;
    end

    return logoutState.seenResting ~= true and (os.clock() - logoutState.startClock) < 2.50;
end

local function GetLogoutCountdown(settings)
    settings = settings or {};

    if (settings.enableLogoutCountdown == false or logoutState.active ~= true or logoutState.endClock == nil) then
        return nil;
    end

    local now = os.clock();
    local remaining = math.max(0, logoutState.endClock - now);
    local duration = math.max(1, tonumber(logoutState.duration) or 30);

    if (remaining <= 0) then
        ClearLogout();
        return nil;
    end

    return {
        progress = (remaining / duration) * 100,
        text = 'Logout ' .. tostring(math.ceil(remaining)) .. 's',
    };
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

function restingTick.ResetAll()
    Reset();
    ClearLogout();
end

function restingTick.IsResting(status)
    return IsResting(status);
end

function restingTick.IsLogoutActive(settings)
    return GetLogoutCountdown(settings) ~= nil;
end

function restingTick.ShouldPreserveLogoutTransition()
    return ShouldPreserveLogoutTransition();
end

function restingTick.HandleTextIn(e)
    local message = StripControlCodes(
        (e ~= nil and (e.message or e.text or e.original or e.modified or e.injected)) or ''
    );

    if (message == '') then
        return;
    end

    local seconds = string.match(message, 'Executing logout in (%d+) seconds');

    if (seconds ~= nil) then
        local duration = math.max(1, tonumber(seconds) or 30);

        logoutState.active = true;
        logoutState.startClock = os.clock();
        logoutState.endClock = logoutState.startClock + duration;
        logoutState.duration = duration;
        logoutState.seenResting = false;
        return;
    end

    if (message:find('Cancel healing to remain logged in.', 1, true) ~= nil) then
        ClearLogout();
    end
end

function restingTick.Get(status, hp, mp, maxMp, settings)
    if (type(maxMp) == 'table' and settings == nil) then
        settings = maxMp;
        maxMp = nil;
    end

    settings = settings or {};

    if (settings.enabled == false) then
        Reset();
        ClearLogout();
        return nil;
    end

    if (IsResting(status) ~= true) then
        Reset();

        if (ShouldPreserveLogoutTransition() ~= true) then
            ClearLogout();
        end

        return nil;
    end

    if (logoutState.active == true) then
        logoutState.seenResting = true;
    end

    local logoutCountdown = GetLogoutCountdown(settings);

    if (logoutCountdown ~= nil) then
        return logoutCountdown;
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
