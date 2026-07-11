local mounted = {};

local mountedEntityStatuses = {
    [5] = true,  -- Rental chocobo.
    [85] = true, -- Personal mounts.
};

local defaultPlateLift = 1.05;
local plateLiftByMountId = {
    [51] = 0.4,
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

function mounted.GetPlateLift(index)
    local mountId = nil;

    pcall(function()
        local entity = AshitaCore:GetMemoryManager():GetEntity();

        if (entity ~= nil and entity.GetMountId ~= nil and index ~= nil) then
            mountId = entity:GetMountId(index);
        end
    end);

    return plateLiftByMountId[tonumber(mountId)] or defaultPlateLift;
end

return mounted;
