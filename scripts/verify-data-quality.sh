#!/bin/bash
# Script de vérification de la qualité des données GTIXT
# Détecte les doublons, les données manquantes, les valeurs aberrantes

set -e

SITE_URL="${SITE_URL:-http://localhost:3000}"
API_ENDPOINT="${SITE_URL}/api/firms/?limit=200"

echo "🔍 Vérification de la qualité des données GTIXT"
echo "================================================"
echo ""

# Vérifier que l'API est accessible
echo "📡 Test de connectivité à l'API..."
if ! curl -sf "${API_ENDPOINT}" > /dev/null; then
  echo "❌ ERREUR: L'API n'est pas accessible à ${API_ENDPOINT}"
  exit 1
fi
echo "✅ API accessible"
echo ""

# Télécharger les données
echo "📥 Récupération des données..."
RESPONSE=$(curl -s "${API_ENDPOINT}")
TOTAL_FIRMS=$(echo "$RESPONSE" | jq '.firms | length')
echo "✅ ${TOTAL_FIRMS} enregistrements récupérés"
echo ""

# Vérifier les doublons par firm_name
echo "🔎 Vérification des doublons par nom de firme..."
DUPLICATES=$(echo "$RESPONSE" | jq -r '[.firms[] | .name // .firm_name] | group_by(.) | map({name: .[0], count: length}) | map(select(.count > 1))')
DUPLICATE_COUNT=$(echo "$DUPLICATES" | jq 'length')

if [ "$DUPLICATE_COUNT" -gt 0 ]; then
  echo "❌ ERREUR: ${DUPLICATE_COUNT} firmes apparaissent en double:"
  echo "$DUPLICATES" | jq -r '.[] | "  - \(.name): \(.count) fois"'
  echo ""
else
  echo "✅ Aucun doublon détecté"
  echo ""
fi

# Vérifier les doublons par firm_id
echo "🔎 Vérification des doublons par firm_id..."
ID_DUPLICATES=$(echo "$RESPONSE" | jq -r '[.firms[] | select(.firm_id != null) | .firm_id] | group_by(.) | map({id: .[0], count: length}) | map(select(.count > 1))')
ID_DUPLICATE_COUNT=$(echo "$ID_DUPLICATES" | jq 'length')

if [ "$ID_DUPLICATE_COUNT" -gt 0 ]; then
  echo "❌ ERREUR: ${ID_DUPLICATE_COUNT} firm_id en double:"
  echo "$ID_DUPLICATES" | jq -r '.[] | "  - \(.id): \(.count) fois"'
  echo ""
else
  echo "✅ Aucun doublon d'ID détecté"
  echo ""
fi

# Vérifier les données manquantes critiques
echo "🔎 Vérification des données manquantes..."
MISSING_NAME=$(echo "$RESPONSE" | jq '[.firms[] | select(.name == null and .firm_name == null)] | length')
MISSING_SCORE=$(echo "$RESPONSE" | jq '[.firms[] | select(.score_0_100 == null)] | length')
MISSING_ID=$(echo "$RESPONSE" | jq '[.firms[] | select(.firm_id == null)] | length')

echo "  - Firmes sans nom: ${MISSING_NAME}"
echo "  - Firmes sans score: ${MISSING_SCORE}"
echo "  - Firmes sans ID: ${MISSING_ID}"

if [ "$MISSING_NAME" -gt 0 ] || [ "$MISSING_SCORE" -gt 0 ]; then
  echo "⚠️  AVERTISSEMENT: Données manquantes détectées"
  echo ""
else
  echo "✅ Toutes les données critiques présentes"
  echo ""
fi

# Vérifier les valeurs de score aberrantes
echo "🔎 Vérification des scores aberrants..."
INVALID_SCORES=$(echo "$RESPONSE" | jq '[.firms[] | select(.score_0_100 != null and (.score_0_100 < 0 or .score_0_100 > 100))] | length')

if [ "$INVALID_SCORES" -gt 0 ]; then
  echo "❌ ERREUR: ${INVALID_SCORES} scores hors limites [0-100]"
  echo "$RESPONSE" | jq -r '[.firms[] | select(.score_0_100 != null and (.score_0_100 < 0 or .score_0_100 > 100))] | .[] | "  - \(.name // .firm_name): \(.score_0_100)"'
  echo ""
else
  echo "✅ Tous les scores sont dans [0-100]"
  echo ""
fi

# Statistiques finales
echo "📊 Statistiques de qualité des données"
echo "======================================="
UNIQUE_FIRMS=$(echo "$RESPONSE" | jq '[.firms[] | .firm_id // (.name // .firm_name)] | unique | length')
echo "Total enregistrements: ${TOTAL_FIRMS}"
echo "Firmes uniques: ${UNIQUE_FIRMS}"
echo "Taux de duplication: $(echo "scale=2; ($TOTAL_FIRMS - $UNIQUE_FIRMS) * 100 / $TOTAL_FIRMS" | bc)%"
echo ""

# Score de qualité global
QUALITY_SCORE=100
if [ "$DUPLICATE_COUNT" -gt 0 ]; then
  QUALITY_SCORE=$((QUALITY_SCORE - 30))
fi
if [ "$ID_DUPLICATE_COUNT" -gt 0 ]; then
  QUALITY_SCORE=$((QUALITY_SCORE - 20))
fi
if [ "$MISSING_NAME" -gt 0 ]; then
  QUALITY_SCORE=$((QUALITY_SCORE - 15))
fi
if [ "$MISSING_SCORE" -gt 5 ]; then
  QUALITY_SCORE=$((QUALITY_SCORE - 10))
fi
if [ "$INVALID_SCORES" -gt 0 ]; then
  QUALITY_SCORE=$((QUALITY_SCORE - 25))
fi

echo "🎯 Score de qualité: ${QUALITY_SCORE}/100"

if [ "$QUALITY_SCORE" -ge 90 ]; then
  echo "✅ EXCELLENT: Qualité des données optimale"
  exit 0
elif [ "$QUALITY_SCORE" -ge 70 ]; then
  echo "⚠️  BON: Quelques problèmes mineurs détectés"
  exit 0
elif [ "$QUALITY_SCORE" -ge 50 ]; then
  echo "⚠️  MOYEN: Problèmes nécessitant attention"
  exit 1
else
  echo "❌ CRITIQUE: Problèmes majeurs de qualité des données"
  exit 1
fi
