param(
    [string]$OutputPath = "data\generated\wiki_legacy_npcs.lua",
    [string]$CsvOutputPath = "data\generated\wiki_legacy_npcs.csv",
    [string]$CacheDir = "TEMP WORK FOLDER\data-scraping\ffxiclopedia"
)

$ErrorActionPreference = "Stop"

$addonRoot = Split-Path -Parent $PSScriptRoot
$fullOutputPath = Join-Path $addonRoot $OutputPath
$fullCsvOutputPath = Join-Path $addonRoot $CsvOutputPath
$fullCacheDir = Join-Path $addonRoot $CacheDir
$apiBase = "https://ffxiclopedia.fandom.com/api.php"

New-Item -ItemType Directory -Path $fullCacheDir -Force | Out-Null

$typeCategories = [ordered]@{
    "Adventurer's Assistant" = "Adventurer's Assistant"
    "Armor Storer" = "Armor Storer"
    "Assault Mission Giver" = "Assault Mission Giver"
    "Atma Fabricant" = "Atma Fabricant"
    "Atma Infusionist" = "Atma Infusionist"
    "Bastion Prefect" = "Bastion Prefect"
    "Campaign Arbiter" = "Campaign Arbiter"
    "Chocobo Renter" = "Chocobo Renter"
    "Conquest Overseer" = "Conquest Overseer"
    "Cruor Prospector" = "Cruor Prospector"
    "Conflux Surveyor" = "Conflux Surveyor"
    "Event Item Storer" = "Event Item Storer"
    "Goal Tracker" = "Goal Tracker"
    "Guild Merchant" = "Guild Merchant"
    "Imperial Gate Guard" = "Imperial Gate Guard"
    "Immigration NPC" = "Immigration NPC"
    "Item Deliverer" = "Item Deliverer"
    "Machine Outfitter" = "Machine Outfitter"
    "Map Marker" = "Map Marker"
    "Outpost Vendor" = "Outpost Vendor"
    "Outpost Teleporters" = "Outpost Teleporter"
    "Past Event Watcher" = "Past Event Watcher"
    "Patrol" = "Patrol"
    "Quest NPC" = "Quest NPC"
    "Reputation NPC" = "Reputation NPC"
    "Resistance Sapper" = "Resistance Sapper"
    "Resistance Sergeant" = "Resistance Sergeant"
    "Regional Vendor" = "Regional Vendor"
    "Standard Merchant" = "Standard Merchant"
    "Tactical Assessment" = "Tactical Assessment"
    "Tenshodo Merchant" = "Tenshodo Merchant"
    "Tutorial NPC" = "Tutorial NPC"
    "Title Changer" = "Title Changer"
    "Warp NPCs" = "Warp NPC"
    "Weather Checker" = "Weather Checker"
}

$typeIconMap = @{
    "Chocobo Renter" = "ChocoboRenter.png"
    "Item Deliverer" = "Deliverer.png"
    "Armor Storer" = "ItemStorage.png"
    "Event Item Storer" = "ItemStorage.png"
}

$zoneCategories = @(
    "Abyssea NPCs",
    "Adoulin NPCs",
    "Al Zahbi NPCs",
    "Bastok NPCs",
    "Battle NPCs",
    "Chocobo Circuit NPCs",
    "Cutscene NPCs",
    "Far East NPCs",
    "Jeuno NPCs",
    "Kazham NPCs",
    "Lumoria NPCs",
    "Mhaura NPCs",
    "Nashmau NPCs",
    "Norg NPCs",
    "Outland NPCs",
    "Pankration NPCs",
    "Rabao NPCs",
    "Tavnazian Safehold NPCs",
    "San d'Oria NPCs",
    "Selbina NPCs",
    "Special Event NPCs",
    "Windurst NPCs",
    "San d'Oria (S) NPCs",
    "Bastok (S) NPCs",
    "Windurst (S) NPCs",
    "Jeuno (S) NPCs",
    "Fort Karugo-Narugo (S) NPCs",
    "Beastman Confederate NPCs",
    "Freelance NPCs"
)

function ConvertTo-QueryString {
    param([hashtable]$Params)

    $parts = @()
    foreach ($key in ($Params.Keys | Sort-Object)) {
        $parts += ([uri]::EscapeDataString([string]$key) + "=" + [uri]::EscapeDataString([string]$Params[$key]))
    }
    return ($parts -join "&")
}

