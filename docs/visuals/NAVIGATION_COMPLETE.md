# 🎯 Navigation et Flux de Données - Guide Complet

## ✅ Modifications Appliquées

### 1. Composant de Navigation Créé

**Fichier:** `/opt/gpti/gpti-site/components/PageNavigation.tsx`

Un composant réutilisable avec navigation entre toutes les pages principales:
- 🏠 **Accueil** → `/`
- 📋 **Liste des Firms** → `/firms`
- 🤖 **Tableau de bord Agents** → `/agents-dashboard`
- 📊 **Phase 2** → `/phase2`
- 💾 **Données** → `/data`

### 2. Navigation Ajoutée aux Pages Existantes

✅ **Pages modifiées:**
- `/pages/firm/[id].tsx` - Page détail d'une firm (route dynamique)
- `/pages/firm.tsx` - Page de liste/profil de firm
- `/pages/agents-dashboard.tsx` - Tableau de bord des agents
- `/pages/phase2.tsx` - Overview Phase 2
- `/pages/data.tsx` - Explorer de données

### 3. Redirection URL Corrigée

**Fichier:** `/opt/gpti/gpti-site/next.config.js`

Ajout d'une redirection automatique:
```
/firm/?id=X  →  /firm/X
```

Cela corrige le problème où la page n'affichait pas les données avec l'URL incorrecte.

---

## 🚀 Comment Tester

### 1. Démarrer le Serveur

```bash
cd /opt/gpti/gpti-site
npm run dev
```

Le serveur démarre sur `http://localhost:3001`

### 2. URLs à Tester

#### ✅ **Page d'Accueil**
```
http://localhost:3001/
```
- Affiche la page d'accueil
- Boutons de navigation en haut

#### ✅ **Liste des Firms**
```
http://localhost:3001/firms
```
- Affiche la liste des 100 firms
- Navigation en haut pour accéder aux autres pages
- Clics sur les firms redirigent vers leur page détail

#### ✅ **Détail d'une Firm (Dynamic Route)**
```
http://localhost:3001/firm/topstep
http://localhost:3001/firm/1
http://localhost:3001/firm/ftmo
```
- Affiche le profil complet de la firm
- Navigation en haut
- Scores, métriques, historique
- Preuve des agents (AgentEvidence)

#### ✅ **Ancienne URL avec Redirection**
```
http://localhost:3001/firm/?id=topstep
```
- Redirige automatiquement vers `/firm/topstep`
- Corrige le problème de données non affichées

#### ✅ **Tableau de Bord Agents**
```
http://localhost:3001/agents-dashboard
```
- Affiche le statut de tous les agents Phase 2
- Navigation en haut
- Santé, performance, tests

#### ✅ **Phase 2 Overview**
```
http://localhost:3001/phase2
```
- Vue d'ensemble des 9 agents
- Navigation en haut
- Architecture et statut

#### ✅ **Explorer de Données**
```
http://localhost:3001/data
```
- Accès aux snapshots
- Navigation en haut
- SHA256, timestamps

---

## 📊 Flux de Données Vérifié

### Architecture Confirmée

```
Seed Data (seed.json - 100 firms)
         ↓
API Routes (/api/*)
         ↓
Pages (utilisant fetch)
         ↓
Composants (affichage)
```

### APIs Utilisées par les Pages

| Page | API Endpoint | Données Récupérées |
|------|--------------|-------------------|
| `/firm/[id]` | `/api/firm?id=X` | Détails complets de la firm |
| `/firm/[id]` | `/api/firm-history?id=X` | Historique des scores |
| `/firm/[id]` | `/api/evidence?firm_id=X` | Preuves des agents |
| `/firms` | `/api/firms` | Liste de toutes les firms |
| `/agents-dashboard` | `/api/agents/health` | Statut des agents |
| `/data` | MinIO direct | Snapshots publics |

### Composants avec Données

| Composant | Props | Source |
|-----------|-------|--------|
| `AgentEvidence` | `firmId` | Fetch `/api/evidence` |
| `IntegrityBeaconHero` | `firmId` | Props parent |
| `ScoreTrajectory` | `history[]` | API firm-history |
| `SnapshotHistory` | `history[]` | API firm-history |

---

## 🔧 Résolution du Problème Initial

### Problème
```
❌ http://localhost:3001/firm/?id=topstep
   → Page vide / 404 / pas de données
```

### Cause
- Next.js utilise des routes dynamiques avec `[id]` dans le nom du fichier
- L'URL avec query param `?id=` n'est pas reconnue par le système de routing
- La page `/pages/firm/[id].tsx` attend `/firm/topstep` et non `/firm/?id=topstep`

