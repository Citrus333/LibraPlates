local streamerNames = {};

local aliases = {};
local selfAlias = 'Player1';
local nextAliasNumber = 2;

local function NormalizeName(name)
    return tostring(name or ''):lower():gsub('[^%w]', '');
end

local function GetIdentityKey(player)
    local serverId = tonumber(player ~= nil and player.serverId) or 0;

    if (serverId > 0) then
        return 'sid:' .. tostring(serverId);
    end

    local name = NormalizeName(player ~= nil and player.name or '');

    if (name ~= '') then
        return 'name:' .. name;
    end

    return 'index:' .. tostring(player ~= nil and player.index or '');
end

local function IsEnabled(settings)
    return settings ~= nil and settings.streamerModeEnabled == true;
end

local function GetAlias(player)
    local key = GetIdentityKey(player);

    if (aliases[key] == nil) then
        aliases[key] = 'Player' .. tostring(nextAliasNumber);
        nextAliasNumber = nextAliasNumber + 1;
    end

    return aliases[key];
end

function streamerNames.GetDisplayName(player, fallbackName, settings)
    if (IsEnabled(settings) ~= true) then
        return fallbackName;
    end

    return GetAlias(player);
end

function streamerNames.GetSelfDisplayName(fallbackName, settings)
    if (IsEnabled(settings) ~= true) then
        return fallbackName;
    end

    return selfAlias;
end

function streamerNames.GetSelfSignature(settings)
    if (IsEnabled(settings) ~= true) then
        return 'streamer=off';
    end

    return 'streamer=self:' .. selfAlias;
end

function streamerNames.GetSignature(player, settings)
    if (IsEnabled(settings) ~= true) then
        return 'streamer=off';
    end

    return 'streamer=numbered:' .. GetAlias(player);
end

return streamerNames;