function Get-CacheKey {
    param([string]$Value)

    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
    $hash = $sha1.ComputeHash($bytes)
    return ([BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
}

function Invoke-FfxiApi {
    param([hashtable]$Params)

    $url = $apiBase + "?" + (ConvertTo-QueryString $Params)
    $cachePath = Join-Path $fullCacheDir ((Get-CacheKey $url) + ".json")

    if (Test-Path -LiteralPath $cachePath) {
        return Get-Content -LiteralPath $cachePath -Raw | ConvertFrom-Json
    }

    $content = & curl.exe -L -s -A "Mozilla/5.0 LibraPlates data builder" $url

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($content)) {
        throw "curl failed for $url"
    }

    Set-Content -LiteralPath $cachePath -Value $content -Encoding UTF8
    return $content | ConvertFrom-Json
}

function Get-CategoryMembers {
    param(
        [string]$CategoryName,
        [int]$Namespace = 0
    )

    $members = @()
    $continueValue = $null

    do {
        $params = @{
            action = "query"
            list = "categorymembers"
            cmtitle = "Category:$CategoryName"
            cmnamespace = $Namespace
            cmlimit = "500"
            format = "json"
        }

        if ($continueValue) {
            $params.cmcontinue = $continueValue
        }

        $response = Invoke-FfxiApi $params

        if ($response.query -and $response.query.categorymembers) {
            $members += $response.query.categorymembers
        }

        $continueValue = $null
        if ($response.continue -and $response.continue.cmcontinue) {
            $continueValue = $response.continue.cmcontinue
        }
    } while ($continueValue)

    return $members
}

function Get-PageLink {
    param([string]$Title)
    return "https://ffxiclopedia.fandom.com/wiki/" + [uri]::EscapeDataString($Title.Replace(" ", "_")).Replace("%2F", "/")
}

function Escape-LuaString {
    param([string]$Value)

    if ($null -eq $Value) {
        return ""
    }

    return $Value.Replace("\", "\\").Replace("'", "\'").Replace("`r", "").Replace("`n", "\n")
}

function Clean-WikiText {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    $text = $Value
    $text = [regex]::Replace($text, "\{\{Location\|([^|}]+)\|?([^}]*)\}\}", {
        param($m)
        $zone = $m.Groups[1].Value.Trim()
        $pos = $m.Groups[2].Value.Trim()
        if ([string]::IsNullOrWhiteSpace($pos)) { return $zone }
        return ($zone + " " + $pos).Trim()
    })
    $text = [regex]::Replace($text, "\[\[[^|\]]+\|([^\]]+)\]\]", '$1')
    $text = [regex]::Replace($text, "\[\[([^\]]+)\]\]", '$1')
    $text = [regex]::Replace($text, "\|\s*[A-Za-z0-9 _-]+\s*=.*$", "")
    $text = [regex]::Replace($text, "={2,}\s*([^=]+?)\s*={2,}", '$1:')
    $text = [regex]::Replace($text, "(?s)\}\}.*$", "")
    $text = [regex]::Replace($text, "''+", "")
    $text = [regex]::Replace($text, "<[^>]+>", "")
    $text = [regex]::Replace($text, "\{\{[^}]+\}\}", "")
    $text = [regex]::Replace($text, "(?i)category:[^\s]+", "")
    $text = [regex]::Replace($text, "\s+", " ")
    return $text.Trim()
}

function Convert-WikiLinksToText {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    $text = $Value
    $text = [regex]::Replace($text, "\{\{Location\|([^|}]+)\|?([^}]*)\}\}", {
        param($m)
        $zone = $m.Groups[1].Value.Trim()
        $pos = $m.Groups[2].Value.Trim()
        if ([string]::IsNullOrWhiteSpace($pos)) { return $zone }
        return ($zone + " " + $pos).Trim()
    })
    $text = [regex]::Replace($text, "\[\[[^|\]]+\|([^\]]+)\]\]", '$1')
    $text = [regex]::Replace($text, "\[\[([^\]]+)\]\]", '$1')
    $text = [regex]::Replace($text, "\[https?://[^\s\]]+\s+([^\]]+)\]", '$1')
    $text = [regex]::Replace($text, "\[https?://[^\]]+\]", "")
    $text = [regex]::Replace($text, "={2,}\s*([^=]+?)\s*={2,}", '$1:')
    $text = [regex]::Replace($text, "(?s)\}\}.*$", "")
    $text = [regex]::Replace($text, "''+", "")
    $text = [regex]::Replace($text, "<[^>]+>", "")
    $text = [regex]::Replace($text, "\{\{[^}]+\}\}", "")
    $text = [regex]::Replace($text, "(?i)category:[^\s]+", "")
    return $text.Trim()
}

function Get-WikiListItems {
    param([string]$Value)

    $items = New-Object System.Collections.Generic.List[string]

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $items
    }

    $text = Convert-WikiLinksToText $Value
    $lines = $text -split "`r?`n"

    foreach ($line in $lines) {
        $item = [regex]::Replace($line, "^\s*[*#:;]+\s*", "")
        $item = [regex]::Replace($item, "\s+", " ").Trim()

        if ([string]::IsNullOrWhiteSpace($item)) { continue }
        if ($item -match "^\|") { continue }
        if ($item -match "^\{\{") { continue }
        if ($item -match "\}\}") { continue }
        if ($item -match "(?i)thumb\||file:|image:|category:") { continue }
        if (-not $items.Contains($item)) {
            $items.Add($item)
        }
    }

    if ($items.Count -eq 0) {
        $fallback = [regex]::Replace($text, "\s+", " ").Trim()
        if (-not [string]::IsNullOrWhiteSpace($fallback) -and $fallback -notmatch "\}\}" -and $fallback -notmatch "(?i)thumb\||file:|image:|category:") {
            $items.Add($fallback)
        }
    }

    return $items
}

function Add-NoteSection {
    param(
        [System.Collections.Generic.List[string]]$Sections,
        [string]$Title,
        [System.Collections.Generic.List[string]]$Items
    )

    if ($Items.Count -eq 0) {
        return
    }

    $Sections.Add($Title + ":`n" + (($Items | ForEach-Object { "* " + $_ }) -join "`n"))
}

function Format-NoteBody {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    return ([regex]::Replace($Value, "(?m)^\s*[\-\*]\s*", "* ")).Trim()
}

function Get-ZoneNameFromLocation {
    param([string]$Location)

    if ([string]::IsNullOrWhiteSpace($Location)) {
        return ""
    }

    $zone = [string]$Location
    $zone = [regex]::Replace($zone, "\s*[-,]?\s*\([A-Z]-\d+\).*$", "")
    $zone = [regex]::Replace($zone, "\s+[A-Z]-\d+.*$", "")
    $zone = [regex]::Replace($zone, "\s+", " ")
    return $zone.Trim()
}

function Get-TemplateField {
    param(
        [string]$Content,
        [string]$Field
    )

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return ""
    }

    $pattern = "(?ms)^\|\s*" + [regex]::Escape($Field) + "\s*=\s*(.*?)(?=^\|\s*[A-Za-z0-9 _-]+\s*=|\z)"
    $match = [regex]::Match($Content, $pattern)

    if ($match.Success -ne $true) {
        return ""
    }

    return (Clean-WikiText $match.Groups[1].Value)
}

