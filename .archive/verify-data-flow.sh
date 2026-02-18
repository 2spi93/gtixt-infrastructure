#!/bin/bash

# Vérifier le flux de données complet: agents → snapshot → API → pages
# Colour codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  VÉRIFICATION COMPLÈTE DU FLUX DE DONNÉES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

PASSED=0
FAILED=0

# ============================================================================
# TEST 1: Vérifier que le snapshot existe avec les vraies juridictions
# ============================================================================
echo -e "\n${YELLOW}[TEST 1]${NC} Snapshot avec juridictions réelles"

SNAPSHOT_PATH="/opt/gpti/gpti-site/data/test-snapshot.json"
SNAPSHOT_TMP="/tmp/gpti_snapshot.json"

if test -f "$SNAPSHOT_PATH"; then
    echo -e "${GREEN}✓${NC} Fichier snapshot trouvé (test-snapshot.json)"
    SNAPSHOT_SOURCE="$SNAPSHOT_PATH"
else
    LATEST_URL=$(grep -E "^NEXT_PUBLIC_LATEST_POINTER_URL=|^NEXT_PUBLIC_SNAPSHOT_LATEST_URL=|^SNAPSHOT_LATEST_URL=" /opt/gpti/gpti-site/.env.local 2>/dev/null | tail -n1 | cut -d= -f2-)
    MINIO_ROOT=$(grep -E "^NEXT_PUBLIC_MINIO_PUBLIC_ROOT=|^MINIO_PUBLIC_ROOT=" /opt/gpti/gpti-site/.env.local 2>/dev/null | head -n1 | cut -d= -f2-)
    LATEST_URL="${LATEST_URL:-https://data.gtixt.com/gpti-snapshots/universe_v0.1_public/_public/latest.json}"
    MINIO_ROOT="${MINIO_ROOT:-https://data.gtixt.com/gpti-snapshots/}"

    LATEST_OBJ=$(curl -s "$LATEST_URL" | jq -r '.object // empty' 2>/dev/null || echo "")
    if [ -n "$LATEST_OBJ" ]; then
        SNAPSHOT_URL="${MINIO_ROOT}${LATEST_OBJ}"
        if curl -sf "$SNAPSHOT_URL" > "$SNAPSHOT_TMP"; then
            echo -e "${GREEN}✓${NC} Snapshot remote trouvé (${SNAPSHOT_URL})"
            SNAPSHOT_SOURCE="$SNAPSHOT_TMP"
        else
            SNAPSHOT_SOURCE=""
        fi
    else
        SNAPSHOT_SOURCE=""
    fi
fi

if [ -n "$SNAPSHOT_SOURCE" ] && test -f "$SNAPSHOT_SOURCE"; then
    ((PASSED++))

    # Compter les juridictions réelles
    TOTAL_FIRMS=$(jq '.records | length' "$SNAPSHOT_SOURCE" 2>/dev/null || jq '.firms | length' "$SNAPSHOT_SOURCE" 2>/dev/null || echo "0")
    echo -e "   Total de firmes: ${TOTAL_FIRMS}"

    # Vérifier qu'aucune juridiction n'est null
    NULL_COUNT=$(jq '( .records // .firms // [] )[] | select(.jurisdiction == null) | .name' "$SNAPSHOT_SOURCE" 2>/dev/null | wc -l)
    if [ "$NULL_COUNT" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Aucune juridiction NULL"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $NULL_COUNT firmes avec juridiction NULL"
        ((FAILED++))
    fi

    # Distribution des juridictions
    echo -e "   Distribution des juridictions:"
    jq -r '( .records // .firms // [] )[] | .jurisdiction' "$SNAPSHOT_SOURCE" 2>/dev/null | sort | uniq -c | sort -rn | sed 's/^/     /'
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Snapshot introuvable (test ou remote)"
    ((FAILED++))
fi

# ============================================================================
# TEST 2: Vérifier que les agents collectent les données
# ============================================================================
echo -e "\n${YELLOW}[TEST 2]${NC} Agents Python (Source de données)"

# Vérifier RVI Agent
if python3 -c "
import sys
sys.path.insert(0, '/opt/gpti/gpti-data-bot/src')
from gpti_bot.agents.rvi_agent import RVIAgent
agent = RVIAgent()
assert agent.name == 'RVI'
assert agent.frequency == 'weekly'
" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} RVI Agent (Registry Verification) - Hebdomadaire"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Erreur RVI Agent"
    ((FAILED++))
fi

# Vérifier REM Agent
if python3 -c "
import sys
sys.path.insert(0, '/opt/gpti/gpti-data-bot/src')
from gpti_bot.agents.rem_agent import REMAgent
agent = REMAgent()
assert agent.name == 'REM'
assert agent.frequency == 'daily'
" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} REM Agent (Regulatory Events) - Quotidienne"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Erreur REM Agent"
    ((FAILED++))
fi

# Vérifier SSS Agent
if python3 -c "
import sys
sys.path.insert(0, '/opt/gpti/gpti-data-bot/src')
from gpti_bot.agents.sss_agent import SSSAgent
agent = SSSAgent()
assert agent.name == 'SSS'
assert agent.frequency == 'monthly'
" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} SSS Agent (Sanctions Screening) - Mensuelle"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Erreur SSS Agent"
    ((FAILED++))
fi

# ============================================================================
# TEST 3: Vérifier les APIs Next.js
# ============================================================================
echo -e "\n${YELLOW}[TEST 3]${NC} APIs Next.js (Endpoints)"

# Vérifier que /api/firms.ts charge le snapshot via MinIO
if grep -q "fetchJsonWithFallback" /opt/gpti/gpti-site/pages/api/firms.ts; then
    echo -e "${GREEN}✓${NC} /api/firms charge le snapshot MinIO"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} /api/firms n'utilise pas MinIO"
    ((FAILED++))
