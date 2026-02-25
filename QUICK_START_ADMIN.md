# 🚀 Démarrage Rapide - Console Admin GTIXT

## ✅ Système entièrement sécurisé

### Pour vous (développeur)

**Accès production (HTTPS)**:
```
https://admin.gtixt.com/admin/login/
```

**Accès local** (développement):
```
http://localhost:3000/admin/login/
```

Credentials de test:
- `alice` / `alice123` (reviewer)
- `bob` / `bob123` (lead_reviewer)  
- `compliance` / `audit123` (auditor)

---

## 🔑 Changer le mot de passe

- UI: `https://admin.gtixt.com/admin/change-password/`
- Obligatoire si le mot de passe a expiré

---

### Pour un collaborateur distant

**1. Créer son compte**:
```bash
cd /opt/gpti/gpti-data-bot

python3 src/gpti_bot/enrichment/create_internal_user.py \
  reviewer \
  nom_collaborateur \
  email@exemple.com \
  MotDePasseSecurise123
```

**2. Lui communiquer**:
- URL: `https://admin.gtixt.com/admin/login/`
- Username: `nom_collaborateur`
- Password: `MotDePasseSecurise123`

**3. Il se connecte**:
1. Ouvre l'URL dans son navigateur
2. Saisit username + password
3. Clique "Sign In"
4. ✅ Accès à la console admin !

---

## 🔒 Protection appliquée

✅ **Pages UI**: Redirection automatique si non authentifié  
✅ **APIs**: Retour 401 si pas de token valide  
✅ **Tokens**: JWT stockés en sessionStorage (24h expiration)  
✅ **Logout**: Bouton disponible en haut à droite  
✅ **Audit**: Tous les accès loggés dans `internal_access_log`

---

## 📚 Documentation complète

- **[ADMIN_ACCESS_GUIDE.md](./ADMIN_ACCESS_GUIDE.md)**: Guide complet pour collaborateurs
- **[INTERNAL_CONSOLE_GUIDE.md](./INTERNAL_CONSOLE_GUIDE.md)**: Documentation technique APIs

---

## 🧪 Test rapide

```bash
# 1. Login
TOKEN=$(curl -s -X POST http://localhost:3000/api/internal/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","password":"alice123"}' | jq -r '.token')

# 2. Vérifier token
curl -s http://localhost:3000/api/internal/auth/me/ \
  -H "Authorization: Bearer $TOKEN" | jq .user.username

# 3. Accéder à la queue
curl -s "http://localhost:3000/api/internal/review-queue/?limit=3" \
  -H "Authorization: Bearer $TOKEN" | jq .meta
```

---

## 🌐 Mise en production

1. **Domaine**: Configurer DNS (`admin.gtixt.com`)
2. **HTTPS**: Certificat SSL (Let's Encrypt)
3. **Nginx**: Reverse proxy vers `localhost:3000`
4. **Firewall**: Restreindre accès par IP (optionnel)
5. **Env vars**: `DATABASE_URL`, `JWT_SECRET` en production

Voir détails dans [ADMIN_ACCESS_GUIDE.md](./ADMIN_ACCESS_GUIDE.md) section "Déploiement en production"

---

**Fait le**: 2026-02-25  
**Status**: ✅ Production Ready
