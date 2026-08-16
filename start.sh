#!/usr/bin/env bash
# ==============================================================================
# M&S Delivery Express Kabacan - All-in-One Startup Launcher
# Starts FastAPI REST Backend and all 3 Flutter Applications concurrently.
# ==============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Terminal Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${CYAN}======================================================${NC}"
echo -e "${BOLD}${CYAN}    M&S Delivery Express Kabacan - Unified Launcher   ${NC}"
echo -e "${BOLD}${CYAN}======================================================${NC}"

# 1. Clean up any existing instances on target ports
echo -e "${YELLOW}Checking and freeing ports (8000, 3000, 3001, 3002)...${NC}"
for PORT in 8000 3000 3001 3002; do
  PID=$(lsof -ti tcp:$PORT || true)
  if [ -n "$PID" ]; then
    echo -e "Freeing port $PORT (killing PID $PID)..."
    kill -9 $PID 2>/dev/null || true
  fi
done

# 2. Verify / Run DB Seed
echo -e "${BLUE}Ensuring database is migrated and seeded...${NC}"
.venv/bin/python backend/app/seed.py

# Trap SIGINT / SIGTERM for clean shutdown
cleanup() {
  echo -e "\n${YELLOW}Shutting down all M&S Delivery services...${NC}"
  kill 0
  exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# 3. Start Backend
echo -e "${GREEN}Starting FastAPI Backend on port 8000...${NC}"
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload --app-dir backend > /dev/null 2>&1 &
BACKEND_PID=$!

# 4. Start Admin Web App
echo -e "${GREEN}Starting Admin Console on port 3000...${NC}"
(cd ui/apps/admin && flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0 --dart-define=API_BASE_URL=http://localhost:8000 > /dev/null 2>&1) &
ADMIN_PID=$!

# 5. Start Customer Web App
echo -e "${GREEN}Starting Customer App on port 3001...${NC}"
(cd ui/apps/customer && flutter run -d web-server --web-port=3001 --web-hostname=0.0.0.0 --dart-define=API_BASE_URL=http://localhost:8000 > /dev/null 2>&1) &
CUSTOMER_PID=$!

# 6. Start Rider Web App
echo -e "${GREEN}Starting Rider App on port 3002...${NC}"
(cd ui/apps/rider && flutter run -d web-server --web-port=3002 --web-hostname=0.0.0.0 --dart-define=API_BASE_URL=http://localhost:8000 > /dev/null 2>&1) &
RIDER_PID=$!

echo -e "\n${BOLD}${GREEN}✔ All services launched successfully!${NC}\n"
echo -e "  • ${BOLD}FastAPI Backend Docs:${NC}  ${CYAN}http://localhost:8000/docs${NC}"
echo -e "  • ${BOLD}Admin Console:${NC}         ${CYAN}http://localhost:3000${NC}  (admin@mns.com / AdminPass123!)"
echo -e "  • ${BOLD}Customer App:${NC}          ${CYAN}http://localhost:3001${NC}  (customer@mns.com / CustomerPass123!)"
echo -e "  • ${BOLD}Rider App:${NC}             ${CYAN}http://localhost:3002${NC}  (rider@mns.com / RiderPass123!)"
echo -e "\n${YELLOW}Press Ctrl+C at any time to terminate all services.${NC}\n"

wait
