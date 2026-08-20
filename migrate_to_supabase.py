#!/usr/bin/env python3
"""
M&S Delivery Express Kabacan - Supabase Migration CLI Runner
"""

import sys
import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(PROJECT_ROOT / "backend"))

# Use virtualenv python if available and not currently in it
IS_WINDOWS = os.name == "nt"
VENV_PYTHON = PROJECT_ROOT / ".venv" / ("Scripts/python.exe" if IS_WINDOWS else "bin/python")

if VENV_PYTHON.exists() and sys.executable != str(VENV_PYTHON):
    import subprocess
    cmd = [str(VENV_PYTHON), str(PROJECT_ROOT / "backend/app/migrate_to_supabase.py")] + sys.argv[1:]
    sys.exit(subprocess.call(cmd))

from app.migrate_to_supabase import main

if __name__ == "__main__":
    main()
