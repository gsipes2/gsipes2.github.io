# gsipes2.github.io — Local/CI workflow

This repository is a Quarto website published via GitHub Pages from the `docs/` folder.

Summary
- Source files: `.qmd` and `notebooks/` in the repository root (e.g. `index.qmd`, `about.qmd`).
- Published site: contents of `docs/` — this is what GitHub Pages serves.
- CI: `.github/workflows/build-and-deploy-docs.yml` is the canonical workflow that can render the site and commit built files into `docs/`.

Two ways to update the live site

1) Local render & push (fast, direct)

- Edit `.qmd` source files locally.
- Render locally (Quarto writes directly into `docs/`):

```powershell
quarto render
```

- Commit and push the built `docs/` folder to `main`:

```powershell
git add docs
git commit -m "chore(site): update docs from local render"
git push origin main
```

Notes:
- Because `_quarto.yml` sets `project.output-dir: docs`, Quarto writes build output directly into `docs/`.
- The repository is configured so the central workflow ignores `docs/**` pushes — pushing `docs/` will update Pages directly (GitHub runs a managed Pages deployment job).
- On Windows you may see line-ending warnings (LF -> CRLF). These are harmless; configure `core.autocrlf` if desired.

2) CI-driven build & deploy (recommended for reproducible builds)

- Commit source changes only (do NOT commit `docs/`). Example:

```powershell
git add index.qmd tutorials.qmd projects.qmd notebooks/
git commit -m "feat(site): update homepage"
git push origin main
```

- The `build-and-deploy-docs.yml` workflow will run on push, render the site using Quarto on the runner, and commit the generated `docs/` files for you.

Why we centralised deployment
- Previously multiple workflows and scripts committed into `docs/`, which caused conflicting updates and surprising published content. Now a single central workflow is responsible for creating `docs/` from source; notebook workflows only generate artifacts locally (`_site/`) but do not commit.

Troubleshooting
- If your changes do not appear on the live site:
  - Confirm you pushed either `docs/` (for local-render flow) or source files (for CI flow).
  - Check Actions → `build-and-deploy-docs` to see logs if you used the CI flow.
  - If pushing `docs/` doesn't update Pages, check Pages settings to ensure the source is `main / docs`.

- If you see build warnings like `Unable to resolve link target: jupyterlite/index.html`, that indicates a cross-link or notebook path that Quarto could not resolve; adjust links or inspect notebook paths.

Recommended workflow
- For single-author edits or previewing changes quickly: use local `quarto render` and push `docs/`.
- For collaborative, repeatable builds: push source and let CI render and commit `docs/`.

If you want, I can:
- Run a test render and push to update the live site now, or
- Help configure the repo to always use the artifact-based deploy flow (no `docs/` commits) instead.

---
Last updated: 2025-09-21
