require 'swagger_helper'

RSpec.describe 'Budget Months API', type: :request do
  path '/api/v1/budget_months' do
    get 'List budget months' do
      tags 'Budget Months'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false
      parameter name: :budget_id, in: :query, type: :string, required: false
      parameter name: :month, in: :query, type: :string, required: false

      response '200', 'budget months retrieved' do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :string },
                  budget_id: { type: :string },
                  month: { type: :string },
                  available: { type: :number },
                  created_at: { type: :string },
                  updated_at: { type: :string }
                }
              }
            },
            meta: {
              type: :object,
              properties: {
                current_page: { type: :integer },
                per_page: { type: :integer },
                total_pages: { type: :integer },
                total_count: { type: :integer }
              }
            }
          }

        let(:user) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:Authorization) { "Bearer #{JwtService.encode({ user_id: user.id)}" }

        run_test!
      end
    end

    post 'Create budget month' do
      tags 'Budget Months'
      consumes 'application/json'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :budget_month, in: :body, schema: {
        type: :object,
        properties: {
          budget_id: { type: :string },
          month: { type: :string },
          available: { type: :number }
        },
        required: ['budget_id', 'month']
      }

      response '201', 'budget month created' do
        schema type: :object,
          properties: {
            id: { type: :string },
            budget_id: { type: :string },
            month: { type: :string },
            available: { type: :number },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

        let(:user) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:budget) { user.budgets.create! }
        let(:Authorization) { "Bearer #{JwtService.encode({ user_id: user.id)}" }
        let(:budget_month) { { budget_id: budget.id, month: Date.today.beginning_of_month.iso8601, available: 0 } }

        run_test!
      end
    end

    post 'Transition to next month' do
      tags 'Budget Months'
      consumes 'application/json'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :budget_id, in: :query, type: :string, required: true
      parameter name: :target_month, in: :query, type: :string, required: false

      response '201', 'month transitioned' do
        schema type: :object,
          properties: {
            budget_month: {
              type: :object,
              properties: {
                id: { type: :string },
                budget_id: { type: :string },
                month: { type: :string },
                available: { type: :number }
              }
            },
            message: { type: :string }
          }

        let(:user) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:budget) { user.budgets.create! }
        let(:Authorization) { "Bearer #{JwtService.encode({ user_id: user.id)}" }
        let(:budget_id) { budget.id }

        run_test!
      end
    end
  end

  path '/api/v1/budget_months/{id}' do
    parameter name: :id, in: :path, type: :string

    get 'Show budget month' do
      tags 'Budget Months'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'budget month found' do
        schema type: :object,
          properties: {
            id: { type: :string },
            budget_id: { type: :string },
            month: { type: :string },
            available: { type: :number },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

        let(:user) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:budget) { user.budgets.create! }
        let(:budget_month) { budget.budget_months.create!(user: user, month: Date.today.beginning_of_month, available: 0) }
        let(:id) { budget_month.id }
        let(:Authorization) { "Bearer #{JwtService.encode({ user_id: user.id)}" }

        run_test!
      end
    end
  end
end
