# 🗺️ GPTI Infrastructure Map

## État Actuel (19 Feb 2026)

### 📊 Données

**230 total firms** dans snapshot_id=41:
- ✅ **20 firms** avec données (9%) - NA rate 42-57%
- ⚠️ **210 firms** sans données (91%) - NA rate 100%

**Scores:**
- Moyenne réelle: **41.91** (arrondi à 42 sur UI)
- Pass Rate: **0%** (toutes firms en verdict='review')
- NA Rate moyen: **96%** (normal - crawl en cours)

---

## 🐳 Docker & Services

### Conteneurs Actifs

```
┌─────────────────────────────────────────────────────────┐
│  Container Name          │ Port    │ Description         │
├─────────────────────────────────────────────────────────┤
│  gpti-postgres           │ 5432    │ Production DB       │
│  infra-postgres-1        │ 5432    │ (duplicate)         │
│                          │         │                     │
│  gpti-minio              │ 9000    │ MinIO Storage       │
│  infra-minio-1           │ 9000    │ (duplicate)         │
│                          │ 9002    │ Alternative port    │
│                          │         │                     │
│  gpti-prefect-server     │ 4200    │ Prefect Server      │
│  infra-prefect-server-1  │ 4200    │ (duplicate)         │
│                          │         │                     │
│  gpti-prefect-worker     │ -       │ Prefect Worker      │
│  infra-prefect-worker-1  │ -       │ (duplicate)         │
│                          │         │                     │
│  gpti-site (systemd)     │ 3000    │ Next.js Production  │
└─────────────────────────────────────────────────────────┘
```

**Note:** Il y a des doublons de conteneurs (`gpti-*` et `infra-*`) lancés depuis différents docker-compose. Tous deux fonctionnent mais créent de la redondance.

### Docker Compose Locations

```
/opt/gpti/gpti-data-bot/infra/docker-compose.yml  ← PRINCIPAL
/opt/gpti/docker/docker-compose.yml               ← Ancien (legacy)
```

**Recommandation:** Utiliser uniquement `/opt/gpti/gpti-data-bot/infra/docker-compose.yml`

---

## 🗄️ PostgreSQL

### Instances Actives

| Port | Password | Firms | Usage | Status |
|------|----------|-------|-------|--------|
| **5432** | `2e8c1b61927c490738c23e5e7976f69790a1b2bd4c75b1c8` | **230** | ✅ **PRODUCTION** | Active |
| 5433 | `superpassword` | 193 | ❌ Ancien | Deprecated |
| 5434 | différent | 141 | ❌ Ancien | Deprecated |

### Connection URLs par Service

**✅ PRODUCTION (à utiliser):**
```bash
# Next.js Site (.env.local)
DATABASE_URL=postgresql://gpti:2e8c1b61927c490738c23e5e7976f69790a1b2bd4c75b1c8@localhost:5432/gpti

# Data Bot (infra/.env)
DATABASE_URL=postgresql://gpti:2e8c1b61927c490738c23e5e7976f69790a1b2bd4c75b1c8@postgres:5432/gpti

# Scripts Python
postgresql://gpti:2e8c1b61927c490738c23e5e7976f69790a1b2bd4c75b1c8@localhost:5432/gpti
```

### Tables Principales

```sql
firms                -- 230 firms (metadata)
snapshot_scores      -- snapshot_id=41 avec 230 records
agent_c_audit        -- verdicts (pass/review)
validation_metrics   -- System health
evidence             -- Crawl evidence
evidence_collection  -- VIEW → evidence
```

---

## 💾 MinIO Storage

### Instances Actives

| Endpoint | Usage | Status |
|----------|-------|--------|
| `localhost:9000` | MinIO API | ✅ Active |
| `localhost:9002` | MinIO (alt port) | ✅ Active |
| `data.gtixt.com` | Public CDN | 🔒 Production |

### Buckets Structure

```
gpti-snapshots/
├── universe_v0.1_public/
│   └── _public/
│       ├── gtixt_snapshot_20260219T003928.json  ← Current (230 firms)
│       └── latest.json
└── archives/
    └── [older snapshots]
```

### MinIO Access

```bash
# Alias configuré 
mc alias set gpti http://localhost:9002 [ACCESS_KEY] [SECRET_KEY]

# Upload snapshot
mc cp snapshot.json gpti/gpti-snapshots/universe_v0.1_public/_public/

# List objects
mc ls gpti/gpti-snapshots/universe_v0.1_public/_public/
```

