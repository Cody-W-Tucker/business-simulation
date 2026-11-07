# Office hardware props

Project-owned primitive meshes, authored for the office's 1 unit = 1 metre
scale. Origins are at the bottom centre; the visible front faces +Z. Thin clients
and workstations are decorative and have no collision. The server cabinet has
a single box collider.

The proportions, dark equipment colour, and matte finish follow the existing
office monitors, desks, and dividers in `scripts/build_office.gd`. Instances
are placed by that builder; the committed office scene is the generated result.

The upstairs network closet sits inside the west end of the IT and engineering
office, reusing its floor, ceiling, and exterior walls. Glass partitions enclose
it, with a 1.4-metre clear entrance between frame posts, an open glass door, and
a collidable server rack.
The office smoke test checks the equipment counts, doorway, and glass collision.
