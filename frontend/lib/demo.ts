/**
 * Demo account credentials. Used by the demo sign-in buttons on the login page.
 * - single: from rails db:seed (USER 1 — 50/30/20 / single male scenario)
 * - family: from rails db:seed (USER 2 — family scenario)
 * Optional: `rails runner db/seeds_demo_mother.rb` adds mother@demo.com (not included in default seed).
 * Password change and forgot-password are disabled for these accounts.
 */
const DEMO_PASSWORD = 'SeedPassword1!';

export const DEMO_OPTIONS = [
  { id: 'single', label: 'Single demo', email: 'single@example.com', password: DEMO_PASSWORD },
  { id: 'family', label: 'Family demo', email: 'family@example.com', password: DEMO_PASSWORD },
] as const;

/** Emails that are demo/seed accounts (must match backend User::DEMO_EMAILS). */
export const DEMO_EMAILS: string[] = [
  ...DEMO_OPTIONS.map((d) => d.email),
  'mother@demo.com', // optional: rails runner db/seeds_demo_mother.rb
  'test@email.com', // dev: ensure_demo_user + seeds_mock_data default
];

/** Returns true if the given email belongs to a demo account. */
export function isDemoEmail(email: string | null | undefined): boolean {
  if (!email || typeof email !== 'string') return false;
  return DEMO_EMAILS.includes(email.trim().toLowerCase());
}

/** @deprecated Use DEMO_OPTIONS[0] or pick by id; kept for backward compatibility. */
export const DEMO_CREDENTIALS = {
  email: DEMO_OPTIONS[0].email,
  password: DEMO_OPTIONS[0].password,
} as const;
