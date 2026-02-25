# Guide Accès Collaborateurs - Console Admin GTIXT

**Date**: 2026-02-25  
**Version**: 1.0  
**Statut**: ✅ Sécurisé & Opérationnel

---

## 🔐 Accès sécurisé

La console admin est **entièrement protégée par authentification**. Toute tentative d'accès sans login valide redirige automatiquement vers la page de connexion.

### 🌐 URLs

**Production (HTTPS)**:  
- Login: `https://admin.gtixt.com/admin/login/`  
- Console: `https://admin.gtixt.com/admin/review-queue/`

**Développement local**:  
- Login: `http://localhost:3000/admin/login/`  
- Console: `http://localhost:3000/admin/review-queue/`

> ✅ **Certificat SSL**: Let's Encrypt, auto-renouvelé, expire 2026-05-26

---

## 👥 Créer un compte collaborateur

### Méthode 1: Via script Python (recommandé)

```bash
cd /opt/gpti/gpti-data-bot

# Créer un reviewer
python3 src/gpti_bot/enrichment/create_internal_user.py \
  reviewer \
  jean \
  jean@gpti.internal \
  MotDePasseSecurise123

# Créer un lead reviewer
python3 src/gpti_bot/enrichment/create_internal_user.py \
  lead_reviewer \
  marie \
  marie@gpti.internal \
  AutreMotDePasse456

# Créer un auditeur (lecture seule)
python3 src/gpti_bot/enrichment/create_internal_user.py \
  auditor \
  audit_team \
  audit@gpti.internal \
  AuditPass789
```

### Méthode 2: Via SQL direct

```sql
-- Se connecter à la DB
psql postgresql://gpti:PASSWORD@localhost:5432/gpti

-- Créer un user (mot de passe sera hashé en SHA256)
INSERT INTO internal_users (username, email, password_hash, role, created_at)
VALUES (
  'jean',
  'jean@gpti.internal',
  encode(digest('MotDePasseSecurise123', 'sha256'), 'hex'),
  'reviewer',
  NOW()
);
```

---

## 🎫 Rôles et permissions

| Rôle            | Permissions                                                      |
|-----------------|------------------------------------------------------------------|
| `reviewer`      | Voir queue, approuver/rejeter candidats, commenter               |
| `lead_reviewer` | + escalader, override décisions, changer statut, actions admin   |
| `auditor`       | **Lecture seule**, accès trails d'audit complets, exports       |
| `admin`         | **Tous pouvoirs**, gestion users, configuration système         |

---

## 🚪 Workflow de connexion

### 1. Accès initial

Le collaborateur se rend sur:
```
http://localhost:3000/admin/review-queue/
```

**Résultat**: Redirection automatique vers `/admin/login/` avec paramètre `returnTo`:
```
http://localhost:3000/admin/login/?returnTo=%2Fadmin%2Freview-queue%2F
```

### 2. Formulaire de login

Le collaborateur saisit:
- **Username**: son identifiant (ex: `jean`)
- **Password**: son mot de passe

Cliquer sur **Sign In**

### 3. Authentification backend

L'API `/api/internal/auth/login/` vérifie:
- ✅ Username existe
- ✅ Password match (SHA256)
- ✅ User actif

**Succès**: Retourne token JWT valide 24h
**Échec**: Message d'erreur (credentials invalides)

### 4. Stockage session

Le token est stocké dans `sessionStorage` (disparaît à la fermeture du navigateur):
```javascript
sessionStorage.setItem("admin_token", "542506c07f0ddb9e88ce...")
sessionStorage.setItem("admin_user", '{"id":1,"username":"jean",...}')
```

### 5. Redirection

L'utilisateur est redirigé vers la page demandée initialement (review queue)

---

## 🔑 Changement de mot de passe

### Depuis l'interface

- Page dédiée: `https://admin.gtixt.com/admin/change-password/`
- Accessible après login
- Obligation de changer si le mot de passe a expiré

### Politique de mot de passe (par défaut)

- Longueur minimale: 12 caractères
- Majuscule + minuscule + chiffre requis
- Symbole optionnel

### Paramètres configurables (.env)

```bash
# Auth / sessions
INTERNAL_SESSION_TTL_HOURS=24

# Password policy
INTERNAL_PASSWORD_MIN_LENGTH=12
INTERNAL_PASSWORD_REQUIRE_UPPER=true
INTERNAL_PASSWORD_REQUIRE_LOWER=true
INTERNAL_PASSWORD_REQUIRE_NUMBER=true
INTERNAL_PASSWORD_REQUIRE_SYMBOL=false

# Password rotation (0 = disabled)
INTERNAL_PASSWORD_ROTATION_DAYS=0
INTERNAL_PASSWORD_ROTATION_REQUIRE_INITIAL=false
```

---

## 🔒 Protection des pages

### Côté client (React)

Chaque page admin utilise le hook `useAdminAuth()`:

```typescript
import { useAdminAuth, adminFetch, adminLogout } from "../../lib/admin-auth-guard";

function AdminPage() {
  const auth = useAdminAuth(); // Vérifie auth, redirige si besoin
  
  if (auth.loading) {
    return <div>Verifying authentication...</div>;
  }
  
  // Page protégée affichée seulement si authentifié
  return <div>Hello {auth.user?.username}</div>;
}
```

### Côté serveur (API)

Chaque endpoint API utilise `requireRole()`:

```typescript
import { requireRole } from "../../../../lib/internal-auth";

export default async function handler(req, res) {
  const user = await requireRole(req, res, ["reviewer", "lead_reviewer"]);
  if (!user) return; // 401 automatique si non authentifié
  
  // Logique protégée
}
```

