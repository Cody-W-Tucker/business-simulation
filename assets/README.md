# Community assets

Use `_scratch/` for local trials. It is ignored, disposable, and not a backup;
do not commit scenes or code that depend on it. Keep source and license notes
locally while experimenting. Download archives also belong in scratch.

Promote anything referenced by the shared project, even a temporary placeholder:

1. Check license, automated access and redistribution terms. Record the source
   URL, author, version or date, license, attribution, and modifications in a
   committed `SOURCE.md`; retain any required license text.
2. For unmodified, directly obtainable files, add a URL and verified content hash
   to `downloads.nix`, add an exact binary path to `.gitignore`, and retain the
   Godot `.import` sidecar in Git. `nix develop` fetches and links the file at
   that path; both the default and preview shells do this. It never overwrites
   existing files. A conflicting file must be moved aside by its owner.
3. For modified assets, commit the modified source or a reproducible transformation
   (only if the license permits). Store project-owned work in Git, considering
   Git LFS separately for large or frequently edited binaries.
4. Commit the references and metadata together. Test a fresh checkout: enter
   `nix develop .#preview`, run `godot --headless --editor --path . --import`,
   then the headless smoke tests in the project README.

Download definitions pin content, not availability. An upstream outage or
changed file can block fresh setup; use a permitted durable mirror or backup for
important assets. Git-backed flakes include only tracked or staged files: add
new manifest and project files before testing with `nix develop`.

Godot editor plugins normally belong in `addons/`, following their own install
instructions, rather than here.
