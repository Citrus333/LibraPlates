$npcSqlUrl = "https://raw.githubusercontent.com/LandSandBoat/server/refs/heads/base/sql/npc_list.sql"

$npcOutPath = "tools\generated_npc_skeleton.lua"
$objOutPath = "tools\generated_object_skeleton.lua"

$sql = Invoke-WebRequest $npcSqlUrl -UseBasicParsing | Select-Object -ExpandProperty Content

$objects = @{}
$npcs = @{}

$currentZoneName = $null
$currentZoneId = $null

function Add-Entity {
    param($Table, [string]$Name, [string]$ZoneName, [int]$ZoneId)

    if (-not $Table.ContainsKey($Name)) {
        $Table[$Name] = @{
            zones = @{}
            zoneIds = @{}
        }
    }

    $Table[$Name].zones[$ZoneName] = $true
    $Table[$Name].zoneIds[$ZoneId] = $true
}

function Is-JunkName {
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) { return $true }
    if ($Name -match "^(none|unknown|dummy|test|blank)$") { return $true }
    if ($Name -match "^NPC\[\d+\]$") { return $true }
    if ($Name -match "^_") { return $true }
    if ($Name -match "^\d") { return $true }
    if ($Name -match "^=TEST=") { return $true }

    return $false
}

function Is-ObjectName {
    param([string]$Name)

    if ($Name -eq "!") { return $true }
    if ($Name -eq "???") { return $true }

    if ($Name -match "^(Door|Gate|Switch|Lever|Lamp|Torch|Crate|Barrel|Box|Bookshelf|Well|Monument)") { return $true }
    if ($Name -match "(Point|Chest|Coffer|Casket|Waypoint|Portal|Guide|Furnace|Apparatus|Circle|Conflux|Junction|Fount|Maw|Rift|Footprint|Footprints|Passage|Counter)") { return $true }
    if ($Name -match "^(Home Point|Survival Guide|Runic Portal|Proto-Waypoint|Geomagnetic Fount|Ethereal Junction|Veridical Conflux|Planar Rift|Cavernous Maw|Synergy Furnace|Auction Counter)") { return $true }

    return $false
}

function Escape-LuaString {
    param([string]$Text)
    return ($Text -replace "\\", "\\\\" -replace "'", "\\'")
}

function Write-EntityFile {
    param(
        $Table,
        [string]$OutPath,
        [string]$TableName,
        [string]$DefaultType,
        [string]$DefaultIcon
    )

    $lines = New-Object System.Collections.ArrayList
    [void]$lines.Add("local $TableName = T{")
    [void]$lines.Add("")

    foreach ($name in ($Table.Keys | Sort-Object)) {
        $safeName = Escape-LuaString $name
        $zones = $Table[$name].zones.Keys | Sort-Object
        $zoneIds = $Table[$name].zoneIds.Keys | Sort-Object

        $zoneText = ($zones | ForEach-Object { "'" + (Escape-LuaString $_) + "'" }) -join ", "
        $zoneIdText = $zoneIds -join ", "

        [void]$lines.Add("    ['$safeName'] = {")
        [void]$lines.Add("        type = '$DefaultType',")
        [void]$lines.Add("        icon = '$DefaultIcon',")
        [void]$lines.Add("        zones = { $zoneText },")
        [void]$lines.Add("        zoneIds = { $zoneIdText },")
        [void]$lines.Add("        note = 'Needs Review.',")
        [void]$lines.Add("    },")
        [void]$lines.Add("")
    }

    [void]$lines.Add("};")
    [void]$lines.Add("")
    [void]$lines.Add("return $TableName;")

    $lines | Set-Content $OutPath -Encoding UTF8
}

foreach ($line in ($sql -split "`n")) {
    if ($line -match "^--\s+(.+?)\s+\(Zone\s+(\d+)\)") {
        $currentZoneName = $matches[1].Trim()
        $currentZoneId = [int]$matches[2]
        continue
    }

    if (-not $currentZoneName) { continue }
    if ($line -notmatch "VALUES\s*\((\d+),'((?:\\'|[^'])*)','((?:\\'|[^'])*)'") { continue }

    $name = $matches[3] -replace "\\'", "'"

    if (Is-JunkName $name) { continue }

    if (Is-ObjectName $name) {
        Add-Entity -Table $objects -Name $name -ZoneName $currentZoneName -ZoneId $currentZoneId
    } else {
        Add-Entity -Table $npcs -Name $name -ZoneName $currentZoneName -ZoneId $currentZoneId
    }
}

Write-EntityFile -Table $npcs -OutPath $npcOutPath -TableName "npcIcons" -DefaultType "Unknown" -DefaultIcon "Dialogue.png"
Write-EntityFile -Table $objects -OutPath $objOutPath -TableName "itemIcons" -DefaultType "Object" -DefaultIcon "QuestionMark.png"

Write-Host "Done:"
Write-Host "NPCs:" $npcs.Count "->" $npcOutPath
Write-Host "Objects:" $objects.Count "->" $objOutPath