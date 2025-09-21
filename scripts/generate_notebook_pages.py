#!/usr/bin/env python3
"""Generate tutorials.qmd and projects.qmd by scanning the notebooks/ folder.

Rules:
- If a notebook is under `notebooks/projects/` it is classified as a project.
- If a notebook has a top-level `metadata` field with `tags` containing `project`, it is a project.
- Otherwise it is a tutorial.

This script writes `tutorials.qmd` and `projects.qmd` at the repo root.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NOTEBOOKS = ROOT / 'notebooks'

def read_nb(path: Path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception:
        return None

def classify_nb(path: Path):
    # Folder-based rule
    rel = path.relative_to(NOTEBOOKS)
    if rel.parts[0] == 'projects':
        return 'projects'

    nb = read_nb(path)
    if not nb:
        return 'tutorials'

    meta = nb.get('metadata', {})
    tags = meta.get('tags', []) or []
    if 'project' in tags:
        return 'projects'
    return 'tutorials'

def title_from_nb(path: Path):
    nb = read_nb(path)
    if not nb:
        return path.stem
    # search first markdown cell for a title
    for cell in nb.get('cells', []):
        if cell.get('cell_type') == 'markdown':
            src = cell.get('source', [])
            if src:
                first = src[0]
                if isinstance(first, str) and first.strip().startswith('#'):
                    return first.strip().lstrip('#').strip()
    return path.stem

def main():
    tutorials = []
    projects = []
    for path in sorted(NOTEBOOKS.rglob('*.ipynb')):
        rel = path.relative_to(ROOT)
        kind = classify_nb(path)
        title = title_from_nb(path)
        link = str(rel).replace('\\', '/')
        if kind == 'projects':
            projects.append((title, link))
        else:
            tutorials.append((title, link))

    # write tutorials.qmd
    tut_path = ROOT / 'tutorials.qmd'
    with open(tut_path, 'w', encoding='utf-8') as f:
        f.write('---\ntitle: Tutorials\nformat: html\n---\n\n')
        f.write('## Tutorials\n\n')
        if tutorials:
            for t, l in tutorials:
                f.write(f'- [{t}]({l})\n')
        else:
            f.write('No tutorials found.\n')

    proj_path = ROOT / 'projects.qmd'
    with open(proj_path, 'w', encoding='utf-8') as f:
        f.write('---\ntitle: Projects\nformat: html\n---\n\n')
        f.write('## Projects\n\n')
        if projects:
            for t, l in projects:
                f.write(f'- [{t}]({l})\n')
        else:
            f.write('No projects found.\n')

    print(f'Wrote {len(tutorials)} tutorials and {len(projects)} projects.')

if __name__ == '__main__':
    main()
