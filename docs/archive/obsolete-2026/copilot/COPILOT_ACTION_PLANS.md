# 📋 PLANS D'ACTION - Copilot AI GTIXT

**Date**: 27 février 2026  
**Contexte**: Déploiement du Copilot AI débridé avec capacités avancées

---

## 🏠 PLAN D'ACTION INTERNE (GTIXT)

### 🔴 PRIORITÉ 1: Sécurité (J+0 à J+3)

#### Tâche 1.1: Path Validation
**Objectif**: Empêcher l'accès à des fichiers sensibles  
**Effort**: 2h  
**Assigné**: DevOps Lead

**Implémentation**:
```typescript
// File: app/api/admin/copilot/route.ts (ligne ~85)

const ALLOWED_PATHS = [
  '/opt/gpti/gpti-site/app',
  '/opt/gpti/gpti-site/components',
  '/opt/gpti/gpti-site/lib',
  '/opt/gpti/gpti-site/public',
  '/opt/gpti/*.md',  // Documentation
];

const FORBIDDEN_PATTERNS = [
  '.env',
  'secrets',
  'node_modules',
  '.git',
  'prisma/migrations',
];

const isPathSafe = (filePath: string): { safe: boolean; reason?: string } => {
  const fullPath = path.resolve('/opt/gpti', filePath);
  
  // Check if in allowed paths
  const isAllowed = ALLOWED_PATHS.some(allowed => 
    fullPath.startsWith(path.resolve(allowed))
  );
  
  if (!isAllowed) {
    return { safe: false, reason: 'Path not in allowed directories' };
  }
  
  // Check forbidden patterns
  const hasForbidden = FORBIDDEN_PATTERNS.some(pattern => 
    fullPath.includes(pattern)
  );
  
  if (hasForbidden) {
    return { safe: false, reason: 'Path contains forbidden pattern' };
  }
  
  return { safe: true };
};

// Update readWorkspaceFile
const readWorkspaceFile = async (filePath: string): Promise<string> => {
  const safetyCheck = isPathSafe(filePath);
  
  if (!safetyCheck.safe) {
    throw new Error(`Access denied: ${safetyCheck.reason}`);
  }
  
  const fullPath = path.join('/opt/gpti', filePath);
  const content = await fs.readFile(fullPath, 'utf-8');
  return content;
};
```

**Tests**:
```bash
# Test 1: Fichier autorisé
curl -X POST http://localhost:3000/api/admin/copilot/ \
  -d '{"action": {"type": "read_file", "params": {"filePath": "gpti-site/app/page.tsx"}}}'
# Expected: ✅ File content returned

# Test 2: Fichier interdit (.env)
curl -X POST http://localhost:3000/api/admin/copilot/ \
  -d '{"action": {"type": "read_file", "params": {"filePath": "gpti-site/.env"}}}'
# Expected: ❌ Access denied

# Test 3: Path traversal
curl -X POST http://localhost:3000/api/admin/copilot/ \
  -d '{"action": {"type": "read_file", "params": {"filePath": "../../../etc/passwd"}}}'
# Expected: ❌ Access denied
```

---

#### Tâche 1.2: File Size Limits
**Objectif**: Éviter le blocage sur gros fichiers  
**Effort**: 1h  
**Assigné**: Backend Dev

**Implémentation**:
```typescript
const MAX_FILE_SIZE = 500 * 1024; // 500 KB

const readWorkspaceFile = async (filePath: string): Promise<string> => {
  const safetyCheck = isPathSafe(filePath);
  if (!safetyCheck.safe) throw new Error(safetyCheck.reason);
  
  const fullPath = path.join('/opt/gpti', filePath);
  
  // Check file size before reading
  const stats = await fs.stat(fullPath);
  
  if (stats.size > MAX_FILE_SIZE) {
    throw new Error(`File too large: ${stats.size} bytes (max: ${MAX_FILE_SIZE})`);
  }
  
  const content = await fs.readFile(fullPath, 'utf-8');
  return content;
};
```

