$existingPath = "data\item_icons.lua"
$generatedPath = "tools\generated_object_skeleton.lua"
$outPath = "tools\item_icons_merged.lua"

$existing = Get-Content $existingPath -Raw
$generated = Get-Content $generatedPath -Raw

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
$out = $out -replace "\}\s*;\s*return\s+itemIcons\s*;\s*$", ""

$out += "`r`n"
$out += "`r`n    -------------------------------------------------------------------------------"
$out += "`r`n    -- Missing Objects Added From SQL"
$out += "`r`n    -------------------------------------------------------------------------------"
$out += "`r`n`r`n"

$out += ($missingBlocks -join "`r`n")
$out += "`r`n    };"
$out += "`r`n`r`nreturn itemIcons;"

$out | Set-Content $outPath -Encoding UTF8

Write-Host "Done: $outPath"
Write-Host "Existing objects:" $existingNames.Count
Write-Host "Added missing:" $added