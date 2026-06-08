local outputPath = arg[1] or 'TEMP WORK FOLDER/npc_type_audit.txt';
local csvPath = arg[2] or 'TEMP WORK FOLDER/npc_type_audit.csv';

function T(t)
    return t;
end

local sources = {
    { key = 'catseye_npc', path = 'data/catseye_npc_icons.lua', custom = true },
    { key = 'npc', path = 'data/npc_icons.lua', custom = false },
    { key = 'catseye_item', path = 'data/catseye_item_icons.lua', custom = true },
    { key = 'item', path = 'data/item_icons.lua', custom = false },
    { key = 'legacy_wiki', path = 'data/generated/wiki_legacy_npcs.lua', custom = false },
    { key = 'current_wiki', path = 'data/generated/wiki_current_npcs.lua', custom = false },
};

local bgTypes = {
    ['Advanced Synthesis Image Support'] = true,
    ['Airship Dock Vendor'] = true,
    ['Airship Timer NPC'] = true,
    ['Allegiance Changer'] = true,
    ['Armor Storage NPCs'] = true,
    ['Armor Vendor'] = true,
    ['Assault NPC'] = true,
    ['Assault Personnel'] = true,
    ['Auction House Rep.'] = true,
    ['Campaign Battle NPCs'] = true,
    ['Chocobo NPC'] = true,
    ['Conquest NPC'] = true,
    ['Consulate Rep.'] = true,
    ['Cutscene NPC'] = true,
    ['Cutscene Replay'] = true,
    ['Delivery Box NPC'] = true,
    ['ENM NPC'] = true,
    ['Event Storage NPC'] = true,
    ['Fame NPC'] = true,
    ['Ferry NPCs'] = true,
    ['Ferry Ticket NPC'] = true,
    ['Ferry Timer NPC'] = true,
    ['Gate Guard'] = true,
    ['Guild Master'] = true,
    ['Guild NPC'] = true,
    ['Guild Union Representative'] = true,
    ['Guild Vendor'] = true,
    ['Imperial Standing NPC'] = true,
    ['Information NPC'] = true,
    ['Item Vendor'] = true,
    ['Linkshell NPC'] = true,
    ['Lucky Roll NPC'] = true,
    ['Map Vendor'] = true,
    ['Map Viewer'] = true,
    ['Marshal'] = true,
    ['Mentor NPC'] = true,
    ['Mission NPC'] = true,
    ['Mog House NPC'] = true,
    ['Moogle'] = true,
    ['Other NPC'] = true,
    ['Pet Item Vendor'] = true,
    ['Proto-Waypoint NPC'] = true,
    ['Pursuivant'] = true,
    ['Quest Guide NPCs'] = true,
    ['Quest NPC'] = true,
    ['Records of Eminence NPC'] = true,
    ['Regional Vendor'] = true,
    ['RSE Vendor'] = true,
    ['Scroll Vendor'] = true,
    ['Seasonal Event NPC'] = true,
    ['Synthesis Image Support'] = true,
    ['Teleport NPC'] = true,
    ['Tenshodo Vendor'] = true,
    ['Title NPC'] = true,
    ['VCS Chocobo NPC'] = true,
    ['Weather Forecast'] = true,
    ['Weapon Vendor'] = true,
    ['World Pass NPC'] = true,
};

local suggestions = {
    ['Adventurer\'s Assistant'] = 'Information NPC',
    ['Adventurer\'s Assistant NPC'] = 'Information NPC',
    ['Auction House'] = 'Auction House Rep.',
    ['Auction House Rep'] = 'Auction House Rep.',
    ['Campaign Arbiter'] = 'Campaign Battle NPCs',
    ['Campaign Battle NPC'] = 'Campaign Battle NPCs',
    ['Chocobo Renter'] = 'Chocobo NPC',
    ['Conquest Overseer'] = 'Conquest NPC',
    ['Delivery NPC'] = 'Delivery Box NPC',
    ['Deliverer'] = 'Delivery Box NPC',
    ['Dialogue NPC'] = 'Other NPC',
    ['Event Item Storer'] = 'Event Storage NPC',
    ['Event NPC'] = 'Seasonal Event NPC',
    ['Ferry Ticket'] = 'Ferry Ticket NPC',
    ['Guild Merchant'] = 'Guild Vendor',
    ['Imperial Gate Guard'] = 'Imperial Standing NPC',
    ['Information'] = 'Information NPC',
    ['Item Deliverer'] = 'Delivery Box NPC',
    ['Item Storage'] = 'Armor Storage NPCs',
    ['Map NPC'] = 'Map Vendor',
    ['Map Marker'] = 'Map Viewer',
    ['Mog House'] = 'Mog House NPC',
    ['Mog House Guide'] = 'Mog House NPC',
    ['Outpost Teleporter'] = 'Teleport NPC',
    ['Outpost Teleporter NPC'] = 'Teleport NPC',
    ['Outpost Vendor'] = 'Regional Vendor',
    ['Quest Associate'] = 'Quest NPC',
    ['Quest Giver'] = 'Quest NPC',
    ['Quest Giver NPC'] = 'Quest NPC',
    ['Quest Starter'] = 'Quest NPC',
    ['Records of Eminence'] = 'Records of Eminence NPC',
    ['Armor Merchant'] = 'Armor Vendor',
    ['Regional Merchant'] = 'Regional Vendor',
    ['Scroll Merchant'] = 'Scroll Vendor',
    ['Synthesis Support'] = 'Synthesis Image Support',
    ['Tenshodo Merchant'] = 'Tenshodo Vendor',
    ['Teleporter'] = 'Teleport NPC',
    ['Title Changer'] = 'Title NPC',
    ['Traveling Bard'] = 'Title NPC',
    ['Trust Coordinator'] = 'Other NPC',
    ['Tutorial NPC'] = 'Information NPC',
    ['Warp NPC'] = 'Teleport NPC',
    ['Weather Checker'] = 'Weather Forecast',
    ['Weapon Merchant'] = 'Weapon Vendor',
    ['Wildcat Recruiter'] = 'Quest NPC',
};