function Get-TemplateFieldRaw {
    param(
        [string]$Content,
        [string]$Field
    )

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return ""
    }

    $pattern = "(?ms)^\|\s*" + [regex]::Escape($Field) + "\s*=\s*(.*?)(?=^\|\s*[A-Za-z0-9 _-]+\s*=|\z)"
    $match = [regex]::Match($Content, $pattern)

    if ($match.Success -ne $true) {
        return ""
    }

    return $match.Groups[1].Value.Trim()
}

function Get-RevisionContent {
    param($Page)

    if ($Page -eq $null -or $Page.revisions -eq $null -or $Page.revisions.Count -lt 1) {
        return ""
    }

    $revision = $Page.revisions[0]

    if ($revision.slots -and $revision.slots.main) {
        return [string]$revision.slots.main.'*'
    }

    return [string]$revision.'*'
}

function Get-PageWikitextBatch {
    param([string[]]$Titles)

    if ($Titles.Count -eq 0) {
        return @{}
    }

    $response = Invoke-FfxiApi @{
        action = "query"
        prop = "revisions"
        rvprop = "content"
        rvslots = "main"
        titles = ($Titles -join "|")
        format = "json"
    }

    $contentByTitle = @{}

    foreach ($property in $response.query.pages.PSObject.Properties) {
        $page = $property.Value
        $title = [string]$page.title

        if (-not [string]::IsNullOrWhiteSpace($title)) {
            $contentByTitle[$title] = Get-RevisionContent $page
        }
    }

    return $contentByTitle
}

