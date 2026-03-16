import type {
  User,
  Account,
  AccountGroup,
  Transaction,
  Budget,
  BudgetMonth,
  Category,
  CategoryGroup,
  CategoryMonth,
  Goal,
  Summary,
  LoginRequest,
  SignupRequest,
  LoginResponse,
  SignupResponse,
  PaginatedResponse,
  ApiError,
} from '@/types/api';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

// Token management
const TOKEN_KEY = 'auth_token';

export function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(TOKEN_KEY, token);
}

export function removeToken(): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(TOKEN_KEY);
}

// Enhanced API fetch with token handling
async function apiFetch<T>(
  path: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getToken();
  
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  try {
    const response = await fetch(`${API_URL}${path}`, {
      ...options,
      headers,
    });

    if (!response.ok) {
      let error: ApiError;
      try {
        const errorData = await response.json();
        error = { ...errorData, status: response.status };
      } catch {
        error = {
          error: 'Request failed',
          message: response.status >= 500
            ? 'Something went wrong. Please try again later.'
            : `HTTP ${response.status}: ${response.statusText}`,
          status: response.status,
        };
      }
      // 5xx: show a user-friendly message (backend may not send one in production)
      if (response.status >= 500 && !error.message) {
        error = { ...error, message: 'Something went wrong. Please try again later.' };
      } else if (response.status >= 500 && typeof error.message === 'string' && error.message.toLowerCase().includes('internal server error')) {
        error = { ...error, message: 'Something went wrong. Please try again later.' };
      }
      throw error;
    }

    // Handle 204 No Content
    if (response.status === 204) {
      return null as T;
    }

    return response.json();
  } catch (error) {
    // Network errors (e.g. backend down, CORS, DNS)
    if (error instanceof TypeError && error.message === 'Failed to fetch') {
      throw {
        error: 'Network error',
        message: 'Unable to connect. Please check your connection and try again.',
        status: 0,
      } as ApiError;
    }
    // Re-throw API errors (4xx/5xx) as-is
    throw error;
  }
}

// Authentication API
export const authApi = {
  async login(credentials: LoginRequest): Promise<LoginResponse> {
    const response = await apiFetch<LoginResponse>('/api/v1/sessions', {
      method: 'POST',
      body: JSON.stringify({ user: credentials }),
    });
    setToken(response.token);
    return response;
  },

  async signup(data: SignupRequest): Promise<SignupResponse> {
    const response = await apiFetch<SignupResponse>('/api/v1/users', {
      method: 'POST',
      body: JSON.stringify({ user: data }),
    });
    setToken(response.token);
    return response;
  },

  async logout(): Promise<void> {
    await apiFetch<void>('/api/v1/sessions', {
      method: 'DELETE',
    });
    removeToken();
  },

  async getCurrentUser(): Promise<User> {
    return apiFetch<User>('/api/v1/users/me');
  },

  /** Request a password reset token for the given email. Returns reset_token if account exists and is not a demo account. */
  async requestPasswordReset(email: string): Promise<{ reset_token?: string; message?: string }> {
    return apiFetch<{ reset_token?: string; message?: string }>('/api/v1/password_reset_requests', {
      method: 'POST',
      body: JSON.stringify({ email: email.trim() }),
    });
  },

  /** Set new password using a reset token (from forgot-password flow). */
  async resetPassword(params: {
    reset_token: string;
    password: string;
    password_confirmation: string;
  }): Promise<{ message: string }> {
    return apiFetch<{ message: string }>('/api/v1/password_reset', {
      method: 'POST',
      body: JSON.stringify(params),
    });
  },

  /** Change password when logged in (current password required). Not allowed for demo users. */
  async changePassword(params: {
    current_password: string;
    password: string;
    password_confirmation: string;
  }): Promise<{ message: string }> {
    return apiFetch<{ message: string }>('/api/v1/users/me/password', {
      method: 'PATCH',
      body: JSON.stringify(params),
    });
  },
};

