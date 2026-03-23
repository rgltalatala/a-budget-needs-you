# Backend (Rails API)

Rails 8.1 API for the budgeting app. Runs on port 3001 when used with the frontend.

## Run locally

From the project root, or from `backend/`:

```bash
bundle install
rails db:create
rails db:migrate
rails db:seed
PORT=3001 rails server
```

The API is at `http://localhost:3001`. The frontend expects this port when running locally.

## Optional: extra seed data

- **Mock data** (full budget, sample transactions):  
  `bundle exec rails runner db/seeds_mock_data.rb [user_email]`  
  Default email: `test@email.com`
- **Demo: Family of 4** (mother@demo.com):  
  `bundle exec rails runner db/seeds_demo_mother.rb`
- **Dump/restore** your current data as seeds: see `db/dump_seed.rb` and `db/seeds_dumped.rb` (run with `rails runner`).

## API overview

- **Auth:** `POST /api/v1/users` (signup), `POST /api/v1/sessions` (login), `DELETE /api/v1/sessions` (logout)
- **Password:** `PATCH /api/v1/users/me/password` (change when logged in), `POST /api/v1/password_reset_requests`, `POST /api/v1/password_reset`
- **Resources** (require auth): accounts, account_groups, categories, transactions, budgets, budget_months, category_groups, category_months, goals, summaries

## Tests

```bash
rails test
```

## Docs

Detailed API and implementation notes: [DESIGN_AND_IMPLEMENTATION.md](./DESIGN_AND_IMPLEMENTATION.md).