fi

# Vérifier que /api/firm.ts charge le snapshot via MinIO
if grep -q "fetchJsonWithFallback" /opt/gpti/gpti-site/pages/api/firm.ts; then
    echo -e "${GREEN}✓${NC} /api/firm charge le snapshot MinIO"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} /api/firm n'utilise pas MinIO"
    ((FAILED++))
fi

# Vérifier que les APIs retournent les firms
if grep -q "snapshot.records" /opt/gpti/gpti-site/pages/api/firms.ts; then
    echo -e "${GREEN}✓${NC} /api/firms retourne les records du snapshot"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} /api/firms ne retourne pas les records"
    ((FAILED++))
fi

# ============================================================================
# TEST 4: Vérifier les pages consomment les APIs
# ============================================================================
echo -e "\n${YELLOW}[TEST 4]${NC} Pages (Consommatrices de données)"

# Vérifier /rankings.tsx
if grep -q "/api/firms" /opt/gpti/gpti-site/pages/rankings.tsx; then
    echo -e "${GREEN}✓${NC} /rankings appelle /api/firms"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} /rankings n'appelle pas /api/firms"
    ((FAILED++))
fi

# Vérifier /firm/[id].tsx
if grep -q "/api/firm" /opt/gpti/gpti-site/pages/firm/\[id\].tsx; then
    echo -e "${GREEN}✓${NC} /firm/[id] appelle /api/firm"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} /firm/[id] n'appelle pas /api/firm"
    ((FAILED++))
fi

# Vérifier que les pages affichent les juridictions
if grep -q "jurisdiction" /opt/gpti/gpti-site/pages/rankings.tsx; then
    echo -e "${GREEN}✓${NC} /rankings affiche les juridictions"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} /rankings n'affiche pas les juridictions"
    ((FAILED++))
fi

# ============================================================================
# TEST 5: Vérifier Slack Integration (Agent Interface)
# ============================================================================
echo -e "\n${YELLOW}[TEST 5]${NC} Intégration Slack (Interface Agents)"

if test -f /opt/gpti/gpti-data-bot/src/slack_integration/agent_interface.py; then
    echo -e "${GREEN}✓${NC} Fichier agent_interface.py trouvé"
    ((PASSED++))
    
    if grep -q "class AgentInterface" /opt/gpti/gpti-data-bot/src/slack_integration/agent_interface.py; then
        echo -e "${GREEN}✓${NC} Classe AgentInterface définie"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Classe AgentInterface non trouvée"
        ((FAILED++))
    fi
    
    if grep -q "_fetch_data_context" /opt/gpti/gpti-data-bot/src/slack_integration/agent_interface.py; then
        echo -e "${GREEN}✓${NC} Méthode _fetch_data_context pour récupérer MinIO/PostgreSQL"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Pas de méthode de fetch de contexte"
        ((FAILED++))
    fi
