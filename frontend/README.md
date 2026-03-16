# Frontend (Next.js)

Next.js app for the budgeting UI. Runs on port 3000 and talks to the Rails backend.

## Run locally

From the project root, or from `frontend/`:

```bash
npm install
npm run dev
```

Open **http://localhost:3000** in your browser.

For local development you don’t need any env file: the app uses `http://localhost:3001` as the API URL by default. To override, set `NEXT_PUBLIC_API_URL` (e.g. in `.env.local` from `.env.example`).

## Tests

```bash
npm run test
```
