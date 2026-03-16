require 'swagger_helper'

RSpec.describe 'Accounts API', type: :request do
  path '/api/v1/accounts' do
    get 'List accounts' do
      tags 'Accounts'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'

      response '200', 'accounts retrieved' do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :string },
                  name: { type: :string },
                  account_type: { type: :string, nullable: true },
                  balance: { type: :number },
                  account_group_id: { type: :string, nullable: true },
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
        let(:token) { JwtService.encode({ user_id: user.id }) }
        let(:Authorization) { "Bearer #{token}" }

        run_test!
      end

      response '401', 'unauthorized' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }

        let(:Authorization) { nil }
        run_test!
      end
    end

    post 'Create account' do
      tags 'Accounts'
      consumes 'application/json'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :account, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          account_type: { type: :string },
          balance: { type: :number },
          account_group_id: { type: :string }
        },
        required: ['name']
      }

      response '201', 'account created' do
        schema type: :object,
          properties: {
            id: { type: :string },
            name: { type: :string },
            account_type: { type: :string, nullable: true },
            balance: { type: :number },
            account_group_id: { type: :string, nullable: true },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

        let(:user) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:token) { JwtService.encode({ user_id: user.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:account) { { name: 'Checking Account', account_type: 'checking', balance: 1000.00 } }

        run_test!
      end

      response '422', 'validation error' do
        schema type: :object,
          properties: {
            error: { type: :string },
            message: { type: :array, items: { type: :string } }
          }

        let(:user) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:token) { JwtService.encode({ user_id: user.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:account) { { name: '' } }

        run_test!
      end
    end
  end

  path '/api/v1/accounts/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'Account ID'

    get 'Show account' do
      tags 'Accounts'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'account found' do
        schema type: :object,
          properties: {
            id: { type: :string },
            name: { type: :string },
            account_type: { type: :string, nullable: true },
            balance: { type: :number },
            account_group_id: { type: :string, nullable: true },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

        let(:user) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:account) { user.accounts.create!(name: 'Test Account', balance: 1000.00) }
        let(:id) { account.id }
        let(:token) { JwtService.encode({ user_id: user.id }) }
        let(:Authorization) { "Bearer #{token}" }

        run_test!
      end

      response '404', 'account not found' do
        schema type: :object,
          properties: {
            error: { type: :string },
            message: { type: :string }
          }

        let(:user) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:id) { 'invalid-id' }
        let(:token) { JwtService.encode({ user_id: user.id }) }
        let(:Authorization) { "Bearer #{token}" }

        run_test!
      end
    end

    patch 'Update account' do
      tags 'Accounts'
      consumes 'application/json'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :account, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          account_type: { type: :string },
          balance: { type: :number },
          account_group_id: { type: :string }
        }
      }

      response '200', 'account updated' do
        schema type: :object,
          properties: {
            id: { type: :string },
            name: { type: :string },
            account_type: { type: :string, nullable: true },
            balance: { type: :number },
            account_group_id: { type: :string, nullable: true },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

        let(:user) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:account_record) { user.accounts.create!(name: 'Test Account', balance: 1000.00) }
        let(:id) { account_record.id }
        let(:token) { JwtService.encode({ user_id: user.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:account) { { name: 'Updated Account' } }

        run_test!
      end
    end

    delete 'Delete account' do
      tags 'Accounts'
      security [bearerAuth: []]

      response '204', 'account deleted' do
        let(:user) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:account) { user.accounts.create!(name: 'Test Account', balance: 1000.00) }
        let(:id) { account.id }
        let(:token) { JwtService.encode({ user_id: user.id }) }
        let(:Authorization) { "Bearer #{token}" }

        run_test!
      end
    end
  end
end
