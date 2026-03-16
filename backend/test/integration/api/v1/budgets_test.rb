require "test_helper"

module Api
  module V1
    class BudgetsTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @budget = budgets(:one)
      end

      test "should get index" do
        get api_v1_budgets_url, headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response["data"].is_a?(Array)
        assert json_response["meta"].present?
      end

      test "should show budget" do
        get api_v1_budget_url(@budget), headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal @budget.id.to_s, json_response["id"]
      end

      test "should create budget" do
        initial_count = Budget.count
        post api_v1_budgets_url,
             params: {
               budget: {}
             },
             headers: auth_headers_for(@user),
             as: :json

        if response.status != 201
          puts "Response status: #{response.status}"
          puts "Response body: #{response.body}"
        end
        assert_response :created
        assert_equal initial_count + 1, Budget.count, "Budget count should increase by 1"
        json_response = JSON.parse(response.body)
        assert json_response["id"].present?
      end

      test "should update budget" do
        # Budget has no updatable attributes, so we just verify it doesn't error
        patch api_v1_budget_url(@budget),
              params: {
                budget: {}
              },
              headers: auth_headers_for(@user),
              as: :json

        assert_response :success
      end

      test "should destroy budget" do
        assert_difference("Budget.count", -1) do
          delete api_v1_budget_url(@budget), headers: auth_headers_for(@user), as: :json
        end

        assert_response :no_content
      end
    end
  end
end
