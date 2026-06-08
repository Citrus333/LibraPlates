    if (peer.jobIconSize == nil) then peer.jobIconSize = 18; end
    EnsurePeerTextDefaults(peer, 'job', -190, -16);
end

local function EnsurePeerLevelDefaults(peer)
    if (peer.showLevel == nil) then peer.showLevel = true; end
    EnsurePeerTextDefaults(peer, 'level', -145, -16);
    if (peer.levelDifficultyColorsEnabled == nil) then peer.levelDifficultyColorsEnabled = false; end
    if (peer.levelTwColor == nil) then peer.levelTwColor = { 0.55, 0.55, 0.55, 1.0 }; end
    if (peer.levelEpColor == nil) then peer.levelEpColor = { 0.45, 0.72, 1.0, 1.0 }; end
    if (peer.levelDcColor == nil) then peer.levelDcColor = { 0.40, 0.90, 0.45, 1.0 }; end
    if (peer.levelEmColor == nil) then peer.levelEmColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (peer.levelTColor == nil) then peer.levelTColor = { 1.0, 0.90, 0.35, 1.0 }; end
    if (peer.levelVtColor == nil) then peer.levelVtColor = { 1.0, 0.62, 0.25, 1.0 }; end
    if (peer.levelItColor == nil) then peer.levelItColor = { 1.0, 0.30, 0.30, 1.0 }; end
end

local function EnsurePeerIconDefaults(peer, prefix, offsetX, offsetY)
    if (peer[prefix .. 'OffsetX'] == nil) then peer[prefix .. 'OffsetX'] = offsetX; end
    if (peer[prefix .. 'OffsetY'] == nil) then peer[prefix .. 'OffsetY'] = offsetY; end
    if (peer[prefix .. 'IconSize'] == nil) then peer[prefix .. 'IconSize'] = peer.iconSize or 18; end
end

local function EnsurePeerHpBarDefaults(peer)
    if (peer.showHpBar == nil) then peer.showHpBar = true; end
    if (peer.hpBarOffsetX == nil) then peer.hpBarOffsetX = 0; end
    if (peer.hpBarOffsetY == nil) then peer.hpBarOffsetY = 0; end
    if (peer.hpBarWidth == nil) then peer.hpBarWidth = 437; end
    if (peer.hpBarHeight == nil) then peer.hpBarHeight = 16; end
    if (peer.hpBarColor == nil) then peer.hpBarColor = { 0.0, 0.75, 0.16, 1.0 }; end
    if (peer.hpBarBackgroundColor == nil) then peer.hpBarBackgroundColor = { 0.05, 0.05, 0.05, 0.85 }; end
    if (peer.hpBarBorderSize == nil) then peer.hpBarBorderSize = 0; end
    if (peer.hpBarBorderColor == nil) then peer.hpBarBorderColor = { 0.0, 0.0, 0.0, 1.0 }; end
    if (peer.showHpPercent == nil) then peer.showHpPercent = true; end
    if (peer.hpPercentOffsetX == nil) then peer.hpPercentOffsetX = 0; end
    if (peer.hpPercentOffsetY == nil) then peer.hpPercentOffsetY = 0; end
    if (peer.hpPercentFontSize == nil) then peer.hpPercentFontSize = 12; end
    if (peer.hpPercentColor == nil) then peer.hpPercentColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (peer.hpPercentOutlineSize == nil) then peer.hpPercentOutlineSize = 2; end
    if (peer.hpPercentOutlineColor == nil) then peer.hpPercentOutlineColor = { 0.0, 0.0, 0.0, 1.0 }; end
end

local function EnsurePeerBackgroundDefaults(peer)
    peer.showBackground = true;
    if (peer.backgroundOffsetX == nil) then peer.backgroundOffsetX = 0; end
    if (peer.backgroundOffsetY == nil) then peer.backgroundOffsetY = 0; end
    if (peer.backgroundWidth == nil) then peer.backgroundWidth = 460; end
    if (peer.backgroundHeight == nil) then peer.backgroundHeight = 72; end
    if (peer.backgroundColor == nil) then peer.backgroundColor = { 0.0, 0.0, 0.0, 0.45 }; end
    if (peer.backgroundOpacity == nil) then peer.backgroundOpacity = math.floor(((tonumber(peer.backgroundColor[4]) or 0.45) * 100) + 0.5); end
    if (peer.backgroundBorderSize == nil) then peer.backgroundBorderSize = 0; end
    if (peer.backgroundBorderColor == nil) then peer.backgroundBorderColor = { 0.0, 0.0, 0.0, 1.0 }; end
