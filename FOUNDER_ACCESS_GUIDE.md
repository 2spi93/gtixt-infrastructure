# Guide Fondateur - Admin Console GTIXT

## 🎯 Accès Fondateur

**Connexion:**
- **URL:** `https://admin.gtixt.com/admin/login/`
- **Username:** `founder`
- **Password:** `FounderSecure2026$9x`
- **Rôle:** `admin` (accès complet)

> ⚠️ **IMPORTANT:** Changez ce mot de passe immédiatement après votre première connexion.

---

## 📋 Comptes Admin Existants

| Username   | Rôle          | Email | Permissions |
|------------|---------------|-------|-------------|
| **founder** | **admin**  | founder@gtixt.internal | ✅ Complet: Créer/modifier/supprimer utilisateurs, changer policies, 2FA |
| alice      | reviewer   | alice@gpti.internal | Voir queue, approuver/rejeter candidats |
| bob        | lead_reviewer | bob@gpti.internal | + Override, escalade, changement statut |
| compliance | auditor | audit@gpti.internal | Lecture seule + accès audit trails |

---

## 🔐 Sécurité - Politique Stricte

**Configuration actuelle** (depuis 2026-02-25):
- **TTL Session:** 24 heures
- **Longueur mot de passe:** **14 caractères minimum**
- **Caractères requis:** Majuscule + Minuscule + Chiffre + **SYMBOLE**
- **Rotation de mot de passe:** **90 jours**
- **Initial password reset required:** Oui

**Exemple mot de passe conforme:**
```
MySecurePass2026!@#
```

Les 4 premiers caractères doivent respecter la policy pour chaque nouveau mot de passe.

---

## 🛡️ 2FA TOTP (Two-Factor Authentication)

### Setup 2FA

1. Allez à `https://admin.gtixt.com/admin/setup-2fa/`
2. Cliquez **"🔐 Start 2FA Setup"**
3. **Scannez le QR code** avec votre authenticator:
   - Google Authenticator
   - Microsoft Authenticator
   - Authy
   - 1Password
   - Autre (iOS/Android compatible TOTP)

4. Entrez le code **6 chiffres** généré par l'app
5. Cliquez **"✅ Verify & Enable 2FA"**
6. **2FA est maintenant activé!**

### Login avec 2FA

1. Entrez username + password normalement
2. Le système demande: **"Please provide TOTP code"**
3. Ouvrez l'authenticator et entrez les 6 chiffres actuels
4. L'accès est accordé si le code est valide

### Désactiver 2FA

- Page setup-2fa > **"❌ Disable 2FA"**
- Nécessite confirmation

---

## 👥 Gestion des Utilisateurs

### URL Admin
`https://admin.gtixt.com/admin/users/` (admin seulement)

### Actions Disponibles

#### 1. Créer un nouvel utilisateur
- Remplissez: **Username, Email (optionnel), Rôle, Mot de passe temporaire**
- **Rôles:** reviewer, lead_reviewer, auditor, admin
- L'utilisateur devra changer le mot de passe à la première connexion (car il vient de vous)

#### 2. Réinitialiser un mot de passe
- Cherchez l'utilisateur dans la table
- Bouton **"Reset Password"**
- Entrez un nouveau mot de passe temporaire
- Informez l'utilisateur du nouveau mot de passe (via email séparé)

#### 3. Changer un rôle
- Sélectionnez un nouveau rôle dans le dropdown
- Le changement est immédiat

#### 4. Désactiver/Activer un compte
- Bouton **"Disable User"** ou **"Enable User"**
- Utilisateur ne peut pas se connecter si désactivé

---

## 🔄 Workflow de Changement de Mot de Passe

### Self-Service (Utilisateur)
1. Connectez-vous avec ancien mot de passe
2. Allez à `https://admin.gtixt.com/admin/change-password/`
3. Entrez **ancien mot de passe + nouveau mot de passe (2x)**
4. Le nouveau mot de passe doit respecter la policy stricte
5. **Les anciennes sessions sont révoquées** après le changement

### Force Change (Admin)
1. Utilisateur se connecte
2. S'il a un rot  ation obligatoire ou mot de passe expiré:
   - **Redirection automatique** vers `/admin/change-password/`
   - Doit changer avant d'accéder au dashboard
3. Le système enregistre la date du changement

