// API Response Types
export interface User {
  id: string;
  email: string;
  name: string;
  created_at: string;
  updated_at: string;
}

export interface AccountGroup {
  id: string;
  name: string;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface Account {
  id: string;
  name: string;
  account_type: string | null;
  balance: number;
  account_group_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface Transaction {
  id: string;
  account_id: string;
  category_id: string;
  date: string;
  payee: string | null;
  amount: number;
  created_at: string;
  updated_at: string;
  category?: Category;
}

export interface Budget {
  id: string;
  created_at: string;
  updated_at: string;
}

export interface BudgetMonth {
  id: string;
  budget_id: string;
  month: string;
  available: number;
  created_at: string;
  updated_at: string;
  summary?: Summary;
}

export interface Category {
  id: string;
  name: string;
  is_default: boolean;
  category_group_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface CategoryGroup {
  id: string;
  name: string;
  is_default: boolean;
  budget_month_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface CategoryMonth {
  id: string;
  category_id: string;
  category_group_id: string | null;
  month: string;
  allotted: number;
  spent: number;
  balance: number;
  created_at: string;
  updated_at: string;
}

export interface Goal {
  id: string;
  category_id: string;
  goal_type: 'needed_for_spending' | 'target_savings_balance' | 'monthly_savings_builder';
  target_amount: number | null;
  target_date: string | null;
  created_at: string;
  updated_at: string;
}

export interface Summary {
  id: string;
  budget_month_id: string;
  income: number;
  carryover: number;
  available: number;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

// API Request Types
export interface LoginRequest {
  email: string;
  password: string;
}

export interface SignupRequest {
  email: string;
  name: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  user: User;
}

export interface SignupResponse {
  token: string;
  user: User;
}

// Paginated Response
export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    current_page: number;
    per_page: number;
    total_pages: number;
    total_count: number;
  };
}

// API Error
export interface ApiError {
  error: string;
  message: string | string[];
  status?: number;
}
