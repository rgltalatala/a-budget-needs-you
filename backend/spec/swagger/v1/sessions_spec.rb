require 'swagger_helper'

RSpec.describe 'Sessions API', type: :request do
  path '/api/v1/sessions' do
    post 'Login' do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string }
        },
        required: ['email', 'password']
      }

      response '200', 'login successful' do
        schema type: :object,
          properties: {
            token: { type: :string },
            user: {
              type: :object,
              properties: {
                id: { type: :string },
                email: { type: :string },
                name: { type: :string }
              }
            }
          }

        let(:user_record) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:user) { { email: 'test@example.com', password: 'password123' } }

        run_test!
      end

      response '401', 'invalid credentials' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }

        let(:user) { { email: 'test@example.com', password: 'wrongpassword' } }

        run_test!
      end
    end

    delete 'Logout' do
      tags 'Authentication'
      security [bearerAuth: []]

      response '200', 'logout successful' do
        let(:user) { User.create!(email: 'test@example.com', name: 'Test User', password: 'password123') }
        let(:Authorization) { "Bearer #{JwtService.encode({ user_id: user.id)}" }

        run_test!
      end
    end
  end
end
