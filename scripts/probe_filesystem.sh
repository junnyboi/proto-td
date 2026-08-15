#!/usr/bin/env bash
set -euo pipefail

MODE="native"
GODOT="${GODOT:-$HOME/bin/godot}"
OUT_DIR=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/godot_import_profile.sh"
for arg in "$@"; do
  case "$arg" in
    --web) MODE="web" ;;
    --out=*) OUT_DIR="${arg#*=}" ;;
    *) GODOT="$arg" ;;
  esac
done

root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
mkdir -p "$root/data" "$root/config" "$root/cache"
export XDG_CACHE_HOME="$root/cache"

version="$($GODOT --headless --version)"
[[ "$version" == 4.7.1.stable.official.* ]] || {
  echo "[filesystem-probe] expected Godot 4.7.1, got $version" >&2
  exit 2
}
EXPECTED_CHECKS=162
EXPECTED_CASES='["empty","main","main_bak","main_tmp","main_bak_tmp","main_equal_divergent_sidecars","bak","tmp","bak_tmp","corrupt_main_bak","corrupt_main_tmp","all_invalid","equal_version_divergence","tmp_not_newer_than_invalid_header","tmp_same_generation_higher_revision","tmp_same_generation_lower_than_invalid_bak","invalid_main_invalid_bak_newer_tmp","v3_store_round_trip"]'

if [[ "$MODE" == "web" ]]; then
  [[ -n "$OUT_DIR" ]] || OUT_DIR="$root/web-result"
  rm -rf "$OUT_DIR"
  mkdir -p "$OUT_DIR" "$root/project" "$root/export"
  tar --exclude=.git --exclude=.godot --exclude=artifacts -cf - . \
    | (cd "$root/project" && tar -xf -)
  cp tools/probe_filesystem.gd "$root/project/tools/probe_filesystem_web.gd"
  sed -i \
    -e 's/^extends SceneTree$/extends Node/' \
    -e 's/^func _initialize() -> void:/func _ready() -> void:/' \
    -e 's/quit(0 if _failures.is_empty() else 1)/get_tree().quit(0 if _failures.is_empty() else 1)/' \
    -e 's/_check(OS.get_name() == "Linux", "probe acceptance platform is Linux")/_check(OS.has_feature("web"), "probe acceptance platform is Web")/' \
    -e 's/_check(DisplayServer.get_name() == "headless", "probe runs headless")/_check(DisplayServer.get_name() == "web", "probe runs Web display")/' \
    -e 's/_check(not OS.has_feature("web"), "native probe is not Web")/_check(OS.has_feature("web"), "Web feature flag is present")/' \
    "$root/project/tools/probe_filesystem_web.gd"
  cat > "$root/project/scenes/probe_filesystem_web.tscn" <<'SCENE'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tools/probe_filesystem_web.gd" id="1"]

[node name="FilesystemProbeWeb" type="Node"]
script = ExtResource("1")
SCENE
  sed -i 's#^run/main_scene=.*#run/main_scene="res://scenes/probe_filesystem_web.tscn"#' \
    "$root/project/project.godot"
	  (
	    cd "$root/project"
	    import_config="$root/editor-config"
	    protos_write_single_threaded_import_profile "$import_config"
		    XDG_CONFIG_HOME="$import_config" XDG_CACHE_HOME="$root/cache" \
		      timeout 120s "$GODOT" --headless --recovery-mode --path . --import
			    XDG_CONFIG_HOME="$import_config" XDG_CACHE_HOME="$root/cache" \
			      timeout 180s "$GODOT" --headless --path . --export-release Web "$root/export/index.html"
		  ) >"$OUT_DIR/export.log" 2>&1
	  python3 - "$root/export/index.html" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
needle = "\t\t}).then(() => {\n\t\t\tsetStatusMode('hidden');"
replacement = (
    "\t\t}).then(() => {\n"
    "\t\t\tdocument.documentElement.setAttribute('data-p16-engine-exit', 'ok');\n"
    "\t\t\tconsole.log('P16_ENGINE_EXIT_OK');\n"
    "\t\t\tsetStatusMode('hidden');"
    "\n\t\t\twindow.close();"
)
if source.count(needle) != 1:
    raise SystemExit("Godot Web completion hook not found exactly once")
