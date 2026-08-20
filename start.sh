#!/usr/bin/env bash
# ==============================================================================
# M&S Delivery Express Kabacan - Unified Interactive Multi-App Launcher
# Dual Simulator + Cloudflare Tunnel + Hot-Reload Piping
# ==============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Mapbox Access Token
export MAPBOX_ACCESS_TOKEN="pk.eyJ1IjoiamVhcmFyZCIsImEiOiJjbWE2ZjNlM2YwM2wyMmlvYW9mdDQ5OHJ5In0.57WdNE6fCl-qVJAoMZe40Q"

# Terminal Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${CYAN}======================================================${NC}"
echo -e "${BOLD}${CYAN}    M&S Delivery Express Kabacan - Unified Launcher   ${NC}"
echo -e "${BOLD}${CYAN}======================================================${NC}"

# 1. Clean up existing ports & tunnel
echo -e "${YELLOW}Checking and freeing ports (8000, 3000, 3001, 3002)...${NC}"
for PORT in 8000 3000 3001 3002; do
  PID=$(lsof -ti tcp:$PORT || true)
  if [ -n "$PID" ]; then
    echo -e "Freeing port $PORT (killing PID $PID)..."
    kill -9 $PID 2>/dev/null || true
  fi
done
pkill -f "cloudflared tunnel" 2>/dev/null || true

# 2. Database Migration & Seed
echo -e "${BLUE}Ensuring database is migrated and seeded with deterministic IDs...${NC}"
.venv/bin/python backend/app/seed.py

# 3. Start Backend
echo -e "${BLUE}Starting FastAPI Backend on port 8000...${NC}"
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload --app-dir backend 2>&1 | sed -e "s/^/[BACKEND] /" &
BACKEND_PID=$!

# 4. Cloudflare Tunnels (Backend API & Admin Console)
echo -e "${YELLOW}Establishing Cloudflare Tunnels for API & Admin Console...${NC}"
CF_LOG=$(mktemp /tmp/cloudflared.XXXXXX)
cloudflared tunnel --url http://127.0.0.1:8000 > "$CF_LOG" 2>&1 &
CF_PID=$!

CF_ADMIN_LOG=$(mktemp /tmp/cloudflared_admin.XXXXXX)
cloudflared tunnel --url http://127.0.0.1:3000 --http-host-header 0.0.0.0:3000 > "$CF_ADMIN_LOG" 2>&1 &
CF_ADMIN_PID=$!