---

## 📊 Audit Trails

### Accès Au Journal
```sql
SELECT u.username, l.action, l.occurred_at, l.ip_address, l.details
FROM internal_access_log l
LEFT JOIN internal_users u ON u.id = l.user_id
ORDER BY l.occurred_at DESC
LIMIT 100;
```

### Actions Enregistrées
- `login` - Connexion (include username, 2FA utilisé)
- `password_change` - Changement de mot de passe
- `2fa_enabled`, `2fa_disabled` - 2FA modification
- `create_user`, `list_users`, `update_role`, `reset_password` - Actions admin
- Chaque entrée inclut: **user_id, ip_address, timestamp**

---

## 🔧 Configuration Avancée

### Variables d'Environnement (.env)

Modifiez `/opt/gpti/gpti-site/.env.production.local`:

```bash
# Session TTL (hours)
INTERNAL_SESSION_TTL_HOURS=24

# Password Policy
INTERNAL_PASSWORD_MIN_LENGTH=14                    # Minimum chars
INTERNAL_PASSWORD_REQUIRE_UPPER=true               # Uppercase
INTERNAL_PASSWORD_REQUIRE_LOWER=true               # Lowercase
INTERNAL_PASSWORD_REQUIRE_NUMBER=true              # Number
INTERNAL_PASSWORD_REQUIRE_SYMBOL=true              # Symbol (!@#$%^&*)
INTERNAL_PASSWORD_ROTATION_DAYS=90                 # Force change every N days
INTERNAL_PASSWORD_ROTATION_REQUIRE_INITIAL=true    # First login must change
```

**Après modification:** `pm2 restart all`

---

## 🚀 Points de Terminaison API

### Login avec 2FA
```bash
POST /api/internal/auth/login/
{
  "username": "founder",
  "password": "FounderSecure2026$9x",
  "totp": "123456"  # Optional, required si 2FA activé
}
```

### Setup 2FA (Générer QR)
```bash
POST /api/internal/auth/setup-2fa/
# Retour: { secret, qrCode }
```

### Activer 2FA
```bash
POST /api/internal/auth/enable-2fa/
{
  "code": "123456"  # Code TOTP
}
```

### Désactiver 2FA
```bash
POST /api/internal/auth/disable-2fa/
```

### Créer Utilisateur
```bash
POST /api/internal/users/
{
  "username": "jean",
  "email": "jean@gpti.internal",
  "role": "reviewer",
  "password": "SecurePass123!"
}
```

### Changer Rôle / Désactiver
```bash
PATCH /api/internal/users/[id]
{
  "role": "lead_reviewer"    # OR
  "active": false            # Désactiver compte
}
```

---

## 🔗 Quick Links

| Page | URL |
|------|-----|
| Login | `https://admin.gtixt.com/admin/login/` |
| Change Password | `https://admin.gtixt.com/admin/change-password/` |
| User Management | `https://admin.gtixt.com/admin/users/` |
| Setup 2FA | `https://admin.gtixt.com/admin/setup-2fa/` |
| Review Queue | `https://admin.gtixt.com/admin/review-queue/` |

---

## ⚠️ Typos Corrections

La page login accepte aussi:
- `/loging` → Redirige automatiquement vers `/admin/login/` (pour les typos)

---

## 🆘 Support & Troubleshooting

**Password ne respecte pas la policy?**
- Minimum 14 caractères
- Au moins 1 MAJUSCULE
- Au moins 1 minuscule
- Au moins 1 chiffre  
- Au moins 1 symbole (!@#$%^&* etc)

**2FA Code invalide?**
- Vérifiez que l'horloge du téléphone est synchronisée
- Attendez quelques secondes, les codes changent tous les 30s
- Utilisez les 2 derniers codes (window: 2)

**Session expirée?**
- Reconnectez-vous
- Le serveur génère une nouvelle session (24h de validité)
- Les anciennes sessions sont invalidées

**Database issues?**
```bash
export DATABASE_URL="postgresql://gpti:superpassword@localhost:5434/gpti"
psql $DATABASE_URL -c "SELECT u.username, u.role, u.active FROM internal_users;"
```

---

**Dernière mise à jour:** 2026-02-25
**Version Admin:** 2.0 (avec 2FA TOTP & Strict Password Policy)