---

#### Tâche 1.3: Command Sanitization
**Objectif**: Sécuriser les commandes shell  
**Effort**: 2h  
**Assigné**: Security Engineer

**Implémentation**:
```typescript
const ALLOWED_COMMANDS = ['diff', 'wc', 'head', 'tail', 'grep'];

const sanitizeCommand = (cmd: string): { safe: boolean; reason?: string } => {
  const firstWord = cmd.trim().split(/\s+/)[0];
  
  if (!ALLOWED_COMMANDS.includes(firstWord)) {
    return { safe: false, reason: `Command '${firstWord}' not allowed` };
  }
  
  // Check for dangerous patterns
  const dangerousPatterns = ['>', '<', '|', ';', '&', '`', '$'];
  const hasDangerous = dangerousPatterns.some(pattern => cmd.includes(pattern));
  
  if (hasDangerous) {
    return { safe: false, reason: 'Command contains dangerous operators' };
  }
  
  return { safe: true };
};

const generateDiff = async (file1: string, file2: string): Promise<string> => {
  // Validate paths
  if (!isPathSafe(file1).safe || !isPathSafe(file2).safe) {
    throw new Error('Invalid file paths');
  }
  
  // Escape paths for shell
  const escapedFile1 = file1.replace(/'/g, "'\\''");
  const escapedFile2 = file2.replace(/'/g, "'\\''");
  
  const command = `diff -u '${escapedFile1}' '${escapedFile2}'`;
  
  const safety = sanitizeCommand(command);
  if (!safety.safe) throw new Error(safety.reason);
  
  const { stdout } = await execAsync(command);
  return stdout;
};
```

---

### 🟡 PRIORITÉ 2: Rate Limiting & Quotas (J+3 à J+5)

#### Tâche 2.1: Rate Limiting par IP
**Objectif**: Empêcher l'abus de l'API  
**Effort**: 3h  
**Assigné**: Backend Dev

**Implémentation**:
```typescript
// File: lib/rate-limiter.ts

import { LRUCache } from 'lru-cache';

interface RateLimitEntry {
  count: number;
  resetAt: number;
}

const rateLimitCache = new LRUCache<string, RateLimitEntry>({
  max: 1000,
  ttl: 1000 * 60 * 60, // 1 hour
});

export const checkRateLimit = (
  identifier: string,
  maxRequests: number = 50,
  windowMs: number = 60 * 60 * 1000 // 1 hour
): { allowed: boolean; remaining: number; resetAt: number } => {
  const now = Date.now();
  const entry = rateLimitCache.get(identifier);
  
  if (!entry || entry.resetAt < now) {
    const newEntry = {
      count: 1,
      resetAt: now + windowMs,
    };
    rateLimitCache.set(identifier, newEntry);
    return { allowed: true, remaining: maxRequests - 1, resetAt: newEntry.resetAt };
  }
  
  if (entry.count >= maxRequests) {
    return { allowed: false, remaining: 0, resetAt: entry.resetAt };
  }
  
  entry.count += 1;
  rateLimitCache.set(identifier, entry);
  
  return { allowed: true, remaining: maxRequests - entry.count, resetAt: entry.resetAt };
};

// Usage in route.ts
export async function POST(request: NextRequest) {
  const ip = request.headers.get('x-forwarded-for') || 'unknown';
  const rateLimit = checkRateLimit(ip, 50); // 50 requests/hour
  
  if (!rateLimit.allowed) {
    return NextResponse.json(
      { 
        error: 'Rate limit exceeded',
        resetAt: new Date(rateLimit.resetAt).toISOString()
      },
      { status: 429 }
    );
  }
  
  // ... rest of the handler
}
```

---

#### Tâche 2.2: Token Budget
**Objectif**: Limiter les coûts OpenAI  
**Effort**: 2h  
**Assigné**: Backend Dev

**Implémentation**:
```typescript
// Track token usage per user/session
const tokenUsageCache = new LRUCache<string, number>({
  max: 1000,
  ttl: 1000 * 60 * 60 * 24, // 24 hours
});

const MAX_TOKENS_PER_DAY = 50000; // ~$1 at GPT-4 Turbo prices

export async function POST(request: NextRequest) {
  const userId = request.headers.get('x-user-id') || 'anonymous';
  const currentUsage = tokenUsageCache.get(userId) || 0;
  
  if (currentUsage >= MAX_TOKENS_PER_DAY) {
    return NextResponse.json(
      { error: 'Daily token quota exceeded' },
      { status: 429 }
    );
  }
  
  // ... make OpenAI call
  
  const tokensUsed = completion.usage?.total_tokens || 0;
  tokenUsageCache.set(userId, currentUsage + tokensUsed);
  
  return NextResponse.json({
    success: true,
    response,
    usage: completion.usage,
    quotaRemaining: MAX_TOKENS_PER_DAY - (currentUsage + tokensUsed),
  });
}
```

---

### 🟢 PRIORITÉ 3: Monitoring & Logging (J+5 à J+7)

#### Tâche 3.1: Audit Logs
**Objectif**: Tracer toutes les actions sensibles  
**Effort**: 3h  
**Assigné**: DevOps Lead

**Schema Prisma**:
```prisma
model AdminCopilotLogs {
  id          String   @id @default(cuid())
  action      String   // 'read_file', 'generate_diff', 'message'
  userId      String?
  ipAddress   String?
  filePath    String?
  message     String?  @db.Text
  tokensUsed  Int?
  success     Boolean
  errorMsg    String?
  metadata    Json?
  createdAt   DateTime @default(now())
  
  @@index([userId])
  @@index([action])
  @@index([createdAt])
}
```

**Implémentation**:
```typescript
const logCopilotAction = async (data: {
  action: string;
  userId?: string;
  ipAddress?: string;
  filePath?: string;
  message?: string;
  tokensUsed?: number;
  success: boolean;
  errorMsg?: string;
  metadata?: any;
}) => {
  await prisma.adminCopilotLogs.create({ data });
};

// In route handler
export async function POST(request: NextRequest) {
  const ip = request.headers.get('x-forwarded-for') || 'unknown';
  const userId = request.headers.get('x-user-id') || 'anonymous';
  
  try {
    // ... process request
    
    await logCopilotAction({
      action: action?.type || 'message',
      userId,
      ipAddress: ip,
      filePath: action?.params?.filePath,
      message,
      tokensUsed: completion.usage?.total_tokens,
      success: true,
    });
    
    return NextResponse.json({ success: true, ... });
  } catch (error) {
    await logCopilotAction({
      action: action?.type || 'message',
      userId,
      ipAddress: ip,
      message,
      success: false,
      errorMsg: String(error),
    });
    
    throw error;
  }
}
```

---

#### Tâche 3.2: Métriques Prometheus
**Objectif**: Monitorer les performances  
**Effort**: 2h  
**Assigné**: DevOps

**Implémentation**:
```typescript
// File: lib/metrics.ts
import { Counter, Histogram } from 'prom-client';

export const copilotRequestsTotal = new Counter({
  name: 'copilot_requests_total',
  help: 'Total copilot requests',
  labelNames: ['action_type', 'status'],
});

export const copilotRequestDuration = new Histogram({
  name: 'copilot_request_duration_seconds',
  help: 'Copilot request duration',
  labelNames: ['action_type'],
  buckets: [0.1, 0.5, 1, 2, 5, 10],
});

export const copilotTokensUsed = new Counter({
  name: 'copilot_tokens_used_total',
  help: 'Total tokens used',
  labelNames: ['model'],
});

// Usage
const end = copilotRequestDuration.startTimer({ action_type: action?.type || 'message' });

try {
  // ... make request
  
  copilotRequestsTotal.inc({ action_type: action?.type, status: 'success' });
  copilotTokensUsed.inc({ model: 'gpt-4-turbo' }, tokensUsed);
} catch (error) {
  copilotRequestsTotal.inc({ action_type: action?.type, status: 'error' });
} finally {
  end();
}
```

---

### 🔵 PRIORITÉ 4: Interface UI (J+7 à J+14)

#### Tâche 4.1: File Browser
**Objectif**: Sélecteur de fichiers graphique  
**Effort**: 8h  
**Assigné**: Frontend Dev

**Wireframe**:
```
┌─────────────────────────────────────┐
│ 📖 Read File                        │
├─────────────────────────────────────┤
│ 📁 gpti-site/                       │
│   ├─ 📁 app/                        │
│   │  ├─ 📁 admin/                   │
│   │  │  ├─ 📄 page.tsx           ✓  │
│   │  │  └─ 📁 copilot/              │
│   │  │     └─ 📄 page.tsx        ✓  │
│   │  └─ 📄 layout.tsx             ✓  │
│   ├─ 📁 components/                 │
│   └─ 📁 lib/                        │
│                                      │
│ Selected: app/admin/copilot/page.tsx│
│ [Read File]  [Cancel]               │
└─────────────────────────────────────┘
```

**Composant React**:
```tsx
// components/FileBrowser.tsx
export function FileBrowser({ onSelect }: { onSelect: (path: string) => void }) {
  const [files, setFiles] = useState<FileTree>({});
  const [selectedPath, setSelectedPath] = useState('');
  
  const loadDirectory = async (dir: string) => {
    const res = await fetch('/api/admin/copilot/', {
      method: 'POST',
      body: JSON.stringify({
        action: { type: 'list_files', params: { directory: dir } }
      })
    });
    const data = await res.json();
    return data.actionResult.files;
  };
  
  return (
    <div className="file-browser">
      <TreeView data={files} onSelect={setSelectedPath} />
      <button onClick={() => onSelect(selectedPath)}>
        Read File
      </button>
    </div>
  );
}
```

---

#### Tâche 4.2: Diff Viewer
**Objectif**: Visualisation colorée des diffs  
**Effort**: 4h  
**Assigné**: Frontend Dev

**Package**: `react-diff-viewer-continued`

```tsx
import ReactDiffViewer from 'react-diff-viewer-continued';

function DiffDisplay({ diff }: { diff: string }) {
  const [oldCode, newCode] = parseDiff(diff);
  
  return (
    <ReactDiffViewer
      oldValue={oldCode}
      newValue={newCode}
      splitView={true}
      useDarkTheme={true}
      showDiffOnly={false}
    />
  );
}
```

---

#### Tâche 4.3: Action Buttons
**Objectif**: Boutons contextuels pour actions rapides  
**Effort**: 2h  
**Assigné**: Frontend Dev

```tsx
// Dans copilot/page.tsx
{message.actions?.map(action => (
  <button
    key={action.type}
    onClick={() => executeAction(action)}
    className="action-button"
  >
    {action.label}
  </button>
))}
```

---

## 🌐 PLAN D'ACTION EXTERNE

### 📚 Phase 1: Documentation (Semaine 1)

#### Livrable 1.1: Guide Utilisateur
**Format**: Markdown + Vidéo  
**Contenu**:
- Introduction au Copilot AI
- Exemples de prompts efficaces
- Liste des capacités
- FAQ

**Structure**:
```markdown
# Guide Utilisateur - Copilot AI GTIXT

## 🚀 Démarrage Rapide

### Premiers Prompts
1. "Lis le fichier app/admin/page.tsx et résume-le"
2. "Propose un patch pour améliorer les performances"
3. "Crée un plan d'action pour ajouter une nouvelle fonctionnalité"

## 📖 Capacités Avancées

### Lecture de Fichiers
**Prompt**: "Lis le fichier [path] et analyse-le"
**Exemple**: ...

### Génération de Patches
**Prompt**: "Propose un patch pour corriger [problème] dans [fichier]"
**Exemple**: ...

## 💡 Tips & Astuces

### Mode Agent
Activez le mode agent pour des réponses plus créatives:
- Toggle "🤖 Agent Mode" dans l'interface
- Le copilot prendra plus d'initiatives

### Contexte Système
Le copilot a accès automatiquement à:
- Nombre de crawls actifs
- Status des jobs
- Alertes système
```

---

#### Livrable 1.2: Tutoriel Vidéo
**Durée**: 5-7 minutes  
**Contenu**:
1. Introduction (30s)
2. Interface copilot (1min)
3. Exemple: Lire un fichier (1min 30s)
4. Exemple: Générer un patch (2min)
5. Exemple: Plan d'action (1min 30s)
6. Tips & Tricks (1min)

---

### 🔌 Phase 2: Intégrations (Semaine 2-3)

#### Intégration 2.1: GitHub Actions
**Objectif**: Review automatique des PRs  
**Fichier**: `.github/workflows/copilot-review.yml`

```yaml
name: Copilot AI Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Get changed files
        id: changed-files
        uses: tj-actions/changed-files@v40
        
      - name: AI Review
        run: |
          for file in ${{ steps.changed-files.outputs.all_changed_files }}; do
            curl -X POST ${{ secrets.COPILOT_URL }}/api/admin/copilot/ \
              -H "Authorization: Bearer ${{ secrets.COPILOT_TOKEN }}" \
              -H "Content-Type: application/json" \
              -d "{
                \"message\": \"Review this file for issues and improvements: $(cat $file)\",
                \"agentMode\": true
              }" > review_$file.txt
          done
          
      - name: Comment on PR
        uses: actions/github-script@v6
        with:
          script: |
            const reviews = require('fs').readdirSync('.').filter(f => f.startsWith('review_'));
            let comment = '## 🤖 Copilot AI Review\n\n';
            reviews.forEach(file => {
              const content = require('fs').readFileSync(file, 'utf8');
              comment += `### ${file}\n${content}\n\n`;
            });
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });
```

---

#### Intégration 2.2: Slack Bot
**Objectif**: Copilot accessible depuis Slack  
**Tech Stack**: Bolt.js + Slack API

```typescript
// slack-bot.ts
import { App } from '@slack/bolt';

