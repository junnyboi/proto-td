#!/bin/bash
# PostToolUse hook: validate any written .gd file; exit 2 feeds stderr back to Claude.
export PATH="$HOME/.local/bin:$PATH"
f=$(jq -r '.tool_input.file_path // empty')
[[ "$f" == *.gd ]] || exit 0
out=$(godot --headless --check-only -s "$f" 2>&1) || { echo "$out" >&2; exit 2; }
command -v gdlint >/dev/null && { out=$(gdlint "$f" 2>&1) || { echo "$out" >&2; exit 2; }; }
exit 0
