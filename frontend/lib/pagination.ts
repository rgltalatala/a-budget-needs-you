import type { PaginatedResponse } from "@/types/api";

type ListParams = Record<string, unknown> & { page?: number; per_page?: number };

/**
 * Call a paginated list API repeatedly and return the concatenated data array.
 * Uses per_page from baseParams (default 100) and stops when current_page >= total_pages.
 */
export async function fetchAllPages<T, P extends ListParams>(
  listFn: (params: P) => Promise<PaginatedResponse<T>>,
  baseParams: P
): Promise<T[]> {
  const perPage = baseParams.per_page ?? 100;
  const all: T[] = [];
  let page = 1;
  let totalPages = 1;
  do {
    const res = await listFn({ ...baseParams, page, per_page: perPage } as P);
    all.push(...res.data);
    totalPages = res.meta?.total_pages ?? 1;
    page += 1;
  } while (page <= totalPages);
  return all;
}
