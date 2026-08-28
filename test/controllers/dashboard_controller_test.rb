require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    Ahoy::Visit.delete_all
    @admin = users(:one)
    @user  = users(:two)
  end

  test "requires authentication" do
    get "/dashboard/metrics.json"
    assert_response :unauthorized
  end

  test "forbids non-admins" do
    sign_in @user
    get "/dashboard/metrics.json"
    assert_response :forbidden
  end

  test "returns the metrics payload for an admin" do
    sign_in @admin
    get "/dashboard/metrics.json"
    assert_response :success

    body = JSON.parse(response.body)
    assert body["totals"].key?("visits")
    assert body["range"]["days"].positive?
    assert_kind_of Array, body["visits_by_day"]
    assert body.key?("logs")
  end

  test "honours the days parameter" do
    sign_in @admin
    get "/dashboard/metrics.json", params: { days: 7 }

    body = JSON.parse(response.body)
    assert_equal 7, body["range"]["days"]
    assert_equal 7, body["visits_by_day"].size
  end

  test "accepts an admin api token" do
    get "/dashboard/metrics.json", headers: { "x-api-token" => @admin.auth_token }
    assert_response :success
  end
end
