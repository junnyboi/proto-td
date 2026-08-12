from __future__ import annotations

import argparse
import gzip
import hashlib
import http.server
import json
import os
import platform
import re
import shutil
import socketserver
import subprocess
import threading
import time
from pathlib import Path
from typing import Any

from PIL import Image
from playwright.sync_api import Error as PlaywrightError
from playwright.sync_api import sync_playwright


class HeaderHandler(http.server.SimpleHTTPRequestHandler):
    server_version = "AUI00Baseline/1"

    def end_headers(self) -> None:
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "cross-origin")
        super().end_headers()

    def log_message(self, format_string: str, *args: object) -> None:
        server_log = getattr(self.server, "request_log", None)
        if isinstance(server_log, list):
            server_log.append(format_string % args)


class ReusableServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True



def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()



def command_version(command: list[str]) -> str:
    result = subprocess.run(command, text=True, capture_output=True, check=False, timeout=30)
    return (result.stdout or result.stderr).strip().splitlines()[0]



def directory_size(path: Path) -> int:
    return sum(item.stat().st_size for item in path.rglob("*") if item.is_file())



def gzip_size(path: Path) -> int:
    total = 0
    for item in sorted(candidate for candidate in path.rglob("*") if candidate.is_file()):
        total += len(gzip.compress(item.read_bytes(), compresslevel=9, mtime=0))
    return total



