# 🔑 GUIDE PRATIQUE - OÙ TROUVER VOS SECRETS

## 1️⃣ PAGERDUTY_INTEGRATION_KEY

### Où le trouver?

**Cas A: Vous avez déjà un compte PagerDuty**
```
1. Allez sur: https://app.pagerduty.com
2. Login avec vos identifiants
3. Menu: Integrations → Integration & Extensions
4. Cherchez "Events API V2" ou "Webhooks"
5. Cliquez "New Integration"
6. Copiez la clé dans "Integration Key"
```

**Cas B: Vous n'avez pas PagerDuty**
```
Option 1 (Recommandé):
- Créer compte gratuit: https://www.pagerduty.com/sign-up
- Suivre étapes Cas A ci-dessus

Option 2 (Alternative):
- Utiliser Slack webhooks seul (suffit pour alertes)
- Laisser PAGERDUTY_INTEGRATION_KEY vide dans GitHub
- Les déploiements fonctionnent quand même
```

### Comment l'intégrer dans GitHub?

```
GitHub → Your Repository → Settings → Secrets and variables → Actions

Click "New repository secret"
  Name: PAGERDUTY_INTEGRATION_KEY
  Value: <Copiez-collez ici votre clé>
  
Click "Add secret"
```

**Format attendu:**
```
Exemple: f4cffa7ade334d00b74d5cc98c2a9c99
Longueur: ~32 caractères hexadécimaux
```

---

## 2️⃣ PRODUCTION_SSH_KEY

### Où le trouver?

**Cas A: Vous avez déjà une clé SSH**
```
Sur votre machine locale:
  ls -la ~/.ssh/
  
Vous verrez des fichiers comme:
  - id_rsa (clé privée) ← C'EST CELLE-CI
  - id_rsa.pub (clé publique)
  - id_ed25519 (alternative)
  - id_ed25519.pub
```

**Cas B: Vous n'avez pas de clé SSH**
```
Générer une nouvelle clé:
  ssh-keygen -t ed25519 -C "admin@gtixt.com"
  
Questions:
  File: Appuyez juste Enter (utilise ~/.ssh/id_ed25519)
  Passphrase: Laissez vide (appuyez Enter 2x)
  
Résultat:
  ~/.ssh/id_ed25519 (clé privée) ← À mettre dans GitHub
  ~/.ssh/id_ed25519.pub (clé publique) ← À mettre sur serveur
```

### Comment copier la clé?

```bash
# Afficher la clé privée (SANS partager!)
cat ~/.ssh/id_ed25519

# Ou avec votre éditeur
nano ~/.ssh/id_ed25519

# Format attendu:
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUtbm9uZS1ub2...
[~ 20 lignes de caractères aléatoires]
-----END OPENSSH PRIVATE KEY-----
```

### Intégrer dans GitHub:

```
GitHub → Your Repository → Settings → Secrets and variables → Actions

Click "New repository secret"
  Name: PRODUCTION_SSH_KEY
  Value: [Collez TOUTE la clé du -----BEGIN au -----END]
  
Click "Add secret"
```

⚠️ **IMPORTANT**: 
- Ne JAMAIS partager la clé privée (id_rsa ou id_ed25519)
- Ne JAMAIS la mettre en .env ou commit dans git
- C'est comme un mot de passe - gardez-la secrète!

---

## 3️⃣ COPILOT_URL

### Format correct pour votre repository:

**Votre repo:** https://github.com/2spi93/gtixt-infrastructure

**COPILOT_URL sera:**
```
https://api.github.com/repos/2spi93/gtixt-infrastructure/copilot
```

**EN GÉNÉRAL:**
```
Format: https://api.github.com/repos/<OWNER>/<REPO>/copilot
          |_______________|          |_____|  |_____|
                |               |              |
          API GitHub      Votre username   Nom du repository
```

**Exemple avec le vôtre:**
```
https://api.github.com/repos/2spi93/gtixt-infrastructure/copilot
                             |___|  |______________________|
                             Owner        Repository name
```

### Comment intégrer dans GitHub:

