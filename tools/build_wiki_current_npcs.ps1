param(
    [string]$OutputPath = "data\generated\wiki_current_npcs.lua",
    [string]$CacheDir = "TEMP WORK FOLDER\data-scraping\bg-wiki"
)

$ErrorActionPreference = "Stop"

$addonRoot = Split-Path -Parent $PSScriptRoot
$fullOutputPath = Join-Path $addonRoot $OutputPath
$fullCacheDir = Join-Path $addonRoot $CacheDir
$apiBases = @(
    "https://www.bg-wiki.com/ffxi/api.php",
    "https://www.bg-wiki.com/ffxi/index.php",
    "https://www.bg-wiki.com/api.php",
    "https://www.bg-wiki.com/index.php"
)

New-Item -ItemType Directory -Path $fullCacheDir -Force | Out-Null

$typeCategories = [ordered]@{
    "Auction House Rep." = "Auction House Rep."
    "Delivery Box NPC" = "Delivery Box NPC"
    "Teleport NPC" = "Teleport NPC"
    "Proto-Waypoint NPC" = "Proto-Waypoint NPC"
    "Home Point" = "Home Point"
    "Conquest NPC" = "Conquest NPC"
    "Gate Guard" = "Gate Guard"
    "Imperial Standing NPC" = "Imperial Standing NPC"
    "Records of Eminence NPC" = "Records of Eminence NPC"
    "Quest Guide NPCs" = "Quest Guide"
    "Quest NPC" = "Quest NPC"
    "Mission NPC" = "Mission NPC"
    "Guild Master" = "Guild Master"
    "Guild Vendor" = "Guild Vendor"
    "Guild NPC" = "Guild NPC"
    "Synthesis Image Support" = "Synthesis Support"
    "Advanced Synthesis Image Support" = "Advanced Synthesis Support"
    "Armor Vendor" = "Armor Vendor"
    "Weapon Vendor" = "Weapon Vendor"
    "Item Vendor" = "Item Vendor"
    "Scroll Vendor" = "Scroll Vendor"
    "Regional Vendor" = "Regional Vendor"
    "Map Vendor" = "Map Vendor"
    "Chocobo NPC" = "Chocobo NPC"
    "Moogle" = "Moogle"
    "Mog House NPC" = "Mog House NPC"
    "Event Storage NPC" = "Event Storage"
    "Armor Storage NPCs" = "Armor Storage"
    "Title NPC" = "Title NPC"
    "Weather Forecast" = "Weather Forecast"
    "Ferry Ticket NPC" = "Ferry Ticket"
    "Airship Timer NPC" = "Airship Timer"
    "Ferry Timer NPC" = "Ferry Timer"
    "Cutscene Replay" = "Cutscene Replay"
}

function ConvertTo-QueryString {
    param([hashtable]$Params)

    $parts = @()
    foreach ($key in $Params.Keys) {
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

function Invoke-BgApi {
    param([hashtable]$Params)

    $lastError = $null
    foreach ($base in $apiBases) {
        try {
            $url = $base + "?" + (ConvertTo-QueryString $Params)
            $cachePath = Join-Path $fullCacheDir ((Get-CacheKey $url) + ".json")

            if (Test-Path -LiteralPath $cachePath) {
                return Get-Content -LiteralPath $cachePath -Raw | ConvertFrom-Json
            }

            $headers = @{
                "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36"
                "Accept" = "application/json,text/html,*/*"
                "Referer" = "https://www.bg-wiki.com/ffxi/Category:NPCs"
            }
            $responseText = Invoke-WebRequest -Uri $url -Headers $headers -TimeoutSec 30 | Select-Object -ExpandProperty Content
            Set-Content -LiteralPath $cachePath -Value $responseText -Encoding UTF8
            return $responseText | ConvertFrom-Json
        } catch {
            $lastError = $_
        }
    }

    throw $lastError
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

        $response = Invoke-BgApi $params

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

function Get-CategorySubcategories {
    param([string]$CategoryName)
    return Get-CategoryMembers -CategoryName $CategoryName -Namespace 14
}

function Get-PageLink {
    param([string]$Title)
    return "https://www.bg-wiki.com/ffxi/" + [uri]::EscapeDataString($Title.Replace(" ", "_")).Replace("%2F", "/")
}

function Escape-LuaString {
    param([string]$Value)

    if ($null -eq $Value) {
        return ""
    }

    return $Value.Replace("\", "\\").Replace("'", "\'").Replace("`r", "").Replace("`n", "\n")
}

$entries = [ordered]@{}

Write-Host "Downloading BG Wiki NPC page list..."
$npcPages = Get-CategoryMembers -CategoryName "NPCs" -Namespace 0

foreach ($page in $npcPages) {
    $title = [string]$page.title
    if ([string]::IsNullOrWhiteSpace($title)) { continue }

    $entries[$title] = [ordered]@{
        type = ""
        link = Get-PageLink $title
        source = "bg"
        zones = New-Object System.Collections.Generic.List[string]
    }
}

Write-Host "Downloading useful NPC type categories..."
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
                    link = Get-PageLink $title
                    source = "bg"
                    zones = New-Object System.Collections.Generic.List[string]
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

Write-Host "Downloading zone categories..."
$subcategories = Get-CategorySubcategories -CategoryName "NPCs"
$zoneCategories = $subcategories |
    Where-Object { $_.title -match " NPCs$" } |
    ForEach-Object { ([string]$_.title).Replace("Category:", "") } |
    Sort-Object -Unique

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
                    link = Get-PageLink $title
                    source = "bg"
                    zones = New-Object System.Collections.Generic.List[string]
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

New-Item -ItemType Directory -Path (Split-Path $fullOutputPath) -Force | Out-Null

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("-- Generated by tools/build_wiki_current_npcs.ps1. Do not edit by hand.")
$lines.Add("local bgNpcs = T{")

foreach ($name in ($entries.Keys | Sort-Object)) {
    $entry = $entries[$name]
    $safeName = Escape-LuaString $name
    $safeType = Escape-LuaString ([string]$entry.type)
    $safeLink = Escape-LuaString ([string]$entry.link)

    if ([string]::IsNullOrWhiteSpace($safeType) -and ($entry.zones.Count -eq 0)) {
        $lines.Add("    ['$safeName'] = { link = '$safeLink', source = 'bg' },")
        continue
    }

    $parts = @("link = '$safeLink'", "source = 'bg'")

    if (-not [string]::IsNullOrWhiteSpace($safeType)) {
        $parts = @("type = '$safeType'") + $parts
    }

    if ($entry.zones.Count -gt 0) {
        $zoneParts = @()
        foreach ($zone in ($entry.zones | Sort-Object)) {
            $zoneParts += "'" + (Escape-LuaString $zone) + "'"
        }
        $parts += "zones = { " + ($zoneParts -join ", ") + " }"
    }

    $lines.Add("    ['$safeName'] = { " + ($parts -join ", ") + " },")
}

$lines.Add("};")
$lines.Add("")
$lines.Add("return bgNpcs;")

Set-Content -LiteralPath $fullOutputPath -Value $lines -Encoding ASCII
Write-Host ("Wrote {0} NPC entries to {1}" -f $entries.Count, $fullOutputPath)
