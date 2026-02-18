#!/usr/bin/env python3
"""
Load firms with proper transaction handling
"""

import sys
import json
sys.path.insert(0, '/opt/gpti/gpti-data-bot/src')

def main():
    import psycopg
    from datetime import datetime
    
    print("=" * 70)
    print("GPTI - Load 196 Firms for Index Calculations")
    print("=" * 70)
    print()
    
    # Load data
    print("Loading firms data...")
    with open('/opt/gpti/tmp/firms_3001.json') as f:
        data = json.load(f)
    
    firms = data['firms']
    print(f"  ✓ Loaded {len(firms)} firms")
    print()
    
    # Connect
    conn = psycopg.connect(dbname='gpti', user='gpti', password='superpassword', host='127.0.0.1', port=5433)
    cur = conn.cursor()
    
    # Clear
    print("Clearing database...")
    cur.execute("DELETE FROM firms")
    conn.commit()
    print("  ✓ Database cleared")
    print()
    
    # Insert
    print("Inserting firms...")
    inserted = 0
    skipped = 0
    seen_names = set()
    
    for i, firm in enumerate(firms, 1):
        name = firm.get('name', 'Unknown')
        
        # Skip duplicates by name
        if name in seen_names:
            skipped += 1
            continue
        
        seen_names.add(name)
        
        try:
            cur.execute("""
                INSERT INTO firms (name, score, status, firm_id, website_root, 
                                   model_type, jurisdiction, confidence, na_rate, pillar_scores)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                name,
                float(firm.get('score_0_100', 0)),
                firm.get('status', 'candidate'),
                firm.get('firm_id'),
                firm.get('website_root'),
                firm.get('model_type'),
                firm.get('jurisdiction'),
                float(firm.get('confidence', 0)),
                float(firm.get('na_rate', 0)),
                json.dumps(firm.get('pillar_scores', {}))
            ))
            conn.commit()
            inserted += 1
            
            if inserted % 50 == 0:
                print(f"  ... {inserted} firms inserted")
        except Exception as e:
            conn.rollback()
            skipped += 1
    
    print(f"  ✓ Successfully inserted {inserted} firms")
    if skipped > 0:
        print(f"  ⚠ Skipped {skipped} duplicates/errors")
    print()
    
    # Stats
    print("Calculating index statistics...")
    cur.execute("""
        SELECT 
            COUNT(*) as total,
            CAST(AVG(score) AS NUMERIC(10,2)) as avg,
            MAX(score) as max_s,
            MIN(score) as min_s,
            COUNT(CASE WHEN score >= 80 THEN 1 END) as tier1,
            COUNT(CASE WHEN score >= 60 AND score < 80 THEN 1 END) as tier2,
            COUNT(CASE WHEN score < 60 THEN 1 END) as tier3
        FROM firms
    """)
    total, avg_score, max_s, min_s, tier1, tier2, tier3 = cur.fetchone()
    
    print(f"  ✓ Index calculated")
    print(f"    Total Firms: {total}")
    print(f"    Average Score: {avg_score}")
    print(f"    Range: {min_s} - {max_s}")
    print(f"    Tier 1 (80+): {tier1}")
    print(f"    Tier 2 (60-79): {tier2}")
    print(f"    Tier 3 (<60): {tier3}")
    print()
    
    # Top firms
    print("Top 20 firms by score:")
    cur.execute("""
        SELECT name, score, jurisdiction, status
        FROM firms
        ORDER BY score DESC
        LIMIT 20
    """)
    
    print("  # │ Name                           │ Score │ Country")
    print("  ──┼────────────────────────────────┼───────┼──────────")
    for i, (name, score, jurisdiction, status) in enumerate(cur.fetchall(), 1):
        print(f"  {i:2} │ {name[:30]:30} │ {score:5.1f} │ {(jurisdiction or 'N/A'):8}")
    
    print()
    
    # Create snapshot
    print("Creating comprehensive index snapshot...")
    cur.execute("""
        SELECT id, name, score, status, jurisdiction, model_type, confidence
        FROM firms ORDER BY score DESC
    """)
    
    all_firms = []
    for row in cur.fetchall():
        all_firms.append({
            "id": row[0], "name": row[1], "score": row[2], "status": row[3],
            "jurisdiction": row[4], "model_type": row[5], "confidence": row[6]
        })
    
    snapshot = {
        "timestamp": datetime.now().isoformat(),
        "version": "5.0-final-index",
        "total_firms": total,
        "metrics": {
            "average_score": float(avg_score) if avg_score else 0,
            "max_score": float(max_s) if max_s else 0,
            "min_score": float(min_s) if min_s else 0,
            "tier1_count": tier1, "tier2_count": tier2, "tier3_count": tier3
        },
        "firms": all_firms
    }
    
    cur.execute("""
        INSERT INTO snapshots (name, data, public_access)
        VALUES (%s, %s, %s)
    """, (
        f"index_{total}_firms_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
        json.dumps(snapshot, default=str),
        True
    ))
    conn.commit()
    print(f"  ✓ Snapshot created with {total} firms")
    print()
    
    conn.close()
    
    print("=" * 70)
    print("✓ INDEX LOADED SUCCESSFULLY")
    print("=" * 70)
    print()
    print(f"Status: Ready for score calculations with {total} firms")
    print()

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
