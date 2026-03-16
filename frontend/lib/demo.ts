/**
 * Demo account credentials. Used by the demo sign-in buttons on the login page.
 * - default: from rails db:seed (test@example.com)
 * - mother: from rails runner db/seeds_demo_mother.rb (mother@demo.com, family of 4)
 * Password change and forgot-password are disabled for these accounts.
 */
const DEMO_PASSWORD = 'SeedPassword1!';

export const DEMO_OPTIONS = [
  { id: 'default', label: 'Default demo', email: 'test@example.com', password: DEMO_PASSWORD },
  { id: 'mother', label: 'Family of 4 demo', email: 'mother@demo.com', password: DEMO_PASSWORD },
] as const;

/** Emails that are demo/seed accounts (must match backend User::DEMO_EMAILS). */
export const DEMO_EMAILS: string[] = [
  ...DEMO_OPTIONS.map((d) => d.email),
  'test@email.com', // seed/mock user used in development
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
