# Godot MCP Operating Contract

## Handshake before engine work

Inventory the exposed Godot MCP tools and call `get_capabilities` or a semantic equivalent when available. Record the server version, Godot version, executable, and capability flags. Apply the feature-based matrix and remediation rules in `mcp-compatibility.md`; do not depend on exact tool names.

Asset work requires loaded-scene inspection and owned background jobs. Pixel review additionally requires safe off-desktop rendering and silent audio. If no equivalent tool or owned-runner adaptation satisfies a required capability, stop that part of the workflow; do not claim runtime or scene evidence from source-text guesses.

Use `get_project_info` to bind every operation to the intended `project.godot`. Use `inspect_scene` before and after construction for loaded-resource metrics: bounds, nodes, mesh/MultiMesh counts, instance buffers, authored MultiMesh bounds, rendered triangles, materials, collisions, lights, particles, and non-uniform scales.

## Run owned jobs safely

Use `run_godot_job` for builders, contract tests, traversal probes, performance probes, and captures. Pass:

- the absolute project directory and `res://` runner scene;
- `mode=headless` for non-pixel work or `mode=render` for screenshots/benchmarks;
- `user_args` for target, manifest, report, routes, and output paths;
- a bounded `timeout_seconds` and an `expected_output` completion marker;
- `quit_after` as a crash safeguard, not as proof of completion.

The MCP starts only its own child process, uses Dummy audio, positions render windows off-desktop, never reuses or terminates the user's editor/game, and returns stdout, stderr, timing, exit reason, and detected engine errors. Treat timeout, missing marker, nonzero exit, or engine error as failure unless the contract explicitly permits that error.

## Match the tool to the evidence

- Structural claim: `inspect_scene` and contract JSON.
- Generated result: builder marker plus round-trip reload.
- Traversal claim: owned runtime route probe using the real controller when possible.
- NPC reachability: NavigationServer path query after map synchronization.
- Performance claim: fixed-camera before/after runtime reports.
- Visual claim: render job screenshots plus direct image inspection.

Current source-scene inspection does not replace live runtime-tree, input, or frame metrics. Obtain those through a project-side runner launched by `run_godot_job`.

## Fallback boundary

Read-only file inspection may diagnose an unavailable MCP. Do not silently fall back to Blender, downloaded assets, a visible editor, broad process termination, or an unowned Godot launch. If the executable/project cannot be identified safely, stop and report the missing prerequisite.

Do not modify or install MCP code as an implicit fallback. Follow the permission-gated extension protocol in `mcp-compatibility.md` only after the user explicitly authorizes that separate change.
