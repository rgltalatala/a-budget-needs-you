require 'swagger_helper'

RSpec.describe 'Users API', type: :request do
  path '/api/v1/users' do
    post 'Create user (signup)' do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          name: { type: :string },
          password: { type: :string }
        },
        required: ['email', 'name', 'password']
      }

      response '201', 'user created' do
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

        let(:user) { { email: 'newuser@example.com', name: 'New User', password: 'password123' } }

        run_test!
      end

      response '422', 'validation error' do
        schema type: :object,
          properties: {
            error: { type: :string },
            message: { type: :array, items: { type: :string } }
          }

        let(:user) { { email: 'invalid', name: '', password: 'short' } }

        run_test!
      end
    end
  end
end
