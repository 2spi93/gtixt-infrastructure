# Guide Console Interne ASIC Review Queue

Date: 2026-02-25  
Statut: ✅ Opérationnel

---

## 📋 Vue d'ensemble

Console web interne pour réviser et approuver les matchs ASIC (Australian Securities & Investments Commission) pour les firms prop trading basées en Australie.

**Base de données**: PostgreSQL `localhost:5432/gpti`  
**Serveur**: Next.js sur `http://localhost:3000` (local) / `https://admin.gtixt.com` (prod)  
**Console Admin**: `https://admin.gtixt.com/admin/login/` ✅ HTTPS Actif

> **🔐 SÉCURITÉ**: Toutes les pages admin sont **protégées par authentification**. L'accès sans login redirige automatiquement vers `/admin/login/`. Les APIs backend utilisent des tokens JWT avec expiration 24h.

> **Note**: Les pages UI sont sous `/admin/*` pour cohérence avec les autres pages d'administration. Les APIs backend restent sous `/api/internal/*` car ce sont des APIs internes protégées.

> **📖 Guide collaborateurs**: Voir [`ADMIN_ACCESS_GUIDE.md`](./ADMIN_ACCESS_GUIDE.md) pour instructions complètes sur création de comptes et accès en production.

> **🔑 Changement mot de passe**: `https://admin.gtixt.com/admin/change-password/`

---

## 🔐 Authentification

### Accès Web (Interface UI)

**Page de login**: `http://localhost:3000/admin/login/`

1. Ouvrir la page de login dans le navigateur
2. Saisir username et password
3. Cliquer "Sign In"
4. Redirection automatique vers la console

**Workflow automatique**:
- Tentative d'accès à `/admin/review-queue/` sans login → Redirection vers `/admin/login/`
- Après login réussi → Token stocké en `sessionStorage` (valide 24h)
- Token inclus automatiquement dans tous les appels API via `adminFetch()`
- Bouton "Logout" disponible en haut à droite de chaque page

### Comptes de test créés

| Username   | Password   | Rôle            | Permissions                                   |
|------------|------------|-----------------|-----------------------------------------------|
| alice      | alice123   | reviewer        | Voir queue, approuver/rejeter candidats       |
| bob        | bob123     | lead_reviewer   | + override, escalade, changement statut       |
| compliance | audit123   | auditor         | Lecture seule, accès trails d'audit complets  |

> **Création de comptes**: Voir section "Créer un compte collaborateur" dans [`ADMIN_ACCESS_GUIDE.md`](./ADMIN_ACCESS_GUIDE.md)

### Login API (pour tests/scripts)

```bash
curl -X POST http://localhost:3000/api/internal/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","password":"alice123"}'
```

**Réponse**:
```json
{
  "success": true,
  "token": "7f05f6020b387faf41f2...",
  "user": {
    "id": 1,
    "username": "alice",
    "email": "alice@gpti.internal",
    "role": "reviewer"
  }
}
```

---

## 📊 Endpoints API

### 1. Liste des candidats

```bash
curl -s "http://localhost:3000/api/internal/review-queue/" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Paramètres query** (optionnels):
- `status=pending|approved|rejected|escalated`
- `jurisdiction=AU`
- `search=text` (recherche dans firm_name ou afs_name)
- `minScore=0.80`
- `maxScore=0.95`
- `limit=50`
- `offset=0`

**Réponse**:
```json
{
  "success": true,
  "data": [
    {
      "id": 17,
      "firm_id": "asic_test_001",
      "firm_name": "Test Financial Pty Ltd",
      "afs_name": "Test Financial Services Pty Ltd",
      "fuzzy_score": "0.8889",
      "review_status": "pending",
      "reviewed_by": null,
      "reviewed_at": null,
      "created_at": "2026-02-25T17:45:26.974Z",
      "website_root": "https://test-financial.com.au",
      "jurisdiction": "AU"
    }
  ],
  "meta": {
    "total": 8,
    "pending": 8,
    "avgScore": 0.8554375,
    "limit": 50,
    "offset": 0
  }
}
```

### 2. Détail d'un candidat

```bash
curl -s "http://localhost:3000/api/internal/review-queue/17/" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. Historique d'audit

```bash
curl -s "http://localhost:3000/api/internal/review-queue/17/audit/" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Réponse**:
```json
{
  "success": true,
  "data": [
    {
      "id": 42,
      "review_queue_id": 17,
      "action": "approved",
      "details": {"notes": "High confidence match"},
      "triggered_by": "bob",
      "occurred_at": "2026-02-25T18:00:00.000Z"
    }
  ]
}
```

### 4. Actions sur candidat

```bash
# Approuver
curl -X POST "http://localhost:3000/api/internal/review-queue/17/actions/" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "approve",
    "notes": "AFS license verified, strong name match"
  }'

# Rejeter
curl -X POST "http://localhost:3000/api/internal/review-queue/17/actions/" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "reject",
    "notes": "Incorrect ABN lookup result"
  }'

# Ajouter commentaire
curl -X POST "http://localhost:3000/api/internal/review-queue/17/actions/" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "comment",
    "notes": "Needs manual ABN verification"
  }'

# Escalader (lead_reviewer uniquement)
curl -X POST "http://localhost:3000/api/internal/review-queue/17/actions/" \
  -H "Authorization: Bearer LEAD_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "escalate",
    "notes": "Complex case - conflicting evidence"
  }'
```

**Actions disponibles**:
- `approve` - Approuver le match ASIC (reviewer+)
- `reject` - Rejeter le match (reviewer+)
- `comment` - Ajouter note sans changer statut (reviewer+)
- `escalate` - Escalader pour révision senior (lead_reviewer+)
- `set_status` - Changer statut manuellement (lead_reviewer+)

### 5. Chat avec agent d'assistance

```bash
curl -X POST http://localhost:3000/api/internal/agent-chat/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "review_id": 17,
    "message": "Should I approve this candidate with 0.88 fuzzy score?"
  }'
