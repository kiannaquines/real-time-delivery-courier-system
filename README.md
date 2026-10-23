# 🚀 M&S Delivery Express Kabacan

> **Real-Time Food Delivery & Courier Dispatch Platform tailored for Kabacan, Cotabato.**  
> Powered by a high-performance **FastAPI** backend and a multi-platform **Flutter** ecosystem (**Customer Mobile App**, **Rider Mobile App**, and **Admin Web Operations Console**).

---

## 🌐 Live Staging Backend

The staging environment is deployed and online with 24/7 uptime:

| Resource | URL | Status |
| :--- | :--- | :---: |
| **Live API Server** | `https://real-time-delivery-courier-system.onrender.com` | 🟢 Online |
| **Interactive API Docs (Swagger)** | `https://real-time-delivery-courier-system.onrender.com/docs` | 🟢 Active |
| **Health Check** | `https://real-time-delivery-courier-system.onrender.com/health` | 🟢 200 OK |

---

## 📱 The Applications

| Application | Android / Web Display Name | Icon | What is it for? | Ready-to-Use File |
| :--- | :--- | :---: | :--- | :--- |
| **🛍️ Customer App** | `M&S Delivery Customer` | 🛍️ | Browse Kabacan restaurants, cart, COD checkout, live rider GPS tracking | `build_output\apks\customer-app-release.apk` |
| **🛵 Rider App** | `M&S Express Courier` | 🛵 | On-duty GPS telemetry sharing, accept deliveries, order checklist | `build_output\apks\rider-app-release.apk` |
| **💻 Admin Portal** | `M&S Delivery Operations Console` | 💻 | Live fleet radar map, order dispatching, store catalog, sales audit | `ui/apps/admin/` (Port 3000) |

---

## 📱 Android APK Generation (Easiest Way to Get the Apps)

> 💡 **For Complete Beginners:** You do **not** need to write code or type complicated terminal commands. We created a 1-click builder that compiles the apps and connects to the online staging server automatically.

### 🟢 Easy 3-Step Build Guide:

1. **Double-Click the Builder**:
   In your project folder on Windows, double-click:
   ```text
   build_apk.bat
   ```

2. **Choose Which App to Build**:
   When the menu appears, type a number and press **Enter**:
   - Press **`1`** for the 🛍️ **Customer App**
   - Press **`2`** for the 🛵 **Rider App**
   - Press **`3`** for **Both Apps**  
   *(Then simply press **Enter** to accept the defaults—it connects to the live server automatically!)*

3. **Get Your APK File**:
   When finished, your installer files will be waiting in:
   ```text
   build_output\apks\
   ├── customer-app-release.apk
   └── rider-app-release.apk
   ```

### 📲 How to Install on Your Android Phone:
1. **Send the APK to your phone**: Plug your phone via USB and copy the file over, or upload it to **Google Drive**, **Telegram**, or **WhatsApp**.
2. **Open the file**: On your phone, tap the `.apk` file in your **Files** or **Downloads** app.
3. **Tap Install**: If prompted with *"Allow from this source"*, tap **Allow** $\rightarrow$ tap **Install**. 🎉 **Done!**

---

## ⚡ Running the System Locally (1-Click Launchers)

If you want to run the backend and Flutter apps on your computer:

### 1. First-Time Setup (Run Once):
- **Windows**: Double-click `install.bat`
- **macOS / Linux**: Run `./install.sh`

### 2. Start Everything:
- **Windows**: Double-click `start.bat`
- **macOS / Linux**: Run `./start.sh`

*(The launcher automatically starts the FastAPI server, seeds test data, connects Cloudflare tunnels, and boots the Flutter apps).*

---

## 🔑 Default Test Accounts

All accounts come pre-configured and ready to use:

| Role | Email | Password | Used In |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin@mns.com` | `AdminPass123!` | Admin Web Portal (`http://localhost:3000`) |
| **Rider** | `rider@mns.com` | `RiderPass123!` | Rider Mobile App / Simulator |
| **Customer** | `customer@mns.com` | `CustomerPass123!` | Customer Mobile App / Simulator |

---

## 📖 In-Depth Technical Documentation

Looking for the complete architecture diagram, manual terminal commands, Cloudflare tunnel configurations, Supabase database migration, or WebSocket telemetry schemas?

👉 **See the comprehensive guide: [SETUP.md](SETUP.md)**

It covers:
- 🏛️ Full System Architecture & Mermaid Flowcharts
- 📂 Complete Project Structure & File Tree
- 🛠️ Step-by-Step Manual Execution Guide (FastAPI, uvicorn, Flutter CLI)
- 🌐 Cloudflare Tunnels Deep Dive & Host-Header Rewriting
- 🗄️ One-Click Supabase PostgreSQL Migration
- 📦 Production Web Bundle Compilation
- 📡 WebSocket Channels & Real-Time Telemetry Payloads
- ❓ Full Developer Troubleshooting & FAQ

---

## 📄 License
This project is proprietary and maintained for **M&S Delivery Express Kabacan**. All rights reserved.
