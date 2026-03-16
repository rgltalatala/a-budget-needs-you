require "test_helper"

module Api
  module V1
    class MonthTransitionTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @budget = budgets(:one)
        # Use fixed future dates so we never hit fixture budget_months (March/April 2026)
        @current_month = Date.new(2027, 3, 1)
        @next_month = Date.new(2027, 4, 1)
        
        @current_budget_month = @budget.budget_months.find_or_create_by!(month: @current_month) do |bm|
          bm.user = @user
          bm.available = 0
        end

        @category_group = CategoryGroup.find_or_create_by!(
          budget_month: @current_budget_month,
          user: @user,
          name: "Test Group"
        )

        @category = categories(:three)
      end

      test "should transition month via API" do
        # Create some data in current month
        CategoryMonth.create!(
          category: @category,
          category_group: @category_group,
          month: @current_month,
          user: @user,
          allotted: 1000.00,
          spent: 700.00,
          balance: 300.00
        )

        post transition_api_v1_budget_months_url,
             params: { budget_id: @budget.id, target_month: @next_month.strftime("%Y-%m-%d") },
             headers: auth_headers_for(@user),
             as: :json

        assert_response :created
        json_response = JSON.parse(response.body)
        assert_not_nil json_response["budget_month"]
        assert_equal @next_month.strftime("%Y-%m-%d"), json_response["budget_month"]["month"]
      end

      test "should transition to specific month" do
        specific_month = Date.new(2027, 6, 1)

        post transition_api_v1_budget_months_url,
             params: {
               budget_id: @budget.id,
               target_month: specific_month.strftime("%Y-%m-%d")
             },
             headers: auth_headers_for(@user),
             as: :json

        assert_response :created
        json_response = JSON.parse(response.body)
        assert_equal specific_month.strftime("%Y-%m-%d"), json_response["budget_month"]["month"]
      end

      test "should return existing month if already transitioned" do
        # Transition once (pass target_month so we use our fixed dates, not Date.today.next_month)
        post transition_api_v1_budget_months_url,
             params: { budget_id: @budget.id, target_month: @next_month.strftime("%Y-%m-%d") },
             headers: auth_headers_for(@user),
             as: :json

        assert_response :created
        first_response = JSON.parse(response.body)
        budget_month_id = first_response["budget_month"]["id"]

        # Transition again to same month
        post transition_api_v1_budget_months_url,
             params: { budget_id: @budget.id, target_month: @next_month.strftime("%Y-%m-%d") },
             headers: auth_headers_for(@user),
             as: :json

        assert_response :ok
        second_response = JSON.parse(response.body)
        assert_equal budget_month_id, second_response["budget_month"]["id"]
        assert_includes second_response["message"], "already exists"
      end

      test "should require budget_id" do
        post transition_api_v1_budget_months_url,
             params: {},
             headers: auth_headers_for(@user),
             as: :json

        assert_response :bad_request
        json_response = JSON.parse(response.body)
        assert_equal "Budget ID required", json_response["error"]
      end

      test "should validate budget belongs to user" do
        other_user = User.create!(email: "other@example.com", name: "Other", password: "password123!@#", password_confirmation: "password123!@#")
        other_budget = Budget.create!(user: other_user)

        post transition_api_v1_budget_months_url,
             params: { budget_id: other_budget.id },
             headers: auth_headers_for(@user),
             as: :json

        assert_response :not_found
      end

      test "should validate date format" do
        post transition_api_v1_budget_months_url,
             params: {
               budget_id: @budget.id,
               target_month: "invalid-date"
             },
             headers: auth_headers_for(@user),
             as: :json

        assert_response :bad_request
        json_response = JSON.parse(response.body)
        assert_equal "Invalid date format", json_response["error"]
      end
    end
  end
end
