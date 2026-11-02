# Project asset workflow

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