path.write_text(source.replace(needle, replacement))
PY
	  cat > "$root/probe_server.mjs" <<'SERVER'
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
const root = path.resolve(process.argv[2]);
const types = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
};
http.createServer((request, response) => {
  const requested = request.url === "/" ? "/index.html" : new URL(request.url, "http://localhost").pathname;
  const file = path.resolve(root, `.${requested}`);
  if (!file.startsWith(`${root}${path.sep}`) || !fs.existsSync(file)) {
    response.writeHead(404);
    response.end("not found");
    return;
  }
  response.writeHead(200, {
    "Content-Type": types[path.extname(file)] ?? "application/octet-stream",
    "Cross-Origin-Opener-Policy": "same-origin",
    "Cross-Origin-Embedder-Policy": "require-corp",
    "Cache-Control": "no-store",
  });
  fs.createReadStream(file).pipe(response);
}).listen(18081, "127.0.0.1");
SERVER
  node "$root/probe_server.mjs" "$root/export" >"$OUT_DIR/server.log" 2>&1 &
  server_pid=$!
  browser_pid=""
  cleanup_server() {
    [[ -z "$browser_pid" ]] || kill "$browser_pid" 2>/dev/null || true
    kill "$server_pid" 2>/dev/null || true
  }
  trap 'cleanup_server; rm -rf "$root"' EXIT
  for _attempt in $(seq 1 40); do
    curl -fsS http://127.0.0.1:18081/index.html >/dev/null 2>&1 && break
    sleep 0.25
  done
	  chromium \
	    --headless --no-sandbox --disable-dev-shm-usage --enable-unsafe-swiftshader \
	    --enable-logging=stderr --v=0 http://127.0.0.1:18081/index.html \
	    >"$OUT_DIR/browser.log" 2>&1 &
	  browser_pid=$!
	  completed=0
	  for _attempt in $(seq 1 120); do
	    if grep -q 'P16_ENGINE_EXIT_OK' "$OUT_DIR/browser.log"; then
	      completed=1
	      break
	    fi
	    kill -0 "$browser_pid" 2>/dev/null || break
	    sleep 0.25
	  done
	  [[ "$completed" -eq 1 ]] || {
	    echo '[filesystem-probe] engine completion sentinel missing' >&2
	    exit 1
	  }
	  for _attempt in $(seq 1 40); do
	    kill -0 "$browser_pid" 2>/dev/null || break
	    sleep 0.25
	  done
	  kill -0 "$browser_pid" 2>/dev/null && {
	    echo '[filesystem-probe] Chromium did not exit normally after engine completion' >&2
	    exit 1
	  }
	  set +e
	  wait "$browser_pid"
	  browser_status=$?
	  set -e
	  browser_pid=""
	  [[ "$browser_status" -eq 0 ]] || {
	    echo "[filesystem-probe] Chromium exited nonzero status=$browser_status" >&2
	    exit 1
	  }
  line="$(grep 'P16_FILESYSTEM_RESULT=' "$OUT_DIR/browser.log" | tail -1)"
  [[ -n "$line" ]] || { echo '[filesystem-probe] missing Web result sentinel' >&2; exit 1; }
  result="$(printf '%s\n' "$line" | sed -E 's/^.*P16_FILESYSTEM_RESULT=//' | sed -E 's/", source:.*$//' | sed 's/\\"/"/g')"
  jq -e --argjson cases "$EXPECTED_CASES" --argjson checks "$EXPECTED_CHECKS" \
    '.id == "filesystem" and .platform == "Web" and .web == true and .headless == false
    and .verdict == "pass" and .mandatory_failures == [] and .checks == $checks
    and .case_count == ($cases | length) and .case_ids == $cases' \
    <<< "$result" >/dev/null
  jq -cS . <<< "$result" > "$OUT_DIR/result.json"
  cleanup_server
  trap 'rm -rf "$root"' EXIT
  echo "[filesystem-probe] WEB PASS checks=$(jq -r '.checks' <<< "$result")"
  exit 0
fi

output="$root/result.log"
XDG_DATA_HOME="$root/data" \
XDG_CONFIG_HOME="$root/config" \
XDG_CACHE_HOME="$root/cache" \
timeout 30s "$GODOT" --headless --path . \
  -s tools/probe_filesystem.gd -- --case=all | tee "$output"

line="$(grep '^P16_FILESYSTEM_RESULT=' "$output" | tail -1)"
[[ -n "$line" ]] || { echo '[filesystem-probe] missing result sentinel' >&2; exit 1; }
result="${line#P16_FILESYSTEM_RESULT=}"
jq -e --argjson cases "$EXPECTED_CASES" --argjson checks "$EXPECTED_CHECKS" \
  '.id == "filesystem" and .platform == "Linux" and .web == false and .headless == true
  and .verdict == "pass" and .mandatory_failures == [] and .checks == $checks
  and .case_count == ($cases | length) and .case_ids == $cases' \
  <<< "$result" >/dev/null

leftovers="$(find "$root/data" -type f -o -type d | sort)"
if grep -q 'p16_filesystem_probe' <<< "$leftovers"; then
  echo '[filesystem-probe] probe directory survived cleanup' >&2
  exit 1
fi

if [[ -n "$OUT_DIR" ]]; then
  mkdir -p "$(dirname "$OUT_DIR")"
  jq -cS . <<< "$result" > "$OUT_DIR"
fi

echo "[filesystem-probe] NATIVE PASS checks=$(jq -r '.checks' <<< "$result")"
