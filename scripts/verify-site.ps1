$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$indexPath = Join-Path $root 'index.html'
$html = Get-Content -Raw -LiteralPath $indexPath

if ($html -notmatch '<title>[^<]+</title>') {
    throw 'index.html must contain a non-empty title.'
}

if ($html -notmatch '<meta name="description" content="[^"]+">') {
    throw 'index.html must contain a meta description.'
}

$idMatches = [regex]::Matches($html, '\sid="([^"]+)"')
$ids = @($idMatches | ForEach-Object { $_.Groups[1].Value })
$duplicates = @($ids | Group-Object | Where-Object Count -gt 1 | Select-Object -ExpandProperty Name)
if ($duplicates.Count -gt 0) {
    throw "Duplicate HTML ids: $($duplicates -join ', ')"
}

$anchors = [regex]::Matches($html, 'href="#([^"]+)"')
foreach ($anchor in $anchors) {
    $target = $anchor.Groups[1].Value
    if ($target -and $target -notin $ids) {
        throw "Anchor target '#$target' does not exist."
    }
}

$localAssets = [regex]::Matches($html, '(?:src|href)="((?:assets|scripts)/[^"]+)"')
foreach ($asset in $localAssets) {
    $relativePath = $asset.Groups[1].Value.Replace('/', [IO.Path]::DirectorySeparatorChar)
    $assetPath = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $assetPath -PathType Leaf)) {
        throw "Referenced local asset does not exist: $relativePath"
    }
}

Write-Host "Static site checks passed: $($ids.Count) ids, $($anchors.Count) internal links, $($localAssets.Count) local assets."