$entries = [ordered]@{}

Write-Host "Downloading FFXIclopedia NPC page list..."
$npcPages = Get-CategoryMembers -CategoryName "NPCs" -Namespace 0

foreach ($page in $npcPages) {
    $title = [string]$page.title
    if ([string]::IsNullOrWhiteSpace($title)) { continue }

    $entries[$title] = [ordered]@{
        type = ""
        zones = New-Object System.Collections.Generic.List[string]
        location = ""
        info = ""
        note = ""
        icon = ""
    }
}

Write-Host "Downloading NPC type categories..."
foreach ($categoryName in $typeCategories.Keys) {
    $displayType = $typeCategories[$categoryName]

    try {
        $members = Get-CategoryMembers -CategoryName $categoryName -Namespace 0

        foreach ($page in $members) {
            $title = [string]$page.title
            if ([string]::IsNullOrWhiteSpace($title)) { continue }

            if (-not $entries.Contains($title)) {
                $entries[$title] = [ordered]@{
                    type = ""
                    zones = New-Object System.Collections.Generic.List[string]
                    location = ""
                    info = ""
                    note = ""
                    icon = ""
                }
            }

            if ([string]::IsNullOrWhiteSpace([string]$entries[$title].type)) {
                $entries[$title].type = $displayType
            }
        }
    } catch {
        Write-Warning "Could not read Category:$categoryName"
    }
}

Write-Host "Downloading broad NPC affiliation/location categories..."
foreach ($zoneCategory in $zoneCategories) {
    $zoneName = $zoneCategory -replace " NPCs$", ""

    try {
        $members = Get-CategoryMembers -CategoryName $zoneCategory -Namespace 0

        foreach ($page in $members) {
            $title = [string]$page.title
            if ([string]::IsNullOrWhiteSpace($title)) { continue }

            if (-not $entries.Contains($title)) {
                $entries[$title] = [ordered]@{
                    type = ""
                    zones = New-Object System.Collections.Generic.List[string]
                    location = ""
                    info = ""
                    note = ""
                    icon = ""
                }
            }

            if (-not $entries[$title].zones.Contains($zoneName)) {
                $entries[$title].zones.Add($zoneName)
            }
        }
    } catch {
        Write-Warning "Could not read Category:$zoneCategory"
    }
}

Write-Host "Downloading NPC page template fields..."
$allNames = @($entries.Keys | Sort-Object)
$batchSize = 50

for ($i = 0; $i -lt $allNames.Count; $i += $batchSize) {
    $count = [Math]::Min($batchSize, $allNames.Count - $i)
    $batch = @($allNames[$i..($i + $count - 1)])
    $contentByTitle = Get-PageWikitextBatch $batch

    foreach ($name in $batch) {
        if (-not $contentByTitle.ContainsKey($name)) {
            continue
        }

        $content = $contentByTitle[$name]
        $type = Get-TemplateField $content "type"
        $location = Get-TemplateField $content "location"
        $notes = Get-TemplateField $content "notes"
        $description = Get-TemplateField $content "description"
        $startsQuests = Get-WikiListItems (Get-TemplateFieldRaw $content "starts quests")
        $involvedQuests = Get-WikiListItems (Get-TemplateFieldRaw $content "involved in quests")
        $startsMissions = Get-WikiListItems (Get-TemplateFieldRaw $content "starts missions")
        $involvedMissions = Get-WikiListItems (Get-TemplateFieldRaw $content "involved in missions")
        $noteSections = New-Object System.Collections.Generic.List[string]

        if (-not [string]::IsNullOrWhiteSpace($type) -and $type -ne "NPC") {
            $entries[$name].type = $type
        }

        if (-not [string]::IsNullOrWhiteSpace($location)) {
            $entries[$name].location = $location
        }

        Add-NoteSection $noteSections "Starts Quests" $startsQuests
        Add-NoteSection $noteSections "Involved in Quests" $involvedQuests
        Add-NoteSection $noteSections "Starts Missions" $startsMissions
        Add-NoteSection $noteSections "Involved in Missions" $involvedMissions

        if (-not [string]::IsNullOrWhiteSpace($description)) {
            $noteSections.Add("Description:`n" + (Format-NoteBody $description))
        }

        if (-not [string]::IsNullOrWhiteSpace($notes)) {
            $noteSections.Add("Notes:`n" + (Format-NoteBody $notes))
        }

        if ($noteSections.Count -gt 0) {
            $entries[$name].note = ($noteSections -join "`n`n")
            $entries[$name].info = [string]$entries[$name].note
        }

        if (-not [string]::IsNullOrWhiteSpace([string]$entries[$name].type) -and $typeIconMap.ContainsKey([string]$entries[$name].type)) {
            $entries[$name].icon = $typeIconMap[[string]$entries[$name].type]
        }
    }
}