---

## 🌐 Next.js Site (gpti-site)

### Service

```bash
# SystemD service
systemctl status gpti-site
systemctl restart gpti-site

# Logs
journalctl -u gpti-site -f
```

### Configuration Files Priority

```
1. .env.production.local     ← IGNORED (Next.js ne lit pas ce fichier)
2. .env.local                ← ✅ UTILISÉ en production
3. .env.example              ← Template seulement
```

### Current Config (.env.local)

```bash
# ✅ PRODUCTION - Configuration correcte
DATABASE_URL=postgresql://gpti:2e8c1b61927c490738c23e5e7976f69790a1b2bd4c75b1c8@localhost:5432/gpti

# Snapshots served from local /public folder
NEXT_PUBLIC_LATEST_POINTER_URL=/snapshots/latest.json
NEXT_PUBLIC_MINIO_PUBLIC_ROOT=/snapshots/
NEXT_PUBLIC_SNAPSHOT_BASE_URL=/snapshots

# API verification
VERIFICATION_API_URL=http://localhost:3101

# Slack
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
```

### Public Snapshots

```
/opt/gpti/gpti-site/public/snapshots/
├── gtixt_snapshot_20260219T003928.json  ← 230 firms
├── gtixt_snapshot_20260219_002040.json  ← 193 firms (old)
└── latest.json                          ← Points to 003928
```

**URLs:**
- Local: `http://localhost:3000/snapshots/latest.json`
- Public: `https://www.gtixt.com/snapshots/latest.json`

---

## 🤖 Data Bot & Prefect

### Configuration (.env dans infra/)

```bash
# PostgreSQL (from container)
DATABASE_URL=postgresql://gpti:2e8c1b61927c490738c23e5e7976f69790a1b2bd4c75b1c8@postgres:5432/gpti

# MinIO (from container)
MINIO_ENDPOINT=http://minio:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin

# Prefect
PREFECT_API_URL=http://prefect-server:4200/api
```

### Bot Commands

```bash
# Via docker compose run (bot ne tourne pas en daemon)
cd /opt/gpti/gpti-data-bot/infra

# Crawl 50 firms
sudo docker compose run --rm bot python -m gpti_bot crawl 50

# Run agents
sudo docker compose run --rm bot python -m gpti_bot run-agents

# Score snapshot
sudo docker compose run --rm bot python -m gpti_bot score-snapshot

# Export public
sudo docker compose run --rm bot python -m gpti_bot export-snapshot --public
```

### Prefect Server

```bash
# Web UI
http://localhost:4200

# Health check
curl http://localhost:4200/api/health

# Deployments
prefect deployment ls
```

---

## 🔄 Automation

### Cron Schedule (PRODUCTION)

```cron
# Master automation - toutes les 6 heures
0 */6 * * * /opt/gpti/gpti-production-master.sh run >> /var/log/gpti/production-cron.log 2>&1
```

**Anciens crons supprimés:**
- ❌ `/opt/gpti/scripts/run-gpti-pipeline.sh`
- ❌ `/opt/gpti/auto-sync-snapshots.sh`
- ❌ `/opt/gpti/run-enrichment-agent.sh`

### Master Script

```bash
# Location
/opt/gpti/gpti-production-master.sh

# Commands
bash gpti-production-master.sh status   # System status
bash gpti-production-master.sh run      # Run pipeline
bash gpti-production-master.sh logs     # View logs
bash gpti-production-master.sh test     # Health check
bash gpti-production-master.sh deploy   # Deploy automation

# Logs
/var/log/gpti/production-master.log
/var/log/gpti/crawl.log
/var/log/gpti/agents.log
/var/log/gpti/scoring.log
```

### Configuration

```bash
PRODUCTION_MODE="intelligent"
AGENT_C_MODE="relaxed"
PUBLIC_VERDICTS="pass,review"
CRAWL_LIMIT=50
SCHEDULE_INTERVAL="6h"
ENABLE_AUTO_RECOVERY="true"
ENABLE_SLACK_ALERTS="true"
```

---

## 📁 Fichiers .env - Résumé

### ✅ Fichiers Utilisés en Production

```
/opt/gpti/gpti-site/.env.local
  → Next.js site configuration
  → DATABASE_URL: localhost:5432
  → Snapshots: /snapshots/ (local)

/opt/gpti/gpti-data-bot/infra/.env.local
  → Docker bot configuration
  → DATABASE_URL: postgres:5432 (container name)
  → MinIO: http://minio:9000 (container name)

/opt/gpti/gpti-production-master.sh
  → Variables hardcodées dans le script
  → Agent C mode, verdicts, crawl limit
```

