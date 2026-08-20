# 🚀 M&S Delivery Express Kabacan — Real-Time Delivery & Courier System

A modern, full-stack real-time food delivery and courier dispatch platform tailored for Kabacan, Cotabato. Built with a high-performance **FastAPI** backend (WebSocket live telemetry) and a multi-platform **Flutter** ecosystem (**Admin Web Portal**, **Rider Mobile App**, and **Customer Mobile App**), powered by **Cloudflare Tunnels** for instant global HTTPS access without open ports or static IPs.

---

## 📑 Table of Contents
- [Architecture Overview](#-architecture-overview)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Quick Start (One-Command Launcher)](#-quick-start-one-command-launcher)
- [How Cloudflare Tunnels Work](#-how-cloudflare-tunnels-work)
- [Default Test Credentials](#-default-test-credentials)
- [Manual Execution Guide](#-manual-execution-guide)
  - [1. Backend & Database Setup](#1-backend--database-setup)
  - [2. Starting Cloudflare Tunnels](#2-starting-cloudflare-tunnels)
  - [3. Running Flutter Applications](#3-running-flutter-applications)
- [Production Web Build & Deployment](#-production-web-build--deployment)
- [WebSocket & Real-Time Telemetry](#-websocket--real-time-telemetry)
- [Troubleshooting & FAQs](#-troubleshooting--faqs)

---

## 🏛 Architecture Overview

```mermaid
graph TD
    subgraph Cloudflare Global Edge
        CF_API[Backend Cloudflare Tunnel<br/>https://*.trycloudflare.com]
        CF_ADMIN[Admin Console Cloudflare Tunnel<br/>https://*.trycloudflare.com]
    end

    subgraph Client Apps (Flutter)
        ADMIN_WEB[Admin Portal<br/>Flutter Web :3000]
        RIDER_APP[Rider App<br/>iOS Simulator / Web :3002]
        CUSTOMER_APP[Customer App<br/>iOS Simulator / Web :3001]
    end

    subgraph Core Backend (FastAPI :8000)
        FASTAPI[FastAPI ASGI Server]
        WS_HUB[WebSocket Dispatch & GPS Hub]
        DB[(SQLite / PostgreSQL Database)]
    end

    CF_ADMIN -->|Host: 0.0.0.0:3000| ADMIN_WEB
    CF_API -->|Forward to :8000| FASTAPI

    ADMIN_WEB -->|REST & WebSockets| CF_API
    RIDER_APP -->|REST & GPS Telemetry WS| CF_API
    CUSTOMER_APP -->|REST & Order Tracking WS| CF_API

    FASTAPI --> DB
    FASTAPI --> WS_HUB
```

- **Backend (`backend/`)**: FastAPI, SQLAlchemy, SQLite/PostgreSQL, JWT Authentication, WebSocket Hub for live rider coordinates & order statuses.
- **Admin Portal (`ui/apps/admin`)**: Operations dashboard, live interactive map (Mapbox / OpenStreetMap), order assignment, rider management, store & menu catalog, sales reports, and activity logs.
- **Rider App (`ui/apps/rider`)**: Shift dashboard, location sharing engine, interactive turn-by-turn routing, pickup & delivery task checklist, cash collection (COD), and earnings log.
- **Customer App (`ui/apps/customer`)**: Restaurant browsing, cart management with fixed Kabacan delivery fee, cash on delivery (COD) checkout, live order tracking with polyline route visualization, and saved addresses.

---

## 📂 Project Structure

```text
.
├── backend/                  # FastAPI backend server
│   ├── app/
│   │   ├── api/v1/          # REST endpoints (auth, orders, riders, stores, etc.)
│   │   ├── core/            # Config, security, database engine
│   │   ├── models/          # SQLAlchemy database models
│   │   ├── schemas/         # Pydantic validation schemas
│   │   ├── websocket/       # Real-time WebSocket connection manager
│   │   └── seed.py          # Database seeder (Kabacan stores, riders, users)
│   └── requirements.txt
├── ui/
│   ├── apps/
│   │   ├── admin/           # Admin Web Application (Flutter Web)
│   │   ├── customer/        # Customer Application (iOS / Android / Web)
│   │   └── rider/           # Rider Application (iOS / Android / Web)
│   └── packages/
│       ├── api_client/      # Unified REST & WebSocket API client
│       ├── auth_session/    # JWT token storage & session manager
│       ├── design_system/   # Shared UI components, colors, and typography
│       └── domain_models/   # Shared domain entities & enums
├── start.sh                  # Interactive bash launcher (Tunnels + Simulators + Hot-Reload)
├── start.py                  # Python unified multi-app launcher
└── README.md
```

---

## ⚙️ Prerequisites

Make sure the following dependencies are installed on your machine:

1. **Flutter SDK** (`>= 3.20.0`):
   ```bash
   flutter --version
   flutter doctor
   ```
2. **Python** (`>= 3.10`):
   ```bash
   python3 --version
   ```
3. **Cloudflare `cloudflared` CLI**:
   - **macOS (Homebrew)**:
     ```bash
     brew install cloudflared
     ```
   - **Linux (Debian/Ubuntu)**:
     ```bash
     sudo apt-get install cloudflared
     ```
   - **Windows**:
     ```powershell
     winget install Cloudflare.cloudflared
     ```
4. **Xcode & iOS Simulator** *(macOS only, optional for running native simulators)*:
   ```bash
   xcode-select --install
   ```

---

## ⚡ Quick Start (One-Command Launcher)

The easiest and recommended way to start the entire system with Cloudflare Tunnels, dual mobile simulators (or web fallbacks), and interactive hot-reloading is using [`./start.sh`](file:///Users/kianjearardnaquines/mns/start.sh):

```bash
chmod +x start.sh
./start.sh
```

### What `./start.sh` does automatically:
1. **Frees all required ports** (`8000`, `3000`, `3001`, `3002`).
2. **Migrates and seeds the database** with Kabacan stores, menu items, sample orders, and accounts.
3. **Starts the FastAPI Backend** on port `8000`.
4. **Spawns Cloudflare Tunnels**:
   - Public Backend API Tunnel (`https://<api-subdomain>.trycloudflare.com`)
   - Public Admin Console Tunnel (`https://<admin-subdomain>.trycloudflare.com`)
5. **Detects & boots dual iOS Simulators** (iPhone 16 for Customer, iPhone 16 Pro for Rider) or falls back to Web Server ports.
6. **Passes the public API URL** to all Flutter apps via `--dart-define=API_BASE_URL=<Cloudflare_URL>`.
7. **Opens interactive Hot-Reload control pipes**.

### Interactive Controls (in terminal):
| Key | Action |
| :--- | :--- |
| `r` | 🔥 **Hot Reload** all running Flutter applications simultaneously |
| `R` | 🔄 **Hot Restart** all running Flutter applications |
| `c` | 🧹 Clear terminal screen |
| `q` | 🛑 Gracefully stop all apps and shut down Cloudflare tunnels |

---

## 🌐 How Cloudflare Tunnels Work

Cloudflare Quick Tunnels (`trycloudflare.com`) expose your local servers securely to the internet without needing port forwarding, dynamic DNS, or public IP addresses.

### 1. Backend API Tunnel
```bash
cloudflared tunnel --url http://127.0.0.1:8000
```
- Routes public HTTPS traffic to FastAPI.
- Automatically handles SSL/TLS termination and WebSocket connections (`wss://.../ws/...`).

### 2. Admin Console Web Tunnel
```bash
cloudflared tunnel --url http://127.0.0.1:3000 --http-host-header 0.0.0.0:3000
```
> [!IMPORTANT]
> When tunneling Flutter Web (`web-server` or static server), `--http-host-header 0.0.0.0:3000` is required so that incoming requests match the local host header binding.

---

## 🔑 Default Test Credentials

All accounts come pre-seeded and ready to use:

| Role | Email | Password | Access Location |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin@mns.com` | `AdminPass123!` | Admin Web Portal (`:3000` / Cloudflare URL) |
| **Rider** | `rider@mns.com` | `RiderPass123!` | Rider App (`:3002` / Simulator) |
| **Customer** | `customer@mns.com` | `CustomerPass123!` | Customer App (`:3001` / Simulator) |

---

## 🛠 Manual Execution Guide

If you prefer to start components individually in separate terminal tabs:

### 1. Backend & Database Setup
```bash
# Set up Python virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r backend/requirements.txt

# Run database migration & seed
python backend/app/seed.py

# Start FastAPI server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload --app-dir backend
```
- Local Docs: `http://localhost:8000/docs`

---

### 2. Starting Cloudflare Tunnels

In a new terminal, launch the Backend API Tunnel:
```bash
cloudflared tunnel --url http://127.0.0.1:8000
```
*Copy the generated URL (e.g., `https://example-api.trycloudflare.com`).*

In another terminal, launch the Admin Console Tunnel:
```bash
cloudflared tunnel --url http://127.0.0.1:3000 --http-host-header 0.0.0.0:3000
```
*Copy the generated URL (e.g., `https://example-admin.trycloudflare.com`).*

---

### 3. Running Flutter Applications

Export your Mapbox access token and public API URL:
```bash
export API_URL="https://example-api.trycloudflare.com"
export MAPBOX_ACCESS_TOKEN="your_mapbox_access_token_here"
```

#### A. Run Admin Web App
```bash
cd ui/apps/admin
flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0 \
  --dart-define=API_BASE_URL=$API_URL \
  --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN
```

#### B. Run Customer App
```bash
cd ui/apps/customer
# To run on iOS Simulator:
flutter run -d "iPhone 16" \
  --dart-define=API_BASE_URL=$API_URL \
  --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN

# Or to run on Web:
flutter run -d web-server --web-port=3001 --web-hostname=0.0.0.0 \
  --dart-define=API_BASE_URL=$API_URL \
  --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN
```

#### C. Run Rider App
```bash
cd ui/apps/rider
# To run on iOS Simulator:
flutter run -d "iPhone 16 Pro" \
  --dart-define=API_BASE_URL=$API_URL \
  --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN

# Or to run on Web:
flutter run -d web-server --web-port=3002 --web-hostname=0.0.0.0 \
  --dart-define=API_BASE_URL=$API_URL \
  --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN
```

---

## 📦 Production Web Build & Deployment

To build a standalone, optimized production bundle for the Admin Portal:

```bash
cd ui/apps/admin
flutter build web --release \
  --dart-define=API_BASE_URL="https://your-api-domain.com" \
  --dart-define=MAPBOX_ACCESS_TOKEN="your-mapbox-token"
```

Serve the output static files (`build/web/`) using any web server or container:
```bash
# Using Python static server:
python3 -m http.server 3000 --directory ui/apps/admin/build/web

# Or using NGINX, Docker, or Cloudflare Pages
```

---

## 📡 WebSocket & Real-Time Telemetry

The platform uses WebSockets for instant updates across apps:

| Channel | Endpoint | Description |
| :--- | :--- | :--- |
| **Order Tracking** | `/api/v1/ws/orders/{order_id}` | Broadcasts order status changes (`pending` $\rightarrow$ `assigned` $\rightarrow$ `picked_up` $\rightarrow$ `on_the_way` $\rightarrow$ `delivered`) and live rider GPS coordinates to the Customer app. |
| **Rider GPS Stream** | `/api/v1/ws/riders/{rider_id}/telemetry` | Ingests real-time latitude, longitude, heading, and speed from the Rider app. |
| **Admin Dispatch Feed** | `/api/v1/ws/admin/dispatch` | Streams live order creations, assignment events, and live rider positions onto the Admin Live Map. |

---

## ❓ Troubleshooting & FAQs

### 1. `cloudflared` command not found
Install the CLI via Homebrew (`brew install cloudflared`) or download it from the [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/).

### 2. Port already in use (8000, 3000, 3001, 3002)
Run `./start.sh` which automatically frees the ports, or manually kill them:
```bash
lsof -ti tcp:8000,3000,3001,3002 | xargs kill -9
```

### 3. iOS Simulator not launching
Make sure Xcode is configured with command line tools:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### 4. WebSocket connection issues over Cloudflare
Ensure the `API_BASE_URL` uses `https://`. The client automatically translates `https://` to `wss://` for WebSocket connections.

---

## 📄 License
This project is proprietary and maintained for **M&S Delivery Express Kabacan**. All rights reserved.
