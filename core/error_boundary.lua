local log = require('core.log');

local errorBoundary = {};
local activeFailures = {};
local repeatLogIntervalSeconds = 10;

function errorBoundary.Call(key, label, callback, ...)
    if (type(callback) ~= 'function') then
        return false, nil;
    end

    local ok, value1, value2, value3, value4 = pcall(callback, ...);
    local failureKey = tostring(key or label or 'unknown');
    local failure = activeFailures[failureKey];

    if (ok == true) then
        if (failure ~= nil) then
            failure.active = false;
        end
        return true, value1, value2, value3, value4;
    end

    local now = os.clock();

    if (failure == nil) then
        failure = {
            active = false,
            lastLoggedAt = nil,
        };
        activeFailures[failureKey] = failure;
    end

    local shouldLog =
        failure.active ~= true and
        (
            failure.lastLoggedAt == nil or
            (now - failure.lastLoggedAt) >= repeatLogIntervalSeconds
        );

    failure.active = true;

    if (shouldLog == true) then
        failure.lastLoggedAt = now;
        log.Warn(
            tostring(label or failureKey) ..
            ' failed; unrelated LibraPlates systems continued: ' ..
            tostring(value1)
        );
    end

    return false, nil;
end

function errorBoundary.Reset()
    activeFailures = {};
end

return errorBoundary;
