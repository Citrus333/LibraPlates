require('common');

local entities = require('core.entities');
local log = require('core.log');

local jobChange = {};

local jobCodeToId = {
    ['WAR'] = 1,
    ['MNK'] = 2,
    ['WHM'] = 3,
    ['BLM'] = 4,
    ['RDM'] = 5,
    ['THF'] = 6,
    ['PLD'] = 7,
    ['DRK'] = 8,
    ['BST'] = 9,
    ['BRD'] = 10,
    ['RNG'] = 11,
    ['SAM'] = 12,
    ['NIN'] = 13,
    ['DRG'] = 14,
    ['SMN'] = 15,
    ['BLU'] = 16,
    ['COR'] = 17,
    ['PUP'] = 18,
    ['DNC'] = 19,
    ['SCH'] = 20,
    ['GEO'] = 21,
    ['RUN'] = 22,
};

local jobIdToCode = {};
for code, id in pairs(jobCodeToId) do
    jobIdToCode[id] = code;
end

local moogleNames = {
    ['Moogle'] = true,
    ['Nomad Moogle'] = true,
    ['Green Thumb Moogle'] = true,
    ['Pilgrim Moogle'] = true,
};

local baseTempJobCodes = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF' };
local queuedActions = {};
local sequenceActive = false;

local function GetNow()
    return os.clock();
end

local function CleanName(name)
    return tostring(name or ''):gsub('\170', '');
end

local function IsMogHouseMoogleName(name)
    return CleanName(name) == 'Moogle';
end

local function IsNomadMoogleName(name)
    return CleanName(name) == 'Nomad Moogle';
end

local function GetCurrentZoneId()
    local zoneId = nil;

    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    return tonumber(zoneId) or 0;
end

local function IsRuLudeGardens()
    return GetCurrentZoneId() == 243;
end

local function GetJobCode(jobId)
    return jobIdToCode[tonumber(jobId) or 0];
end

local function NormalizeJobCode(job)
    local text = tostring(job or ''):upper():gsub('[^A-Z]', '');
    return (text ~= '') and text or nil;
end

local function SendOutgoingPacket(id, packedData)
    if (packedData == nil) then
        return false;
    end

    local ok, err = pcall(function()
        AshitaCore:GetPacketManager():AddOutgoingPacket(id, packedData);
    end);

    if (ok ~= true) then
        log.Warn('Job change packet send failed id=0x' .. string.format('%03X', tonumber(id) or 0) .. ' err=' .. tostring(err));
        return false;
    end

    return true;
end

local function QueueAction(delaySeconds, action)
    queuedActions[#queuedActions + 1] = {
        at = GetNow() + math.max(0, tonumber(delaySeconds) or 0),
        action = action,
    };
end

local function ClearQueue()
    queuedActions = {};
    sequenceActive = false;
end

local function FindNearbyJobChangeNpc()
    for index = 0, 2303 do
        local ent = GetEntity(index);
        local name = CleanName(ent ~= nil and ent.Name or '');
        local distance = tonumber(ent ~= nil and ent.Distance or nil);

        if (name ~= '' and moogleNames[name] == true and distance ~= nil and distance <= 36) then
            local serverId = nil;
            pcall(function()
                serverId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(index);
            end);

            return {
                index = index,
                serverId = tonumber(serverId) or 0,
                name = name,
                distance = math.sqrt(math.max(0, distance)),
            };
        end
    end

    return nil;
end

local function BuildJobPacket(jobId, isMain)
    return struct.pack(
        'bbbbbbbb',
        0x00,
        0x05,
        0x00,
        0x00,
        isMain == true and jobId or 0x00,
        isMain == true and 0x00 or jobId,
        0x00,
        0x00
    ):totable();
end

local function BuildNpcPokePacket(serverId, targetIndex)
    return struct.pack(
        'bbbbihhhhfff',
        0x1A,
        0x07,
        0x00,
        0x00,
        tonumber(serverId) or 0,
        tonumber(targetIndex) or 0,
        0x00,
        0x00,
        0x00,
        0.0,
        0.0,
        0.0
    ):totable();
end

local function FindTempJobId(currentMain, currentSub, targetMain, targetSub)
    for _, code in ipairs(baseTempJobCodes) do
        if (code ~= currentMain and code ~= currentSub and code ~= targetMain and code ~= targetSub) then
            return jobCodeToId[code];
        end
    end

    return nil;
end

