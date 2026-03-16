require "test_helper"

module Api
  module V1
    class AccountsTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @account = accounts(:one)
        @account_group = account_groups(:one)
      end

      test "should get index" do
        get api_v1_accounts_url, headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response["data"].is_a?(Array)
        assert json_response["meta"].present?
        assert json_response["meta"]["current_page"].present?
        assert json_response["meta"]["per_page"].present?
        assert json_response["meta"]["total_count"].present?
      end

      test "should show account" do
        get api_v1_account_url(@account), headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal @account.id.to_s, json_response["id"]
        assert_equal @account.name, json_response["name"]
      end

      test "should create account" do
        assert_difference("Account.count") do
          post api_v1_accounts_url,
               params: {
                 account: {
                   name: "New Account",
                   account_type: "checking",
                   balance: 1000.00,
                   account_group_id: @account_group.id
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :created
        json_response = JSON.parse(response.body)
        assert_equal "New Account", json_response["name"]
        assert_equal "checking", json_response["account_type"]
      end

      test "should not create account with invalid params" do
        assert_no_difference("Account.count") do
          post api_v1_accounts_url,
               params: {
                 account: {
                   name: "",
                   balance: "invalid"
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :unprocessable_entity
        json_response = JSON.parse(response.body)
        assert json_response["error"].present?
      end

      test "should update account" do
        patch api_v1_account_url(@account),
              params: {
                account: {
                  name: "Updated Account Name",
                  balance: 2000.00
                }
              },
              headers: auth_headers_for(@user), as: :json

        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal "Updated Account Name", json_response["name"]
        @account.reload
        assert_equal "Updated Account Name", @account.name
      end

      test "should not update account with invalid params" do
        original_name = @account.name
        patch api_v1_account_url(@account),
              params: {
                account: {
                  name: "",
                  balance: "invalid"
                }
              },
              headers: auth_headers_for(@user), as: :json

        assert_response :unprocessable_entity
        @account.reload
        assert_equal original_name, @account.name
      end

      test "should destroy account" do
        assert_difference("Account.count", -1) do
          delete api_v1_account_url(@account), headers: auth_headers_for(@user), as: :json
        end

        assert_response :no_content
      end

      test "should return 404 for non-existent account" do
        get api_v1_account_url(id: "00000000-0000-0000-0000-000000000000"), headers: auth_headers_for(@user), as: :json
        assert_response :not_found
        json_response = JSON.parse(response.body)
        assert json_response["error"].present?
      end
    end
  end
end