def title_signal(path: Path) -> dict[str, Any]:
    image = Image.open(path).convert("RGB")
    width, height = image.size
    crop = image.crop((width // 5, height // 5, width * 4 // 5, height * 4 // 5))
    pixels = list(crop.get_flattened_data())
    bright = sum(1 for red, green, blue in pixels if red > 185 and green > 185 and blue > 185)
    dark = sum(1 for red, green, blue in pixels if red < 70 and green < 70 and blue < 70)
    corner_pixels: list[tuple[int, int, int]] = []
    for box in [
        (0, 0, 64, 64),
        (width - 64, 0, width, 64),
        (0, height - 64, 64, height),
        (width - 64, height - 64, width, height),
    ]:
        corner_pixels.extend(image.crop(box).get_flattened_data())
    corner_luma = sum((red + green + blue) / 3.0 for red, green, blue in corner_pixels) / len(
        corner_pixels
    )
    title_background_band = 50.0 <= corner_luma <= 130.0
    visible = bright >= 100 and dark >= 100 and title_background_band
    return {
        "bright_center_pixels": bright,
        "corner_luma": round(corner_luma, 3),
        "dark_center_pixels": dark,
        "dimensions": [width, height],
        "title_background_band": title_background_band,
        "visible": visible,
    }



def process_rss_kib(process_id: int) -> int | None:
    status = Path(f"/proc/{process_id}/status")
    if not status.is_file():
        return None
    match = re.search(r"^VmRSS:\s*(\d+)\s*kB$", status.read_text(encoding="utf-8"), re.MULTILINE)
    return int(match.group(1)) if match else None



def console_errors(stderr: str) -> list[str]:
    errors: list[str] = []
    for line in stderr.splitlines():
        lowered = line.lower()
        is_console = "console" in lowered or "uncaught" in lowered
        is_error = any(token in lowered for token in ["error", "exception", "typeerror", "referenceerror"])
        if is_console and is_error:
            errors.append(line.strip())
    return errors



def run_browser(
    chromium: str, url: str, screenshot: Path, wait_budget_ms: int
) -> dict[str, Any]:
    launch_args = [
        "--no-sandbox",
        "--enable-unsafe-swiftshader",
        "--use-angle=swiftshader",
        "--disable-dev-shm-usage",
        "--disable-background-networking",
        "--disable-component-update",
        "--disable-default-apps",
        "--disable-extensions",
        "--disable-sync",
        "--metrics-recording-only",
        "--no-first-run",
    ]
    started = time.monotonic()
    browser_console: list[str] = []
    error_text = ""
    exit_code = 0
    try:
        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(
                executable_path=chromium, headless=True, args=launch_args
            )
            page = browser.new_page(viewport={"width": 1280, "height": 720})
            page.on(
                "console",
                lambda message: browser_console.append(
                    f"{message.type}: {message.text}"
                )
                if message.type == "error"
                else None,
            )
            page.on("pageerror", lambda error: browser_console.append(f"pageerror: {error}"))
            response = page.goto(url, wait_until="commit", timeout=30000)
            if response is None or not response.ok:
                browser_console.append(
                    f"navigation error: {response.status if response is not None else 'no response'}"
                )
            page.wait_for_timeout(wait_budget_ms)
            page.screenshot(path=str(screenshot))
            browser.close()
    except (PlaywrightError, TimeoutError) as error:
        exit_code = 1
        error_text = str(error)
    wall_ms = round((time.monotonic() - started) * 1000)
    signal = title_signal(screenshot) if screenshot.is_file() else {
        "bright_center_pixels": 0,
        "dark_center_pixels": 0,
        "dimensions": None,
        "visible": False,
    }
    return {
        "command": ["playwright.chromium.launch", chromium, *launch_args],
        "console_errors": browser_console,
        "exit_code": exit_code,
        "maximum_resident_kib": None,
        "screenshot": screenshot.name if screenshot.is_file() else None,
        "signal": signal,
        "stderr_log": f"chromium-{wait_budget_ms}.stderr.log",
        "wait_budget_ms": wait_budget_ms,
        "wall_ms": wall_ms,
        "stderr": error_text + ("\n" if error_text else ""),
    }



def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--godot", default=str(Path.home() / "bin/godot"))
    parser.add_argument("--chromium", default=shutil.which("chromium") or "chromium")
    args = parser.parse_args()

    repo = args.repo.resolve()
    output = args.out.resolve()
    if output.exists() and any(output.iterdir()):
        raise SystemExit(f"output must be absent or empty: {output}")
    output.mkdir(parents=True, exist_ok=True)
    export_dir = output / "web"
    export_dir.mkdir()
    export_log = output / "godot-export.log"
    export_command = [
        args.godot,
        "--headless",
        "--path",
        str(repo),
        "--export-release",
        "Web",
        str(export_dir / "index.html"),
    ]
    export_started = time.monotonic()
    export_result = subprocess.run(export_command, text=True, capture_output=True, check=False, timeout=180)
    export_wall_ms = round((time.monotonic() - export_started) * 1000)
    export_log.write_text(export_result.stdout + export_result.stderr, encoding="utf-8")
    if export_result.returncode != 0 or not (export_dir / "index.html").is_file():
        raise SystemExit("Web export failed; see godot-export.log")

    request_log: list[str] = []
    previous_cwd = Path.cwd()
    server: ReusableServer | None = None
    thread: threading.Thread | None = None
    attempts: list[dict[str, Any]] = []
    try:
        os.chdir(export_dir)
        server = ReusableServer(("127.0.0.1", 0), HeaderHandler)
        setattr(server, "request_log", request_log)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        url = f"http://127.0.0.1:{server.server_address[1]}/index.html"
        for budget in [1000, 3000, 6000, 12000]:
            screenshot = output / f"web-{budget}.png"
            attempt = run_browser(args.chromium, url, screenshot, budget)
            (output / attempt["stderr_log"]).write_text(attempt.pop("stderr"), encoding="utf-8")
            attempts.append(attempt)
            if attempt["exit_code"] == 0 and attempt["signal"]["visible"]:
                break
    finally:
        if server is not None:
            server.shutdown()
            server.server_close()
        if thread is not None:
            thread.join(timeout=5)
        os.chdir(previous_cwd)

    visible_attempts = [attempt for attempt in attempts if attempt["signal"]["visible"]]
    all_console_errors = [error for attempt in attempts for error in attempt["console_errors"]]
    maximum_memory = max(
        (attempt["maximum_resident_kib"] for attempt in attempts if attempt["maximum_resident_kib"] is not None),
        default=None,
    )
    tool_path = Path(__file__).resolve()
    report = {
        "schema_version": 1,
        "result": "pass" if visible_attempts and not all_console_errors and all(
            attempt["exit_code"] == 0 for attempt in attempts
        ) else "fail",
        "repo": str(repo),
        "export": {
            "command": export_command,
            "compressed_gzip_bytes": gzip_size(export_dir),
            "exit_code": export_result.returncode,
            "file_count": sum(1 for item in export_dir.rglob("*") if item.is_file()),
            "uncompressed_bytes": directory_size(export_dir),
            "wall_ms": export_wall_ms,
        },
        "browser": {
            "attempts": attempts,
            "console_errors": all_console_errors,
            "first_title_visible_wait_ms": visible_attempts[0]["wait_budget_ms"] if visible_attempts else None,
            "maximum_resident_kib": maximum_memory,
            "memory_status": "measured" if maximum_memory is not None else "unsupported",
            "request_count": len(request_log),
        },
        "environment": {
            "chromium": command_version([args.chromium, "--version"]),
            "godot": command_version([args.godot, "--version"]),
            "os": platform.platform(),
            "tool_sha256": sha256(tool_path),
        },
    }
    (output / "server.log").write_text("\n".join(request_log) + "\n", encoding="utf-8")
    (output / "web-baseline.json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if report["result"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