```
GitHub → Your Repository → Settings → Secrets and variables → Actions

Click "New repository secret"
  Name: COPILOT_URL
  Value: https://api.github.com/repos/2spi93/gtixt-infrastructure/copilot
  
Click "Add secret"
```

---

## 4️⃣ COPILOT_API_KEY

### Où le trouver?

**Si vous avez GitHub Copilot (payant):**
```
1. Allez: https://github.com/settings/tokens (vos tokens personnels)
2. Click "Generate new token" → "Generate new token (classic)"
3. Scope: Sélectionnez "repo" + "admin:repo_hook"
4. Cliquez "Generate token"
5. Copiez le token immédiatement (vous ne pourrez pas le voir après)
```

**Si vous n'avez pas Copilot:**
```
Option 1: Acheter Copilot
  GitHub → Settings → Billing and plans → GitHub Copilot → Enable

Option 2: Utiliser sans Copilot (optionnel)
  - COPILOT_URL et COPILOT_API_KEY peuvent être laissés vides
  - Les déploiements fonctionnent sans eux
```

### Format et intégration:

```
GitHub → Your Repository → Settings → Secrets and variables → Actions

Click "New repository secret"
  Name: COPILOT_API_KEY
  Value: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx (token GitHub)
  
Click "Add secret"
```

---

## 5️⃣ CLÉS SSH PRODUCTION ET STAGING

### Avez-vous besoin de clés DIFFÉRENTES?

**Recommandé:**
```
✅ OUI - Créer clés séparées pour chaque environnement:
   - production-key (pour prod)
   - staging-key (pour staging)
   
Avantages:
  - Plus sécurisé (perte d'une clé = 1 env affecté)
  - Conformité de sécurité
  - Révocation facile d'une env
```

**Alternative (moins sécurisé):**
```
⚠️ Utiliser la MÊME clé pour prod ET staging
   Si la clé est compromiseattaque les 2 environnements
```

### Générer les clés:

```bash
# Clé PRODUCTION
ssh-keygen -t ed25519 -C "production@gtixt.com" -f ~/.ssh/production-key
  Passphrase: Laissez vide (Enter 2x)
  Résultat: ~/.ssh/production-key (privée) + ~/.ssh/production-key.pub (publique)

# Clé STAGING
ssh-keygen -t ed25519 -C "staging@gtixt.com" -f ~/.ssh/staging-key
  Passphrase: Laissez vide (Enter 2x)
  Résultat: ~/.ssh/staging-key (privée) + ~/.ssh/staging-key.pub (publique)
```

### Intégrer dans GitHub:

```
GitHub → Your Repository → Settings → Secrets and variables → Actions

Pour PRODUCTION:
  Name: PRODUCTION_SSH_KEY
  Value: [Contenu de ~/.ssh/production-key]

Pour STAGING:
  Name: STAGING_SSH_KEY
  Value: [Contenu de ~/.ssh/staging-key]
```

### Mettre les clés PUBLIQUES sur les serveurs:

**Sur votre serveur production:**
```bash
# Connectez-vous au serveur:
ssh ubuntu@your-production-ip

# Créez/éditez le fichier:
nano ~/.ssh/authorized_keys

# Collez le contenu de: ~/.ssh/production-key.pub

# Sauvegarder: Ctrl+X → Y → Enter
```

**Sur votre serveur staging:**
```bash
# Même procédure avec ~/.ssh/staging-key.pub
```

---

## 🎯 RÉSUMÉ - OÙ TROUVER CHAQUE SECRET

