#!/usr/bin/env python3
"""
Mock Agents API Server - Port 3002
Returns agent evidence data from database
"""

import json
import sys
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

sys.path.insert(0, '/opt/gpti/gpti-data-bot/src')

import psycopg

class AgentsHandler(BaseHTTPRequestHandler):
    
    AGENTS_INFO = {
        'RVI': 'Registry Verification',
        'SSS': 'Sanctions Screening',
        'REM': 'Regulatory Event Monitor',
        'FRP': 'Firm Reputation & Payout',
        'IRS': 'Independent Review System',
        'MIS': 'Manual Investigation',
        'IIP': 'IOSCO Compliance'
    }
    
    def get_db_connection(self):
        """Get database connection"""
        return psycopg.connect(
            dbname='gpti',
            user='gpti',
            password='superpassword',
            host='127.0.0.1',
            port=5433
        )
    
    def send_json(self, data, status=200):
        """Send JSON response"""
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data, default=str).encode())
    
    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        # CORS preflight
        if self.command == 'OPTIONS':
            self.send_response(200)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', 'Content-Type')
            self.end_headers()
            return
        
        try:
            # Health check
            if path == '/health':
                return self.send_json({
                    'status': 'ok',
                    'port': 3002,
                    'service': 'agents-api'
                })
            
            # List all agents
            if path == '/api/agents':
                agents = [
                    {'code': code, 'label': label}
                    for code, label in self.AGENTS_INFO.items()
                ]
                return self.send_json(agents)
            
            # Get agents for firm
            if path.startswith('/api/agents/'):
                parts = path.strip('/').split('/')
                if len(parts) >= 3:
                    firm_id = parts[2]
                    agent_code = parts[3].upper() if len(parts) > 3 else None
                    
                    # Get firm from database
                    conn = self.get_db_connection()
                    cur = conn.cursor()
                    
                    cur.execute(
                        'SELECT name, score, confidence FROM firms WHERE firm_id = %s OR id::text = %s LIMIT 1',
                        (firm_id, firm_id)
                    )
                    
                    result = cur.fetchone()
                    conn.close()
                    
                    if not result:
                        return self.send_json({'error': 'Firm not found'}, 404)
                    
                    name, score, confidence = result
                    
                    # Return specific agent
                    if agent_code:
                        if agent_code not in self.AGENTS_INFO:
                            return self.send_json({'error': 'Unknown agent'}, 400)
                        
                        return self.send_json({
                            'agent': agent_code,
                            'label': self.AGENTS_INFO[agent_code],
                            'status': 'SUCCESS',
                            'evidence': {
                                'firm_name': name,
                                'score': float(score) if score else 50,
                                'confidence': float(confidence) if confidence else 0.8,
                                'verified_at': datetime.now().isoformat(),
                                'data_quality': 'high'
                            },
                            'timestamp': datetime.now().isoformat()
                        })
                    
                    # Return all agents for firm
                    agents = []
                    for code, label in self.AGENTS_INFO.items():
                        agents.append({
                            'agent': code,
                            'label': label,
                            'status': 'SUCCESS',
                            'evidence': {
                                'firm_name': name,
                                'score': float(score) if score else 50,
                                'confidence': float(confidence) if confidence else 0.8,
                                'last_updated': datetime.now().isoformat()
                            },
                            'timestamp': datetime.now().isoformat()
                        })
                    
                    return self.send_json(agents)
            
            # Not found
            return self.send_json({'error': 'Not found'}, 404)
            
        except Exception as e:
            print(f'Error: {e}')
            return self.send_json({'error': str(e)}, 500)
    
    def do_OPTIONS(self):
        """Handle CORS preflight"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def log_message(self, format, *args):
        """Suppress default logging"""
        pass

def main():
    """Start the API server"""
    port = 3002
    server_address = ('127.0.0.1', port)
    httpd = HTTPServer(server_address, AgentsHandler)
    
    print("=" * 60)
    print("GPTI - Agents API Server (Mock)")
    print("=" * 60)
    print(f"\n✓ Server running on http://localhost:{port}")
    print(f"\nEndpoints:")
    print(f"  GET /health")
    print(f"  GET /api/agents")
    print(f"  GET /api/agents/:firmId")
    print(f"  GET /api/agents/:firmId/:agentCode")
    print(f"\nPress Ctrl+C to stop\n")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n✓ Server stopped")

if __name__ == '__main__':
    main()
