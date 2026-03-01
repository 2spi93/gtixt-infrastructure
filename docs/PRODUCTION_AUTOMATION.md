# 🤖 GPTI Production Automation System

## Vue d'ensemble

Système d'automatisation unifié pour la production GPTI avec agents intelligents autonomes.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│         GPTI Production Master Orchestrator             │
│         (gpti-production-master.sh)                     │
└───────────────────┬─────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
  ┌─────▼──────┐         ┌─────▼──────┐
  │  Pipeline  │         │   Cron     │
  │   Manual   │         │  Schedule  │
  └─────┬──────┘         └─────┬──────┘
        │                      │
        │   Every 6h (default) │
        └──────────┬───────────┘
                   │
        ┌──────────▼──────────┐
        │  Production Flow    │
        └──────────┬──────────┘
                   │
     ┌─────────────┼─────────────┐
     │             │             │
  ┌──▼───┐    ┌───▼────┐   ┌───▼────┐
  │Crawl │    │ Agents │   │ Score  │
  └──┬───┘    └───┬────┘   └───┬────┘
     │            │            │
     └────────────┼────────────┘
                  │
          ┌───────▼────────┐
          │  Agent C Gate  │
          │  (Oversight)   │
          └───────┬────────┘
                  │
          ┌───────▼────────┐
          │     Export     │
          │   Snapshot     │
          └───────┬────────┘
                  │
          ┌───────▼────────┐
          │  Deploy MinIO  │
          │  + Production  │
          └────────────────┘
```

## Composants

### 1. Pipeline de Production
**Séquence automatique:**
1. **Crawl & Discovery** - Découverte de nouvelles firms
2. **Agents Execution** - RVI, REM, SSS, etc.
3. **Score Calculation** - Calcul des scores 0-100
4. **Oversight Gate (Agent C)** - Filtrage qualité
5. **Snapshot Export** - JSON avec firms éligibles
6. **Validation** - Vérification intégrité
7. **Deployment** - MinIO + Site public

### 2. Agents Intelligents

#### **Agent C (Oversight Gate)**
**Mode:** `relaxed` (recommandé production)
- `soft`: Accepte tout (testing)
- `relaxed`: Filtre erreurs techniques
- `strict`: Filtre strict qualité

**Règles:**
```python
FIRM_NA_RATE_THRESHOLD = 0.40  # Max 40% NA
verdict = "pass" if no_technical_errors else "review"
```

**Verdicts publics:**
- `pass,review` = Exporte firms avec pass OU review (recommandé)
- `pass` = Seulement firms parfaites (strict)

#### **Agents de Collecte**
- **RVI** (Registry Verification) - Vérification régulateurs
- **REM** (Rules Extraction) - Extraction règles
- **SSS** (Sanctions Screening) - Screening sanctions
- **IRS** (Intelligent Routing) - Routing intelligent
- **FRP** (Firm Reputation) - Réputation
- **MIS** (Market Intelligence) - Intelligence marché
- **IIP** (Industry Insight) - Insights secteur

### 3. Configuration Production

**Variables d'environnement** (dans script):
```bash
PRODUCTION_MODE="intelligent"  # intelligent | manual | debug
AGENT_C_MODE="relaxed"         # soft | relaxed | strict  
PUBLIC_VERDICTS="pass,review"  # pass,review | pass
CRAWL_LIMIT=50                 # Firms par run
SCHEDULE_INTERVAL="6h"         # 6h | 12h | 24h
ENABLE_AUTO_RECOVERY="true"    # Auto-fix errors
ENABLE_SLACK_ALERTS="true"     # Notifications
RETENTION_DAYS=90              # Retention snapshots
```

### 4. Schedule Automatique

**Cron actifs:**
```cron
0 */6 * * *  Production pipeline (toutes les 6h)
0 2 * * *    Enrichment agent (2h AM daily)
```

**Modifier le schedule:**
```bash
# Éditer le script
nano /opt/gpti/gpti-production-master.sh
# Changer SCHEDULE_INTERVAL="6h" → "12h" ou "24h"

# Redéployer
bash /opt/gpti/gpti-production-master.sh deploy
```

## Utilisation

### Déploiement Initial
```bash
cd /opt/gpti
bash gpti-production-master.sh deploy
```

### Lancer Manuellement
```bash
bash gpti-production-master.sh run
```

### Status Système
```bash
bash gpti-production-master.sh status
```

### Logs
```bash
# 50 dernières lignes
bash gpti-production-master.sh logs

# 200 dernières lignes
bash gpti-production-master.sh logs 200

# Tail en temps réel
tail -f /var/log/gpti/production-master.log
```

### Test Santé
```bash
bash gpti-production-master.sh test
```

## Interface Agents (Dashboard)

**URL:** https://www.gtixt.com/agents-dashboard

**Features:**
- ✅ Status temps réel des 7 agents
- 📊 Métriques de performance
- 🔍 Dernière exécution
- ⚡ Temps d'exécution
- 🎯 Tests pass/fail
- 📦 Preuves collectées

**API Endpoint:**
```bash
curl https://www.gtixt.com/api/agents/health
```

## Communication avec les Agents

### 1. Via Dashboard Web
Accédez à: https://www.gtixt.com/agents-dashboard

### 2. Via Logs
```bash
# Logs master
tail -f /var/log/gpti/production-master.log

# Logs spécifiques
tail -f /var/log/gpti/crawl.log
tail -f /var/log/gpti/agents.log
tail -f /var/log/gpti/scoring.log
tail -f /var/log/gpti/validation.log
```

### 3. Via Slack (si configuré)
Notifications automatiques envoyées à:
- Pipeline start/completion
- Errors détectés
- Auto-recovery actions

### 4. Via État JSON
```bash
# Lire l'état actuel
cat /tmp/gpti-production-state.json | jq .

