local base = {
    enabled = true,
    width = 500,
    height = 250,
    offsetX = 0,
    offsetY = 0,
    texture = 'None',
    bstArtworkOpacity = 100,
    color = { 0.0, 0.0, 0.0, 0.0 },
    borderColor = { 0.0, 0.0, 0.0, 0.0 },
    borderSize = 0,

    bstNameSettings = {
        enabled = true,
        textSize = 22,
        color = { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = true,
        outlineColor = { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = 2,
        offsetX = 85,
        offsetY = -72,
        anchorTo = 'Plate',
        anchorPoint = 'Center',
    },
    bstHpBarSettings = {
        enabled = true,
        width = 250,
        height = 14,
        offsetX = 85,
        offsetY = -42,
        color = { 0.20, 0.95, 0.34, 0.95 },
        backgroundColor = { 0.02, 0.02, 0.02, 0.70 },
        borderColor = { 0.0, 0.0, 0.0, 1.0 },
        borderSize = 0,
        cornerRadius = 3,
        texture = 'Solid',
        textureStrength = 100,
        showValue = false,
        showPercent = true,
        showAtPercent = 100,
        lowColorEnabled = true,
        lowColorPercent = 25,
        lowColor = { 1.0, 0.15, 0.10, 1.0 },
        lowAnimationEnabled = false,
        lowAnimation = 'Important',
        lowAnimationSpeed = 40,
        lowAnimationColor = { 1.0, 1.0, 1.0, 0.35 },
        textOffsetX = 0,
        textOffsetY = 0,
        useSmallFont = true,
        fontSize = 8,
        textColor = { 1.0, 1.0, 1.0, 1.0 },
        textOutlineEnabled = true,
        textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
        textOutlineSize = 1,
        anchorTo = 'Plate',
        anchorPoint = 'Center',
    },
    bstTpBarSettings = {
        enabled = true,
        width = 250,
        height = 9,
        offsetX = 85,
        offsetY = -17,
        color = { 1.0, 0.70, 0.18, 1.0 },
        color2 = { 0.80, 0.45, 1.0, 0.95 },
        color3 = { 0.35, 0.75, 1.0, 0.95 },
        fullColor = { 1.0, 0.70, 0.18, 1.0 },
        backgroundColor = { 0.02, 0.02, 0.02, 0.70 },
        borderColor = { 0.0, 0.0, 0.0, 1.0 },
        borderSize = 0,
        cornerRadius = 3,
        texture = 'Solid',
        textureStrength = 100,
        showValue = false,
        showPercent = false,
        showAtPercent = 0,
        segmented = true,
        segmentGap = 4,
        textOffsetX = 0,
        textOffsetY = 0,
        useSmallFont = true,
        fontSize = 7,
        textColor = { 1.0, 1.0, 1.0, 1.0 },
        textOutlineEnabled = true,
        textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
        textOutlineSize = 1,
        anchorTo = 'Plate',
        anchorPoint = 'Center',
    },
    bstEnmitySettings = {
        enabled = true,
        allyIconFile = 'warning-dimond.png',
        allyColor = { 1.0, 0.25, 0.20, 1.0 },
        allyOffsetX = 230,
        allyOffsetY = -78,
        allyIconSize = 30,
    },
    bstPetTimerSettings = {
        enabled = true,
        displayMode = 'Text',
        iconSize = 24,
        labelOffsetX = 0,
        labelOffsetY = -13,
        textOffsetX = 0,
        textOffsetY = 10,
        textSize = 14,
        color = { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = true,
        outlineColor = { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = 2,
        offsetX = -88,
        offsetY = -10,
    },
    bstPetStateSettings = {
        enabled = true,
        displayMode = 'Icon',
        iconSize = 24,
        labelOffsetX = 0,
        labelOffsetY = 0,
        textSize = 12,
        color = { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = true,
        outlineColor = { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = 2,
        offsetX = 225,
        offsetY = 25,
    },
    bstActionSettings = {
        enabled = true,
        behindPlateArtwork = true,
        width = 52,
        height = 65,
        offsetX = -20,
        offsetY = 78,
        color = { 0.10, 0.55, 1.00, 1.0 },
        color2 = { 0.80, 0.45, 1.0, 0.95 },
        color3 = { 0.35, 0.75, 1.0, 0.95 },
        backgroundColor = { 0.02, 0.02, 0.02, 0.70 },
        borderColor = { 0.0, 0.0, 0.0, 0.0 },
        borderSize = 0,
        cornerRadius = 24,
        texture = 'Soft Gray',
        textureStrength = 100,
        fillDirection = 'Bottom to top',
        segmented = false,
        segmentLayout = 'Rows',
        segmentGap = 4,
        chargeSeconds = 30,
        labelDisplayMode = 'None',
        showValue = false,
        showPercent = true,
        showReadyTimer = true,
        showSicTimer = true,
        textOffsetX = 0,
        textOffsetY = 38,
        counterOffsetX = 0,
        counterOffsetY = 0,
        useSmallFont = true,
        fontSize = 10,
        textColor = { 1.0, 1.0, 1.0, 1.0 },
        textOutlineEnabled = true,
        textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
        textOutlineSize = 2,
    },
    bstRewardSettings = {
        enabled = true,
        behindPlateArtwork = true,
        width = 52,
        height = 65,
        offsetX = 80,
        offsetY = 78,
        color = { 0.95, 0.22, 0.16, 1.0 },
        backgroundColor = { 0.02, 0.02, 0.02, 0.70 },
        borderColor = { 0.0, 0.0, 0.0, 0.0 },
        borderSize = 0,
        cornerRadius = 24,
        texture = 'Soft Gray',
        textureStrength = 100,
        fillDirection = 'Bottom to top',
        labelDisplayMode = 'None',
        showValue = false,
        showPercent = true,
        showRewardTimer = true,
        textOffsetX = 0,
        textOffsetY = 38,
        useSmallFont = true,
        fontSize = 10,
        textColor = { 1.0, 1.0, 1.0, 1.0 },
        textOutlineEnabled = true,
        textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
        textOutlineSize = 2,
    },
};

local function Copy(value)
    if type(value) ~= 'table' then
        return value;
    end

    local result = {};
    for key, child in pairs(value) do
        result[key] = Copy(child);
    end
    return result;
end

return {
    GetJug = function()
        local result = Copy(base);
        result.bstArtworkFile = 'Jug-plate.png';
        result.bstArtworkOpacity = 100;
        result.bstPetState = 'Jug Pet';

        result.bstNameSettings.enabled = true;
        result.bstNameSettings.textSize = 20;
        result.bstNameSettings.color = { 0.331, 0.676, 0.329, 1.0 };
        result.bstNameSettings.outlineColor = { 0.015, 0.015, 0.015, 1.0 };
        result.bstNameSettings.outlineSize = 2;
        result.bstNameSettings.offsetX = 71;
        result.bstNameSettings.offsetY = -58;

        result.bstHpBarSettings.enabled = true;
        result.bstHpBarSettings.width = 200;
        result.bstHpBarSettings.height = 10;
        result.bstHpBarSettings.offsetX = 88;
        result.bstHpBarSettings.offsetY = -36;
        result.bstHpBarSettings.borderColor = { 0.336, 0.265, 0.265, 1.0 };
        result.bstHpBarSettings.borderSize = 1;
        result.bstHpBarSettings.cornerRadius = 6;
        result.bstHpBarSettings.texture = 'Solid';
        result.bstHpBarSettings.lowColorPercent = 50;
        result.bstHpBarSettings.lowAnimationEnabled = true;
        result.bstHpBarSettings.lowAnimation = 'Pulse';
        result.bstHpBarSettings.lowAnimationSpeed = 70;
        result.bstHpBarSettings.fontSize = 16;
        result.bstHpBarSettings.textOutlineSize = 3;

        result.bstTpBarSettings.enabled = true;
        result.bstTpBarSettings.width = 200;
        result.bstTpBarSettings.height = 9;
        result.bstTpBarSettings.offsetX = 88;
        result.bstTpBarSettings.offsetY = -19;
        result.bstTpBarSettings.cornerRadius = 6;
        result.bstTpBarSettings.texture = 'Solid';
        result.bstTpBarSettings.segmented = true;
        result.bstTpBarSettings.segmentGap = 8;
        result.bstTpBarSettings.showPercent = true;
        result.bstTpBarSettings.showValue = false;
        result.bstTpBarSettings.textOffsetX = 64;
        result.bstTpBarSettings.textOffsetY = 3;
        result.bstTpBarSettings.useSmallFont = false;
        result.bstTpBarSettings.fontSize = 15;
        result.bstTpBarSettings.textOutlineSize = 3;

        result.bstEnmitySettings.enabled = true;
        result.bstEnmitySettings.allyOffsetX = -7;
        result.bstEnmitySettings.allyOffsetY = -59;
        result.bstEnmitySettings.allyIconSize = 23;

        result.bstPetTimerSettings.enabled = true;
        result.bstPetTimerSettings.displayMode = 'Icon';
        result.bstPetTimerSettings.iconSize = 45;
        result.bstPetTimerSettings.labelOffsetX = -8;
        result.bstPetTimerSettings.labelOffsetY = -20;
        result.bstPetTimerSettings.textOffsetX = -7;
        result.bstPetTimerSettings.textOffsetY = 8;
        result.bstPetTimerSettings.textSize = 14;
        result.bstPetTimerSettings.outlineSize = 2;
        result.bstPetTimerSettings.offsetX = -78;
        result.bstPetTimerSettings.offsetY = -10;

        result.bstPetStateSettings.enabled = true;
        result.bstPetStateSettings.displayMode = 'Icon';
        result.bstPetStateSettings.iconSize = 30;
        result.bstPetStateSettings.offsetX = 0;
        result.bstPetStateSettings.offsetY = 0;

        result.bstActionSettings.enabled = true;
        result.bstActionSettings.behindPlateArtwork = true;
        result.bstActionSettings.width = 44;
        result.bstActionSettings.height = 48;
        result.bstActionSettings.offsetX = -27;
        result.bstActionSettings.offsetY = 83;
        result.bstActionSettings.color = { 0.981, 0.432, 0.0, 1.0 };
        result.bstActionSettings.borderColor = { 0.394, 0.182, 0.015, 0.0 };
        result.bstActionSettings.borderSize = 0;
        result.bstActionSettings.cornerRadius = 0;
        result.bstActionSettings.texture = 'Gloss Dark';
        result.bstActionSettings.textureStrength = 50;
        result.bstActionSettings.segmented = true;
        result.bstActionSettings.segmentLayout = 'Rows';
        result.bstActionSettings.segmentGap = 3;
        result.bstActionSettings.labelDisplayMode = 'Text';
        result.bstActionSettings.labelIconOffsetX = 12;
        result.bstActionSettings.labelIconOffsetY = 49;
        result.bstActionSettings.labelIconSize = 60;
        result.bstActionSettings.showPercent = true;
        result.bstActionSettings.showReadyTimer = true;
        result.bstActionSettings.textOffsetX = 0;
        result.bstActionSettings.textOffsetY = 0;
        result.bstActionSettings.counterOffsetX = -27;
        result.bstActionSettings.counterOffsetY = 46;
        result.bstActionSettings.fontSize = 14;
        result.bstActionSettings.textOutlineSize = 5;

        result.bstRewardSettings.enabled = true;
        result.bstRewardSettings.behindPlateArtwork = true;
        result.bstRewardSettings.width = 38;
        result.bstRewardSettings.height = 48;
        result.bstRewardSettings.offsetX = 77;
        result.bstRewardSettings.offsetY = 83;
        result.bstRewardSettings.borderColor = { 0.263, 0.193, 0.193, 0.0 };
        result.bstRewardSettings.borderSize = 4;
        result.bstRewardSettings.cornerRadius = 0;
        result.bstRewardSettings.texture = 'Soft Gray';
        result.bstRewardSettings.textureStrength = 100;
        result.bstRewardSettings.labelDisplayMode = 'Text';
        result.bstRewardSettings.labelIconOffsetX = 0;
        result.bstRewardSettings.labelIconOffsetY = 47;
        result.bstRewardSettings.showPercent = false;
        result.bstRewardSettings.showRewardTimer = true;
        result.bstRewardSettings.textOffsetX = 0;
        result.bstRewardSettings.textOffsetY = 0;
        result.bstRewardSettings.fontSize = 14;
        result.bstRewardSettings.textOutlineSize = 2;
        return result;
    end,
    GetCharmed = function()
        local result = Copy(base);
        result.bstArtworkFile = 'Charm-plate.png';
        result.bstPetState = 'Charmed Pet';
        result.bstActionSettings.segmented = false;
        result.bstActionSettings.showSicTimer = true;
        return result;
    end,
};
