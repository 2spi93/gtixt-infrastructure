# Documentation Errata and Conflicts

This file captures known inconsistencies found during the docs audit. Treat these items as needing verification before relying on them as source-of-truth.

## Conflicting status claims
- Several reports claim "production ready" and "all systems operational" while runtime investigation showed missing DATABASE_URL and a PostgreSQL peer auth failure.
- Some docs state zero TypeScript errors and complete API coverage, but earlier audit notes list missing /api/firm data and incomplete firm profile sections.

## Database naming inconsistencies
- Canonical database name is now gpti_data. References to other names were normalized in docs.
- See docs/DB_ADDENDUM.md for preserved schema details that originally referenced other database names.

## Template or placeholder content
- At least one report contains "Generated: $(date)" placeholders and should not be treated as a final report.

## Next verification steps
- Re-verify connection settings for DATABASE_URL with gpti_data.
- Re-run the runtime checks for /api/firm, firm profile page, and snapshot verification before marking the system as production ready.
- Replace placeholder timestamps with real values or mark documents as templates.
