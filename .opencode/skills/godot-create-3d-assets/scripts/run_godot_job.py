#!/usr/bin/env python3
"""Run one owned Godot generator, test, or off-desktop render job safely."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True, type=Path)
    parser.add_argument("--project", required=True, type=Path)
    parser.add_argument("--scene", required=True)
    parser.add_argument("--mode", choices=("headless", "render"), default="headless")
    parser.add_argument("--resolution", default="1280x720")
    parser.add_argument("--position", default="32000,32000")
    parser.add_argument("--timeout", type=float, default=180.0)
    parser.add_argument(
        "--quit-after",
        type=int,
        default=600,
        help="Godot frame limit; use 0 only for a job that intentionally runs longer",
    )
    parser.add_argument("--user-arg", action="append", default=[])
    parser.add_argument("--expect", action="append", default=[])
    parser.add_argument(
        "--allow-engine-errors",
        action="store_true",
        help="Do not fail when Godot logs SCRIPT ERROR or ERROR lines",
    )
    args = parser.parse_args()

    godot = args.godot.resolve()
    project = args.project.resolve()
    if not godot.is_file():
        parser.error(f"Godot executable not found: {godot}")
    if not (project / "project.godot").is_file():
        parser.error(f"Not a Godot project: {project}")

    command = [str(godot)]
    if args.mode == "headless":
        command.append("--headless")
    else:
        command.extend(["--resolution", args.resolution, "--position", args.position])
    if args.quit_after > 0:
        command.extend(["--quit-after", str(args.quit_after)])
    command.extend(["--audio-driver", "Dummy", "--path", str(project), args.scene])
    if args.user_arg:
        command.append("--")
        command.extend(args.user_arg)

    creationflags = subprocess.CREATE_NO_WINDOW if sys.platform == "win32" else 0
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=args.timeout,
            creationflags=creationflags,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        print(f"Godot job timed out after {args.timeout:.1f}s", file=sys.stderr)
        if exc.stdout:
            print(exc.stdout)
        if exc.stderr:
            print(exc.stderr, file=sys.stderr)
        return 124

    if result.stdout:
        print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, end="", file=sys.stderr)
    combined = f"{result.stdout}\n{result.stderr}"
    engine_errors = [
        line
        for line in combined.splitlines()
        if line.lstrip().startswith(("SCRIPT ERROR:", "ERROR:"))
    ]
    if engine_errors and not args.allow_engine_errors:
        print(
            f"Godot reported {len(engine_errors)} engine/script error line(s)",
            file=sys.stderr,
        )
        return 3
    missing = [token for token in args.expect if token not in result.stdout]
    if missing:
        print(f"Missing expected output: {missing}", file=sys.stderr)
        return 2
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
