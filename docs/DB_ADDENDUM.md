# Database Addendum (Canonical: gpti_data)

This addendum preserves database-specific details that were previously scattered across docs under different database names. Treat all of them as schemas/tables within gpti_data.

## Sanctions data (formerly gpti_sanctions)
These objects should live in gpti_data with the same table names:
- sanctions_lists
- sanctions_entities
- sanctions_matches
- views: active_sanctions, sanctions_statistics

Related docs:
- gpti-data-bot/docs/PHASE_3_WEEK_3_COMPLETE.md
- gpti-data-bot/PHASE_3_WEEK_3_DELIVERY_REPORT.md
- gpti-data-bot/PHASE_3_WEEK_4_DELIVERY_REPORT.md

## Validation framework (already gpti_data in many docs)
Tables and migrations referenced in gpti-data-bot/docs/DEPLOYMENT_VALIDATION.md and gpti-data-bot/docs/VALIDATION_FRAMEWORK_README.md should also target gpti_data.

Key migrations:
- src/gpti_bot/db/migrations/002_create_validation_tables.sql
- src/gpti_bot/db/migrations/003_populate_historical_events.sql

## Application references (formerly gpti_bot or gpti_db)
Any DATABASE_URL or DB_NAME examples that referenced gpti_bot or gpti_db now point to gpti_data.

If a future schema split is desired, define explicit schema names (e.g., sanctions.*) but keep the database name gpti_data.
