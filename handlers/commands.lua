local state = require('core.state');
local log = require('core.log');
local bit = require('bit');
local occlusion = require('core.occlusion');
local canvasDefaults = require('config.canvas');
local canvasTexture = require('core.canvas_texture');
local entities = require('core.entities');
local worldMarkerProbe = require('core.world_marker_probe');
local mouseControls = require('core.mouse_controls');
local targeting = require('core.targeting');
local engagedEnemies = require('core.engaged_enemies');
local enemyPlate = require('modules.plates.enemy');
local overlaySuppression = require('core.overlay_suppression');
local nativeTargetArrow = require('core.native_target_arrow');
local targetOverlay = require('modules.target_overlay');
local targetModuleMarker = require('core.target_module_marker');
local modules = require('modules.init');
local perfMeter = require('core.perf_meter');
local lagTest = require('core.lag_test');
local diagnostics = require('core.diagnostics');
local petState = require('core.pet_state');
local abilityRecast = require('libs.abilityrecast');
local enemyCasts = require('core.enemy_casts');
local targetActionRange = require('core.target_action_range');
local aoeNameHighlight = require('core.aoe_name_highlight');
local adaptivePerformance = require('core.adaptive_performance');
local cursorOverlay = require('core.cursor_overlay');
local petPlate = require('modules.plates.pet');
local mogJobDebug = require('core.mog_job_debug');
local luopanStatuses = require('core.luopan_statuses');
local jobChange = require('core.job_change');
local globalDefaults = require('config.global');
local jobDefaults = require('config.widgets.job');
local levelDefaults = require('config.widgets.level');
local buffsDefaults = require('config.widgets.buffs');
local debuffsDefaults = require('config.widgets.debuffs');
local playerStatuses = require('core.player_statuses');
local partyStatuses = require('core.party_statuses');
local enemyStatuses = require('core.enemy_statuses');
local npcObjectInfo = require('core.npc_object_info');
local typeLineDefaults = require('config.widgets.type_line');

local commands = {};
local visDebugCaptures = {};
local npcCapturePath = 'C:\\Users\\Lila\\Documents\\ffxi Addon Work\\WORK\\missing_npcs.txt';
local staffCapturePath = 'C:\\Users\\Lila\\Documents\\ffxi Addon Work\\WORK\\staff_players.txt';

local function HasFlag(value, flag)
    return bit.band(tonumber(value) or 0, flag) ~= 0;
end

