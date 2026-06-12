$existingPath = "data\npc_icons.lua"
$generatedPath = "tools\generated_npc_skeleton.lua"
$outPath = "tools\npc_icons_merged.lua"

$existing = Get-Content $existingPath -Raw
$generated = Get-Content $generatedPath -Raw

function Escape-Lua {
    param([string]$Text)
    return ($Text -replace "\\", "\\\\" -replace "'", "\\'")
}

function Get-EntryNames {
    param([string]$Text)

    $names = @{}

    [regex]::Matches($Text, "\['((?:\\'|[^'])+)'\]\s*=") | ForEach-Object {
        $name = $_.Groups[1].Value -replace "\\'", "'"
        $names[$name] = $true
    }

    return $names
}

$existingNames = Get-EntryNames $existing
$generatedNames = Get-EntryNames $generated

$missingBlocks = @()
$added = 0

$pattern = "(?ms)^\s*\['((?:\\'|[^'])+)'\]\s*=\s*\{.*?^\s*\},"

[regex]::Matches($generated, $pattern) | ForEach-Object {
    $name = $_.Groups[1].Value -replace "\\'", "'"

    if (-not $existingNames.ContainsKey($name)) {
        $missingBlocks += $_.Value.TrimEnd()
        $missingBlocks += ""
        $added++
    }
}

$out = $existing.TrimEnd()

$out = $out -replace "\}\s*$", ""

$out += "`r`n"
$out += "`r`n-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
$out += "`r`n-- Missing NPCs Added From SQL"
$out += "`r`n-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
$out += "`r`n`r`n"

$out += ($missingBlocks -join "`r`n")
$out += "`r`n}"

$out | Set-Content $outPath -Encoding UTF8

Write-Host "Done: $outPath"
Write-Host "Existing names:" $existingNames.Count
Write-Host "Generated names:" $generatedNames.Count
Write-Host "Added missing:" $added