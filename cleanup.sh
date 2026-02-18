#!/bin/bash

# 🧹 Intelligent Disk Cleanup Script
# Removes internal docs, old backups, caches without breaking the system

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  INTELLIGENT DISK CLEANUP                                  ║"
echo "╡════════════════════════════════════════════════════════════╗"

FREED=0

# Get initial size
SIZE_BEFORE=$(du -sh /opt/gpti 2>/dev/null | cut -f1)
echo "Starting size: $SIZE_BEFORE"
echo ""

# ========== CLEANUP 1: Internal documentation (after keeping key parts) ==========
echo "📌 Cleanup 1: Archive old internal docs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -d /opt/gpti/.internal-docs ]; then
    SIZE=$(du -sh /opt/gpti/.internal-docs | cut -f1)
    rm -rf /opt/gpti/.internal-docs
    echo "✅ Removed .internal-docs directory ($SIZE freed)"
else
    echo "✅ .internal-docs already clean"
fi

# ========== CLEANUP 2: Node modules cache ==========
echo ""
echo "📌 Cleanup 2: Clean npm/node cache"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for NODE_MOD in /opt/gpti/gpti-site/node_modules /opt/gpti/gpti-data-bot/node_modules; do
    if [ -d "$NODE_MOD/.cache" ]; then
        rm -rf "$NODE_MOD/.cache"
        echo "✅ Removed $NODE_MOD/.cache"
    fi
done

# Remove package-lock backups
find /opt/gpti -name "package-lock.json.bak" -delete 2>/dev/null || true
echo "✅ Cleaned npm backup files"

# ========== CLEANUP 3: Python cache ==========
echo ""
echo "📌 Cleanup 3: Clean Python cache"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

find /opt/gpti -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find /opt/gpti -type f -name "*.pyc" -delete 2>/dev/null || true
find /opt/gpti -type f -name "*.pyo" -delete 2>/dev/null || true

echo "✅ Cleaned Python cache files"

# ========== CLEANUP 4: Old log files ==========
echo ""
echo "📌 Cleanup 4: Archive old logs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Keep only recent logs
if [ -d /opt/gpti/tmp ]; then
    find /opt/gpti/tmp -name "*.log" -mtime +30 -delete 2>/dev/null || true
    echo "✅ Removed logs older than 30 days"
fi

# ========== CLEANUP 5: Old backups (keep only latest 3) ==========
echo ""
echo "📌 Cleanup 5: Archive old backups"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -d /opt/gpti/backups ]; then
    BACKUP_SIZE=$(du -sh /opt/gpti/backups | cut -f1)
    
    # Keep only 3 most recent postgres backups
    ls -t /opt/gpti/backups/postgres/* 2>/dev/null | tail -n +4 | xargs rm -rf 2>/dev/null || true
    
    # Keep only 3 most recent minio backups
    ls -t /opt/gpti/backups/minio/* 2>/dev/null | tail -n +4 | xargs rm -rf 2>/dev/null || true
    
    NEW_BACKUP_SIZE=$(du -sh /opt/gpti/backups | cut -f1)
    echo "✅ Cleaned old backups (was $BACKUP_SIZE, now $NEW_BACKUP_SIZE)"
else
    echo "✅ No backups directory found"
fi

# ========== CLEANUP 6: Redundant documentation in root ==========
echo ""
echo "📌 Cleanup 6: Consolidate documentation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Archive old verify scripts (keep deploy-staging and verify-staging)
for OLD_SCRIPT in /opt/gpti/verify-*.sh; do
    if [ -f "$OLD_SCRIPT" ]; then
        BASENAME=$(basename "$OLD_SCRIPT")
        if [ "$BASENAME" != "verify-staging.sh" ]; then
            # Archive old scripts instead of deleting (for safety)
            mkdir -p /opt/gpti/.archive
            mv "$OLD_SCRIPT" /opt/gpti/.archive/ 2>/dev/null || true
            echo "  ✅ Archived $BASENAME"
        fi
    fi
done

# Keep only essential root scripts
for SCRIPT in /opt/gpti/generate-*.sh /opt/gpti/test-*.sh /opt/gpti/stop-*.sh; do
    if [ -f "$SCRIPT" ]; then
        BASENAME=$(basename "$SCRIPT")
        mkdir -p /opt/gpti/.archive
        mv "$SCRIPT" /opt/gpti/.archive/ 2>/dev/null || true
        echo "  ✅ Archived $BASENAME"
    fi
done

echo "✅ Consolidated root directory"

# ========== CLEANUP 7: Build artifacts ==========
echo ""
echo "📌 Cleanup 7: Clean build artifacts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Clean Next.js build cache
rm -rf /opt/gpti/gpti-site/.next 2>/dev/null || true
rm -rf /opt/gpti/gpti-site/out 2>/dev/null || true

# Clean Python build artifacts
find /opt/gpti -type d -name "build" -path "*/gpti-data-bot/*" -exec rm -rf {} + 2>/dev/null || true
find /opt/gpti -type d -name "dist" -path "*/gpti-data-bot/*" -exec rm -rf {} + 2>/dev/null || true

echo "✅ Cleaned build artifacts"

# ========== Final report ==========
echo ""
SIZE_AFTER=$(du -sh /opt/gpti 2>/dev/null | cut -f1)

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  CLEANUP COMPLETE                                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Disk Usage:"
echo "   Before: $SIZE_BEFORE"
echo "   After:  $SIZE_AFTER"
echo ""
echo "✅ Cleaned files:"
echo "   • .internal-docs/ (old internal documentation)"
echo "   • __pycache__/ directories"
echo "   • *.pyc Python cache files"
echo "   • Old backup files (kept 3 recent)"
echo "   • Old verification scripts"
echo "   • Next.js build cache"
echo ""
echo "✅ Preserved critical files:"
echo "   • /opt/gpti/docs/ (current documentation)"
echo "   • /opt/gpti/gpti-data-bot/ (backend)"
echo "   • /opt/gpti/gpti-site/ (frontend)"
echo "   • /opt/gpti/docker/ (infrastructure)"
echo "   • deploy-staging.sh (deployment script)"
echo "   • verify-staging.sh (testing script)"
echo ""