# Exemple de sortie:
{
  "last_run_start": "2026-02-19T01:00:00+00:00",
  "last_run_end": "2026-02-19T01:15:23+00:00",
  "last_run_duration": "923",
  "last_run_errors": "0",
  "pipeline_status": "completed",
  "current_step": "deployment",
  "crawl_duration": "120",
  "agents_duration": "380",
  "scoring_duration": "45"
}
```

### 5. Via Database Queries
```bash
# Firms count
psql postgresql://gpti:PASSWORD@localhost:5432/gpti \
  -c "SELECT COUNT(*) FROM firms"

# Recent snapshots
psql postgresql://gpti:PASSWORD@localhost:5432/gpti \
  -c "SELECT snapshot_id, COUNT(*) as firms, created_at 
      FROM snapshot_scores 
      WHERE snapshot_id = (SELECT MAX(snapshot_id) FROM snapshot_scores)
      GROUP BY snapshot_id, created_at"

# Agent C verdicts
psql postgresql://gpti:PASSWORD@localhost:5432/gpti \
  -c "SELECT verdict, COUNT(*) 
      FROM agent_c_audit 
      WHERE snapshot_key='universe_v0.1' 
      GROUP BY verdict"
```

## Gestion des Erreurs

### Auto-Recovery
Activé par défaut (`ENABLE_AUTO_RECOVERY=true`)

**Actions automatiques:**
- Redémarrage conteneurs Docker si down
- Retry failed steps (1x)
- Nettoyage locks stales
- Rollback si erreur critique

### Monitoring
```bash
# Vérifier santé système
bash gpti-production-master.sh test

# Vérifier conteneurs
sudo docker ps | grep -E "postgres|minio|prefect|bot"

# Vérifier PostgreSQL
psql postgresql://gpti:PASSWORD@localhost:5432/gpti -c "SELECT 1"

# Vérifier MinIO
curl http://localhost:9002/minio/health/live
```

## Résolution Problèmes

### Pipeline ne démarre pas
```bash
# Vérifier lock
rm -f /tmp/gpti-production.lock

# Vérifier conteneurs
sudo docker compose -f /opt/gpti/gpti-data-bot/infra/docker-compose.yml up -d

# Relancer
bash gpti-production-master.sh run
```

### 0 Firms dans snapshot
**Cause:** Agent C filtre toutes les firms (verdict='review' mais PUBLIC_VERDICTS='pass')

**Solution:**
```bash
# Option 1: Accepter pass ET review
nano /opt/gpti/gpti-production-master.sh
# Changer PUBLIC_VERDICTS="pass,review"

# Option 2: Passer Agent C en mode soft
# Changer AGENT_C_MODE="soft"

# Redéployer
bash gpti-production-master.sh deploy
bash gpti-production-master.sh run
```

### Scores null
Vérifier que snapshot utilise `score_0_100` et non `score`:
```bash
jq '.records[0] | keys' /opt/gpti/tmp/gtixt_snapshot_*.json
# Doit contenir "score_0_100"
```

### Pass Rate 0%
**Normal avec Agent C mode relaxed** - Toutes firms en 'review' car erreurs techniques (crawl errors, missing data).

**Solutions:**
1. Améliorer qualité data (plus de crawls)
2. Mode soft: `AGENT_C_MODE="soft"`
3. Accepter review: `PUBLIC_VERDICTS="pass,review"`

## Fichiers Importants

```
/opt/gpti/
├── gpti-production-master.sh         # 🎯 Script principal
├── tmp/
│   ├── export_scored_snapshot.py    # Génération snapshots
│   ├── gtixt_snapshot_*.json        # Snapshots générés
│   └── latest.json                  # Pointer
├── gpti-data-bot/
│   ├── flows/production_flow.py     # Prefect flow
│   └── src/gpti_bot/
│       ├── cli.py                   # CLI commands
│       └── agents/gate_agent_c.py   # Agent C logic
└── var/log/gpti/
    ├── production-master.log        # Logs principal
    ├── crawl.log
    ├── agents.log
    ├── scoring.log
    └── validation.log
```

## Métriques Production

**Objectifs cibles:**
- ✅ Pipeline completion: < 20 minutes
- ✅ Uptime: > 99%
- ✅ Errors: < 5% des runs
- ✅ Auto-recovery success: > 90%
- ✅ Data freshness: < 6 heures

**Monitoring:**
```bash
# Stats dernières 24h
grep "PIPELINE SUMMARY" /var/log/gpti/production-master.log | tail -10

# Taux de succès
grep "SUCCESS" /var/log/gpti/production-master.log | wc -l

# Taux d'erreur
grep "WITH ERRORS" /var/log/gpti/production-master.log | wc -l
```

## Support

**Documentation:**
- [Production Flow](../gpti-data-bot/flows/production_flow.py)
- [Agent C Logic](../gpti-data-bot/src/gpti_bot/agents/gate_agent_c.py)
- [Export Snapshot](../gpti-data-bot/src/gpti_bot/export_snapshot.py)

**Dashboard:**
- Agents: https://www.gtixt.com/agents-dashboard
- Rankings: https://www.gtixt.com/rankings

**Logs en temps réel:**
```bash
tail -f /var/log/gpti/production-master.log
```

## Évolution Future

**Roadmap:**
- [ ] Machine Learning pour verdicts Agent C
- [ ] A/B testing de configurations
- [ ] Prédiction de qualité avant crawl
- [ ] Auto-tuning de CRAWL_LIMIT
- [ ] Integration avec monitoring externe (Datadog, etc.)
- [ ] API GraphQL pour communication agents