const app = new App({
  token: process.env.SLACK_BOT_TOKEN,
  signingSecret: process.env.SLACK_SIGNING_SECRET,
});

app.message(/^!copilot (.+)/, async ({ message, say }) => {
  const prompt = message.text.replace('!copilot ', '');
  
  const response = await fetch('http://localhost:3000/api/admin/copilot/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: prompt }),
  });
  
  const data = await response.json();
  
  await say({
    blocks: [
      {
        type: 'section',
        text: { type: 'mrkdwn', text: `🤖 *Copilot AI*\n\n${data.response}` }
      },
      ...(data.actions || []).map(action => ({
        type: 'actions',
        elements: [{
          type: 'button',
          text: { type: 'plain_text', text: action.label },
          action_id: `copilot_${action.type}`,
        }]
      }))
    ]
  });
});

app.start(3001);
```

**Usage Slack**:
```
!copilot Lis le fichier app/admin/page.tsx
!copilot Crée un plan d'action pour la prochaine release
!copilot Quelle est la santé du système ?
```

---

#### Intégration 2.3: VSCode Extension (Future)
**Objectif**: Copilot en IDE  
**Effort**: 40h (Sprint dédié)

**Fonctionnalités**:
- Sélectionner du code → Clic droit → "Ask Copilot"
- Commande Palette: "GTIXT: Ask Copilot"
- Inline suggestions
- Diff preview avant d'appliquer patches

---

### 🌍 Phase 3: API Publique (Semaine 4-5)

#### Objectif
Permettre aux développeurs externes d'utiliser le Copilot

#### Authentification
```typescript
// middleware/auth.ts
export const validateApiKey = async (apiKey: string): Promise<boolean> => {
  const key = await prisma.apiKeys.findUnique({ where: { key: apiKey } });
  return key && key.active && key.expiresAt > new Date();
};

