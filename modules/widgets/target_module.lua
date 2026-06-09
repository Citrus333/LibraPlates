local imgui = require('imgui');
local uiTooltip = require('core.ui_tooltip');
local arrowAnimation = require('core.target_arrow_animation');
local state = require('core.state');
local globalDefaults = require('config.global');

local targetModule = {};
local unpackTable = table.unpack or unpack;
local labelColor = { 0.92, 0.92, 0.90, 1.0 };
local valueColor = { 0.65, 0.90, 1.0, 1.0 };
local actionColor = { 1.0, 0.84, 0.0, 1.0 };
local fileCache = {};
local heldButtonState = {};
local targetModuleTableFlags = (_G.ImGuiTableFlags_SizingFixedFit or 0) + (_G.ImGuiTableFlags_BordersInnerH or 0);
local autoPlaceAnchorOptions = T{ 'Widest element', 'Name', 'HP Bar' };
local colorEditFlags = bit ~= nil and bit.bor ~= nil
    and bit.bor(_G.ImGuiColorEditFlags_NoAlpha or 0, _G.ImGuiColorEditFlags_NoInputs or 0)
    or ((_G.ImGuiColorEditFlags_NoAlpha or 0) + (_G.ImGuiColorEditFlags_NoInputs or 0));

local function GetAddonPath()
    local ok, path = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and path ~= nil) then
        return tostring(path);
    end

    return '.\\';
end

local function GetTargetAssetPath(category)
    return GetAddonPath() .. 'assets\\images\\target\\' .. tostring(category or '') .. '\\';
end

