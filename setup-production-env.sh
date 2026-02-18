#!/bin/bash

# 🚀 Production Environment Setup Script
# Usage: bash setup-production-env.sh

set -e

echo "=================================="
echo "🚀 Production Environment Setup"
echo "=================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running from correct directory
if [ ! -f "DEPLOYMENT_CHECKLIST.md" ]; then
    echo -e "${RED}❌ Please run this script from /opt/gpti directory${NC}"
    exit 1
fi

# ============ FRONTEND ============
echo -e "\n${YELLOW}📦 Frontend Setup (gpti-site)${NC}"

if [ ! -f "gpti-site/.env.production.local" ]; then
    echo "Creating gpti-site/.env.production.local..."
    cp gpti-site/.env.production.local.example gpti-site/.env.production.local
    echo -e "${GREEN}✅ Created - please edit with real values:${NC}"
    echo "   nano gpti-site/.env.production.local"
else
    echo -e "${GREEN}✅ gpti-site/.env.production.local exists${NC}"
fi

# Verify production env has values
echo "Verifying frontend production env..."
if grep -q "http://51.210.246.61:9000" gpti-site/.env.production.local; then
    echo -e "${GREEN}✅ MinIO URLs configured${NC}"
else
    echo -e "${RED}❌ MinIO URLs missing${NC}"
fi

if grep -q "hooks.slack.com/services/T08BTRRNC4V" gpti-site/.env.production.local; then
    echo -e "${GREEN}✅ Slack webhook configured${NC}"
else
    echo -e "${YELLOW}⚠️  Slack webhook not configured (optional for frontend)${NC}"
fi

# ============ BACKEND BOT ============
echo -e "\n${YELLOW}📦 Backend Bot Setup (gpti-data-bot)${NC}"

if [ ! -f "gpti-data-bot/.env.production.local" ]; then
    echo "Creating gpti-data-bot/.env.production.local..."
    cp gpti-data-bot/.env.production.local.example gpti-data-bot/.env.production.local
    echo -e "${GREEN}✅ Created - please edit with real values:${NC}"
    echo "   nano gpti-data-bot/.env.production.local"
else
    echo -e "${GREEN}✅ gpti-data-bot/.env.production.local exists${NC}"
fi

# Verify production env has values
if grep -q "a16332001@smtp-brevo.com" gpti-data-bot/.env.production.local; then
    echo -e "${GREEN}✅ SMTP credentials configured${NC}"
else
    echo -e "${YELLOW}⚠️  SMTP credentials missing (email won't work)${NC}"
fi

if grep -q "U1P2zcMXE8FQHahv" gpti-data-bot/.env.production.local; then
    echo -e "${GREEN}✅ Brevo API key configured${NC}"
else
    echo -e "${YELLOW}⚠️  Brevo API key missing${NC}"
fi

# ============ INFRASTRUCTURE ============
echo -e "\n${YELLOW}📦 Infrastructure Setup (infra)${NC}"

if [ ! -f "gpti-data-bot/infra/.env.production.local" ]; then
    echo "Creating gpti-data-bot/infra/.env.production.local..."
    cp gpti-data-bot/infra/.env.production.local.example gpti-data-bot/infra/.env.production.local
    echo -e "${GREEN}✅ Created - please edit with real values:${NC}"
    echo "   nano gpti-data-bot/infra/.env.production.local"
else
    echo -e "${GREEN}✅ gpti-data-bot/infra/.env.production.local exists${NC}"
fi

# Verify production env has values
if grep -q "2e8c1b61927c490738c23e5e7976f69790a1b2bd4c75b1c8" gpti-data-bot/infra/.env.production.local; then
    echo -e "${GREEN}✅ Postgres credentials configured${NC}"
else
    echo -e "${YELLOW}⚠️  Postgres credentials missing${NC}"
fi

if grep -q "05eec508d5f6235c" gpti-data-bot/infra/.env.production.local; then
    echo -e "${GREEN}✅ MinIO root credentials configured${NC}"
else
    echo -e "${YELLOW}⚠️  MinIO root credentials missing${NC}"
fi

# ============ GIT IGNORE CHECK ============
echo -e "\n${YELLOW}🔒 Security Check${NC}"

if grep -q "\.env\.production\.local" .gitignore; then
    echo -e "${GREEN}✅ .env.production.local is in .gitignore${NC}"
else
    echo -e "${RED}❌ .env.production.local NOT in .gitignore${NC}"
    echo "   Adding to .gitignore..."
    echo ".env.production.local" >> .gitignore
fi

if grep -q "\.env\.local" .gitignore; then
    echo -e "${GREEN}✅ .env.local is in .gitignore${NC}"
else
    echo -e "${RED}❌ .env.local NOT in .gitignore${NC}"
    echo "   Adding to .gitignore..."
    echo ".env.local" >> .gitignore
fi

# ============ TEST CONNECTIVITY ============
echo -e "\n${YELLOW}🧪 Testing Connectivity${NC}"

# Test MinIO
echo -n "Testing MinIO connectivity... "
if curl -s http://51.210.246.61:9000/minio/health/live > /dev/null 2>&1; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌${NC}"
fi

# Test Slack webhook
echo -n "Testing Slack webhook... "
SLACK_URL=$(grep "SLACK_WEBHOOK_URL=" gpti-site/.env.production.local | cut -d'=' -f2)
if [ ! -z "$SLACK_URL" ]; then
    if curl -s -X POST "$SLACK_URL" \
        -H 'Content-type: application/json' \
        --data '{"text":"🧪 Production setup test"}' > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
    fi
else
    echo -e "${YELLOW}⏭️  Skipped (not configured)${NC}"
fi

# ============ SUMMARY ============
echo -e "\n${GREEN}=================================="
echo "✅ Production environment setup complete!"
echo "==================================${NC}"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Review and edit all .env.production.local files"
echo "2. Run: bash setup-production-env.sh (again to verify)"
echo "3. Test locally: npm run build && npm run preview"
echo "4. Deploy: netlify deploy --prod (or vercel --prod)"
echo "5. Monitor Slack #alerts for issues"

echo -e "\n${YELLOW}Files to review:${NC}"
echo "  • gpti-site/.env.production.local"
echo "  • gpti-data-bot/.env.production.local"
echo "  • gpti-data-bot/infra/.env.production.local"
echo "  • DEPLOYMENT_CHECKLIST.md"

echo -e "\n${YELLOW}Documentation:${NC}"
echo "  • See DEPLOYMENT_CHECKLIST.md for full instructions"
echo "  • See gpti-site/docs/SLACK_ALERTING_SETUP.md for monitoring"
echo "  • See gpti-data-bot/docs/DEPLOYMENT_VALIDATION.md for backend setup"
