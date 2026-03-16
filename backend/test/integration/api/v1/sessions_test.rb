require "test_helper"

module Api
  module V1
    class SessionsTest < ActionDispatch::IntegrationTest
      setup do
        # Use a unique email for each test to avoid conflicts
        @user = User.create!(
          email: "sessiontest#{SecureRandom.hex(4)}@example.com",
          name: "Test User",
          password: "password123!@#",
          password_confirmation: "password123!@#"
        )
      end

      test "should login with valid credentials" do
        post api_v1_sessions_url,
             params: {
               email: @user.email,
               password: "password123!@#"
             }, as: :json

        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal @user.email, json_response["user"]["email"]
        assert json_response["message"].present?
      end

      test "should not login with invalid email" do
        post api_v1_sessions_url,
             params: {
               email: "wrong@example.com",
               password: "password123!@#"
             }, as: :json

        assert_response :unauthorized
        json_response = JSON.parse(response.body)
        assert json_response["error"].present?
      end

      test "should not login with invalid password" do
        post api_v1_sessions_url,
             params: {
               email: @user.email,
               password: "wrongpassword"
             }, as: :json

        assert_response :unauthorized
        json_response = JSON.parse(response.body)
        assert json_response["error"].present?
      end

      test "should logout" do
        delete api_v1_sessions_url, headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response["message"].present?
      end
    end
  end
end
