# Godot 3D Production Patterns

## Choose a construction method

- Compose existing scenes for style-matched props, architecture kits, furniture, and foliage.
- Use `PrimitiveMesh` for beams, walls, foundations, posts, planks, stones, and low-poly markers.
- Use `SurfaceTool` for wedges, gables, paths, custom silhouettes, or vertex colors.
- Use `MultiMeshInstance3D` for repeated non-interactive details.
- Use a shader instead of dense geometry for grain, mottling, stains, roof courses, or subtle variation.

## Keep a generator reproducible

- Store the builder in `tools/build_<asset>.gd` with a small runner scene.
- Save output to an ordinary project scene such as `world/generated/<asset>.tscn`.
- Make regeneration deterministic: fixed seeds, explicit dimensions, stable names.
- Assign `owner` recursively before packing procedurally created children.
- Do not recurse into instantiated scenes while assigning ownership; preserve the instance instead of inlining its internal nodes.
- Check `ResourceSaver.save()`, reload the saved `PackedScene`, instantiate it, and compare structural counts against the builder tree.
- Write the final measured bounds and cost metrics into the asset manifest.
- Print one unambiguous completion marker only after round-trip validation succeeds.
- Treat the builder as source and the generated scene as output.

## Preserve scale and orientation

- Use meters: a human door normally needs meaningful clearance above and beside the actual controller capsule.
- Inspect imported model pivots and AABBs instead of assuming kit units.
- Establish the asset's forward direction and interaction side in the contract.
- Test terrain contact from more than one angle; bury tiny seams instead of leaving floating bases.

## Seat large assets on real terrain

- Treat terrain contact as a profile, not one Y coordinate. Sample the rotated footprint center, corners, a 2-4m interior grid, and each approach axis through the live project height provider.
- Express samples relative to the asset origin. Choose a flat site, a stepped buried foundation, or a ramp from measured height differences instead of guessing transforms.
- Use an origin contract such as `terrain_contact` when visible foundation geometry intentionally extends below ground; `ground_center` audits should otherwise expect the visible base near Y=0.
- Primitive collision has no subtraction. Split plinth and foundation boxes around gates, tunnels, stairs, and causeways; a visually open portal can still meet a full-width buried collider.
- Derive a ramp from its two measured endpoints. Overlap the terrain-facing end slightly and match the destination floor height so the controller encounters a slope rather than a vertical lip.

## Build collision deliberately

- Keep `CollisionShape3D` under its `CollisionObject3D` parent.
- Prefer simple boxes/capsules for architecture and traversal.
- Keep decorative braces, signs, foliage, and tiny stones non-colliding unless gameplay needs them.
- Validate passages with the real player body or a matching shape, not only rays.
- Separate the visible threshold from a shallow physical ramp when the controller cannot step up.
- Test the full route from natural terrain through every ramp and portal. Log final local position and slide colliders when movement stalls; an upward collision normal often identifies the active ramp, while a lateral normal exposes a hidden wall or foundation edge.

## Close construction interfaces

- Derive paired roof and gable endpoints from the same pitch/span values. Extend the gable slightly behind the roof underside so raster precision, bevels, or a cardinal camera cannot expose the background.
- Give ridges, eaves, valleys, flashing, and roof penetrations intentional overlap. Avoid exact coplanar joins: they can expose hairline gaps or z-fight at distance.
- Model each opening as `wall opening -> exterior trim -> pane/leaf -> interior trim`. Make trim outer extents meet or overlap the wall opening and make the pane overlap the trim's inner aperture by a small hidden margin.
- Inspect openings from both sides. Exterior trim does not conceal a raw or oversized opening from an interior camera, especially when a roof or upper shell is hidden.
- Keep a compact junction table in the manifest or builder comments with opening size, trim outer/inner size, pane size, recess, and planned overlap. Assert these dimensions in the builder when it owns them.
- Prefer shared meshes or one MultiMesh batch for repeated trim pieces; construction closure should not require one draw call per jamb.

## Build terrain-following roads and paths

- Inspect the established road representation first. If the project paints roads into a Terrain3D colormap or control map, extend that baker and its existing dirt/wear palette; do not add an overlay mesh.
- Store each route's polyline and width once. Reuse that source for paint falloff, grass/tree/rock clearance, navigation, and automated samples so visuals and gameplay cannot drift apart.
- Clear vegetation only inside the maintained core and retain a soft painted shoulder. Review both from above and at player height.
- Use a ribbon for raised, physically distinct, or project-native mesh roads. Resample bends every 2-3m, sample both edges from the live terrain provider, and lift only 0.05-0.15m to prevent z-fighting.
- Verify ribbon winding and continuity from grazing and distant angles; long triangles can cut through rolling terrain even when endpoints are grounded.

## Integrate without breaking contracts

- Search for node paths, groups, metadata, scripts, and tests that reference the replaced asset.
- Preserve stable root names and required child paths when feasible.
- Keep roofs or removable shells grouped beneath the node expected by interior reveal systems.
- Avoid editing generated `.import`, `.uid`, cache, or third-party addon files.

## Control cost

- Share materials and meshes where possible.
- Avoid one newly allocated material per part when a shared resource or instance shader parameter can express the variation.
- Use one coarse collider for a walkable surface rather than one per plank.
- Add geometry where it changes silhouette or scale perception; use materials for micro-detail.
- Measure before introducing LOD. Optimize repeated world dressing before unique landmarks.
