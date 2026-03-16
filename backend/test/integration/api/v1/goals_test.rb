require "test_helper"

module Api
  module V1
    class GoalsTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @category = categories(:one)
        @goal = goals(:one)
      end

      test "should get index" do
        get api_v1_goals_url, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response["data"].is_a?(Array)
        assert json_response["meta"].present?
      end

      test "should filter by category_id" do
        get api_v1_goals_url, params: { category_id: @category.id }, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        json_response["data"].each do |goal|
          assert_equal @category.id.to_s, goal["category_id"]
        end
      end

      test "should filter by goal_type" do
        get api_v1_goals_url, params: { goal_type: "needed_for_spending" }, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        json_response["data"].each do |goal|
          assert_equal "needed_for_spending", goal["goal_type"]
        end
      end

      test "should show goal" do
        get api_v1_goal_url(@goal), headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal @goal.id.to_s, json_response["id"]
        assert_equal @goal.goal_type, json_response["goal_type"]
      end

      test "should create goal" do
        # First delete existing goal for this category if it exists
        Goal.where(category_id: @category.id).destroy_all

        assert_difference("Goal.count") do
          post api_v1_goals_url,
               params: {
                 goal: {
                   category_id: @category.id,
                   goal_type: "monthly_savings_builder",
                   target_amount: 500.00
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :created
        json_response = JSON.parse(response.body)
        assert_equal "monthly_savings_builder", json_response["goal_type"]
      end

      test "should not create goal with invalid category_id" do
        assert_no_difference("Goal.count") do
          post api_v1_goals_url,
               params: {
                 goal: {
                   category_id: "00000000-0000-0000-0000-000000000000",
                   goal_type: "needed_for_spending"
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should not create duplicate goal for same category" do
        # Use category three which doesn't have a goal in fixtures
        test_category = categories(:three)
        # Ensure no goal exists for this category
        Goal.where(category_id: test_category.id).destroy_all
        
        # Create a goal for this category
        existing_goal = Goal.create!(
          category: test_category,
          user: @user,
          goal_type: "needed_for_spending"
        )

        # Try to create another goal for the same category - should fail
        assert_no_difference("Goal.count") do
          post api_v1_goals_url,
               params: {
                 goal: {
                   category_id: test_category.id,
                   goal_type: "monthly_savings_builder",
                   target_amount: 500.00
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should update goal" do
        patch api_v1_goal_url(@goal),
              params: {
                goal: {
                  target_amount: 6000.00
                }
              },
              headers: auth_headers_for(@user), as: :json

        assert_response :success
        @goal.reload
        assert_equal 6000.00, @goal.target_amount.to_f
      end

      test "should destroy goal" do
        assert_difference("Goal.count", -1) do
          delete api_v1_goal_url(@goal), headers: auth_headers_for(@user), as: :json
        end

        assert_response :no_content
      end
    end
  end
end
