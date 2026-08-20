#!/usr/bin/env python3
"""
M&S Delivery Express Kabacan - Unified Interactive Multi-App Launcher
Supports simultaneous hot-reloading (r) and hot-restarting (R) for all apps.
"""

import os
import sys
import subprocess
import signal
import threading

PROJECT_ROOT = os.path.abspath(os.path.dirname(__file__))
MAPBOX_TOKEN = "pk.eyJ1IjoiamVhcmFyZCIsImEiOiJjbWE2ZjNlM2YwM2wyMmlvYW9mdDQ5OHJ5In0.57WdNE6fCl-qVJAoMZe40Q"

os.environ["MAPBOX_ACCESS_TOKEN"] = MAPBOX_TOKEN

SERVICES = [
    {
        "name": "BACKEND",
        "cmd": [
            os.path.join(PROJECT_ROOT, ".venv", "bin", "uvicorn"),
            "app.main:app",
            "--host", "0.0.0.0",
            "--port", "8000",
            "--reload",
            "--app-dir", "backend",
        ],
        "cwd": PROJECT_ROOT,
        "is_flutter": False,
    },
    {
        "name": "ADMIN",
        "cmd": [
            "flutter", "run",
            "-d", "web-server",
            "--web-port=3000",
            "--web-hostname=0.0.0.0",
            "--dart-define=API_BASE_URL=http://localhost:8000",
            f"--dart-define=MAPBOX_ACCESS_TOKEN={MAPBOX_TOKEN}",
        ],
        "cwd": os.path.join(PROJECT_ROOT, "ui", "apps", "admin"),
        "is_flutter": True,
    },
    {
        "name": "CUSTOMER",
        "cmd": [
            "flutter", "run",
            "-d", "web-server",
            "--web-port=3001",
            "--web-hostname=0.0.0.0",
            "--dart-define=API_BASE_URL=http://localhost:8000",
            f"--dart-define=MAPBOX_ACCESS_TOKEN={MAPBOX_TOKEN}",
        ],
        "cwd": os.path.join(PROJECT_ROOT, "ui", "apps", "customer"),
        "is_flutter": True,
    },
    {
        "name": "RIDER",
        "cmd": [
            "flutter", "run",
            "-d", "web-server",
            "--web-port=3002",
            "--web-hostname=0.0.0.0",
            "--dart-define=API_BASE_URL=http://localhost:8000",
            f"--dart-define=MAPBOX_ACCESS_TOKEN={MAPBOX_TOKEN}",
        ],
        "cwd": os.path.join(PROJECT_ROOT, "ui", "apps", "rider"),
        "is_flutter": True,
    },
]


def free_ports(ports=[8000, 3000, 3001, 3002]):
    for port in ports:
        try:
            out = subprocess.check_output(["lsof", "-ti", f"tcp:{port}"], stderr=subprocess.DEVNULL)
            for pid in out.decode().strip().splitlines():
                if pid:
                    os.kill(int(pid), signal.SIGKILL)
        except Exception:
            pass


def stream_logs(process, tag):
    for line in iter(process.stdout.readline, b""):
        text = line.decode("utf-8", errors="replace")
        print(f"[{tag}] {text}", end="", flush=True)


def main():
    print("=" * 60)
    print("    M&S Delivery Express Kabacan - Unified Launcher    ")
    print("=" * 60)

    # 1. Clean ports
    print("Freeing target ports (8000, 3000, 3001, 3002)...")
    free_ports()

    # 2. Seed database
    print("Ensuring database migration and seed data...")
    subprocess.run([
        os.path.join(PROJECT_ROOT, ".venv", "bin", "python"),
        os.path.join(PROJECT_ROOT, "backend", "app", "seed.py"),
    ], check=True)

    processes = {}

    def shutdown(sig=None, frame=None):
        print("\n\nShutting down all M&S Delivery services...")
        for p in processes.values():
            try:
                p.terminate()
            except Exception:
                pass
        sys.exit(0)

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    print("\n✔ Launching services with interactive Hot-Reload support:")
    print("  • FastAPI Docs:  http://localhost:8000/docs")
    print("  • Admin Console: http://localhost:3000 (admin@mns.com / AdminPass123!)")
    print("  • Customer App:  http://localhost:3001 (customer@mns.com / CustomerPass123!)")
    print("  • Rider App:     http://localhost:3002 (rider@mns.com / RiderPass123!)")
    print("  • Mapbox Token:  Active")
    print("\nInteractive Commands (broadcast to all 3 Flutter apps):")
    print("  [r] Hot Reload 🔥🔥🔥 | [R] Hot Restart 🔄 | [c] Clear | [q] Quit\n" + "-" * 60)

    for s in SERVICES:
        p = subprocess.Popen(
            s["cmd"],
            cwd=s["cwd"],
            stdin=subprocess.PIPE if s["is_flutter"] else None,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        processes[s["name"]] = p
        t = threading.Thread(target=stream_logs, args=(p, s["name"]), daemon=True)
        t.start()

    try:
        while True:
            char = sys.stdin.read(1)
            if not char:
                break
            if char == 'r':
                print("\n⚡ Broadcasting HOT RELOAD to all 3 Flutter apps... 🔥🔥🔥", flush=True)
                for name, p in processes.items():
                    if name in ["ADMIN", "CUSTOMER", "RIDER"] and p.stdin:
                        try:
                            p.stdin.write(b"r\n")
                            p.stdin.flush()
                        except Exception:
                            pass
            elif char == 'R':
                print("\n🔄 Broadcasting HOT RESTART to all 3 Flutter apps...", flush=True)
                for name, p in processes.items():
                    if name in ["ADMIN", "CUSTOMER", "RIDER"] and p.stdin:
                        try:
                            p.stdin.write(b"R\n")
                            p.stdin.flush()
                        except Exception:
                            pass
            elif char == 'c':
                os.system('clear')
            elif char == 'q':
                shutdown()
    except (KeyboardInterrupt, EOFError):
        shutdown()


if __name__ == "__main__":
    main()
