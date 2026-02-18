#!/usr/bin/env python3
"""
Monitoring dashboard for Agents API
- Health checks
- Performance metrics
- Agent status
- HTTP API for monitoring
"""

import os
import sys
import json
import time
from datetime import datetime
from typing import Dict, List
from collections import defaultdict
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
import threading

sys.path.insert(0, '/opt/gpti/gpti-data-bot/src')

import psycopg
import requests

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DATABASE_URL = os.environ.get('DATABASE_URL', 'postgresql://gpti:superpassword@127.0.0.1:5433/gpti')
AGENTS_API_URL = os.environ.get('AGENTS_API_URL', 'http://localhost:3002')
MONITORING_PORT = int(os.environ.get('MONITORING_PORT', '3003'))

class AgentMonitor:
    def __init__(self):
        self.conn = psycopg.connect(DATABASE_URL)
        self.metrics = defaultdict(lambda: {
            'total_calls': 0,
            'successful_calls': 0,
            'failed_calls': 0,
            'avg_response_time': 0,
            'response_times': [],
            'last_error': None,
            'last_check': None
        })
        self.last_full_check = None
    
    def health_check(self) -> Dict:
        """Check agents API health"""
        try:
            start = time.time()
            response = requests.get(
                f'{AGENTS_API_URL}/health',
                timeout=5
            )
            elapsed = time.time() - start
            
            is_healthy = response.status_code == 200
            
            return {
                'status': 'healthy' if is_healthy else 'unhealthy',
                'response_time_ms': round(elapsed * 1000, 2),
                'http_status': response.status_code,
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {
                'status': 'down',
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def check_agent_for_firm(self, firm_id: str, agent_code: str) -> Dict:
        """Check specific agent for a firm"""
        try:
            start = time.time()
            response = requests.get(
                f'{AGENTS_API_URL}/api/agents/{firm_id}/{agent_code}',
                timeout=10
            )
            elapsed = time.time() - start
            
            if response.status_code == 200:
                data = response.json()
                return {
                    'agent': agent_code,
                    'firm_id': firm_id,
                    'status': 'SUCCESS',
                    'response_time_ms': round(elapsed * 1000, 2),
                    'http_status': response.status_code
                }
            else:
                return {
                    'agent': agent_code,
                    'firm_id': firm_id,
                    'status': 'ERROR',
                    'response_time_ms': round(elapsed * 1000, 2),
                    'http_status': response.status_code
                }
        except Exception as e:
            return {
                'agent': agent_code,
                'firm_id': firm_id,
                'status': 'FAILED',
                'error': str(e),
                'response_time_ms': 0
            }
    
    def check_all_agents(self, sample_size: int = 10) -> Dict:
        """Check all agents with sample firms"""
        try:
            cur = self.conn.cursor()
            
            # Get sample firms
            cur.execute('SELECT firm_id FROM firms ORDER BY RANDOM() LIMIT %s', (sample_size,))
            sample_firms = [row[0] for row in cur.fetchall()]
            
            agents = ['RVI', 'SSS', 'REM', 'FRP', 'IRS', 'MIS', 'IIP']
            results = []
            
            for firm_id in sample_firms:
                for agent in agents:
                    result = self.check_agent_for_firm(firm_id, agent)
                    results.append(result)
                    time.sleep(0.1)  # Rate limiting
            
            return {
                'total_checks': len(results),
                'successful': sum(1 for r in results if r['status'] == 'SUCCESS'),
                'failed': sum(1 for r in results if r['status'] in ['ERROR', 'FAILED']),
                'avg_response_time_ms': sum(r.get('response_time_ms', 0) for r in results) / len(results) if results else 0,
                'sample_firm_count': len(sample_firms),
                'results': results
            }
        except Exception as e:
            return {'error': str(e)}
    
    def get_database_stats(self) -> Dict:
        """Get database statistics"""
        try:
            cur = self.conn.cursor()
            
            # Firms
            cur.execute('SELECT COUNT(*) FROM firms')
            firm_count = cur.fetchone()[0]
            
            # Evidence records
            cur.execute('SELECT COUNT(*) FROM evidence_collection')
            evidence_count = cur.fetchone()[0]
            
            # Distribution by agent
            cur.execute('''
                SELECT collected_by, COUNT(*) 
                FROM evidence_collection 
                GROUP BY collected_by
                ORDER BY COUNT(*) DESC
            ''')
            agent_distribution = {row[0]: row[1] for row in cur.fetchall()}
            
            # Average firm score
            cur.execute('SELECT AVG(score) FROM firms')
            avg_score = cur.fetchone()[0]
            
            # Score distribution
            cur.execute('''
                SELECT 
                    CASE 
                        WHEN score >= 80 THEN 'Elite (80+)'
                        WHEN score >= 60 THEN 'Strong (60-79)'
                        ELSE 'Standard (<60)'
                    END as tier,
                    COUNT(*) as count
                FROM firms
                GROUP BY tier
                ORDER BY tier DESC
            ''')
            
            distribution = {row[0]: row[1] for row in cur.fetchall()}
            
            return {
                'total_firms': firm_count,
                'total_evidence_records': evidence_count,
                'avg_firm_score': round(avg_score, 2) if avg_score else 0,
                'agent_distribution': agent_distribution,
                'firm_tier_distribution': distribution,
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {'error': str(e)}
    
    def get_system_status(self) -> Dict:
        """Get overall system status"""
        health = self.health_check()
        db_stats = self.get_database_stats()
        
        return {
            'api_health': health,
            'database': db_stats,
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.0'
        }

monitor = AgentMonitor()

class MonitoringHandler(BaseHTTPRequestHandler):
    """HTTP Request Handler for monitoring endpoints"""
    
    def do_GET(self):
        """Handle GET requests"""
        path = urlparse(self.path).path
        
        try:
            if path == '/health':
                self.send_json(monitor.health_check())
            elif path == '/api/status':
                self.send_json(monitor.get_system_status())
            elif path == '/api/database':
                self.send_json(monitor.get_database_stats())
            elif path == '/':
                self.send_html(self.get_dashboard_html())
            else:
                self.send_json({'error': 'Not found'}, 404)
        except Exception as e:
            logger.error(f"Error handling {path}: {e}")
            self.send_json({'error': str(e)}, 500)
    
    def send_json(self, data: Dict, status: int = 200):
        """Send JSON response"""
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data, default=str).encode())
    
    def send_html(self, html: str, status: int = 200):
        """Send HTML response"""
        self.send_response(status)
        self.send_header('Content-Type', 'text/html')
        self.end_headers()
        self.wfile.write(html.encode())
    
    def log_message(self, format, *args):
        """Suppress default logging"""
        pass
    
    def get_dashboard_html(self) -> str:
        """Get monitoring dashboard HTML"""
        return '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>GPTI Agents API Monitoring</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0f172a; color: #e2e8f0; padding: 20px; }
            .container { max-width: 1400px; margin: 0 auto; }
            h1 { margin-bottom: 30px; text-align: center; font-size: 2.5em; }
            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-bottom: 30px; }
            .card { background: #1e293b; border: 1px solid #334155; border-radius: 8px; padding: 20px; }
            .card h2 { font-size: 0.9em; color: #94a3b8; margin-bottom: 15px; text-transform: uppercase; }
            .card .value { font-size: 2.5em; font-weight: bold; color: #0ede64; }
            .card.error { border-color: #dc2626; }
            .card.error .value { color: #ff6b6b; }
            .status { display: inline-block; padding: 6px 12px; border-radius: 4px; font-size: 0.85em; font-weight: bold; }
            .status.healthy { background: #10b981; color: white; }
            .status.warning { background: #f59e0b; color: white; }
            .status.down { background: #dc2626; color: white; }
            .footer { text-align: center; color: #64748b; font-size: 0.85em; margin-top: 40px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 GPTI Agents API Monitor</h1>
            <p style="text-align: center; margin-bottom: 20px; color: #94a3b8;">Port 3003 • Auto-refreshes every 30 seconds</p>
            
            <div class="grid">
                <div class="card">
                    <h2>API Status</h2>
                    <div id="api-status" class="status">Loading...</div>
                </div>
                <div class="card">
                    <h2>Response Time</h2>
                    <div id="response-time" class="value">--ms</div>
                </div>
                <div class="card">
                    <h2>Total Firms</h2>
                    <div id="total-firms" class="value">--</div>
                </div>
                <div class="card">
                    <h2>Evidence Records</h2>
                    <div id="evidence-count" class="value">--</div>
                </div>
            </div>
            
            <div style="background: #1e293b; border: 1px solid #334155; border-radius: 8px; padding: 20px; margin-bottom: 20px;">
                <h2 style="color: #94a3b8; margin-bottom: 15px;">Agent Statistics</h2>
                <pre id="agent-stats" style="color: #0ede64; font-family: monospace; white-space: pre-wrap;">Loading...</pre>
            </div>
            
            <div class="footer">
                <p>✓ Monitoring Active • Agents API: http://localhost:3002</p>
            </div>
        </div>
        
        <script>
            async function updateDashboard() {
                try {
                    const healthRes = await fetch('/health').then(r => r.json());
                    const statusEl = document.getElementById('api-status');
                    const statusClass = healthRes.status === 'healthy' ? 'healthy' : healthRes.status === 'down' ? 'down' : 'warning';
                    statusEl.className = 'status ' + statusClass;
                    statusEl.textContent = healthRes.status.toUpperCase();
                    document.getElementById('response-time').textContent = (healthRes.response_time_ms || 0) + 'ms';
                    
                    const statsRes = await fetch('/api/database').then(r => r.json());
                    document.getElementById('total-firms').textContent = statsRes.total_firms || 0;
                    document.getElementById('evidence-count').textContent = statsRes.total_evidence_records || 0;
                    
                    let stats = 'Firm Distribution:\\n';
                    for (const [tier, count] of Object.entries(statsRes.firm_tier_distribution || {})) {
                        stats += `  • ${tier}: ${count}\\n`;
                    }
                    stats += '\\nAgent Records:\\n';
                    for (const [agent, count] of Object.entries(statsRes.agent_distribution || {})) {
                        stats += `  • ${agent}: ${count}\\n`;
                    }
                    document.getElementById('agent-stats').textContent = stats;
                } catch (e) {
                    console.error('Update failed:', e);
                }
            }
            
            updateDashboard();
            setInterval(updateDashboard, 30000);
        </script>
    </body>
    </html>
        '''

def run_monitoring_server():
    """Start HTTP monitoring server"""
    server_address = ('0.0.0.0', MONITORING_PORT)
    httpd = HTTPServer(server_address, MonitoringHandler)
    logger.info(f"🚀 Monitoring server started on http://localhost:{MONITORING_PORT}")
    httpd.serve_forever()

if __name__ == '__main__':
    logger.info(f"Starting Agents Monitoring on port {MONITORING_PORT}")
    logger.info(f"📊 Dashboard: http://localhost:{MONITORING_PORT}")
    logger.info(f"📡 Agent API: {AGENTS_API_URL}")
    run_monitoring_server()
