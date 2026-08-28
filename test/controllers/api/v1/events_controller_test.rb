require "test_helper"

class Api::V1::EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Ahoy::Event.delete_all
    Ahoy::Visit.delete_all
    @user = users(:two)
    @visit_headers = {
      "Ahoy-Visitor" => SecureRandom.uuid,
      "Ahoy-Visit"   => SecureRandom.uuid
    }
  end

  def body(events)
    { events: events, platform: "ios", app_version: "1.0.0", os_version: "18.0" }
  end

  test "records an allow-listed event anonymously" do
    assert_difference -> { Ahoy::Event.count }, 1 do
      post api_v1_events_url, params: body([ { name: "app_opened", properties: {}, time: Time.current.iso8601 } ]),
           headers: @visit_headers, as: :json
    end
    assert_response :success

    result = JSON.parse(response.body)
    assert_equal 1, result["tracked"]
    assert_equal 1, result["received"]
    assert_equal "app_opened", Ahoy::Event.last.name
  end

  test "drops an event that is not on the allow-list" do
    assert_no_difference -> { Ahoy::Event.count } do
      post api_v1_events_url, params: body([ { name: "sign_up", properties: {} } ]), headers: @visit_headers, as: :json
    end
    assert_response :success

    result = JSON.parse(response.body)
    assert_equal 0, result["tracked"]
    assert_equal 1, result["received"], "the request still succeeds; the event is simply not written"
  end

  test "attributes the event to a user when a token is sent" do
    post api_v1_events_url, params: body([ { name: "push_opened", properties: { screen: "today" } } ]),
         headers: @visit_headers.merge("x-api-token" => @user.auth_token), as: :json
    assert_response :success
    assert_equal @user.id, Ahoy::Event.last.user_id
  end

  test "stamps the source as app" do
    post api_v1_events_url, params: body([ { name: "app_opened" } ]), headers: @visit_headers, as: :json
    assert_equal "app", Ahoy::Event.last.properties["source"]
  end

  test "rejects a non-array events param" do
    post api_v1_events_url, params: { events: "nope" }, headers: @visit_headers, as: :json
    assert_response :bad_request
  end

  test "rejects more events than the per-request cap" do
    events = Array.new(Api::V1::EventsController::MAX_EVENTS_PER_REQUEST + 1) { { name: "app_opened" } }
    post api_v1_events_url, params: body(events), headers: @visit_headers, as: :json
    assert_response :unprocessable_entity
  end

  test "survives a malformed time without failing the batch" do
    post api_v1_events_url, params: body([ { name: "app_opened", time: "not-a-time" } ]), headers: @visit_headers, as: :json
    assert_response :success
    assert_equal 1, JSON.parse(response.body)["tracked"]
  end

  test "reuses the same visit across requests with the same tokens" do
    2.times { post api_v1_events_url, params: body([ { name: "app_opened" } ]), headers: @visit_headers, as: :json }

    assert_equal 2, Ahoy::Event.count
    assert_equal 1, Ahoy::Visit.count, "both events should land on one visit"
  end
end
