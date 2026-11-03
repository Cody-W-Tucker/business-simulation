# Multi-angle Visual Review

## Design the shot set

Use matched distance, focal length, target height, lighting, and time for comparable views.

- Capture front, back, left, and right for isolated props or buildings.
- Add two three-quarter views when depth, roof, or layered construction matters.
- Add player-height approach and interaction views for doors, bridges, signs, and cover.
- Add one world-context view to judge scale, palette, terrain contact, and neighboring composition.
- Add courtyard and interior views for enterable buildings, plus a distant source-location view when the landmark must read from a village, road, or spawn.
- Add native-resolution detail views for every unique opening and critical roof/foundation junction. Capture openings from outside and inside; capture removable roofs both visible and hidden.
- Temporarily hide occluding neighbors only for diagnostic elevation shots; keep context shots honest.

## Run the construction-junction pass

Composition views prove the whole; they do not prove the joins. After cardinal review, inspect these interfaces at 100% pixel scale:

| Interface | Required views | Reject when |
| --- | --- | --- |
| Ridge, eaves, valleys | both roof slopes and one grazing angle | sky/background sliver, z-fighting, unsupported edge |
| Roof to each gable | exact cardinal plus three-quarter | uncovered attic edge or triangle ending before the roof |
| Chimney/roof penetration | uphill and downhill sides | floating chimney, open cut, missing overlap/flashing |
| Wall/foundation/terrain | grazing exterior views | floating wall, exposed underside, hard terrain crack |
| Door/window assembly | outside and inside close-ups | raw wall reveal, detached pane, trim/opening mismatch, light leak |
| Revealable shell | visible and hidden states | exterior hole when visible or leftover roof pieces when hidden |

Use a high-contrast background or lighting angle when a seam could blend into the environment. Inspect the saved source image, not only a scaled chat preview. A valid image-statistics report does not pass this gate. Record each interface as `pass`, `fixed`, or `not_applicable`; do not mark the building complete while any applicable row is unreviewed.

## Review in this order

1. Silhouette and proportions.
2. Scale relative to player and nearby assets.
3. Ground contact, seams, intersections, and floating geometry.
4. Functional openings, traversal, sightlines, and interaction reach.
5. Material family, value grouping, repetition, and texture scale.
6. Secondary structure: supports, joints, drainage, access, and believable construction.
7. Lighting across representative day, dusk, night, and weather states when relevant.
8. Paired transforms such as roof slopes, doors, and mirrored towers; cardinal views expose reversed rotation signs that a three-quarter hero view can hide.
9. Construction joins at native resolution, including both faces of openings and shell reveal states.

## Iterate from evidence

- Name each capture by angle and pass.
- Keep the generated `review_report.json`; use its resolution and luminance statistics to catch blank, black, or clipped captures before visual inspection.
- Fix the largest perceptual defect first.
- Recapture every angle affected by geometry or material changes.
- Keep the accepted final views in project documentation when the repository tracks visual deltas.
- Do not accept an asset because one hero angle looks good.
- Reposition diagnostic cameras when foreground roofs or walls hide the subject, but retain at least one honest player-route context view.

## Pair visual and physical checks

- Report script, shader, and import errors alongside screenshots.
- Probe collision bounds, traversal, roof/interior behavior, and required metadata.
- Run focused tests during iteration and the full project suite before handoff when integration risk is broad.
- Treat image statistics as capture diagnostics, not an aesthetic score. The agent must still inspect every accepted image.
