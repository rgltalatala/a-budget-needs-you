require "test_helper"

module Api
  module V1
    class UsersTest < ActionDispatch::IntegrationTest
      test "should create user with valid params" do
        assert_difference("User.count") do
          post api_v1_users_url,
               params: {
                 user: {
                   email: "newuser@example.com",
                   name: "New User",
                   password: "password123!@#",
                   password_confirmation: "password123!@#"
                 }
               }, as: :json
        end

        assert_response :created
        json_response = JSON.parse(response.body)
        assert_equal "newuser@example.com", json_response["user"]["email"]
        assert json_response["message"].present?
      end

      test "should not create user with invalid email" do
        assert_no_difference("User.count") do
          post api_v1_users_url,
               params: {
                 user: {
                   email: "",
                   name: "New User",
                   password: "password123!@#",
                   password_confirmation: "password123!@#"
                 }
               }, as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should not create user with duplicate email" do
        User.create!(
          email: "existing@example.com",
          name: "Existing User",
          password: "password123!@#",
          password_confirmation: "password123!@#"
        )

        assert_no_difference("User.count") do
          post api_v1_users_url,
               params: {
                 user: {
                   email: "existing@example.com",
                   name: "New User",
                   password: "password123!@#",
                   password_confirmation: "password123!@#"
                 }
               }, as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should not create user with short password" do
        assert_no_difference("User.count") do
          post api_v1_users_url,
               params: {
                 user: {
                   email: "user@example.com",
                   name: "New User",
                   password: "short",
                   password_confirmation: "short"
                 }
               }, as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should not create user without number in password" do
        assert_no_difference("User.count") do
          post api_v1_users_url,
               params: {
                 user: {
                   email: "user@example.com",
                   name: "New User",
                   password: "passwordwithoutnumber!",
                   password_confirmation: "passwordwithoutnumber!"
                 }
               }, as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should not create user without special character in password" do
        assert_no_difference("User.count") do
          post api_v1_users_url,
               params: {
                 user: {
                   email: "user@example.com",
                   name: "New User",
                   password: "password123456",
                   password_confirmation: "password123456"
                 }
               }, as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should not create user with mismatched passwords" do
        assert_no_difference("User.count") do
          post api_v1_users_url,
               params: {
                 user: {
                   email: "user@example.com",
                   name: "New User",
                   password: "password123!@#",
                   password_confirmation: "different123!@#"
                 }
               }, as: :json
        end

        assert_response :unprocessable_entity
      end
    end
  end
end
