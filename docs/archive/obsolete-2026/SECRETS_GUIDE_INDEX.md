# 🔐 GUIDE DES SECRETS - TABLE DES MATIÈRES

## 📚 GUIDES DISPONIBLES

### 🚀 **POUR COMMENCER - LISEZ D'ABORD**

#### 1. [SECRETS_RETRIEVAL_GUIDE_FR.md](./SECRETS_RETRIEVAL_GUIDE_FR.md)
```
"Où trouver vos secrets?"
├─ PAGERDUTY_INTEGRATION_KEY (où le trouver + comment)
├─ PRODUCTION_SSH_KEY (générer / trouver)
├─ COPILOT_URL (formule correcte pour votre repo)
├─ COPILOT_API_KEY (où l'obtenir)
├─ SLACK_WEBHOOK_URL (créer et obtenir)
└─ Clés SSH prod/staging (même clés? quand les générer?)

Durée: 20 min à lire
Utilité: ⭐⭐⭐⭐⭐ (LISEZ CECI EN PREMIER)
```

---

### 🛠️ **POUR CONFIGURER - ENSUITE**

#### 2. [COMPLETE_SECRETS_SETUP.md](./COMPLETE_SECRETS_SETUP.md)
```
"Comment ajouter les secrets étape par étape?"
├─ Étape 1: Générer clés SSH
├─ Étape 2: Ajouter dans GitHub (PRODUCTION_SSH_KEY)
├─ Étape 3: Ajouter IPs et usernames
├─ Étape 4: Ajouter COPILOT_URL
├─ Étape 5: Obtenir et ajouter COPILOT_API_KEY
├─ Étape 6: Ajouter SLACK_WEBHOOK_URL
├─ Étape 7: Ajouter PAGERDUTY (optionnel)
├─ Étape 8: Mettre clés publiques sur serveurs
├─ Vérification finale
└─ Dépannage

Durée: 45 min à exécuter
Utilité: ⭐⭐⭐⭐⭐ (GUIDE COMPLET À SUIVRE)
```

---

### 📋 **POUR VÉRIFIER - CONSULTEZ**

#### 3. [SECRETS_FORMAT_EXAMPLES.md](./SECRETS_FORMAT_EXAMPLES.md)
```
"À quoi doivent ressembler les secrets?"
├─ Exemple PRODUCTION_SSH_KEY (format exact)
├─ Exemple PRODUCTION_HOST (IP ou domain)
├─ Exemple PRODUCTION_USER (ubuntu, deploy, etc.)
├─ Exemple COPILOT_URL (pour 2spi93/gtixt-infrastructure)
├─ Exemple COPILOT_API_KEY (ghp_xxxxx)
├─ Exemple SLACK_WEBHOOK_URL (https://hooks.slack...)
├─ Exemple PAGERDUTY_INTEGRATION_KEY (32 chars hexa)
├─ Checklist format (vérifier avant d'ajouter)
├─ Erreurs courantes à éviter
└─ Comment tester après ajout

Durée: 10 min à consulter
Utilité: ⭐⭐⭐⭐ (RÉFÉRENCE DE FORMATAGE)
```

---

### 🔑 **POUR GÉNÉRER - SCRIPT**

#### 4. [generate-ssh-keys.sh](./generate-ssh-keys.sh)
```
Script bash automatique qui:
├─ Génère clé SSH production
├─ Génère clé SSH staging
├─ Affiche clés PRIVÉES (pour GitHub)
├─ Affiche clés PUBLIQUES (pour serveurs)
└─ Donne instructions d'installation

Comment utiliser:
  bash /opt/gpti/generate-ssh-keys.sh

Durée: 2 min d'exécution
Utilité: ⭐⭐⭐⭐⭐ (INDISPENSABLE)
```

---

### 📖 **POUR COMPRENDRE - ORIGINAL**

#### 5. [GITHUB_SECRETS_CONFIG.md](./GITHUB_SECRETS_CONFIG.md)
```
(Gardez le GITHUB_SECRETS_CONFIG.md original)

⚠️ ATTENTION: Ce fichier contient template des secrets
   → À LIRE pour comprendre structure
   → À SUPPRIMER après avoir copié valeurs
   → NE JAMAIS commiter dans git

Durée: 15 min à lire
Utilité: ⭐⭐⭐ (Template de référence)
```

---

## 🎯 ORDRE DE LECTURE RECOMMANDÉ

```
JOUR 1 - PRÉPARATION (30 minutes)
├─ 1. Lisez: SECRETS_RETRIEVAL_GUIDE_FR.md
│  └─ Comprendre où obtenir chaque secret
├─ 2. Lisez: SECRETS_FORMAT_EXAMPLES.md
│  └─ Voir à quoi ça doit ressembler
└─ 3. Exécutez: bash generate-ssh-keys.sh
   └─ Générer vos clés SSH

JOUR 1 - INSTALLATION (45 minutes)
├─ 1. Suivez: COMPLETE_SECRETS_SETUP.md
├─ 2. Étape par étape dans GitHub
├─ 3. Ajouter clés publiques sur serveurs
├─ 4. Tester connexions SSH
└─ 5. Vérifier tout dans GitHub Secrets

RÉSULTAT FINAL
└─ Tous les secrets dans GitHub ✅
   Prêt à déployer! 🚀
```

