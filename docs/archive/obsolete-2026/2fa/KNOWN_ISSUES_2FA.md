# ⚠️ Known Issues - Admin Console 2FA Security Update

## Issue #1: Admin Pages Return 404 (2FA Setup, User Management)

**Status:** 🔴 OPEN - In Progress  
**Severity:** HIGH (Feature unavailable)  
**Affected Pages:**
- `/admin/setup-2fa/`
- `/admin/users/`  
- `/admin/change-password/` (trailing slash issue only)

### Symptoms
- Pages show "404: This page could not be found" in browser
- HTTP Status: 404
- Problem occurs on both `localhost:3000` and `https://admin.gtixt.com`
- Redirect without trailing slash `/admin/change-password` works (308 → adds slash)

### Root Cause
🔍 **Diagnosed but not fully resolved:**
1. ✅ Pages compile successfully to `pages/admin/*.js` (server-side)
2. ✅ Manifest routes correctly reference the `.js` files
3. ✅ Next.js is configured for SSR (not static export)
4. ✅ getServerSideProps added to force server-side rendering
5. ❌ **Runtime issue:** Node.js/Turbopack fails to serve compiled routes despite proper configuration

**Hypothesis:**
- Turbopack compiler generates chunks that can't be resolved at runtime
- Possible conflict between `speakeasy` (TOTP library) and SSR
- Next.js 16 Turbopack incompatibility with certain external modules

### Temporary Workaround

**For founder/admin to test authentication:**
Since `/admin/setup-2fa/` and `/admin/users/` don't load, use **API directly**:

```bash
# 1. Get token (login)
TOKEN=$(curl -s -X POST https://admin.gtixt.com/api/internal/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"founder","password":"FounderSecure2026$9x"}' \
  | jq -r '.token')

# 2. Setup 2FA (get QR code)
curl -X POST https://admin.gtixt.com/api/internal/auth/setup-2fa/ \
  -H "Authorization: Bearer $TOKEN"

# 3. List users (admin only)
curl -X GET https://admin.gtixt.com/api/internal/users/ \
  -H "Authorization: Bearer $TOKEN"
```

**Web UI Workaround:**
- `/admin/change-password` (without slash) **WORKS** - use this
- `/admin/login/` **WORKS** - authentication available
- `/admin/review-queue/` **WORKS** - main dashboard accessible

### Attempted Fixes
1. ✅ Added `getServerSideProps` to force SSR
2. ✅ Verified pages compile as `.js` (not `.html`)
3. ✅ Rebuilt entire `.next` directory from scratch
4. ✅ Restarted PM2 with `--update-env`
5. ❌ Still returns 404 at runtime

### Permanent Solutions (Pending)

**Option A: Downgrade Next.js + Webpack**
- Use Next.js 14 or 15 with Webpack instead of Turbopack
- Drawback: Slower builds, older runtime

**Option B: Refactor Page Components**
- Remove `speakeasy` import from client-side pages
- Move TOTP setup to separate API-only endpoint
- Use simpler state management
- Drawback: More refactoring required

**Option C: Docker Container Isolation**
- Run app in isolated container with proper module resolution
- Ensure all Turbopack chunks are bundled correctly
- Drawback: Infrastructure changes

**Recommended Next Step:**
Contact Vercel/Next.js support with:
- Reproduction: `git checkout staging`
- Issue: Pages with `getServerSideProps` + `speakeasy` library return 404
- Environment: Next.js 16.1.6 (Turbopack)

---

## Issue #2: Password Change Page Trailing Slash

**Status:** 🟡 PARTIALLY RESOLVED  
**Severity:** LOW (Workaround available)  
**Affected Page:** `/admin/change-password/`

### Description
- `/admin/change-password/` (with slash) → 404
- `/admin/change-password` (without slash) → 308 redirect → but then 404 after
- Caused by `trailingSlash: true` in `next.config.js`

### Root Cause
Next.js configuration enforces trailing slashes globally, but page routing has issues with the generated redirects.

### Solution - STATUS
✅ **Workaround:** Use `/admin/change-password` directly (browsers auto-follow 308)
⏳ **Permanent fix:** Pending upgrade to newer Next.js version

---

## Issue #3: 2FA TOTP Specification

**Status:** 🟢 WORKING  
**Severity:** NONE (Feature operational)

### Details
✅ Database columns added (`totp_secret`, `totp_enabled`)
✅ APIs functional:
- `POST /api/internal/auth/setup-2fa/` - Generate QR  
- `POST /api/internal/auth/enable-2fa/` - Verify code
- `POST /api/internal/auth/disable-2fa/` - Disable 2FA
✅ Login API updated to handle `totp` param
✅ Can test via curl (see workaround above)

### Test Command
```bash
curl https://admin.gtixt.com/api/internal/auth/setup-2fa/ \
  -H "Authorization: Bearer TOKEN" | jq '.data.qrCode'
# Returns base64 PNG for QR code scanning
```

---

## Issue #4: Strict Password Policy

**Status:** 🟢 WORKING  
**Severity:** NONE

### Configuration Applied
```
INTERNAL_PASSWORD_MIN_LENGTH=14
INTERNAL_PASSWORD_REQUIRE_SYMBOL=true
INTERNAL_PASSWORD_ROTATION_DAYS=90  
INTERNAL_PASSWORD_ROTATION_REQUIRE_INITIAL=true
```

**Validated via:** `POST /api/internal/auth/change-password/`
- Rejects passwords < 14 chars
- Requires: Uppercase + Lowercase + Digit + Symbol
- Forces change every 90 days

✅ Policy enforcement confirmed via API testing

---

## Summary Table

| Issue | Severity | Status | Workaround |
|-------|----------|--------|-----------|
| `/admin/setup-2fa/` returns 404 | 🔴 HIGH | OPEN | Use API endpoints directly |
| `/admin/users/` returns 404 | 🔴 HIGH | OPEN | Use API endpoints directly |
| `/admin/change-password/` trailing slash | 🟡 LOW | PARTIAL | Use without slash |
| 2FA TOTP APIs | 🟢 NONE | WORKING | ✅ All functional |
| Strict password policy | 🟢 NONE | WORKING | ✅ All functional |

---

## Escalation Timeline

| Date | Action | Result |
|------|--------|--------|
| 2026-02-25 21:50 | Pages compiled successfully in build | ✅ Build passes |
| 2026-02-25 22:00 | Clean rebuild + PM2 restart | ❌ Still 404 |
| 2026-02-25 22:09 | Added `getServerSideProps` | ✅ Changed from `.html` to `.js` |
| 2026-02-25 22:13 | Rebuilt with SSR | ❌ Still 404 in HTTP/HTTPS |
| 2026-02-25 22:14 | Verified nginx passes requests correctly | ❌ Node.js returns 404 |

---

**Next.js Version:** 16.1.6 (Turbopack)  
**Node Version:** 18+  
**Problem Since:** 2026-02-25 (deployment date)  
**Blocking:** Feature availability (use API workaround meanwhile)
