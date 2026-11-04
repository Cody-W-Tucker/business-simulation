# Project asset workflow

The flake lock pins Godot 4.7.2 stable; the project uses GDScript. Use the
project's Nix shells rather than an unrelated system Godot. After changes, run
`nix develop .#preview --command bash scripts/verify.sh` from the project root.
The preview gate does not test gdCEF; use the browser integration test in the
README for browser changes.

Follow `assets/README.md` when adding or changing assets. Trial files and download
archives go in ignored `assets/_scratch/`; never commit references to scratch.
Shared scenes, scripts and tests may only depend on adopted assets: register
unmodified downloads with URL and hash in `assets/downloads.nix`, ignore their
exact binary paths, and commit their `.import` sidecars and provenance/license
records. Preserve modified or original work as source, subject to its license.

Run `nix develop .#preview` from the project root before opening Godot or running
tests; it makes pinned downloads available without overwriting local files. After
asset changes, test a fresh checkout and Godot import and smoke tests as described
in `assets/README.md`. Don't delete or overwrite scratch files or existing assets
without permission. Never assume a third-party model's external textures are
unused solely because scripts do not reference them.

## Opening the editor

When an editor session is needed, the user permits the agent to open it. From
the project root run `nix develop .#preview --command godot --editor --path .`
in the background. If there is no desktop display, use a private virtual X
display instead: `nix shell nixpkgs#xvfb-run --command xvfb-run -a nix develop
.#preview --command godot --audio-driver Dummy --editor --path .`. Check the
Godot MCP session list before relying on the connection. Godot's `--headless`
editor disables the MCP plugin, so it is suitable for tests but not for an MCP
editor session. Do not stop or replace an existing user-owned editor session.