---

## 👤 Gestion des utilisateurs (admin seulement)

### Page UI

- `https://admin.gtixt.com/admin/users/`
- Visible uniquement pour le rôle `admin`

### Actions disponibles

- Créer un utilisateur (username, email, role)
- Réinitialiser un mot de passe
- Activer / désactiver un compte
- Changer un rôle

---

## 📡 Appels API authentifiés

### Automatique via `adminFetch`

Les pages admin utilisent `adminFetch()` qui inclut automatiquement le token:

```typescript
import { adminFetch } from "../../lib/admin-auth-guard";

// Appel API avec auth automatique
const res = await adminFetch("/api/internal/review-queue/");
const data = await res.json();
```

### Manuel (si besoin)

```javascript
const token = sessionStorage.getItem("admin_token");

fetch("/api/internal/review-queue/", {
  headers: {
    "Authorization": `Bearer ${token}`
  }
});
```

---

## 🚪 Déconnexion

### Depuis l'interface

Cliquer sur **Logout** dans la barre utilisateur (en haut à droite)

### Programmatique

```typescript
import { adminLogout } from "../../lib/admin-auth-guard";

// Appelle /api/internal/auth/logout puis redirige
adminLogout();
```

### Ce qui se passe

1. Appel API `/api/internal/auth/logout/` (invalide session en DB)
2. Suppression du token local (`sessionStorage.clear()`)
3. Redirection vers `/admin/login/`

---

## 🌐 Déploiement en production

### 1. Configuration domaine

Mettre à jour les URLs dans `.env`:

```bash
NEXT_PUBLIC_SITE_URL=https://admin.gtixt.com
```

### 2. HTTPS obligatoire

**⚠️ CRITIQUE**: Les tokens sont sensibles, HTTPS est **obligatoire** en production.

```nginx
# nginx config
server {
  listen 443 ssl http2;
  server_name admin.gtixt.com;
  
  ssl_certificate /etc/letsencrypt/live/admin.gtixt.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/admin.gtixt.com/privkey.pem;
  
  location / {
    proxy_pass http://localhost:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```

### 3. Variables d'environnement

```bash
# Production DB
DATABASE_URL=postgresql://user:pass@prod-db:5432/gpti

# JWT secret (générer avec openssl rand -hex 32)
JWT_SECRET=your_super_secret_key_here
```

### 4. Firewall

Restreindre l'accès par IP si possible:

```bash
# ufw (Ubuntu)
sudo ufw allow from OFFICE_IP to any port 3000

# iptables
iptables -A INPUT -p tcp --dport 3000 -s OFFICE_IP -j ACCEPT
iptables -A INPUT -p tcp --dport 3000 -j DROP
```

---

## 🔍 Monitoring & Audit

### Logs d'accès

Tous les appels API sont loggés dans `internal_access_log`:

```sql
SELECT 
  u.username,
  al.action,
  al.resource_id,
  al.occurred_at,
  al.ip_address
FROM internal_access_log al
JOIN internal_users u ON u.id = al.user_id
ORDER BY al.occurred_at DESC
LIMIT 50;
```

### Sessions actives

```sql
SELECT 
  u.username,
  u.role,
  s.created_at,
  s.expires_at,
  s.last_used_at
FROM internal_sessions s
JOIN internal_users u ON u.id = s.user_id
WHERE s.expires_at > NOW()
ORDER BY s.last_used_at DESC;
```

### Révoquer une session

```sql
-- Révoquer toutes les sessions d'un user
DELETE FROM internal_sessions WHERE user_id = 3;

-- Révoquer une session spécifique
DELETE FROM internal_sessions WHERE token_hash = '...';
```

---

## 🆘 Dépannage

### "Unauthorized" après login

**Cause**: Token expiré ou invalide

**Solution**:
1. Se déconnecter explicitement
2. Vider le cache navigateur (`Ctrl+Shift+Delete`)
3. Se reconnecter

### Page reste sur "Verifying authentication"

**Cause**: API `/api/internal/auth/me/` ne répond pas

**Solution**:
```bash
# Vérifier que le service tourne
sudo systemctl status gpti-site.service

# Vérifier logs
sudo journalctl -u gpti-site.service -n 50
```

### Password oublié

**Reset via SQL**:
```sql
-- Générer nouveau hash (exemple: "NewPassword123")
UPDATE internal_users 
SET password_hash = encode(digest('NewPassword123', 'sha256'), 'hex')
WHERE username = 'jean';
```

---

## 📚 Fichiers importants

- **Page login**: `/opt/gpti/gpti-site/pages/admin/login.tsx`
- **Guard auth**: `/opt/gpti/gpti-site/lib/admin-auth-guard.ts`
- **API login**: `/opt/gpti/gpti-site/pages/api/internal/auth/login.ts`
- **Schema SQL**: `/opt/gpti/gpti-data-bot/infra/sql/010_internal_auth.sql`
- **Script user**: `/opt/gpti/gpti-data-bot/src/gpti_bot/enrichment/create_internal_user.py`

---

## ✅ Checklist déploiement collaborateur

- [ ] Compte créé avec rôle approprié
- [ ] Password sécurisé communiqué (hors email, via 1Password/LastPass)
- [ ] URL admin communiquée (`/admin/login/`)
- [ ] HTTPS configuré (production uniquement)
- [ ] Test de connexion validé
- [ ] IP autorisée dans firewall (optionnel)
- [ ] Session timeout configuré (défaut: 24h)

---

**Support**: Pour toute question, contacter l'équipe technique GTIXT
