$npcSqlUrl = "https://raw.githubusercontent.com/LandSandBoat/server/refs/heads/base/sql/npc_list.sql"
$outPath = "tools\generated_npc_skeleton.lua"

$sql = Invoke-WebRequest $npcSqlUrl -UseBasicParsing | Select-Object -ExpandProperty Content

$zoneGroups = @(
    @{ name = "Republic of Bastok"; zones = @("Bastok Markets", "Bastok Mines", "Metalworks", "Port Bastok") },
    @{ name = "Kingdom of San d'Oria"; zones = @("Southern San d'Oria", "Northern San d'Oria", "Port San d'Oria", "Chateau d'Oraguille") },
    @{ name = "Federation of Windurst"; zones = @("Windurst Waters", "Windurst Walls", "Windurst Woods", "Port Windurst", "Heavens Tower") },
    @{ name = "Jeuno"; zones = @("Lower Jeuno", "Upper Jeuno", "Port Jeuno", "Ru'Lude Gardens") },
    @{ name = "Aht Urhgan"; zones = @("Aht Urhgan Whitegate", "Al Zahbi", "Nashmau") },
    @{ name = "Adoulin"; zones = @("Eastern Adoulin", "Western Adoulin", "Celennia Memorial Library") }
)

$npcs = @{}
$currentZoneName = $null
$currentZoneId = $null

foreach ($line in ($sql -split "`n")) {
    if ($line -match "^--\s+(.+?)\s+\(Zone\s+(\d+)\)") {
        $currentZoneName = $matches[1].Trim()
        $currentZoneId = [int]$matches[2]
        continue
    }

    if (-not $currentZoneName) { continue }
    if ($line -notmatch "VALUES\s*\((\d+),'((?:\\'|[^'])*)','((?:\\'|[^'])*)'") { continue }

    $name = $matches[3] -replace "\\'", "'"

	if ([string]::IsNullOrWhiteSpace($name)) { continue }
	if ($name -match "^(none|unknown|dummy|test|blank)$") { continue }
	if ($name -match "^NPC\[\d+\]$") { continue }
	if ($name -match "^_") { continue }
	if ($name -match "^\d+$") { continue }
	if ($name -match "^\d") { continue }
	if ($name -match "^=TEST=") { continue }

    if (-not $npcs.ContainsKey($name)) {
        $npcs[$name] = @{
            zones = @{}
            zoneIds = @{}
        }
    }

    $npcs[$name].zones[$currentZoneName] = $true
    $npcs[$name].zoneIds[$currentZoneId] = $true
}

function Escape-LuaString {
    param([string]$Text)
    return ($Text -replace "\\", "\\\\" -replace "'", "\\'")
}

function Add-NpcEntry {
    param(
        [System.Collections.ArrayList]$Lines,
        [string]$Name,
        $NpcData
    )

    $safeName = Escape-LuaString $Name
    $zones = $NpcData.zones.Keys | Sort-Object
    $zoneIds = $NpcData.zoneIds.Keys | Sort-Object

    $zoneText = ($zones | ForEach-Object { "'" + (Escape-LuaString $_) + "'" }) -join ", "
    $zoneIdText = $zoneIds -join ", "

    [void]$Lines.Add("    ['$safeName'] = {")
    [void]$Lines.Add("        type = 'Unknown',")
    [void]$Lines.Add("        icon = 'Dialogue.png',")
    [void]$Lines.Add("        zones = { $zoneText },")
    [void]$Lines.Add("        zoneIds = { $zoneIdText },")
    [void]$Lines.Add("        note = 'Needs Review.',")
    [void]$Lines.Add("    },")
    [void]$Lines.Add("")
}

$singleZone = @{}
$multipleZone = @{}

foreach ($name in $npcs.Keys) {
    if ($npcs[$name].zoneIds.Count -eq 1) {
        $zoneName = ($npcs[$name].zones.Keys | Select-Object -First 1)

        if (-not $singleZone.ContainsKey($zoneName)) {
            $singleZone[$zoneName] = @{}
        }

        $singleZone[$zoneName][$name] = $npcs[$name]
    } else {
        $multipleZone[$name] = $npcs[$name]
    }
}

$handledZones = @{}
$lines = New-Object System.Collections.ArrayList
[void]$lines.Add("local npcIcons = T{")
[void]$lines.Add("")

foreach ($group in $zoneGroups) {
    [void]$lines.Add("-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
    [void]$lines.Add("-- $($group.name)")
    [void]$lines.Add("-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
    [void]$lines.Add("")

    foreach ($zoneName in $group.zones) {
        if (-not $singleZone.ContainsKey($zoneName)) { continue }

        $handledZones[$zoneName] = $true

        [void]$lines.Add("-- ------------------------------------------------------------")
        [void]$lines.Add("-- $zoneName")
        [void]$lines.Add("-- ------------------------------------------------------------")
        [void]$lines.Add("")

        foreach ($name in ($singleZone[$zoneName].Keys | Sort-Object)) {
            Add-NpcEntry -Lines $lines -Name $name -NpcData $singleZone[$zoneName][$name]
        }
    }
}

[void]$lines.Add("-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
[void]$lines.Add("-- Other Areas")
[void]$lines.Add("-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
[void]$lines.Add("")

foreach ($zoneName in ($singleZone.Keys | Sort-Object)) {
    if ($handledZones.ContainsKey($zoneName)) { continue }

    [void]$lines.Add("-- ------------------------------------------------------------")
    [void]$lines.Add("-- $zoneName")
    [void]$lines.Add("-- ------------------------------------------------------------")
    [void]$lines.Add("")

    foreach ($name in ($singleZone[$zoneName].Keys | Sort-Object)) {
        Add-NpcEntry -Lines $lines -Name $name -NpcData $singleZone[$zoneName][$name]
    }
}

[void]$lines.Add("-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
[void]$lines.Add("-- Multiple Zones")
[void]$lines.Add("-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
[void]$lines.Add("")

foreach ($name in ($multipleZone.Keys | Sort-Object)) {
    Add-NpcEntry -Lines $lines -Name $name -NpcData $multipleZone[$name]
}

[void]$lines.Add("}")

$lines | Set-Content $outPath -Encoding UTF8

Write-Host "Done: $outPath"
Write-Host "NPC entries:" $npcs.Count
Write-Host "Single-zone entries:" $singleZone.Values.Count
Write-Host "Multiple-zone entries:" $multipleZone.Count