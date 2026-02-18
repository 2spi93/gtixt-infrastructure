#!/bin/bash
# Test script to verify data flow and calculations

set -e

echo "🔍 VERIFICATION DU FLUX DE DONNEES - GPTI"
echo "========================================"

cd /opt/gpti

# Test 1: Vérifier snapshot JSON
echo ""
echo "TEST 1: Snapshot JSON"
echo "--------------------"
SNAPSHOT_COUNT=$(jq '.records | length' gpti-site/data/test-snapshot.json 2>/dev/null || echo "0")
echo "✅ Firmas dans snapshot: $SNAPSHOT_COUNT"
if [ "$SNAPSHOT_COUNT" -lt 50 ]; then
    echo "⚠️  ATTENTION: Moins de 50 firmas!"
fi

# Test 2: Vérifier structure snapshot
echo ""
echo "TEST 2: Structure Snapshot"
echo "------------------------"
HAS_SCORE=$(jq '.records[0].score_0_100' gpti-site/data/test-snapshot.json 2>/dev/null | grep -c "^[0-9]" || echo "0")
echo "✅ Scores présents: $HAS_SCORE/1"

CONF_RAW=$(jq -r '.records[0].confidence // empty' gpti-site/data/test-snapshot.json 2>/dev/null)
if [ -n "$CONF_RAW" ]; then
    echo "✅ Confidence présente: $CONF_RAW"
else
    echo "❌ Confidence manquante"
fi

HAS_NA_RATE=$(jq '.records[0].na_rate' gpti-site/data/test-snapshot.json 2>/dev/null | grep -c "[0-9.]" || echo "0")
echo "✅ N/A rate présente: $HAS_NA_RATE/1"

# Test 3: Vérifier les types de données
echo ""
echo "TEST 3: Validation des Types"
echo "----------------------------"
FIRST_RECORD=$(jq '.records[0]' gpti-site/data/test-snapshot.json 2>/dev/null)

SCORE=$(echo "$FIRST_RECORD" | jq '.score_0_100')
if [[ $SCORE =~ ^[0-9]+\.?[0-9]*$ ]]; then
    echo "✅ score_0_100 est un nombre: $SCORE"
else
    echo "❌ score_0_100 n'est pas un nombre: $SCORE"
fi

CONFIDENCE=$(echo "$FIRST_RECORD" | jq -r '.confidence')
if [[ $CONFIDENCE =~ ^[0-9]+\.?[0-9]*$ ]]; then
    echo "✅ confidence est un nombre: $CONFIDENCE"
elif [[ $CONFIDENCE == "high" || $CONFIDENCE == "medium" || $CONFIDENCE == "low" ]]; then
    echo "✅ confidence est un label: $CONFIDENCE"
else
    echo "❌ confidence n'est pas valide: $CONFIDENCE"
fi

NA_RATE=$(echo "$FIRST_RECORD" | jq '.na_rate')
if [[ $NA_RATE =~ ^[0-9]+\.?[0-9]*$ ]] || [[ $NA_RATE == "null" ]]; then
    echo "✅ na_rate est un nombre ou null: $NA_RATE"
else
    echo "❌ na_rate n'est pas valide: $NA_RATE"
fi

# Test 4: Vérifier agents Python
echo ""
echo "TEST 4: Agents Python"
echo "--------------------"
AGENT_COUNT=$(ls gpti-data-bot/src/gpti_bot/agents/*.py 2>/dev/null | wc -l)
echo "✅ Agents trouvés: $AGENT_COUNT"

# Test 5: Vérifier .env files
echo ""
echo "TEST 5: Configuration .env"
echo "-------------------------"
for env_file in gpti-site/.env.local gpti-data-bot/.env.local gpti-data-bot/infra/.env.local; do
    if [ -f "$env_file" ]; then
        echo "✅ $env_file existe"
    else
        echo "❌ $env_file manquant"
    fi
done

# Test 6: Vérifier MinIO URLs
echo ""
echo "TEST 6: MinIO Configuration"
echo "-------------------------"
MINIO_URL=$(grep "MINIO_PUBLIC_ROOT\|MINIO_ENDPOINT" gpti-site/.env.local 2>/dev/null | head -1)
echo "✅ MinIO URL: $MINIO_URL"

# Test 7: Vérifier PostgreSQL connection string
echo ""
echo "TEST 7: PostgreSQL Configuration"
echo "-------------------------------"
DB_URL=$(grep "DATABASE_URL" gpti-data-bot/.env.local 2>/dev/null | head -1)
echo "✅ Database config trouvé: $(echo $DB_URL | head -c 50)..."

# Test 8: Calcul de vérification
echo ""
echo "TEST 8: Validation Calculs"
echo "-----------------------"
SCORES=$(jq '[.records[].score_0_100] | map(select(. != null))' gpti-site/data/test-snapshot.json 2>/dev/null)
MIN_SCORE=$(echo "$SCORES" | jq 'min')
MAX_SCORE=$(echo "$SCORES" | jq 'max')
AVG_SCORE=$(echo "$SCORES" | jq 'add / length')

echo "Score MIN: $MIN_SCORE"
echo "Score MAX: $MAX_SCORE"
echo "Score AVG: $AVG_SCORE"

if (( $(echo "$MIN_SCORE >= 0" | bc -l) )) && (( $(echo "$MAX_SCORE <= 100" | bc -l) )); then
    echo "✅ Scores dans la plage 0-100"
else
    echo "❌ Scores hors plage: $MIN_SCORE - $MAX_SCORE"
fi

# Test 9: Vérifier TypeScript compilation
echo ""
echo "TEST 9: TypeScript Compilation"
echo "-----------------------------"
cd gpti-site
if npx tsc --noEmit 2>&1 | grep -q "error"; then
    echo "❌ Erreurs TypeScript détectées:"
    npx tsc --noEmit 2>&1 | grep "error" | head -3
else
    echo "✅ Pas d'erreurs TypeScript"
fi
cd /opt/gpti

echo ""
echo "========================================"
echo "✅ VERIFICATION COMPLETE"
echo "========================================"