// Accounts API
export const accountsApi = {
  async list(params?: { page?: number; per_page?: number }): Promise<PaginatedResponse<Account>> {
    const query = new URLSearchParams();
    if (params?.page) query.append('page', params.page.toString());
    if (params?.per_page) query.append('per_page', params.per_page.toString());
    const queryString = query.toString();
    return apiFetch<PaginatedResponse<Account>>(`/api/v1/accounts${queryString ? `?${queryString}` : ''}`);
  },

  async get(id: string): Promise<Account> {
    return apiFetch<Account>(`/api/v1/accounts/${id}`);
  },

  async create(data: Partial<Account>): Promise<Account> {
    return apiFetch<Account>('/api/v1/accounts', {
      method: 'POST',
      body: JSON.stringify({ account: data }),
    });
  },

  async update(id: string, data: Partial<Account>): Promise<Account> {
    return apiFetch<Account>(`/api/v1/accounts/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ account: data }),
    });
  },

  async delete(id: string): Promise<void> {
    return apiFetch<void>(`/api/v1/accounts/${id}`, {
      method: 'DELETE',
    });
  },
};

// Account Groups API
export const accountGroupsApi = {
  async list(params?: { page?: number; per_page?: number }): Promise<PaginatedResponse<AccountGroup>> {
    const query = new URLSearchParams();
    if (params?.page) query.append('page', params.page.toString());
    if (params?.per_page) query.append('per_page', params.per_page.toString());
    const queryString = query.toString();
    return apiFetch<PaginatedResponse<AccountGroup>>(`/api/v1/account_groups${queryString ? `?${queryString}` : ''}`);
  },

  async get(id: string): Promise<AccountGroup> {
    return apiFetch<AccountGroup>(`/api/v1/account_groups/${id}`);
  },

  async create(data: Partial<AccountGroup>): Promise<AccountGroup> {
    return apiFetch<AccountGroup>('/api/v1/account_groups', {
      method: 'POST',
      body: JSON.stringify({ account_group: data }),
    });
  },

  async update(id: string, data: Partial<AccountGroup>): Promise<AccountGroup> {
    return apiFetch<AccountGroup>(`/api/v1/account_groups/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ account_group: data }),
    });
  },

  async delete(id: string): Promise<void> {
    return apiFetch<void>(`/api/v1/account_groups/${id}`, {
      method: 'DELETE',
    });
  },
};

// Transactions API
export const transactionsApi = {
  async list(params?: {
    page?: number;
    per_page?: number;
    account_id?: string;
    category_id?: string;
    start_date?: string;
    end_date?: string;
    include?: string;
    q?: string;
  }): Promise<PaginatedResponse<Transaction>> {
    const query = new URLSearchParams();
    if (params?.page) query.append('page', params.page.toString());
    if (params?.per_page) query.append('per_page', params.per_page.toString());
    if (params?.account_id) query.append('account_id', params.account_id);
    if (params?.category_id) query.append('category_id', params.category_id);
    if (params?.start_date) query.append('start_date', params.start_date);
    if (params?.end_date) query.append('end_date', params.end_date);
    if (params?.include) query.append('include', params.include);
    if (params?.q) query.append('q', params.q);
    const queryString = query.toString();
    return apiFetch<PaginatedResponse<Transaction>>(`/api/v1/transactions${queryString ? `?${queryString}` : ''}`);
  },

  async get(id: string): Promise<Transaction> {
    return apiFetch<Transaction>(`/api/v1/transactions/${id}`);
  },

  async create(data: Partial<Transaction>): Promise<Transaction> {
    return apiFetch<Transaction>('/api/v1/transactions', {
      method: 'POST',
      body: JSON.stringify({ transaction: data }),
    });
  },

  async update(id: string, data: Partial<Transaction>): Promise<Transaction> {
    return apiFetch<Transaction>(`/api/v1/transactions/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ transaction: data }),
    });
  },

  async delete(id: string): Promise<void> {
    return apiFetch<void>(`/api/v1/transactions/${id}`, {
      method: 'DELETE',
    });
  },
};

// Budgets API
export const budgetsApi = {
  async list(params?: { page?: number; per_page?: number }): Promise<PaginatedResponse<Budget>> {
    const query = new URLSearchParams();
    if (params?.page) query.append('page', params.page.toString());
    if (params?.per_page) query.append('per_page', params.per_page.toString());
    const queryString = query.toString();
    return apiFetch<PaginatedResponse<Budget>>(`/api/v1/budgets${queryString ? `?${queryString}` : ''}`);
  },

  async get(id: string): Promise<Budget> {
    return apiFetch<Budget>(`/api/v1/budgets/${id}`);
  },

  async create(): Promise<Budget> {
    return apiFetch<Budget>('/api/v1/budgets', {
      method: 'POST',
      body: JSON.stringify({ budget: {} }),
    });
  },
};

// Budget Months API
export const budgetMonthsApi = {
  async list(params?: {
    page?: number;
    per_page?: number;
    budget_id?: string;
    month?: string;
    include?: string;
  }): Promise<PaginatedResponse<BudgetMonth>> {
    const query = new URLSearchParams();
    if (params?.page) query.append('page', params.page.toString());
    if (params?.per_page) query.append('per_page', params.per_page.toString());
    if (params?.budget_id) query.append('budget_id', params.budget_id);
    if (params?.month) query.append('month', params.month);
    if (params?.include) query.append('include', params.include);
    const queryString = query.toString();
    return apiFetch<PaginatedResponse<BudgetMonth>>(`/api/v1/budget_months${queryString ? `?${queryString}` : ''}`);
  },

  async get(id: string, params?: { include?: string }): Promise<BudgetMonth> {
    const query = params?.include ? `?include=${params.include}` : '';
    return apiFetch<BudgetMonth>(`/api/v1/budget_months/${id}${query}`);
  },

  async transition(budgetId: string, targetMonth?: string): Promise<{ budget_month: BudgetMonth; message: string }> {
    const query = new URLSearchParams();
    query.append('budget_id', budgetId);
    if (targetMonth) query.append('target_month', targetMonth);
    return apiFetch<{ budget_month: BudgetMonth; message: string }>(`/api/v1/budget_months/transition?${query.toString()}`, {
      method: 'POST',
    });
  },
};

// Categories API
export const categoriesApi = {
  async list(params?: { page?: number; per_page?: number }): Promise<PaginatedResponse<Category>> {
    const query = new URLSearchParams();
    if (params?.page) query.append('page', params.page.toString());
    if (params?.per_page) query.append('per_page', params.per_page.toString());
    const queryString = query.toString();
    return apiFetch<PaginatedResponse<Category>>(`/api/v1/categories${queryString ? `?${queryString}` : ''}`);
  },

  async get(id: string): Promise<Category> {
    return apiFetch<Category>(`/api/v1/categories/${id}`);
  },

  async create(data: Partial<Category>): Promise<Category> {
    return apiFetch<Category>('/api/v1/categories', {
      method: 'POST',
      body: JSON.stringify({ category: data }),
    });
  },

  async update(id: string, data: Partial<Category>): Promise<Category> {
    return apiFetch<Category>(`/api/v1/categories/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ category: data }),
    });
  },

  async delete(id: string): Promise<void> {
    return apiFetch<void>(`/api/v1/categories/${id}`, {
      method: 'DELETE',
    });
  },
};

