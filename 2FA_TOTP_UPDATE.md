# 🔐 2FA TOTP & Strict Security Policy - Update 2026-02-25

## Summary of Changes

### 1. 2FA TOTP Implementation
✅ **TOTP (Time-based One-Time Password) 2FA added**
- New page: `/admin/setup-2fa/`
- Supports: Google Authenticator, Microsoft Authenticator, Authy, 1Password, etc.
- Database columns added: `totp_secret`, `totp_enabled` in `internal_users`
- QR code generation and verification implemented
- Login flow updated: asks for TOTP code if enabled

### 2. Strict Password Policy
✅ **Security hardened (Feb 2026)**
- Min length: **14 characters** (was 12)
- **Symbol required** (new requirement)
- Rotation enforced: **90 days**
- Initial password reset: **required**

Policy file: `.env.production.local`
```
INTERNAL_PASSWORD_MIN_LENGTH=14
INTERNAL_PASSWORD_REQUIRE_SYMBOL=true
INTERNAL_PASSWORD_ROTATION_DAYS=90
INTERNAL_PASSWORD_ROTATION_REQUIRE_INITIAL=true
```

### 3. Founder Account Created
✅ **Founder (admin) account available**
- Username: `founder`
- Password: `FounderSecure2026$9x`
- Role: `admin` (full permissions)
- See: [FOUNDER_ACCESS_GUIDE.md](./FOUNDER_ACCESS_GUIDE.md)

### 4. Login Typo Redirect
✅ `/loging` → `/admin/login/` (automatic redirect for typos)

---

## API Changes

### Login - Now with TOTP
```javascript
POST /api/internal/auth/login/
{
  "username": "founder",
  "password": "FounderSecure2026$9x",
  "totp": "123456"  // NEW: Optional, required if 2FA enabled
}

Response (2FA required):
{
  "success": false,
  "totp_required": true,
  "message": "Please provide TOTP code"
}

Response (Success):
{
  "success": true,
  "token": "...",
  "totp_enabled": true,  // NEW: Indicates user has 2FA
  ...
}
```

### New 2FA Endpoints
```javascript
// Generate TOTP secret + QR code
POST /api/internal/auth/setup-2fa/
Response: { secret: "ABC123...", qrCode: "data:image/png..." }

// Enable 2FA (verify code)
POST /api/internal/auth/enable-2fa/
{ "code": "123456" }

// Disable 2FA
POST /api/internal/auth/disable-2fa/
```

---

## Database Changes

### Migration Applied
```sql
ALTER TABLE internal_users 
ADD COLUMN totp_secret VARCHAR(32),
ADD COLUMN totp_enabled BOOLEAN DEFAULT FALSE;

CREATE INDEX idx_internal_users_totp_enabled ON internal_users(totp_enabled);
```

Migration file: `gpti-data-bot/infra/sql/011_internal_auth_2fa.sql`

---

## New Pages

### `/admin/setup-2fa/`
- **Purpose:** Setup/manage TOTP 2FA
- **Access:** Authenticated users only
- **Features:**
  - Generate QR code
  - Display secret (for manual entry)
  - Verify code before activation
  - Disable existing 2FA with confirmation

UI Component: `pages/admin/setup-2fa.tsx` (371 lines)

---

##  Updated Pages

### `/admin/change-password/`
- Added link to Setup 2FA in navigation

### `/admin/users/`
- Added link to Setup 2FA in navigation

### `/admin/review-queue/`
- Added link to Setup 2FA in navigation

### `/admin/login/`
- Now checks for `totp_enabled` flag
- Prompts for TOTP code if enabled
- Logs "login" action with `totp_used` flag

---

## Code Changes

### `lib/internal-auth.ts` (+90 lines)
- `getTotpStatus(userId)` - Check if 2FA enabled
- `generateTotpSecret(userId)` - Create QR + secret
- `verifyTotpCode(userId, code)` - Verify TOTP code
- `enableTotp(userId)` - Activate 2FA
- `disableTotp(userId)` - Disable 2FA

### `pages/api/internal/auth/login.ts`
- Added TOTP verification before session creation
- Returns `totp_required: true` if 2FA enabled but code not provided
- Returns `totp_enabled` flag in response

### `pages/api/internal/auth/setup-2fa.ts` (NEW, 30 lines)
- Generate TOTP secret and QR code
- Log setup attempt

### `pages/api/internal/auth/enable-2fa.ts` (NEW, 28 lines)
- Verify TOTP code
- Enable 2FA flag
- Log activation

### `pages/api/internal/auth/disable-2fa.ts` (NEW, 23 lines)
- Clear TOTP secret and flag
- Log deactivation

---

## Admins & Accounts

### Current Admin Users

| Username | Role | Email | 2FA | Password Changed |
|----------|------|-------|-----|------------------|
| founder | admin | founder@gtixt.internal | ❌ (setup recommended) | Initial: `FounderSecure2026$9x` |
| alice | reviewer | alice@gpti.internal | Not applicable | Initial: `alice123` |
| bob | lead_reviewer | bob@gpti.internal | Not applicable | Initial: `bob123` |
| compliance | auditor | audit@gpti.internal | Not applicable | Initial: `audit123` |

---

## Next Steps (Recommendations)

1. **Founder:** Change initial password to something unique
2. **Founder:** Enable 2FA via `/admin/setup-2fa/`
3. **Other admins:** Consider enabling 2FA for security
4. **Future:** Consider IP allowlist (`INTERNAL_IP_ALLOWLIST` env var)
5. **Future:** Migrate hashing from SHA256 to bcrypt

---

## Testing

### Test 2FA Setup
```bash
# 1. Login as founder
curl -X POST https://admin.gtixt.com/api/internal/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"founder","password":"FounderSecure2026$9x"}'
# Get token from response

# 2. Setup 2FA
curl -X POST https://admin.gtixt.com/api/internal/auth/setup-2fa/ \
  -H "Authorization: Bearer TOKEN"
# Get secret and QR code

# 3. Enable 2FA (after scanning QR)
curl -X POST https://admin.gtixt.com/api/internal/auth/enable-2fa/ \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"code":"123456"}'

# 4. Logout and re-login
curl -X POST https://admin.gtixt.com/api/internal/auth/logout/ \
  -H "Authorization: Bearer TOKEN"

# 5. Login with TOTP
curl -X POST https://admin.gtixt.com/api/internal/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"founder","password":"FounderSecure2026$9x","totp":"123456"}'
```

---

## Troubleshooting

### "404: This page could not be found" on `/admin/change-password/`
- **Status:** Known issue with Next.js 16 Turbopack + trailingSlash
- **Workaround:** Use page without slash: `/admin/change-password` will redirect
- **Fix pending:** Next.js version upgrade or server config

###  "Invalid TOTP code"
- Ensure phone clock is synchronized (use NTP)
- Codes are valid for 30 seconds, window of 2 tokens supported
- Try the next code if near the boundary

### "Password policy failed"
- Ensure 14+ characters with: uppercase + lowercase + digit + symbol
- Example: `MyPass2026!@#` ✅

---

## Git Info

**Commit:**
```
commit 0124807
Add 2FA TOTP authentication, setup page, and /loging redirect
10 files changed, 649 insertions(+), 2 deletions(-)
```

**Branch:** staging

---

**Update Date:** 2026-02-25  
**Security Level:** Strict (2FA + 90-day rotation + 14-char password)
