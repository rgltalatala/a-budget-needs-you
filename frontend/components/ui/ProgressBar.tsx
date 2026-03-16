"use client";

interface ProgressBarProps {
  /** The amount allotted to this category */
  allotted: number;
  /** The amount spent in this category */
  spent: number;
  /** The goal amount (target_amount from Goal) */
  goalAmount: number | null;
  /** Optional className for styling */
  className?: string;
}

/**
 * ProgressBar component that visualizes category budget progress.
 *
 * Allotted = money assigned from "Ready to assign" this month. Goal = target amount (separate).
 * Bar shows how much of the goal is funded by this category's available amount (allotted - spent).
 *
 * - If no money allotted: no green bar (width = 0)
 * - If available (allotted - spent) reaches goal: fully green bar (100% width)
 * - As spending increases, green bar gets shorter
 * - If overspent (spent > allotted): bar turns red at 100% width
 */
export function ProgressBar({
  allotted,
  spent,
  goalAmount,
  className = "",
}: ProgressBarProps) {
  // Use 1 as fallback when no goal so we still show a bar (e.g. 0% progress)
  const effectiveGoal = goalAmount && goalAmount > 0 ? goalAmount : 1;

  // Determine if overspent
  const isOverspent = spent > allotted;

  // Calculate available amount (allotted - spent)
  const available = allotted - spent;

  // Calculate bar width based on goal
  // If no money allotted, width = 0 (no green)
  // If allotted = goal and no spending, width = 100% (fully green)
  // As spent increases, width decreases
  // If overspent, show red bar at 100% width
  let barWidth: number;
  if (isOverspent) {
    // Overspent: show red bar at 100% width
    barWidth = 100;
  } else if (allotted === 0) {
    // No money allotted: no green bar
    barWidth = 0;
  } else {
    // Calculate percentage: (available / effectiveGoal) * 100
    // Cap at 100% (can't exceed goal)
    barWidth = Math.min(100, Math.max(0, (available / effectiveGoal) * 100));
  }

  const barColor = isOverspent ? "bg-red-500" : "bg-green-500";

  // Calculate percentage for display (based on available vs goal)
  const progressPercent =
    allotted > 0 && effectiveGoal > 0
      ? Math.min(100, Math.max(0, (available / effectiveGoal) * 100))
      : 0;

  return (
    <div className={`w-full ${className}`}>
      <div className="w-full bg-gray-200 rounded-full h-2.5 overflow-hidden">
        <div
          className={`h-2.5 rounded-full transition-all duration-300 ${barColor}`}
          style={{ width: `${barWidth}%` }}
        />
      </div>
    </div>
  );
}
