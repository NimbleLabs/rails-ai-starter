require "test_helper"

class LogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Log.delete_all
    LogSubscription.delete_all
    @admin = users(:one)
    @user  = users(:two)
    @log   = Log.record("something broke", source: "web", level: :error)
  end

  test "index requires authentication" do
    get logs_url(format: :json)
    assert_response :unauthorized
  end

  test "index forbids non-admins" do
    sign_in @user
    get logs_url(format: :json)
    assert_response :forbidden
  end

  test "admin can list logs" do
    sign_in @admin
    get logs_url(format: :json)
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 1, body["total"]
    assert_equal "something broke", body["logs"].first["message"]
    assert body["counts"].key?("unresolved")
  end

  test "index defaults to unresolved and can show resolved" do
    @log.resolve!
    sign_in @admin

    get logs_url(format: :json)
    assert_equal 0, JSON.parse(response.body)["total"]

    get logs_url(format: :json, status: "resolved")
    assert_equal 1, JSON.parse(response.body)["total"]

    get logs_url(format: :json, status: "all")
    assert_equal 1, JSON.parse(response.body)["total"]
  end

  test "index filters by level, source and search" do
    Log.record("a warning", source: "job", level: :warn)
    sign_in @admin

    get logs_url(format: :json, level: "error")
    assert_equal 1, JSON.parse(response.body)["total"]

    get logs_url(format: :json, source: "job")
    assert_equal 1, JSON.parse(response.body)["total"]

    get logs_url(format: :json, q: "warning")
    assert_equal 1, JSON.parse(response.body)["total"]
  end

  test "index paginates and caps per_page" do
    # Distinct wording per row: same-shaped messages would (correctly) roll up
    # into a single fingerprint and there would be nothing to paginate.
    30.times { |i| Log.record("failure in #{("a".."z").to_a[i % 26]}#{i}-module", source: "web") }
    sign_in @admin

    get logs_url(format: :json, per_page: 5, page: 2)
    body = JSON.parse(response.body)
    assert_equal 5, body["logs"].size
    assert_equal 2, body["page"]

    get logs_url(format: :json, per_page: 5_000)
    assert_operator JSON.parse(response.body)["per_page"], :<=, LogsController::PER_PAGE_MAX
  end

  test "show returns the full record including backtrace and context" do
    sign_in @admin
    get log_url(@log, format: :json)
    assert_response :success

    body = JSON.parse(response.body)
    assert body.key?("context")
    assert_equal @log.id, body["id"]
  end

  test "update resolves and reopens" do
    sign_in @admin

    patch log_url(@log, format: :json), params: { log: { resolved: true } }
    assert_response :success
    assert @log.reload.resolved?

    patch log_url(@log, format: :json), params: { log: { resolved: false } }
    assert_not @log.reload.resolved?
  end

  test "destroy removes the log" do
    sign_in @admin
    assert_difference -> { Log.count }, -1 do
      delete log_url(@log, format: :json)
    end
    assert_response :no_content
  end

  test "resolve_all resolves everything matching the filters" do
    Log.record("a warning", source: "job", level: :warn)
    sign_in @admin

    patch resolve_all_logs_url(format: :json, source: "job")
    assert_response :success

    assert_not @log.reload.resolved?, "a log outside the filter must be untouched"
    assert_equal 1, Log.resolved.count
  end

  test "destroy_resolved deletes only resolved logs" do
    keeper = Log.record("still broken", source: "web")
    @log.resolve!
    sign_in @admin

    delete destroy_resolved_logs_url(format: :json)
    assert_response :success

    assert Log.exists?(keeper.id)
    assert_not Log.exists?(@log.id)
  end

  test "accepts an admin api token instead of a session" do
    get logs_url(format: :json), headers: { "x-api-token" => @admin.auth_token }
    assert_response :success
  end

  test "rejects a non-admin api token" do
    get logs_url(format: :json), headers: { "x-api-token" => @user.auth_token }
    assert_response :forbidden
  end
end
