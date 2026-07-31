local helpSearch = {};

function helpSearch.Normalize(value)
    return tostring(value or ''):lower():gsub('[^%w%s]+', ' '):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '');
end

function helpSearch.GetQueryAlternatives(word, searchTerms)
    word = helpSearch.Normalize(word);
    local alternatives = { word };
    local seen = { [word] = true };

    for _, group in ipairs((searchTerms or {}).aliases or {}) do
        local groupMatches = false;
        for _, term in ipairs(group) do
            local normalizedTerm = helpSearch.Normalize(term);
            for termWord in normalizedTerm:gmatch('%S+') do
                if (termWord == word) then
                    groupMatches = true;
                    break;
                end
            end

            if (groupMatches == true) then
                break;
            end
        end

        if (groupMatches == true) then
            for _, term in ipairs(group) do
                local normalizedTerm = helpSearch.Normalize(term);
                if (seen[normalizedTerm] ~= true) then
                    seen[normalizedTerm] = true;
                    alternatives[#alternatives + 1] = normalizedTerm;
                end
            end
        end
    end

    return alternatives;
end

function helpSearch.BuildEntryTerms(entry, searchTerms)
    searchTerms = searchTerms or {};
    local parts = {};

    local function add(value)
        value = tostring(value or '');
        if (value ~= '') then
            parts[#parts + 1] = value;
        end
    end

    add((searchTerms.settings or {})[entry.section]);
    add((searchTerms.entities or {})[entry.entity]);
    add((searchTerms.states or {})[entry.state]);
    add((searchTerms.widgets or {})[entry.widget]);
    add((searchTerms.features or {})[entry.title]);
    add(entry.terms);

    return table.concat(parts, ' ');
end

function helpSearch.WordsAreClose(left, right)
    left = tostring(left or '');
    right = tostring(right or '');
    local leftLength = #left;
    local rightLength = #right;

    if (math.min(leftLength, rightLength) < 3 or math.abs(leftLength - rightLength) > 1) then
        return false;
    end

    if (leftLength == rightLength) then
        local differences = 0;
        for index = 1, leftLength do
            if (left:sub(index, index) ~= right:sub(index, index)) then
                differences = differences + 1;
                if (differences > 1) then
                    return false;
                end
            end
        end

        return differences == 1;
    end

    local shorter = leftLength < rightLength and left or right;
    local longer = leftLength < rightLength and right or left;
    local shortIndex = 1;
    local longIndex = 1;
    local skipped = false;

    while (shortIndex <= #shorter and longIndex <= #longer) do
        if (shorter:sub(shortIndex, shortIndex) == longer:sub(longIndex, longIndex)) then
            shortIndex = shortIndex + 1;
            longIndex = longIndex + 1;
        elseif (skipped == false) then
            skipped = true;
            longIndex = longIndex + 1;
        else
            return false;
        end
    end

    return true;
end

function helpSearch.AlternativeMatches(haystack, alternative, allowFuzzy)
    if (haystack:find(alternative, 1, true) ~= nil) then
        return true;
    end

    if (allowFuzzy ~= true or alternative:find(' ', 1, true) ~= nil) then
        return false;
    end

    for haystackWord in haystack:gmatch('%S+') do
        if (helpSearch.WordsAreClose(alternative, haystackWord) == true) then
            return true;
        end
    end

    return false;
end

return helpSearch;
