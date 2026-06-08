local log = {};

function log.Info(message)
    print('[LibraPlates] ' .. tostring(message));
end

function log.Warn(message)
    print('[LibraPlates] Warning: ' .. tostring(message));
end

return log;