```

**Réponse**:
```json
{
  "success": true,
  "data": {
    "reply": "A fuzzy score of 0.88 is above the 0.80 threshold...",
    "suggestions": [
      "Verify ABN lookup results",
      "Check AFS license status on ASIC website",
      "Compare business names carefully"
    ]
  }
}
```

### 6. Vérifier session

```bash
curl -s http://localhost:3000/api/internal/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 7. Logout

```bash
curl -X POST http://localhost:3000/api/internal/auth/logout \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🗄️ Schéma Base de Données

### Tables créées

#### `internal_users` - Comptes console
- `id`, `username`, `email`, `password_hash`, `role`, `active`

#### `internal_sessions` - Sessions auth
- `id`, `user_id`, `token`, `expires_at`, `ip_address`, `user_agent`

#### `internal_access_log` - Journal d'accès
- `id`, `user_id`, `action`, `resource`, `details`, `ip_address`, `occurred_at`

#### `asic_review_queue` - Candidats à réviser
- `id`, `firm_id` (FK firms), `firm_name`, `afs_name`, `fuzzy_score`
- `asic_abn`, `asic_acn`, `asic_afs_licence`, `asic_company_status`
- `review_status` (pending/approved/rejected/escalated)
- `reviewed_by`, `reviewed_at`, `reviewer_notes`

#### `asic_verification_audit` - Trail d'audit
- `id`, `review_queue_id`, `action`, `details`, `triggered_by`, `occurred_at`

---

## 🚀 Workflow Recommandé

### 1. Révision quotidienne

```bash
# Login
TOKEN=$(curl -sL http://localhost:3000/api/internal/auth/login -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","password":"alice123"}' | jq -r '.token')

# Liste candidats pending
curl -s "http://localhost:3000/api/internal/review-queue/?status=pending&limit=10" \
  -H "Authorization: Bearer $TOKEN" | jq '.data[] | {id, firm_name, afs_name, fuzzy_score}'

# Réviser candidat #17
curl -s "http://localhost:3000/api/internal/review-queue/17/" \
  -H "Authorization: Bearer $TOKEN" | jq .

# Demander conseil agent
curl -sX POST http://localhost:3000/api/internal/agent-chat/ \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"review_id":17,"message":"Evaluate this match"}' | jq .

# Approuver
curl -sX POST "http://localhost:3000/api/internal/review-queue/17/actions/" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"action":"approve","notes":"Verified via ASIC website"}' | jq .
```

### 2. Audit hebdomadaire (Auditor)

```bash
# Login as auditor
TOKEN=$(curl -sL http://localhost:3000/api/internal/auth/login -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"compliance","password":"audit123"}' | jq -r '.token')

# Stats globales
curl -s "http://localhost:3000/api/internal/review-queue/" \
  -H "Authorization: Bearer $TOKEN" | jq '.meta'

# Voir toutes les approbations récentes
curl -s "http://localhost:3000/api/internal/review-queue/?status=approved" \
  -H "Authorization: Bearer $TOKEN" | jq '.data[] | {firm_name, reviewed_by, reviewed_at}'
```

---

## 🔧 Maintenance

### Ajouter un utilisateur

```bash
cd /opt/gpti/gpti-data-bot
export DATABASE_URL="postgresql://gpti:2e8c1b61927c490738c23e5e7976f69790a1b2bd4c75b1c8@localhost:5432/gpti"
python3 src/gpti_bot/enrichment/create_internal_user.py reviewer john john@gpti.internal john123
```

### Vérifier les sessions actives

```sql
SELECT u.username, s.token, s.expires_at, s.ip_address
FROM internal_sessions s
JOIN internal_users u ON u.id = s.user_id
WHERE s.expires_at > NOW()
ORDER BY s.created_at DESC;
```

### Consulter le journal d'accès

```sql
SELECT u.username, l.action, l.resource, l.occurred_at
FROM internal_access_log l
LEFT JOIN internal_users u ON u.id = l.user_id
ORDER BY l.occurred_at DESC
LIMIT 50;
```

---

## 📈 Métriques Actuelles

- **Candidats total**: 8
- **Pending**: 8
- **Score moyen**: 0.8554
- **Utilisateurs**: 3 (1 reviewer, 1 lead, 1 auditor)

---

## ⚠️ Notes Importantes

1. **Trailing slash**: Toujours inclure `/` à la fin des URLs API (`/review-queue/` pas `/review-queue`)
2. **Token expiration**: Les tokens expirent après 24h
3. **Base de données**: gpti-site et gpti-data-bot utilisent des DB différentes (ports 5432 vs 5434)
4. **ABN API**: En attente de clé API (5 jours) - actuellement stub uniquement
5. **Authentification**: SHA256 en place, upgrade vers bcrypt recommandé pour production

---

## 🔗 Liens Utiles

- Migration SQL Auth: `/opt/gpti/gpti-data-bot/infra/sql/010_internal_auth.sql`
- Migration SQL Review: `/opt/gpti/gpti-data-bot/infra/sql/009_asic_review_queue.sql`
- Script création user: `/opt/gpti/gpti-data-bot/src/gpti_bot/enrichment/create_internal_user.py`
- API Routes: `/opt/gpti/gpti-site/pages/api/internal/`
- UI Pages: `/opt/gpti/gpti-site/pages/admin/`

---

**Dernière mise à jour**: 2026-02-25 18:00 UTC  
**Status**: ✅ Production Ready (dev mode)
