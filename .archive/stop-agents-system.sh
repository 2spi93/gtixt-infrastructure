#!/bin/bash

# Stop Script for GTIXT 7-Agent System

echo "🛑 Stopping GTIXT System..."

# Stop agents backend
if [ -f /tmp/gpti-agents.pid ]; then
  AGENTS_PID=$(cat /tmp/gpti-agents.pid)
  if kill -0 $AGENTS_PID 2>/dev/null; then
    kill $AGENTS_PID
    echo "✓ Stopped agents backend (PID: $AGENTS_PID)"
  fi
  rm -f /tmp/gpti-agents.pid
fi

# Stop frontend
if [ -f /tmp/gpti-site.pid ]; then
  SITE_PID=$(cat /tmp/gpti-site.pid)
  if kill -0 $SITE_PID 2>/dev/null; then
    kill $SITE_PID
    echo "✓ Stopped frontend site (PID: $SITE_PID)"
  fi
  rm -f /tmp/gpti-site.pid
fi

# Also kill any remaining processes
pkill -f "npm run agents:start" 2>/dev/null || true
pkill -f "npm run dev" 2>/dev/null || true

# Clean up log files
rm -f /tmp/gpti-agents.log /tmp/gpti-site.log

echo "✅ GTIXT System stopped"
