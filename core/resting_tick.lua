local restingTick = {};

local tickState = {
    active = false,
    cycleStart = nil,
    cycleLength = 20,
    displayLength = 20,
    awaitingFirstTick = false,
    lastHp = nil,
    lastMp = nil,
};
local logoutState = {
    active = false,
    startClock = nil,
    endClock = nil,
    duration = 30,
    seenResting = false,
    label = 'Logout',
};

local function Reset()
    tickState.active = false;
    tickState.cycleStart = nil;
    tickState.cycleLength = 20;
    tickState.displayLength = 20;
    tickState.awaitingFirstTick = false;
    tickState.lastHp = nil;
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
    logoutState.label = 'Logout';
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
        text = tostring(math.ceil(remaining)) .. 's',
        label = tostring(logoutState.label or 'Logout'),
        countdown = true,
    };
end

local function ResyncFromObservedMpTick(now)
    local elapsed = now - (tickState.cycleStart or now);
    local expectedLength = math.max(1, tonumber(tickState.cycleLength) or 10);
    local overrun = math.max(0, elapsed - expectedLength);
    local repeatLength = math.max(1, 10 - overrun);

    tickState.active = true;
    tickState.cycleStart = now;
    tickState.cycleLength = repeatLength;
    tickState.displayLength = repeatLength;
end

local function StartRepeatCycleFromObservedTick(now)
    tickState.active = true;
    tickState.awaitingFirstTick = false;
    tickState.cycleStart = now;
    tickState.cycleLength = 10;
    tickState.displayLength = 10;
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

    local lowerMessage = string.lower(message);
    local action, seconds = string.match(lowerMessage, 'executing (logout) in (%d+) seconds');

    if (seconds == nil) then
        action, seconds = string.match(lowerMessage, 'executing (shutdown) in (%d+) seconds');
    end

    if (seconds ~= nil) then
        local duration = math.max(1, tonumber(seconds) or 30);

        logoutState.active = true;
        logoutState.startClock = os.clock();
        logoutState.endClock = logoutState.startClock + duration;
        logoutState.duration = duration;
        logoutState.seenResting = false;
        logoutState.label = (tostring(action or 'logout') == 'shutdown') and 'Shutdown' or 'Logout';
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
    local hpValue = tonumber(hp);
    local mpValue = tonumber(mp);
    local maxMpValue = tonumber(maxMp);
    local canDetectFullMp = maxMpValue ~= nil and maxMpValue > 0;
    local mpIsFull = canDetectFullMp == true and mpValue ~= nil and mpValue >= maxMpValue;
    local mpTickThreshold = 12;
    local hpTickThreshold = tonumber(settings.hpTickThreshold) or mpTickThreshold;
    local mpGain = (mpValue ~= nil and tickState.lastMp ~= nil) and (mpValue - tickState.lastMp) or 0;
    local hpGain = (hpValue ~= nil and tickState.lastHp ~= nil) and (hpValue - tickState.lastHp) or 0;
    local observedTick = mpGain > mpTickThreshold or hpGain > hpTickThreshold;

    if (tickState.active ~= true or tickState.cycleStart == nil) then
        tickState.active = true;
        tickState.cycleStart = now;
        tickState.cycleLength = 20;
        tickState.displayLength = 20;
        tickState.awaitingFirstTick = true;
    elseif (tickState.awaitingFirstTick == true and observedTick == true) then
        StartRepeatCycleFromObservedTick(now);
    elseif (tickState.awaitingFirstTick ~= true and mpGain > mpTickThreshold) then
        ResyncFromObservedMpTick(now);
    end

    tickState.lastHp = hpValue;
    tickState.lastMp = mpValue;

    local elapsed = now - tickState.cycleStart;

    if (elapsed >= tickState.cycleLength) then
        if (tickState.awaitingFirstTick == true) then
            return {
                progress = 0,
                text = '0s',
            };
        end

        if (canDetectFullMp == true and mpIsFull ~= true) then
            return {
                progress = 0,
                text = '0s',
            };
        end

        while (elapsed >= tickState.cycleLength) do
            elapsed = elapsed - tickState.cycleLength;
            tickState.cycleStart = now - elapsed;
            tickState.cycleLength = 10;
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
