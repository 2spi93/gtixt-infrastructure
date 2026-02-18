#!/usr/bin/env python3
"""
Initialize GPTI Database and populate sample data
"""

import sys
import os
import psycopg
import json
from datetime import datetime

# Add GPTI to path
sys.path.insert(0, '/opt/gpti/gpti-data-bot/src')

def init_database():
    """Initialize database schema and populate sample data"""
    
    # Connection parameters
    conn_params = {
        'dbname': 'gpti',
        'user': 'gpti',
        'password': 'superpassword',
        'host': '127.0.0.1',
        'port': 5433
    }
    
    print("=" * 45)
    print("GPTI - Database Initialization")
    print("=" * 45)
    print()
    
    try:
        # Connect to database
        print("Connecting to PostgreSQL...")
        conn = psycopg.connect(**conn_params)
        cur = conn.cursor()
        print(f"  ✓ Connected on port 5433")
        print()
        
        # Create tables
        print("Creating schema...")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS firms (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL UNIQUE,
                score FLOAT DEFAULT 0,
                status VARCHAR(50) DEFAULT 'pending',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        
        cur.execute("""
            CREATE TABLE IF NOT EXISTS snapshots (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                data JSONB,
                public_access BOOLEAN DEFAULT false,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        
        cur.execute("""
            CREATE TABLE IF NOT EXISTS audit_findings (
                id SERIAL PRIMARY KEY,
                firm_id INTEGER REFERENCES firms(id),
                finding_type VARCHAR(100),
                finding_data JSONB,
                severity VARCHAR(50),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        
        # Create indexes
        cur.execute("CREATE INDEX IF NOT EXISTS idx_firms_name ON firms(name);")
        cur.execute("CREATE INDEX IF NOT EXISTS idx_snapshots_timestamp ON snapshots(timestamp);")
        cur.execute("CREATE INDEX IF NOT EXISTS idx_audit_findings_firm ON audit_findings(firm_id);")
        
        conn.commit()
        print("  ✓ Tables created")
        print()
        
        # Insert sample firms
        print("Inserting sample firms...")
        firms_data = [
            ('Prop Trading Firm Alpha', 85.5, 'active'),
            ('Quantum Capital Markets', 78.3, 'active'),
            ('Elite Traders LLC', 92.1, 'active'),
            ('Market Pulse Trading', 76.8, 'active'),
            ('Apex Proprietary Trading', 88.9, 'active'),
            ('Strategic Investments Inc', 81.2, 'active'),
            ('Digital Trading Solutions', 79.5, 'active'),
            ('Revenue Dynamics Pro', 83.7, 'active'),
            ('Empirical Finance Group', 87.4, 'active'),
            ('Volatility Traders Corp', 75.9, 'pending'),
        ]
        
        for name, score, status in firms_data:
            try:
                cur.execute(
                    "INSERT INTO firms (name, score, status) VALUES (%s, %s, %s) ON CONFLICT (name) DO NOTHING;",
                    (name, score, status)
                )
            except:
                pass
        
        conn.commit()
        
        # Count firms
        cur.execute("SELECT COUNT(*) FROM firms;")
        firms_count = cur.fetchone()[0]
        print(f"  ✓ {firms_count} firms inserted")
        print()
        
        # Insert sample snapshot
        print("Creating sample snapshot...")
        snapshot_data = {
            "version": "1.0",
            "timestamp": datetime.now().isoformat(),
            "firms_count": firms_count,
            "metrics": {
                "avg_score": 82.3,
                "median_score": 83.5,
                "total_active": 9,
                "total_pending": 1
            }
        }
        
        cur.execute(
            "INSERT INTO snapshots (name, data, public_access) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING;",
            ('snapshot_2026_02_18', json.dumps(snapshot_data), True)
        )
        conn.commit()
        
        cur.execute("SELECT COUNT(*) FROM snapshots;")
        snapshots_count = cur.fetchone()[0]
        print(f"  ✓ {snapshots_count} snapshots created")
        print()
        
        # Verify all data
        print("Database Status:")
        cur.execute("""
            SELECT 
                (SELECT COUNT(*) FROM firms) as firms,
                (SELECT COUNT(*) FROM snapshots) as snapshots,
                (SELECT AVG(score) FROM firms) as avg_score;
        """)
        
        firms_t, snapshots_t, avg_score = cur.fetchone()
        print(f"  • Firms: {firms_t}")
        print(f"  • Snapshots: {snapshots_t}")
        print(f"  • Average Score: {avg_score:.1f}" if avg_score else "  • Average Score: N/A")
        
        # Show sample firms
        cur.execute("SELECT id, name, score, status FROM firms LIMIT 3;")
        print()
        print("  Sample firms:")
        for row in cur.fetchall():
            print(f"    - {row[1]}: score={row[2]}, status={row[3]}")
        
        conn.close()
        
        print()
        print("=" * 45)
        print("✓ Database initialized successfully!")
        print("=" * 45)
        print()
        print("Ready for application testing")
        
        return True
        
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False

if __name__ == '__main__':
    success = init_database()
    sys.exit(0 if success else 1)