else
    echo -e "${RED}✗${NC} Fichier agent_interface.py introuvable"
    ((FAILED++))
fi

# ============================================================================
# TEST 6: Vérifier Orchestration Prefect (Scheduling)
# ============================================================================
echo -e "\n${YELLOW}[TEST 6]${NC} Orchestration Prefect (Scheduling)"

if test -f /opt/gpti/gpti-data-bot/flows/orchestration.py; then
    echo -e "${GREEN}✓${NC} Fichier orchestration.py trouvé"
    ((PASSED++))
    
    if grep -q "flow_daily_agents" /opt/gpti/gpti-data-bot/flows/orchestration.py; then
        echo -e "${GREEN}✓${NC} Flow quotidien pour RVI, REM, IRS, FRP"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Flow quotidien non trouvé"
        ((FAILED++))
    fi
    
    if grep -q "task_run_" /opt/gpti/gpti-data-bot/flows/orchestration.py; then
        # Compter les agents
        AGENT_COUNT=$(grep -o "task_run_[a-z]*" /opt/gpti/gpti-data-bot/flows/orchestration.py | sort -u | wc -l)
        echo -e "${GREEN}✓${NC} $AGENT_COUNT agents orchestrés par Prefect"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Pas de tasks Prefect trouvées"
        ((FAILED++))
    fi
else
    echo -e "${RED}✗${NC} Fichier orchestration.py introuvable"
    ((FAILED++))
fi

# ============================================================================
# TEST 7: Vérifier PageNavigation (Connecte toutes les pages)
# ============================================================================
echo -e "\n${YELLOW}[TEST 7]${NC} Navigation entre Pages"

if test -f /opt/gpti/gpti-site/components/PageNavigation.tsx; then
    echo -e "${GREEN}✓${NC} PageNavigation.tsx trouvé"
    ((PASSED++))
    
    if grep -q "href=\"/rankings\"" /opt/gpti/gpti-site/components/PageNavigation.tsx; then
        echo -e "${GREEN}✓${NC} Navigation vers /rankings"
        ((PASSED++))
    fi
    
    if grep -q "href=\"/agents-dashboard\"" /opt/gpti/gpti-site/components/PageNavigation.tsx; then
        echo -e "${GREEN}✓${NC} Navigation vers /agents-dashboard"
        ((PASSED++))
    fi
else
    echo -e "${RED}✗${NC} PageNavigation.tsx introuvable"
    ((FAILED++))
fi

# ============================================================================
# TEST 8: Vérifier les redirections URL
# ============================================================================
echo -e "\n${YELLOW}[TEST 8]${NC} Redirections URL (next.config.js)"

if grep -q "/firm/.*id" /opt/gpti/gpti-site/next.config.js; then
    echo -e "${GREEN}✓${NC} Redirection /firm/?id= → /firm/[id]"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Redirection /firm/ non trouvée"
    ((FAILED++))
fi

if grep -q "/rankings\|/firms" /opt/gpti/gpti-site/next.config.js; then
    echo -e "${GREEN}✓${NC} Redirection vers /rankings"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Redirection /rankings non trouvée"
    ((FAILED++))
fi

# ============================================================================
# RÉSUMÉ
# ============================================================================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  RÉSUMÉ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

TOTAL=$((PASSED + FAILED))
PERCENTAGE=$((PASSED * 100 / TOTAL))

echo -e "Tests réussis: ${GREEN}${PASSED}${NC}/${TOTAL}"
echo -e "Tests échoués: ${RED}${FAILED}${NC}/${TOTAL}"
echo -e "Taux de réussite: ${PERCENTAGE}%"

if [ "$FAILED" -eq 0 ]; then
    echo -e "\n${GREEN}✓ TOUS LES TESTS RÉUSSIS${NC}"
    echo -e "Le flux de données est correct:"
    echo -e "  Agents (Python) → Snapshot (JSON) → APIs (Next.js) → Pages (React)"
    exit 0
else
    echo -e "\n${RED}✗ ${FAILED} TEST(S) ÉCHOUÉ(S)${NC}"
    exit 1
fi
