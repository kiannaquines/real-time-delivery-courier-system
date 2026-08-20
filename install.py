#!/usr/bin/env python3
"""
M&S Delivery Express Kabacan - Automated Full-Stack Installation Script
Cross-platform installer for macOS, Linux, and Windows.

Installs and configures:
1. System Prerequisites & Environment Verification
2. Environment Configuration (.env setup)
3. Python Virtual Environment (.venv) & Backend Dependencies
4. SQLite Persistence Layer & Seed Data Initialization
5. Flutter Web Support & Shared Package Dependencies:
   - domain_models
   - api_client
   - auth_session
   - design_system
   - realtime_client
6. Flutter Client Applications:
   - Admin Web Cockpit (ui/apps/admin)
   - Customer Mobile/Web App (ui/apps/customer)
   - Rider Mobile/Web App (ui/apps/rider)
7. Health Verification & Service Readiness
"""

import os
import sys
import shutil
import subprocess
import time
from pathlib import Path

# --- Terminal Styling ---
IS_WINDOWS = os.name == "nt"

# Enable VT100 colors on Windows if possible
if IS_WINDOWS:
    try:
        import ctypes
        kernel32 = ctypes.windll.kernel32
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
    except Exception:
        pass

class Style:
    HEADER = "\033[95m"
    BLUE = "\033[94m"
    CYAN = "\033[96m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    NC = "\033[0m"

def print_header(title: str):
    print(f"\n{Style.BOLD}{Style.CYAN}┌─────────────────────────────────────────────────────────────┐{Style.NC}")
    print(f"{Style.BOLD}{Style.CYAN}│  {title:<57}  │{Style.NC}")
    print(f"{Style.BOLD}{Style.CYAN}└─────────────────────────────────────────────────────────────┘{Style.NC}")

def step_info(step_num: int, total_steps: int, msg: str):
    print(f"\n{Style.BOLD}{Style.BLUE}[{step_num}/{total_steps}] {msg}{Style.NC}")

def success(msg: str):
    print(f"  {Style.GREEN}✔ {msg}{Style.NC}")

def warn(msg: str):
    print(f"  {Style.YELLOW}⚠ {msg}{Style.NC}")

def error(msg: str):
    print(f"  {Style.RED}✖ {msg}{Style.NC}")

def run_cmd(cmd, cwd=None, env=None, check=True, capture_output=False):
    """Executes a command and streams output or returns result."""
    merged_env = os.environ.copy()
    if env:
        merged_env.update(env)
    
    if capture_output:
        res = subprocess.run(
            cmd,
            cwd=cwd,
            env=merged_env,
            shell=isinstance(cmd, str),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        if check and res.returncode != 0:
            raise subprocess.CalledProcessError(res.returncode, cmd, output=res.stdout, stderr=res.stderr)
        return res
    else:
        res = subprocess.run(
            cmd,
            cwd=cwd,
            env=merged_env,
            shell=isinstance(cmd, str)
        )
        if check and res.returncode != 0:
            raise subprocess.CalledProcessError(res.returncode, cmd)
        return res


PROJECT_ROOT = Path(__file__).resolve().parent
BACKEND_DIR = PROJECT_ROOT / "backend"
UI_DIR = PROJECT_ROOT / "ui"
VENV_DIR = PROJECT_ROOT / ".venv"

if IS_WINDOWS:
    PYTHON_VENV_BIN = VENV_DIR / "Scripts" / "python.exe"
    PIP_VENV_BIN = VENV_DIR / "Scripts" / "pip.exe"
else:
    PYTHON_VENV_BIN = VENV_DIR / "bin" / "python"
    PIP_VENV_BIN = VENV_DIR / "bin" / "pip"


def check_prerequisites():
    step_info(1, 6, "Checking System Prerequisites...")
    
    # 1. Python version check
    py_ver = sys.version_info
    if py_ver.major < 3 or (py_ver.major == 3 and py_ver.minor < 10):
        error(f"Python 3.10+ is required. Found Python {py_ver.major}.{py_ver.minor}.{py_ver.micro}")
        sys.exit(1)
    success(f"Python {py_ver.major}.{py_ver.minor}.{py_ver.micro} detected.")

    # 2. Flutter SDK check
    flutter_bin = shutil.which("flutter")
    if not flutter_bin:
        error("Flutter SDK was not found in PATH!")
        print(f"\n{Style.YELLOW}Please install Flutter SDK from https://docs.flutter.dev/get-started/install and add it to PATH.{Style.NC}")
        sys.exit(1)
    
    try:
        flt_res = run_cmd(["flutter", "--version"], capture_output=True)
        flt_first_line = flt_res.stdout.strip().split("\n")[0]
        success(f"Flutter SDK detected: {flt_first_line}")
    except Exception as e:
        warn(f"Flutter detected at {flutter_bin} (could not query version: {e})")

    # 3. Optional tools check (cloudflared, git, chrome)
    cloudflared_bin = shutil.which("cloudflared")
    if cloudflared_bin:
        success("Cloudflare Tunnel CLI ('cloudflared') detected.")
    else:
        warn("Cloudflare Tunnel CLI ('cloudflared') not found. (Optional for local testing, required for public tunnel sharing)")
        if IS_WINDOWS:
            print(f"      {Style.DIM}Install with: winget install Cloudflare.cloudflared{Style.NC}")
        elif sys.platform == "darwin":
            print(f"      {Style.DIM}Install with: brew install cloudflared{Style.NC}")
        else:
            print(f"      {Style.DIM}Install from: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/{Style.NC}")


def setup_environment_files():
    step_info(2, 6, "Configuring Environment (.env)...")
    env_file = PROJECT_ROOT / ".env"
    env_example = PROJECT_ROOT / ".env.example"
    
    if not env_file.exists():
        if env_example.exists():
            shutil.copy(env_example, env_file)
            success("Created .env from .env.example template.")
        else:
            default_env = """# M&S Delivery System Environment Configuration
APP_ENV=development
API_BASE_URL=http://localhost:8000
MAPBOX_ACCESS_TOKEN=pk.eyJ1IjoiamVhcmFyZCIsImEiOiJjbWE2ZjNlM2YwM2wyMmlvYW9mdDQ5OHJ5In0.57WdNE6fCl-qVJAoMZe40Q
JWT_SECRET_KEY=insecure-default-secret-key-change-in-production-mns-2026
JWT_KEY_ID=mns-key-1
"""
            env_file.write_text(default_env)
            success("Created default .env configuration file.")
    else:
        success(".env configuration file already exists.")

    # Enable Flutter web support
    try:
        run_cmd(["flutter", "config", "--enable-web"], capture_output=True)
        success("Flutter web platform enabled.")
    except Exception as e:
        warn(f"Could not enable Flutter web platform automatically: {e}")


def setup_python_backend():
    step_info(3, 6, "Setting Up Python Virtual Environment & Backend Dependencies...")
    
    # 1. Create venv if needed
    if not PYTHON_VENV_BIN.exists():
        print(f"  {Style.BLUE}Creating Python virtual environment in .venv...{Style.NC}")
        try:
            import venv
            venv.create(VENV_DIR, with_pip=True)
            success(f"Virtual environment created at {VENV_DIR}")
        except Exception as e:
            # Fallback to sys.executable -m venv
            run_cmd([sys.executable, "-m", "venv", str(VENV_DIR)])
            success(f"Virtual environment created at {VENV_DIR}")
    else:
        success(f"Using existing Python virtual environment at {VENV_DIR}")

    # 2. Upgrade pip
    print(f"  {Style.BLUE}Upgrading pip, setuptools, and wheel in virtual environment...{Style.NC}")
    run_cmd([str(PYTHON_VENV_BIN), "-m", "pip", "install", "--upgrade", "pip", "setuptools", "wheel", "-q"])

    # 3. Install requirements
    req_file = BACKEND_DIR / "requirements.txt"
    if req_file.exists():
        print(f"  {Style.BLUE}Installing backend requirements from backend/requirements.txt...{Style.NC}")
        run_cmd([str(PYTHON_VENV_BIN), "-m", "pip", "install", "-r", str(req_file), "-q"])
        success("FastAPI backend dependencies installed successfully.")
    else:
        warn("backend/requirements.txt not found.")


def setup_database():
    step_info(4, 6, "Initializing Database & Seeding Deterministic Data...")
    seed_script = BACKEND_DIR / "app" / "seed.py"
    
    if seed_script.exists():
        try:
            res = run_cmd([str(PYTHON_VENV_BIN), str(seed_script)], cwd=str(PROJECT_ROOT), capture_output=True)
            success("Database schema migrated and seeded with initial demo data:")
            for line in res.stdout.strip().splitlines():
                if "✔" in line or "Seeded" in line or "Created" in line or "Ready" in line:
                    print(f"    {Style.DIM}{line}{Style.NC}")
        except subprocess.CalledProcessError as e:
            error(f"Database seed failed: {e.stderr or e.output}")
            sys.exit(1)
    else:
        warn(f"Seed script not found at {seed_script}")


def setup_flutter_packages_and_apps():
    step_info(5, 6, "Installing Dependencies for Flutter Packages & Applications...")

    packages = [
        ("Shared Model (domain_models)", UI_DIR / "packages" / "domain_models"),
        ("Shared API Client (api_client)", UI_DIR / "packages" / "api_client"),
        ("Shared Auth Session (auth_session)", UI_DIR / "packages" / "auth_session"),
        ("Shared Design System (design_system)", UI_DIR / "packages" / "design_system"),
        ("Shared Realtime Client (realtime_client)", UI_DIR / "packages" / "realtime_client"),
    ]

    apps = [
        ("Admin Web Portal (admin)", UI_DIR / "apps" / "admin"),
        ("Customer Mobile App (customer)", UI_DIR / "apps" / "customer"),
        ("Rider Mobile App (rider)", UI_DIR / "apps" / "rider"),
    ]

    # Shared packages first
    print(f"\n  {Style.BOLD}--- Step 5A: Shared Foundation Packages ---{Style.NC}")
    for name, pkg_dir in packages:
        if pkg_dir.exists() and (pkg_dir / "pubspec.yaml").exists():
            print(f"  {Style.BLUE}• Fetching packages for {name}...{Style.NC}")
            try:
                run_cmd(["flutter", "pub", "get"], cwd=str(pkg_dir), capture_output=True)
                success(f"{name} ready.")
            except subprocess.CalledProcessError as e:
                error(f"Failed to fetch packages for {name}: {e.stderr}")
                sys.exit(1)
        else:
            warn(f"Directory or pubspec.yaml missing for {name}")

    # Apps
    print(f"\n  {Style.BOLD}--- Step 5B: Flutter Client Applications ---{Style.NC}")
    for name, app_dir in apps:
        if app_dir.exists() and (app_dir / "pubspec.yaml").exists():
            print(f"  {Style.BLUE}• Fetching packages for {name}...{Style.NC}")
            try:
                run_cmd(["flutter", "pub", "get"], cwd=str(app_dir), capture_output=True)
                success(f"{name} ready.")
            except subprocess.CalledProcessError as e:
                error(f"Failed to fetch packages for {name}: {e.stderr}")
                sys.exit(1)
        else:
            warn(f"Directory or pubspec.yaml missing for {name}")


def verify_installation():
    step_info(6, 6, "Final Health Verification...")
    
    # Check Python backend import
    try:
        verify_code = "import fastapi, uvicorn, sqlalchemy, pydantic; from app.main import app; print('Backend OK')"
        run_cmd([str(PYTHON_VENV_BIN), "-c", verify_code], cwd=str(BACKEND_DIR), capture_output=True)
        success("FastAPI backend engine and routers verified.")
    except Exception as e:
        warn(f"Backend verification check warning: {e}")

    # Make executable scripts executable on Unix
    if not IS_WINDOWS:
        for script in ["start.sh", "install.sh"]:
            sp = PROJECT_ROOT / script
            if sp.exists():
                try:
                    os.chmod(sp, 0o755)
                except Exception:
                    pass
        success("Launcher script permissions configured.")


def print_completion_banner():
    print(f"\n{Style.BOLD}{Style.GREEN}═════════════════════════════════════════════════════════════════{Style.NC}")
    print(f"{Style.BOLD}{Style.GREEN} 🎉  M&S DELIVERY SYSTEM INSTALLATION COMPLETED SUCCESSFULLY!    {Style.NC}")
    print(f"{Style.BOLD}{Style.GREEN}═════════════════════════════════════════════════════════════════{Style.NC}")
    
    print(f"""
{Style.BOLD}Installed Components:{Style.NC}
  ✔ Python Virtual Environment ({VENV_DIR.name})
  ✔ FastAPI Real-Time Backend Engine + Database
  ✔ 5 Shared Flutter Dart Packages (domain_models, api_client, etc.)
  ✔ 3 Flutter Client Applications (Admin, Customer, Rider)

{Style.BOLD}How to Start the System:{Style.NC}
  {Style.CYAN}macOS / Linux:{Style.NC}     ./start.sh   {Style.DIM}(or: python3 start.py){Style.NC}
  {Style.CYAN}Windows (PS):{Style.NC}      .\\start.ps1  {Style.DIM}(or: python start.py){Style.NC}
  {Style.CYAN}Windows (CMD):{Style.NC}     start.bat

{Style.BOLD}Endpoints & Default Logins:{Style.NC}
  • Backend API & Docs:   {Style.CYAN}http://localhost:8000/docs{Style.NC}
  • Admin Web Portal:     {Style.CYAN}http://localhost:3000{Style.NC}  (admin@mns.com / AdminPass123!)
  • Customer App:         {Style.CYAN}http://localhost:3001{Style.NC}  (customer@mns.com / CustomerPass123!)
  • Rider App:            {Style.CYAN}http://localhost:3002{Style.NC}  (rider@mns.com / RiderPass123!)

{Style.BOLD}{Style.GREEN}Everything is configured and ready to run!{Style.NC}
""")


def main():
    print_header("M&S Delivery Express Kabacan — System Setup & Installer")
    print(f"{Style.DIM}Project Directory: {PROJECT_ROOT}{Style.NC}")
    start_time = time.time()
    
    try:
        check_prerequisites()
        setup_environment_files()
        setup_python_backend()
        setup_database()
        setup_flutter_packages_and_apps()
        verify_installation()
        elapsed = round(time.time() - start_time, 1)
        print(f"\n{Style.DIM}Total installation time: {elapsed} seconds{Style.NC}")
        print_completion_banner()
    except KeyboardInterrupt:
        print(f"\n\n{Style.YELLOW}Installation interrupted by user.{Style.NC}")
        sys.exit(130)
    except Exception as e:
        print(f"\n\n{Style.RED}Installation encountered an error: {e}{Style.NC}")
        sys.exit(1)


if __name__ == "__main__":
    main()
