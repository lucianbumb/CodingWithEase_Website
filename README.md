# CodingWithEase Website

The public static website for [coding-with-ease.net](https://coding-with-ease.net), describing the engineering philosophy, architecture, security model, code-generation workflow, and AI capabilities behind CodingWithEase applications.

## Local preview

Serve the repository root with any static HTTP server. For example:

```powershell
python -m http.server 4173 --bind 127.0.0.1
```

Then open `http://127.0.0.1:4173/`.

## Verification

```powershell
& ./scripts/verify-site.ps1
```

The checks validate navigation, local references, canonical URLs, crawler directives, social-card metadata, JSON-LD, the manifest, sitemap, AI-readable files, and diagram accessibility metadata.

## Brand assets

`assets/CxLogoV1.png` is the preserved source artwork. To regenerate favicons, application icons, and the 1200 × 630 social-sharing card:

```powershell
python ./scripts/generate-brand-assets.py
```

Generated files are stored in `assets/brand/` and are referenced by every page, `site.webmanifest`, Open Graph, X/Twitter cards, and structured data.

## Machine discovery

- `robots.txt` and `sitemap.xml` provide crawler discovery.
- `llms.txt` is the concise AI-readable site map; `llms-full.txt` contains the longer technical reference.
- `.well-known/security.txt` publishes the responsible-disclosure contact.
- Every page includes a canonical URL, descriptive metadata, social preview data, and Schema.org JSON-LD.

## Deployment

Pushes to `main` deploy through GitHub Pages. The repository's Pages custom domain and `CNAME` file point the site to `coding-with-ease.net`.
