local state = require('core.state');

local profiles = {};

function profiles.GetActiveName()
    return state.GetActiveProfileName();
end

function profiles.GetNames()
    return state.GetProfileNames();
end

function profiles.SetActive(name)
    return state.SetActiveProfile(name);
end

function profiles.Create(name, copyCurrent)
    return state.CreateProfile(name, copyCurrent);
end

function profiles.Copy(sourceName, newName)
    return state.CopyProfile(sourceName, newName);
end

function profiles.Rename(oldName, newName)
    return state.RenameProfile(oldName, newName);
end

function profiles.Delete(name)
    return state.DeleteProfile(name);
end

function profiles.Reset(name)
    return state.ResetProfile(name);
end

return profiles;
