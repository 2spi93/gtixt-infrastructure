# 🎯 GPTI Documentation Index

**Latest Status**: 🟢 **PRODUCTION READY** (Feb 18, 2026)

## 📌 START HERE (Quick Links)

| Document | Purpose | Read Time |
|----------|---------|-----------|
| [**COMPLETE_AUDIT_2026-02-18.md**](COMPLETE_AUDIT_2026-02-18.md) | **✨ NEW - Unified, Complete Audit** | 15 min |
| [QUICKSTART.md](QUICKSTART.md) | 5-minute deployment guide | 5 min |
| [DEPLOYMENT_PLAN.md](DEPLOYMENT_PLAN.md) | Step-by-step procedures | 10 min |
| [WEB_SEARCH_SERVICE.md](WEB_SEARCH_SERVICE.md) | Search engine architecture | 8 min |
| [COMPLETION_SUMMARY.md](COMPLETION_SUMMARY.md) | Project delivery summary | 10 min |

## 📊 REFERENCE SECTIONS

- **audits/** (old audit findings - see COMPLETE_AUDIT for unified version)
- **data-flow/** (data flow diagrams and verification)
- **testing/** (quick tests and test reports)
- **deployment/** (infra, VPS, credentials setup)
- **visuals/** (UI changes and navigation)
- **reports/** (phase progress notes)
- **archive/** (original snapshots - preserved for reference)

## 🔧 DEPLOYMENT SCRIPTS

Located in `/opt/gpti/`:
- `deploy-staging.sh` - Deploy to staging environment
- `verify-staging.sh` - Run comprehensive tests
- `fix-issues.sh` - Fix remaining issues
- `cleanup.sh` - Intelligent disk cleanup
- `health-check-staging.sh` - Quick health check

## 📁 DATABASE

**Canonical DB name:** `gpti_data`  
(If you see gpti_db, gpti_bot, or gpti_sanctions in older docs, they mean gpti_data)

## App-specific docs
- gpti-site/docs/
- gpti-data-bot/docs/
