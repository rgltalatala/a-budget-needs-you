require "test_helper"

module Api
  module V1
    class CategoryMonthsTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @category = categories(:one)
        @category_group = category_groups(:one)
        @category_month = category_months(:one)
      end

      test "should get index" do
        get api_v1_category_months_url, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response["data"].is_a?(Array)
        assert json_response["meta"].present?
      end

      test "should filter by category_id" do
        get api_v1_category_months_url, params: { category_id: @category.id }, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        json_response["data"].each do |cm|
          assert_equal @category.id.to_s, cm["category_id"]
        end
      end

      test "should filter by category_group_id" do
        get api_v1_category_months_url, params: { category_group_id: @category_group.id }, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        json_response["data"].each do |cm|
          assert_equal @category_group.id.to_s, cm["category_group_id"]
        end
      end

      test "should filter by month" do
        get api_v1_category_months_url, params: { month: "2026-03-01" }, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        json_response["data"].each do |cm|
          assert_equal "2026-03-01", cm["month"]
        end
      end

      test "should show category_month" do
        get api_v1_category_month_url(@category_month), headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal @category_month.id.to_s, json_response["id"]
        assert_equal @category_month.spent.to_f, json_response["spent"].to_f
      end

      test "should create category_month" do
        post api_v1_category_months_url,
             params: {
               category_month: {
                 category_id: @category.id,
                 category_group_id: @category_group.id,
                 month: "2026-04-01",
                 spent: 200.00,
                 allotted: 300.00,
                 balance: 100.00
               }
             },
             headers: auth_headers_for(@user), as: :json

        assert_response :created
        json_response = JSON.parse(response.body)
        assert_equal "2026-04-01", json_response["month"]
        assert_equal @category.id.to_s, json_response["category_id"]
        assert CategoryMonth.exists?(category_id: @category.id, month: "2026-04-01", user_id: @user.id)
      end

      test "should not create category_month with invalid category_id" do
        assert_no_difference("CategoryMonth.count") do
          post api_v1_category_months_url,
               params: {
                 category_month: {
                   category_id: "00000000-0000-0000-0000-000000000000",
                   month: "2026-04-01"
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should update category_month" do
        patch api_v1_category_month_url(@category_month),
              params: {
                category_month: {
                  allotted: 2000.00
                }
              },
              headers: auth_headers_for(@user), as: :json

        assert_response :success
        @category_month.reload
        assert_equal 2000.00, @category_month.allotted.to_f
      end

      test "should destroy category_month" do
        assert_difference("CategoryMonth.count", -1) do
          delete api_v1_category_month_url(@category_month), headers: auth_headers_for(@user), as: :json
        end

        assert_response :no_content
      end
    end
  end
end