local vendorTypes = {
    ['Armor Vendor'] = true,
    ['Item Vendor'] = true,
    ['Pet Item Vendor'] = true,
    ['RSE Vendor'] = true,
    ['Regional Vendor'] = true,
    ['Scroll Vendor'] = true,
    ['Tenshodo Vendor'] = true,
    ['Weapon Vendor'] = true,
};

local function IsVendorish(typeName)
    typeName = tostring(typeName or '');

    return typeName:find('Vendor', 1, true) ~= nil
        or typeName:find('Merchant', 1, true) ~= nil
        or typeName:find('Shop', 1, true) ~= nil
        or typeName:find('Armorer', 1, true) ~= nil;
end

local function GetVendorSuggestion(typeName)
    typeName = tostring(typeName or '');

    if (vendorTypes[typeName] == true) then
        return typeName;
    end

    if (typeName:find('Tenshodo', 1, true) ~= nil) then
        return 'Tenshodo Vendor';
    end

    if (typeName:find('Regional', 1, true) ~= nil or typeName:find('Outpost', 1, true) ~= nil) then
        return 'Regional Vendor';
    end

    if (typeName:find('Scroll', 1, true) ~= nil) then
        return 'Scroll Vendor';
    end

    if (typeName:find('RSE', 1, true) ~= nil) then
        return 'RSE Vendor';
    end

    if (typeName:find('Pet Item', 1, true) ~= nil) then
        return 'Pet Item Vendor';
    end

    if (typeName:find('Weapon', 1, true) ~= nil or typeName:find('Weapons', 1, true) ~= nil or typeName:find('Armorer', 1, true) ~= nil) then
        return 'Weapon Vendor';
    end

    if (typeName:find('Armor', 1, true) ~= nil or typeName:find('Armour', 1, true) ~= nil) then
        return 'Armor Vendor';
    end

    return '';
end

local customKeep = {
    ['Aether Traveler'] = true,
    ['AF+1 Augments'] = true,
    ['AP Shop & Warp'] = true,
    ['Assault Gear'] = true,
    ['Beastcoin Exchange'] = true,
    ['Curio Shop'] = true,
    ['Daily Box'] = true,
    ['Daily Shard Rewards'] = true,
    ['Domain Warp'] = true,
    ['Dynamis Storage'] = true,
    ['EXP Guide'] = true,
    ['EXP Guide (S)'] = true,
    ['EXP Ventures'] = true,
    ['Fish Exchange'] = true,
    ['Gear Upgrades'] = true,
    ['GM'] = true,
    ['HELM Vendor'] = true,
    ['Helper Rewards'] = true,
    ['Imperial Marks'] = true,
    ['Imperial Rank'] = true,
    ['Incursion Exchange'] = true,
    ['Incursion Warp'] = true,
    ['Item Collections'] = true,
    ['Item Recycling'] = true,
    ['JSE Weapons'] = true,
    ['Junk Exchange'] = true,
    ['Key Storage'] = true,
    ['Merit Reset'] = true,
    ['Merit Storage'] = true,
    ['PF Rewards'] = true,
    ['Prestige System'] = true,
    ['PvP Teleporter'] = true,
    ['PUP Shop'] = true,
    ['Race Change'] = true,
    ['Referral Concierge'] = true,
    ['Scroll Storage'] = true,
    ['Sea Dailies'] = true,
    ['Spell Training'] = true,
    ['Stronghold Warp'] = true,
    ['Strongholds'] = true,
    ['Venture Registration'] = true,
    ['Ventures'] = true,
    ['Weekly Hunt'] = true,
};

local function LoadSource(source)
    local loader, err = loadfile(source.path);

    if (loader == nil) then
        return nil, err;
    end

    local ok, data = pcall(loader);

    if (ok ~= true or type(data) ~= 'table') then
        return nil, data;
    end

    return data, nil;
end

local function Csv(value)
    value = tostring(value or '');
    value = value:gsub('"', '""');
    return '"' .. value .. '"';
end

local stats = {};
local loadErrors = {};

