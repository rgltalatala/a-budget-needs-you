require "test_helper"

module Api
  module V1
    class SummariesTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @budget_month = budget_months(:one)
        @summary = summaries(:one)
      end

      test "should get index" do
        get api_v1_summaries_url, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response["data"].is_a?(Array)
        assert json_response["meta"].present?
      end

      test "should filter by budget_month_id" do
        get api_v1_summaries_url, params: { budget_month_id: @budget_month.id }, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        json_response["data"].each do |summary|
          assert_equal @budget_month.id.to_s, summary["budget_month_id"]
        end
      end

      test "should show summary" do
        get api_v1_summary_url(@summary), headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal @summary.id.to_s, json_response["id"]
        assert_equal @summary.income.to_f, json_response["income"].to_f
      end

      test "should create summary" do
        # Use a budget_month without a summary
        new_budget_month = budget_months(:two)
        Summary.where(budget_month_id: new_budget_month.id).destroy_all

        assert_difference("Summary.count") do
          post api_v1_summaries_url,
               params: {
                 summary: {
                   budget_month_id: new_budget_month.id,
                   income: 3500.00,
                   carryover: 500.00,
                   available: 4000.00,
                   notes: "April 2026 summary"
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :created
        json_response = JSON.parse(response.body)
        assert_equal 3500.00, json_response["income"].to_f
      end

      test "should not create summary with invalid budget_month_id" do
        assert_no_difference("Summary.count") do
          post api_v1_summaries_url,
               params: {
                 summary: {
                   budget_month_id: "00000000-0000-0000-0000-000000000000",
                   income: 3000.00
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should not create duplicate summary for same budget_month" do
        assert_no_difference("Summary.count") do
          post api_v1_summaries_url,
               params: {
                 summary: {
                   budget_month_id: @budget_month.id,
                   income: 3000.00
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should update summary" do
        patch api_v1_summary_url(@summary),
              params: {
                summary: {
                  income: 3200.00,
                  available: 5200.00
                }
              },
              headers: auth_headers_for(@user), as: :json

        assert_response :success
        @summary.reload
        assert_equal 3200.00, @summary.income.to_f
      end

      test "should destroy summary" do
        assert_difference("Summary.count", -1) do
          delete api_v1_summary_url(@summary), headers: auth_headers_for(@user), as: :json
        end

        assert_response :no_content
      end
    end
  end
end