end

local function EnsurePeerNameDefaults(peer)
    if (peer.showName == nil) then peer.showName = true; end
    if (peer.nameOffsetX == nil) then peer.nameOffsetX = 0; end
    if (peer.nameOffsetY == nil) then peer.nameOffsetY = -54; end
    if (peer.nameFontSize == nil) then peer.nameFontSize = 32; end
    if (peer.nameColor == nil) then peer.nameColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (peer.nameOutlineSize == nil) then peer.nameOutlineSize = 3; end
    if (peer.nameOutlineColor == nil) then peer.nameOutlineColor = { 0.0, 0.0, 0.0, 1.0 }; end
end

local function EnsurePeerIdDefaults(peer)
    if (peer.showId == nil) then peer.showId = false; end
    if (peer.idOffsetX == nil) then peer.idOffsetX = 0; end
    if (peer.idOffsetY == nil) then peer.idOffsetY = 24; end
    if (peer.idFontSize == nil) then peer.idFontSize = 7; end
    if (peer.idColor == nil) then peer.idColor = { 0.65, 0.90, 1.0, 1.0 }; end
    if (peer.idOutlineSize == nil) then peer.idOutlineSize = 2; end
    if (peer.idOutlineColor == nil) then peer.idOutlineColor = { 0.0, 0.0, 0.0, 1.0 }; end
    if (peer.idBoxEnabled == nil) then peer.idBoxEnabled = true; end
    if (peer.idBoxSize == nil) then peer.idBoxSize = 18; end
    if (peer.idBoxColor == nil) then peer.idBoxColor = { 0.45, 0.15, 0.15, 0.90 }; end
    if (peer.idBoxBorderSize == nil) then peer.idBoxBorderSize = 0; end
    if (peer.idBoxBorderColor == nil) then peer.idBoxBorderColor = { 1.0, 1.0, 1.0, 1.0 }; end
    if (peer.idCornerRadius == nil) then peer.idCornerRadius = 4; end
end

local function DrawPeerActive(activeKey, settings)
    DrawCheckbox('Active', settings.peer[activeKey] == true, function(value)
        settings.peer[activeKey] = value == true;
        state.Save();
    end);
end

