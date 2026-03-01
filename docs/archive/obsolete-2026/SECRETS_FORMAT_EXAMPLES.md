# 📋 EXEMPLE CONCRET - CES SECRETS DOIVENT RESSEMBLER À ÇA

## 🔐 AVANT: Ce que VOUS devez obtenir

### 1️⃣ PRODUCTION_SSH_KEY

**Ressemble à:**
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUtbm9uZS1ub25lAAAACXNzaC1lZDI1NTE5
AAAAIDnZJ5L4K7S8H9k2N8m3X0L5K6P7Q8R9S0T1U2V3W4XAAAAAB2dyZXBka2Uw
AWQ1AyasdyasdyasHJk2DXM0X....
[~20-30 lignes de caractères]
AIBBzHkXxSk5Tr7g8H9i0J1K2L3M4N5O6P7QR8STU9V0W1X2Y3Z
-----END OPENSSH PRIVATE KEY-----
```

**Longueur:** ~1500-2000 caractères (avec sauts de ligne)

---

### 2️⃣ PRODUCTION_HOST

**Ressemble à:**
```
Exemple 1 (IP):
  51.210.246.61

Exemple 2 (Domain):
  admin.gtixt.com

Exemple 3 (AWS):
  ec2-51-210-246-61.compute-1.amazonaws.com
```

**Longueur:** 10-50 caractères

---

### 3️⃣ PRODUCTION_USER

**Ressemble à:**
```
ubuntu
```

ou

```
deploy
```

ou

```
ec2-user
```

**Longueur:** 3-15 caractères

---

### 4️⃣ STAGING_SSH_KEY

**Ressemble à:** Exactement comme PRODUCTION_SSH_KEY (même format, clé différente)
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUtbm9uZS1ub25lAAAACXNzaC1lZDI1NTE5
AAAAIDnZJ5L4K7S8H9k2N8m3X0L5K6P7Q8R9S0T1U2V3W4XAAAAAB2dyZXBka...
[clé complètement différente]
-----END OPENSSH PRIVATE KEY-----
```

---

### 5️⃣ STAGING_HOST

**Ressemble à:**
```
staging.gtixt.com
```

ou

```
51.210.246.62
```

---

### 6️⃣ STAGING_USER

**Ressemble à:**
```
ubuntu
```

---

### 7️⃣ COPILOT_URL

**Pour votre repository:**
```
https://api.github.com/repos/2spi93/gtixt-infrastructure/copilot
```

**Format général:**
```
https://api.github.com/repos/<OWNER>/<REPO>/copilot
```

**Longueur:** ~60 caractères

---

### 8️⃣ COPILOT_API_KEY

**Ressemble à:**
```
ghp_x4Vx9zYzA1bCdEfGhIjKlMnOpQrStUvWxYzA1bC2d3E
```

ou

```
ghp_16C7e42F292c6912E7710c838347Ae178B4a
```

**Commence par:** `ghp_`
**Longueur:** ~36-50 caractères

---

### 9️⃣ SLACK_WEBHOOK_URL

**Ressemble à:**
```
https://hooks.slack.com/services/T05PJKL9Z/B05QM9H2R/kJ8mX4nL2pQ9oR5sT7uV3wX
```

ou

```
https://hooks.slack.com/services/T1234567890/B1234567890/xxxxxxxxxxxxxxxxxxxxx
```

**Commence par:** `https://hooks.slack.com/services/`
**Longueur:** ~100-120 caractères
**Format:** T[ID]/B[ID]/[Token]

---

### 🔟 PAGERDUTY_INTEGRATION_KEY

**Ressemble à:**
```
f4cffa7ade334d00b74d5cc98c2a9c99
```

ou

```
a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6
```

**Format:** Chaîne hexadécimale
**Longueur:** 32 caractères
**Optionnel:** Peut être vide

---

## ✅ CHECKLIST FORMAT

Avant d'ajouter chaque secret à GitHub, vérifiez:

### SSH Keys (PRODUCTION_SSH_KEY, STAGING_SSH_KEY)
```
✅ Commence par: -----BEGIN OPENSSH PRIVATE KEY-----
✅ Finit par: -----END OPENSSH PRIVATE KEY-----
✅ Contient ~20-30 lignes de caractères aléatoires
✅ PAS d'espaces avant/après
✅ Format OpenSSH Ed25519
✅ C'est la clé PRIVÉE (pas .pub)
```

### Hostnames (PRODUCTION_HOST, STAGING_HOST)
```
✅ IP valide: XXX.XXX.XXX.XXX (0-255 chaque octet)
✅ Ou domain FQDN: exemple.gtixt.com
✅ Pas de protocole (pas http://)
✅ Pas d'accès SSH (pas ssh://user@host)
✅ Pas de port (pas :22)
```

