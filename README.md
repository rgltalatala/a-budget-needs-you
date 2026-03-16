# Personal Budgeting App

A full-stack personal finance budgeting application using the envelope budgeting method, built with Rails (backend) and Next.js (frontend).

## Quick Start

### Prerequisites
- Ruby 3.3.2
- PostgreSQL
- Node.js 18+ and npm

### Setup

1. **Backend Setup:**
   ```bash
   cd backend
   bundle install
   rails db:create
   rails db:migrate
   rails db:seed
   ```

2. **Frontend Setup:**
   ```bash
   cd frontend
   npm install
   ```

### Saving and restoring seed data (dump / reseed)

You can save the current app data (including your allotted amounts and budget state) as a seed file and use it as the basis for future reseeds.

- **Save current data to a seed file** (run from project root):
  ```bash
  cd backend
  bundle exec rails runner db/dump_seed.rb [user_email]
  ```
  Default user email is `test@email.com` if omitted. This overwrites `backend/db/seeds_dumped.rb` with the current user, budget months, category groups, category months (allotted/spent/balance), summaries, accounts, transactions, and goals.

- **Restore from the saved seed** (e.g. after `db:drop db:create db:migrate` or to reset to the saved state):
  ```bash
  cd backend
  bundle exec rails runner db/seeds_dumped.rb [user_email]
  ```
  Use the same email as when you ran the dump, or pass a different one to load into another user.

You can commit `db/seeds_dumped.rb` so others (or you later) can reseed to this state, or regenerate it anytime with `db/dump_seed.rb`.

### Demo users

- **Default seed user** (from `rails db:seed`): `test@example.com` / `SeedPassword1!` — minimal accounts, categories, and transactions.
- **Mock data** (optional): `bundle exec rails runner db/seeds_mock_data.rb [user_email]` — adds a full budget, bi-weekly income, recurring bills, and past months (default email `test@email.com`).
- **Demo: Mother (family of 4)** (optional): `bundle exec rails runner db/seeds_demo_mother.rb` — creates `mother@demo.com` / `SeedPassword1!` with HCOL-style categories (mortgage, groceries ~$1,500, eating out ~$500, childcare, student loans, savings, investments), 50/30/20 budget groups, bi-weekly pay ($2,115) and 5% EOY bonus.

### Running the Application

You need to run **BOTH servers simultaneously** on **different ports**:

**Terminal 1 - Backend (port 3001):**
```bash
cd backend
PORT=3001 rails server
```
You should see: "Listening on http://localhost:3001"

**Terminal 2 - Frontend (port 3000):**
```bash
cd frontend
npm run dev
```
You should see: "Ready on http://localhost:3000"

### Access the Application

- **Frontend**: http://localhost:3000 ← **Open this in your browser!**
- **Backend API**: http://localhost:3001 (used by frontend, don't visit directly)

**Important**: You must run both servers at the same time. The frontend (port 3000) makes API calls to the backend (port 3001).

### Production deployment

When you deploy, set these environment variables (e.g. in your host’s dashboard or `.env.production` on the server). You need **all** of these for production, not just the database.

**Backend (required)**

| Variable | Purpose |
|----------|---------|
| `RAILS_ENV` | Set to `production` |
| `SECRET_KEY_BASE` | From `bundle exec rails secret` (generate once, store securely) |
| `DATABASE_URL` | Full Postgres URL (e.g. `postgres://user:pass@host/dbname`) from your host, or use `BACKEND_DATABASE_PASSWORD` and ensure DB/user exist per `config/database.yml` |
| `ALLOWED_ORIGINS` | Comma-separated frontend origin(s), e.g. `https://raphbudget.com` |

- For load balancers: `GET /health` (liveness), `GET /ready` (readiness, checks DB).

**Frontend (at build time)**

| Variable | Purpose |
|----------|---------|
| `NEXT_PUBLIC_API_URL` | Production backend URL, e.g. `https://api.raphbudget.com` (set before `npm run build`) |

- Run migrations and start the server:

  ```bash
  cd backend
  RAILS_ENV=production bundle exec rails db:migrate
  RAILS_ENV=production PORT=3001 bundle exec rails server
  ```

**Frontend**

- Set `NEXT_PUBLIC_API_URL` to your production backend URL (e.g. `https://api.yourdomain.com`) before building. This is baked in at build time.
- Build and start:

  ```bash
  cd frontend
  npm run build
  npm run start
  ```

  The app will serve on port 3000 by default. Ensure the backend is reachable at the URL you set for `NEXT_PUBLIC_API_URL`.

Deploying to a platform (e.g. Render, Fly, Vercel): set the variables above in the platform’s environment config; many hosts provide `DATABASE_URL` and a secret key for you. Frontend can go on Vercel or any Node host; point `NEXT_PUBLIC_API_URL` at your backend URL.

## Project Structure

- `backend/` - Rails 8.1 API-only application
- `frontend/` - Next.js 16 application with TypeScript

## Documentation

- Backend documentation: `backend/README.md` and `backend/LEARNING_PLAN_DOCUMENTATION.md`
- Frontend documentation: `frontend/README.md`
