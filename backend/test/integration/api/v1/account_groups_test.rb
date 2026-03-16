require "test_helper"

module Api
  module V1
    class AccountGroupsTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @account_group = account_groups(:one)
      end

      test "should get index" do
        get api_v1_account_groups_url, headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response["data"].is_a?(Array)
        assert json_response["meta"].present?
      end

      test "should show account_group" do
        get api_v1_account_group_url(@account_group), headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal @account_group.id.to_s, json_response["id"]
        assert_equal @account_group.name, json_response["name"]
      end

      test "should create account_group" do
        assert_difference("AccountGroup.count") do
          post api_v1_account_groups_url,
               params: {
                 account_group: {
                   name: "New Account Group",
                   sort_order: 3
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :created
        json_response = JSON.parse(response.body)
        assert_equal "New Account Group", json_response["name"]
      end

      test "should not create account_group with invalid params" do
        assert_no_difference("AccountGroup.count") do
          post api_v1_account_groups_url,
               params: {
                 account_group: {
                   name: ""
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should update account_group" do
        patch api_v1_account_group_url(@account_group),
              params: {
                account_group: {
                  name: "Updated Account Group Name"
                }
              },
              headers: auth_headers_for(@user), as: :json

        assert_response :success
        @account_group.reload
        assert_equal "Updated Account Group Name", @account_group.name
      end

      test "should not destroy account_group with accounts" do
        # Create an account in the group
        account = Account.create!(
          user: @user,
          name: "Test Account",
          account_type: "checking",
          balance: 1000.00,
          account_group: @account_group
        )

        assert_no_difference("AccountGroup.count") do
          delete api_v1_account_group_url(@account_group), headers: auth_headers_for(@user), as: :json
        end

        assert_response :unprocessable_entity
        json_response = JSON.parse(response.body)
        assert json_response["error"].present?
      end

      test "should destroy account_group without accounts" do
        empty_group = AccountGroup.create!(
          user: @user,
          name: "Empty Group",
          sort_order: 99
        )

        assert_difference("AccountGroup.count", -1) do
          delete api_v1_account_group_url(empty_group), headers: auth_headers_for(@user), as: :json
        end

        assert_response :no_content
      end
    end
  end
end
