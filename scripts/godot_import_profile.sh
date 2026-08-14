#!/usr/bin/env bash

# Godot 4.7.1 can crash its importer worker pool while a gate imports a complete
# copied worktree. Scratch gates use this isolated editor profile so the exact
# same resources are imported serially without mutating the user's settings.
protos_write_single_threaded_import_profile() {
  local config_root="${1:?config root required}"
  mkdir -p "$config_root/godot"
  cat > "$config_root/godot/editor_settings-4.7.tres" <<'SETTINGS'
[gd_resource type="EditorSettings" format=3]

[resource]
resource_local_to_scene = false
resource_name = ""
editor/import/use_multiple_threads = false
SETTINGS
}
