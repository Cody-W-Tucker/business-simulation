---
name: godot-create-3d-assets
description: Create, rebuild, optimize, integrate, and visually validate stylized Godot 4 3D assets and environments through the Godot MCP. Use for props, enterable buildings, landmarks, vegetation regions, terrain features, roads, modular environments, procedural meshes, materials, collisions, navigation, performance audits, and multi-angle in-world review without Blender or online asset generators.
---

# Godot-native 3D Asset Builder V2.2

Create game-ready assets using the agent, the project's existing resources, Godot 4, and the Godot MCP. Treat style discovery, construction, integration, gameplay validation, runtime cost, screenshots, and iteration as one evidence-producing workflow.

## Keep the stack Godot-only

- Do not use Blender, external DCC applications, online model generators, paid APIs, or downloaded asset libraries.
- Reuse models, textures, shaders, materials, and modular scenes already licensed and present in the repository.
- Author missing forms with Godot primitives, `SurfaceTool`, `ArrayMesh`, shaders, and deterministic GDScript builders.
- Save static results as ordinary `PackedScene` resources and instance them from the authored world. Never rebuild static landmarks during gameplay.

## Establish the MCP session

1. Read repository instructions and inspect existing Godot processes without stopping them.
2. Inventory the exposed Godot MCP tools, then call `get_capabilities` or its semantic equivalent when available. Build a capability matrix instead of depending on exact tool names.
3. Require project binding, loaded-scene structural inspection, and owned bounded headless jobs for all asset work. Also require off-desktop rendering and silent audio for pixel review. Verify claimed safety behavior with a small smoke job before relying on it.
4. Adapt around missing optional features. Project-side runners may replace runtime-tree, input, direct-screenshot, MultiMesh-detail, and performance-monitor tools when owned jobs remain available. Missing scene-editing tools are not a blocker because deterministic builders can author scenes.
5. If a required capability is absent, stop the affected workflow and provide a remediation report. Never modify, install, rebuild, or reconfigure the user's MCP without explicit authorization. When authorized and source is available, implement only the smallest missing capability, test it, build it, and explain that the MCP client must restart before the new tool exists.
6. Use version, project-info, and scene-inspection tools to confirm the project, neighboring scenes, real bounds, materials, collision structure, MultiMesh state, and current errors. Use the owned job tool for builders, tests, probes, benchmarks, and captures.

Read `references/mcp-compatibility.md` for capability negotiation and the permission-gated extension workflow. Read `references/mcp-and-cli.md` for the safe job contract.

## Select an asset profile

Choose exactly one primary profile: `prop`, `enterable_building`, `landmark`, `vegetation_region`, or `terrain_feature`. Copy the matching contract from `assets/manifests/` and adapt it beside the output scene. Read `references/asset-profiles.md` for required evidence, default budgets, and profile-specific gates.

## Build an evidence contract

Before editing, record:

- footprint, height, origin, forward axis, silhouette goal, and interaction sides;
- three to eight project style references and why each applies;
- player, NPC, door, stair, ramp, clearing, or approach clearances;
- terrain samples and required routes in asset-local coordinates;
- critical construction interfaces, intended overlap/reveal tolerances, and the close-up views that will prove each interface from every visible side;
- node, mesh, MultiMesh, triangle, material, light, particle, shadow, and collision budgets;
- isolated, integrated, player-height, distant, interior, and weather review views as applicable;
- every final claim and the structural, runtime, performance, or screenshot evidence that will prove it.

Add at least two off-happy-path checks for enterable, interactive, terrain-integrated, or navigation-affecting assets.

## Derive the project style

Inspect representative neighboring assets rather than relying on a generic medieval style. Record palette, material values, texture scale, silhouette families, proportions, density, repetition, detail level, and construction language. Read `references/style-and-composition.md` before significant visual authorship.

## Construct with the least complex suitable method

