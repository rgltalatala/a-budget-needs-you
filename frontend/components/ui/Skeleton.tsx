import type { ReactNode } from 'react';

interface SkeletonProps {
  className?: string;
  children?: ReactNode;
}

export function Skeleton({ className = '', children }: SkeletonProps) {
  return (
    <div
      className={`animate-pulse rounded bg-gray-200 ${className}`}
      aria-hidden
    >
      {children}
    </div>
  );
}

export function CardSkeleton() {
  return (
    <div className="bg-white rounded-lg shadow-md p-6 border-2 border-gray-300">
      <Skeleton className="h-5 w-24 mb-4" />
      <Skeleton className="h-9 w-32 mb-2" />
      <Skeleton className="h-4 w-full max-w-[120px]" />
    </div>
  );
}

export function TableRowSkeleton({ cols = 4 }: { cols?: number }) {
  return (
    <div
      className="grid gap-3 py-3 px-2 border-b border-gray-200 items-center"
      style={{ gridTemplateColumns: `repeat(${cols}, minmax(0, 1fr))` }}
    >
      {Array.from({ length: cols }).map((_, i) => (
        <Skeleton key={i} className="h-4" />
      ))}
    </div>
  );
}
