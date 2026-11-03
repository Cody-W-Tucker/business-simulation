# Godot MCP Operating Contract

## Handshake before engine work

Inventory the exposed Godot MCP tools and call `get_capabilities` or a semantic equivalent when available. Record the server version, Godot version, executable, and capability flags. Apply the feature-based matrix and remediation rules in `mcp-compatibility.md`; do not depend on exact tool names.

Asset work requires loaded-scene inspection and owned background jobs. Pixel review additionally requires safe off-desktop rendering and silent audio. If no equivalent tool or owned-runner adaptation satisfies a required capability, stop that part of the workflow; do not claim runtime or scene evidence from source-text guesses.

Bind every operation to the intended `project.godot` and pinned Godot executable. When available, use MCP project information; Godot AI 4.3.1 exposes project path and version through `session_manage(op="list")` and editor state. Inspect loaded scenes before and after construction using scene/node/resource tools or a project-side audit runner. Collect applicable bounds, nodes, mesh/MultiMesh counts, instance buffers, authored MultiMesh bounds, rendered triangles, materials, collisions, lights, particles, and non-uniform scales. Do not assume one hierarchy call provides all metrics.

## Run owned jobs safely

Use a compatible MCP job tool when available, or a harness-owned shell job, for builders, contract tests, traversal probes, performance probes, and captures. Specify:

- the absolute project directory and `res://` runner scene;
- headless mode for non-pixel work or a verified off-desktop display for screenshots/benchmarks;
- runner arguments for target, manifest, report, routes, and output paths;
- a bounded timeout and an expected completion marker;
- any frame limit only as a crash safeguard, not as proof of completion.

For a shell job, enter the project's prescribed environment and use its pinned Godot binary. Launch a fresh, owned process with a bounded timeout; capture stdout and stderr, exit status and elapsed time. Ensure timeout cleanup covers the owned process and its children without signaling unrelated processes, and verify that behavior with a small safe smoke job. Do not use a broad process-name kill. For rendering, use an isolated virtual display or another verified off-desktop backend and Dummy audio; do not capture input or reuse the user's editor/game. Use unique output paths and validate that outputs were freshly produced. Treat timeout, missing marker, nonzero exit, or engine error as failure unless the contract explicitly permits that error. If the shell/harness cannot guarantee safe cleanup or an isolated display, stop the affected job and report the limitation.

## Match the tool to the evidence

- Structural claim: loaded-scene inspection or an audit runner and contract JSON.
- Generated result: builder marker plus round-trip reload.
- Traversal claim: owned runtime route probe using the real controller when possible.
- NPC reachability: NavigationServer path query after map synchronization.
- Performance claim: fixed-camera before/after runtime reports.
- Visual claim: render job screenshots plus direct image inspection.

Source-scene inspection does not replace live runtime-tree, input, or frame metrics. Obtain those through a project-side runner launched by an owned bounded job.

## Fallback boundary

Read-only file inspection may diagnose an unavailable MCP but is not loaded-scene evidence. Do not silently fall back to Blender, downloaded assets, a visible editor, broad process termination, or an unowned Godot launch. If the executable/project cannot be identified safely, stop and report the missing prerequisite.

Do not modify or install MCP code as an implicit fallback. Follow the permission-gated extension protocol in `mcp-compatibility.md` only after the user explicitly authorizes that separate change.
