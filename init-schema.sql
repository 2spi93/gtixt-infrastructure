-- Initialize GPTI database schema and sample data

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

-- Insert sample firms
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

-- Insert sample snapshot
INSERT INTO snapshots (name, data, public_access) VALUES
(
    'snapshot_2026_02_18',
    jsonb_build_object(
        'version', '1.0',
        'timestamp', '2026-02-18T12:00:00Z',
        'firms_count', 10,
        'metrics', jsonb_build_object(
            'avg_score', 82.3,
            'median_score', 83.5,
            'total_active', 9,
            'total_pending', 1
        )
    ),
    true
)
ON CONFLICT DO NOTHING;

-- Verify
SELECT COUNT(*) as firms_count FROM firms;
SELECT COUNT(*) as snapshots_count FROM snapshots;
