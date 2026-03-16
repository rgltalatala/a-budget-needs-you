/**
 * Parse an ISO date-only string (YYYY-MM-DD) as local date and format as "Month Year".
 * Using new Date(isoString) parses as UTC midnight, which can show the wrong month in western timezones.
 */
export function formatBudgetMonthLabel(monthStr: string): string {
  const s = monthStr.slice(0, 10);
  const [y, m] = s.split("-").map(Number);
  const date = new Date(y, (m ?? 1) - 1, 1);
  return date.toLocaleDateString(undefined, { year: "numeric", month: "long" });
}

/** Return start and end date strings (YYYY-MM-DD) for a calendar month. */
export function getMonthBounds(
  year: number,
  month: number
): { start: string; end: string } {
  const start = `${year}-${String(month).padStart(2, "0")}-01`;
  const lastDay = new Date(year, month, 0).getDate();
  const end = `${year}-${String(month).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;
  return { start, end };
}

/** Return start and end date strings (YYYY-MM-DD) for a calendar year. */
export function getYearBounds(year: number): { start: string; end: string } {
  return {
    start: `${year}-01-01`,
    end: `${year}-12-31`,
  };
}

/** Get "YYYY-MM" from an ISO date string (e.g. "2026-02-01" -> "2026-02"). */
export function getMonthKey(dateStr: string): string {
  return dateStr.slice(0, 7);
}

/** Get the month key for the month that is `delta` months before/after the given date string. */
export function getAdjacentMonthKey(dateStr: string, delta: number): string {
  const key = getMonthKey(dateStr);
  const [y, m] = key.split("-").map(Number);
  const date = new Date(y, m - 1 + delta, 1);
  const year = date.getFullYear();
  const month = date.getMonth() + 1;
  return `${year}-${String(month).padStart(2, "0")}`;
}

/** Format a date as YYYY-MM-DD (local). */
export function toISODateString(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

/**
 * Parse an ISO date-only string (YYYY-MM-DD) as local calendar date.
 * Avoids new Date(isoString) which parses as UTC midnight and can show the previous day in western timezones.
 */
export function parseDateOnlyLocal(dateStr: string): Date {
  const s = (dateStr && String(dateStr).slice(0, 10)) || "";
  const [y, m, d] = s.split("-").map(Number);
  return new Date(y ?? 0, (m ?? 1) - 1, d ?? 1);
}

/** Format a transaction date string (YYYY-MM-DD) for display in the user's locale, without timezone shift. */
export function formatTransactionDate(dateStr: string): string {
  return parseDateOnlyLocal(dateStr).toLocaleDateString();
}

/** Preset date ranges: start and end (YYYY-MM-DD). */
export type DateRangePreset = "all" | "this_month" | "last_month" | "last_7" | "last_30" | "last_90" | "custom";

export function getDateRangeForPreset(
  preset: DateRangePreset,
  customStart?: string,
  customEnd?: string
): { start: string | undefined; end: string | undefined } {
  const today = new Date();
  const todayStr = toISODateString(today);
  if (preset === "all") return { start: undefined, end: undefined };
  if (preset === "custom" && customStart && customEnd)
    return { start: customStart.slice(0, 10), end: customEnd.slice(0, 10) };
  if (preset === "this_month") {
    const y = today.getFullYear();
    const m = today.getMonth() + 1;
    return getMonthBounds(y, m);
  }
  if (preset === "last_month") {
    const y = today.getFullYear();
    const m = today.getMonth();
    const lastMonth = m === 0 ? 12 : m;
    const lastYear = m === 0 ? y - 1 : y;
    return getMonthBounds(lastYear, lastMonth);
  }
  const end = new Date(today);
  const start = new Date(today);
  if (preset === "last_7") start.setDate(start.getDate() - 6);
  else if (preset === "last_30") start.setDate(start.getDate() - 29);
  else if (preset === "last_90") start.setDate(start.getDate() - 89);
  return { start: toISODateString(start), end: todayStr };
}