New-Item -ItemType Directory -Path (Split-Path $fullOutputPath) -Force | Out-Null

$lines = New-Object System.Collections.Generic.List[string]
$csvRows = New-Object System.Collections.Generic.List[object]
$lines.Add("-- Generated by tools/build_wiki_legacy_npcs.ps1. Do not edit by hand.")
$lines.Add("local legacyWikiNpcs = T{")

foreach ($name in ($entries.Keys | Sort-Object)) {
    $entry = $entries[$name]
    $safeName = Escape-LuaString $name
    $safeType = Escape-LuaString ([string]$entry.type)
    $safeInfo = Escape-LuaString ([string]$entry.info)
    $safeNote = Escape-LuaString ([string]$entry.note)
    $safeIcon = Escape-LuaString ([string]$entry.icon)
    $safeLocation = Escape-LuaString ([string]$entry.location)
    $parts = @()
    $zones = New-Object System.Collections.Generic.List[string]

    foreach ($zone in $entry.zones) {
        if (-not [string]::IsNullOrWhiteSpace([string]$zone) -and -not $zones.Contains([string]$zone)) {
            $zones.Add([string]$zone)
        }
    }

    $locationZone = Get-ZoneNameFromLocation ([string]$entry.location)
    if (-not [string]::IsNullOrWhiteSpace($locationZone) -and -not $zones.Contains($locationZone)) {
        $zones.Add($locationZone)
    }

    if (-not [string]::IsNullOrWhiteSpace($safeType)) {
        $parts += "type = '$safeType'"
    }

    if ($zones.Count -gt 0) {
        $zoneParts = @()
        foreach ($zone in ($zones | Sort-Object)) {
            $zoneParts += "'" + (Escape-LuaString $zone) + "'"
        }
        $parts += "zones = { " + ($zoneParts -join ", ") + " }"
    }

    if (-not [string]::IsNullOrWhiteSpace($safeLocation)) {
        $parts += "location = '$safeLocation'"
    }

    if (-not [string]::IsNullOrWhiteSpace($safeNote)) {
        $parts += "note = '$safeNote'"
    } elseif (-not [string]::IsNullOrWhiteSpace($safeInfo)) {
        $parts += "info = '$safeInfo'"
    }

    if (-not [string]::IsNullOrWhiteSpace($safeIcon)) {
        $parts += "icon = '$safeIcon'"
    }

    if ($parts.Count -eq 0) {
        continue
    }

    $lines.Add("    ['$safeName'] = { " + ($parts -join ", ") + " },")
    $csvRows.Add([pscustomobject]@{
        Name = [string]$name
        Type = [string]$entry.type
        Zones = (($zones | Sort-Object) -join "; ")
        Location = [string]$entry.location
        Info = [string]$entry.info
        Note = [string]$entry.note
        Icon = [string]$entry.icon
    }) | Out-Null
}

$lines.Add("};")
$lines.Add("")
$lines.Add("return legacyWikiNpcs;")

Set-Content -LiteralPath $fullOutputPath -Value $lines -Encoding ASCII
New-Item -ItemType Directory -Path (Split-Path $fullCsvOutputPath) -Force | Out-Null
$csvRows | Export-Csv -LiteralPath $fullCsvOutputPath -NoTypeInformation -Encoding UTF8
Write-Host ("Wrote {0} useful NPC entries to {1}" -f ($lines.Count - 4), $fullOutputPath)
Write-Host ("Wrote CSV copy to {0}" -f $fullCsvOutputPath)
