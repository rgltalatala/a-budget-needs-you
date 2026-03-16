require 'swagger_helper'

RSpec.describe 'Transactions API', type: :request do
  path '/api/v1/transactions' do
    get 'List transactions' do
      tags 'Transactions'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false
      parameter name: :account_id, in: :query, type: :string, required: false
      parameter name: :category_id, in: :query, type: :string, required: false
      parameter name: :start_date, in: :query, type: :string, required: false
      parameter name: :end_date, in: :query, type: :string, required: false

      response '200', 'transactions retrieved' do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :string },
                  account_id: { type: :string },
                  category_id: { type: :string },
                  date: { type: :string },
                  payee: { type: :string, nullable: true },
                  amount: { type: :number },
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

    post 'Create transaction' do
      tags 'Transactions'
      consumes 'application/json'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :transaction, in: :body, schema: {
        type: :object,
        properties: {
          account_id: { type: :string },
          category_id: { type: :string },
          date: { type: :string },
          payee: { type: :string },
          amount: { type: :number }
        },
        required: ['account_id', 'category_id', 'date', 'amount']
      }

      response '201', 'transaction created' do
        schema type: :object,
          properties: {
            id: { type: :string },
            account_id: { type: :string },
            category_id: { type: :string },
            date: { type: :string },
            payee: { type: :string, nullable: true },
            amount: { type: :number },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

        let(:user) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:account) { user.accounts.create!(name: 'Test Account', balance: 1000.00) }
        let(:category) { user.categories.create!(name: 'Test Category') }
        let(:Authorization) { "Bearer #{JwtService.encode({ user_id: user.id)}" }
        let(:transaction) do
          {
            account_id: account.id,
            category_id: category.id,
            date: Date.today.iso8601,
            payee: 'Test Payee',
            amount: -50.00
          }
        end

        run_test!
      end
    end
  end

  path '/api/v1/transactions/{id}' do
    parameter name: :id, in: :path, type: :string

    get 'Show transaction' do
      tags 'Transactions'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'transaction found' do
        schema type: :object,
          properties: {
            id: { type: :string },
            account_id: { type: :string },
            category_id: { type: :string },
            date: { type: :string },
            payee: { type: :string, nullable: true },
            amount: { type: :number },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

        let(:user) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:account) { user.accounts.create!(name: 'Test Account', balance: 1000.00) }
        let(:category) { user.categories.create!(name: 'Test Category') }
        let(:transaction) { user.transactions.create!(account: account, category: category, date: Date.today, amount: -50.00) }
        let(:id) { transaction.id }
        let(:Authorization) { "Bearer #{JwtService.encode({ user_id: user.id)}" }

        run_test!
      end
    end
  end
end