local function DebugFlagList(value, flags)
    local parts = {};

    value = tonumber(value) or 0;

    for _, flag in ipairs(flags) do
        if (HasFlag(value, flag) == true) then
            parts[#parts + 1] = string.format('0x%X', flag);
        end
    end

    if (#parts == 0) then
        return '-';
    end

    return table.concat(parts, ',');
end

-- ============================================================
-- Parsing
-- ============================================================

local function SplitCommand(command)
    local args = {};

    for part in tostring(command or ''):gmatch('%S+') do
        table.insert(args, part);
    end

    return args;
end

local function CommandSafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function FormatDebugNumber(value)
    local number = tonumber(value);

    if (number == nil) then
        return tostring(value);
    end

    return string.format('%.4f', number);
end

local function ParseDebugList(text)
    local values = {};

    for key, value in tostring(text or ''):gmatch('([^=,]+)=([^,]+)') do
        values[tostring(key)] = tonumber(value) or tostring(value);
    end

    return values;
end

local function AddChangedField(parts, label, a, b)
    if (a == nil and b == nil) then
        return;
    end

    if (tostring(a) == tostring(b)) then
        return;
    end

    parts[#parts + 1] = label .. ':' .. FormatDebugNumber(a) .. '>' .. FormatDebugNumber(b);
end

local function BuildListDiff(prefix, aText, bText)
    local a = ParseDebugList(aText);
    local b = ParseDebugList(bText);
    local keys = {};
    local seen = {};

    for key, _ in pairs(a) do
        if (seen[key] ~= true) then
            keys[#keys + 1] = key;
            seen[key] = true;
        end
    end

    for key, _ in pairs(b) do
        if (seen[key] ~= true) then
            keys[#keys + 1] = key;
            seen[key] = true;
        end
    end

    table.sort(keys, function(left, right)
        local leftNumber = tonumber(left, 16);
        local rightNumber = tonumber(right, 16);

        if (leftNumber ~= nil and rightNumber ~= nil) then
            return leftNumber < rightNumber;
        end

        return tostring(left) < tostring(right);
    end);

    local parts = {};

    for _, key in ipairs(keys) do
        AddChangedField(parts, prefix .. key, a[key], b[key]);
    end

    return parts;
end

local function BuildVisibilityDiff(a, b)
    local parts = {};

    for _, field in ipairs({
        'status', 'hpPercent', 'type', 'spawnFlags', 'renderFlags0', 'renderFlags1',
        'boneCount', 'boneSpanZ', 'boneSpanY',
        'objectPointer',
    }) do
        AddChangedField(parts, field, a[field], b[field]);
    end

    for _, boneName in ipairs({ 'bone2', 'bone12' }) do
        local boneA = a[boneName] or {};
        local boneB = b[boneName] or {};
        local relZA = (boneA.worldZ ~= nil and a.baseZ ~= nil) and (boneA.worldZ - a.baseZ) or nil;
        local relZB = (boneB.worldZ ~= nil and b.baseZ ~= nil) and (boneB.worldZ - b.baseZ) or nil;

        AddChangedField(parts, boneName .. '.relZ', relZA, relZB);
    end

    for _, value in ipairs(BuildListDiff('af.', a.actorScalars, b.actorScalars)) do
        parts[#parts + 1] = value;
    end

    for _, value in ipairs(BuildListDiff('ai.', a.actorInts, b.actorInts)) do
        parts[#parts + 1] = value;
    end

    for _, value in ipairs(BuildListDiff('of.', a.objectScalars, b.objectScalars)) do
        parts[#parts + 1] = value;
    end

    for _, value in ipairs(BuildListDiff('oi.', a.objectInts, b.objectInts)) do
        parts[#parts + 1] = value;
    end

    return parts;
end

local function ReadTrustProbeStatusIds(memberPtr)
    local ids = {};
    local empty = false;

    if (memberPtr == nil or memberPtr == 0) then
        return ids;
    end

    for buffIndex = 0, 31 do
        if (empty == true) then
            break;
        end

        local highBits = CommandSafeCall(0, function()
            return ashita.memory.read_uint8(memberPtr + 8 + math.floor(buffIndex / 4));
        end);
        local shift = math.fmod(buffIndex, 4) * 2;
        highBits = bit.lshift(bit.band(bit.rshift(highBits, shift), 0x03), 8);

        local lowBits = CommandSafeCall(0, function()
            return ashita.memory.read_uint8(memberPtr + 16 + buffIndex);
        end);
        local statusId = highBits + lowBits;

        if (statusId == 255) then
            empty = true;
        elseif (statusId > 0) then
            ids[#ids + 1] = tostring(statusId);
        end
    end

    return ids;
end

local function GetTrustProbePartyStatusPointer()
    local pointerAddress = CommandSafeCall(0, function()
        return AshitaCore:GetPointerManager():Get('party.statusicons');
    end);

    pointerAddress = tonumber(pointerAddress) or 0;

    if (pointerAddress == 0) then
        return 0;
    end

    return tonumber(CommandSafeCall(0, function()
        return ashita.memory.read_uint32(pointerAddress);
    end)) or 0;
end

local function BuildTrustProbeMembers(party, entityManager)
    local members = {};

    for slot = 0, 17 do
        local active = CommandSafeCall(0, function() return party:GetMemberIsActive(slot); end);
        local targetIndex = CommandSafeCall(0, function() return party:GetMemberTargetIndex(slot); end);
        local serverId = CommandSafeCall(0, function() return party:GetMemberServerId(slot); end);
        local memberName = CommandSafeCall('', function() return party:GetMemberName(slot); end);
        local entityName = '';
        local entityStatus = nil;

        targetIndex = tonumber(targetIndex) or 0;
        serverId = tonumber(serverId) or 0;

        if (entityManager ~= nil and targetIndex > 0) then
            entityName = CommandSafeCall('', function() return entityManager:GetName(targetIndex); end);
            entityStatus = CommandSafeCall(nil, function() return entityManager:GetStatus(targetIndex); end);
        end

        if (tonumber(active) == 1 or targetIndex > 0 or serverId > 0) then
            members[#members + 1] = {
                slot = slot,
                active = active,
                targetIndex = targetIndex,
                serverId = serverId,
                memberName = memberName,
                entityName = entityName,
                entityStatus = entityStatus,
            };
        end
    end

    return members;
end

local function LogTrustBuffProbe(scanMode)
    local party = CommandSafeCall(nil, function()
        return AshitaCore:GetMemoryManager():GetParty();
    end);
    local entityManager = CommandSafeCall(nil, function()
        return AshitaCore:GetMemoryManager():GetEntity();
    end);
    local statusPointer = GetTrustProbePartyStatusPointer();

    log.Info('Trust buff probe statusPtr=0x' .. string.format('%X', tonumber(statusPointer) or 0));

    if (party == nil) then
        log.Warn('Trust buff probe failed: party manager unavailable.');
        return;
    end

    local members = BuildTrustProbeMembers(party, entityManager);

    if (scanMode == true and statusPointer ~= 0) then
        local wanted = {};

        for _, member in ipairs(members) do
            if ((tonumber(member.serverId) or 0) > 0) then
                wanted[tonumber(member.serverId)] = member;
            end
        end

        local found = 0;
        for offset = 0, 0x900, 4 do
            local value = CommandSafeCall(0, function()
                return ashita.memory.read_uint32(statusPointer + offset);
            end);
            local member = wanted[tonumber(value) or 0];

            if (member ~= nil) then
                found = found + 1;
                local rowPtr = statusPointer + offset;
                local ids = ReadTrustProbeStatusIds(rowPtr);

                log.Info(
                    'Trust buff scan match slot=' .. tostring(member.slot) ..
                    ' name=' .. tostring(member.memberName) ..
                    ' server=' .. tostring(member.serverId) ..
                    ' offset=0x' .. string.format('%X', offset) ..
                    ' rowPtr=0x' .. string.format('%X', rowPtr) ..
                    ' ids=' .. (#ids > 0 and table.concat(ids, '/') or 'none')
                );
            end
        end

        if (found == 0) then
            log.Info('Trust buff scan found no active party/trust server ids near party.statusicons.');
        end

        return;
    end

    for _, member in ipairs(members) do
        local memberPtr = (statusPointer ~= 0) and (statusPointer + (0x30 * member.slot)) or 0;
        local rawServerId = CommandSafeCall(0, function()
            return ashita.memory.read_uint32(memberPtr);
        end);
        local ids = {};

        if ((tonumber(rawServerId) or 0) == (tonumber(member.serverId) or -1)) then
            ids = ReadTrustProbeStatusIds(memberPtr);
        end

        log.Info(
            'Trust buff probe slot=' .. tostring(member.slot) ..
            ' active=' .. tostring(member.active) ..
            ' partyName=' .. tostring(member.memberName) ..
            ' entityName=' .. tostring(member.entityName) ..
            ' index=' .. tostring(member.targetIndex) ..
            ' server=' .. tostring(member.serverId) ..
            ' rawServer=' .. tostring(rawServerId) ..
            ' status=' .. tostring(member.entityStatus) ..
            ' ids=' .. (#ids > 0 and table.concat(ids, '/') or 'none')
        );
    end
end

local function FindAlTaieuFishIndex()
    local zoneId = nil;

    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    if (tonumber(zoneId) ~= 33) then
        return nil;
    end

    local entityManager = AshitaCore:GetMemoryManager():GetEntity();
    local bestIndex = nil;
    local bestDistance = nil;

    if (entityManager == nil) then
        return nil;
    end

    for index = 0, 2303 do
        local ent = GetEntity(index);
        local name = tostring(ent ~= nil and ent.Name or ''):gsub('\170', ''):lower();

        if (
            (name == "ul'hpemde" or name == "ul'phuabo") and
            ent.HPPercent ~= nil and
            ent.HPPercent > 0
        ) then
            local distance = tonumber(ent.Distance);

            if (bestIndex == nil or (distance ~= nil and (bestDistance == nil or distance < bestDistance))) then
                bestIndex = index;
                bestDistance = distance;
            end
        end
    end

    return bestIndex;
end

local function ResolveVisDebugTarget(args, firstIndex)
    local value = tostring(args[firstIndex] or ''):lower();

    if (value == 'pet') then
        return entities.GetOwnPetTargetIndex();
    end

    if (value == 'fish' or value == 'sea') then
        return FindAlTaieuFishIndex();
    end

    if (tonumber(args[firstIndex]) ~= nil) then
        return tonumber(args[firstIndex]);
    end

    return targeting.GetCurrentTargetIndex() or entities.GetOwnPetTargetIndex();
end

local function GetAddonRoot()
    local ok, path = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and path ~= nil) then
        return tostring(path);
    end

    return '.\\';
end

local function GetCurrentZoneName()
    local zoneId = nil;

    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    if (zoneId ~= nil and AshitaCore ~= nil and AshitaCore.GetResourceManager ~= nil) then
        local ok, zoneName = pcall(function()
            return AshitaCore:GetResourceManager():GetString('zones.names', zoneId);
        end);

        if (ok == true and zoneName ~= nil and tostring(zoneName) ~= '' and tostring(zoneName) ~= 'nil') then
            return tostring(zoneName);
        end
    end

    if (zoneId ~= nil) then
        return 'Zone ' .. tostring(zoneId);
    end

    return 'Unknown Zone';
end

local function GetCurrentTargetName()
    local targetIndex = targeting.GetCurrentTargetIndex() or targeting.GetCurrentSubTargetIndex();

    if (targetIndex == nil or targetIndex == 0) then
        return nil;
    end

    local ok, name = pcall(function()
        return AshitaCore:GetMemoryManager():GetEntity():GetName(targetIndex);
    end);

    if (ok ~= true or name == nil or tostring(name) == '' or tostring(name) == 'nil') then
        return nil;
    end

    return tostring(name);
end

local function AppendMissingNpc()
    local name = GetCurrentTargetName();

    if (name == nil) then
        log.Warn('NPC capture failed: target an NPC first.');
        return;
    end

    local zoneName = GetCurrentZoneName();
    local line = name .. ' | ' .. zoneName;
    local path = npcCapturePath;
    local file = io.open(path, 'a');

    if (file == nil) then
        log.Warn('NPC capture failed: could not open ' .. path);
        return;
    end

    file:write(line);
    file:write('\n');
    file:close();

    log.Info('NPC capture added: ' .. line);
end

local function FormatHex(value)
    return '0x' .. string.format('%X', tonumber(value or 0) or 0);
end

local function BuildRenderFlagText(debug)
    local parts = {};
    local flags = debug ~= nil and debug.renderFlags or nil;

    for flagIndex = 0, 7 do
        local value = flags ~= nil and flags[flagIndex] or debug ~= nil and debug['renderFlags' .. tostring(flagIndex)] or 0;
        parts[#parts + 1] = 'render' .. tostring(flagIndex) .. '=' .. FormatHex(value);
    end

    return table.concat(parts, ' | ');
end

local function AppendStaffPlayer(label)
    local targetIndex = targeting.GetCurrentTargetIndex() or targeting.GetCurrentSubTargetIndex();

    if (targetIndex == nil or targetIndex == 0) then
        log.Warn('Staff capture failed: target the player first.');
        return;
    end

    local entityManager = AshitaCore:GetMemoryManager():GetEntity();
    local okName, name = pcall(function()
        return entityManager:GetName(targetIndex);
    end);
    local okServer, serverId = pcall(function()
        return entityManager:GetServerId(targetIndex);
    end);
    local okType, entityType = pcall(function()
        return entityManager:GetType(targetIndex);
    end);

    name = (okName == true and name ~= nil) and tostring(name) or '';
    serverId = (okServer == true) and tonumber(serverId) or nil;

    if (name == '' or name == 'nil' or serverId == nil or serverId == 0) then
        log.Warn('Staff capture failed: no valid target name/serverId.');
        return;
    end

    local zoneName = GetCurrentZoneName();
    local debug = entities.GetEntityDebugInfo(targetIndex, targeting.GetSettings().enemyPlateRange);
    local captureLabel = tostring(label or ''):lower();
    local labelText = (captureLabel ~= '' and captureLabel ~= 'nil') and (' | label=' .. captureLabel) or '';
    local line = name ..
        labelText ..
        ' | serverId=' .. tostring(serverId) ..
        ' | index=' .. tostring(targetIndex) ..
        ' | type=' .. tostring(entityType) ..
        ' | status=' .. tostring(debug ~= nil and debug.status or nil) ..
        ' | spawn=' .. FormatHex(debug ~= nil and debug.spawnFlags or 0) ..
        ' | ' .. BuildRenderFlagText(debug) ..
        ' | distance=' .. tostring(debug ~= nil and debug.distance or nil) ..
        ' | zone=' .. zoneName;
    local path = staffCapturePath;
    local file = io.open(path, 'a');

    if (file == nil) then
        log.Warn('Staff capture failed: could not open ' .. path);
        return;
    end

    file:write(line);
    file:write('\n');
    file:close();

    log.Info('Staff capture added: ' .. line);
end

-- ============================================================
-- Command handler
-- ============================================================

function commands.Handle(e)
    local args = SplitCommand(e.command);
    local command = tostring(args[1] or ''):lower();

    if (command == '/help' or command == '/h') then
        engagedEnemies.MarkCallForHelp(targeting.GetCurrentTargetIndex());
        return;
    end

    if (command ~= '/libraplates' and command ~= '/lp') then
        return;
    end

    e.blocked = true;

    local subcommand = tostring(args[2] or 'status'):lower();

    if (subcommand == 'reload') then
        pcall(function()
            AshitaCore:GetChatManager():QueueCommand(1, '/addon reload LibraPlates');
        end);
        return;
    end

    if (subcommand == 'npc' or subcommand == 'npcadd') then
        AppendMissingNpc();
        return;
    end

    if (subcommand == 'pccap' or subcommand == 'staffcap' or subcommand == 'gmid') then
        AppendStaffPlayer(args[3]);
        return;
    end

    if (subcommand == 'world') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            state.SetWorldEnabled(true);
        elseif (value == 'off') then
            state.SetWorldEnabled(false);
        else
            state.SetWorldEnabled(not state.GetWorldEnabled());
        end

        log.Info('World plates enabled=' .. tostring(state.GetWorldEnabled()));
        return;
    end

    if (subcommand == 'worlddepth') then
        if (canvasDefaults.worldDepth == nil) then
            canvasDefaults.worldDepth = {};
        end

        canvasDefaults.worldDepth.enabled = false;
        log.Warn('World depth plate is disabled; the experimental beginscene path changes scene lighting.');
        return;
    end

    if (subcommand == 'bridge' or subcommand == 'worldmarker') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            worldMarkerProbe.SetEnabled(true);
            worldMarkerProbe.SetReplacePlates(true);
        elseif (value == 'off') then
            worldMarkerProbe.SetEnabled(false);
        elseif (value == 'status' or value == '') then
            log.Info(
                worldMarkerProbe.GetStatusText() ..
                ' target=' .. tostring(targeting.GetCurrentTargetIndex()) ..
                ' subtarget=' .. tostring(targeting.GetCurrentSubTargetIndex()) ..
                ' locked=' .. tostring(targeting.GetIsTargetLockedOn()) ..
                ' ' .. targeting.GetDebugStatus()
            );
            return;
        else
            worldMarkerProbe.SetEnabled(not worldMarkerProbe.GetEnabled());
            worldMarkerProbe.SetReplacePlates(true);
        end

        log.Info('World marker bridge enabled=' .. tostring(worldMarkerProbe.GetEnabled()));
        return;
    end

    if (subcommand == 'isolate' or subcommand == 'perfiso') then
        local name = tostring(args[3] or 'status'):lower();
        local value = tostring(args[4] or 'status'):lower();

        if (name == 'status' or name == '') then
            log.Info('Perf isolate disabled subsystems: ' .. modules.GetPerfIsolationStatus());
            return;
        end

        if (value == 'on' or value == 'disable' or value == 'disabled') then
            if (modules.SetPerfIsolation(name, true) ~= true) then
                log.Warn('Usage: /lp isolate targeting|native|mouse|overlays|all on|off|status');
                return;
            end
        elseif (value == 'off' or value == 'enable' or value == 'enabled') then
            if (modules.SetPerfIsolation(name, false) ~= true) then
                log.Warn('Usage: /lp isolate targeting|native|mouse|overlays|all on|off|status');
                return;
            end
        elseif (value == 'toggle' or value == '') then
            if (modules.SetPerfIsolation(name, modules.GetPerfIsolation(name) ~= true) ~= true) then
                log.Warn('Usage: /lp isolate targeting|native|mouse|overlays|all on|off|status');
                return;
            end
        elseif (value ~= 'status') then
            log.Warn('Usage: /lp isolate targeting|native|mouse|overlays|all on|off|status');
            return;
        end

        log.Info('Perf isolate disabled subsystems: ' .. modules.GetPerfIsolationStatus());
        return;
    end

    if (subcommand == 'clickdebug') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            worldMarkerProbe.SetClickDebug(true);
        elseif (value == 'off') then
            worldMarkerProbe.SetClickDebug(false);
        else
            worldMarkerProbe.SetClickDebug(not worldMarkerProbe.GetClickDebug());
        end

        log.Info('Click debug path enabled=' .. tostring(worldMarkerProbe.GetClickDebug()) .. ' visible=' .. tostring(worldMarkerProbe.GetClickBordersVisible()));
        return;
    end

    if (subcommand == 'canvasdebug' or subcommand == 'canvascenter') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            worldMarkerProbe.SetCanvasCenterDebug(true);
        elseif (value == 'off') then
            worldMarkerProbe.SetCanvasCenterDebug(false);
        else
            worldMarkerProbe.SetCanvasCenterDebug(not worldMarkerProbe.GetCanvasCenterDebug());
        end

        log.Info('Canvas center debug=' .. tostring(worldMarkerProbe.GetCanvasCenterDebug()));
        return;
    end

    if (subcommand == 'petpos' or subcommand == 'petposition') then
        local action = tostring(args[3] or 'status'):lower();
        local value = tonumber(args[4]);

        if (action == 'bone' and value ~= nil) then
            petPlate.SetAnchorBone(value);
        elseif ((action == 'offset' or action == 'offsety' or action == 'y') and value ~= nil) then
            petPlate.SetWorldOffsetY(value);
        elseif (action == 'reset') then
            petPlate.ResetPositionDebug();
        elseif (action ~= 'status' and action ~= '') then
            log.Warn('Usage: /lp petpos bone <0-32> | offset <number> | reset | status');
            return;
        end

        log.Info(petPlate.GetPositionDebugText());
        return;
    end

    if (subcommand == 'pettargeting' or subcommand == 'petclick') then
        local value = tostring(args[3] or 'status'):lower();
        local settings = targeting.GetSettings();

        if (value == 'on') then
            settings.enablePetPlateTargeting = true;
        elseif (value == 'off') then
            settings.enablePetPlateTargeting = false;
        elseif (value ~= 'status' and value ~= '') then
            settings.enablePetPlateTargeting = settings.enablePetPlateTargeting == false;
        end

        state.Save();
        log.Info('Pet plate targeting enabled=' .. tostring(settings.enablePetPlateTargeting ~= false));
        return;
    end

    if (subcommand == 'enemypos' or subcommand == 'enemyposition') then
        local action = tostring(args[3] or 'status'):lower();
        local value = tonumber(args[4]);

        if (action == 'bone' and value ~= nil) then
            enemyPlate.SetAnchorBone(value);
        elseif ((action == 'offset' or action == 'offsety' or action == 'y') and value ~= nil) then
            enemyPlate.SetWorldOffsetY(value);
        elseif (action == 'reset') then
            enemyPlate.ResetPositionDebug();
        elseif (action ~= 'status' and action ~= '') then
            log.Warn('Usage: /lp enemypos bone <0-32> | offset <number> | reset | status');
            return;
        end

        log.Info(enemyPlate.GetPositionDebugText());
        return;
    end

    if (subcommand == 'anchor') then
        local action = tostring(args[3] or 'status'):lower();
        local value = tostring(args[4] or ''):lower();

        if (action == 'debug' or action == 'dump') then
            local targetIndex = nil;

            if (value == 'pet') then
                targetIndex = entities.GetOwnPetTargetIndex();
            elseif (tonumber(args[4]) ~= nil) then
                targetIndex = tonumber(args[4]);
            else
                targetIndex = targeting.GetCurrentTargetIndex() or entities.GetOwnPetTargetIndex();
            end

            local debug, err = worldMarkerProbe.GetAnchorDebug(targetIndex, entities.GetEntityManager, entities.GetBone);

            if (debug == nil) then
                log.Warn('Anchor debug failed: ' .. tostring(err) .. ' target=' .. tostring(targetIndex));
                return;
            end

            log.Info(
                'Anchor debug target=' .. tostring(debug.targetIndex) ..
                ' boneScreen=' .. tostring(debug.boneScreenX) .. ',' .. tostring(debug.boneScreenY) .. ',' .. tostring(debug.boneScreenZ) ..
                ' exactOk=' .. tostring(debug.exactOk) ..
                ' exactScreen=' .. tostring(debug.exactScreenX) .. ',' .. tostring(debug.exactScreenY) .. ',' .. tostring(debug.exactScreenZ) ..
                ' delta=' .. tostring(debug.deltaScreenX) .. ',' .. tostring(debug.deltaScreenY) ..
                ' helper=' .. tostring(debug.helperStatus)
            );
            return;
        elseif (action == 'bone' and tonumber(args[4]) ~= nil) then
            worldMarkerProbe.SetAnchorMode('bone');
            worldMarkerProbe.SetAnchorBone(tonumber(args[4]));
        elseif (action == 'bone') then
            worldMarkerProbe.SetAnchorMode('bone');
        elseif (action == 'exact' or action == 'nameplate') then
            worldMarkerProbe.SetAnchorMode('exact');
        elseif (action == 'compare') then
            if (value == 'on') then
                worldMarkerProbe.SetCompareAnchors(true);
            elseif (value == 'off') then
                worldMarkerProbe.SetCompareAnchors(false);
            else
                worldMarkerProbe.SetCompareAnchors(not worldMarkerProbe.GetCompareAnchors());
            end
        elseif (action == 'offset' and tonumber(args[4]) ~= nil) then
            worldMarkerProbe.SetVerticalOffset(tonumber(args[4]));
        elseif ((action == 'nameheight' or action == 'nameoffset') and tonumber(args[4]) ~= nil) then
            worldMarkerProbe.SetNameVerticalOffset(tonumber(args[4]));
        elseif (action ~= 'status' and action ~= '') then
            log.Warn('Usage: /lp anchor bone [0-32] | exact | compare [on/off] | offset <n> | nameheight <n> | debug [pet/index] | status');
            return;
        end

        log.Info(worldMarkerProbe.GetStatusText());
        return;
    end

    if (subcommand == 'visdebug' or subcommand == 'visibilitydebug') then
        local action = tostring(args[3] or ''):lower();

        if (action == 'compare' or action == 'diff') then
            local leftName = tostring(args[4] or 'large'):lower();
            local rightName = tostring(args[5] or 'small'):lower();
            local left = visDebugCaptures[leftName];
            local right = visDebugCaptures[rightName];

            if (left == nil or right == nil) then
                log.Warn('Visibility compare needs saved captures. Use: /lp visdebug save large, /lp visdebug save small, then /lp visdebug compare large small');
                return;
            end

            local diffs = BuildVisibilityDiff(left, right);

            log.Info(
                'Visibility compare ' .. leftName .. '(' .. tostring(left.name) .. '#' .. tostring(left.targetIndex) .. ')' ..
                ' -> ' .. rightName .. '(' .. tostring(right.name) .. '#' .. tostring(right.targetIndex) .. ')' ..
                ' diffs=' .. tostring(#diffs)
            );

            if (#diffs == 0) then
                return;
            end

            local chunk = {};

            for i, diff in ipairs(diffs) do
                chunk[#chunk + 1] = diff;

                if (#chunk >= 12 or i == #diffs) then
                    log.Info('Visibility diff: ' .. table.concat(chunk, ' '));
                    chunk = {};
                end
            end

            return;
        end

        local captureName = nil;
        local targetArgIndex = 3;

        if (action == 'save' or action == 'capture') then
            captureName = tostring(args[4] or ''):lower();

            if (captureName == '') then
                log.Warn('Usage: /lp visdebug save <label> [target/pet/index]');
                return;
            end

            targetArgIndex = 5;
        end

        local targetIndex = ResolveVisDebugTarget(args, targetArgIndex);
        local debug, err = worldMarkerProbe.GetVisibilityDebug(targetIndex, entities.GetEntityManager, entities.GetBone);

        if (debug == nil) then
            log.Warn('Visibility debug failed: ' .. tostring(err) .. ' target=' .. tostring(targetIndex));
            return;
        end

        if (captureName ~= nil) then
            visDebugCaptures[captureName] = debug;
            log.Info('Visibility debug saved ' .. captureName .. '=' .. tostring(debug.name) .. '#' .. tostring(debug.targetIndex));
        end

        local bone2 = debug.bone2 or {};
        local bone12 = debug.bone12 or {};
        local enemyPlate2 = debug.enemyPlate2 or {};
        local cleanDebugName = tostring(debug.name or ''):gsub('\170', ''):lower();
        local fishDebug = tonumber(debug.zoneId) == 33 and (cleanDebugName == "ul'hpemde" or cleanDebugName == "ul'phuabo");
        local fishBelow = fishDebug == true
            and tonumber(enemyPlate2.plateWorldY) ~= nil
            and tonumber(debug.selfZ) ~= nil
            and tonumber(enemyPlate2.plateWorldY) < (tonumber(debug.selfZ) - 1.50);

        log.Info(
            'Visibility debug target=' .. tostring(debug.targetIndex) ..
            ' zone=' .. tostring(debug.zoneId) ..
            ' name=' .. tostring(debug.name) ..
            ' fish=' .. tostring(fishDebug) ..
            ' fishBelow=' .. tostring(fishBelow) ..
            ' status=' .. tostring(debug.status) ..
            ' hp=' .. tostring(debug.hpPercent) ..
            ' type=' .. tostring(debug.type) ..
            ' spawn=0x' .. string.format('%X', tonumber(debug.spawnFlags) or 0) ..
            ' rf0=0x' .. string.format('%X', tonumber(debug.renderFlags0) or 0) ..
            ' rf1=0x' .. string.format('%X', tonumber(debug.renderFlags1) or 0) ..
            ' local=' .. tostring(debug.localX) .. ',' .. tostring(debug.localY) .. ',' .. tostring(debug.localZ) ..
            ' last=' .. tostring(debug.lastX) .. ',' .. tostring(debug.lastY) .. ',' .. tostring(debug.lastZ) ..
            ' b2=' .. tostring(bone2.screenX) .. ',' .. tostring(bone2.screenY) .. ',' .. tostring(bone2.screenZ) .. ',p=' .. tostring(bone2.projected) ..
            ' b12=' .. tostring(bone12.screenX) .. ',' .. tostring(bone12.screenY) .. ',' .. tostring(bone12.screenZ) .. ',p=' .. tostring(bone12.projected) ..
            ' plate2=' .. tostring(enemyPlate2.screenX) .. ',' .. tostring(enemyPlate2.screenY) .. ',' .. tostring(enemyPlate2.screenZ) .. ',p=' .. tostring(enemyPlate2.projected) ..
            ' plateY=' .. tostring(enemyPlate2.plateWorldY) ..
            ' selfZ=' .. tostring(debug.selfZ) ..
            ' viewH=' .. tostring(debug.viewportHeight) ..
            ' bones=' .. tostring(debug.boneCount) ..
            ' z=' .. tostring(debug.boneMinZ) .. '/' .. tostring(debug.boneMaxZ) .. '/' .. tostring(debug.boneSpanZ) ..
            ' y=' .. tostring(debug.boneMinY) .. '/' .. tostring(debug.boneMaxY) .. '/' .. tostring(debug.boneSpanY) ..
            ' baseZ=' .. tostring(debug.baseZ) ..
            ' obj=0x' .. string.format('%X', tonumber(debug.objectPointer) or 0) ..
            ' af=' .. tostring(debug.actorScalars) ..
            ' ai=' .. tostring(debug.actorInts) ..
            ' of=' .. tostring(debug.objectScalars) ..
            ' oi=' .. tostring(debug.objectInts)
        );
        return;
    end

    if (subcommand == 'targetoverlay') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            enemyPlate.SetTargetOverlayEnabled(true);
        elseif (value == 'off') then
            enemyPlate.SetTargetOverlayEnabled(false);
        else
            enemyPlate.SetTargetOverlayEnabled(not enemyPlate.GetTargetOverlayEnabled());
        end

        log.Info('Target overlay enabled=' .. tostring(enemyPlate.GetTargetOverlayEnabled()));
        return;
    end

    if (subcommand == 'nativearrow') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'debugoff') then
            nativeTargetArrow.SetTraceEnabled(false);
            nativeTargetArrow.SetDrawBlockEnabled(false);
            nativeTargetArrow.SetPartyTraceEnabled(false);
            nativeTargetArrow.SetPartyBlockEnabled(false);
            nativeTargetArrow.SetHardHideEveryDrawEnabled(false);
            log.Info('native arrow debug modes disabled');
            return;
        end

        if (value == 'windowstatus') then
            nativeTargetArrow.WriteTargetWindowStatus('manual');
            log.Info('native target windowstatus written file=' .. nativeTargetArrow.GetTraceFilePath());
            return;
        end

        if (value ~= '' and value ~= 'status') then
            log.Warn('Usage: /lp nativearrow status | /lp nativearrow debugoff | /lp nativearrow windowstatus');
            return;
        end

        log.Info(nativeTargetArrow.GetStatusText() .. ' ' .. modules.GetNativeTargetArrowDebugStatus() .. ' ' .. nativeTargetArrow.GetTraceStatusText() .. ' ' .. nativeTargetArrow.GetHardHideEveryDrawStatusText());
        return;
    end

    if (subcommand == 'perf' or subcommand == 'performance') then
        local value = tostring(args[3] or 'status'):lower();

        if (value == 'detail') then
            local detailValue = tostring(args[4] or 'status'):lower();

            if (detailValue == 'on') then
                perfMeter.SetDetailEnabled(true);
            elseif (detailValue == 'off') then
                perfMeter.SetDetailEnabled(false);
            elseif (detailValue ~= 'status' and detailValue ~= '') then
                log.Warn('Usage: /lp perf detail [on|off|status]');
                return;
            end
        elseif (value == 'on') then
            perfMeter.SetOverlayEnabled(true);
        elseif (value == 'off') then
            perfMeter.SetOverlayEnabled(false);
        elseif (value == 'reset') then
            perfMeter.Reset();
            log.Info('Performance meter reset.');
            return;
        elseif (value == 'report') then
            perfMeter.WritePerformanceReport();
            log.Info('Performance report saved.');
            return;
        elseif (value ~= 'status' and value ~= '') then
            log.Warn('Usage: /lp perf [on|off|reset|report|status] | /lp perf detail [on|off|status]');
            return;
        end

        for _, line in ipairs(perfMeter.GetSummaryLines()) do
            log.Info(line);
        end

        local canvasStats = canvasTexture.GetCacheStats();

        if (canvasStats ~= nil) then
            log.Info(
                'Canvas texture cache: ' ..
                tostring(canvasStats.count) .. '/' .. tostring(canvasStats.max) ..
                ' evictions=' .. tostring(canvasStats.evictions)
            );
        end

        return;
    end

    if (subcommand == 'backups') then
        local value = tostring(args[3] or 'prune'):lower();

        if (value ~= 'prune' and value ~= 'clean' and value ~= 'status') then
            log.Warn('Usage: /lp backups status');
            return;
        end

        log.Warn('In-game backup pruning is disabled. Close the game and delete old files from the LibraPlates backups folder manually. Future backups overwrite settings-backup.lua only.');

        return;
    end

    if (subcommand == 'lagtest' or subcommand == 'lagcheck') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'cancel' or value == 'stop') then
            lagTest.Cancel();
        elseif (value == 'status') then
            log.Info(lagTest.GetStatusText());
        elseif (value == 'self') then
            lagTest.Start(tonumber(args[4]), 'self');
        else
            lagTest.Start(tonumber(args[3]));
        end

        return;
    end

    if (subcommand == 'perftest') then
        adaptivePerformance.SetEnabled(true);
        perfMeter.Reset();
        perfMeter.SetDetailEnabled(true);
        perfMeter.SetOverlayEnabled(true);
        log.Info('Perf test ready: fpsobserve=on detail=on overlay=on. After a stutter, run /lp perf status.');
        return;
    end

    if (subcommand == 'lag') then
        local path, phaseName, seconds = diagnostics.StartAuto(tonumber(args[3]) or 15);
        log.Info('Lag diagnostics started. Play normally; I will say when done. file=' .. tostring(path) .. ' phase=' .. tostring(phaseName) .. ' seconds=' .. tostring(seconds));
        return;
    end

    if (subcommand == 'diag' or subcommand == 'diagnostics') then
        local action = tostring(args[3] or 'status'):lower();

        if (action == 'start') then
            local path = diagnostics.Start(args[4] or '');
            log.Info('Diagnostics started file=' .. tostring(path));
            return;
        elseif (action == 'stop') then
            local path = diagnostics.Stop();
            log.Info('Diagnostics stopped file=' .. tostring(path));
            return;
        elseif (action == 'mark') then
            diagnostics.Mark(table.concat(args, ' ', 4));
            log.Info('Diagnostics marked.');
            return;
        elseif (action == 'scenario') then
            local ok, result = diagnostics.ApplyScenario(args[4] or '');

            if (ok == true) then
                log.Info('Diagnostics scenario applied=' .. tostring(result) .. ' file=' .. tostring(diagnostics.GetFilePath()));
            else
                log.Warn('Usage: /lp diag scenario native-off | native-arrow-on | native-party-on | target-off | target-on');
            end

            return;
        elseif (action == 'restore') then
            diagnostics.Restore();
            log.Info('Diagnostics restored original target/native settings.');
            return;
        elseif (action == 'auto') then
            local subaction = tostring(args[4] or 'start'):lower();

            if (subaction == 'stop') then
                local path = diagnostics.StopAuto();
                log.Info('Diagnostics auto stopped file=' .. tostring(path));
                return;
            end

            local path, phaseName, seconds = diagnostics.StartAuto(args[4]);
            log.Info('Diagnostics auto started phase=' .. tostring(phaseName) .. ' seconds=' .. tostring(seconds) .. ' file=' .. tostring(path));
            return;
        elseif (action ~= 'status' and action ~= '') then
            log.Warn('Usage: /lp diag auto [seconds] | /lp diag auto stop | start | stop | mark <text> | scenario <name> | restore | status');
            return;
        end

        log.Info(diagnostics.GetStatusText());
        return;
    end

    if (subcommand == 'engaged') then
        log.Info(engagedEnemies.GetStatusText());
        return;
    end

    if (subcommand == 'claimdebug') then
        local action = tostring(args[3] or 'on'):lower();

        if (action == 'off' or action == 'stop') then
            engagedEnemies.DisableClaimDebug();
        else
            engagedEnemies.EnableClaimDebugForSeconds(tonumber(args[4]) or tonumber(args[3]) or 20);
        end

        return;
    end

    if (subcommand == 'overlaystatus') then
        log.Info(overlaySuppression.GetStatusText());
        return;
    end

    if (subcommand == 'targetdebug') then
        log.Info(targetModuleMarker.GetDebugStatus());
        return;
    end

    if (subcommand == 'doorscan') then
        local range = tonumber(args[3]) or 12;
        local objects = entities.GetNearbyRawObjects(range, 10);

        if (#objects == 0) then
            log.Warn('Door scan found no raw objects in range=' .. tostring(range));
            return;
        end

        log.Info('Door scan range=' .. tostring(range) .. ' objects=' .. tostring(#objects));
        log.Info('Door scan mogHouseObjectSuppression=' .. tostring(entities.IsMogHouseObjectSuppressionArea()));

        for _, object in ipairs(objects) do
            log.Info(
                'Door scan object index=' .. tostring(object.index) ..
                ' name=' .. tostring(object.name) ..
                ' nameLen=' .. tostring(object.nameLen) ..
                ' type=' .. tostring(object.type) ..
                ' status=' .. tostring(object.status) ..
                ' distance=' .. string.format('%.2f', tonumber(object.distance) or 0) ..
                ' spawn=0x' .. string.format('%X', tonumber(object.spawnFlags) or 0) ..
                ' render0=0x' .. string.format('%X', tonumber(object.renderFlags0) or 0) ..
                ' render1=0x' .. string.format('%X', tonumber(object.renderFlags1) or 0) ..
                ' visible=' .. tostring(object.visible) ..
                ' mogFurniture=' .. tostring(object.mogHouseFurniturePlaceholder) ..
                ' statusAllowed=' .. tostring(object.statusAllowed)
            );
        end

        return;
    end

    if (subcommand == 'entitydebug' or subcommand == 'targetcap' or subcommand == 'doorcap') then
        local targetIndex = tonumber(args[3]) or targeting.GetCurrentTargetIndex() or targeting.GetCurrentSubTargetIndex();
        local debug = entities.GetEntityDebugInfo(targetIndex, targeting.GetSettings().enemyPlateRange);

        if (debug == nil) then
            log.Warn('Entity debug failed: no current target. current=' .. tostring(targeting.GetCurrentTargetIndex()) .. ' sub=' .. tostring(targeting.GetCurrentSubTargetIndex()));
            return;
        end

        local rawEntityName = (tonumber(debug.type) == 2 or tonumber(debug.type) == 3) and 'Object' or 'NPC';
        local cleanName = tostring(debug.name or ''):gsub('\170', '');
        local resolvedEntityName, info = npcObjectInfo.ResolveKind(cleanName, rawEntityName);
        local typeLineSettings = state.GetWidgetSettings(resolvedEntityName, 'Idle', 'Type line', typeLineDefaults);
        local render0 = tonumber(debug.renderFlags0) or 0;
        local render1 = tonumber(debug.renderFlags1) or 0;
        local hasNativeSpecialNameMarker = tostring(debug.name or ''):sub(1, 1) == string.char(0xAA);
        local expectedStar = hasNativeSpecialNameMarker == true and HasFlag(render1, 0x800) == true;

        log.Info(
            'Entity debug target=' .. tostring(debug.index) ..
            ' name=' .. tostring(debug.name) ..
            ' type=' .. tostring(debug.type) ..
            ' status=' .. tostring(debug.status) ..
            ' distance=' .. tostring(debug.distance) ..
            ' current=' .. tostring(targeting.GetCurrentTargetIndex()) ..
            ' sub=' .. tostring(targeting.GetCurrentSubTargetIndex()) ..
            ' nameLen=' .. tostring(string.len(tostring(debug.name or ''))) ..
            ' cleanLen=' .. tostring(string.len(cleanName)) ..
            ' spawn=0x' .. string.format('%X', tonumber(debug.spawnFlags) or 0) ..
            ' render0=0x' .. string.format('%X', render0) ..
            ' render1=0x' .. string.format('%X', render1) ..
            ' specialNameBit=' .. tostring(HasFlag(render1, 0x800)) ..
            ' specialNameMarker=' .. tostring(hasNativeSpecialNameMarker) ..
            ' r0hi=' .. tostring(HasFlag(render0, 0x80000000)) ..
            ' r0mid=' .. tostring(HasFlag(render0, 0x40000000)) ..
            ' indexAllowed=' .. tostring(debug.indexAllowed) ..
            ' isMob=' .. tostring(debug.isMob) ..
            ' isParty=' .. tostring(debug.isParty) ..
            ' visible=' .. tostring(debug.visible) ..
            ' visibleSkeleton=' .. tostring(debug.visibleWithSkeleton) ..
            ' mogFurniture=' .. tostring(debug.mogHouseFurniturePlaceholder) ..
            ' mogObjectSuppression=' .. tostring(debug.mogHouseObjectSuppression) ..
            ' settled=' .. tostring(debug.settled) ..
            ' inRange=' .. tostring(debug.inRange) ..
            ' statusAllowed=' .. tostring(debug.statusAllowed) ..
            ' npcScanAllowed=' .. tostring(debug.npcScanAllowed) ..
            ' resolved=' .. tostring(resolvedEntityName) ..
            ' infoSource=' .. tostring(info ~= nil and info.source or nil) ..
            ' infoType=' .. tostring(info ~= nil and info.type or nil) ..
            ' typeLineEnabled=' .. tostring(typeLineSettings ~= nil and typeLineSettings.enabled == true)
        );
        log.Info(
            'Entity icon probe target=' .. tostring(debug.index) ..
            ' name=' .. tostring(cleanName) ..
            ' nativeSpecial=' .. tostring(HasFlag(render1, 0x800)) ..
            ' nativeMarker=' .. tostring(hasNativeSpecialNameMarker) ..
            ' r0Bits=' .. DebugFlagList(render0, { 0x200, 0x2000, 0x400000, 0x800000, 0x40000000, 0x80000000 }) ..
            ' r1Bits=' .. DebugFlagList(render1, { 0x8, 0x40, 0x400, 0x800, 0x8000, 0x2000000 }) ..
            ' expectedStar=' .. tostring(expectedStar)
        );
        return;
    end

    if (subcommand == 'pcdebug') then
        local targetIndex = targeting.GetCurrentTargetIndex();
        local players = entities.GetNearbyPlayers(64.4);
        local found = nil;

        for _, player in ipairs(players) do
            if (tonumber(player.index) == tonumber(targetIndex)) then
                found = player;
                break;
            end
        end

        if (found == nil) then
            log.Warn('PC debug failed: target is not a nearby PC. target=' .. tostring(targetIndex));
            return;
        end

        local layoutStateName = (tonumber(found.slot) ~= nil or tonumber(found.status) == 1) and 'Combat' or 'Idle';
        local jobSettings = state.GetWidgetSettings('PC', layoutStateName, 'Job', jobDefaults);
        local levelSettings = state.GetWidgetSettings('PC', layoutStateName, 'Level', levelDefaults);
        local debug = entities.GetEntityDebugInfo(found.index, targeting.GetSettings().enemyPlateRange);
        local entity = GetEntity(found.index);
        local linkshellColor = tonumber(entity ~= nil and entity.LinkshellColor) or 0;

        log.Info(
            'PC debug target=' .. tostring(found.index) ..
            ' name=' .. tostring(found.name) ..
            ' serverId=' .. tostring(found.serverId) ..
            ' status=' .. tostring(found.status) ..
            ' type=' .. tostring(debug ~= nil and debug.type or nil) ..
            ' spawn=0x' .. string.format('%X', tonumber(debug ~= nil and debug.spawnFlags or 0) or 0) ..
            ' render0=0x' .. string.format('%X', tonumber(debug ~= nil and debug.renderFlags0 or 0) or 0) ..
            ' render1=0x' .. string.format('%X', tonumber(debug ~= nil and debug.renderFlags1 or 0) or 0) ..
            ' layout=' .. tostring(layoutStateName) ..
            ' slot=' .. tostring(found.slot) ..
            ' hp=' .. tostring(found.hp) .. '/' .. tostring(found.maxHp) .. ' pct=' .. tostring(found.hpPercent) ..
            ' mp=' .. tostring(found.mp) .. '/' .. tostring(found.maxMp) .. ' pct=' .. tostring(found.mpPercent) ..
            ' tp=' .. tostring(found.tp) ..
            ' job=' .. tostring(found.mainJob) ..
            ' lvl=' .. tostring(found.mainJobLevel) ..
            ' linkshellColor=0x' .. string.format('%06X', linkshellColor) ..
            ' jobEnabled=' .. tostring(jobSettings.enabled == true) ..
            ' jobXY=' .. tostring(jobSettings.offsetX) .. ',' .. tostring(jobSettings.offsetY) ..
            ' jobMode=' .. tostring(jobSettings.displayModeIndex) ..
            ' levelEnabled=' .. tostring(levelSettings.enabled == true) ..
            ' levelXY=' .. tostring(levelSettings.offsetX) .. ',' .. tostring(levelSettings.offsetY)
        );
        return;
    end

    if (subcommand == 'petstate') then
        log.Info(petState.GetStatusText());
        return;
    end

    if (subcommand == 'petprobe') then
        local selfEntity = entities.GetSelf();
        local petIndex = entities.GetOwnPetTargetIndex();
        local mainJob = entities.GetPlayerMainJobId();
        local pet = entities.GetOwnDrgPet() or entities.GetOwnBstPet() or entities.GetOwnSmnPet() or entities.GetOwnPupPet() or entities.GetOwnLuopan();
        local debug = petIndex ~= nil and entities.GetEntityDebugInfo(petIndex, targeting.GetSettings().enemyPlateRange) or nil;
        local selfStatus = tonumber(selfEntity ~= nil and selfEntity.status or nil);
        local petStatus = tonumber(pet ~= nil and pet.status or nil);
        local restingTrigger = petStatus == 33 or selfStatus == 33;
        local petAnchorBone = (pet ~= nil and pet.petType == 'wyvern') and petPlate.GetWyvernAnchorBone(pet) or nil;
        local petWorldOffset = (pet ~= nil and pet.petType == 'wyvern') and petPlate.GetWyvernWorldOffsetY(pet) or nil;
        local petOverlayOffset = (pet ~= nil and pet.petType == 'wyvern') and petPlate.GetWyvernOverlayOffsetY(pet) or nil;

        log.Info(
            'Pet probe mainJob=' .. tostring(mainJob) ..
            ' selfStatus=' .. tostring(selfStatus) ..
            ' petIndex=' .. tostring(petIndex) ..
            ' petName=' .. tostring(pet ~= nil and pet.name or nil) ..
            ' petType=' .. tostring(pet ~= nil and pet.petType or nil) ..
            ' petServer=' .. tostring(pet ~= nil and pet.serverId or nil) ..
            ' petStatus=' .. tostring(petStatus) ..
            ' petHpPct=' .. tostring(pet ~= nil and pet.hpPercent or nil) ..
            ' petDistance=' .. tostring(pet ~= nil and pet.distance or nil) ..
            ' restingTrigger=' .. tostring(restingTrigger) ..
            ' petAnchorBone=' .. tostring(petAnchorBone) ..
            ' petWorldOffsetY=' .. tostring(petWorldOffset) ..
            ' petOverlayOffsetY=' .. tostring(petOverlayOffset) ..
            ' rawName=' .. tostring(debug ~= nil and debug.name or nil) ..
            ' rawType=' .. tostring(debug ~= nil and debug.type or nil) ..
            ' rawStatus=' .. tostring(debug ~= nil and debug.status or nil) ..
            ' spawn=0x' .. string.format('%X', tonumber(debug ~= nil and debug.spawnFlags or 0) or 0) ..
            ' render0=0x' .. string.format('%X', tonumber(debug ~= nil and debug.renderFlags0 or 0) or 0) ..
            ' render1=0x' .. string.format('%X', tonumber(debug ~= nil and debug.renderFlags1 or 0) or 0)
        );
        return;
    end

    if (subcommand == 'pupdebug') then
        log.Info(entities.GetOwnPupDebugText());
        return;
    end

    if (subcommand == 'restdebug') then
        local center = entities.GetSelfCanvasCenter(canvasDefaults.offsetX, canvasDefaults.offsetY);
        local global = state.GetGlobalSettings(globalDefaults);
        local resting = global.resting or {};

        if (center == nil) then
            log.Warn('Rest debug failed: self projection unavailable.');
            return;
        end

        log.Info(
            'Rest debug status=' .. tostring(center.status) ..
            ' hp=' .. tostring(center.hp) .. '/' .. tostring(center.maxHp) .. ' pct=' .. tostring(center.hpPercent) ..
            ' mp=' .. tostring(center.mp) .. '/' .. tostring(center.maxMp) .. ' pct=' .. tostring(center.mpPercent) ..
            ' enabled=' .. tostring(resting.enabled ~= false) ..
            ' display=' .. tostring(resting.displayMode or 'Bar') ..
            ' hideFullHp=' .. tostring(resting.hideAtFullHp == true) ..
            ' hideFullMp=' .. tostring(resting.hideAtFullMp == true)
        );
        return;
    end

    if (subcommand == 'buffdebug' or subcommand == 'statusdebug') then
        local selfEntity = entities.GetSelf();
        local liveState = 'Idle';
        local targetIndex = targeting.GetCurrentTargetIndex();
        local targetEntity = nil;

        if (selfEntity ~= nil and tonumber(selfEntity.status) == 1) then
            liveState = 'Combat';
        elseif (selfEntity ~= nil and tonumber(selfEntity.status) == 33) then
            liveState = 'Resting';
        end

        if (targetIndex ~= nil and targetIndex ~= 0) then
            local entityManager = AshitaCore:GetMemoryManager():GetEntity();

            if (entityManager ~= nil) then
                local ok = pcall(function()
                    targetEntity = {
                        index = targetIndex,
                        name = entityManager:GetName(targetIndex),
                        serverId = entityManager:GetServerId(targetIndex),
                    };
                end);

                if (ok ~= true) then
                    targetEntity = nil;
                end
            end
        end

        local buffsSettings = state.GetWidgetSettings('Self', liveState, 'Buffs', buffsDefaults);
        local debuffsSettings = state.GetWidgetSettings('Self', liveState, 'Debuffs', debuffsDefaults);
        local pcBuffsSettings = state.GetWidgetSettings('PC', 'Combat', 'Buffs', buffsDefaults);
        local pcDebuffsSettings = state.GetWidgetSettings('PC', 'Combat', 'Debuffs', debuffsDefaults);
        local targetServerId = targetEntity ~= nil and targetEntity.serverId or nil;

        log.Info(
            'Buff debug state=' .. tostring(liveState) ..
            ' selfStatus=' .. tostring(selfEntity ~= nil and selfEntity.status or nil) ..
            ' buffsEnabled=' .. tostring(buffsSettings ~= nil and buffsSettings.enabled == true) ..
            ' debuffsEnabled=' .. tostring(debuffsSettings ~= nil and debuffsSettings.enabled == true) ..
            ' buffsXY=' .. tostring(buffsSettings ~= nil and buffsSettings.offsetX or nil) .. ',' .. tostring(buffsSettings ~= nil and buffsSettings.offsetY or nil) ..
            ' debuffsXY=' .. tostring(debuffsSettings ~= nil and debuffsSettings.offsetX or nil) .. ',' .. tostring(debuffsSettings ~= nil and debuffsSettings.offsetY or nil) ..
            ' ' .. playerStatuses.GetSelfDebugText() ..
            ' target=' .. tostring(targetEntity ~= nil and targetEntity.name or nil) ..
            ' targetServer=' .. tostring(targetServerId) ..
            ' pcBuffsEnabled=' .. tostring(pcBuffsSettings ~= nil and pcBuffsSettings.enabled == true) ..
            ' pcDebuffsEnabled=' .. tostring(pcDebuffsSettings ~= nil and pcDebuffsSettings.enabled == true) ..
            ' ' .. partyStatuses.GetDebugText(targetServerId)
        );
        return;
    end

    if (subcommand == 'trustbuffdebug' or subcommand == 'truststatusdebug') then
        local action = tostring(args[3] or ''):lower();
        LogTrustBuffProbe(action == 'scan');
        return;
    end

    if (subcommand == 'luopanprobe' or subcommand == 'luopandebug') then
        local action = tostring(args[3] or 'status'):lower();
        local seconds = tonumber(args[4]);

        if (action == 'on' or action == 'start') then
            luopanStatuses.EnableProbe(seconds or 120);
            return;
        end

        if (action == 'off' or action == 'stop') then
            luopanStatuses.DisableProbe();
            return;
        end

        if (action == 'status' or action == '') then
            log.Info(luopanStatuses.GetProbeStatusText());
            return;
        end

        log.Info('Usage: /lp luopanprobe on [seconds] | off | status');
        return;
    end

        if (subcommand == 'enemystatusdebug' or subcommand == 'enemybuffdebug' or subcommand == 'enemydebuffdebug') then
        local action = tostring(args[3] or 'status'):lower();
        local seconds = tonumber(args[4]);
        local targetIndex = targeting.GetCurrentTargetIndex() or targeting.GetCurrentSubTargetIndex();
        local targetName = nil;
        local targetServerId = 0;
        local targetEnemy = nil;
        local targetEngaged = false;
        local geoRows = {};

        if (targetIndex ~= nil and targetIndex ~= 0) then
            local entityManager = AshitaCore:GetMemoryManager():GetEntity();

            if (entityManager ~= nil) then
                targetName = CommandSafeCall(nil, function() return entityManager:GetName(targetIndex); end);
                targetServerId = CommandSafeCall(0, function() return entityManager:GetServerId(targetIndex); end);
            end

            targetEnemy = entities.GetEnemy(targetIndex, true);
            targetEngaged = engagedEnemies.IsEngaged(targetIndex) == true;
            geoRows = enemyStatuses.GetGeoAuraDebuffRows(targetEnemy ~= nil and targetEnemy.distance or nil, targetEngaged);
        end

        if (action == 'on' or action == 'capture') then
            enemyStatuses.EnableDebugForSeconds(seconds or 20, targetServerId);
            log.Info(
                'Enemy status capture on for ' .. tostring(seconds or 20) ..
                ' seconds. target=' .. tostring(targetName) ..
                ' server=' .. tostring(targetServerId)
            );
            return;
        end

        if (action == 'off') then
            enemyStatuses.SetDebugEnabled(false);
            log.Info('Enemy status capture off.');
            return;
        end

        if (targetServerId == 0) then
            log.Warn('Enemy status debug failed: target an enemy first.');
            return;
        end

        log.Info(
            'Enemy target=' .. tostring(targetName) ..
            ' index=' .. tostring(targetIndex) ..
            ' server=' .. tostring(targetServerId) ..
            ' distance=' .. tostring(targetEnemy ~= nil and targetEnemy.distance or nil) ..
            ' engaged=' .. tostring(targetEngaged) ..
            ' geoRows=' .. tostring(#geoRows) ..
            ' ' .. enemyStatuses.GetDebugText(targetServerId)
        );
        return;
    end

    if (subcommand == 'fishingdebug' or subcommand == 'gatheringdebug' or subcommand == 'gathering') then
        local action = tostring(args[3] or 'status'):lower();

        if (action == 'test' or action == 'show') then
            targeting.ForceGatheringDisplay(args[4] or 'hatchet', tonumber(args[5]) or 8);
            log.Info('Gathering test display: ' .. targeting.GetGatheringDebugStatus());
            return;
        end

        log.Info(
            'Fishing/gathering debug interact=' .. tostring(targeting.GetGatheringInteractStatus()) ..
            ' equip=' .. tostring(targeting.GetFishingEquipmentStatus()) ..
            ' gather=' .. tostring(targeting.GetGatheringDebugStatus()) ..
            ' ' .. worldMarkerProbe.GetStatusText()
        );
        return;
    end

    if (subcommand == 'recasts') then
        log.Info(abilityRecast.GetDebugText());
        return;
    end

    if (subcommand == 'castdebug') then
        local action = tostring(args[3] or 'on'):lower();
        local seconds = tonumber(args[4]);

        if (action == 'check' or action == 'probe') then
            local rawCommand = tostring(e.command or '');
            local probeCommand = rawCommand:gsub('^%s*%S+%s+%S+%s+%S+%s*', '', 1);

            if (probeCommand == '') then
                log.Info('Usage: /lp castdebug check /ma "Cure" <stpc>');
                return;
            end

            log.Info(targetActionRange.ProbeCommandText(probeCommand));
            return;
        end

        if (action == 'packets') then
            local packetAction = tostring(args[4] or 'on'):lower();
            local packetSeconds = tonumber(args[5]);

            if (packetAction == 'on') then
                targetActionRange.EnablePacketDebugForSeconds(packetSeconds or 20);
                log.Info('Cast packet debug on for ' .. tostring(packetSeconds or 20) .. ' seconds.');
                return;
            end

            if (packetAction == 'off') then
                targetActionRange.SetPacketDebugEnabled(false);
                log.Info('Cast packet debug off.');
                return;
            end

            if (packetAction == 'status') then
                log.Info('Cast packet debug enabled=' .. tostring(targetActionRange.GetPacketDebugEnabled()) .. '.');
                return;
            end

            log.Info('Usage: /lp castdebug packets on [seconds] | off | status');
            return;
        end

        if (action == 'tracker') then
            local trackerAction = tostring(args[4] or 'status'):lower();
            local trackerSeconds = tonumber(args[5]);

            if (trackerAction == 'on') then
                enemyCasts.EnableDebugForSeconds(trackerSeconds or 20);
                log.Info('Cast tracker capture on for ' .. tostring(trackerSeconds or 20) .. ' seconds.');
                return;
            end

            if (trackerAction == 'off') then
                enemyCasts.SetDebugEnabled(false);
                log.Info('Cast tracker capture off.');
                return;
            end

            if (trackerAction == 'status') then
                log.Info(enemyCasts.GetDebugText());
                return;
            end

            log.Info('Usage: /lp castdebug tracker on [seconds] | off | status');
            return;
        end

        if (action == 'on') then
            targetActionRange.EnableDebugForSeconds(seconds or 20);
            log.Info('Cast range debug on for ' .. tostring(seconds or 20) .. ' seconds.');
            return;
        end

        if (action == 'off') then
            targetActionRange.SetDebugEnabled(false);
            log.Info('Cast range debug off.');
            return;
        end

        if (action == 'status') then
            log.Info(targetActionRange.GetDebugText());
            log.Info(targetActionRange.GetQueuedActionText());
            log.Info('Cast packet debug enabled=' .. tostring(targetActionRange.GetPacketDebugEnabled()) .. '.');
            return;
        end

        log.Info('Usage: /lp castdebug on [seconds] | off | status | check /ma "Cure" <stpc> | packets on [seconds] | packets off | packets status | tracker on [seconds] | tracker off | tracker status');
        return;
    end

    if (subcommand == 'aoedebug') then
        log.Info(aoeNameHighlight.GetDebugText());
        return;
    end

    if (subcommand == 'mogjobdebug' or subcommand == 'mogdebug') then
        local action = tostring(args[3] or 'status'):lower();
        local seconds = tonumber(args[4]);

        if (action == 'on') then
            mogJobDebug.EnableForSeconds(seconds or 20);
            return;
        end

        if (action == 'off') then
            mogJobDebug.SetEnabled(false);
            log.Info('Mog job debug off.');
            return;
        end

        if (action == 'status') then
            log.Info(mogJobDebug.GetDebugText());
            return;
        end

        log.Info('Usage: /lp mogjobdebug on [seconds] | off | status');
        return;
    end

    if (subcommand == 'jobchange' or subcommand == 'job') then
        local action = tostring(args[3] or 'status');
        local actionLower = action:lower();

        if (actionLower == 'status') then
            log.Info(jobChange.GetStatusText());
            return;
        end

        if (actionLower == 'cancel' or actionLower == 'off') then
            jobChange.Cancel();
            log.Info('Queued job change cancelled.');
            return;
        end

        local success = false;
        local err = nil;

        if (actionLower == 'main') then
            success, err = jobChange.ChangeJobs(args[4], nil);
        elseif (actionLower == 'sub') then
            success, err = jobChange.ChangeJobs(nil, args[4]);
        else
            local pair = tostring(args[3] or ''):gsub('\\', '/');
            local slashIndex = pair:find('/', 1, true);

            if (slashIndex ~= nil) then
                local mainJob = pair:sub(1, slashIndex - 1);
                local subJob = pair:sub(slashIndex + 1);
                success, err = jobChange.ChangeJobs(mainJob ~= '' and mainJob or nil, subJob ~= '' and subJob or nil);
            else
                success, err = jobChange.ChangeJobs(action, nil);
            end
        end

        if (success ~= true) then
            local message = tostring(err or 'Job change failed.');

            if (message == 'No change required.') then
                log.Info(message);
            else
                log.Warn(message);
                log.Info('Usage: /lp jobchange WAR | main WAR | sub NIN | PUP/COR | status | cancel');
            end
        end
        return;
    end

    if (subcommand == 'mousemove' or subcommand == 'mousecontrols') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            mouseControls.SetBothButtonForwardEnabled(true);
        elseif (value == 'off') then
            mouseControls.SetBothButtonForwardEnabled(false);
        elseif (value == 'status' or value == '') then
            log.Info('Both-button forward enabled=' .. tostring(mouseControls.GetBothButtonForwardEnabled()));
            return;
        else
            mouseControls.SetBothButtonForwardEnabled(not mouseControls.GetBothButtonForwardEnabled());
        end

        state.Save();
        log.Info('Both-button forward enabled=' .. tostring(mouseControls.GetBothButtonForwardEnabled()));
        return;
    end

    if (subcommand == 'mousesteer') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            mouseControls.SetBothButtonSteerEnabled(true);
        elseif (value == 'off') then
            mouseControls.SetBothButtonSteerEnabled(false);
        elseif (value == 'status' or value == '') then
            log.Info('Both-button steer enabled=' .. tostring(mouseControls.GetBothButtonSteerEnabled()));
            return;
        else
            mouseControls.SetBothButtonSteerEnabled(not mouseControls.GetBothButtonSteerEnabled());
        end

        state.Save();
        log.Info('Both-button steer enabled=' .. tostring(mouseControls.GetBothButtonSteerEnabled()));
        return;
    end

    if (subcommand == 'mouseinvert') then
        local value = tostring(args[3] or ''):lower();

        if (value == 'on') then
            mouseControls.SetInvertSteer(true);
        elseif (value == 'off') then
            mouseControls.SetInvertSteer(false);
        elseif (value == 'status' or value == '') then
            log.Info('Mouse steer inverted=' .. tostring(mouseControls.GetInvertSteer()));
            return;
        else
            mouseControls.SetInvertSteer(not mouseControls.GetInvertSteer());
        end

        state.Save();
        log.Info('Mouse steer inverted=' .. tostring(mouseControls.GetInvertSteer()));
        return;
    end

    if (subcommand == 'config' or subcommand == 'settings') then
        state.SetConfigOpen(not state.GetConfigOpen());
        return;
    end

    if (subcommand == 'depthbridge') then
        occlusion.PrintStatus();
        return;
    end

    if (subcommand == 'depthtest') then
        local center = entities.GetSelfCanvasCenter(canvasDefaults.offsetX, canvasDefaults.offsetY);

        if (center == nil) then
            log.Warn('Depth test failed: self projection unavailable.');
            return;
        end

        local result, err, nativeStatus = occlusion.TestScreenPoint(
            center.boneScreenX,
            center.boneScreenY,
            center.boneScreenZ,
            canvasDefaults.occlusion
        );

        if (result == nil) then
            log.Warn(string.format(
                'Depth test failed: screen=%s,%s projectedDepth=%s error=%s %s',
                tostring(center.boneScreenX),
                tostring(center.boneScreenY),
                tostring(center.boneScreenZ),
                tostring(err),
                occlusion.FormatNativeStatus(nativeStatus)
            ));
            return;
        end

        log.Info(string.format(
            'Depth test: screen=%s,%s projectedDepth=%s sampledDepth=%s occluded=%s source=%s %s',
            tostring(center.boneScreenX),
            tostring(center.boneScreenY),
            tostring(result.projectedDepth),
            tostring(result.sampledDepth),
            tostring(result.occluded),
            tostring(result.source),
            occlusion.FormatNativeStatus(nativeStatus)
        ));
        return;
    end

    if (subcommand == 'fpsobserve') then
        local action = tostring(args[3] or 'status'):lower();

        if (action == 'on') then
            adaptivePerformance.SetEnabled(true);
        elseif (action == 'off') then
            adaptivePerformance.SetEnabled(false);
        end

        log.Info(adaptivePerformance.GetStatusText());
        return;
    end

    if (subcommand == 'fpsmode') then
        local mode = tostring(args[3] or ''):lower();

        if (mode == 'auto' or mode == 'quality' or mode == 'smooth' or mode == 'fps1' or mode == 'light') then
            adaptivePerformance.SetSelectedMode(mode);
        end

        log.Info(adaptivePerformance.GetStatusText());
        return;
    end

    if (subcommand == 'fpsstatus') then
        log.Info(adaptivePerformance.GetStatusText());
        return;
    end

    if (subcommand == 'imgui') then
        local imguiApi = require('imgui');
        local names = T{
            'PushFont',
            'PopFont',
            'SetWindowFontScale',
            'SetWindowFontSize',
            'SetWindowScale',
            'GetFont',
            'GetFontBaked',
            'GetFontSize',
        };
        local parts = T{};

        for _, name in ipairs(names) do
            parts:append(tostring(name) .. '=' .. tostring(type(imguiApi[name])));
        end

        log.Info('ImGui API: ' .. table.concat(parts, ' '));
        return;
    end

    if (subcommand == 'cursor') then
        local action = tostring(args[3] or 'toggle'):lower();

        if (action == 'on') then
            cursorOverlay.SetEnabled(true);
        elseif (action == 'off') then
            cursorOverlay.SetEnabled(false);
        elseif (action == 'toggle') then
            cursorOverlay.Toggle();
        end

        state.Save();
        log.Info('Cursor overlay enabled=' .. tostring(cursorOverlay.GetEnabled()));
        return;
    end

    log.Info('Commands: /lp config, /lp petprobe, /lp perf on, /lp perf detail on, /lp isolate status, /lp diag start, /lp diag scenario target-on, /lp diag restore, /lp world on, /lp world off, /lp mousemove on, /lp mousesteer on, /lp bridge status, /lp depthbridge, /lp depthtest, /lp castdebug on [seconds], /lp fpsstatus, /lp imgui, /lp cursor on');
end

return commands;
