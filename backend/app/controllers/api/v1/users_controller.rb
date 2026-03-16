module Api
  module V1
    class UsersController < BaseController
      skip_before_action :authenticate_user!, only: [:create]
      
      # POST /api/v1/users (signup)
      def create
        @user = User.new(user_params)

        if @user.save
          token = JwtService.generate_token(@user)
          render json: {
            user: Api::V1::UserSerializer.serialize(@user),
            token: token,
            message: "User created successfully"
          }, status: :created
        else
          render json: {
            error: "Validation failed",
            message: @user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/users/me (current user)
      def me
        render json: Api::V1::UserSerializer.serialize(current_user)
      end

      private

      def user_params
        params.require(:user).permit(:email, :name, :password, :password_confirmation)
      end
    end
  end
end
