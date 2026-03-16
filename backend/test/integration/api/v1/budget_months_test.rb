require "test_helper"

module Api
  module V1
    class BudgetMonthsTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @budget = budgets(:one)
        @budget_month = budget_months(:one)
      end

      test "should get index" do
        get api_v1_budget_months_url, headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response["data"].is_a?(Array)
        assert json_response["meta"].present?
      end

      test "should filter by budget_id" do
        get api_v1_budget_months_url, params: { budget_id: @budget.id }, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        json_response["data"].each do |bm|
          assert_equal @budget.id.to_s, bm["budget_id"]
        end
      end

      test "should filter by month" do
        get api_v1_budget_months_url, params: { month: "2026-03-01" }, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        json_response["data"].each do |bm|
          assert_equal "2026-03-01", bm["month"]
        end
      end

      test "should show budget_month" do
        get api_v1_budget_month_url(@budget_month), headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal @budget_month.id.to_s, json_response["id"]
        assert_equal @budget_month.month.to_s, json_response["month"]
      end

      test "should create budget_month" do
        assert_difference("BudgetMonth.count") do
          post api_v1_budget_months_url,
               params: {
                 budget_month: {
                   budget_id: @budget.id,
                   month: "2026-05-01",
                   available: 6000.00
                 }
               },
               headers: auth_headers_for(@user),
               as: :json
        end

        assert_response :created
        json_response = JSON.parse(response.body)
        assert_equal "2026-05-01", json_response["month"]
      end

      test "should not create budget_month with invalid budget_id" do
        assert_no_difference("BudgetMonth.count") do
          post api_v1_budget_months_url,
               params: {
                 budget_month: {
                   budget_id: "00000000-0000-0000-0000-000000000000",
                   month: "2026-05-01"
                 }
               },
               headers: auth_headers_for(@user),
               as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should update budget_month" do
        patch api_v1_budget_month_url(@budget_month),
              params: {
                budget_month: {
                  available: 5500.00
                }
              },
              headers: auth_headers_for(@user),
              as: :json

        assert_response :success
        @budget_month.reload
        assert_equal 5500.00, @budget_month.available.to_f
      end

      test "should destroy budget_month" do
        assert_difference("BudgetMonth.count", -1) do
          delete api_v1_budget_month_url(@budget_month), headers: auth_headers_for(@user), as: :json
        end

        assert_response :no_content
      end
    end
  end
end
