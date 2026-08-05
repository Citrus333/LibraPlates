local targeting = require('core.targeting');
local entities = require('core.entities');

local nativeUiPolicy = {};

local function GetTargetingSettings()
    local ok, settings = pcall(function()
        return targeting.GetSettings();
    end);

    if (ok == true and type(settings) == 'table') then
        return settings;
    end

    return {};
end

local function ForceNativeUi()
    local ok, forced = pcall(function()
        return entities.IsMogHouseObjectSuppressionArea() == true;
    end);

    return ok == true and forced == true;
end

function nativeUiPolicy.IsNativeUiForced()
    return ForceNativeUi() == true;
end

function nativeUiPolicy.ShowNativeParty()
    if (ForceNativeUi() == true) then
        return true;
    end

    local settings = GetTargetingSettings();

    if (settings.hideNativeTargetArrow == true) then
        return false;
    end

    return settings.hideNativePartyTargetUi ~= true;
end

function nativeUiPolicy.UseNativeTargetingSystem()
    local settings = GetTargetingSettings();

    if (settings.hideNativePartyTargetUi == true) then
        return false;
    end

    return settings.hideNativeTargetArrow ~= true;
end

function nativeUiPolicy.UseNativeNames()
    return GetTargetingSettings().hideNativeNamesOnLoad ~= true;
end

function nativeUiPolicy.ShouldOverwriteNativeNameColors()
    return GetTargetingSettings().overwriteNativeNameColors ~= false;
end

function nativeUiPolicy.ShouldDrawLibraTargetingSystem()
    return nativeUiPolicy.UseNativeTargetingSystem() ~= true;
end

function nativeUiPolicy.ShouldDrawLibraNames()
    return nativeUiPolicy.UseNativeNames() ~= true;
end

return nativeUiPolicy;
