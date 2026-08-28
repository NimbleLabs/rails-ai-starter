require "test_helper"

class LogSubscriptionTest < ActiveSupport::TestCase
  setup { LogSubscription.delete_all }

  test "email subscription requires a valid address" do
    assert LogSubscription.new(channel: :email, destination: "ops@example.com").valid?
    assert_not LogSubscription.new(channel: :email, destination: "nope").valid?
  end

  test "slack subscription requires a slack webhook url" do
    assert LogSubscription.new(channel: :slack, destination: "https://hooks.slack.com/services/T/B/x").valid?
    assert_not LogSubscription.new(channel: :slack, destination: "https://evil.example.com/hook").valid?
  end

  test "throttle must be within bounds" do
    assert_not LogSubscription.new(channel: :email, destination: "a@b.com", throttle_minutes: -1).valid?
    assert_not LogSubscription.new(channel: :email, destination: "a@b.com", throttle_minutes: 99_999).valid?
  end

  test "matches? respects min_level and active" do
    subscription = LogSubscription.create!(channel: :email, destination: "ops@example.com", min_level: :error)

    assert subscription.matches?(Log.new(level: :error))
    assert subscription.matches?(Log.new(level: :fatal))
    assert_not subscription.matches?(Log.new(level: :warn))
    assert_not subscription.matches?(Log.new(level: :info))

    subscription.update!(active: false)
    assert_not subscription.matches?(Log.new(level: :fatal))
  end

  test "display_name falls back to channel and destination" do
    named = LogSubscription.new(name: "Ops", channel: :email, destination: "ops@example.com")
    anon  = LogSubscription.new(channel: :email, destination: "ops@example.com")

    assert_equal "Ops", named.display_name
    assert_match "ops@example.com", anon.display_name
  end
end
