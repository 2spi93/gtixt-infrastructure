#!/bin/bash

# Script to initialize the database and populate firms data
# Use native PostgreSQL with direct SQL commands

set -e

GPTI_DIR="/opt/gpti"
BOT_DIR="$GPTI_DIR/gpti-data-bot"
DB_PORT=5433  # Native PostgreSQL port

echo "==========================================="
echo "GPTI - Initializing Database"  
echo "==========================================="

# Step 1: Create tables via SQL
echo ""
echo "Step 1: Creating database schema..."
sudo -u postgres psql -p $DB_PORT -d gpti << 'SQLEOF'

-- Create firms table
CREATE TABLE IF NOT EXISTS firms (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    score FLOAT DEFAULT 0,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create snapshots table
CREATE TABLE IF NOT EXISTS snapshots (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data JSONB,
    sha256 VARCHAR(64),
    public_access BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create audit_findings table
CREATE TABLE IF NOT EXISTS audit_findings (
    id SERIAL PRIMARY KEY,
    firm_id INTEGER REFERENCES firms(id),
    finding_type VARCHAR(100),
    finding_data JSONB,
    severity VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_firms_name ON firms(name);
CREATE INDEX IF NOT EXISTS idx_snapshots_timestamp ON snapshots(timestamp);
CREATE INDEX IF NOT EXISTS idx_audit_findings_firm ON audit_findings(firm_id);

SELECT 'Database schema created successfully' as status;
SQLEOF

echo "  ✓ Schema created"

# Step 2: Insert sample firms data
echo ""
echo "Step 2: Inserting sample firms..."
sudo -u postgres psql -p $DB_PORT -d gpti << 'SQLEOF'

-- Insert sample prop trading firms
INSERT INTO firms (name, score, status) VALUES 
    ('Prop Trading Firm Alpha', 85.5, 'active'),
    ('Quantum Capital Markets', 78.3, 'active'),
    ('Elite Traders LLC', 92.1, 'active'),
    ('Market Pulse Trading', 76.8, 'active'),
    ('Apex Proprietary Trading', 88.9, 'active'),
    ('Strategic Investments Inc', 81.2, 'active'),
    ('Digital Trading Solutions', 79.5, 'active'),
    ('Revenue Dynamics Pro', 83.7, 'active'),
    ('Empirical Finance Group', 87.4, 'active'),
    ('Volatility Traders Corp', 75.9, 'pending')
ON CONFLICT (name) DO NOTHING;

-- Verify insert
SELECT COUNT(*) as firms_inserted FROM firms;
SQLEOF

echo "  ✓ Sample firms inserted"

# Step 3: Create a sample snapshot
echo ""
echo "Step 3: Creating sample snapshot..."
sudo -u postgres psql -p $DB_PORT -d gpti << 'SQLEOF'

INSERT INTO snapshots (name, data, public_access) VALUES
(
    'snapshot_2026_02_18',
    '{
        "version": "1.0",
        "timestamp": "2026-02-18T12:00:00Z",
        "firms_count": 10,
        "metrics": {
            "avg_score": 82.3,
            "median_score": 83.5,
            "total_active": 9,
            "total_pending": 1
        },
        "firms": [
            {
                "name": "Prop Trading Firm Alpha",
                "score": 85.5,
                "status": "active",
                "trades_count": 1245,
                "win_rate": 0.562
            },
            {
                "name": "Quantum Capital Markets",
                "score": 78.3,
                "status": "active",
                "trades_count": 989,
                "win_rate": 0.548
            }
        ]
    }',
    true
)
ON CONFLICT DO NOTHING;

SELECT COUNT(*) as snapshots_created FROM snapshots;
SQLEOF

echo "  ✓ Sample snapshot created"

# Step 4: Verify all data
echo ""
echo "Step 4: Verifying populated data..."
sudo -u postgres psql -p $DB_PORT -d gpti << 'SQLEOF'

SELECT 
    (SELECT COUNT(*) FROM firms) as "Total Firms",
    (SELECT COUNT(*) FROM snapshots) as "Total Snapshots",
    (SELECT COUNT(*) FROM audit_findings) as "Audit Findings",
    (SELECT AVG(score) FROM firms) as "Avg Score";
    
-- Show sample firms
SELECT '--- Sample Firms ---' as section;
SELECT id, name, score, status FROM firms LIMIT 5;

SQLEOF

echo ""
echo "==========================================="
echo "✓ Database initialized successfully!"
echo "==========================================="
echo ""
echo "Database is ready for staging tests"
echo "  Port: $DB_PORT (native PostgreSQL)"
echo "  User: gpti"
echo "  Database: gpti"
echo ""
