# Project asset workflow

This checkout is shared with Beast over NFS. Edit source files from either host,
but run all Godot, project Nix shells, direnv reloads, imports and tests on Beast.
From another host use `ssh beast` and work in `~/Projects/godot-3d-starter`.
Do not enter a project Nix shell or run Godot against this checkout on the NAS:
`.godot`, `.direnv` and the `cef_artifacts` link are shared but Nix stores are not.
Do not run two editors against the checkout at once; do not stop a user's game
or editor. Use an isolated copy on Beast for checks if the checkout is in use.

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

When an editor session is needed, the user permits the agent to open it on Beast.
From the project root run `nix develop --command godot --editor --path .`
in the background. If there is no desktop display, use a private virtual X
display on Beast instead: `nix shell nixpkgs#xvfb-run --command xvfb-run -a nix
develop --command godot --audio-driver Dummy --editor --path .`. Check the
Godot MCP session list before relying on the connection. Godot's `--headless`
editor disables the MCP plugin, so it is suitable for tests but not for an MCP
editor session. Do not stop or replace an existing user-owned editor session.
