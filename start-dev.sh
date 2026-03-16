#!/bin/bash

# Start Rails backend on port 3001
echo "Starting Rails backend on port 3001..."
cd backend
PORT=3001 rails server &
RAILS_PID=$!

# Wait a moment for Rails to start
sleep 3

# Start Next.js frontend on port 3000
echo "Starting Next.js frontend on port 3000..."
cd ../frontend
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

# Wait for user interrupt
trap "kill $RAILS_PID $NEXT_PID 2>/dev/null; exit" INT TERM
wait
