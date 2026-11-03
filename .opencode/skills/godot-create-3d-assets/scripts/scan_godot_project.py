#!/usr/bin/env python3
"""Read-only inventory for a Godot project."""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path


CATEGORIES = {
    "scenes": {".tscn", ".scn"},
    "scripts": {".gd", ".cs"},
    "models": {".glb", ".gltf", ".fbx", ".obj", ".blend"},
    "textures": {".png", ".jpg", ".jpeg", ".webp", ".svg", ".exr", ".hdr"},
    "shaders": {".gdshader", ".shader"},
    "audio": {".wav", ".ogg", ".mp3"},
}
IGNORED_PARTS = {".godot", ".git", "node_modules", "build"}


def project_name(project_file: Path) -> str:
    text = project_file.read_text(encoding="utf-8", errors="replace")
    match = re.search(r'^config/name\s*=\s*"([^"]+)"', text, re.MULTILINE)
    return match.group(1) if match else project_file.parent.name


def classify(suffix: str) -> str:
    for category, suffixes in CATEGORIES.items():
        if suffix in suffixes:
            return category
    return "other"


def scan(project: Path) -> dict[str, object]:
    project = project.resolve()
    project_file = project / "project.godot"
    if not project_file.is_file():
        raise SystemExit(f"Not a Godot project: {project}")

    counts: Counter[str] = Counter()
    tests: list[str] = []
    addons: set[str] = set()
    for path in project.rglob("*"):
        if not path.is_file() or any(part in IGNORED_PARTS for part in path.parts):
            continue
        relative = path.relative_to(project)
        counts[classify(path.suffix.lower())] += 1
        if "tests" in relative.parts and path.suffix.lower() in {".gd", ".tscn"}:
            tests.append(relative.as_posix())
        if relative.parts and relative.parts[0] == "addons" and len(relative.parts) > 1:
            addons.add(relative.parts[1])

    instruction_files: list[str] = []
    cursor = project
    for _ in range(5):
        candidate = cursor / "AGENTS.md"
        if candidate.is_file():
            instruction_files.append(str(candidate))
        if cursor.parent == cursor:
            break
        cursor = cursor.parent

    return {
        "name": project_name(project_file),
        "path": str(project),
        "counts": dict(sorted(counts.items())),
        "addons": sorted(addons),
        "test_files": sorted(tests),
        "instruction_files": instruction_files,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project", type=Path)
    parser.add_argument("--compact", action="store_true", help="Emit compact JSON")
    args = parser.parse_args()
    result = scan(args.project)
    print(json.dumps(result, indent=None if args.compact else 2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
