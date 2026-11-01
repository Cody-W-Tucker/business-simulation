#!/usr/bin/env python3
"""Exercise the embedded browser with an isolated profile and local fixture."""

import functools
import http.server
import os
from pathlib import Path
import subprocess
import tempfile
import threading


def main():
    fixture_dir = Path(__file__).resolve().parent
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=fixture_dir)
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        with tempfile.TemporaryDirectory(prefix="whiteboard-browser-test-") as data_dir:
            env = os.environ.copy()
            env["XDG_DATA_HOME"] = data_dir
            env["TEST_FIXTURE_URL"] = (
                f"http://127.0.0.1:{server.server_port}/browser_fixture.html"
            )
            command = [
                "xvfb-run", "-a", "godot", "--path", str(fixture_dir.parent),
                "--audio-driver", "Dummy", "--rendering-method", "gl_compatibility",
                "--script", "res://tests/browser_smoke.gd",
            ]
            subprocess.run(command, env=env, check=True, timeout=120)
            env["TEST_EXPECT_SAVED"] = "1"
            subprocess.run(command, env=env, check=True, timeout=120)
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


if __name__ == "__main__":
    main()
