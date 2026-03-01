# GTIXT Versioning Strategy

**Document Version:** 1.0  
**Last Updated:** 2026-02-24

## Overview

GTIXT uses **Semantic Versioning (MAJOR.MINOR.PATCH)** across all components, APIs, SDKs, and specifications to ensure predictable, transparent versioning and backward compatibility.

## Table of Contents

1. [Version Format](#version-format)
2. [Component Versioning](#component-versioning)
3. [API Versioning](#api-versioning)
4. [SDK Versioning](#sdk-versioning)
5. [Specification Versioning](#specification-versioning)
6. [Release Process](#release-process)
7. [Breaking Changes](#breaking-changes)
8. [Version Checking](#version-checking)

---

## Version Format

### Semantic Versioning (SemVer)

GTIXT follows **Semantic Versioning 2.0.0** with format: **X.Y.Z**

```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]
```

#### MAJOR (X)
- **Purpose:** Breaking changes, incompatible API changes
- **Increment When:** Removing features, changing API structure, incompatible spec changes
- **Example:** 1.x.x → 2.0.0
- **Compatibility:** ❌ NOT backward compatible

#### MINOR (Y)
- **Purpose:** New features, backward compatible additions
- **Increment When:** Adding new endpoints, SDK features, optional fields
- **Example:** 1.2.0 → 1.3.0
- **Compatibility:** ✅ Fully backward compatible

#### PATCH (Z)
- **Purpose:** Bug fixes, security patches, documentation updates
- **Increment When:** Fixing bugs, security issues, typos
- **Example:** 1.2.0 → 1.2.1
- **Compatibility:** ✅ Fully backward compatible

### Pre-release Versions

For testing and staged releases:

```
1.2.0-alpha.1     # Alpha release
1.2.0-beta.1      # Beta release
1.2.0-rc.1        # Release candidate
```

**Changelog Entry:** Pre-releases should be noted in CHANGELOG.md with testing requirements.

### Build Metadata

For internal tracking (does not affect precedence):

```
1.2.0+20260224.abc1234    # Commit-based build metadata
1.2.0+docker              # Environment metadata
```

---

## Component Versioning

### Current Component Versions (TIER 2 - 1.2.0)

| Component | Version | Location | Release Date |
|-----------|---------|----------|---|
| Frontend | 1.2.0 | `gpti-site/package.json` | 2026-02-24 |
| Data Bot | 1.2.0 | `gpti-data-bot/package.json` | 2026-02-24 |
| API Spec | 1.0.0 | `gtixt-api-v1.0.yaml` | 2026-02-24 |
| Python SDK | 1.0.0 | `sdks/gtixt-python-sdk.py` | 2026-02-24 |
| JavaScript SDK | 1.0.0 | `sdks/gtixt-js-sdk.js` | 2026-02-24 |

### Version Synchronization

All components are versioned together for a release:
- Same MAJOR version: All components increment together
- Example: Release v1.2.0 updates all 5 components to v1.2.0

### Component-Specific Versioning

Individual components may have patch releases:
- **Python SDK 1.0.1:** Bug fix in Python SDK only (others stay 1.2.0)
- **Frontend 1.2.1:** UI fix in frontend only (others stay 1.2.0)

---

## API Versioning

### URL Path Versioning Strategy

All GTIXT APIs support versioning via URL paths:

```
/v1/api/snapshots/latest      # v1 API
/v1/api/evidence/[firm_id]    # v1 API
/v1/api/audit_export          # v1 API
/v1/api/verify_score          # v1 API
```

### Version in Headers

All API responses include version information:

```json
{
  "meta": {
    "api_version": "1.0.0",
    "spec_version": "1.0.0",
    "sdk_version": "1.0.0",
    "timestamp": "2026-02-24T15:30:45Z"
  },
  "data": {...}
}
```

### Request Version Specification (Optional)

Clients can optionally specify desired API version:

```bash
# Using Accept header (recommended)
curl -H "Accept: application/vnd.gtixt.v1+json" https://gtixt.com/api/snapshots/latest

# Using query parameter (fallback)
curl https://gtixt.com/api/snapshots/latest?api_version=1.0.0
```

### Current API Endpoints

| Endpoint | Method | API Version | Status |
|----------|--------|---|---|
| `/v1/api/snapshots/latest` | GET | 1.0.0 | Production |
| `/v1/api/snapshots/history` | GET | 1.0.0 | Production |
| `/v1/api/evidence/[firm_id]` | GET | 1.0.0 | Production |
| `/v1/api/specification` | GET | 1.0.0 | Production |
| `/v1/api/audit_export` | GET | 1.0.0 | Production |
| `/v1/api/verify_score` | POST | 1.0.0 | Production |

---

## SDK Versioning

### Python SDK

Version information:

```python
from gtixt import __version__, __api_version__

print(__version__)        # Output: 1.0.0
print(__api_version__)    # Output: 1.0.0
```

Check version at runtime:

```python
client = GTIXTClient(api_key="xxx")
version_info = client.get_version()
# Returns: {'sdk_version': '1.0.0', 'api_version': '1.0.0', 'author': 'GTIXT Team'}
```

Installation by version:

```bash
pip install gtixt-sdk==1.0.0
pip install gtixt-sdk==1.0.1        # Patch update
pip install gtixt-sdk>=1.0.0,<2.0   # Any v1 version
```

### JavaScript SDK

Version information:

```javascript
import { version, apiVersion } from 'gtixt-sdk';

console.log(version);              // Output: 1.0.0
console.log(apiVersion);           // Output: 1.0.0
```

Check version at runtime:

```javascript
const client = new GTIXTClient({apiKey: 'xxx'});
const versionInfo = client.getVersion();
// Returns: {sdkVersion: '1.0.0', apiVersion: '1.0.0', author: 'GTIXT Team'}
```

Installation by version:

```bash
npm install gtixt-sdk@1.0.0
npm install gtixt-sdk@latest
npm install gtixt-sdk@^1.0.0        # Any v1 version
```

---

## Specification Versioning

### GTIXT Specification Versions

The GTIXT scoring specification has its own version:

```json
{
  "version": "1.0.0",
  "effective_date": "2026-02-24",
  "next_revision": "2026-05-24",
  "pillars": [
    {"id": "regulatory_compliance", "weight": 0.30, "version": "1.0.0"},
    {"id": "financial_stability", "weight": 0.25, "version": "1.0.0"},
    ...
  ]
}
```

### Specification Versioning Rules

- **Spec Version:** Increments independently from API/SDK versions
- **Breaking Change:** Weight changes, pillar removals → MAJOR increment
- **New Pillar:** New optional pillar → MINOR increment
- **Rule Adjustment:** Scoring rule refinement → PATCH increment

### Specification Files

```
public/specs/
  gtixt-scoring-specification-v1.0.json    # v1.0.0
  gtixt-scoring-specification-v1.1.json    # v1.1.0 (future)
  gtixt-scoring-specification-v2.0.json    # v2.0.0 (future)
```

### Accessing Versions

```bash
# Get current specification
curl https://gtixt.com/api/specification?version=1.0.0

# List available versions
curl https://gtixt.com/api/specifications/versions
```

---

## Release Process

### Prerequisites
- [ ] All tests passing (unit, integration, E2E)
- [ ] Code review complete
- [ ] CHANGELOG updated with proposed changes
- [ ] VERSION.md updated with new version number
- [ ] Breaking changes documented (if applicable)

### Release Steps

#### Step 1: Prepare Release
```bash
# Create release branch
git checkout -b release/v1.2.0

# Update VERSION.md with new version
# Update CHANGELOG.md with release notes
# Update package.json files
```

#### Step 2: Version Components

**Frontend (gpti-site/package.json):**
```json
{
  "version": "1.2.0"
}
```

**Data Bot (gpti-data-bot/package.json):**
```json
{
  "version": "1.2.0"
}
```

**Python SDK (sdks/gtixt-python-sdk.py):**
```python
__version__ = "1.0.0"
__api_version__ = "1.0.0"
```

**JavaScript SDK (sdks/gtixt-js-sdk.js):**
```javascript
const VERSION = '1.0.0';
const API_VERSION = '1.0.0';
```

**OpenAPI Spec (public/openapi/gtixt-api-v1.0.yaml):**
```yaml
info:
  version: 1.0.0
```

#### Step 3: Create Git Tag
```bash
git tag -a v1.2.0 -m "TIER 2: Institutional Integration Layer"
git push origin v1.2.0
```

#### Step 4: Publish SDKs

**Python SDK to PyPI:**
```bash
python -m twine upload dist/gtixt-sdk-1.0.0.tar.gz
```

**JavaScript SDK to npm:**
```bash
npm publish
```

#### Step 5: Deploy

```bash
# Build
npm run build

# Deploy to staging
./deploy.sh staging v1.2.0

# Verify
./verify.sh staging

# Deploy to production
./deploy.sh production v1.2.0
```

#### Step 6: Announce Release

- [ ] Send release notification to api-support@gtixt.com
- [ ] Post release notes on website
- [ ] Notify integration partners
- [ ] Update API documentation portals

---

## Breaking Changes

### When Changes Are "Breaking"

✅ NOT Breaking:
- Adding new optional API fields
- Adding new API endpoints
- Adding new methods to SDKs
- Adding new pillars to spec (if optional)
- Bug fixes

❌ Breaking:
- Changing response field types
- Removing API fields
- Removing API endpoints
- Changing required parameters
- Changing pillar weights significantly (>5%)
- Changing aggregation formula

### Breaking Changes Process

#### 1. Announcement (60+ days before)
```
DEPRECATION NOTICE (v1.5.0):

Effective v2.0.0 (released 2026-05-24), the following changes will occur:

- /api/snapshots/firm-scores endpoint will be removed
  → USE: /v2/api/snapshots/history instead
  
- Evidence confidence levels will change from 5 to 3 levels
  → See migration guide: /docs/migrations/v1-to-v2.md
```

#### 2. Grace Period (Dual Support)
- v1 API remains available with existing behavior
- v2 API available with new behavior
- 6-month overlap period for migration

#### 3. Sunset
- After 6 months, v1 endpoints will be read-only
- After 12 months, v1 endpoints will be removed

### Migration Guide Template

Create `/docs/migrations/v1-to-v2.md` for each major version:

```markdown
# Migration Guide: v1.x → v2.0

## What Changed
1. [Change 1]
2. [Change 2]
3. [Change 3]

## Migration Steps
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Breaking Changes
| v1.x | v2.0 |
|------|------|
| endpoint | new_endpoint |
| field_name | new_field_name |

## Support
- Python SDK: pip install gtixt-sdk==2.0.0
- JavaScript SDK: npm install gtixt-sdk@2.0.0
```

---

## Version Checking

### Check GTIXT Version

**Unified VERSION file:**
```bash
cat /opt/gpti/VERSION.md
```

Output format:
```
# GTIXT Global Prop Trading Index - Version Management

**Current Release:** 1.2.0 (TIER 2 - February 24, 2026)

## Component Versions

| Component | Version | Release Date | Status |
|-----------|---------|--------------|--------|
| Frontend (gpti-site) | 1.2.0 | 2026-02-24 | Production |
| Data Bot | 1.2.0 | 2026-02-24 | Production |
| API Specification | 1.0.0 | 2026-02-24 | Production |
```

### Check API Version

```bash
curl -s https://gtixt.com/api/health | jq '.meta'
```

Response:
```json
{
  "api_version": "1.0.0",
  "spec_version": "1.0.0",
  "sdk_version": "1.0.0",
  "timestamp": "2026-02-24T15:30:45Z"
}
```

### Check Python SDK Version

```python
from gtixt import __version__
print(__version__)  # Output: 1.0.0
```

### Check JavaScript SDK Version

```javascript
import { version } from 'gtixt-sdk';
console.log(version);  // Output: 1.0.0
```

### Check Installed Package Versions

```bash
# Python
pip show gtixt-sdk | grep Version

# JavaScript
npm ls gtixt-sdk
```

---

## Version Compatibility Matrix

| Client SDK | API Support | Status | EOL Date |
|---|---|---|---|
| Python 1.0.x | v1.0.0 | Supported | 2027-02-24 |
| JavaScript 1.0.x | v1.0.0 | Supported | 2027-02-24 |
| Frontend 1.2.x | v1.0.0 | Current | 2027-02-24 |
| Frontend 1.1.x | v1.0.0 | Deprecated | 2026-08-24 |

---

## Documentation Files

- **VERSION.md** - Master version file, component versions
- **CHANGELOG.md** - Change history by version
- **docs/versioning.md** - This file
- **docs/migrations/** - Version-specific migration guides
- **public/openapi/gtixt-api-v*.*.yaml** - API specification by version

---

## Questions?

- **Versioning Questions:** version@gtixt.com
- **API Questions:** api-support@gtixt.com
- **SDK Issues:** GitHub Issues (sdk repositories)
- **Security Issues:** security@gtixt.com
