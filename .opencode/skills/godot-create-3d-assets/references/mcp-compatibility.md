# Godot MCP Compatibility and Extension Protocol

## Negotiate capabilities, not product names

Inventory the Godot MCP tools exposed to the current agent. Call `get_capabilities` when present, but do not reject a server only because that exact tool or naming convention is absent. Map tools by their inputs, outputs, process ownership, and observable behavior. Treat a capability claim as provisional until a safe smoke operation succeeds.

Record a table with `capability`, `provider/tool`, `status`, `fallback`, and `action`. Use `available`, `adapted`, `missing`, or `unverified` as status values. Include the server version, Godot version/path, bound project, client, and any restart requirement without recording credentials or private configuration values.

## Capability tiers

### Core requirements

Require these for every completed asset workflow:

- **Project binding:** identify the intended `project.godot` and Godot version before mutation.
- **Loaded-scene inspection:** load a scene through Godot and report nodes, meshes, bounds, materials, collision, lights, particles, and warnings. A source-text scan alone is insufficient.
- **Owned bounded jobs:** an MCP tool or harness-owned shell job must launch only its own processes and support timeouts, exit codes, captured output, completion markers, and cleanup without stopping an editor or unrelated game. Verify these properties before relying on them.
- **Headless execution:** run builders, contract tests, traversal probes, and audits without opening a visible window.

If any core requirement is missing and no behaviorally equivalent MCP tool exists, stop before engine claims or integration.

### Task-required capabilities

Require these when the requested evidence needs them:

- **Off-desktop render jobs** for screenshots and native-resolution visual review.
- **Silent audio** for any render job; prefer the Dummy driver.
- **MultiMesh/bounds inspection** for repeated vegetation or modular regions.
- **Navigation and runtime execution** for enterable or traversal-affecting assets.
- **Timing and render metrics** for performance claims.

An owned project-side runner may satisfy MultiMesh, navigation, runtime, and performance evidence. Pixel review still requires a safe render path.

### Optional conveniences

Do not block work merely because direct scene editing, runtime-tree inspection, runtime input injection, viewport screenshot, or live performance-monitor tools are absent. Prefer deterministic GDScript builders and the bundled audit, route, navigation, performance, and review runners.

## Adaptation order

1. Use an MCP tool that directly satisfies the behavior and safety contract.
2. Use an equivalent MCP tool under a different name after checking its schema and a smoke result.
3. Use a bundled or project-side runner launched by a bounded, owned harness shell job under the contract in `mcp-and-cli.md`. For inspection, load the actual scene and emit the required metrics; source text alone is not equivalent.
4. Report any capability still missing and the smallest remediation. Do not silently use Blender, a visible editor, an unowned Godot process, broad process termination, or unverifiable source inspection. A missing MCP job tool alone is not a blocker when the harness shell satisfies the same contract.

### Known server profile: Godot AI 4.3.1

The connected Godot AI 4.3.1 server exposes `session_manage`, `editor_state`, `scene_get_hierarchy`, `node_get_properties`, `resource_manage`, `editor_screenshot`, `project_run`, and `test_run`; it does not advertise `get_capabilities`, `inspect_scene`, or `run_godot_job`. Confirm the catalog and session at runtime rather than assuming this profile. Session information can bind the project and version; hierarchy and node/resource inspection can inspect an open scene. Use a loaded-scene audit runner for metrics those tools do not expose, and an owned shell job for bounded tests or off-desktop captures. Do not treat `project_run` as an owned bounded job: it targets the editor's game and can reuse an existing run or autosave. `editor_screenshot` is useful when its source is safe and current, but is not proof of an isolated, owned render job.

Do not weaken an evidence gate to match the available tools. Mark the affected claim unverified instead.

## Remediation report

When blocked, report:

- detected server/client versions and the bound project;
- the missing semantic capability and why the task needs it;
- tools examined and why they are not equivalent;
- whether a bundled runner can safely adapt around it;
- the minimum MCP change, build command, tests, and restart step;
- what work can continue without that change.

Ask for authorization only after producing this report. A request to create an asset does not authorize MCP installation or source modification.

## Permission-gated MCP extension

Proceed only when the user explicitly authorizes MCP modification and the server source or a user-approved extension repository is available.

1. Locate the active server command and source checkout without exposing environment values or credentials. Confirm which checkout actually backs the client configuration.
2. Inspect repository instructions, license, status, build scripts, tool registration, schemas, tests, and process-management code. Preserve unrelated and uncommitted changes.
3. Prefer a small adapter or one new tool over replacing the server. Keep request parameters explicit and avoid shell-string interpolation.
4. For job execution, enforce child-process ownership, bounded timeouts, Dummy audio, off-desktop windows, structured stdout/stderr, expected-output checks, and cleanup of only the spawned child.
5. Add tests for schema validation, paths with spaces, timeout, missing completion markers, nonzero exits, engine-error detection, process ownership, and command-injection resistance. Test supported operating systems when the change is intended to be portable.
6. Build and validate the server. Do not edit the MCP client configuration, install global packages, or replace an installed server unless separately authorized.
7. Explain that the running client cannot discover the new schema dynamically. Ask the user to restart or reconnect it, then repeat capability negotiation and the smoke test.

If source is unavailable, closed, or cannot be mapped to the active server, do not reverse engineer or patch binaries. Offer a manual upgrade path or a separate open-source adapter.
