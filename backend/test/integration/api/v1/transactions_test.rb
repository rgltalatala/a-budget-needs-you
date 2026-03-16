require "test_helper"

module Api
  module V1
    class TransactionsTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @account = accounts(:one)
        @category = categories(:one)
        @transaction = transactions(:one)
      end

      test "should get index" do
        get api_v1_transactions_url, headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response["data"].is_a?(Array)
        assert json_response["meta"].present?
      end

      test "should filter transactions by account_id" do
        get api_v1_transactions_url, params: { account_id: @account.id }, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        json_response["data"].each do |transaction|
          assert_equal @account.id.to_s, transaction["account_id"]
        end
      end

      test "should filter transactions by category_id" do
        get api_v1_transactions_url, params: { category_id: @category.id }, headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        json_response["data"].each do |transaction|
          assert_equal @category.id.to_s, transaction["category_id"]
        end
      end

      test "should filter transactions by date range" do
        get api_v1_transactions_url,
            params: {
              start_date: "2026-01-10",
              end_date: "2026-01-15"
            },
            headers: auth_headers_for(@user)
        assert_response :success
        json_response = JSON.parse(response.body)
        json_response["data"].each do |transaction|
          date = Date.parse(transaction["date"])
          assert date >= Date.parse("2026-01-10")
          assert date <= Date.parse("2026-01-15")
        end
      end

      test "should show transaction" do
        get api_v1_transaction_url(@transaction), headers: auth_headers_for(@user), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal @transaction.id.to_s, json_response["id"]
        assert_equal @transaction.payee, json_response["payee"]
      end

      test "should create transaction" do
        @account.recalculate_balance!
        initial_balance = @account.balance

        assert_difference("Transaction.count") do
          post api_v1_transactions_url,
               params: {
                 transaction: {
                   account_id: @account.id,
                   category_id: @category.id,
                   date: Date.today,
                   payee: "Test Payee",
                   amount: -50.00
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :created
        json_response = JSON.parse(response.body)
        assert_equal "Test Payee", json_response["payee"]
        assert_equal "-50.0", json_response["amount"].to_s

        # Verify account balance was updated
        @account.reload
        assert_equal initial_balance - 50.00, @account.balance
      end

      test "should not create transaction with invalid params" do
        assert_no_difference("Transaction.count") do
          post api_v1_transactions_url,
               params: {
                 transaction: {
                   date: "",
                   amount: "invalid"
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should not create transaction without required fields" do
        assert_no_difference("Transaction.count") do
          post api_v1_transactions_url,
               params: {
                 transaction: {
                   payee: "Test"
                   # Missing date, amount, account_id, category_id, user_id
                 }
               },
               headers: auth_headers_for(@user), as: :json
        end

        assert_response :unprocessable_entity
      end

      test "should update transaction" do
        @account.recalculate_balance!
        initial_balance = @account.balance
        old_amount = @transaction.amount

        patch api_v1_transaction_url(@transaction),
              params: {
                transaction: {
                  payee: "Updated Payee",
                  amount: -200.00
                }
              },
              headers: auth_headers_for(@user), as: :json

        assert_response :success
        @transaction.reload
        assert_equal "Updated Payee", @transaction.payee

        # Verify account balance was updated correctly
        @account.reload
        expected_balance = initial_balance - old_amount + (-200.00)
        assert_equal expected_balance, @account.balance
      end

      test "should destroy transaction" do
        @account.recalculate_balance!
        initial_balance = @account.balance
        transaction_amount = @transaction.amount

        assert_difference("Transaction.count", -1) do
          delete api_v1_transaction_url(@transaction), headers: auth_headers_for(@user), as: :json
        end

        assert_response :no_content

        # Verify account balance was reverted
        @account.reload
        assert_equal initial_balance - transaction_amount, @account.balance
      end
    end
  end
end