1. Compose existing scenes when their style and scale match.
2. Use MCP scene operations for small, inspectable node changes.
3. Use a typed, seeded one-shot builder for custom or repeated geometry. Adapt `assets/asset_builder.gd` and the helpers under `assets/geometry/`.
4. Use shared meshes/materials and spatially partitioned `MultiMeshInstance3D` for repeated non-interactive elements.
5. Give every authored MultiMesh a valid buffer and conservative `custom_aabb`; partition it so culling and LOD do not treat an entire region as one object.
6. Build collision from gameplay requirements, not visible decomposition. Keep decoration non-colliding and split primitive foundations around openings.
7. Preserve one authoritative route definition for terrain paint, vegetation clearance, navigation, and tests.
8. Close visible construction envelopes deliberately. Match or slightly overlap roof/gable, ridge, eave, wall/foundation, frame/wall, pane/frame, and chimney/roof interfaces. Treat every door and window as a layered assembly with exterior and interior trim; do not rely on distance, darkness, or a similar background color to hide gaps.

Read `references/godot-3d-patterns.md` for mesh, collision, terrain, imported-resource, and packed-scene patterns.

Copy each runner `.tscn` together with its same-named `.gd`; their relative resource links keep the pair portable inside a project-local tooling folder. Update builder output paths and manifest paths before running it.

## Validate before visual review

1. Reload the saved scene and run `inspect_scene`. Reject missing meshes, empty bounds, lost MultiMesh buffers, missing authored bounds, excessive materials, or budget regressions.
2. Run `assets/asset_contract_test.tscn` with the target and manifest. Retain its JSON audit.
3. Assert authored interface dimensions when the builder owns them: opening versus trim extents, pane overlap behind trim, paired roof endpoints, and foundation overlap. Reject zero-margin coplanar joins and unexplained background-visible gaps.
4. For required routes, move the real project player or a manifest-matched body through the complete approach and interior. Use `assets/route_probe.tscn` only when the real controller cannot be isolated.
5. Validate NavigationMesh/path reachability separately from physics; neither proves the other. Prefer the project's NPC harness, with `assets/navigation_probe.tscn` as the isolated fallback.
6. Benchmark integrated cost with `assets/performance_probe.tscn`, including warm-up, average and p95 frame time, draw calls, object counts, and render memory. Prefer before/after deltas over universal FPS claims.

Read `references/performance-and-imports.md` when setting budgets, using MultiMesh/LOD, reusing imports, or interpreting runtime cost.

## Review and iterate from pixels

Capture both isolated and honest in-world views through MCP render jobs. Save timestamps, scene modification time, framing, and luminance diagnostics in `review_report.json`. Inspect every accepted image yourself at native resolution; image statistics only detect broken captures.

For buildings and layered props, run a construction-junction pass after the composition pass. Capture tight diagnostic views of roof ridge/eaves/gables and penetrations, wall/foundation contact, every unique door or window from outside and inside, and revealable shells both visible and hidden. Reject background-colored slivers, light leaks, raw wall openings, floating panes, trim that does not meet plaster, or a gap concealed by foliage or shadow. Read `references/visual-review.md` for the junction matrix and acceptance rules.

Fix the highest-impact defect first, then recapture every affected angle and rerun affected contracts. Do not accept an asset from one hero view or from structural metrics alone. Read `references/visual-review.md` for shot design and the visual rubric.

## Protect the user's session

- Keep audio on the Dummy driver and render windows off-desktop.
- Never launch an editor unless the user explicitly asks.
- Never capture or lock the mouse.
- Never call a broad process stop. Let `run_godot_job` terminate only its own child on timeout.
- Treat stale screenshots, missing expected-output markers, engine errors, and a frame-limit exit as failures.

## Complete only with evidence

Require all applicable gates: valid packed-scene round trip; style references recorded; correct scale/orientation; closed construction-junction matrix; current MultiMesh buffers and bounds; primitive collision aligned to gameplay; player and navigation routes passing; terrain contact sampled; interactions and save metadata preserved; budgets passing; before/after performance recorded; isolated, junction-detail, interior, and contextual screenshots visually inspected at native resolution; relevant project tests passing; and no disturbance to the user's existing Godot session.
