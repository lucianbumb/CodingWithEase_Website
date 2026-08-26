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
    $requiredDiscoveryMarkup = @{
        'crawler directives' = '<meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1">'
        'canonical URL' = '<link rel="canonical" href="https://coding-with-ease\.net/[^"]*">'
        'AI-readable alternate' = '<link rel="alternate" type="text/plain" href="https://coding-with-ease\.net/llms\.txt"'
        'web manifest' = '<link rel="manifest" href="/site\.webmanifest">'
        'favicon' = '<link rel="icon" href="/assets/brand/favicon\.ico" sizes="any">'
        'Open Graph title' = '<meta property="og:title" content="[^"]+">'
        'Open Graph description' = '<meta property="og:description" content="[^"]+">'
        'Open Graph image' = '<meta property="og:image" content="https://coding-with-ease\.net/assets/brand/coding-with-ease-social-1200x630\.png">'
        'Open Graph image dimensions' = '<meta property="og:image:width" content="1200">[\s\S]*<meta property="og:image:height" content="630">'
        'X/Twitter card' = '<meta name="twitter:card" content="summary_large_image">'
        'X/Twitter image' = '<meta name="twitter:image" content="https://coding-with-ease\.net/assets/brand/coding-with-ease-social-1200x630\.png">'
        'JSON-LD' = '<script type="application/ld\+json">'
    }
    foreach ($requirement in $requiredDiscoveryMarkup.GetEnumerator()) {
        if ($html -notmatch $requirement.Value) {
            throw "$($htmlFile.Name) must contain $($requirement.Key)."
        }
    }

    $jsonLdBlocks = [regex]::Matches($html, '(?s)<script type="application/ld\+json">\s*(.*?)\s*</script>')
    foreach ($jsonLdBlock in $jsonLdBlocks) {
        try {
            $null = $jsonLdBlock.Groups[1].Value | ConvertFrom-Json
        }
        catch {
            throw "$($htmlFile.Name) contains invalid JSON-LD: $($_.Exception.Message)"
        }
    }
    if ($html -notmatch 'data-nav-toggle' -or $html -notmatch 'data-site-nav') {
        throw "$($htmlFile.Name) must include the responsive primary navigation controls."
    }
    if ($html -notmatch '<script src="assets/site.js" defer></script>') {
        throw "$($htmlFile.Name) must load the shared navigation script."
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

$requiredSiteFiles = @(
    'robots.txt',
    'sitemap.xml',
    'site.webmanifest',
    'llms.txt',
    'llms-full.txt',
    'humans.txt',
    '.well-known/security.txt',
    'favicon.ico',
    'apple-touch-icon.png',
    'assets/brand/favicon.ico',
    'assets/brand/cwe-logo-16.png',
    'assets/brand/cwe-logo-32.png',
    'assets/brand/cwe-logo-180.png',
    'assets/brand/cwe-logo-192.png',
    'assets/brand/cwe-logo-512.png',
    'assets/brand/coding-with-ease-social-1200x630.png'
)
foreach ($siteFile in $requiredSiteFiles) {
    $sitePath = Join-Path $root $siteFile.Replace('/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $sitePath -PathType Leaf)) {
        throw "Missing required discovery or brand file: $siteFile"
    }
}

$robots = Get-Content -Raw -LiteralPath (Join-Path $root 'robots.txt')
if ($robots -notmatch '(?m)^User-agent: \*$' -or $robots -notmatch '(?m)^Allow: /$' -or $robots -notmatch '(?m)^Sitemap: https://coding-with-ease\.net/sitemap\.xml$') {
    throw 'robots.txt must allow public crawling and publish the canonical sitemap.'
}

[xml]$sitemap = Get-Content -Raw -LiteralPath (Join-Path $root 'sitemap.xml')
$sitemapUrls = @($sitemap.urlset.url.loc)
if ($sitemapUrls.Count -ne $htmlFiles.Count) {
    throw "sitemap.xml contains $($sitemapUrls.Count) URLs for $($htmlFiles.Count) HTML pages."
}

$manifest = Get-Content -Raw -LiteralPath (Join-Path $root 'site.webmanifest') | ConvertFrom-Json
if (-not $manifest.name -or -not $manifest.short_name -or @($manifest.icons).Count -lt 2) {
    throw 'site.webmanifest must contain a name, short name, and at least two icons.'
}
foreach ($icon in $manifest.icons) {
    $iconPath = Join-Path $root $icon.src.TrimStart('/').Replace('/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $iconPath -PathType Leaf)) {
        throw "site.webmanifest references missing icon: $($icon.src)"
    }
}

function Get-PngDimensions([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 24 -or $bytes[0] -ne 137 -or $bytes[1] -ne 80 -or $bytes[2] -ne 78 -or $bytes[3] -ne 71) {
        throw "$Path is not a valid PNG file."
    }
    $width = ([int]$bytes[16] -shl 24) -bor ([int]$bytes[17] -shl 16) -bor ([int]$bytes[18] -shl 8) -bor [int]$bytes[19]
    $height = ([int]$bytes[20] -shl 24) -bor ([int]$bytes[21] -shl 16) -bor ([int]$bytes[22] -shl 8) -bor [int]$bytes[23]
    return @{ Width = $width; Height = $height }
}

$socialCardPath = Join-Path $root 'assets/brand/coding-with-ease-social-1200x630.png'
$socialCardDimensions = Get-PngDimensions $socialCardPath
if ($socialCardDimensions.Width -ne 1200 -or $socialCardDimensions.Height -ne 630) {
    throw 'The social sharing image must be exactly 1200x630 pixels.'
}

$diagramFiles = @(Get-ChildItem -LiteralPath (Join-Path $root 'assets/diagrams') -Filter '*.svg' -File)
foreach ($diagramFile in $diagramFiles) {
    [xml]$svg = Get-Content -Raw -LiteralPath $diagramFile.FullName
    if (-not $svg.svg.viewBox -or -not $svg.svg.title -or -not $svg.svg.desc) {
        throw "$($diagramFile.Name) must include a viewBox, title, and description."
    }
}

Write-Host "Static site checks passed: $($totals.Pages) pages, $($diagramFiles.Count) diagrams, $($totals.Ids) ids, $($totals.Anchors) internal anchors, $($totals.Assets) local references, metadata and machine discovery."
