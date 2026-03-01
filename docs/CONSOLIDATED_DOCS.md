# GTIXT - Documentation Consolidée
**Date:** 2026-02-20
**Système:** Pipeline d'indexation prop firms avec scoring automatisé

---

## 📋 ARCHITECTURE SYSTÈME

### Stack Technique
- **Frontend:** Next.js 16.1.6 (PM2, port 3000)
- **Backend:** Python 3.10 (FastAPI-style)
- **Database:** PostgreSQL 16 (port 5434)
- **Storage:** MinIO (port 9002)
- **LLM:** Ollama (qwen2.5:1.5b, localhost:11434)
- **Crawling:** Proxy-enabled web scraping

### Services Actifs
```
- gpti-site (Next.js, PM2)
- PostgreSQL (systemd, port 5434)
- MinIO (systemd, port 9002)
- Ollama (systemd, port 11434)
- Prefect (agents + server)
```

---

## 🔄 PIPELINE AUTONOMOUS (6 Phases)

1. **Discovery** - Agent 2: Market Intelligence
2. **Enrichment** - Crawl + Extraction LLM
3. **Scoring** - Scoring rapide (option-b)
4. **Validation** - Agent C audit
5. **Publication** - Export MinIO + snapshot JSON
6. **Monitoring** - Slack notifications

### Commandes Clés
```bash
# Pipeline complet
cd /opt/gpti/gpti-data-bot
python3 scripts/autonomous_pipeline.py --crawl-limit 30

# Scoring uniquement (skip crawl)
python3 scripts/option-b-scoring.py

# Extraction depuis evidences existantes
python3 -c "from gpti_bot.extract_from_evidence import run_extract_from_evidence_for_firm; print(run_extract_from_evidence_for_firm('ftmocom'))"
```

---

## 📊 DATA FLOW

### 1. Acquisition
- Web crawl → HTML/PDF → MinIO (gpti-raw)
- External sources → Fallback URLs
- Evidence table (firm_id, key, raw_object_path)

### 2. Extraction
- LLM (Ollama) → JSON structured
- Regex fallback
- Datapoints table (firm_id, key, value_json)

### 3. Scoring
- 5 pillar model: Risk, Transparency, Payout, Legal, Reputation
- Métriques: payout_frequency, max_drawdown, daily_drawdown
- NA Rate tracking

### 4. Publication
- Snapshot JSON → MinIO (gpti-snapshots)
- snapshot_scores table
- Frontend polling toutes les 5 min

---

## 🐛 PROBLÈMES RÉSOLUS (2026-02-20)

### 1. Ollama Configuration
**Issue:** LLM timeout, mauvais endpoint
**Fix:**
- Port: `11435` → `11434`
- Host: `host.docker.internal` → `localhost`
- Timeout: `60s` → `300s`
- Modèle: `llama3.1:latest` (8B) → `qwen2.5:1.5b`

**Fichiers modifiés:**
- `/opt/gpti/docker/.env` (lignes 18-21)
- `/opt/gpti/gpti-data-bot/src/gpti_bot/llm/ollama_client.py` (ligne 13-15)

### 2. External URLs 404
**Issue:** Patterns incorrects pour thetrustedprop.com
**Fix:** Ajout `/prop-firms/` prefix dans `external_sources.py`

### 3. Domain Slug Broken
**Issue:** `_strip_tld("www.ftmo.com")` retournait "www"
**Fix:** Amélioration parsing domaine dans `external_sources.py`

---

## 📈 MÉTRIQUES ACTUELLES

**Snapshot #49 (2026-02-20 13:11):**
- Total firms: 157
- NA Rate moyen: 84.9%
- Firms complètes (NA < 30%): 0
- Score moyen: 46.0/100
- Meilleure firm: blueguardiancom (25% NA)

**Espace Disque:**
- Total: 73GB / 54GB utilisés (75%)
- Backups: 1.2GB (réduit de 3.4GB)
- gpti-site: 718MB
- gpti-data-bot: 97MB

---

## ✅ CHECKLIST MAINTENANCE

### Quotidien
- [ ] Vérifier Ollama runner (pas stuck)
- [ ] Check logs pipeline: `/opt/gpti/tmp/pipeline*.log`
- [ ] Monitoring espace disque: `df -h /`

### Hebdomadaire
- [ ] Supprimer anciens backups MinIO (garder 3)
- [ ] Nettoyer `/opt/gpti/tmp/` (snapshots >7j)
- [ ] Vérifier NA Rate snapshot latest

### Mensuel
- [ ] Backup PostgreSQL complet
- [ ] Audit data coverage
- [ ] Review duplicates/incohérences

---

## 🚀 DÉPLOIEMENT PRODUCTION

### Environnement
```bash
# Variables critiques
DATABASE_URL=postgresql://gpti:superpassword@localhost:5434/gpti
MINIO_ENDPOINT=localhost:9002
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_DEFAULT_MODEL=qwen2.5:1.5b
GPTI_FAST_MODE=1
```

### Services à Redémarrer
```bash
# Ollama (si stuck)
sudo systemctl restart ollama

# Frontend
pm2 restart gpti-site

# Pipeline (background)
nohup python3 scripts/autonomous_pipeline.py --crawl-limit 30 > /opt/gpti/tmp/pipeline.log 2>&1 &
```

---

## 📚 RÉFÉRENCES ARCHIVÉES

Les fichiers suivants sont **obsolètes** et consolidés ici:
- `audits/IMPLEMENTATION_GUIDE.md` (1196 lignes)
- `audits/COMPREHENSIVE_AUDIT.md` (1028 lignes)
- `deployment/ARCHITECTURE_COMPLETE_VPS.md` (511 lignes)
- `COMPLETE_AUDIT_2026-02-18.md` (440 lignes)
- `DEPLOYMENT_AUDIT.md` (403 lignes)

**Archive complète:** `/opt/gpti/docs/archive/`

---

**Dernière mise à jour:** 2026-02-20 13:20 UTC
**Maintaineur:** Infrastructure GTIXT
