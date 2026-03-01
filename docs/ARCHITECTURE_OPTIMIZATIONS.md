# 🏗️ ARCHITECTURE OPTIMIZATIONS — GTIXT Pipeline

**Date**: 2025-02-20  
**Statut**: Implémentation progressive (ne casse pas le processus actuel)  
**NA Rate actuel**: 84.55% (objectif <50%)

---

## 📊 ANALYSE ACTUELLE

### ✅ Ce qui fonctionne
- **Ollama phi (1.6GB)**: Extraction stable
- **3 workers**: Stable (pas de freeze Ollama)
- **JSON retry logic**: 3-step fallback (parse → fix → minimal)
- **Async batch extraction**: ThreadPoolExecutor performant
- **Timeout 600s**: Suffisant pour phi / 1b

### ❌ Problèmes identifiés

| Problème | Impact | Priorité |
|----------|--------|----------|
| **Prompts trop longs** (9000 chars rules, 12000 chars pricing) | Latence élevée, RAM Ollama | 🔴 HIGH |
| **Pas de cache LLM** | Même evidence = même appel LLM | 🔴 HIGH |
| **20/157 firms extraits** | NA rate toujours 84.55% | 🔴 HIGH |
| **Workers=3 lent** | Batch 20 firms = 8-12 min (objectif 3-6 min) | 🟡 MEDIUM |
| **Ollama freeze sous charge** | Besoin 3 restart pendant batch | 🟡 MEDIUM |
| **Tradeoff taille/qualite modele** | Qualite vs RAM disponible | 🟢 LOW |

---

## 🎯 OPTIMISATIONS INTELLIGENTES

### 1. **PROMPT SIZE REDUCTION** (Gros gain ⚡)

**Problème**: 
- `rules_extractor.py`: chunks de 9000 chars → 4 passes max
- `pricing_extractor.py`: text[:12000] → 1 pass
- Prompts longs = latence élevée + RAM + timeout risques

**Solution**:
```python
# rules_extractor.py ligne 116
chunks = _chunk(text, max_chars=6000)  # 9000 → 6000 (-33%)

# pricing_extractor.py ligne 86
+ text[:8000]  # 12000 → 8000 (-33%)

# extract_from_evidence.py ligne 169
if not text or len(text) < 200:  # 400 → 200 (moins strict)
```

**Impact estimé**:
- ✅ Latence LLM réduite ~30-40%
- ✅ RAM Ollama réduite ~25%
- ✅ Batch 20 firms: 8-12 min → **5-7 min**
- ⚠️ Risque: Qualité extraction légèrement réduite (compense avec multi-pass)

**Validation**:
```bash
# Test sur 3 firms pilotes
cd /opt/gpti/gpti-data-bot
python3 scripts/test_prompt_reduction.py --firms topstepcom,ftmocom,e8marketscom
```

---

### 2. **LLM EVIDENCE CACHE** (Énorme gain 🚀)

**Problème**: 
- Même evidence SHA256 = même appel LLM répété
- Exemple: `topstepcom` rules_html crawlé 3x → 3 appels LLM identiques
- Aucune persistance des résultats LLM entre runs

**Solution**:
```python
# Créer nouveau fichier: src/gpti_bot/llm/evidence_cache.py
from pathlib import Path
import json
import hashlib

CACHE_DIR = Path("/opt/gpti/tmp/llm_evidence_cache")
CACHE_DIR.mkdir(parents=True, exist_ok=True)

def _cache_key(evidence_sha256: str, model: str, extraction_type: str) -> str:
    """
    evidence_sha256: SHA256 de l'evidence raw
    model: phi
    extraction_type: rules | pricing
    """
    composite = f"{evidence_sha256}:{model}:{extraction_type}"
    return hashlib.sha256(composite.encode()).hexdigest()[:16]

def get_cached_extraction(evidence_sha256: str, model: str, extraction_type: str):
    key = _cache_key(evidence_sha256, model, extraction_type)
    cache_file = CACHE_DIR / f"{key}.json"
    if cache_file.exists():
        try:
            with open(cache_file) as f:
                return json.load(f)
        except Exception:
            return None
    return None

def save_extraction_cache(evidence_sha256: str, model: str, extraction_type: str, result: dict):
    key = _cache_key(evidence_sha256, model, extraction_type)
    cache_file = CACHE_DIR / f"{key}.json"
    with open(cache_file, "w") as f:
        json.dump(result, f, indent=2)
```

