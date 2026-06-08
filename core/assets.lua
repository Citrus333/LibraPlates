local assets = {};

local root = addon.path .. '\\assets';

-- ============================================================
-- Path helpers
-- ============================================================

function assets.Path(...)
    local parts = { root };

    for _, part in ipairs({ ... }) do
        table.insert(parts, tostring(part));
    end

    return table.concat(parts, '\\');
end

-- ============================================================
-- Asset groups
-- ============================================================

function assets.Icon(fileName)
    return assets.Path('icons', fileName);
end

function assets.JobIcon(theme, job)
    return assets.Path('jobs', tostring(theme):lower(), tostring(job):lower() .. '.png');
end

function assets.StatusIcon(theme, statusId)
    return assets.Path('status', tostring(theme):lower(), tostring(statusId) .. '.png');
end

function assets.BarFill(fileName)
    return assets.Path('bars', 'fills', fileName);
end

return assets;
