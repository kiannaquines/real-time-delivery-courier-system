#!/usr/bin/env python3
"""
M&S Delivery Express Kabacan - All-in-One Multi-Process Launcher
Starts FastAPI REST Backend and all 3 Flutter Applications concurrently.
"""

import os
import sys
import subprocess
import signal
import time

PROJECT_ROOT = os.path.abspath(os.path.dirname(__file__))

SERVICES = [
    {
        "name": "FastAPI REST Backend",
        "url": "http://localhost:8000/docs",
        "cmd": [
            os.path.join(PROJECT_ROOT, ".venv", "bin", "uvicorn"),
            "app.main:app",
            "--host", "0.0.0.0",
            "--port", "8000",
            "--reload",
            "--app-dir", "backend",
        ],
        "cwd": PROJECT_ROOT,
    },
    {
        "name": "Admin Web Console",
        "url": "http://localhost:3000 (admin@mns.com / AdminPass123!)",
        "cmd": [
            "flutter", "run",
            "-d", "web-server",
            "--web-port=3000",
            "--web-hostname=0.0.0.0",
            "--dart-define=API_BASE_URL=http://localhost:8000",
        ],
        "cwd": os.path.join(PROJECT_ROOT, "ui", "apps", "admin"),
    },
    {
        "name": "Customer Mobile App",
        "url": "http://localhost:3001 (customer@mns.com / CustomerPass123!)",
        "cmd": [
            "flutter", "run",
            "-d", "web-server",
            "--web-port=3001",
            "--web-hostname=0.0.0.0",
            "--dart-define=API_BASE_URL=http://localhost:8000",
        ],
        "cwd": os.path.join(PROJECT_ROOT, "ui", "apps", "customer"),
    },
    {
        "name": "Rider Courier App",
        "url": "http://localhost:3002 (rider@mns.com / RiderPass123!)",
        "cmd": [
            "flutter", "run",
            "-d", "web-server",
            "--web-port=3002",
            "--web-hostname=0.0.0.0",
            "--dart-define=API_BASE_URL=http://localhost:8000",
        ],
        "cwd": os.path.join(PROJECT_ROOT, "ui", "apps", "rider"),
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


def main():
    print("=" * 60)
    print("    M&S Delivery Express Kabacan - All-in-One Launcher    ")
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

    processes = []

    def shutdown(sig, frame):
        print("\nStopping all services...")
        for p in processes:
            try:
                p.terminate()
            except Exception:
                pass
        sys.exit(0)

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    print("\nLaunching services:")
    for s in SERVICES:
        print(f"  ▶ Launching {s['name']} -> {s['url']}")
        p = subprocess.Popen(
            s["cmd"],
            cwd=s["cwd"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        processes.append(p)

    print("\n✔ All 4 applications are running!")
    print("Press Ctrl+C to terminate all services.\n")

    while True:
        time.sleep(1)


if __name__ == "__main__":
    main()
