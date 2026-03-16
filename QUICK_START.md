# Quick Start Guide

## How the Servers Work Together

You need to run **TWO separate servers** on **different ports**:

1. **Frontend (Next.js)** → Port 3000 → This is what you see in your browser
2. **Backend (Rails API)** → Port 3001 → This handles API requests from the frontend

## Step-by-Step Instructions

### Step 1: Start the Backend (Terminal 1)

```bash
cd backend
PORT=3001 rails server
```

You should see: "Listening on http://localhost:3001"

**Keep this terminal open!**

### Step 2: Start the Frontend (Terminal 2)

Open a NEW terminal window, then:

```bash
cd frontend
npm run dev
```

You should see: "Ready on http://localhost:3000"

**Keep this terminal open too!**

### Step 3: Open Your Browser

Go to: **http://localhost:3000**

This is your frontend application. The frontend will automatically make API calls to the backend on port 3001.

## What You'll See

- **http://localhost:3000** → Your Next.js frontend (the app you interact with)
- **http://localhost:3001** → Your Rails API (you won't visit this directly, but the frontend uses it)

## Important Notes

- You MUST run both servers at the same time
- They run on different ports (3000 and 3001)
- The frontend (.env.local) should have: `NEXT_PUBLIC_API_URL=http://localhost:3001`
- If you only run one server, things won't work!

## Stopping the Servers

Press `Ctrl+C` in each terminal to stop the servers.
