# Project Style and Composition

## Build a style profile

Select three to eight project references that match the requested asset's role, distance, biome, and importance. Prefer immediate neighbors and repeatedly used modular kits over one exceptional hero asset.

Record:

- material resource paths, base colors, roughness, metallic, emission, transparency mode, and shader family;
- texture resolution and apparent world scale;
- mesh bounds and ratios such as door-to-player, wall thickness, roof pitch, trunk height, canopy width, and prop spacing;
- silhouette families: blocky, tapered, faceted, rounded, asymmetric, ruined, or ornamented;
- value grouping and accent colors;
- geometric density by importance and viewing distance;
- repetition strategy, controlled variation, and how edges meet the ground;
- construction language: visible beams, stone courses, buttresses, arches, supports, drainage, thresholds, and roof overhangs.

Persist a small `style_profile.json` beside the asset when the project tracks generated contracts. Otherwise include the same fields in the asset manifest.

## Compose before decorating

Review in this order:

1. Primary silhouette and relationship to the skyline.
2. Large masses and believable structural support.
3. Entrance, focal point, and player-readable route.
4. Rhythm of repeated elements and intentional breaks.
5. Negative space: clearing, courtyard, gaps, windows, alleys, and breathing room.
6. Secondary landmarks that explain scale and function.
7. Material grouping and surface variation.
8. Small dressing only where it reinforces use, history, or navigation.

Do not distribute details uniformly. Create gradients: denser near shelter and use, sparse along maintained routes, clustered by ecological or human cause, and quieter around the main focal shape.

## Avoid procedural-looking results

- Vary scale, rotation, spacing, and species within bounded ranges; do not randomize every property independently.
- Use a few authored clusters and gaps rather than uniform noise.
- Break perfect symmetry only where structure still reads as load-bearing and intentional.
- Keep repeated proxies in the same silhouette/material family as detailed source models.
- Spend geometry on the outline, openings, roofline, joints, and interaction points; use materials for micro-detail.
- Reuse the project's dirt, stone, wood, foliage, and plaster values instead of inventing parallel palettes.

## Evaluate visual evidence

For each accepted view, answer:

- Is the intended subject immediately readable?
- Does its scale agree with the player and neighbors?
- Is there a clear focal hierarchy rather than equal visual noise?
- Do repeated elements show rhythm without looking cloned or purely random?
- Do negative spaces create usable routes and compositional rest?
- Do materials share the project's value, saturation, and texture scale?
- Are supports, thresholds, roofs, walls, and terrain joins physically plausible?
- Does the asset still read from its important gameplay distance?

Fix the highest-impact failed answer before adding more detail.
