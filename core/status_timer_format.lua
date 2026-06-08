local statusTimerFormat = {};

function statusTimerFormat.Format(seconds)
    seconds = tonumber(seconds);

    if (seconds == nil) then
        return '';
    end

    seconds = math.max(0, math.ceil(seconds));

    if (seconds >= 86400) then
        return tostring(math.max(1, math.ceil(seconds / 86400))) .. 'd';
    end

    if (seconds >= 3600) then
        local hours = math.floor(seconds / 3600);
        local minutes = math.ceil((seconds - (hours * 3600)) / 60);

        if (minutes >= 60) then
            hours = hours + 1;
            minutes = 0;
        end

        return tostring(hours) .. ':' .. string.format('%02d', minutes) .. 'h';
    end

    if (seconds >= 600) then
        return tostring(math.max(1, math.ceil(seconds / 60))) .. 'm';
    end

    if (seconds >= 60) then
        local minutes = math.floor(seconds / 60);
        local remainder = seconds - (minutes * 60);
        return tostring(minutes) .. ':' .. string.format('%02d', remainder);
    end

    return tostring(seconds) .. 's';
end

return statusTimerFormat;