for _, source in ipairs(sources) do
    local data, err = LoadSource(source);

    if (data == nil) then
        loadErrors[#loadErrors + 1] = source.path .. ': ' .. tostring(err);
    else
        for name, entry in pairs(data) do
            if (type(entry) == 'table') then
                local entryType = tostring(entry.type or '');

                if (entryType ~= '') then
                    local key = entryType;
                    local row = stats[key];

                    if (row == nil) then
                        row = {
                            typeName = entryType,
                            count = 0,
                            sources = {},
                            examples = {},
                            customOnly = true,
                        };
                        stats[key] = row;
                    end

                    row.count = row.count + 1;
                    row.sources[source.key] = (row.sources[source.key] or 0) + 1;

                    if (source.custom ~= true) then
                        row.customOnly = false;
                    end

                    if (#row.examples < 6) then
                        row.examples[#row.examples + 1] = tostring(name) .. ' (' .. source.key .. ')';
                    end
                end
            end
        end
    end
end

local rows = {};

for _, row in pairs(stats) do
    local status = 'review';
    local suggestion = suggestions[row.typeName] or '';
    local vendorSuggestion = GetVendorSuggestion(row.typeName);

    if (bgTypes[row.typeName] == true) then
        status = 'exact_bg';
        suggestion = row.typeName;
    elseif (vendorSuggestion ~= '') then
        status = 'suggested';
        suggestion = vendorSuggestion;
    elseif (suggestion ~= '') then
        status = 'suggested';
    elseif (IsVendorish(row.typeName) == true) then
        status = 'vendor_review';
    elseif (row.customOnly == true or customKeep[row.typeName] == true) then
        status = 'custom_keep';
    end

    local sourceParts = {};
    for key, count in pairs(row.sources) do
        sourceParts[#sourceParts + 1] = key .. '=' .. tostring(count);
    end
    table.sort(sourceParts);

    rows[#rows + 1] = {
        typeName = row.typeName,
        count = row.count,
        status = status,
        suggestion = suggestion,
        sources = table.concat(sourceParts, '; '),
        examples = table.concat(row.examples, '; '),
    };
end

table.sort(rows, function(a, b)
    if (a.status ~= b.status) then
        local order = { vendor_review = 1, review = 2, suggested = 3, custom_keep = 4, exact_bg = 5 };
        return (order[a.status] or 99) < (order[b.status] or 99);
    end

    if (a.count ~= b.count) then
        return a.count > b.count;
    end

    return a.typeName < b.typeName;
end);

local counts = { exact_bg = 0, suggested = 0, custom_keep = 0, review = 0, vendor_review = 0 };
for _, row in ipairs(rows) do
    counts[row.status] = (counts[row.status] or 0) + 1;
end

local out = assert(io.open(outputPath, 'w'));
out:write('NPC Type Audit\n');
out:write('Source vocabulary: BG Wiki Category:NPCs\n');
out:write('Vendor target types: Armor Vendor, Item Vendor, Pet Item Vendor, RSE Vendor, Regional Vendor, Scroll Vendor, Tenshodo Vendor, Weapon Vendor\n');
out:write(string.format('Unique types=%d exact_bg=%d suggested=%d vendor_review=%d custom_keep=%d review=%d\n\n',
    #rows, counts.exact_bg or 0, counts.suggested or 0, counts.vendor_review or 0, counts.custom_keep or 0, counts.review or 0));

if (#loadErrors > 0) then
    out:write('Load errors:\n');
    for _, err in ipairs(loadErrors) do
        out:write('  ' .. err .. '\n');
    end
    out:write('\n');
end

out:write('Status meanings:\n');
out:write('  exact_bg: already matches BG type vocabulary.\n');
out:write('  suggested: can probably be renamed automatically after review.\n');
out:write('  vendor_review: vendor/shop/merchant type needs one of the specific BG vendor categories.\n');
out:write('  custom_keep: CatsEye/custom type, usually keep unless you want less detail.\n');
out:write('  review: needs a human look before changing.\n\n');

local currentStatus = nil;
for _, row in ipairs(rows) do
    if (row.status ~= currentStatus) then
        currentStatus = row.status;
        out:write('\n[' .. currentStatus .. ']\n');
    end

    out:write(string.format('%s | count=%d | suggest=%s | sources=%s\n',
        row.typeName, row.count, row.suggestion, row.sources));
    out:write('  examples: ' .. row.examples .. '\n');
end
out:close();

local csv = assert(io.open(csvPath, 'w'));
csv:write('Type,Count,Status,Suggestion,Sources,Examples\n');
for _, row in ipairs(rows) do
    csv:write(table.concat({
        Csv(row.typeName),
        tostring(row.count),
        Csv(row.status),
        Csv(row.suggestion),
        Csv(row.sources),
        Csv(row.examples),
    }, ',') .. '\n');
end
csv:close();

print(string.format('Wrote %s', outputPath));
print(string.format('Wrote %s', csvPath));
print(string.format('Unique types=%d exact_bg=%d suggested=%d vendor_review=%d custom_keep=%d review=%d',
    #rows, counts.exact_bg or 0, counts.suggested or 0, counts.vendor_review or 0, counts.custom_keep or 0, counts.review or 0));
