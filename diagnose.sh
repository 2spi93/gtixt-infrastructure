#!/bin/bash

# Diagnostic et correction des erreurs Next.js
echo "🔍 Diagnostic du projet GPTI"
echo "=============================="
echo ""

# 1. Vérifier les dépendances
echo "1️⃣ Vérification des dépendances..."
cd /opt/gpti/gpti-site
npm ls @types/react @types/react-dom @types/node 2>&1 | tail -5
echo ""

# 2. Vérifier tsconfig.json
echo "2️⃣ Configuration TypeScript..."
cat tsconfig.json | jq '.compilerOptions | {jsx, lib, types}'
echo ""

# 3. Vérifier next.config.js  
echo "3️⃣ Configuration Next.js..."
head -20 next.config.js
echo ""

# 4. Nettoyer et rebuilder
echo "4️⃣ Nettoyage du cache..."
rm -rf .next .turbo node_modules/.cache
echo "✓ Cache nettoyé"
echo ""

# 5. Vérifier les fichiers critiques
echo "5️⃣ Vérification des fichiers..."
ls -la pages/api/firm.ts components/InstitutionalHeader.tsx lib/useTranslationStub.ts 2>&1 | awk '{print $NF, "(" $5 " bytes)"}'
echo ""

echo "✅ Diagnostic complet"
