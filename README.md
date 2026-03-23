# Personal Budgeting App

A full-stack personal finance app that uses the envelope budgeting method. You manage accounts, transactions, and category-based budgets with optional goals. Built with a Rails API (backend) and a Next.js frontend.

## Run locally

For another engineer who wants to run this on their own machine (no deployed site required).

### Prerequisites

- **Ruby 3.3.2**
- **PostgreSQL**
- **Node.js 18+** and npm

### 1. Clone and set up the backend

```bash
cd backend
bundle install
rails db:create
rails db:migrate
rails db:seed
```

### 2. Set up the frontend

From the **repo root**, install root deps (Tailwind is listed here so PostCSS can resolve in a monorepo layout), then install the app:

```bash
npm install
cd frontend
npm install
```

No env file is required for local run: the frontend defaults to `http://localhost:3001` for the API.

### 3. Run both servers

You need both processes running at the same time.

**Terminal 1 — backend (port 3001):**

```bash
cd backend
PORT=3001 rails server
```

**Terminal 2 — frontend (port 3000):**

```bash
cd frontend
npm run dev
```

### 4. Open the app

In your browser go to **http://localhost:3000**. Use that URL; the frontend talks to the backend on 3001.

**Sign in:** create an account from the signup page, or use a demo user (from `rails db:seed`):

- **Single demo:** `single@example.com` / `SeedPassword1!`
- **Family demo:** `family@example.com` / `SeedPassword1!`

Optional: `rails runner db/seeds_demo_mother.rb` adds `mother@demo.com` / `SeedPassword1!`

---

More detail: backend docs in `backend/README.md` and `backend/DESIGN_AND_IMPLEMENTATION.md`, frontend in `frontend/README.md`.