API_URL=""
for i in {1..15}; do
  API_URL=$(grep -o -E 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' "$CF_LOG" | head -n 1 || true)
  if [ -n "$API_URL" ]; then
    break
  fi
  sleep 1
done

ADMIN_TUNNEL_URL=""
for i in {1..15}; do
  ADMIN_TUNNEL_URL=$(grep -o -E 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' "$CF_ADMIN_LOG" | head -n 1 || true)
  if [ -n "$ADMIN_TUNNEL_URL" ]; then
    break
  fi
  sleep 1
done

if [ -n "$API_URL" ]; then
  echo -e "${BOLD}${GREEN}✔ Backend API Tunnel:${NC}    ${BOLD}${CYAN}$API_URL${NC}"
else
  echo -e "${YELLOW}⚠ Could not establish API Tunnel. Falling back to localhost:8000${NC}"
  API_URL="http://localhost:8000"
fi

if [ -n "$ADMIN_TUNNEL_URL" ]; then
  echo -e "${BOLD}${GREEN}✔ Admin Console Tunnel:${NC}  ${BOLD}${CYAN}$ADMIN_TUNNEL_URL${NC}"
fi

# 5. Detect & Boot Dual Simulators (Customer & Rider)
echo -e "${BLUE}Detecting / Booting Dual Simulators...${NC}"
CUSTOMER_DEVICE=""
RIDER_DEVICE=""

# Check if iPhone 16 exists
IPHONE_16=$(xcrun simctl list devices 2>/dev/null | grep "iPhone 16 (" | head -n 1 | sed -E 's/.* \(([A-F0-9-]+)\).*/\1/' || true)
# Check if iPhone 16 Pro exists
IPHONE_16_PRO=$(xcrun simctl list devices 2>/dev/null | grep "iPhone 16 Pro (" | head -n 1 | sed -E 's/.* \(([A-F0-9-]+)\).*/\1/' || true)

# If iPhone 16 Pro doesn't exist, create it
if [ -z "$IPHONE_16_PRO" ]; then
  echo -e "${YELLOW}Creating iPhone 16 Pro simulator for Rider App...${NC}"
  IPHONE_16_PRO=$(xcrun simctl create "iPhone 16 Pro" "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro" "com.apple.CoreSimulator.SimRuntime.iOS-26-5" 2>/dev/null || true)
fi

# Boot Customer Device (iPhone 16)
if [ -n "$IPHONE_16" ]; then
  xcrun simctl boot "$IPHONE_16" 2>/dev/null || true
  CUSTOMER_DEVICE="$IPHONE_16"
  echo -e "${GREEN}✔ Customer App Simulator:${NC} ${BOLD}iPhone 16 ($CUSTOMER_DEVICE)${NC}"
fi

# Boot Rider Device (iPhone 16 Pro)
if [ -n "$IPHONE_16_PRO" ]; then
  xcrun simctl boot "$IPHONE_16_PRO" 2>/dev/null || true
  RIDER_DEVICE="$IPHONE_16_PRO"
  echo -e "${GREEN}✔ Rider App Simulator:${NC} ${BOLD}iPhone 16 Pro ($RIDER_DEVICE)${NC}"
fi

open -a Simulator 2>/dev/null || true

# 6. Create Named Pipes for Hot Reload
FIFO_DIR=$(mktemp -d /tmp/mns_launcher.XXXXXX)
ADMIN_IN="$FIFO_DIR/admin_in"
CUSTOMER_IN="$FIFO_DIR/customer_in"
RIDER_IN="$FIFO_DIR/rider_in"

mkfifo "$ADMIN_IN" "$CUSTOMER_IN" "$RIDER_IN"

exec 3<>"$ADMIN_IN"
exec 4<>"$CUSTOMER_IN"
exec 5<>"$RIDER_IN"

cleanup() {
  echo -e "\n${YELLOW}Shutting down all M&S Delivery services and Cloudflare Tunnels...${NC}"
  kill -9 $CF_PID $CF_ADMIN_PID 2>/dev/null || true
  rm -f "$CF_LOG" "$CF_ADMIN_LOG" 2>/dev/null || true
  exec 3>&- 4>&- 5>&- 2>/dev/null || true
  rm -rf "$FIFO_DIR" 2>/dev/null || true
  kill 0 2>/dev/null || true
  exit 0
}
trap cleanup SIGINT SIGTERM EXIT

echo -e "\n${BOLD}${GREEN}✔ Launching services connected to Cloudflare Tunnel ($API_URL)...${NC}\n"
echo -e "  • ${BOLD}Backend API Tunnel:${NC}    ${CYAN}$API_URL${NC}"
echo -e "  • ${BOLD}Backend API Docs:${NC}      ${CYAN}$API_URL/docs${NC} (${CYAN}http://localhost:8000/docs${NC})"
if [ -n "$ADMIN_TUNNEL_URL" ]; then
  echo -e "  • ${BOLD}Admin Console (Online):${NC} ${BOLD}${CYAN}$ADMIN_TUNNEL_URL${NC}  (admin@mns.com / AdminPass123!)"
fi
echo -e "  • ${BOLD}Admin Console (Local):${NC}  ${CYAN}http://localhost:3000${NC}  (admin@mns.com / AdminPass123!)"
if [ -n "$CUSTOMER_DEVICE" ]; then
  echo -e "  • ${BOLD}Customer App:${NC}          ${CYAN}Simulator (iPhone 16)${NC} (customer@mns.com)"
else
  echo -e "  • ${BOLD}Customer App:${NC}          ${CYAN}http://localhost:3001${NC}  (customer@mns.com)"
fi
if [ -n "$RIDER_DEVICE" ]; then
  echo -e "  • ${BOLD}Rider App:${NC}             ${CYAN}Simulator (iPhone 16 Pro)${NC} (rider@mns.com)"
else
  echo -e "  • ${BOLD}Rider App:${NC}             ${CYAN}http://localhost:3002${NC}  (rider@mns.com)"
fi
echo -e "  • ${BOLD}Mapbox Token:${NC}          ${CYAN}Active${NC}"
echo -e "\n${BOLD}${MAGENTA}Interactive Controls (broadcast to ALL apps):${NC}"
echo -e "  [${BOLD}r${NC}] Hot Reload 🔥🔥🔥"
echo -e "  [${BOLD}R${NC}] Hot Restart 🔄"
echo -e "  [${BOLD}c${NC}] Clear Screen 🧹"
echo -e "  [${BOLD}h${NC}] List Help ❓"
echo -e "  [${BOLD}q${NC}] Quit All Services 🛑\n"
echo -e "------------------------------------------------------"

# Start Admin Web App
(cd ui/apps/admin && flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0 --dart-define=API_BASE_URL=$API_URL --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN < "$ADMIN_IN" 2>&1 | sed -e "s/^/[ADMIN] /") &

# Start Customer App (on iPhone 16)
if [ -n "$CUSTOMER_DEVICE" ]; then
  (cd ui/apps/customer && flutter run -d "$CUSTOMER_DEVICE" --dart-define=API_BASE_URL=$API_URL --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN < "$CUSTOMER_IN" 2>&1 | sed -e "s/^/[CUSTOMER] /") &
else
  (cd ui/apps/customer && flutter run -d web-server --web-port=3001 --web-hostname=0.0.0.0 --dart-define=API_BASE_URL=$API_URL --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN < "$CUSTOMER_IN" 2>&1 | sed -e "s/^/[CUSTOMER] /") &
fi

# Start Rider App (on iPhone 16 Pro if booted, otherwise web-server)
if [ -n "$RIDER_DEVICE" ]; then
  (cd ui/apps/rider && flutter run -d "$RIDER_DEVICE" --dart-define=API_BASE_URL=$API_URL --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN < "$RIDER_IN" 2>&1 | sed -e "s/^/[RIDER] /") &
else
  (cd ui/apps/rider && flutter run -d web-server --web-port=3002 --web-hostname=0.0.0.0 --dart-define=API_BASE_URL=$API_URL --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN < "$RIDER_IN" 2>&1 | sed -e "s/^/[RIDER] /") &
fi

# Interactive command loop
while true; do
  read -r -n 1 key 2>/dev/null || true
  case "$key" in
    r)
      echo -e "\n${BOLD}${GREEN}⚡ Broadcasting HOT RELOAD to all apps... 🔥🔥🔥${NC}"
      printf "r" >&3
      printf "r" >&4
      printf "r" >&5
      ;;
    R)
      echo -e "\n${BOLD}${YELLOW}🔄 Broadcasting HOT RESTART to all apps...${NC}"
      printf "R" >&3
      printf "R" >&4
      printf "R" >&5
      ;;
    c)
      clear
      echo -e "${BOLD}${CYAN}Screen cleared.${NC}"
      ;;
    h)
      printf "h" >&3
      ;;
    q)
      echo -e "\n${BOLD}${RED}🛑 Exiting all services...${NC}"
      cleanup
      ;;
  esac
done
