#!/usr/bin/env bash
# Run from the project root inside the preview development shell.
set -euo pipefail

godot --headless --editor --path . --import

# Check project scripts, including untracked work, without entering asset caches.
while IFS= read -r -d '' script; do
  godot --headless --path . --check-only --script "res://${script#./}"
done < <(find ./main.gd ./scripts ./tests -type f -name '*.gd' -print0)

godot --headless --path . --script res://tests/room_smoke.gd
godot --headless --path . --script res://tests/movement_smoke.gd
godot --headless --path . --script res://tests/input_state_smoke.gd
godot --headless --path . --quit-after 300
