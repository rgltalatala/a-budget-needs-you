module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_user!, only: [:create]
      
      # POST /api/v1/sessions (login)
      def create
        email = params[:user]&.dig(:email) || params[:email]
        password = params[:user]&.dig(:password) || params[:password]

        user = User.find_by(email: email)

        if user&.authenticate(password)
          token = JwtService.generate_token(user)
          render json: {
            user: Api::V1::UserSerializer.serialize(user),
            token: token,
            message: "Login successful"
          }, status: :ok
        else
          render json: {
            error: "Invalid credentials",
            message: "Email or password is incorrect"
          }, status: :unauthorized
        end
      end

      # DELETE /api/v1/sessions (logout)
      def destroy
        render json: {
          message: "Logged out successfully"
        }, status: :ok
      end

      private
    end
  end
end