// Usage
export async function POST(request: NextRequest) {
  const apiKey = request.headers.get('X-API-Key');
  
  if (!apiKey || !(await validateApiKey(apiKey))) {
    return NextResponse.json({ error: 'Invalid API key' }, { status: 401 });
  }
  
  // ... rest of handler
}
```

#### Documentation OpenAPI
```yaml
openapi: 3.0.0
info:
  title: GTIXT Copilot AI API
  version: 2.0.0

paths:
  /api/admin/copilot/:
    post:
      summary: Send message to Copilot
      security:
        - ApiKeyAuth: []
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                message:
                  type: string
                agentMode:
                  type: boolean
                context:
                  type: object
      responses:
        200:
          description: Success
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                  response:
                    type: string
                  actions:
                    type: array
                  usage:
                    type: object

components:
  securitySchemes:
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
```

---

## 📊 TIMELINE GLOBAL

```
Semaine 1 (J1-J7):
├─ Sécurité (Path validation, limits)          [CRITIQUE]
├─ Documentation utilisateur                    [IMPORTANT]
└─ Tests sécurité                               [CRITIQUE]

Semaine 2 (J8-J14):
├─ Rate limiting & quotas                       [IMPORTANT]
├─ Monitoring & logging                         [IMPORTANT]
├─ Interface UI (file browser)                  [NICE-TO-HAVE]
└─ Tutoriel vidéo                               [IMPORTANT]

