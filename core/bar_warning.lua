local warning = {};

local function ResolveSetting(settings, defaults, key, fallback)
    if (settings ~= nil and settings[key] ~= nil) then
        return settings[key];
    end

    if (defaults ~= nil and defaults[key] ~= nil) then
        return defaults[key];
    end

    return fallback;
end

function warning.ResolveHp(settings, defaults, hpPercent, normalColor)
    settings = settings or {};
    defaults = defaults or {};
    hpPercent = tonumber(hpPercent) or 100;

    local criticalEnabled = ResolveSetting(settings, defaults, 'criticalColorEnabled', true) == true;
    local criticalPercent = tonumber(ResolveSetting(settings, defaults, 'criticalColorPercent', 25)) or 25;

    if (criticalEnabled == true and hpPercent <= criticalPercent) then
        return ResolveSetting(settings, defaults, 'criticalColor', { 1.0, 0.15, 0.10, 1.0 }), true;
    end

    local lowEnabled = ResolveSetting(settings, defaults, 'lowColorEnabled', true) == true;
    local lowPercent = tonumber(ResolveSetting(settings, defaults, 'lowColorPercent', 50)) or 50;

    if (lowEnabled == true and hpPercent <= lowPercent) then
        return ResolveSetting(settings, defaults, 'lowColor', { 1.0, 0.55, 0.05, 1.0 }), false;
    end

    return normalColor, false;
end

return warning;
