$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$htmlFiles = @(Get-ChildItem -LiteralPath $root -Filter '*.html' -File)
$totals = @{ Ids = 0; Anchors = 0; Assets = 0; Pages = $htmlFiles.Count }

foreach ($htmlFile in $htmlFiles) {
    $html = Get-Content -Raw -LiteralPath $htmlFile.FullName
    if ($html -notmatch '<title>[^<]+</title>') {
        throw "$($htmlFile.Name) must contain a non-empty title."
    }
    if ($html -notmatch '<meta name="description" content="[^"]+">') {
        throw "$($htmlFile.Name) must contain a meta description."
    }

    $ids = @([regex]::Matches($html, '\sid="([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
    $duplicates = @($ids | Group-Object | Where-Object Count -gt 1 | Select-Object -ExpandProperty Name)
    if ($duplicates.Count -gt 0) {
        throw "$($htmlFile.Name) has duplicate ids: $($duplicates -join ', ')"
    }

    $anchors = [regex]::Matches($html, 'href="#([^"]+)"')
    foreach ($anchor in $anchors) {
        $target = $anchor.Groups[1].Value
        if ($target -and $target -notin $ids) {
            throw "$($htmlFile.Name) links to missing anchor '#$target'."
        }
    }

    $localReferences = [regex]::Matches($html, '(?:src|href)="((?!https?:|mailto:|#)[^"]+)"')
    foreach ($reference in $localReferences) {
        $relativePath = $reference.Groups[1].Value.Split('#')[0].Split('?')[0]
        if (-not $relativePath) { continue }
        $resolvedPath = Join-Path $root $relativePath.Replace('/', [IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
            throw "$($htmlFile.Name) references missing local file: $relativePath"
        }
    }

    $totals.Ids += $ids.Count
    $totals.Anchors += $anchors.Count
    $totals.Assets += $localReferences.Count
}

Write-Host "Static site checks passed: $($totals.Pages) pages, $($totals.Ids) ids, $($totals.Anchors) internal anchors, $($totals.Assets) local references."
