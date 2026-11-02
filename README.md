# The Whiteboard Room

A Godot 4 open landscape with four freestanding whiteboards. The middle board loads
Excalidraw at https://draw.homehub.tv/ and the Projects wall loads OpenCode at
https://opencode.homehub.tv/. The other two boards are placeholders.
The surrounding scene uses a photographic outdoor sky, a stone-paved courtyard,
a grassy meadow and a border of trees, with fog for distance. The horizon is a panorama, not walkable
mountain geometry. Asset sources and licensing are recorded in
`assets/polyhaven-landscape/SOURCE.md`, `assets/ambientcg-grass/SOURCE.md`, and
`assets/terraintale-trees/SOURCE.md`.

## Controls

- **WASD**: walk; **Shift**: run; move the mouse to look.
- **Space**: jump. Double-tap Space to toggle flight; hold Space to rise, C to
  descend, and Shift to fly faster. Jumping carries horizontal momentum; you can
  retain takeoff direction and speed in the air, and can jump again after landing on a wall.
- Get within 12 room units of a browser board, aim at it and **click** to
  use it in place. The camera stays still while you move the cursor and draw;
  keyboard input goes to the board. Hold the **right mouse button** to look around,
  and release it to return to the cursor. **Esc** returns to room navigation.
- While navigating, aim at a browser board and press **E** from anywhere in the room for its full-window
  view; **Esc** returns to the room. Press Esc before E if already using the wall,
  since E is sent to the browser in wall mode.
- Outside the board, **Esc** releases the mouse cursor; press Esc again or click
  the room to capture it.

The 3D board displays the same embedded browser as the full-window view. The
viewport is configured for 2560×1440. Each browser board has its own live page.
The embedded browser requests up to 120 updates per second; actual update and
game frame rates depend on rendering load and display synchronization. Adjust
`BROWSER_FRAME_RATE` near the top of `main.gd` if needed. The current gdCEF
version cannot change this limit at runtime, so distant boards are not yet
throttled to 1 FPS. The 3D viewport is disabled while the full-window view is open.

## Comfort settings

The root node exposes `horizontal_fov` (default 90 degrees), `look_smoothing`
(default 25; set to 0 for direct mouse input), and `wall_brightness` (default
0.88). Adjust these in the Godot inspector or at the top of `main.gd`. Smoothing
may feel laggy to some people; the board tint affects only the wall texture,
not the full-window browser. Take a break if the room causes discomfort.

`environment_shadows` on the root node defaults to enabled. Temporarily disable
it in the inspector to compare performance with directional shadows off; restart
the scene after changing it. The camera interpolates between physics ticks while
mouse look remains per-frame, to avoid judder on high-refresh displays.

## World scale and building on the project

One Godot unit is one meter. The camera sits at a 1.7 m eye height; the active
boards are 8 × 4.5 m, with their lower edges about 0.25–0.45 m off the ground.
They're deliberately large surfaces, not desktop monitors. The default jump
reaches roughly 5 m above the starting eye position; change `jump_speed` on the
root node or in `main.gd` to tune it. Flight remains available by double-tapping
Space. The player collides with the courtyard walls and arch blockouts; imported meshes such as
trees do not yet have collision. The ground height remains flat and procedural.

`main.gd` owns movement, browser lifecycle, and interaction. The procedural
landscape and browser-board definitions live in `scripts/landscape.gd`; add a
browser board there with `_make_browser_board(...)`. The currently supported
board geometry is a vertical rectangle facing local +Z. The `CommunityAssets`
node in `main.tscn` is an
editor-visible place to instance models and other scene content without editing
the procedural landscape.

### Add a community asset or plugin

1. Try candidates in ignored `assets/_scratch/`. Follow `assets/README.md` to
   promote assets used by shared scenes or scripts, including placeholders.
   Check license, access and redistribution terms, and record provenance.
2. For models, prefer glTF 2.0 (`.glb` or `.gltf` plus its dependencies). Put
   source files under `assets/<asset-name>/`, open the project in Godot, and let
   the editor import them. Instance the imported scene under `CommunityAssets`
   in `main.tscn`, set its position and scale in meters, and save the scene.
3. For an editor plugin, follow its install instructions (usually an `addons/`
   directory and Project Settings → Plugins). Review scripts and native binaries
   before enabling them; plugins execute code in the editor. Commit the plugin
   files and any required project configuration only when its license permits it.
4. Keep Godot's `.import` sidecar settings and project-owned or modified source
   in Git. Unmodified adopted downloads are pinned in `assets/downloads.nix`;
   generated `.godot/` files stay ignored. Add new files to Git before evaluating
   the Nix flake, since Git-backed flakes only include tracked or staged files.
5. Run the headless and browser checks below, then inspect the scene interactively
   on the target desktop for scale, lighting, performance, and comfort.

**Your existing drawings may not appear automatically.** The embedded browser has
its own persistent profile under Godot's user data directory; it does not share
local browser storage or logins with your usual browser. The supplied homepage
can therefore show a blank canvas. A shareable board or collaboration link may
provide access to the same drawing; the URL is configured in
`scripts/landscape.gd`. Back up important work: browser-local storage is not the same as a
NAS-side board database.

## Run on Beast

Open a terminal in your desktop session:

```sh
cd ~/Projects/godot-3d-starter
nix develop
godot --path .
```

If you already have an older `nix develop` shell open, exit it and enter a new
one first. The first build downloads the pinned gdCEF release (about 1 GB) and
builds a Godot editor with a shared C++ runtime; compiling it can take many
minutes. The project creates an ignored `cef_artifacts` symlink to the Nix store.
It will not overwrite an existing non-managed file or directory at that path.

Use the Godot from this shell, including for the editor (`godot --editor --path .`):
the standard Nixpkgs Godot's static C++ runtime conflicts with gdCEF on shutdown.
The project prefers native Wayland on Linux and falls back to X11 when Wayland
is unavailable. To force X11 for troubleshooting, run
`godot --display-driver x11 --path .`. This project setting affects the game;
the editor's display server is configured separately in Godot's editor settings.
The current gdCEF browser still requires an X11 display (usually XWayland) even
when the Godot window itself runs natively on Wayland. Without one, the embedded
browser fails to initialize and the project falls back to its preview behavior.

If gdCEF fails to initialize, each board opens its URL in the system browser;
the Excalidraw board also uses a periodically refreshed screenshot when `chromium`
is on PATH. For a
preview-only environment without the custom Godot build, run `nix develop
.#preview` instead.

## Verify

For a non-graphical smoke test:

```sh
godot --headless --path . --script res://tests/room_smoke.gd
godot --headless --path . --script res://tests/movement_smoke.gd
```

The browser integration test requires network access to the Excalidraw URL and
uses a temporary, isolated browser profile. It starts a local HTTP fixture and
checks rendering, focus, mouse and keyboard input, persistence across launches,
and clean shutdown under Xvfb:

```sh
nix shell nixpkgs#python3 nixpkgs#xvfb-run --command nix develop --command python tests/run_browser_smoke.py
```

The punctuation regression currently fails with the prebuilt gdCEF extension.
To check the remaining interaction tests separately, prefix the command with
`TEST_SKIP_KNOWN_PUNCTUATION_BUG=1`; this does not fix or test punctuation.