local function AddFile(files, category, name)
    name = tostring(name or ''):gsub('^.*[\\/]', '');

    if (name == '' or string.lower(name):match('%.png$') == nil) then
        return;
    end

    if (category == 'arrows' and arrowAnimation.GetDropdownFileName(name) ~= name) then
        return;
    end

    for _, existing in ipairs(files) do
        if (existing == name) then
            return;
        end
    end

    files[#files + 1] = name;
end

local function GetFiles(category)
    category = tostring(category or 'arrows');

    if (fileCache[category] ~= nil) then
        return fileCache[category];
    end

    local files = T{ 'None' };
    local folder = GetTargetAssetPath(category);
    local pipe = io.popen('dir /b "' .. folder .. '*.png" 2>nul');

    if (pipe ~= nil) then
        for line in pipe:lines() do
            AddFile(files, category, line);
        end

        pipe:close();
    end

    table.sort(files, function(a, b)
        if (a == 'None') then return true; end
        if (b == 'None') then return false; end
        return string.lower(tostring(a)) < string.lower(tostring(b));
    end);

    fileCache[category] = files;
    return files;
end

local function ClickText(label, color)
    imgui.TextColored(color or valueColor, label);

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        return true;
    end

    if (imgui.IsItemHovered ~= nil and imgui.IsMouseDown ~= nil) then
        return (imgui.IsItemHovered() == true and imgui.IsMouseDown(0) == true);
    end

    return false;
end

local function DrawActionButton(label)
    if (imgui.Button ~= nil) then
        return imgui.Button(tostring(label)) == true;
    end

    return ClickText(tostring(label), actionColor) == true;
end

local function DrawToggle(label, value)
    if (imgui.Checkbox ~= nil) then
        local ref = { value == true };

        if (imgui.Checkbox(label, ref) == true) then
            return ref[1] == true;
        end

        return value == true;
    end

    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (ClickText((value == true) and 'On' or 'Off', valueColor) == true) then
        return not (value == true);
    end

    return value == true;
end

local function IsHeldButton(label)
    if (imgui.Button == nil) then
        return false;
    end

    local clicked = imgui.Button(label) == true;
    local active = imgui.IsItemActive ~= nil and imgui.IsItemActive() == true;
    local mouseDown = imgui.IsMouseDown == nil or imgui.IsMouseDown(0) == true;
    local now = os.clock();
    local key = tostring(label or '');

    if (active == true and mouseDown == true) then
        local itemClicked = (imgui.IsItemActivated ~= nil and imgui.IsItemActivated() == true)
            or (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true);
        local state = heldButtonState[key];

        if (state == nil) then
            state = { nextRepeat = now + 0.35, clicked = false };
            heldButtonState[key] = state;
        end

        if ((clicked == true or itemClicked == true) and state.clicked ~= true) then
            state.clicked = true;
            return true;
        end

        if (now >= (tonumber(state.nextRepeat) or now + 0.35)) then
            state.nextRepeat = now + 0.08;
            return true;
        end

        return false;
    end

    if (heldButtonState[key] ~= nil) then
        heldButtonState[key] = nil;
        return false;
    end

    return clicked;
end

local function DrawNumberControl(value, minValue, maxValue, step, id, sliderWidth)
    local current = tonumber(value) or 0;
    local amount = tonumber(step) or 1;
    local minimum = tonumber(minValue) or -1000;
    local maximum = tonumber(maxValue) or 1000;
    local itemId = tostring(id or 'number'):gsub('[^%w_]', '_');

    current = math.max(minimum, math.min(maximum, current));

    if (imgui.Button ~= nil and IsHeldButton('-##target_module_' .. itemId .. '_minus') == true) then
        current = current - amount;
    elseif (imgui.Button == nil and ClickText('less', actionColor) == true) then
        current = current - amount;
    end

    imgui.SameLine();

    if (imgui.InputText ~= nil) then
        local ref = { amount < 1 and tostring(current) or tostring(math.floor(current + 0.5)) };
        if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(tonumber(sliderWidth) or 90); end
        if (imgui.InputText('##target_module_' .. itemId, ref, 16) == true) then
            current = tonumber(ref[1]) or current;
        end
        if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
    elseif (amount < 1 and imgui.SliderFloat ~= nil) then
        local ref = { current };
        if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(tonumber(sliderWidth) or 90); end
        if (imgui.SliderFloat('##target_module_' .. itemId, ref, minimum, maximum) == true) then
            current = tonumber(ref[1]) or current;
        end
        if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
    elseif (amount >= 1 and imgui.SliderInt ~= nil) then
        local ref = { math.floor(current + 0.5) };
        if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(tonumber(sliderWidth) or 90); end
        if (imgui.SliderInt('##target_module_' .. itemId, ref, minimum, maximum) == true) then
            current = tonumber(ref[1]) or current;
        end
        if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
    elseif (amount < 1) then
        imgui.TextColored(valueColor, string.format('%.2f', current));
    else
        imgui.TextColored(valueColor, tostring(current));
    end

    imgui.SameLine();

    if (imgui.Button ~= nil and IsHeldButton('+##target_module_' .. itemId .. '_plus') == true) then
        current = current + amount;
    elseif (imgui.Button == nil and ClickText('more', actionColor) == true) then
        current = current + amount;
    end

    return math.max(minimum, math.min(maximum, current));
end

local function DrawNumber(label, value, minValue, maxValue, step, id)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local result = value;

        if (imgui.BeginTable('##target_module_number_' .. tostring(id or label), 2, targetModuleTableFlags)) then
            imgui.TableSetupColumn('##label', 0, 122);
            imgui.TableSetupColumn('##control', 0, 124);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, label);
            imgui.TableNextColumn();
            result = DrawNumberControl(value, minValue, maxValue, step, id or label, 58);
            imgui.EndTable();
        end

        return result;
    end

    local current = tonumber(value) or 0;
    local itemId = tostring(id or label or 'number'):gsub('[^%w_]', '_');

    imgui.TextColored(labelColor, label);
    imgui.SameLine();
    current = DrawNumberControl(current, minValue, maxValue, step, itemId, 58);

    return current;
end

local function DrawNumberPair(leftLabel, leftValue, rightLabel, rightValue, minValue, maxValue, step, leftId, rightId)
    leftId = leftId or leftLabel;
    rightId = rightId or rightLabel;

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local left = leftValue;
        local right = rightValue;

        if (imgui.BeginTable('##target_module_pair_' .. tostring(leftId) .. '_' .. tostring(rightId), 4, targetModuleTableFlags)) then
            imgui.TableSetupColumn('##label_left', 0, 104);
            imgui.TableSetupColumn('##control_left', 0, 124);
            imgui.TableSetupColumn('##label_right', 0, 104);
            imgui.TableSetupColumn('##control_right', 0, 124);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, leftLabel);
            imgui.TableNextColumn();
            left = DrawNumberControl(leftValue, minValue, maxValue, step, leftId, 58);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, rightLabel);
            imgui.TableNextColumn();
            right = DrawNumberControl(rightValue, minValue, maxValue, step, rightId, 58);
            imgui.EndTable();
        end

        return left, right;
    end

    local left = DrawNumber(leftLabel, leftValue, minValue, maxValue, step, leftId);

    imgui.SameLine();

    local right = DrawNumber(rightLabel, rightValue, minValue, maxValue, step, rightId);

    return left, right;