**Intégration dans `extract_from_evidence.py`**:
```python
# Ligne 172 (avant extract_rules)
from gpti_bot.llm.evidence_cache import get_cached_extraction, save_extraction_cache

model = os.getenv("OLLAMA_DEFAULT_MODEL", "phi")
cached = get_cached_extraction(row["sha256"], model, "rules")
if cached:
    rules = cached
else:
    rules = extract_rules(text)
    save_extraction_cache(row["sha256"], model, "rules", rules)
```

**Impact estimé**:
- ✅ Cache hit rate ~40-60% (evidences récurrentes)
- ✅ Batch 20 firms: 8-12 min → **3-5 min** (avec cache chaud)
- ✅ Réduction charge Ollama ~50%
- ✅ NA rate amélioration stable (pas de variance LLM entre runs)

**Maintenance**:
```bash
# Nettoyer cache > 30 jours
find /opt/gpti/tmp/llm_evidence_cache -name "*.json" -mtime +30 -delete
```

---

### 3. **SMALL MODEL OPTION (1B)** (RAM gain 💾)

**Problème**: 
- RAM limitee pour workers multiples
- Besoin d'une alternative plus legere

**Solution**:
```bash
# Utiliser le modele 1B en fallback RAM
ollama pull llama3.2:1b

# Comparer qualité extraction
cd /opt/gpti/gpti-data-bot
python3 scripts/compare_models.py \
    --models phi,llama3.2:1b \
  --firms topstepcom,ftmocom \
  --metrics accuracy,latency,ram
```

**Impact estime**:
- ✅ RAM reduite (1B < phi)
- ✅ Permet plus de workers si necessaire
- ⚠️ Qualite potentiellement plus faible
- ⚠️ Latence variable selon charge

**Décision**: Tester en local d'abord, n'adopter que si qualité acceptable

---

### 4. **WORKER TUNING** (Stabilité + Performance ⚙️)

**Problème actuel**:
- 3 workers = stable mais lent
- 4 workers = Ollama freeze (timeout)
- 6 workers = freeze immédiat

**Solution hybride**:
```python
# Stratégie dynamique adaptative
import psutil

def get_optimal_workers():
    cpu_count = psutil.cpu_count()
    mem_available = psutil.virtual_memory().available / (1024**3)  # GB
    
    # Si RAM < 3GB disponible → 2 workers
    if mem_available < 3:
        return 2
    # Si CPU >= 4 et RAM >= 4GB → 3 workers
    elif cpu_count >= 4 and mem_available >= 4:
        return 3
    else:
        return 2

# extract_batch_top20.py ligne 15
WORKERS = int(os.getenv("GPTI_EXTRACT_WORKERS", str(get_optimal_workers())))
```

**Impact**:
- ✅ Adaptation automatique aux ressources VPS
- ✅ Moins de freezes Ollama
- ✅ Performance stable long-term

---

### 5. **BATCH EXTRACTION FULL** (NA Rate fix 📈)

**Problème**: 
- 20/157 firms extraits = 12.7% coverage
- NA rate reste 84.55% car 137 firms utilisent vieilles extractions

