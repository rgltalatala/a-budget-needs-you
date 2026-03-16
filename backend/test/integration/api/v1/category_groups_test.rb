require "test_helper"

module Api
  module V1
    class CategoryGroupsTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @budget_month = budget_months(:one)
        @category_group = category_groups(:one)
      end

      test "should get index" do
        get api_v1_category_groups_url, headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response["data"].is_a?(Array)
        assert json_response["meta"].present?
      end

      test "should filter by budget_month_id" do
        get api_v1_category_groups_url, params: { budget_month_id: @budget_month.id }, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        json_response["data"].each do |cg|
          assert_equal @budget_month.id.to_s, cg["budget_month_id"]
        end
      end

      test "should show category_group" do
        get api_v1_category_group_url(@category_group), headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal @category_group.id.to_s, json_response["id"]
        assert_equal @category_group.name, json_response["name"]
      end

      test "should create category_group" do
        assert_difference("CategoryGroup.count") do
          post api_v1_category_groups_url,
               params: {
                 category_group: {
                   budget_month_id: @budget_month.id,
                   name: "New Category Group",
                   is_default: false
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :created
        json_response = JSON.parse(response.body)
        assert_equal "New Category Group", json_response["name"]
      end

      test "should not create category_group with invalid budget_month_id" do
        assert_no_difference("CategoryGroup.count") do
          post api_v1_category_groups_url,
               params: {
                 category_group: {
                   budget_month_id: "00000000-0000-0000-0000-000000000000",
                   name: "Invalid Group"
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should update category_group" do
        patch api_v1_category_group_url(@category_group),
              params: {
                category_group: {
                  name: "Updated Category Group Name"
                }
              },
              headers: auth_headers_for(@user), as: :json

        assert_response :success
        @category_group.reload
        assert_equal "Updated Category Group Name", @category_group.name
      end

      test "should not destroy category_group with categories" do
        # Create a category in the group
        category = Category.create!(
          user: @user,
          name: "Test Category",
          category_group: @category_group
        )

        assert_no_difference("CategoryGroup.count") do
          delete api_v1_category_group_url(@category_group), headers: auth_headers_for(@user), as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should destroy category_group without categories" do
        empty_group = CategoryGroup.create!(
          user: @user,
          budget_month: @budget_month,
          name: "Empty Group"
        )

        assert_difference("CategoryGroup.count", -1) do
          delete api_v1_category_group_url(empty_group), headers: auth_headers_for(@user), as: :json
        end

        assert_response :no_content
      end
    end
  end
end
