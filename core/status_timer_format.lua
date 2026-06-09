local statusTimerFormat = {};

function statusTimerFormat.Format(seconds)
    seconds = tonumber(seconds);

    if (seconds == nil) then
        return '';
    end

    seconds = math.max(0, math.ceil(seconds));

    if (seconds >= 86400) then
        return tostring(math.max(1, math.floor(seconds / 86400))) .. 'd';
    end

    if (seconds >= 3600) then
        return tostring(math.max(1, math.floor(seconds / 3600))) .. 'h';
    end

    if (seconds >= 60) then
        return tostring(math.max(1, math.floor(seconds / 60))) .. 'm';
    end

    return tostring(seconds) .. 's';
end

return statusTimerFormat;