// Category Groups API
export const categoryGroupsApi = {
  async list(params?: {
    page?: number;
    per_page?: number;
    budget_month_id?: string;
  }): Promise<PaginatedResponse<CategoryGroup>> {
    const query = new URLSearchParams();
    if (params?.page) query.append('page', params.page.toString());
    if (params?.per_page) query.append('per_page', params.per_page.toString());
    if (params?.budget_month_id) query.append('budget_month_id', params.budget_month_id);
    const queryString = query.toString();
    return apiFetch<PaginatedResponse<CategoryGroup>>(
      `/api/v1/category_groups${queryString ? `?${queryString}` : ''}`
    );
  },

  async create(data: Partial<CategoryGroup>): Promise<CategoryGroup> {
    return apiFetch<CategoryGroup>('/api/v1/category_groups', {
      method: 'POST',
      body: JSON.stringify({ category_group: data }),
    });
  },

  async update(id: string, data: Partial<CategoryGroup>): Promise<CategoryGroup> {
    return apiFetch<CategoryGroup>(`/api/v1/category_groups/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ category_group: data }),
    });
  },
};

// Category Months API
export const categoryMonthsApi = {
  async list(params?: {
    page?: number;
    per_page?: number;
    category_id?: string;
    category_group_id?: string;
    month?: string;
  }): Promise<PaginatedResponse<CategoryMonth>> {
    const query = new URLSearchParams();
    if (params?.page) query.append('page', params.page.toString());
    if (params?.per_page) query.append('per_page', params.per_page.toString());
    if (params?.category_id) query.append('category_id', params.category_id);
    if (params?.category_group_id) query.append('category_group_id', params.category_group_id);
    if (params?.month) query.append('month', params.month);
    const queryString = query.toString();
    return apiFetch<PaginatedResponse<CategoryMonth>>(
      `/api/v1/category_months${queryString ? `?${queryString}` : ''}`
    );
  },

  async update(id: string, data: Partial<Pick<CategoryMonth, 'allotted' | 'category_group_id' | 'month'>>): Promise<CategoryMonth> {
    return apiFetch<CategoryMonth>(`/api/v1/category_months/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ category_month: data }),
    });
  },
};

// Goals API
export const goalsApi = {
  async list(params?: {
    page?: number;
    per_page?: number;
    category_id?: string;
    goal_type?: string;
  }): Promise<PaginatedResponse<Goal>> {
    const query = new URLSearchParams();
    if (params?.page) query.append('page', params.page.toString());
    if (params?.per_page) query.append('per_page', params.per_page.toString());
    if (params?.category_id) query.append('category_id', params.category_id);
    if (params?.goal_type) query.append('goal_type', params.goal_type);
    const queryString = query.toString();
    return apiFetch<PaginatedResponse<Goal>>(`/api/v1/goals${queryString ? `?${queryString}` : ''}`);
  },

  async get(id: string): Promise<Goal> {
    return apiFetch<Goal>(`/api/v1/goals/${id}`);
  },

  async create(data: Partial<Goal>): Promise<Goal> {
    return apiFetch<Goal>('/api/v1/goals', {
      method: 'POST',
      body: JSON.stringify({ goal: data }),
    });
  },

  async update(id: string, data: Partial<Goal>): Promise<Goal> {
    return apiFetch<Goal>(`/api/v1/goals/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ goal: data }),
    });
  },

  async delete(id: string): Promise<void> {
    return apiFetch<void>(`/api/v1/goals/${id}`, {
      method: 'DELETE',
    });
  },
};
