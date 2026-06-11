local state = require('core.state');
local entities = require('core.entities');

local profileAutoSwitch = {};

local jobCodes = {
    [1] = 'WAR',
    [2] = 'MNK',
    [3] = 'WHM',
    [4] = 'BLM',
    [5] = 'RDM',
    [6] = 'THF',
    [7] = 'PLD',
    [8] = 'DRK',
    [9] = 'BST',
    [10] = 'BRD',
    [11] = 'RNG',
    [12] = 'SAM',
    [13] = 'NIN',
    [14] = 'DRG',
    [15] = 'SMN',
    [16] = 'BLU',
    [17] = 'COR',
    [18] = 'PUP',
    [19] = 'DNC',
    [20] = 'SCH',
    [21] = 'GEO',
    [22] = 'RUN',
};

local lastMainJob = nil;
local lastSubJob = nil;

local function GetJobCode(jobId)
    jobId = tonumber(jobId) or 0;

    if (jobId <= 0) then
        return 'Any';
    end

    return jobCodes[jobId] or 'Any';
end

local function Matches(assignment, mainJob, subJob)
    if (type(assignment) ~= 'table' or assignment.enabled ~= true) then
        return nil;
    end

    local assignedMain = tostring(assignment.mainJob or '');
    local assignedSub = tostring(assignment.subJob or 'Any');

    if (assignedMain ~= mainJob) then
        return nil;
    end

    if (assignedSub == subJob) then
        return 2;
    end

    if (assignedSub == 'Any') then
        return 1;
    end

    return nil;
end

function profileAutoSwitch.Reset()
    lastMainJob = nil;
    lastSubJob = nil;
end

function profileAutoSwitch.Update()
    local mainJob = GetJobCode(entities.GetPlayerMainJobId());
    local subJob = GetJobCode(entities.GetPlayerSubJobId());

    if (mainJob == 'Any') then
        return;
    end

    if (mainJob == lastMainJob and subJob == lastSubJob) then
        return;
    end

    lastMainJob = mainJob;
    lastSubJob = subJob;

    local manifest = state.GetProfileManifest();
    local bestProfile = nil;
    local bestScore = 0;

    for profileName in pairs(manifest.profiles or {}) do
        local assignment = state.GetProfileAssignment(profileName);
        local score = Matches(assignment, mainJob, subJob);

        if (score ~= nil and score > bestScore) then
            bestProfile = profileName;
            bestScore = score;
        end
    end

    if (bestProfile ~= nil and tostring(bestProfile) ~= tostring(state.GetActiveProfileName())) then
        state.SetActiveProfile(bestProfile);
    end
end

return profileAutoSwitch;