local function BuildChangePlan(targetMainCode, targetSubCode)
    local currentMainCode = GetJobCode(entities.GetPlayerMainJobId());
    local currentSubCode = GetJobCode(entities.GetPlayerSubJobId());
    local mainId = targetMainCode ~= nil and jobCodeToId[targetMainCode] or nil;
    local subId = targetSubCode ~= nil and jobCodeToId[targetSubCode] or nil;
    local tempId = nil;
    local plan = {};

    if (targetMainCode ~= nil and targetMainCode == currentMainCode) then
        mainId = nil;
    end

    if (targetSubCode ~= nil and targetSubCode == currentSubCode) then
        subId = nil;
    end

    if (mainId == nil and subId == nil) then
        return nil, 'No change required.';
    end

    if (targetMainCode ~= nil and targetSubCode ~= nil and targetMainCode == targetSubCode) then
        return nil, 'Main and sub job cannot be the same.';
    end

    local function appendChange(jobId, isMain, isConflict)
        plan[#plan + 1] = {
            jobId = jobId,
            isMain = isMain == true,
            isConflict = isConflict == true,
        };
    end

    local function ensureTempId()
        if (tempId == nil) then
            tempId = FindTempJobId(currentMainCode, currentSubCode, targetMainCode, targetSubCode);
        end
        return tempId;
    end

    if (mainId ~= nil and targetMainCode == currentSubCode) then
        if (subId ~= nil and targetSubCode == currentMainCode) then
            appendChange(ensureTempId(), false, true);
            appendChange(mainId, true, false);
            appendChange(subId, false, false);
        else
            if (subId ~= nil) then
                appendChange(subId, false, false);
            else
                appendChange(ensureTempId(), false, true);
            end
            appendChange(mainId, true, false);
        end
    elseif (subId ~= nil and targetSubCode == currentMainCode) then
        if (mainId ~= nil) then
            appendChange(mainId, true, false);
        else
            appendChange(ensureTempId(), true, true);
        end
        appendChange(subId, false, false);
    else
        if (mainId ~= nil) then
            appendChange(mainId, true, false);
        end

        if (subId ~= nil) then
            appendChange(subId, false, false);
        end
    end

    for _, step in ipairs(plan) do
        if (tonumber(step.jobId) == nil or tonumber(step.jobId) <= 0) then
            return nil, 'Could not find a valid temporary job to resolve the change.';
        end
    end

    return plan;
end

local function StartPlan(plan)
    local npc = FindNearbyJobChangeNpc();
    local delay = 0.0;

    if (npc == nil) then
        return false, 'Not close enough to a job-change Moogle.';
    end

    ClearQueue();

    if (npc.name == 'Nomad Moogle' or npc.name == 'Pilgrim Moogle') then
        QueueAction(delay, {
            kind = 'poke',
            serverId = npc.serverId,
            targetIndex = npc.index,
            npcName = npc.name,
        });
        delay = delay + 1.0;
    end

    for _, step in ipairs(plan) do
        QueueAction(delay, {
            kind = 'job',
            jobId = step.jobId,
            isMain = step.isMain == true,
            isConflict = step.isConflict == true,
        });
        delay = delay + 0.6;
    end

    sequenceActive = (#queuedActions > 0);
    log.Info('Queued job change via ' .. tostring(npc.name) .. ' at ' .. string.format('%.1f', tonumber(npc.distance) or 0) .. ' yalms.');
    return true;
end

function jobChange.ChangeJobs(targetMainCode, targetSubCode)
    targetMainCode = NormalizeJobCode(targetMainCode);
    targetSubCode = NormalizeJobCode(targetSubCode);

    if (targetMainCode ~= nil and jobCodeToId[targetMainCode] == nil) then
        return false, 'Unknown main job: ' .. tostring(targetMainCode);
    end

    if (targetSubCode ~= nil and jobCodeToId[targetSubCode] == nil) then
        return false, 'Unknown sub job: ' .. tostring(targetSubCode);
    end

    local plan, err = BuildChangePlan(targetMainCode, targetSubCode);
    if (plan == nil) then
        return false, err;
    end

    return StartPlan(plan);
end

function jobChange.IsJobChangeNpcName(name)
    return moogleNames[CleanName(name)] == true;
end

function jobChange.CanUseTarget(targetName, targetIndex)
    local cleanName = CleanName(targetName);
    local isValidTarget = false;

    if (entities.IsMogHouseObjectSuppressionArea() == true and IsMogHouseMoogleName(cleanName) == true) then
        isValidTarget = true;
    elseif (IsNomadMoogleName(cleanName) == true and IsRuLudeGardens() ~= true) then
        isValidTarget = true;
    end

    if (isValidTarget ~= true) then
        return false;
    end

    local ent = GetEntity(tonumber(targetIndex) or -1);
    local distance = tonumber(ent ~= nil and ent.Distance or nil);
    return distance ~= nil and distance <= 36;
end

function jobChange.Update()
    if (#queuedActions == 0) then
        sequenceActive = false;
        return;
    end

    local now = GetNow();
    local nextAction = queuedActions[1];

    if (nextAction == nil or now < (tonumber(nextAction.at) or 0)) then
        return;
    end

    table.remove(queuedActions, 1);
    local action = nextAction.action or {};

    if (action.kind == 'poke') then
        local ok = SendOutgoingPacket(0x01A, BuildNpcPokePacket(action.serverId, action.targetIndex));
        if (ok == true) then
            log.Info('Poked ' .. tostring(action.npcName or 'Moogle') .. ' for job change.');
        end
    elseif (action.kind == 'job') then
        local packet = BuildJobPacket(action.jobId, action.isMain == true);
        local ok = SendOutgoingPacket(0x100, packet);
        local jobCode = GetJobCode(action.jobId) or tostring(action.jobId);

        if (ok == true) then
            if (action.isConflict == true) then
                log.Info('Resolving conflict: changing ' .. (action.isMain == true and 'main' or 'sub') .. ' job to ' .. tostring(jobCode) .. '.');
            else
                log.Info('Changing ' .. (action.isMain == true and 'main' or 'sub') .. ' job to ' .. tostring(jobCode) .. '.');
            end
        end
    end

    if (#queuedActions == 0) then
        sequenceActive = false;
    end
end

function jobChange.GetStatusText()
    return 'Job change active=' .. tostring(sequenceActive == true) .. ' queued=' .. tostring(#queuedActions);
end

function jobChange.Cancel()
    ClearQueue();
end

return jobChange;
