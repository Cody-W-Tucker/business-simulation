# Asset Profiles and Evidence Gates

Choose one primary profile. Add secondary gates only when the asset genuinely crosses categories. Budgets are project-adjustable starting points, not universal quality scores.

## Prop

Use for furniture, signs, shrines, wells, carts, milestones, and small reusable set dressing.

Require:

- local origin and forward axis;
- scale comparison against the player or a neighboring prop;
- four cardinal isolated views plus one in-world view;
- ground contact and interaction reach when applicable;
- primitive collision only when gameplay needs blocking or interaction;
- a compact node/material budget and no unique runtime script for inert repetition.

Starting budget: 40 nodes, 16 mesh instances, 12 surfaces, 12,000 rendered triangles, 4 materials, 4 collision shapes, no dynamic light.

## Enterable building

Use for houses, taverns, keeps, shops, chapels, towers, and other structures with usable interiors.

Require:

- measured terrain footprint and foundation strategy;
- front/back/left/right, two three-quarter, roof, player approach, and every interior room;
- a construction-junction matrix covering ridge, both roof-to-gable edges, eaves, roof penetrations, wall/foundation contact, and every unique opening;
- native-resolution close-ups of every unique door/window from outside and inside, plus roof-reveal states with the shell visible and hidden;
- complete player routes from natural terrain through every required door, stair, ramp, floor, and exit;
- two off-happy-path routes such as side approach, reverse traversal, narrow landing, or door opened/closed;
- navigation reachability for NPC-accessible rooms;
- door height/width compared with the real controller capsule;
- roof/interior reveal compatibility and stable interaction node paths;
- no background-visible slivers, raw opening edges, floating panes, uncovered attic edges, or trim that fails to meet its surrounding wall;
- representative day and night views when built-in lighting matters.

Starting budget: 220 nodes, 80 mesh instances, 120 surfaces, 350,000 rendered triangles, 16 materials, 36 collision shapes, 6 lights. Exceed only with measured justification.

## Landmark

Use for castles, large ruins, monuments, hilltop structures, bridges, and distant composition anchors.

Require:

- source-location views from village, road, spawn, or another named vantage;
- silhouette readability at near, middle, and far distances;
- foundation and all required approaches tested against the live terrain;
- LOD, HLOD, visibility ranges, or an explicit measured reason they are unnecessary;
- performance delta from at least one distant and one near camera;
- collision only for reachable gameplay surfaces;
- direct packed-scene integration rather than a large runtime builder.

Starting budget: 300 nodes, 100 mesh/MultiMesh draw nodes, 650,000 rendered triangles, 24 materials, 56 collision shapes, 8 lights.

## Vegetation region

Use for forests, groves, orchards, hedgerows, grass regions, rock fields, and dense repeated dressing.

Require:

- authored boundary, density gradient, ecological variation, negative space, clearings, and approach corridors;
- spatial MultiMesh partitions sized for the project's view distance;
- serialized transform buffer for every populated MultiMesh;
- a conservative `custom_aabb` for every MultiMesh draw node;
- distribution extents that prove instances are not stacked at the origin;
- collision only on primary trunks/rocks near gameplay routes;
- runtime scatter exclusion so global procedural systems do not overlap the authored region;
- player and navigation route checks through intended clearings;
- overhead, four edge, interior, and distant world-context views;
- near/mid/far performance deltas, including draw calls and p95 frame time.

Starting budget per regional scene: 160 nodes, 100 MultiMesh draws, 5,000 elements, 600,000 rendered triangles, 24 materials, 64 primitive collisions. Partition larger biomes into multiple scenes.

## Terrain feature

Use for painted roads, paths, hills, ramps, riverbanks, causeways, clearings, and terrain-seated structures whose primary contract is ground continuity.

Require:

- center, corners, 2-4m footprint grid, both edges, and each approach sampled from the project's real height provider;
- one authoritative route/footprint reused for paint, vegetation clearance, navigation, and tests;
- the project's established Terrain3D/control-map representation instead of a mismatched overlay;
- grazing-angle screenshots to reveal floating ribbons and long triangles;
- player traversal in both directions across every join;
- grass/tree/fence exclusions derived from the same geometry;
- no collider or foundation crossing a visually open gate or causeway.

Starting budget depends on route length. Declare triangles per meter, sample spacing, material additions, collision pieces, and maximum added draw calls.

## Evidence matrix

For each user-visible or gameplay claim, record one primary evidence source:

| Claim type | Primary evidence |
| --- | --- |
| Structure exists and is reusable | `inspect_scene` plus packed-scene path |
| Scale and style belong to the project | named references plus contextual screenshots |
| Player can traverse | real-controller runtime route |
| NPC can reach | NavigationServer path result |
| Terrain contact is continuous | sampled height/profile report plus grazing views |
| Repetition is efficient | MultiMesh buffers, partitions, bounds, and runtime draw calls |
| Performance is acceptable | fixed-camera before/after benchmark |
| UI or interaction works | runtime input/state evidence, not node presence alone |

Do not use screenshots to prove collision or scene metrics to prove visual quality.
