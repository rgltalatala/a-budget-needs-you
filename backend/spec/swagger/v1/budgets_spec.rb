require 'swagger_helper'

RSpec.describe 'Budgets API', type: :request do
  path '/api/v1/budgets' do
    get 'List budgets' do
      tags 'Budgets'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response '200', 'budgets retrieved' do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :string },
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

    post 'Create budget' do
      tags 'Budgets'
      consumes 'application/json'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :budget, in: :body, schema: {
        type: :object,
        properties: {}
      }

      response '201', 'budget created' do
        schema type: :object,
          properties: {
            id: { type: :string },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

        let(:user) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:Authorization) { "Bearer #{JwtService.encode({ user_id: user.id)}" }
        let(:budget) { {} }

        run_test!
      end
    end
  end

  path '/api/v1/budgets/{id}' do
    parameter name: :id, in: :path, type: :string

    get 'Show budget' do
      tags 'Budgets'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'budget found' do
        schema type: :object,
          properties: {
            id: { type: :string },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

        let(:user) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:budget) { user.budgets.create! }
        let(:id) { budget.id }
        let(:Authorization) { "Bearer #{JwtService.encode({ user_id: user.id)}" }

        run_test!
      end
    end
  end
end
