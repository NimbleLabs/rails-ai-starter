require "test_helper"

class LogSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    LogSubscription.delete_all
    ActionMailer::Base.deliveries.clear
    @admin = users(:one)
    @user  = users(:two)
    @subscription = LogSubscription.create!(name: "Ops", channel: :email, destination: "ops@example.com", min_level: :error)
  end

  test "requires an admin" do
    get log_subscriptions_url(format: :json)
    assert_response :unauthorized

    sign_in @user
    get log_subscriptions_url(format: :json)
    assert_response :forbidden
  end

  test "admin can list subscriptions" do
    sign_in @admin
    get log_subscriptions_url(format: :json)
    assert_response :success
    assert_equal "ops@example.com", JSON.parse(response.body).first["destination"]
  end

  test "creates a subscription" do
    sign_in @admin
    assert_difference -> { LogSubscription.count }, 1 do
      post log_subscriptions_url(format: :json), params: {
        log_subscription: { name: "Slack", channel: "slack", destination: "https://hooks.slack.com/services/T/B/x", min_level: "warn" }
      }
    end
    assert_response :created
  end

  test "returns validation errors for a bad destination" do
    sign_in @admin
    assert_no_difference -> { LogSubscription.count } do
      post log_subscriptions_url(format: :json), params: {
        log_subscription: { channel: "slack", destination: "https://evil.example.com/hook" }
      }
    end
    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"].key?("destination")
  end

  test "updates and destroys" do
    sign_in @admin

    patch log_subscription_url(@subscription, format: :json), params: { log_subscription: { active: false } }
    assert_response :success
    assert_not @subscription.reload.active?

    assert_difference -> { LogSubscription.count }, -1 do
      delete log_subscription_url(@subscription, format: :json)
    end
  end

  test "test action sends a real notification" do
    sign_in @admin

    assert_difference -> { ActionMailer::Base.deliveries.size }, 1 do
      post test_log_subscription_url(@subscription, format: :json)
    end
    assert_response :success
    assert JSON.parse(response.body)["ok"]
  end

  test "test action does not create a Log row" do
    sign_in @admin
    assert_no_difference -> { Log.count } do
      post test_log_subscription_url(@subscription, format: :json)
    end
  end
end
