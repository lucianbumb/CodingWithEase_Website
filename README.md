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

## Deployment

Pushes to `main` deploy through GitHub Pages. The repository's Pages custom domain and `CNAME` file point the site to `coding-with-ease.net`.
