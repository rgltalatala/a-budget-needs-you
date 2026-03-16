# frozen_string_literal: true

module Api
  module V1
    class PasswordsController < BaseController
      skip_before_action :authenticate_user!, only: [:request_reset, :reset]

      # POST /api/v1/password_reset_requests
      # Body: { email: "user@example.com" }
      # Returns: { reset_token: "..." } so the frontend can redirect to set-new-password?token=...
      # Demo users are rejected.
      def request_reset
        email = params[:email].to_s.strip.presence
        unless email
          return render json: { error: "Email is required" }, status: :unprocessable_entity
        end

        if User.demo_email?(email)
          return render json: {
            error: "Password reset is not available for demo accounts."
          }, status: :unprocessable_entity
        end

        user = User.find_by(email: email)
        unless user
          # Do not reveal whether the email exists
          return render json: {
            message: "If an account exists for that email, you will receive instructions to reset your password."
          }, status: :ok
        end

        token = JwtService.encode_with_expiry(
          { email: user.email, purpose: "password_reset" },
          duration: 1.hour
        )
        render json: { reset_token: token }, status: :ok
      end

      # POST /api/v1/password_reset
      # Body: { reset_token: "...", password: "...", password_confirmation: "..." }
      def reset
        token = params[:reset_token].to_s.presence
        unless token
          return render json: { error: "Reset token is required" }, status: :unprocessable_entity
        end

        payload = JwtService.decode(token)
        unless payload && payload[:purpose] == "password_reset" && payload[:email].present?
          return render json: { error: "Invalid or expired reset link. Please request a new one." }, status: :unprocessable_entity
        end

        user = User.find_by(email: payload[:email])
        unless user
          return render json: { error: "Invalid or expired reset link. Please request a new one." }, status: :unprocessable_entity
        end

        if user.demo_user?
          return render json: { error: "Password reset is not available for demo accounts." }, status: :unprocessable_entity
        end

        user.password = params[:password]
        user.password_confirmation = params[:password_confirmation]
        if user.save
          render json: { message: "Password updated. You can sign in with your new password." }, status: :ok
        else
          render json: {
            error: "Validation failed",
            message: user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/users/me/password
      # Body: { current_password: "...", password: "...", password_confirmation: "..." }
      def update
        if current_user.demo_user?
          return render json: {
            error: "Password cannot be changed for demo accounts. Create your own account to change your password."
          }, status: :unprocessable_entity
        end

        unless current_user.authenticate(params[:current_password])
          return render json: { error: "Current password is incorrect" }, status: :unprocessable_entity
        end

        current_user.password = params[:password]
        current_user.password_confirmation = params[:password_confirmation]
        if current_user.save
          render json: { message: "Password updated successfully." }, status: :ok
        else
          render json: {
            error: "Validation failed",
            message: current_user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
