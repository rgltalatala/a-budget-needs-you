require "test_helper"

module Api
  class HealthTest < ActionDispatch::IntegrationTest
    test "should return ok" do
      get "/health", as: :json
      assert_response :success
      json_response = JSON.parse(response.body)
      assert_equal "ok", json_response["status"]
    end

    test "ready should return 200 and db connected when database is available" do
      get "/ready", as: :json
      assert_response :success
      json_response = JSON.parse(response.body)
      assert_equal "ok", json_response["status"]
      assert_equal "connected", json_response["db"]
    end
  end
end