### Solution Appliquée
1. **Redirection dans `next.config.js`**
   ```javascript
   {
     source: '/firm/',
     has: [{ type: 'query', key: 'id', value: '(?<firmId>.*)' }],
     destination: '/firm/:firmId',
     permanent: false,
   }
   ```

2. **Navigation claire entre pages**
   - Boutons visibles en haut de chaque page
   - Pas besoin de taper manuellement les URLs

3. **Liens dans les composants**
   - Liste des firms → Liens vers `/firm/[id]`
   - Navigation cohérente partout

---

## 🎨 Interface de Navigation

Le composant `PageNavigation` affiche:

```
┌─────────────────────────────────────────────────────┐
│  🏠 Accueil  📋 Liste des Firms  🤖 Agents  📊 ...  │
└─────────────────────────────────────────────────────┘
```

**Caractéristiques:**
- Design avec gradient moderne (violet-mauve)
- Bouton actif mis en évidence (background blanc)
- Hover effects avec élévation
- Responsive mobile (colonne verticale)
- Icons emoji pour clarté visuelle

---

## 📝 Prochaines Étapes Recommandées

### 1. Vérifier les Données Affichées
```bash
# Ouvrir dans le navigateur
http://localhost:3001/firm/topstep
```
- Vérifier que le score s'affiche
- Vérifier l'historique
- Vérifier les preuves des agents

### 2. Tester la Navigation
- Cliquer sur tous les boutons de navigation
- Vérifier que chaque page charge correctement
- Tester les liens dans les pages (ex: liste firms → détail firm)

### 3. Vérifier les Logs Console
```bash
# Dans le terminal du serveur Next.js
# Chercher ces messages:
[Firm Page] Fetching firm data: id=topstep
[Firm Page] Received data: { firm: {...} }
[Firm Page] Loading complete for firm: TopstepTrader
```

### 4. Vérifier les APIs
```bash
# Tester manuellement les endpoints
curl http://localhost:3001/api/firm?id=topstep
curl http://localhost:3001/api/firms
curl http://localhost:3001/api/agents/health
```

---

## 🐛 Dépannage

### Problème: Navigation n'apparaît pas
**Solution:** Vérifier que le composant est importé
```typescript
import PageNavigation from '../components/PageNavigation';
// ...
<PageNavigation />
```

### Problème: Redirection ne fonctionne pas
**Solution:** Redémarrer le serveur Next.js
```bash
# Ctrl+C pour arrêter
npm run dev  # Redémarrer
```

### Problème: Données ne s'affichent toujours pas
**Vérifications:**
1. Le serveur Next.js tourne-t-il?
2. Les APIs répondent-elles? (tester avec curl)
3. Le fichier `seed.json` existe-t-il?
4. Les variables d'environnement sont-elles correctes?

---

## 📚 Fichiers Modifiés

```
/opt/gpti/gpti-site/
├── components/
│   └── PageNavigation.tsx          [CRÉÉ]
├── pages/
│   ├── firm/
│   │   └── [id].tsx                [MODIFIÉ - Navigation ajoutée]
│   ├── firm.tsx                    [MODIFIÉ - Navigation ajoutée]
│   ├── agents-dashboard.tsx        [MODIFIÉ - Navigation ajoutée]
│   ├── phase2.tsx                  [MODIFIÉ - Navigation ajoutée]
│   └── data.tsx                    [MODIFIÉ - Navigation ajoutée]
└── next.config.js                  [MODIFIÉ - Redirection ajoutée]
```

---

## ✅ Checklist de Validation

- [x] Composant PageNavigation créé
- [x] Navigation ajoutée à `/firm/[id].tsx`
- [x] Navigation ajoutée à `/firm.tsx`
- [x] Navigation ajoutée à `/agents-dashboard.tsx`
- [x] Navigation ajoutée à `/phase2.tsx`
- [x] Navigation ajoutée à `/data.tsx`
- [x] Redirection `/firm/?id=X` → `/firm/X` configurée
- [ ] Serveur démarré et testé
- [ ] URLs testées dans le navigateur
- [ ] Données visibles sur les pages
- [ ] Navigation fonctionnelle entre pages

---

## 🎯 Résumé

**Avant:**
- Pages existaient mais pas de navigation claire
- URL `/firm/?id=` ne fonctionnait pas (erreur de routing)
- Utilisateur ne pouvait pas naviguer facilement

**Après:**
- Navigation claire en haut de chaque page
- Redirection automatique des URLs incorrectes
- Flux de données confirmé: Seed → API → Pages → UI
- Expérience utilisateur cohérente et fluide

**Prochaine action:** Démarrer le serveur et tester dans le navigateur!
