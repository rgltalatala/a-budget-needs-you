#!/bin/bash
set -euo pipefail

# Resolve repo root from this script so backend/frontend work no matter where you invoke from.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Starting Rails backend on port 3001..."
cd "$SCRIPT_DIR/backend"
PORT=3001 rails server &
RAILS_PID=$!

sleep 3

echo "Starting Next.js frontend on port 3000..."
cd "$SCRIPT_DIR/frontend"
npm run dev &
NEXT_PID=$!

echo ""
echo "=========================================="
echo "Servers are running:"
echo "  Frontend: http://localhost:3000"
echo "  Backend:  http://localhost:3001"
echo ""
echo "Press Ctrl+C to stop both servers"
echo "=========================================="

trap "kill $RAILS_PID $NEXT_PID 2>/dev/null; exit" INT TERM
wait