Semaine 3 (J15-J21):
├─ GitHub Actions intégration                   [NICE-TO-HAVE]
├─ Slack bot                                    [NICE-TO-HAVE]
└─ Tests end-to-end                             [IMPORTANT]

Semaine 4-5 (J22-J35):
├─ API publique (si besoin)                     [FUTURE]
├─ VSCode extension (exploration)               [FUTURE]
└─ Métriques business                           [IMPORTANT]
```

---

## ✅ CHECKLIST DE VALIDATION

### Avant Déploiement Production
- [ ] Path validation implémentée et testée
- [ ] File size limits configurés
- [ ] Command sanitization active
- [ ] Rate limiting fonctionnel
- [ ] Token quotas configurés
- [ ] Audit logging en place
- [ ] Métriques Prometheus actives
- [ ] Documentation utilisateur publiée
- [ ] Tests de sécurité passés
- [ ] Load testing effectué (100 req/s)
- [ ] Rollback plan documenté
- [ ] Alerte PagerDuty configurée
- [ ] Backup des données de logs
- [ ] GDPR compliance vérifiée

### Post-Déploiement (Semaine 1)
- [ ] Monitoring actif 24/7
- [ ] Zero incident de sécurité
- [ ] Taux d'erreur < 1%
- [ ] P95 latency < 2s
- [ ] Coûts OpenAI sous budget
- [ ] Feedback utilisateurs positif (>80%)
- [ ] Documentation à jour

---

## 🎯 KPIs

| Métrique | Target | Méthode |
|----------|--------|---------|
| **Adoption** | 70% des admins utilisent le copilot | Analytics |
| **Satisfaction** | >80% feedback positif | Survey |
| **Performance** | P95 < 2s | Prometheus |
| **Disponibilité** | 99.9% uptime | Monitoring |
| **Sécurité** | 0 incident | Audit logs |
| **Coûts** | <$100/jour OpenAI | Token tracking |
| **Productivité** | -30% temps de debug | Time tracking |

---

*Plans d'action créés le 27 février 2026*  
*Révision: Hebdomadaire*  
*Owner: CTO & DevOps Lead*