local function DrawPeerTextComponentSettings(settings, activeKey, prefix, label)
    local peer = settings.peer;

    DrawPeerActive(activeKey, settings);

    if (peer[activeKey] ~= true) then
        return;
    end

    local x, xChanged, y, yChanged = DrawPlacementPair('Position X', peer[prefix .. 'OffsetX'], 'Peer' .. label .. 'X', 'Position Y', peer[prefix .. 'OffsetY'], 'Peer' .. label .. 'Y', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        peer[prefix .. 'OffsetX'] = x;
        peer[prefix .. 'OffsetY'] = y;
        state.Save();
    end

    DrawPeerFontRow(peer, prefix, label);
    DrawPeerOutlineRow(peer, prefix, label);
end

local function DrawPeerDifficultyColorInline(peer, label, key, colorId, continueLine)
    imgui.TextColored(peer[key] or { 1.0, 1.0, 1.0, 1.0 }, label);
    imgui.SameLine();

    local nextColor, changed = DrawInlineColorControl(peer[key], colorId);
    peer[key] = nextColor;
    if (changed == true) then state.Save(); end

    if (continueLine == true) then
        imgui.SameLine();
    end
end

local function DrawPeerLevelComponentSettings(settings)
    local peer = settings.peer;

    DrawPeerTextComponentSettings(settings, 'showLevel', 'level', 'Level');

    if (peer.showLevel ~= true) then
        return;
    end

    imgui.Separator();
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Difficulty font colors');

    DrawCheckbox('Use difficulty font colors', peer.levelDifficultyColorsEnabled == true, function(value)
        peer.levelDifficultyColorsEnabled = value == true;
        state.Save();
    end);

    if (peer.levelDifficultyColorsEnabled == true) then
        DrawPeerDifficultyColorInline(peer, 'TW', 'levelTwColor', 'PeerLevelTwColor', true);
        DrawPeerDifficultyColorInline(peer, 'EP', 'levelEpColor', 'PeerLevelEpColor', true);
        DrawPeerDifficultyColorInline(peer, 'DC', 'levelDcColor', 'PeerLevelDcColor', true);
        DrawPeerDifficultyColorInline(peer, 'EM', 'levelEmColor', 'PeerLevelEmColor', true);
        DrawPeerDifficultyColorInline(peer, 'T', 'levelTColor', 'PeerLevelTColor', true);
        DrawPeerDifficultyColorInline(peer, 'VT', 'levelVtColor', 'PeerLevelVtColor', true);
        DrawPeerDifficultyColorInline(peer, 'IT', 'levelItColor', 'PeerLevelItColor', false);
    end
end

local function DrawSmallComboControl(id, items, selected, onSelect)
    local current = tostring(selected or items[1] or 'Default');
    local comboId = '##' .. tostring(id or 'combo');

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then imgui.PushItemWidth(124); end

        if (imgui.BeginCombo(comboId, current) == true) then
            for _, item in ipairs(items) do
                local isSelected = item == current;

                if (imgui.Selectable(tostring(item), isSelected) == true) then
                    onSelect(item);
                end

                if (isSelected == true and imgui.SetItemDefaultFocus ~= nil) then
                    imgui.SetItemDefaultFocus();
                end
            end

            imgui.EndCombo();
        end

        if (imgui.PopItemWidth ~= nil) then imgui.PopItemWidth(); end
        return;
    end

    imgui.TextColored({ 0.92, 0.92, 0.90, 1.0 }, '[' .. current .. ' v]');

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        local nextIndex = 1;

        for i, item in ipairs(items) do
            if (item == current) then
                nextIndex = i + 1;
                break;
            end
        end

        if (nextIndex > #items) then nextIndex = 1; end
        onSelect(items[nextIndex]);
    end
end

local function DrawPeerJobDisplayRow(peer)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local iconMode = tostring(peer.jobDisplay or 'Text') == 'Icon';
        local columnCount = iconMode == true and 4 or 2;

        if (imgui.BeginTable('##peer_job_display_row', columnCount, settingsTableFlags)) then
            imgui.TableSetupColumn('##display_label', 0, 104);
            imgui.TableSetupColumn('##display_control', 0, 124);

            if (iconMode == true) then
                imgui.TableSetupColumn('##theme_label', 0, 104);
                imgui.TableSetupColumn('##theme_control', 0, 124);
            end

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(settingsLabelColor, 'Display');
            imgui.TableNextColumn();
            DrawSmallComboControl('PeerJobDisplay', T{ 'Text', 'Icon' }, peer.jobDisplay or 'Text', function(value)
                peer.jobDisplay = value;
                state.Save();
            end);

            if (iconMode == true) then
                imgui.TableNextColumn();
                imgui.TextColored(settingsLabelColor, 'Icon theme');
                imgui.TableNextColumn();
                DrawSmallComboControl('PeerJobIconTheme', jobIconTextures.GetThemeNames(), peer.jobIconTheme or 'FFXI', function(value)
                    peer.jobIconTheme = value;
                    state.Save();
                end);
            end

            imgui.EndTable();
        end

        return;
    end

    DrawInlineComboRow('Display', T{ 'Text', 'Icon' }, peer.jobDisplay or 'Text', function(value)
        peer.jobDisplay = value;
        state.Save();
    end, 'PeerJobDisplay');

    if (tostring(peer.jobDisplay or 'Text') == 'Icon') then
        DrawInlineComboRow('Icon theme', jobIconTextures.GetThemeNames(), peer.jobIconTheme or 'FFXI', function(value)
            peer.jobIconTheme = value;
            state.Save();
        end, 'PeerJobIconTheme');
    end
end

local function DrawPeerJobComponentSettings(settings)
    local peer = settings.peer;

    DrawPeerActive('showJob', settings);

    if (peer.showJob ~= true) then
        return;
    end

    DrawPeerJobDisplayRow(peer);

    local x, xChanged, y, yChanged = DrawPlacementPair('Position X', peer.jobOffsetX, 'PeerJobX', 'Position Y', peer.jobOffsetY, 'PeerJobY', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        peer.jobOffsetX = x;
        peer.jobOffsetY = y;
        state.Save();
    end

    if (tostring(peer.jobDisplay or 'Text') == 'Icon') then
        local iconSize, iconSizeChanged = DrawPlacementSingle('Icon size', peer.jobIconSize, 'PeerJobIconSize', 6, 160, 1);
        if (iconSizeChanged == true) then
            peer.jobIconSize = iconSize;
            state.Save();
        end
    else
        DrawPeerFontRow(peer, 'job', 'Job');
        DrawPeerOutlineRow(peer, 'job', 'Job');
    end
end

local function DrawPeerIconComponentSettings(settings, activeKey, prefix, label)
    local peer = settings.peer;

    DrawPeerActive(activeKey, settings);

    if (peer[activeKey] ~= true) then
        return;
    end

    local x, xChanged, y, yChanged = DrawPlacementPair('Position X', peer[prefix .. 'OffsetX'], 'Peer' .. label .. 'X', 'Position Y', peer[prefix .. 'OffsetY'], 'Peer' .. label .. 'Y', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        peer[prefix .. 'OffsetX'] = x;
        peer[prefix .. 'OffsetY'] = y;
        state.Save();
    end

    local iconSize, iconSizeChanged = DrawPlacementSingle('Icon size', peer[prefix .. 'IconSize'], 'Peer' .. label .. 'IconSize', 6, 64, 1, 104, 124, 58);
    if (iconSizeChanged == true) then
        peer[prefix .. 'IconSize'] = iconSize;
        state.Save();
    end
end

local function DrawPeerHpBarComponentSettings(settings)
    local peer = settings.peer;

    DrawPeerActive('showHpBar', settings);

    if (peer.showHpBar ~= true) then
        return;
    end

    local x, xChanged, y, yChanged = DrawPlacementPair('HP bar X', peer.hpBarOffsetX, 'PeerHpBarX', 'HP bar Y', peer.hpBarOffsetY, 'PeerHpBarY', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        peer.hpBarOffsetX = x;
        peer.hpBarOffsetY = y;
        state.Save();
    end

    local width, widthChanged, height, heightChanged = DrawPlacementPair('Width', peer.hpBarWidth, 'PeerHpBarWidth', 'Height', peer.hpBarHeight, 'PeerHpBarHeight', 1, 900, 1);
    if (widthChanged == true or heightChanged == true) then
        peer.hpBarWidth = width;
        peer.hpBarHeight = height;
        state.Save();
    end

    local fillColor, fillChanged = DrawSettingsColor('Fill color', peer.hpBarColor, 'PeerHpBarColor');
    peer.hpBarColor = fillColor;
    if (fillChanged == true) then state.Save(); end

    local bgColor, bgChanged = DrawSettingsColor('Background color', peer.hpBarBackgroundColor, 'PeerHpBarBackgroundColor');
    peer.hpBarBackgroundColor = bgColor;
    if (bgChanged == true) then state.Save(); end

    local borderColor, borderChanged = DrawSettingsColor('Border color', peer.hpBarBorderColor, 'PeerHpBarBorderColor');
    peer.hpBarBorderColor = borderColor;
    if (borderChanged == true) then state.Save(); end

    local borderSize, borderSizeChanged = DrawPlacementSingle('Border size', peer.hpBarBorderSize, 'PeerHpBarBorderSize', 0, 24, 1);
    if (borderSizeChanged == true) then
        peer.hpBarBorderSize = borderSize;
        state.Save();
    end

    imgui.Separator();
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'HP percent');

    DrawCheckbox('Active', peer.showHpPercent == true, function(value)
        peer.showHpPercent = value == true;
        state.Save();
    end);

    if (peer.showHpPercent == true) then
        local tx, txChanged, ty, tyChanged = DrawPlacementPair('Percent X', peer.hpPercentOffsetX, 'PeerHpPercentX', 'Percent Y', peer.hpPercentOffsetY, 'PeerHpPercentY', -500, 500, 1);
        if (txChanged == true or tyChanged == true) then
            peer.hpPercentOffsetX = tx;
            peer.hpPercentOffsetY = ty;
            state.Save();
        end

        local fontSize, fontSizeChanged = DrawPlacementSingle('Font size', textScale.NormalizeSetting(peer.hpPercentFontSize, 12), 'PeerHpPercentFontSize', textScale.GetMinVisualSize(), textScale.GetMaxVisualSize(), 1);
        if (fontSizeChanged == true) then
            peer.hpPercentFontSize = fontSize;
            state.Save();
        end

        local textColor, textColorChanged = DrawSettingsColor('Font color', peer.hpPercentColor, 'PeerHpPercentColor');
        peer.hpPercentColor = textColor;
        if (textColorChanged == true) then state.Save(); end

        local outlineColor, outlineColorChanged = DrawSettingsColor('Outline color', peer.hpPercentOutlineColor, 'PeerHpPercentOutlineColor');
        peer.hpPercentOutlineColor = outlineColor;
        if (outlineColorChanged == true) then state.Save(); end

        local outlineSize, outlineSizeChanged = DrawPlacementSingle('Outline size', peer.hpPercentOutlineSize, 'PeerHpPercentOutlineSize', 0, 12, 1);
        if (outlineSizeChanged == true) then
            peer.hpPercentOutlineSize = outlineSize;
            state.Save();
        end
    end
end

local function DrawPeerBackgroundComponentSettings(settings)
    local peer = settings.peer;

    peer.showBackground = true;

    local width, widthChanged, height, heightChanged = DrawPlacementPair('Width', peer.backgroundWidth, 'PeerBackgroundWidth', 'Height', peer.backgroundHeight, 'PeerBackgroundHeight', 1, 900, 1);
    if (widthChanged == true or heightChanged == true) then
        peer.backgroundWidth = width;
        peer.backgroundHeight = height;
        state.Save();
    end

    local x, xChanged, y, yChanged = DrawPlacementPair('Position X', peer.backgroundOffsetX, 'PeerBackgroundX', 'Position Y', peer.backgroundOffsetY, 'PeerBackgroundY', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        peer.backgroundOffsetX = x;
        peer.backgroundOffsetY = y;
        state.Save();
    end

    local fillColor, fillChanged, opacity, opacityChanged = DrawColorAndPlacementRow('Fill color', peer.backgroundColor, 'PeerBackgroundColor', 'Opacity', peer.backgroundOpacity, 'PeerBackgroundOpacity', 0, 100, 1);
    fillColor[4] = 1.0;
    peer.backgroundColor = fillColor;
    if (fillChanged == true or opacityChanged == true) then
        peer.backgroundOpacity = opacity;
        state.Save();
    end

    local borderColor, borderChanged, borderSize, borderSizeChanged = DrawColorAndPlacementRow('Border color', peer.backgroundBorderColor, 'PeerBackgroundBorderColor', 'Border size', peer.backgroundBorderSize, 'PeerBackgroundBorderSize', 0, 24, 1);
    peer.backgroundBorderColor = borderColor;
    if (borderChanged == true or borderSizeChanged == true) then
        peer.backgroundBorderSize = borderSize;
        state.Save();
    end
end

local function DrawPeerIdComponentSettings(settings)
    local peer = settings.peer;

    DrawPeerActive('showId', settings);

    if (peer.showId ~= true) then
        return;
    end

    local x, xChanged, y, yChanged = DrawPlacementPair('Position X', peer.idOffsetX, 'PeerIdX', 'Position Y', peer.idOffsetY, 'PeerIdY', -500, 500, 1);
    if (xChanged == true or yChanged == true) then
        peer.idOffsetX = x;
        peer.idOffsetY = y;
        state.Save();
    end

    DrawPeerFontRow(peer, 'id', 'Id');
    DrawPeerOutlineRow(peer, 'id', 'Id');

    imgui.Separator();
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'ID box');

    DrawCheckbox('Active', peer.idBoxEnabled == true, function(value)
        peer.idBoxEnabled = value == true;
        state.Save();
    end);

    if (peer.idBoxEnabled == true) then
        local boxColor, boxColorChanged, boxSize, boxSizeChanged = DrawColorAndPlacementRow('Box color', peer.idBoxColor, 'PeerIdBoxColor', 'Box size', peer.idBoxSize, 'PeerIdBoxSize', 4, 160, 1);
        peer.idBoxColor = boxColor;
        if (boxColorChanged == true or boxSizeChanged == true) then
            peer.idBoxSize = boxSize;
            state.Save();
        end

        local borderColor, borderColorChanged, borderSize, borderSizeChanged = DrawColorAndPlacementRow('Border color', peer.idBoxBorderColor, 'PeerIdBoxBorderColor', 'Border size', peer.idBoxBorderSize, 'PeerIdBoxBorderSize', 0, 24, 1);
        peer.idBoxBorderColor = borderColor;
        if (borderColorChanged == true or borderSizeChanged == true) then
            peer.idBoxBorderSize = borderSize;
            state.Save();
        end

        local cornerRadius, cornerRadiusChanged = DrawPlacementSingle('Corner radius', peer.idCornerRadius, 'PeerIdCornerRadius', 0, 40, 1);
        if (cornerRadiusChanged == true) then
            peer.idCornerRadius = cornerRadius;
            state.Save();
        end
    end
end

function LibraPlatesSettingsEnsurePeerInspectorDefaults(peer)
    if (peer.displayMode == nil) then peer.displayMode = 'Text'; end
    if (peer.textFontSize == nil) then peer.textFontSize = 14; end
    if (peer.textColor == nil) then peer.textColor = { 0.94, 0.94, 0.90, 1.0 }; end
    if (peer.textOutlineSize == nil) then peer.textOutlineSize = 1; end
    if (peer.textOutlineColor == nil) then peer.textOutlineColor = { 0.0, 0.0, 0.0, 1.0 }; end
    if (peer.showName == nil) then peer.showName = true; end
    if (peer.showLevel == nil) then peer.showLevel = true; end
    if (peer.showHpValue == nil) then peer.showHpValue = true; end
    if (peer.showDistance == nil) then peer.showDistance = peer.showRange ~= false; end
    if (peer.showBehavior == nil) then peer.showBehavior = peer.showAggro ~= false; end
    if (peer.showDetects == nil) then peer.showDetects = peer.showDetection ~= false; end
    if (peer.showLinks == nil) then peer.showLinks = peer.showDetection ~= false; end
    if (peer.showWeakTo == nil) then peer.showWeakTo = peer.showModifiers ~= false; end
    if (peer.showResists == nil) then peer.showResists = peer.showModifiers ~= false; end
end

function LibraPlatesSettingsDrawPeerInspectorBackgroundSettings(peer)
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Background');

    local fillColor, fillChanged, opacity, opacityChanged = DrawColorAndPlacementRow('Fill color', peer.backgroundColor, 'PeerInspectorBackgroundColor', 'Opacity', peer.backgroundOpacity, 'PeerInspectorBackgroundOpacity', 0, 100, 1);
    fillColor[4] = 1.0;
    peer.backgroundColor = fillColor;
    if (fillChanged == true or opacityChanged == true) then
        peer.backgroundOpacity = opacity;
        state.Save();
    end

    local borderColor, borderChanged, borderSize, borderSizeChanged = DrawColorAndPlacementRow('Border color', peer.backgroundBorderColor, 'PeerInspectorBorderColor', 'Border size', peer.backgroundBorderSize, 'PeerInspectorBorderSize', 0, 12, 1);
    peer.backgroundBorderColor = borderColor;
    if (borderChanged == true or borderSizeChanged == true) then
        peer.backgroundBorderSize = borderSize;
        state.Save();
    end
end

function LibraPlatesSettingsDrawPeerSectionCheckbox(peer, label, key)
    DrawCheckbox(label, peer[key] ~= false, function(value)
        peer[key] = value == true;
        state.Save();
    end);
end

function LibraPlatesSettingsDrawPeerSectionList(peer)
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Sections');
