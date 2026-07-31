local imgui = require('imgui');

local helpTroubleshooter = {};
local expandedTitle = nil;

function helpTroubleshooter.Draw(entries, context)
    entries = entries or {};
    context = context or {};

    if (context.drawBreadcrumb ~= nil) then
        context.drawBreadcrumb();
    end

    if (context.drawHeader ~= nil) then
        context.drawHeader('Checklists');
    end

    imgui.TextWrapped('Choose a topic to see its checklist.');
    imgui.Spacing();

    for row, entry in ipairs(entries) do
        local title = tostring(entry.title or 'Troubleshooter');
        local expanded = expandedTitle == title;

        if (imgui.Button ~= nil and imgui.Button((expanded and 'Hide ' or 'Show ') .. title .. '##TroubleshooterToggle' .. tostring(row)) == true) then
            expandedTitle = expanded and nil or title;
            expanded = not expanded;
        end

        if (expanded == true) then
            imgui.TextColored({ 0.65, 0.90, 1.0, 1.0 }, tostring(entry.path or ''));

            for _, check in ipairs(entry.checks or {}) do
                imgui.TextWrapped('- ' .. tostring(check));
            end

            if (entry.tab ~= nil and imgui.Button ~= nil and imgui.Button('Go to ' .. tostring(entry.tab) .. '##TroubleshooterGo' .. tostring(row)) == true) then
                if (context.goTo ~= nil) then
                    context.goTo(entry);
                end
            end
        end

        imgui.Separator();
    end
end

return helpTroubleshooter;