end

local function ClampOffsetToVisibleEdge(value, size, canvasSize, minVisible)
    local halfCanvas = (tonumber(canvasSize) or 0) * 0.5;
    local halfSize = (tonumber(size) or 0) * 0.5;
    local visible = math.max(1, tonumber(minVisible) or 24);
    local limit = math.max(0, halfCanvas + halfSize - visible);
    local current = tonumber(value) or 0;

    if (current < -limit) then
        return -limit;
    end

    if (current > limit) then
        return limit;
    end

    return current;
end

local function CopyDefaults(settings, defaults)
    for key, value in pairs(defaults or {}) do
        if (type(value) == 'table') then
            settings[key] = { unpackTable(value) };
        else
            settings[key] = value;
        end
    end
end

local function ApplyDefaults(settings, defaults)
    for key, value in pairs(defaults or {}) do
        if (settings[key] == nil) then
            if (
                (key == 'backgroundColor' or key == 'arrowColor' or key == 'lockColor' or key == 'chevronColor') and
                type(settings.color) == 'table'
            ) then
                settings[key] = { unpackTable(settings.color) };
            elseif (type(value) == 'table') then
                settings[key] = { unpackTable(value) };
            else
                settings[key] = value;
            end
        end
    end
end

local function DrawColor(label, color)
    color = color or { 1.0, 1.0, 1.0, 1.0 };
    color[1] = tonumber(color[1]) or 1.0;
    color[2] = tonumber(color[2]) or 1.0;
    color[3] = tonumber(color[3]) or 1.0;
    color[4] = tonumber(color[4]) or 1.0;

    if (imgui.ColorEdit4 ~= nil) then
        imgui.ColorEdit4(label, color, colorEditFlags);
        return color;
    end

    imgui.TextColored(color, '#');
    imgui.SameLine();
    imgui.TextColored(labelColor, label);

    local colorId = tostring(label or 'Color'):gsub('[^%w_]', '_');
    color[1] = DrawNumber('Red', color[1], 0, 1, 0.05, colorId .. 'Red');
    color[2] = DrawNumber('Green', color[2], 0, 1, 0.05, colorId .. 'Green');
    color[3] = DrawNumber('Blue', color[3], 0, 1, 0.05, colorId .. 'Blue');
    color[4] = DrawNumber('Alpha', color[4], 0, 1, 0.05, colorId .. 'Alpha');

    return color;
end

