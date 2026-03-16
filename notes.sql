CREATE TABLE public.account_groups (id UUID NOT NULL DEFAULT gen_random_uuid(),
                                                             user_id UUID NOT NULL,
                                                                          name text NOT NULL,
                                                                                    sort_order integer DEFAULT 0,
                                                                                                               CONSTRAINT account_groups_pkey PRIMARY KEY (id));

CREATE TABLE public.accounts (id UUID NOT NULL DEFAULT gen_random_uuid(),
                                                       user_id UUID NOT NULL,
                                                                    name text NOT NULL,
                                                                              TYPE text, balance numeric DEFAULT 0,
                                                                                                                 account_group_id UUID,
                                                                                                                                  CONSTRAINT accounts_pkey PRIMARY KEY (id), CONSTRAINT accounts_user_id_fkey
                              FOREIGN KEY (user_id) REFERENCES auth.users(id),
                                                               CONSTRAINT accounts_account_group_id_fkey
                              FOREIGN KEY (account_group_id) REFERENCES public.account_groups(id));

CREATE TABLE public.budget_months (id UUID NOT NULL DEFAULT gen_random_uuid(),
                                                            budget_id UUID NOT NULL,
                                                                           MONTH date NOT NULL,
                                                                                      available numeric DEFAULT 0,
                                                                                                                user_id UUID NOT NULL,
                                                                                                                             CONSTRAINT budget_months_pkey PRIMARY KEY (id), CONSTRAINT budget_months_budget_id_fkey
                                   FOREIGN KEY (budget_id) REFERENCES public.budgets(id),
                                                                      CONSTRAINT budget_months_user_id_fkey
                                   FOREIGN KEY (user_id) REFERENCES auth.users(id));

CREATE TABLE public.budgets (id UUID NOT NULL DEFAULT gen_random_uuid(),
                                                      user_id UUID NOT NULL,
                                                                   CONSTRAINT budgets_pkey PRIMARY KEY (id), CONSTRAINT budgets_user_id_fkey
                             FOREIGN KEY (user_id) REFERENCES auth.users(id));

CREATE TABLE public.categories (id UUID NOT NULL DEFAULT gen_random_uuid(),
                                                         category_group_id UUID,
                                                                           name text NOT NULL,
                                                                                     is_default boolean DEFAULT FALSE,
                                                                                                                user_id UUID,
                                                                                                                        CONSTRAINT categories_pkey PRIMARY KEY (id), CONSTRAINT categories_user_id_fkey
                                FOREIGN KEY (user_id) REFERENCES auth.users(id),
                                                                 CONSTRAINT categories_category_group_id_fkey
                                FOREIGN KEY (category_group_id) REFERENCES public.category_groups(id));

CREATE TABLE public.category_groups (id UUID NOT NULL DEFAULT gen_random_uuid(),
                                                              budget_month_id UUID,
                                                                              name text NOT NULL,
                                                                                        is_default boolean DEFAULT FALSE,
                                                                                                                   user_id UUID,
                                                                                                                           CONSTRAINT category_groups_pkey PRIMARY KEY (id), CONSTRAINT category_groups_user_id_fkey
                                     FOREIGN KEY (user_id) REFERENCES auth.users(id),
                                                                      CONSTRAINT category_groups_budget_month_id_fkey
                                     FOREIGN KEY (budget_month_id) REFERENCES public.budget_months(id));

CREATE TABLE public.category_months (id UUID NOT NULL DEFAULT gen_random_uuid(),
                                                              category_id UUID NOT NULL,
                                                                               spent numeric DEFAULT 0,
                                                                                                     allotted numeric DEFAULT 0,
                                                                                                                              balance numeric DEFAULT 0,
                                                                                                                                                      user_id UUID NOT NULL,
                                                                                                                                                                   MONTH date, CONSTRAINT category_months_pkey PRIMARY KEY (id), CONSTRAINT category_months_user_id_fkey
                                     FOREIGN KEY (user_id) REFERENCES auth.users(id),
                                                                      CONSTRAINT category_months_category_id_fkey
                                     FOREIGN KEY (category_id) REFERENCES public.categories(id));

CREATE TABLE public.goals (id UUID NOT NULL DEFAULT gen_random_uuid(),
                                                    category_id UUID NOT NULL,
                                                                     goal_type USER-DEFINED NOT NULL,
                                                                                            target_amount numeric, target_date date, user_id UUID NOT NULL,
                                                                                                                                                  CONSTRAINT goals_pkey PRIMARY KEY (id), CONSTRAINT goals_category_id_fkey
                           FOREIGN KEY (category_id) REFERENCES public.categories(id),
                                                                CONSTRAINT goals_user_id_fkey
                           FOREIGN KEY (user_id) REFERENCES auth.users(id));

CREATE TABLE public.summaries (id UUID NOT NULL DEFAULT gen_random_uuid(),
                                                        budget_month_id UUID NOT NULL,
                                                                             income numeric DEFAULT 0,
                                                                                                    carryover numeric DEFAULT 0,
                                                                                                                              available numeric DEFAULT 0,
                                                                                                                                                        notes text, user_id UUID NOT NULL,
                                                                                                                                                                                 CONSTRAINT summaries_pkey PRIMARY KEY (id), CONSTRAINT summaries_user_id_fkey
                               FOREIGN KEY (user_id) REFERENCES auth.users(id),
                                                                CONSTRAINT summaries_budget_month_id_fkey
                               FOREIGN KEY (budget_month_id) REFERENCES public.budget_months(id));

CREATE TABLE public.transactions (id UUID NOT NULL DEFAULT gen_random_uuid(),
                                                           account_id UUID NOT NULL,
                                                                           category_id UUID NOT NULL, date date NOT NULL,
                                                                                                                payee text, amount numeric NOT NULL,
                                                                                                                                           user_id UUID NOT NULL,
                                                                                                                                                        CONSTRAINT transactions_pkey PRIMARY KEY (id), CONSTRAINT transactions_category_id_fkey
                                  FOREIGN KEY (category_id) REFERENCES public.categories(id),
                                                                       CONSTRAINT transactions_account_id_fkey
                                  FOREIGN KEY (account_id) REFERENCES public.accounts(id),
                                                                      CONSTRAINT transactions_user_id_fkey
                                  FOREIGN KEY (user_id) REFERENCES auth.users(id));