**Solution**:
```bash
# Créer script batch ALL firms (top 100 d'abord)
cd /opt/gpti/gpti-data-bot/scripts

cat > extract_batch_full.py << 'EOF'
#!/usr/bin/env python3
"""Extract ALL firms with evidence (priorité: NA rate > 80%)"""
import sys
sys.path.insert(0, '/opt/gpti/gpti-data-bot/src')

from gpti_bot.db import connect
from gpti_bot.extract_from_evidence import run_extract_from_evidence_for_firm
from concurrent.futures import ThreadPoolExecutor, as_completed
import os
import time
from threading import Lock

WORKERS = int(os.getenv("GPTI_EXTRACT_WORKERS", "2"))

def main():
    with connect() as conn:
        cur = conn.cursor()
        
        # Get firms avec evidence + NA rate > 80%
        cur.execute("""
            SELECT DISTINCT e.firm_id, f.name, 
                   (SELECT AVG(na_rate) FROM snapshot_scores 
                    WHERE firm_id=e.firm_id 
                    ORDER BY snapshot_id DESC LIMIT 1) as na_rate
            FROM evidence e
            JOIN firms f ON e.firm_id = f.firm_id
            WHERE e.key IN ('rules_html','pricing_html','external_html','xhr_json')
            AND e.raw_object_path IS NOT NULL
            ORDER BY na_rate DESC NULLS FIRST
        """)
        firms = cur.fetchall()
    
    print(f"🔍 Found {len(firms)} firms to extract")
    
    results = {}
    lock = Lock()
    
    def _run(fid, name, na):
        result = run_extract_from_evidence_for_firm(fid)
        with lock:
            results[fid] = result
            idx = len(results)
            print(f"[{idx}/{len(firms)}] {fid} (NA={na:.1f}%) | "
                  f"Processed: {result['processed']} | Rules: {result['rules']} | "
                  f"Pricing: {result['pricing']} | Errors: {result['errors']}")
        return result
    
    with ThreadPoolExecutor(max_workers=WORKERS) as executor:
        futures = {executor.submit(_run, fid, name, na or 100): fid 
                  for fid, name, na in firms}
        for future in as_completed(futures):
            try:
                future.result()
            except Exception as e:
                print(f"❌ Error: {e}")
    
    total_rules = sum(r['rules'] for r in results.values())
    total_pricing = sum(r['pricing'] for r in results.values())
    print(f"\n✅ DONE: {total_rules} rules, {total_pricing} pricing extracted")

if __name__ == "__main__":
    main()
EOF

chmod +x extract_batch_full.py

# Lancer extraction FULL (avec monitoring)
GPTI_EXTRACT_WORKERS=2 nohup python3 extract_batch_full.py > /opt/gpti/tmp/extract_full.log 2>&1 &
tail -f /opt/gpti/tmp/extract_full.log
```

**Impact estimé**:
- ✅ Coverage passe de 12.7% → **100%**
- ✅ NA rate: 84.55% → **<60%** (objectif <50% après tuning prompts)
- ⏱️ Durée: ~2-4h avec 2 workers (boucle en background safe)

**Rollout progressif**:
1. Top 50 firms (NA > 90%) → valider qualité
2. Top 100 firms → mesurer NA rate improvement
3. ALL 157 firms → scoring final snapshot #53

---

## 🔄 PLAN D'IMPLÉMENTATION

### Phase 1: Quick Wins (30 min) ⚡
- [x] Réduire prompt size (6000 chars rules, 8000 chars pricing) ✅ **DONE 26 Feb**
- [x] Implémenter cache LLM evidence (fichier local JSON) ✅ **DONE 20 Feb** (390 files, 1.6M)
- [x] Tester validation chunking ✅ **DONE 26 Feb** (33% reduction confirmed)
- [ ] Tester extraction complète sur 5 firms pilotes ⏳ **Post-Board**
- [ ] Valider qualité extraction vs baseline ⏳ **Post-Board**

### Phase 2: Stabilité (1h) 🛡️
- [x] Worker adaptatif basé RAM/CPU disponible ✅ **DONE 26 Feb** (get_optimal_workers)
- [x] Script batch avec ThreadPoolExecutor ✅ **DONE 26 Feb** (extract_batch_full.py)
- [ ] Monitoring Ollama health (curl ping automatique) ⏳ **Optional**
- [ ] Auto-restart Ollama si timeout détecté ⏳ **Optional**