### ❌ Fichiers Non Utilisés (à ignorer)

```
/opt/gpti/gpti-site/.env.production.local
  → Next.js n'utilise pas ce fichier en prod

/opt/gpti/docker/.env
  → Ancien docker-compose (legacy)

/opt/gpti/gpti-data-bot/.env
  → Remplacé par infra/.env.local
```

---

## 🔍 Troubleshooting

### Problème: "Wrong database port"

**Symptôme:** Site affiche anciennes données (193 firms au lieu de 230)

**Cause:** `.env.local` pointait sur port 5433 (ancien DB)

**Solution:**
```bash
# Éditer /opt/gpti/gpti-site/.env.local
DATABASE_URL=postgresql://gpti:2e8c1b61927c490738c23e5e7976f69790a1b2bd4c75b1c8@localhost:5432/gpti

# Redémarrer
systemctl restart gpti-site
```

### Problème: "Table validation_metrics not found"

**Cause:** Site pointait sur ancien PostgreSQL sans la table

**Solution:** Créer vue + correction DATABASE_URL (déjà fait)

### Problème: "96% NA rate trop élevé"

**Cause:** 210 sur 230 firms pas encore crawlées

**Solution:** Lancer plus de crawls
```bash
bash gpti-production-master.sh run
# ou
cd /opt/gpti/gpti-data-bot/infra
sudo docker compose run --rm bot python -m gpti_bot crawl 100
```

### Problème: "Scores différents homepage vs rankings"

**Cause:** Arrondi (41.91 → 42)

**Status:** ✅ Normal, pas de problème réel

### Problème: "Conteneurs en double"

**Cause:** `docker-compose.yml` lancé depuis 2 endroits

**Solution temporaire:** Les deux fonctionnent (redondant mais OK)

**Solution permanente:** Arrêter un des deux:
```bash
# Option 1: Garder infra-*
cd /opt/gpti/docker
sudo docker compose down

# Option 2: Garder gpti-*
cd /opt/gpti/gpti-data-bot/infra
sudo docker compose down
# Puis utiliser les conteneurs gpti-*
```

---

## ✅ Checklist Configuration Correcte

```
✅ Next.js DATABASE_URL → localhost:5432
✅ Bot DATABASE_URL → postgres:5432 (container)
✅ Bot MINIO_ENDPOINT → http://minio:9000
✅ Snapshot latest.json → pointe sur 230 firms
✅ Public snapshots copiés dans /public/snapshots/
✅ Cron master activé (6h)
✅ Anciens crons supprimés
✅ Service gpti-site running
✅ Conteneurs postgres/minio/prefect running
```

---

## 🎯 Prochaines Actions Recommandées

### 1. Enrichir les Données (Priorité Haute)

**Actuellement:** 210/230 firms ont NA=100% (pas de données)

**Action:**
```bash
# Crawler plus de firms (100 par batch)
cd /opt/gpti/gpti-data-bot/infra
sudo docker compose run --rm bot python -m gpti_bot crawl 100

# Re-scorer après chaque crawl
sudo docker compose run --rm bot python -m gpti_bot score-snapshot

# Re-exporter snapshot
bash /opt/gpti/gpti-production-master.sh run
```

**Objectif:** Atteindre <50% NA rate

### 2. Nettoyer les Doublons Docker (Priorité Moyenne)

```bash
# Décider quel docker-compose garder
# Recommandé: garder infra/docker-compose.yml

# Arrêter l'autre
cd /opt/gpti/docker
sudo docker compose down

# Vérifier
sudo docker ps | grep -E "postgres|minio|prefect"
```

### 3. Centraliser les .env (Priorité Basse)

**Créer un document maître:**
```bash
/opt/gpti/CONFIG.env  ← Variables centrales
```

Puis sourcer dans tous les scripts.

---

## 📚 Documentation Associée

- [PRODUCTION_AUTOMATION.md](PRODUCTION_AUTOMATION.md) - Automation system
- [DB_ADDENDUM.md](DB_ADDENDUM.md) - Database schema
- Master script: `/opt/gpti/gpti-production-master.sh`
- Dashboard: https://www.gtixt.com/agents-dashboard

---

**Dernière mise à jour:** 19 février 2026  
**Maintainer:** GPTI Production Team