---

## 📊 TABLEAU RÉCAPITULATIF

| Document | Objectif | Durée | Action |
|----------|----------|-------|--------|
| SECRETS_RETRIEVAL_GUIDE_FR.md | Comprendre/Trouver secrets | 20 min | 📖 Lire |
| COMPLETE_SECRETS_SETUP.md | Mettre en place | 45 min | ✅ Exécuter |
| SECRETS_FORMAT_EXAMPLES.md | Vérifier format | 10 min | ✔️ Consulter |
| generate-ssh-keys.sh | Générer clés | 2 min | 🔑 Lancer |
| GITHUB_SECRETS_CONFIG.md | Template original | 15 min | 📝 Supprimer après |

**Temps total:** ~50 minutes

---

## 🆘 QUESTIONS COURANTES

### "Par où je commence?"
```
→ Commencez par: SECRETS_RETRIEVAL_GUIDE_FR.md
  C'est le guide qui explique OÙ obtenir chaque secret
```

### "Comment ajouter les secrets?"
```
→ Suivez: COMPLETE_SECRETS_SETUP.md
  Guide étape par étape avec captures
```

### "À quoi devrait ressembler X?"
```
→ Consultez: SECRETS_FORMAT_EXAMPLES.md
  Voir des exemples concrets de chaque secret
```

### "Comment générer clés SSH?"
```
→ Exécutez: bash /opt/gpti/generate-ssh-keys.sh
  Script automatique qui fait tout pour vous
```

### "Qu'est-ce qu'on fait avec ces clés?"
```
CLÉS PRIVÉES → Mettez dans GitHub Secrets
CLÉS PUBLIQUES → Mettez dans ~/.ssh/authorized_keys sur serveurs
```

---

## ✅ CHECKLIST FINALE

Avant de passer à la suite:

```
Avez-vous lu?
  ✅ SECRETS_RETRIEVAL_GUIDE_FR.md
  ✅ SECRETS_FORMAT_EXAMPLES.md

Avez-vous généré?
  ✅ Clés SSH (via script ou manuel)
  ✅ Noté IPs serveurs
  ✅ Trouvé GitHub tokens

Avez-vous ajouté à GitHub?
  ✅ PRODUCTION_SSH_KEY
  ✅ PRODUCTION_HOST
  ✅ PRODUCTION_USER
  ✅ STAGING_SSH_KEY
  ✅ STAGING_HOST
  ✅ STAGING_USER
  ✅ COPILOT_URL
  ✅ COPILOT_API_KEY
  ✅ SLACK_WEBHOOK_URL
  ✅ PAGERDUTY_INTEGRATION_KEY (optionnel)

Avez-vous mis clés publiques sur serveurs?
  ✅ ~/.ssh/authorized_keys sur production
  ✅ ~/.ssh/authorized_keys sur staging

Avez-vous testé?
  ✅ ssh -i ~/.ssh/production-key ubuntu@<IP> "whoami"
  ✅ ssh -i ~/.ssh/staging-key ubuntu@<IP> "whoami"
  ✅ Tests Slack et PagerDuty (optionnel)

Avez-vous supprimé?
  ✅ GITHUB_SECRETS_CONFIG.md (fichier original)
  ✅ Fichier ".sh" si création manuelle
  ✅ Pas de secrets en local commités
```

---

## 🚀 PROCHAINE ÉTAPE

Une fois TOUS les secrets ajoutés à GitHub:

```bash
# Poussez votre code
git add .
git commit -m "Setup GitHub secrets - ready for deployment"
git push origin develop

# ✅ GitHub Actions va automatiquement:
#    1. Lire les secrets
#    2. Déployer vers staging
#    3. Envoyer notification Slack
#    4. Créer logs dans Prometheus
```

---

## 📞 BESOIN D'AIDE?

```
Pour chaque problème, consultez:

Problème                        | Fichier à lire
─────────────────────────────────────────────────────
"Où obtenir X?"                | SECRETS_RETRIEVAL_GUIDE_FR.md
"À quoi devrait ressembler X?" | SECRETS_FORMAT_EXAMPLES.md
"Comment faire Y étape par étape?" | COMPLETE_SECRETS_SETUP.md
"Script pour générer clés SSH?" | generate-ssh-keys.sh
"Je me suis trompé dans Z"     | COMPLETE_SECRETS_SETUP.md → Dépannage
```

---

## ✨ VOUS ÊTES PRÊT!

Tous les guides sont prêts. Aucune excuse pour ne pas réussir! 🎯

**Commencez par**: SECRETS_RETRIEVAL_GUIDE_FR.md (20 min de lecture)

---

**Créé**: 2026-03-01  
**Version**: 1.0  
**Status**: ✅ **TOUS LES GUIDES DISPONIBLES**