### Phase 3: Full Extraction (2-4h background) 📊
- [x] Créer script `extract_batch_full.py` ✅ **DONE 26 Feb** (optimized version)
- [ ] Lancer batch top 50 firms ⏳ **Post-Board (Feb 27+)**
- [ ] Scoring intermédiaire (snapshot #53_partial) ⏳ **Post-Board**
- [ ] Mesurer NA rate improvement (~70-75%) ⏳ **Post-Board**
- [ ] Lancer batch ALL 157 firms ⏳ **Post-Board (1-2h)**
- [ ] Scoring final (snapshot #53_final) ⏳ **Post-Board**
- [ ] Target: NA rate < 60% ⏳ **Expected by Feb 28**

### Phase 4: Performance (optionnel) 🚀
- [ ] Tester llama3.2:1b en fallback RAM ⏸️ **Not needed (RAM OK)**
- [ ] Si qualite OK: adopter pour batch long ⏸️ **N/A**
- [ ] Experimenter 4 workers avec 1b ⏸️ **Not needed**
- [ ] Monitoring long-term stabilite ⏸️ **Optional**

---

## 📈 MÉTRIQUES ATTENDUES

| Métrique | Avant | Après (Phase 1-2) | Après (Phase 3) |
|----------|-------|-------------------|-----------------|
| **NA Rate Global** | 84.55% | 84.55% | **<60%** |
| **Latence batch 20 firms** | 8-12 min | **5-7 min** | N/A |
| **Latence batch 157 firms** | N/A | N/A | **2-4h** |
| **Ollama freeze incidents** | 3 restarts | **0 restart** | **0 restart** |
| **RAM Ollama (phi/1b)** | 1.6GB / 1.0GB | 1.6GB / 1.0GB | 1.6GB / 1.0GB |
| **Workers stables** | 3 | 2-3 | 2-3 |
| **Cache LLM hit rate** | N/A | **40-60%** | **40-60%** |

---

## 🧪 VALIDATION TESTS

### Test 1: Prompt Reduction Quality
```bash
cd /opt/gpti/gpti-data-bot
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/gpti/gpti-data-bot/src')

from gpti_bot.db import connect
from gpti_bot.agents.rules_extractor import extract_rules_multi_pass

# Test avec topstepcom (firm avec bonne data)
conn = connect()
cur = conn.cursor()
cur.execute("""
    SELECT value_text FROM datapoints 
    WHERE firm_id='topstepcom' AND key='rules_extracted_v0' 
    ORDER BY created_at DESC LIMIT 1
""")
original = cur.fetchone()[0]

# Re-extract avec nouveau prompt size
# (manuel: modifier max_chars=6000 dans rules_extractor.py ligne 116)
# puis relancer extraction

# Compare résultats
print("=== VALIDATION ===")
print(f"Original fields: {len([k for k,v in original.items() if v])}")
print(f"New fields: {len([k for k,v in new.items() if v])}")
print(f"Match rate: {sum(1 for k in original if original[k]==new.get(k)) / len(original) * 100:.1f}%")
EOF
```

### Test 2: Cache LLM Effectiveness
```bash
cd /opt/gpti/gpti-data-bot
# Lancer 2x extraction sur même firm
time python3 -c "from gpti_bot.extract_from_evidence import run_extract_from_evidence_for_firm; run_extract_from_evidence_for_firm('topstepcom')"
# Run 1: 45s (miss cache)
time python3 -c "from gpti_bot.extract_from_evidence import run_extract_from_evidence_for_firm; run_extract_from_evidence_for_firm('topstepcom')"
# Run 2: 2s (hit cache) → 95% faster ✅
```

---

## 🚨 ROLLBACK PLAN

Si problème détecté:

```bash
# 1. Restaurer prompts originaux
cd /opt/gpti/gpti-data-bot/src/gpti_bot/agents
git diff rules_extractor.py pricing_extractor.py
git checkout rules_extractor.py pricing_extractor.py

# 2. Désactiver cache LLM
rm -rf /opt/gpti/tmp/llm_evidence_cache

# 3. Revenir workers=3
export GPTI_EXTRACT_WORKERS=3

# 4. Restart Ollama
sudo systemctl restart ollama

# 5. Scoring rollback snapshot
cd /opt/gpti/gpti-data-bot
python3 scripts/option-b-scoring.py  # Génère snapshot #54 baseline
```

---

## 📝 NOTES

- **Priorité absolue**: Ne pas casser le processus actuel qui fonctionne
- **Validation incrémentale**: Tester chaque optimisation sur 3-5 firms avant rollout
- **Monitoring**: Surveiller RAM/CPU/Ollama health pendant batch FULL
- **Backup**: Garder snapshot #52 comme baseline (84.55% NA rate)
- **Objectif final**: NA rate < 50% → nécessite extraction FULL + prompt tuning + qualité 3B

---

**Prochaine action**: Implémenter Phase 1 (prompt reduction + cache LLM) puis valider sur 5 firms pilotes.