local function DrawFile(label, category, current)
    local files = GetFiles(category);
    local value = tostring(current or files[1] or 'None');

    if (category == 'arrows') then
        value = arrowAnimation.GetDropdownFileName(value);
    end

    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.BeginCombo('##' .. label .. category, value) == true) then
            for _, file in ipairs(files) do
                local selected = (file == value);

                if (imgui.Selectable(tostring(file), selected) == true) then
                    value = file;
                end

                if (selected == true and imgui.SetItemDefaultFocus ~= nil) then
                    imgui.SetItemDefaultFocus();
                end
            end

            imgui.EndCombo();
        end

        return value;
    end

    imgui.TextColored(valueColor, '[' .. value .. ' v]');

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        local index = 1;

        for i, file in ipairs(files) do
            if (file == value) then
                index = i;
                break;
            end
        end

        index = index + 1;

        if (index > #files) then
            index = 1;
        end

        value = files[index] or value;
    end

    return value;
end

local function DrawOption(label, options, current, id)
    local value = tostring(current or options[1] or '');
    local comboId = '##' .. tostring(id or label or 'option');

    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.BeginCombo(comboId, value) == true) then
            for _, option in ipairs(options) do
                local selected = (option == value);

                if (imgui.Selectable(tostring(option), selected) == true) then
                    value = option;
                end

                if (selected == true and imgui.SetItemDefaultFocus ~= nil) then
                    imgui.SetItemDefaultFocus();
                end
            end

            imgui.EndCombo();
        end

        return value;
    end

    if (ClickText(value, valueColor) == true) then
        local index = 1;

        for i, option in ipairs(options) do
            if (option == value) then
                index = i;
                break;
            end
        end

        index = index + 1;

        if (index > #options) then
            index = 1;
        end

        value = options[index] or value;
    end

    return value;
end

function targetModule.DrawSettings(settings, context)
    if (settings == nil) then
        return;
    end

    local defaults = context ~= nil and context.defaults or {};
    local label = tostring(context ~= nil and context.widget or 'Target Module');
    local isNpcObject = tostring(context ~= nil and context.entity or '') == 'NPC';
    local entityName = tostring(context ~= nil and context.entity or '');
    local isSubtargetModule = tostring(label) == 'Subtarget (module)';
    local lockOnly = context ~= nil and context.lockOnly == true;
    local isPet = (
        entityName == 'Pet (BST)' or
        entityName == 'Pet (SMN)' or
        entityName == 'Wyvern' or
        entityName == 'Automaton'
    );

    ApplyDefaults(settings, defaults);

    if (isSubtargetModule ~= true) then
        settings.arrowDistanceColoring = false;
    end

    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, label .. ' settings');
    imgui.SameLine();
    imgui.TextColored((settings.enabled ~= false) and valueColor or { 0.20, 0.65, 0.67, 1.0 }, (settings.enabled ~= false) and 'ON' or 'OFF');
    uiTooltip.Info('This controls only the LibraPlates custom target/subtarget module. The native game target arrow is controlled globally in General > Targeting.');

    if (lockOnly == true) then
        imgui.Separator();
        imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Lock-on icon');
        settings.lockEnabled = DrawToggle('Show lock-on icon', settings.lockEnabled ~= false);

        if (settings.lockEnabled ~= false) then
            settings.lockWidth, settings.lockHeight = DrawNumberPair(
                'Width',
                settings.lockWidth,
                'Height',
                settings.lockHeight,
                1,
                200,
                1,
                'TargetModuleLockWidth',
                'TargetModuleLockHeight'
            );
            settings.lockOffsetX, settings.lockOffsetY = DrawNumberPair(
                'Position X',
                settings.lockOffsetX,
                'Position Y',
                settings.lockOffsetY,
                -500,
                500,
                1,
                'TargetModuleLockX',
                'TargetModuleLockY'
            );
            settings.lockColor = DrawColor('Lock-on tint', settings.lockColor);
            uiTooltip.Info('Shown on the target marker while lock-on is active.');
        end

        return;
    end

    if (isPet == true and label ~= 'Subtarget Module') then
        local globalSettings = state.GetGlobalSettings(globalDefaults);
        globalSettings.targeting = globalSettings.targeting or {};

        if (globalSettings.targeting.enablePetPlateTargeting == nil) then
            globalSettings.targeting.enablePetPlateTargeting = true;
        end

        imgui.Separator();
        local enabled = DrawToggle('Allow pet plate targeting', globalSettings.targeting.enablePetPlateTargeting ~= false);

        if (enabled ~= (globalSettings.targeting.enablePetPlateTargeting ~= false)) then
            globalSettings.targeting.enablePetPlateTargeting = enabled == true;
            state.Save();
        end

        uiTooltip.Info('When off, pet plates stay visible but LibraPlates will not target the pet from plate clicks and will suppress the pet Target module overlay.');

        if (globalSettings.targeting.enablePetPlateTargeting == false) then
            return;
        end
    end

    if (isNpcObject ~= true) then
        imgui.Separator();
        imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Highlight');
        settings.backgroundFile = DrawFile('Highlight image', 'backgrounds', settings.backgroundFile);
        if (tostring(settings.backgroundFile or 'None') == 'None') then
            settings.backgroundEnabled = false;
            settings.showBackground = false;
        elseif (settings.showBackground == true and settings.backgroundEnabled == false) then
            settings.backgroundEnabled = true;
        end

        if (tostring(settings.backgroundFile or 'None') ~= 'None') then
            settings.autoPlaceBackground = DrawToggle('Auto place highlight', settings.autoPlaceBackground ~= false);
            uiTooltip.Info('When enabled, the highlight image follows the selected plate element. Size expands it outward from the anchor edges. Turn it off to use manual highlight width, height, and position.');

            if (settings.autoPlaceBackground ~= false) then
                settings.backgroundAutoPlaceAnchor = DrawOption('Auto place by', autoPlaceAnchorOptions, settings.backgroundAutoPlaceAnchor or 'Widest element', 'TargetModuleBackgroundAnchorMode');
                settings.backgroundSpacing = DrawNumber('Size', settings.backgroundSpacing, 0, 300, 1, 'TargetModuleBackgroundSpacing');
            else
                settings.backgroundWidth, settings.backgroundHeight = DrawNumberPair(
                    'Width',
                    settings.backgroundWidth,
                    'Height',
                    settings.backgroundHeight,
                    8,
                    1000,
                    5,
                    'TargetModuleBackgroundWidth',
                    'TargetModuleBackgroundHeight'
                );
                settings.backgroundOffsetX = DrawNumber('Position X', settings.backgroundOffsetX, -350, 350, 5, 'TargetModuleBackgroundX');

                local backgroundHeight = tonumber(settings.backgroundHeight) or 90;
                settings.backgroundOffsetY = DrawNumber(
                    'Position Y',
                    ClampOffsetToVisibleEdge(settings.backgroundOffsetY, backgroundHeight, 512, 24),
                    -500,
                    500,
                    5,
                    'TargetModuleBackgroundY'
                );
                settings.backgroundOffsetY = ClampOffsetToVisibleEdge(settings.backgroundOffsetY, backgroundHeight, 512, 24);
            end
            settings.backgroundColor = DrawColor('Highlight tint', settings.backgroundColor);
        end
    end

    imgui.Separator();
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Arrow');
    settings.arrowFile = DrawFile('Arrow image', 'arrows', settings.arrowFile);
    uiTooltip.Info('None disables the LibraPlates arrow. Still images use names like arrow_1.png and arrow_2.png. Sprite animations use two-digit frames like arrow_classic_01.png, arrow_classic_02.png, and arrow_classic_03.png; the dropdown shows the first frame and Animate cycles the rest.');

    if (tostring(settings.arrowFile or 'None') ~= 'None') then
        settings.arrowWidth, settings.arrowHeight = DrawNumberPair(
            'Width',
            settings.arrowWidth,
            'Height',
            settings.arrowHeight,
            8,
            200,
            1,
            'TargetModuleArrowWidth',
            'TargetModuleArrowHeight'
        );
        if (settings.arrowAnimation == 'Classic' or settings.arrowAnimation == 'Native shimmer') then
            settings.arrowSprite = true;
            settings.arrowAnimationSpeed = tonumber(settings.arrowAnimationSpeed) or 12;
        end

        settings.arrowAnimation = nil;
        local hasSpriteFrames = arrowAnimation.HasSpriteFrames(settings.arrowFile) == true;
        if (hasSpriteFrames == true) then
            settings.arrowSprite = DrawToggle('Animate', settings.arrowSprite == true);
            if (settings.arrowSprite == true) then
                settings.arrowAnimationSpeed = DrawNumber('Animation speed', settings.arrowAnimationSpeed, 1, 60, 1, 'TargetModuleArrowAnimationSpeed');
            end
        else
            settings.arrowSprite = false;
            imgui.TextColored(labelColor, 'Animate');
            imgui.SameLine();
            imgui.TextColored({ 0.45, 0.60, 0.62, 1.0 }, 'Off');
            uiTooltip.Info('The selected arrow image is a still image. Choose a sprite-frame arrow like arrow_classic_01.png to animate it.');
        end

        settings.arrowOffsetX, settings.arrowOffsetY = DrawNumberPair(
            'Position X',
            settings.arrowOffsetX,
            'Position Y',
            settings.arrowOffsetY,
            -500,
            500,
            5,
            'TargetModuleArrowX',
            'TargetModuleArrowY'
        );
        settings.arrowColor = DrawColor('Arrow tint', settings.arrowColor);

        if (isSubtargetModule == true) then
            settings.arrowDistanceColoring = DrawToggle('Distance colors', settings.arrowDistanceColoring == true);
            uiTooltip.Info('When enabled, LibraPlates uses the last action you send (spells/abilities) to set warning/out-of-range bands. If no action was recently sent, the arrow uses only the base arrow tint.');

            if (settings.arrowDistanceColoring == true) then
                settings.arrowOutOfRangeDistance = DrawNumber(
                    'Out of range',
                    settings.arrowOutOfRangeDistance,
                    1,
                    64.4,
                    0.1,
                    'TargetModuleArrowOutOfRange'
                );
                settings.arrowWarningDistance = DrawNumber(
                    'Warning range',
                    settings.arrowWarningDistance,
                    0,
                    64.4,
                    0.1,
                    'TargetModuleArrowWarningRange'
                );
                settings.arrowOutOfRangeColor = DrawColor('Out-of-range tint', settings.arrowOutOfRangeColor);
                settings.arrowWarningColor = DrawColor('Warning tint', settings.arrowWarningColor);
                settings.arrowInRangeColor = DrawColor('In-range tint', settings.arrowInRangeColor);
            end
        end
    else
        settings.arrowSprite = false;
    end

    if (isSubtargetModule ~= true) then
        imgui.Separator();
        imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Lock-on icon');
        settings.lockEnabled = DrawToggle('Show lock-on icon', settings.lockEnabled ~= false);

        if (settings.lockEnabled ~= false) then
            settings.lockWidth, settings.lockHeight = DrawNumberPair(
                'Width',
                settings.lockWidth,
                'Height',
                settings.lockHeight,
                1,
                200,
                1,
                'TargetModuleLockWidth',
                'TargetModuleLockHeight'
            );
            settings.lockOffsetX, settings.lockOffsetY = DrawNumberPair(
                'Position X',
                settings.lockOffsetX,
                'Position Y',
                settings.lockOffsetY,
                -500,
                500,
                1,
                'TargetModuleLockX',
                'TargetModuleLockY'
            );
            settings.lockColor = DrawColor('Lock-on tint', settings.lockColor);
            uiTooltip.Info('Shown on the target marker while lock-on is active.');
        end
    end

    imgui.Separator();
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Chevrons');
    settings.chevronEnabled = DrawToggle('Show chevrons', settings.chevronEnabled ~= false);
    settings.chevronFile = DrawFile('Chevron image', 'chevrons', settings.chevronFile);

    if (settings.chevronEnabled ~= false and tostring(settings.chevronFile or 'None') ~= 'None') then
        settings.chevronWidth, settings.chevronHeight = DrawNumberPair(
            'Width',
            settings.chevronWidth,
            'Height',
            settings.chevronHeight,
            8,
            200,
            1,
            'TargetModuleChevronsWidth',
            'TargetModuleChevronsHeight'
        );
        settings.autoPlaceChevrons = DrawToggle('Auto place chevrons', settings.autoPlaceChevrons ~= false);
        uiTooltip.Info('When enabled, chevrons are placed outside the full measured plate width for the current enemy state. Chevron spacing then adds extra distance outward from that edge. Turn it off only when you want to shift chevrons manually with Chevrons X.');
        if (settings.autoPlaceChevrons ~= false) then
            settings.chevronAutoPlaceAnchor = DrawOption('Auto place by', autoPlaceAnchorOptions, settings.chevronAutoPlaceAnchor or 'Widest element', 'TargetModuleChevronsAnchorMode');
        end
        settings.chevronSpacing = DrawNumber('Chevron spacing', settings.chevronSpacing, 0, 900, 5, 'TargetModuleChevronsSpacing');

        if (settings.autoPlaceChevrons == false) then
            settings.chevronOffsetX = DrawNumber('Position X', settings.chevronOffsetX, -350, 350, 5, 'TargetModuleChevronsX');
        end

        settings.chevronOffsetY = DrawNumber('Position Y', settings.chevronOffsetY, -500, 500, 5, 'TargetModuleChevronsY');
        settings.chevronColor = DrawColor('Chevron tint', settings.chevronColor);
    end

    imgui.Separator();

    if (DrawActionButton('Reset ' .. label .. ' position') == true) then
        settings.backgroundOffsetX = defaults.backgroundOffsetX;
        settings.backgroundOffsetY = defaults.backgroundOffsetY;
        settings.arrowOffsetX = defaults.arrowOffsetX;
        settings.arrowOffsetY = defaults.arrowOffsetY;
        settings.lockOffsetX = defaults.lockOffsetX;
        settings.lockOffsetY = defaults.lockOffsetY;
        settings.chevronOffsetX = defaults.chevronOffsetX;
        settings.chevronOffsetY = defaults.chevronOffsetY;
        settings.chevronSpacing = defaults.chevronSpacing;
        settings.autoPlaceChevrons = defaults.autoPlaceChevrons;
        settings.backgroundAutoPlaceAnchor = defaults.backgroundAutoPlaceAnchor or 'Widest element';
        settings.chevronAutoPlaceAnchor = defaults.chevronAutoPlaceAnchor or 'Widest element';
    end

    if (DrawActionButton('Reset ' .. label .. ' settings') == true) then
        CopyDefaults(settings, defaults);
    end
end

return targetModule;
