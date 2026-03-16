# Design and Implementation

This document details the design and implementation of the Personal Budgeting Application backend (Rails API) and how it fits with the frontend.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Phase 1: REST API Fundamentals](#phase-1-rest-api-fundamentals)
4. [Phase 2: Authentication & Authorization](#phase-2-authentication--authorization)
5. [Phase 3: Advanced Backend Patterns](#phase-3-advanced-backend-patterns-serializers-scopes-service-objects)
6. [API Endpoints](#api-endpoints)
7. [Authentication Flow](#authentication-flow)
8. [Testing](#testing)
9. [File Structure](#file-structure)
10. [Key Concepts Learned](#key-concepts-learned)

---

## Overview

This Rails 8.1 API-only application implements a personal budgeting system using the envelope budgeting method (similar to You Need A Budget). The application provides a complete REST API with JWT-based authentication, user-scoped data access, and comprehensive error handling.

**Technology Stack:**
- **Framework:** Rails 8.1 (API-only mode)
- **Database:** PostgreSQL with UUID primary keys
- **Authentication:** JWT tokens with bcrypt password hashing
- **Testing:** Minitest (Rails default)

---

## Architecture

```
Frontend (Next.js)  ←→  REST API (Rails)  ←→  PostgreSQL
   TypeScript              Ruby/Rails          UUID Primary Keys
   React Components        JSON Responses      Envelope Budgeting
```

### Key Architectural Decisions

1. **API Versioning:** All endpoints are namespaced under `/api/v1/` for future versioning support
2. **User Scoping:** All data queries are automatically scoped to the current authenticated user
3. **Error Handling:** Centralized error handling in `BaseController` with consistent JSON error responses
4. **Authentication:** JWT tokens with 24-hour expiration, stored in Authorization header

---

## Phase 1: REST API Fundamentals

### 1.1 API Structure Setup

**Files Created:**
- `app/controllers/api/v1/base_controller.rb` - Base controller with error handling
- `config/initializers/cors.rb` - Updated for localhost development

**Key Features:**
- Centralized error handling for:
  - `ActiveRecord::RecordNotFound` → 404 Not Found
  - `ActiveRecord::RecordInvalid` → 422 Unprocessable Entity
  - `ActionController::ParameterMissing` → 400 Bad Request
- CORS configured to allow requests from `localhost:3000` and `localhost:3001`

### 1.2 Accounts API

**File:** `app/controllers/api/v1/accounts_controller.rb`

**Endpoints:**
- `GET /api/v1/accounts` - List all user's accounts
- `GET /api/v1/accounts/:id` - Show specific account
- `POST /api/v1/accounts` - Create new account
- `PATCH/PUT /api/v1/accounts/:id` - Update account
- `DELETE /api/v1/accounts/:id` - Delete account

**Features:**
- Full CRUD operations
- User-scoped queries (users only see their own accounts)
- Strong parameters for security
- Validation error handling

**Test File:** `test/integration/api/v1/accounts_test.rb`

### 1.3 Account Groups API

**File:** `app/controllers/api/v1/account_groups_controller.rb`

**Endpoints:**
- `GET /api/v1/account_groups` - List all user's account groups
- `GET /api/v1/account_groups/:id` - Show specific account group
- `POST /api/v1/account_groups` - Create new account group
- `PATCH/PUT /api/v1/account_groups/:id` - Update account group
- `DELETE /api/v1/account_groups/:id` - Delete account group (with dependency check)

**Features:**
- Prevents deletion of account groups that have associated accounts
- User-scoped queries
- Handles nested resource relationships

**Test File:** `test/integration/api/v1/account_groups_test.rb`

### 1.4 Categories API

**File:** `app/controllers/api/v1/categories_controller.rb`

**Endpoints:**
- `GET /api/v1/categories` - List all user's categories (with optional filtering)
- `GET /api/v1/categories/:id` - Show specific category
- `POST /api/v1/categories` - Create new category
- `PATCH/PUT /api/v1/categories/:id` - Update category
- `DELETE /api/v1/categories/:id` - Delete category

**Features:**
- Filtering support (by `user_id`, `is_default`)
- User-scoped queries
- Category management for budget envelopes

**Test File:** `test/integration/api/v1/categories_test.rb`

### 1.5 Transactions API

**File:** `app/controllers/api/v1/transactions_controller.rb`

**Endpoints:**
- `GET /api/v1/transactions` - List all user's transactions (with filtering)
- `GET /api/v1/transactions/:id` - Show specific transaction
- `POST /api/v1/transactions` - Create new transaction
- `PATCH/PUT /api/v1/transactions/:id` - Update transaction
- `DELETE /api/v1/transactions/:id` - Delete transaction

**Features:**
- Advanced filtering:
  - By `account_id` (must belong to user)
  - By `category_id` (must belong to user)
  - By date range (`start_date`, `end_date`)
- Ordered by date (most recent first)
- Validates account and category belong to current user
- Complex validations for transaction data

**Test File:** `test/integration/api/v1/transactions_test.rb`

---

## Phase 2: Authentication & Authorization

### 2.1 User Authentication Setup

**Files Created/Modified:**
- `Gemfile` - Added `bcrypt` gem
- `db/migrate/20260123000004_add_password_digest_to_users.rb` - Migration to add password_digest
- `app/models/user.rb` - Added `has_secure_password` and validations

**Features:**
- Password hashing using bcrypt
- Minimum password length validation (6 characters)
- Email uniqueness validation
- Secure password storage (never stores plain text passwords)

### 2.2 JWT Token Management

**Files Created:**
- `app/services/jwt_service.rb` - JWT token generation and validation service
- `Gemfile` - Added `jwt` gem

**Features:**
- Token generation with 24-hour expiration
- Token validation and decoding
- Uses Rails secret key base for signing
- HS256 algorithm for token signing

**JwtService Methods:**
- `JwtService.encode(payload)` - Encodes a payload into a JWT token
- `JwtService.decode(token)` - Decodes and validates a JWT token
- `JwtService.generate_token(user)` - Generates a token for a user

### 2.3 Authorization & Current User

**Files Created:**
- `app/controllers/concerns/authenticable.rb` - Authentication concern
- `app/models/current.rb` - Thread-safe current user storage

**Features:**
- `Authenticable` concern for protected controllers
- Extracts JWT token from `Authorization: Bearer <token>` header
- Validates token and sets current user
- Thread-safe current user access via `Current.user`
- Automatic 401 Unauthorized response for invalid/missing tokens

**Usage:**
```ruby
class MyController < BaseController
  include Authenticable  # Requires authentication
  
  def index
    # current_user is available here
    @items = current_user.items
  end
end
```

### 2.4 Secure Controllers

**Files Modified:**
- All resource controllers now include `Authenticable`
- All queries are user-scoped
- Removed `user_id` from permitted parameters (automatically set from current_user)

**Security Features:**
- All endpoints (except login/signup) require authentication
- Users can only access their own data
- Account and category validation in transactions (must belong to user)
- Automatic user assignment on record creation

---

## Phase 3: Advanced Backend Patterns (Serializers, Scopes, Service Objects)

### 3.1 Serializers

**Location:** `app/serializers/api/v1/`

All API responses use serializer classes that inherit from `BaseSerializer`. Serializers control the JSON shape and support optional `include` params for nested associations.

**Serializers in use:**
- `UserSerializer`, `AccountSerializer`, `AccountGroupSerializer`
- `CategorySerializer`, `CategoryGroupSerializer`, `CategoryMonthSerializer`
- `TransactionSerializer`, `BudgetSerializer`, `BudgetMonthSerializer`
- `SummarySerializer`, `GoalSerializer`

Controllers use `serialize_object`, `serialize_collection`, and `render_paginated(collection, SerializerClass)` from `BaseController`.

### 3.2 Scopes

**Transaction** (`app/models/transaction.rb`): `recent_first`, `in_date_range`, `from_date`, `to_date`, `in_month`, `search_payee`, `expenses`  
**BudgetMonth**: `by_month_desc`  
**CategoryMonth**: `creation_order`, `for_month`, `in_groups`  
**CategoryGroup**: `creation_order`, `for_budget_month`  
**Goal**: `by_goal_type`  
**Category**: `default_only`, `by_default`

Scopes are used in controllers (e.g. `current_user.transactions.recent_first`, `.in_date_range(start_d, end_d)`, `.search_payee(params[:q])`) and in services (e.g. `CategoryMonth.for_category_groups(ids).for_month(month)`, `Transaction.in_month(month).expenses`).

### 3.3 Service Objects

**Location:** `app/services/`

- **JwtService** – JWT encode/decode and token generation for auth
- **BudgetService** – `calculate_budget_month_available`, income transaction processing, `refresh_carryover_to_following_months`
- **TransactionService** – process/revert transactions, update category spending and account balances
- **MonthTransitionService** – create a new budget month with structure and carryover from the previous month
- **CategoryCarryoverService** – apply category balances and Ready to assign from one month to the next
- **GoalTrackingService** – goal progress calculations

---

## API Endpoints

### Authentication Endpoints

#### Sign Up
```http
POST /api/v1/users
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "name": "John Doe",
    "password": "password123",
    "password_confirmation": "password123"
  }
}
```

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe"
  },
  "token": "jwt_token_here",
  "message": "User created successfully"
}
```

#### Login
```http
POST /api/v1/sessions
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe"
  },
  "token": "jwt_token_here",
  "message": "Login successful"
}
```

#### Logout
```http
DELETE /api/v1/sessions
Authorization: Bearer <token>
```

### Resource Endpoints

All resource endpoints require authentication via `Authorization: Bearer <token>` header.

#### Accounts
- `GET /api/v1/accounts` - List accounts
- `GET /api/v1/accounts/:id` - Show account
- `POST /api/v1/accounts` - Create account
- `PATCH /api/v1/accounts/:id` - Update account
- `DELETE /api/v1/accounts/:id` - Delete account

#### Account Groups
- `GET /api/v1/account_groups` - List account groups
- `GET /api/v1/account_groups/:id` - Show account group
- `POST /api/v1/account_groups` - Create account group
- `PATCH /api/v1/account_groups/:id` - Update account group
- `DELETE /api/v1/account_groups/:id` - Delete account group

#### Categories
- `GET /api/v1/categories` - List categories
- `GET /api/v1/categories/:id` - Show category
- `POST /api/v1/categories` - Create category
- `PATCH /api/v1/categories/:id` - Update category
- `DELETE /api/v1/categories/:id` - Delete category

#### Transactions
- `GET /api/v1/transactions?account_id=:id&start_date=2026-01-01&end_date=2026-01-31` - List transactions (with filters)
- `GET /api/v1/transactions/:id` - Show transaction
- `POST /api/v1/transactions` - Create transaction
- `PATCH /api/v1/transactions/:id` - Update transaction
- `DELETE /api/v1/transactions/:id` - Delete transaction

#### Summaries
- `GET /api/v1/summaries?budget_month_id=:id` - List summaries (optional filter by budget month)
- `GET /api/v1/summaries/:id` - Show summary
- `POST /api/v1/summaries` - Create summary (body: `{ "summary": { "budget_month_id", "income", "carryover", "available", "notes" } }`)
- `PATCH /api/v1/summaries/:id` - Update summary
- `DELETE /api/v1/summaries/:id` - Delete summary

---

## Summaries API (detailed)

### What it is

The **Summary** resource represents **one row per budget month**: income, carryover, available, and notes for that month. It is backed by the `summaries` table (unique on `budget_month_id`). Backend model: `Summary` (`app/models/summary.rb`); controller: `Api::V1::SummariesController`; serializer: `Api::V1::SummarySerializer`.

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/summaries` | List current user’s summaries. Optional query: `budget_month_id` to filter by budget month. |
| GET | `/api/v1/summaries/:id` | Show one summary by id. |
| POST | `/api/v1/summaries` | Create a summary. Params: `summary: { budget_month_id, income, carryover, available, notes }`. `budget_month_id` must belong to the current user. |
| PATCH | `/api/v1/summaries/:id` | Update a summary. Same params as create. |
| DELETE | `/api/v1/summaries/:id` | Delete a summary. |

### How the frontend gets summary data today

Summary data is **not** loaded via the summaries API in the current UI. It is loaded as an **embedded include** on the budget month resource:

- When the frontend fetches budget months (list or show), it passes **`include=summary`**.
- The backend `BudgetMonthSerializer` includes the budget month’s summary (if present) in the JSON: `budget_month.summary` with `id`, `budget_month_id`, `income`, `carryover`, `available`, `notes`, timestamps.
- The dashboard and **Category Summary Panel** use `budgetMonth.summary` from that embedded payload (e.g. income, carryover, “to be budgeted” / available).

So “opening a category’s summary” (the side panel for a selected category) does **not** call the summaries API because:

1. The panel shows **budget-month-level** summary (income, carryover, available) plus **category-level** data (allotted, spent, goals). The “summary” in the panel is the **budget month’s** summary, not a per-category summary.
2. That budget month summary is already present on the `budget_month` object the app loaded with `include=summary` when fetching budget months. No separate `GET /api/v1/summaries` or `GET /api/v1/summaries/:id` is needed.

The standalone **Summaries API** is available for direct CRUD (e.g. creating or updating a summary by id, or listing summaries by `budget_month_id`). The frontend currently has no `summariesApi` client and does not use these endpoints; all summary data in the UI comes from the embedded summary on budget months.

---

## Authentication Flow

### 1. User Registration
1. Client sends POST request to `/api/v1/users` with user data
2. Server validates data, creates user, hashes password
3. Server generates JWT token and returns user data + token

### 2. User Login
1. Client sends POST request to `/api/v1/sessions` with email/password
2. Server finds user by email and authenticates password
3. Server generates JWT token and returns user data + token

### 3. Authenticated Requests
1. Client includes token in `Authorization: Bearer <token>` header
2. `Authenticable` concern extracts token from header
3. `JwtService` validates and decodes token
4. Current user is set from token's `user_id`
5. Controller action executes with `current_user` available

### 4. Token Expiration
- Tokens expire after 24 hours
- Expired tokens return 401 Unauthorized
- Client must re-authenticate to get new token

---

## Testing

### Test Structure

**Integration tests** (API and health):

- `test/integration/api/health_test.rb` - Health endpoint (`GET /health`)
- `test/integration/api/v1/accounts_test.rb` - Account CRUD operations
- `test/integration/api/v1/account_groups_test.rb` - Account group operations and dependency checks
- `test/integration/api/v1/budgets_test.rb` - Budget operations
- `test/integration/api/v1/budget_months_test.rb` - Budget month CRUD and filters
- `test/integration/api/v1/categories_test.rb` - Category operations and filtering
- `test/integration/api/v1/category_groups_test.rb` - Category group operations
- `test/integration/api/v1/category_months_test.rb` - Category month operations
- `test/integration/api/v1/goals_test.rb` - Goal operations
- `test/integration/api/v1/month_transition_test.rb` - Month transition endpoint
- `test/integration/api/v1/sessions_test.rb` - Login/logout functionality
- `test/integration/api/v1/summaries_test.rb` - Summary operations
- `test/integration/api/v1/transactions_test.rb` - Transaction operations and validations
- `test/integration/api/v1/users_test.rb` - User registration and validation

**Service tests** (`test/services/`):

- `budget_service_test.rb` - Budget available calculation, income processing
- `category_carryover_service_test.rb` - Category carryover calculation
- `goal_tracking_service_test.rb` - Goal tracking logic
- `month_transition_service_test.rb` - Month transition flow
- `transaction_service_test.rb` - Transaction process/revert, account and category_month updates

**Model tests** (`test/models/`):

- `account_test.rb`, `account_group_test.rb`, `budget_month_test.rb`, `transaction_test.rb`, `transaction_income_test.rb`, `user_test.rb`

### Phase 6 (Testing Enhancements)

Phase 6 adds TransactionService tests, health endpoint test, and keeps this documentation in sync with the test suite.

### Running Tests

```bash
# Run all tests
rails test

# Run specific test file
rails test test/integration/api/v1/accounts_test.rb

# Run with verbose output
rails test --verbose
```

### Test Fixtures

Fixtures are located in `test/fixtures/`: `users.yml`, `account_groups.yml`, `accounts.yml`, `budgets.yml`, `budget_months.yml`, `categories.yml`, `category_groups.yml`, `category_months.yml`, `goals.yml`, `summaries.yml`, `transactions.yml`.

### Phase 7 (Production Readiness)

Phase 7 covers production deployment:

1. **Environment and configuration**
   - Backend: `RAILS_ENV=production` behavior, env-based config (`config/environments/production.rb`), production env vars documented (SECRET_KEY_BASE, DATABASE_URL, RAILS_LOG_LEVEL); `config/database.yml` production uses `DATABASE_URL` when set.
   - Frontend: `NEXT_PUBLIC_API_URL` in `lib/api.ts`; `.env.example` added; `frontend/README.md` documents env vars; production build and start commands documented in root README.

2. **Security and robustness**
   - Backend: `config.force_ssl = true` in production; SSL redirect excluded for `/health` and `/up`; secure headers set (X-Content-Type-Options: nosniff, X-Frame-Options: SAMEORIGIN, Referrer-Policy). Rate limiting left optional.
   - CORS: In production, origins restricted to `ALLOWED_ORIGINS` env var (comma-separated); development unchanged (localhost). Documented in production.rb and README.

3. **Observability and operations**
   - Backend: Production logging to STDOUT with `request_id` tag; `RAILS_LOG_LEVEL` env; sensitive params filtered (config/initializers/filter_parameter_logging.rb); `/up`, `/health`, `/ready` silenced from logs via regex.
   - Health: `/health` (liveness) and `/ready` (readiness with DB connectivity check) for load balancers; `/ready` returns 503 when DB is unavailable.

4. **Error handling**
   - Backend: `ApplicationController` rescues `StandardError`, logs backtrace server-side, and in production renders `{ error: "Internal server error" }` only (no message/backtrace). `BaseController` record_not_found and parameter_missing omit exception message in production. Consistent JSON error format.
   - Frontend: `lib/api.ts` shows user-friendly message for 5xx ("Something went wrong. Please try again later.") and for network errors ("Unable to connect. Please check your connection and try again.").

5. **Deployment and docs**
   - README: "Production deployment" section with checklist of required env vars (RAILS_ENV, SECRET_KEY_BASE, DATABASE_URL, ALLOWED_ORIGINS; NEXT_PUBLIC_API_URL for frontend), build/run commands, and note on platforms (Render, Fly, Vercel). Dockerfile(s) left optional.

---

## File Structure

```
backend/
├── app/
│   ├── controllers/
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── base_controller.rb          # Base controller with error handling
│   │   │       ├── accounts_controller.rb       # Accounts CRUD
│   │   │       ├── account_groups_controller.rb # Account groups CRUD
│   │   │       ├── categories_controller.rb     # Categories CRUD
│   │   │       ├── transactions_controller.rb    # Transactions CRUD
│   │   │       ├── sessions_controller.rb      # Login/logout
│   │   │       └── users_controller.rb         # User registration
│   │   └── concerns/
│   │       └── authenticable.rb                 # Authentication concern
│   ├── models/
│   │   ├── user.rb                              # User model with authentication
│   │   ├── account.rb                           # Account model
│   │   ├── account_group.rb                     # Account group model
│   │   ├── category.rb                          # Category model
│   │   ├── transaction.rb                       # Transaction model
│   │   └── current.rb                           # Thread-safe current user
│   └── services/
│       └── jwt_service.rb                       # JWT token service
├── config/
│   ├── routes.rb                                # API routes
│   └── initializers/
│       └── cors.rb                              # CORS configuration
├── db/
│   └── migrate/
│       └── 20260123000004_add_password_digest_to_users.rb
└── test/
    ├── integration/
    │   └── api/
    │       └── v1/                               # Integration tests
    └── fixtures/                                 # Test data
```

---

## Key Concepts Learned

### 1. Rails API-Only Mode
- No views, helpers, or assets
- JSON-only responses
- Optimized for API development

### 2. RESTful API Design
- Standard HTTP verbs (GET, POST, PATCH, DELETE)
- Resource-based URLs
- Consistent response formats

### 3. Strong Parameters
- Prevents mass assignment vulnerabilities
- Explicit parameter whitelisting
- Security best practice

### 4. Error Handling
- Centralized error handling
- Consistent error response format
- Proper HTTP status codes

### 5. Authentication & Authorization
- JWT token-based authentication
- Password hashing with bcrypt
- User-scoped data access
- Thread-safe current user management

### 6. Testing
- Integration tests for API endpoints
- Fixtures for test data
- Test coverage for all CRUD operations

### 7. Database Design
- UUID primary keys
- Foreign key relationships
- Proper indexing
- User-scoped queries

### 8. Rails Conventions
- Controller naming conventions
- Route helpers
- Model associations
- Migration patterns

---

## Implementation Phases

- **Phase 3:** Advanced Backend Patterns (Serializers, Scopes, Service Objects)
- **Phase 4:** Frontend Integration (Next.js connection)
- **Phase 5:** Advanced Features (Search, Pagination, Analytics)
- **Phase 6:** Testing Enhancements
- **Phase 7:** Production Readiness

---

## Quick Start Guide

### 1. Setup Database
```bash
rails db:create
rails db:migrate
rails db:seed
```

### 2. Start Server
```bash
rails server
# Server runs on http://localhost:3000
```

### 3. Test Authentication
```bash
# Sign up
curl -X POST http://localhost:3000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "name": "Test User",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'

# Login (save the token from response)
curl -X POST http://localhost:3000/api/v1/sessions \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# Use token for authenticated requests
curl -X GET http://localhost:3000/api/v1/accounts \
  -H "Authorization: Bearer <your_token_here>"
```

---

## Summary

This implementation provides a solid foundation for a personal budgeting application with:

✅ Complete REST API for all core resources  
✅ Secure JWT-based authentication  
✅ User-scoped data access  
✅ Comprehensive error handling  
✅ Full test coverage  
✅ Clean, maintainable code structure  

The codebase follows Rails conventions and best practices, making it an excellent learning resource for Rails API development.
