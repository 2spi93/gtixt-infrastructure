# PAGE DISPLAY DEBUG REPORT

## Problem Identified
The extracted firm data was present in two places but NOT displayed on the firm detail pages:

1. **Snapshot JSON** ✓ - `/opt/gpti/gpti-site/gtixt/gpti-snapshots/universe_v0.1_public/_public/gtixt_snapshot_20260219T131311.json` contained extracted data (42 payout_frequency, 16 max_drawdown, etc.)

2. **Database** ✓ - PostgreSQL `datapoints` table had 154 extracted records (payout_frequency: 155 entries, payout_split_pct: 49, max_total_drawdown_pct: 24)

3. **BUT**: Web pages showed "Not available" / "—" for these fields ✗

## Root Cause Analysis

### Architecture Flow:
```
Evidence HTML → MinIO (7,082 files)
       ↓
   extract_comprehensive.py (34 firms extracted)
       ↓
PostgreSQL datapoints table (154 entries)
       ↓
comprehensive_merge.py (merge from 3 sources)
       ↓
Snapshot JSON file updated
       ↓
(MISSING STEP) → Sync to MinIO latest snapshot
       ↓
Next.js API loads from MinIO latest.json pointer
       ↓
firm.tsx displays data from API response
```

### The Specific Issue:

The Next.js API at `/pages/api/firm.ts` loads firm data through this cascade:

1. **Queries PostgreSQL `firms` table** - gets structure but fields like `payout_frequency`, `max_drawdown_rule` are NULL/empty
2. **Checks if critical fields missing** (line 654) via `ENRICHED_FIELDS` list which includes:
   - `payout_frequency` 
   - `max_drawdown_rule`
   - `daily_drawdown_rule`
   - etc.
3. **If missing, loads from MinIO snapshot** (line 730-760 `loadRemoteSnapshot()`)
   - Reads `latest.json` pointer→ gets path to snapshot file
   - Loads actual snapshot JSON from MinIO
   - Finds matching firm and merges missing fields
4. **Returns merged data to front-end**

### The Problem:

1. We updated `/opt/gpti/gpti-site/gtixt/gpti-snapshots/universe_v0.1_public/_public/gtixt_snapshot_20260219T131311.json` ✓
2. We uploaded it to MinIO: `local/gpti-snapshots/universe_v0.1_public/_public/gtixt_snapshot_20260219T131311.json` ✓  
3. **BUT**: The `latest.json` pointer was pointing to a different snapshot file!
   - `latest.json` → `universe_v0.1/20260214T040307...json` (OLD)
   - It should → `universe_v0.1_public/_public/gtixt_snapshot_20260219T131311.json` (NEW)
4. A background process (possibly Prefect) was overwriting `latest.json` with different snapshots

## Solution Implemented

### Step 1: Upload our updated snapshot to MinIO
```bash
mc cp /opt/gpti/gpti-site/gtixt/gpti-snapshots/universe_v0.1_public/_public/gtixt_snapshot_20260219T131311.json \
  local/gpti-snapshots/universe_v0.1_public/_public/gtixt_snapshot_20260219T131311.json
```
✓ Completed successfully (240 KiB uploaded)

### Step 2: Update the `latest.json` pointer
```json
{
  "object": "universe_v0.1_public/_public/gtixt_snapshot_20260219T131311.json",
  "sha256": "extracted-data-snapshot",
  "created_at": "2026-02-21T14:57:12Z",
  "count": 227
}
```
✓ Uploaded to `local/gpti-snapshots/universe_v0.1_public/_public/latest.json`

### Step 3: Verify data accessibility
**MinIO now contains:**
- Snapshot file: `universe_v0.1_public/_public/gtixt_snapshot_20260219T131311.json` (with extracted data)
- Pointer: `latest.json` → points to our snapshot

**Snapshot contains for blueguardiancom:**
- payout_frequency: daily ✓
- max_drawdown_rule: 6.0 ✓
- daily_drawdown_rule: 3.0 ✓
- payout_split_pct: 90.0 ✓
- account_size_usd: 50000 ✓

## Remaining Task: Clear Cache and Verify Display

The Next.js server may have cached the old `latest.json` pointer. To complete the fix:

### Option A: Restart Next.js Server
```bash
cd /opt/gpti/gpti-site
# Kill current process
sudo pkill -f "next start"
# Restart
npm run build
npm run start
```

### Option B: Hard refresh browser cache
- Chrome/Firefox: `Ctrl+Shift+Del` to open cache clearing
- Or: `Ctrl+Shift+R` (hard refresh single page)
- Or: Open DevTools → Network tab → check "Disable cache"

### Option C: Wait for cache expiration
Default: `FIRM_CACHE_TTL_MS = 60000ms` (60 seconds)
- API caches firm data for 60 seconds
- After 60 seconds, will fetch fresh from MinIO

## Verification Steps

1. **Check MinIO contents:**
   ```bash
   mc cat local/gpti-snapshots/universe_v0.1_public/_public/latest.json
   # Should show: "object": "universe_v0.1_public/_public/gtixt_snapshot_20260219T131311.json"
   ```

2. **Test API directly:**
   ```bash
   curl http://localhost:3000/api/firm?id=blueguardiancom | jq '.firm | {payout_frequency, max_drawdown_rule, daily_drawdown_rule}'
   # Should show: {"payout_frequency":"daily","max_drawdown_rule":6.0,"daily_drawdown_rule":3.0}
   ```

3. **Check page display:**
   - Open: https://gtixt.com/firm/blueguardiancom/ (or http://localhost:3000/firm/blueguardiancom)
   - Look for metric displays  NOT showing "—" for:
     - Payout frequency: should show "Daily"
     - Max drawdown rule: should show "6.0%"
     - Daily drawdown rule: should show "3.0%"

## Data Coverage After Fix

With snapshot now on MinIO:
- **Payout Frequency**: 42/227 firms (18.5%)
- **Max Drawdown**: 16/227 firms (7.0%)
- **Daily Drawdown**: 16/227 firms (7.0%)
- **Profit Split**: 22/227 firms (9.7%)
- **Account Size**: 15/227 firms (6.6%)
- **Displayable records**: 23/227 firms with 2+ fields (10.1%)

## Files Modified This Session

1. **Created**: `/opt/gpti/extract_comprehensive.py` - Core extraction pipeline (380 lines)
2. **Created**: `/opt/gpti/comprehensive_merge.py` - Data merge engine (250 lines)
3. **Modified**: Local snapshot file with merged data ✓
4. **Uploaded to MinIO**: Snapshot JSON file ✓
5. **Updated**: latest.json pointer in MinIO ✓

## Next Phase: Increase Coverage

Current extraction success rate: 34/157 missing firms (21.7%)
To reach 40-50% coverage goal:
1. Implement SPA-capable extraction (Selenium/Playwright) for JavaScript-heavy sites
2. Handle lazy-loaded content and paginated tables
3. Extract from PDFs and alternative document formats
4. Implement fallback extraction patterns for mobile versions

See `/opt/gpti/EXTRACTION_FINAL_REPORT.md` for detailed analysis.
