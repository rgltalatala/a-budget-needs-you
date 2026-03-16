require "test_helper"

module Api
  module V1
    class CategoriesTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @category = categories(:one)
      end

      test "should get index" do
        get api_v1_categories_url, headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response["data"].is_a?(Array)
        assert json_response["meta"].present?
      end

      test "should filter categories by user_id" do
        get api_v1_categories_url, params: { user_id: @user.id }, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        json_response["data"].each do |category|
          assert_equal @user.id.to_s, category["user_id"]
        end
      end

      test "should filter categories by is_default" do
        get api_v1_categories_url, params: { is_default: true }, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        json_response["data"].each do |category|
          assert_equal true, category["is_default"]
        end
      end

      test "should show category" do
        get api_v1_category_url(@category), headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal @category.id.to_s, json_response["id"]
        assert_equal @category.name, json_response["name"]
      end

      test "should create category" do
        assert_difference("Category.count") do
          post api_v1_categories_url,
               params: {
                 category: {
                   name: "New Category",
                   is_default: false
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :created
        json_response = JSON.parse(response.body)
        assert_equal "New Category", json_response["name"]
      end

      test "should not create category with invalid params" do
        assert_no_difference("Category.count") do
          post api_v1_categories_url,
               params: {
                 category: {
                   name: ""
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should update category" do
        patch api_v1_category_url(@category),
              params: {
                category: {
                  name: "Updated Category Name"
                }
              },
              headers: auth_headers_for(@user), as: :json

        assert_response :success
        @category.reload
        assert_equal "Updated Category Name", @category.name
      end

      test "should destroy category" do
        assert_difference("Category.count", -1) do
          delete api_v1_category_url(@category), headers: auth_headers_for(@user), as: :json
        end

        assert_response :no_content
      end
    end
  end
end
