local mounted = {};

local mountedEntityStatuses = {
    [5] = true,  -- Rental chocobo.
    [85] = true, -- Personal mounts.
};

function mounted.IsStatus(status)
    return mountedEntityStatuses[tonumber(status) or 0] == true;
end

function mounted.GetSelfStatus()
    local ok, status = pcall(function()
        local memory = AshitaCore:GetMemoryManager();
        local party = memory ~= nil and memory:GetParty() or nil;
        local entity = memory ~= nil and memory:GetEntity() or nil;
        local selfIndex = party ~= nil and party:GetMemberTargetIndex(0) or nil;

        if (selfIndex == nil or selfIndex <= 0 or entity == nil or entity.GetStatus == nil) then
            return nil;
        end

        return entity:GetStatus(selfIndex);
    end);

    return ok == true and status or nil;
end

function mounted.IsSelfMounted()
    return mounted.IsStatus(mounted.GetSelfStatus());
end

return mounted;
