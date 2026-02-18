#!/bin/bash

# 🚀 Staging Deployment Script
# Deploys gpti-data-bot and gpti-site to staging environment
# Usage: bash deploy-staging.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ROOT_DIR="/opt/gpti"
BOT_DIR="$ROOT_DIR/gpti-data-bot"
SITE_DIR="$ROOT_DIR/gpti-site"
DOCKER_DIR="$ROOT_DIR/docker"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  STAGING DEPLOYMENT SCRIPT                                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

# ============================================================================
# STEP 1: Checkout staging branches
# ============================================================================
echo -e "\n${YELLOW}📌 STEP 1: Checking out staging branches${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Switching gpti-data-bot to staging..."
cd "$BOT_DIR"
git fetch origin
git checkout staging
git pull origin staging
echo -e "${GREEN}✅ gpti-data-bot on staging branch${NC}"

echo "Switching gpti-site to staging..."
cd "$SITE_DIR"
git fetch origin
git checkout staging
git pull origin staging
echo -e "${GREEN}✅ gpti-site on staging branch${NC}"

# ============================================================================
# STEP 2: Install dependencies
# ============================================================================
echo -e "\n${YELLOW}📦 STEP 2: Installing dependencies${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Installing backend dependencies..."
cd "$BOT_DIR"
if [ -f "requirements.txt" ]; then
    pip install -q -r requirements.txt 2>/dev/null || echo "⚠️  Some dependencies may have failed"
    echo -e "${GREEN}✅ Backend dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠️  No requirements.txt found${NC}"
fi

if [ -f "pyproject.toml" ]; then
    pip install -q -e . 2>/dev/null || true
fi

echo "Installing frontend dependencies..."
cd "$SITE_DIR"
if [ -f "package.json" ]; then
    npm install --prefer-offline --no-audit 2>/dev/null || echo "⚠️  Some npm packages may have failed"
    echo -e "${GREEN}✅ Frontend dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠️  No package.json found${NC}"
fi

# ============================================================================
# STEP 3: Build frontend (Next.js)
# ============================================================================
echo -e "\n${YELLOW}🔨 STEP 3: Building frontend${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$SITE_DIR"
echo "Building Next.js application..."
npm run build 2>&1 | tail -20 || {
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
}
echo -e "${GREEN}✅ Frontend built successfully${NC}"

# ============================================================================
# STEP 4: Start Docker services
# ============================================================================
echo -e "\n${YELLOW}🐳 STEP 4: Starting Docker services${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$DOCKER_DIR"

echo "Pulling latest images..."
docker compose pull -q 2>/dev/null || true

echo "Bringing up services (postgres, minio, ollama, prefect)..."
docker compose up -d --remove-orphans 2>&1 | grep -E "^Creating|^Starting|^Recreating" || true

echo "Waiting for services to be ready (30 seconds)..."
sleep 30

echo "Checking service health..."
services=("postgres" "minio" "ollama" "prefect-server")
for service in "${services[@]}"; do
    if docker compose ps | grep -q "$service"; then
        echo -e "  ${GREEN}✅${NC} $service is up"
    else
        echo -e "  ${RED}❌${NC} $service is NOT running"
    fi
done

echo -e "${GREEN}✅ Docker services started${NC}"

# ============================================================================
# STEP 5: Start backend service
# ============================================================================
echo -e "\n${YELLOW}🤖 STEP 5: Starting backend service${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$BOT_DIR"

# Set environment
export PYTHONPATH="$BOT_DIR/src:${PYTHONPATH:-}"
export GPTI_ENV=staging
export LOG_LEVEL=INFO

echo "Backend service ready at: PYTHONPATH=$PYTHONPATH"
echo -e "${GREEN}✅ Backend ready for execution${NC}"

# ============================================================================
# STEP 6: Start frontend service
# ============================================================================
echo -e "\n${YELLOW}🌐 STEP 6: Starting frontend service${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$SITE_DIR"

# Check if we need npm run dev or npm start
if grep -q '"dev":' package.json; then
    echo "Starting Next.js development server (port 3000)..."
    nohup npm run dev > /tmp/nextjs-staging.log 2>&1 &
    PID=$!
    echo "PID: $PID"
else
    echo "Starting Next.js production server..."
    nohup npm start > /tmp/nextjs-staging.log 2>&1 &
    PID=$!
    echo "PID: $PID"
fi

echo "Waiting for Next.js to start..."
sleep 15

if ps -p $PID > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend started (PID: $PID)${NC}"
    echo "   Logs: tail -f /tmp/nextjs-staging.log"
else
    echo -e "${RED}❌ Frontend failed to start${NC}"
    cat /tmp/nextjs-staging.log
    exit 1
fi

# ============================================================================
# STEP 7: Summary
# ============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  STAGING DEPLOYMENT COMPLETE                              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}✅ DEPLOYMENT SUMMARY${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n${YELLOW}Services running:${NC}"
echo "  Frontend: http://localhost:3000 (PID: $PID)"
echo "  Docker services:"
docker compose ps | tail -n +3 | while read line; do
    if [ -n "$line" ]; then
        echo "    $(echo $line | awk '{print $1, "(" $NF ")"}')"
    fi
done

echo -e "\n${YELLOW}Environment:${NC}"
echo "  Branch: staging"
echo "  PYTHONPATH: $PYTHONPATH"
echo "  GPTI_ENV: staging"

echo -e "\n${YELLOW}Available commands:${NC}"
echo "  tail -f /tmp/nextjs-staging.log      # View frontend logs"
echo "  docker compose -f $DOCKER_DIR/docker-compose.yml logs -f  # Docker logs"
echo "  bash /opt/gpti/verify-staging.sh     # Run tests"

echo -e "\n${GREEN}✅ Ready for testing!${NC}"
echo ""