| Secret | Où le obtenir | Format | Gestion |
|--------|---|--------|---------|
| **PRODUCTION_SSH_KEY** | `~/.ssh/id_ed25519` ou générer | Clé privée OpenSSH | ✅ GitHub Secrets |
| **PRODUCTION_HOST** | IP du serveur ou domain | `51.210.246.61` ou `prod.gtixt.com` | ✅ GitHub Secrets |
| **PRODUCTION_USER** | SSH user du serveur | `ubuntu` ou `deploy` | ✅ GitHub Secrets |
| **STAGING_SSH_KEY** | `~/.ssh/staging-key` ou générer | Clé privée OpenSSH | ✅ GitHub Secrets |
| **STAGING_HOST** | IP du serveur ou domain | `staging.gtixt.com` ou `51.210.246.62` | ✅ GitHub Secrets |
| **STAGING_USER** | SSH user du serveur | `ubuntu` ou `deploy` | ✅ GitHub Secrets |
| **COPILOT_URL** | Créer via URL | `https://api.github.com/repos/2spi93/gtixt-infrastructure/copilot` | ✅ GitHub Secrets |
| **COPILOT_API_KEY** | GitHub → Settings → Tokens | `ghp_xxxxxxxxxx` (32+ chars) | ✅ GitHub Secrets |
| **SLACK_WEBHOOK_URL** | Slack → Apps → Incoming Webhooks | `https://hooks.slack.com/...` | ✅ GitHub Secrets |
| **PAGERDUTY_INTEGRATION_KEY** | PagerDuty → Integrations | Chaîne hexadécimale ~32 chars | ✅ GitHub Secrets |

---

## 📋 CHECKLIST - AVANT D'AJOUTER À GITHUB

Avant chaque secret, vérifiez:

```
PRODUCTION_SSH_KEY:
  ✅ Commence par -----BEGIN OPENSSH PRIVATE KEY-----
  ✅ Finit par -----END OPENSSH PRIVATE KEY-----
  ✅ Aucun espace avant/après
  ✅ C'EST la clé PRIVÉE (pas .pub)

PRODUCTION_HOST:
  ✅ IP valide (XXX.XXX.XXX.XXX)
  ✅ Ou domain FQDN (admin.gtixt.com)
  ✅ Test: ping <host> fonctionne

PRODUCTION_USER:
  ✅ Utilisateur qui a SSH access
  ✅ Généralement "ubuntu" ou "deploy"
  ✅ Test: ssh <user>@<host> fonctionne

COPILOT_URL:
  ✅ Format: https://api.github.com/repos/[OWNER]/[REPO]/copilot
  ✅ Votre owner: 2spi93
  ✅ Votre repo: gtixt-infrastructure

COPILOT_API_KEY:
  ✅ Commence par: ghp_
  ✅ ~32 caractères ou plus
  ✅ Token GitHub valide
  ✅ Scope "repo" sélectionné

SLACK_WEBHOOK_URL:
  ✅ Commence par: https://hooks.slack.com/services/
  ✅ Teste: curl -X POST -d '{"text":"test"}' <URL>

PAGERDUTY_INTEGRATION_KEY:
  ✅ Chaîne hexadécimale
  ✅ ~32 caractères
  ✅ De PagerDuty API
```

---

## 🚀 ORDRE D'ACTIONS RECOMMANDÉ

```
1. Générer clés SSH (production + staging)
   └─ Sauvegarder sur serveurs (authorized_keys)

2. Obtenir IPs/domaines des serveurs
   └─ PRODUCTION_HOST et STAGING_HOST

3. Obtenir GitHub Copilot API key
   └─ https://github.com/settings/tokens

4. Configurer PagerDuty (ou skip)
   └─ Optionnel mais recommandé

5. Obtenir Slack webhook
   └─ Optionnel mais recommandé

6. TOUT ajouter à GitHub Secrets
   └─ Dans les 2 environnements

7. Supprimer GITHUB_SECRETS_CONFIG.md
   └─ Sécurité - ne pas commiter
```

---

## ⚠️ SÉCURITÉ CRITIQUE

```
🔴 JAMAIS:
  ❌ Mettre secrets dans .env ou .env.local
  ❌ Commiter secrets dans git
  ❌ Partager clés SSH par email/Slack
  ❌ Utiliser même clé pour prod + staging
  ❌ Garder secrets dans GITHUB_SECRETS_CONFIG.md

🟢 TOUJOURS:
  ✅ Utiliser GitHub Secrets (chiffré)
  ✅ Clés SSH distinctes par environnement
  ✅ Supprimer GITHUB_SECRETS_CONFIG.md après
  ✅ Rotationner secrets tous les 90 jours
  ✅ Revoquer immédiatement si compromise
```

---

Generated: 2026-03-01  
Status: ✅ **GUIDE COMPLET POUR OBTENIR VOS SECRETS**
