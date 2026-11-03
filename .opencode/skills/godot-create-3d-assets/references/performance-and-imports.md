# Godot-native Asset Budgets and Imports

## Persist an asset contract

Copy `assets/asset_manifest.json` beside the generated scene and adapt it before building. Keep meters, forward axis, ground origin, interaction sides, collision strategy, review framing, and budgets explicit. Replace its measured values after generation; do not leave guessed counts in the final manifest.

Use budgets as project-adjustable starting constraints, not universal quality scores:

- Repeated dressing: minimize nodes and materials; prefer a shared mesh/material and regional `MultiMeshInstance3D` when instances are non-interactive.
- Unique prop: spend geometry on silhouette and interaction readability, not hidden faces or micro-detail.
- Landmark/building: allow more structure, but require context views, traversal checks, and visibility ranges or LOD only when measured cost or viewing distance justifies them.

Audit total nodes, mesh instances, MultiMesh draw nodes and elements, rendered triangles, unique materials, lights, particles, collision shapes, concave collision shapes, and collision triangles with `assets/asset_contract_test.gd`. Fail declared budgets rather than silently accepting growth. Count MultiMesh base-mesh triangles multiplied by its instance count so node reduction cannot hide excessive geometry. A large landmark may justify more geometry, but hundreds of nodes or one collider per visible part require an explicit simplification pass.

Count structure as well as geometry:

- Merge static same-material details when they do not need individual scripts, visibility, or interaction.
- Use a spatially appropriate `MultiMeshInstance3D` for repeated non-interactive pieces such as merlons, roof tiles, posts, or stones.
- Make collision describe walkable floors, blocking walls, stairs, and cover—not decorative mesh decomposition.
- Keep primitive collision around openings split only where traversal needs it. Omit collision from trim, braces, furniture legs, foliage, and unreachable detail.
- Save deterministic builder output as a packed scene and instance it from the authored map. Do not rerun a static asset builder during gameplay.

## Reuse repository models safely

- Reuse GLB or scene assets already licensed and present in the project; do not call an external model generator.
- Instantiate through `PackedScene`, inspect the merged AABB, pivot, forward axis, surface materials, and animation names in Godot.
- Preserve instanced-scene ownership. Set the instance root owner when packing a parent scene, but do not recurse into and inline its imported children.
- Use primitive collision derived from gameplay needs and measured bounds. Avoid mesh collision for movable objects or repeated dressing.
- Avoid non-uniform scale on parents of collisions, lights, or physics bodies. Bake dimensions into primitive meshes or use uniform instance scale.

## Keep rendering cost intentional

- Reuse existing material resources and shader configurations. Count unique materials in the audit.
- Prefer opaque materials. Use alpha scissor/hash for cutouts already supported by project art; avoid broad alpha-blended environmental surfaces.
- Partition large MultiMeshes spatially so whole regions can be culled.
- Add visibility ranges or LOD for numerous or distant assets after measuring, not automatically for one nearby landmark.
- Generate normals for custom triangle meshes and fix winding instead of disabling culling as a blanket workaround.
- Keep dynamic lights and particle emitters within the manifest budget and verify representative night/weather frames when they affect the asset.