### Usernames (PRODUCTION_USER, STAGING_USER)
```
✅ Lettres et chiffres seulement
✅ Généralement: ubuntu, deploy, ou ec2-user
✅ Pas de caractères spéciaux
✅ Casse correcte (ubuntu PAS Ubuntu)
```

### COPILOT_URL
```
✅ Format exact: https://api.github.com/repos/OWNER/REPO/copilot
✅ OWNER: 2spi93
✅ REPO: gtixt-infrastructure
✅ Commence par https://
✅ Pas de / à la fin
```

### COPILOT_API_KEY
```
✅ Commence par: ghp_
✅ ~32-50 caractères après ghp_
✅ Caractères alphanumériques seulement
✅ Token valide et pas expiré
✅ Scope "repo" sélectionné
```

### SLACK_WEBHOOK_URL
```
✅ Format: https://hooks.slack.com/services/T.../B.../...
✅ T...: Team ID (~10 caractères)
✅ B...: Bot/Channel ID (~10 caractères)
✅ ...: Token (~24+ caractères)
✅ Commence par https:// (pas http://)
✅ Webhook actif (créé récemment)
```

### PAGERDUTY_INTEGRATION_KEY
```
✅ 32 caractères hexadécimaux (0-9, a-f)
✅ Pas de tirets ou traits de soulignement
✅ Clé valide (pas expirée)
✅ Service lié à la clé existe
```

---

## 🚫 ERREURS COURANTES À ÉVITER

| Erreur | ❌ MAUVAIS | ✅ BON |
|--------|-----------|-------|
| **SSH Key** | Commence par `ssh-ed25519` | Commence par `-----BEGIN OPENSSH` |
| **SSH Key** | id_rsa.pub (publique) | id_rsa (privée) |
| **Host** | `ssh://ubuntu@51.210.246.61` | `51.210.246.61` |
| **Host** | `51.210.246.61:22` | `51.210.246.61` |
| **User** | `root` ou `ec2` | `ubuntu` ou `deploy` |
| **Token** | `hcp_xxxx` (GitHub Personal Access) | `ghp_xxxx` (GitHub Copilot) |
| **URL** | `https://hooks.slack...` (pas de slash fin) | `https://hooks.slack.../` ❌ |
| **Webhook** | URL créée il y a 2 ans | URL créée récemment |
| **Key** | Avec espaces avant/après | Sans espaces |
| **Format** | Clé dans quotes `"-----BEGIN..."` | Clé sans quotes |

---

## 📸 EXEMPLE COMPLET - DANS GITHUB

Voici à quoi devrait ressembler GitHub Secrets:

```
Go to: Repository → Settings → Secrets and variables → Actions

Vous devriez voir:
┌─────────────────────────────────────────┐
│ Repository secrets                      │
├─────────────────────────────────────────┤
│ COPILOT_API_KEY           Last updated  │
│ COPILOT_URL               Last updated  │
│ PAGERDUTY_INTEGRATION_KEY Last updated  │
│ PRODUCTION_HOST           Last updated  │
│ PRODUCTION_SSH_KEY        Last updated  │
│ PRODUCTION_USER           Last updated  │
│ SLACK_WEBHOOK_URL         Last updated  │
│ STAGING_HOST              Last updated  │
│ STAGING_SSH_KEY           Last updated  │
│ STAGING_USER              Last updated  │
└─────────────────────────────────────────┘

Cliquez sur chaque secret pour voir sa valeur (masquée sauf chiffres finaux)
```

---

## 🧪 TESTER LES SECRETS APRÈS AJOUT

```bash
# 1. SSH Keys
ssh -i ~/.ssh/production-key ubuntu@<PRODUCTION_HOST> "echo ✅ Production OK"
ssh -i ~/.ssh/staging-key ubuntu@<STAGING_HOST> "echo ✅ Staging OK"

# 2. Slack Webhook
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"GTIXT test ✅"}' \
  <SLACK_WEBHOOK_URL>
# Résultat attendu: Message dans Slack

# 3. GitHub Copilot Token (optionnel)
curl -H "Authorization: token <COPILOT_API_KEY>" \
  https://api.github.com/user
# Résultat: JSON avec infos utilisateur (pas d'erreur 401)
```

---

## 🎯 SOMME RAPIDE

Vous devez avoir 10 secrets dans GitHub:

```bash
# Vérifier avec:
curl -H "Authorization: token <YOUR_GITHUB_PAT>" \
  https://api.github.com/repos/2spi93/gtixt-infrastructure/actions/secrets
```

Message de succès: `"total_count": 10`

---

**Statut**: ✅ **TOUS LES EXEMPLES CONCRETS FOURNIS**  
**Prochaine étape**: Exécuter le setup (COMPLETE_SECRETS_SETUP.md)
