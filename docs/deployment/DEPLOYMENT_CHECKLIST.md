# 🚀 Deployment Checklist - Production Ready

## ✅ Frontend (gpti-site)

### Step 1: Prepare Environment
```bash
cd /opt/gpti/gpti-site
cp .env.production.local.example .env.production.local
# Edit with production values:
nano .env.production.local
```

### Step 2: Verify Build
```bash
npm run build
# Should complete successfully with no TypeScript errors
```

### Step 3: Deploy to Netlify/Vercel
```bash
# Option A: Netlify
netlify deploy --prod
# Add env vars: Site Settings → Environment Variables

# Option B: Vercel
vercel --prod
# Add env vars: Project Settings → Environment Variables
```

### Required Variables for Production
```bash
NEXT_PUBLIC_LATEST_POINTER_URL=https://data.gtixt.com/gpti-snapshots/universe_v0.1_public/_public/latest.json
NEXT_PUBLIC_MINIO_PUBLIC_ROOT=https://data.gtixt.com/gpti-snapshots/
SLACK_WEBHOOK_URL=CHANGE_ME
```

---

## ✅ Backend Bot (gpti-data-bot)

### Step 1: Prepare Environment
```bash
cd /opt/gpti/gpti-data-bot
cp .env.production.local.example .env.production.local
# Edit with production values:
nano .env.production.local
```

### Step 2: Test Locally
```bash
# Load production env
set -a; source .env.production.local; set +a

# Run snapshot pipeline
python -m gpti_bot.cli export-snapshot
python -m gpti_bot.cli export-snapshot --public
```

### Step 3: Deploy to Production Server
```bash
# Via PM2
pm2 start ecosystem.config.js --env production

# Via Docker
docker-compose -f infra/docker-compose.yml up -d

# Via systemd
sudo systemctl start gpti-bot
```

### Required Variables for Production
```bash
DATABASE_URL=postgresql://gpti:gpti@postgres:5432/gpti
MINIO_ENDPOINT=https://minio.example.com
MINIO_ACCESS_KEY=CHANGE_ME
MINIO_SECRET_KEY=CHANGE_ME
SLACK_PIPELINE_WEBHOOK=CHANGE_ME
SLACK_VALIDATION_WEBHOOK=CHANGE_ME
SLACK_WEBHOOK_URL=CHANGE_ME
SMTP_HOST=smtp-relay.brevo.com
SMTP_USER=CHANGE_ME
SMTP_PASS=CHANGE_ME
BREVO_API_KEY=CHANGE_ME
PREFECT_API_URL=http://localhost:4200/api
```

---

## ✅ Infrastructure (gpti-data-bot/infra)

### Step 1: Prepare Environment
```bash
cd /opt/gpti/gpti-data-bot/infra
cp .env.production.local.example .env.production.local
# Edit with production values:
nano .env.production.local
```

### Step 2: Start Docker Services
```bash
# Load env
set -a; source .env.production.local; set +a

# Start all services (Postgres, MinIO, Prefect)
docker-compose up -d

# Verify
docker-compose ps
curl http://localhost:9000/minio/health/live  # MinIO
curl http://localhost:5432                      # Postgres
curl http://localhost:4200/api/health          # Prefect
```

### Step 3: Health Checks
```bash
# Check all services
./doctor.sh

# Check data flow
curl -s http://localhost:9000/minio/health/live | jq .

# Check Prefect
curl -s http://localhost:4200/api/collections/ | jq .
```

### Required Variables for Production
```bash
POSTGRES_PASSWORD=CHANGE_ME
POSTGRES_USER=gpti
DATABASE_URL=postgresql://gpti:gpti@postgres:5432/gpti
MINIO_ROOT_USER=CHANGE_ME
MINIO_ROOT_PASSWORD=CHANGE_ME
MINIO_ACCESS_KEY=CHANGE_ME
MINIO_SECRET_KEY=CHANGE_ME
PREFECT_API_KEY=CHANGE_ME
SLACK_VALIDATION_WEBHOOK=CHANGE_ME
```

---

## 📊 Environment Structure

```
Local Development:
  gpti-site/.env.local              ✅ (git ignored)
  gpti-data-bot/.env.local          ✅ (git ignored)
  gpti-data-bot/infra/.env.local    ✅ (git ignored)

Production (Examples):
  gpti-site/.env.production.local.example
  gpti-data-bot/.env.production.local.example
  gpti-data-bot/infra/.env.production.local.example

Public Templates (Templates only):
  gpti-site/.env.example
  gpti-data-bot/.env
  gpti-data-bot/infra/.env
```

---

## 🔒 Security Checklist

- [ ] All `.env.local` files are in `.gitignore`
- [ ] No secrets in `.env` (public template only)
- [ ] All production `.env.production.local` files are NOT committed
- [ ] Slack webhooks are rotated annually
- [ ] Database passwords are strong (>16 chars, mixed)
- [ ] SMTP credentials are from Brevo account
- [ ] MinIO root credentials are changed from defaults
- [ ] No hardcoded secrets in source code

---

## 🧪 Testing Before Production

### Test Frontend
```bash
cd /opt/gpti/gpti-site
npm run build
npm run preview  # Test build locally
# Visit http://localhost:3000/rankings
# Verify data loads from MinIO
```

### Test Backend
```bash
cd /opt/gpti/gpti-data-bot
python -c "from dotenv import load_dotenv; load_dotenv('.env.production.local'); import os; print(f'DB: {os.getenv(\"DATABASE_URL\")}'); print(f'MinIO: {os.getenv(\"MINIO_ENDPOINT\")}')"
# Should output real production URLs
```

### Test Data Flow
```bash
# Start backend
python -m gpti_data.main

# Check Slack alert (test)
curl -X POST $SLACK_WEBHOOK_URL \
  -H 'Content-type: application/json' \
  --data '{"text":"🧪 Production test alert"}'

# Verify in Slack channel
```

---

## ⚠️ Common Mistakes

1. **Committing .env.production.local** → Use `.gitignore`
2. **Mixing local and production URLs** → Double-check all URLs
3. **Forgetting Slack webhooks** → Alerts won't work
4. **Wrong database connection** → Application won't start
5. **MinIO credentials mismatch** → Data won't load

---

## 📞 Support

If something fails:
1. Check `.env.production.local` values
2. Verify connectivity: `curl http://51.210.246.61:9000/minio/health/live`
3. Check logs: `docker-compose logs -f`
4. Review Slack alerts for errors

---

## ✅ Deployment Success Indicators

- [ ] Frontend loads on Netlify/Vercel
- [ ] Rankings page shows firm data
- [ ] Slack alerts received (test)
- [ ] Backend processes run without errors
- [ ] Database queries execute successfully
- [ ] MinIO stores/retrieves data
- [ ] Prefect agent pool is healthy
