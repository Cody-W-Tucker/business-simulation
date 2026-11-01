# The Whiteboard Room

A Godot 4 room with whiteboards on three walls. The middle board loads your
self-hosted Excalidraw instance at https://draw.homehub.tv/ inside the game.

## Controls

- **WASD**: walk; **Shift**: run; move the mouse to look.
- **Space**: jump. Double-tap Space to toggle flight; hold Space to rise, C to
  descend, and Shift to fly faster.
- Aim at the Excalidraw board and press **E** or click to open its interactive,
  full-window view. Use the mouse and keyboard to draw; **Esc** returns to the room.
- Outside the board, **Esc** releases the mouse cursor; press Esc again or click
  the room to capture it.

The 3D board displays the same embedded browser as the full-window view. The
viewport is configured for 2560×1440. The other two boards are placeholders.

**Your existing drawings may not appear automatically.** The embedded browser has
its own persistent profile under Godot's user data directory; it does not share
local browser storage or logins with your usual browser. The supplied homepage
can therefore show a blank canvas. A shareable board or collaboration link may
provide access to the same drawing; the URL is configured near the top of
`main.gd`. Back up important work: browser-local storage is not the same as a
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
Godot chooses the display driver automatically; native Wayland can be requested
with `godot --display-driver wayland --path .`.

If gdCEF fails to initialize, the board opens in the system browser instead and
a periodically refreshed screenshot is used when `chromium` is on PATH. For a
preview-only environment without the custom Godot build, run `nix develop
.#preview` instead.

## Verify

For a non-graphical smoke test:

```sh
godot --headless --path . --quit-after 10
```

The browser integration test requires network access to the Excalidraw URL and
uses a temporary, isolated browser profile. It starts a local HTTP fixture and
checks rendering, focus, mouse and keyboard input, persistence across launches,
and clean shutdown under Xvfb:

```sh
nix shell nixpkgs#python3 nixpkgs#xvfb-run --command nix develop --command python tests/run_browser_smoke.py
```
