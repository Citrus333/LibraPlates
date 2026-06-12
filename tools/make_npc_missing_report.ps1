$npcLuaPath = "data\npc_icons.lua"
$sqlUrl = "https://raw.githubusercontent.com/LandSandBoat/server/refs/heads/base/sql/npc_list.sql"
$outPath = "tools\npc_missing_report.txt"

$lua = Get-Content $npcLuaPath -Raw
$sql = Invoke-WebRequest $sqlUrl -UseBasicParsing | Select-Object -ExpandProperty Content

$existing = [regex]::Matches($lua, "\['([^']+)'\]\s*=") | ForEach-Object {
    $_.Groups[1].Value
} | Sort-Object -Unique

$sqlNames = [regex]::Matches($sql, "\(([^;]+?)\)") | ForEach-Object {
    $row = $_.Groups[1].Value

    $cols = [regex]::Matches($row, "(?:'((?:\\'|[^'])*)'|([^,]+))(?:,|$)") | ForEach-Object {
        if ($_.Groups[1].Success) {
            $_.Groups[1].Value -replace "\\'", "'"
        } else {
            $_.Groups[2].Value.Trim()
        }
    }

    if ($cols.Count -lt 8) { return }

    $name = $cols[0]

    if ([string]::IsNullOrWhiteSpace($name)) { return }
    if ($name -match "^(none|unknown|dummy|test|blank)$") { return }

    if ($name -match "door|gate|lever|switch|crystal|portal|signpost|target|\?\?\?|blank|wall|chest|box|crate|barrel|torch|lamp|elevator|furnace|machine|device|terminal|monument|tablet|rift|waypoint") { return }

    $name
} | Sort-Object -Unique

$missing = $sqlNames | Where-Object { $_ -notin $existing }
$extra = $existing | Where-Object { $_ -notin $sqlNames }

@(
    "Missing from npc_icons.lua:"
    "--------------------------------"
    $missing
    ""
    "Present in npc_icons.lua but not in LSB npc_list.sql:"
    "--------------------------------"
    $extra
) | Set-Content $outPath -Encoding UTF8

Write-Host "Done: $outPath"
Write-Host "Missing:" $missing.Count
Write-Host "Extra:" $extra.Count