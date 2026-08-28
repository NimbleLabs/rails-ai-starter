require "test_helper"

class Api::V1::LogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Log.delete_all
    @user = users(:two)
  end

  def payload(overrides = {})
    { log: { level: "error", message: "Cannot read property of undefined", error_class: "TypeError", source: "mobile" }.merge(overrides) }
  end

  test "accepts an anonymous report" do
    assert_difference -> { Log.count }, 1 do
      post api_v1_logs_url, params: payload, as: :json
    end
    assert_response :created

    log = Log.last
    assert_equal "mobile", log.source
    assert_equal "TypeError", log.error_class
    assert_nil log.user_id
    assert JSON.parse(response.body)["ok"]
  end

  test "attributes the report to the user when a token is sent" do
    post api_v1_logs_url, params: payload, headers: { "x-api-token" => @user.auth_token }, as: :json
    assert_response :created
    assert_equal @user.id, Log.last.user_id
  end

  test "ignores an invalid token rather than attributing it" do
    post api_v1_logs_url, params: payload, headers: { "x-api-token" => "not-a-real-token" }, as: :json
    assert_response :unauthorized
  end

  test "requires a message" do
    assert_no_difference -> { Log.count } do
      post api_v1_logs_url, params: payload(message: ""), as: :json
    end
    assert_response :unprocessable_entity
  end

  test "stores request metadata in context" do
    post api_v1_logs_url, params: payload(context: { screen: "profile" }), as: :json
    assert_response :created

    context = Log.last.context
    assert_equal "profile", context["screen"]
    assert context["ip"].present?
    assert context["request_id"].present?
  end

  test "splits a backtrace string into lines" do
    post api_v1_logs_url, params: payload(backtrace: "at foo (app.js:1)\nat bar (app.js:2)"), as: :json
    assert_response :created
    assert_match "at foo", Log.last.backtrace
  end

  test "rolls repeat reports up into one row" do
    3.times { post api_v1_logs_url, params: payload, as: :json }

    assert_equal 1, Log.count
    assert_equal 3, Log.last.occurrences
  end

  test "coerces an untrusted source to mobile" do
    post api_v1_logs_url, params: payload(source: "job"), as: :json
    assert_equal "mobile", Log.last.source, "a client must not be able to forge a server-side source"
  end

  test "defaults an unknown level to error rather than failing" do
    post api_v1_logs_url, params: payload(level: "banana"), as: :json
    assert_response :created
    assert_equal "error", Log.last.level
  end

  test "rejects an oversized payload" do
    post api_v1_logs_url, params: payload(message: "x" * 70_000), as: :json
    assert_response :content_too_large
  end
end
