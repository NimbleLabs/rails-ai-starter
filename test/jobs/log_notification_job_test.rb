require "test_helper"

class LogNotificationJobTest < ActiveSupport::TestCase
  setup do
    Log.delete_all
    LogSubscription.delete_all
    ActionMailer::Base.deliveries.clear
  end

  test "emails a matching subscription" do
    LogSubscription.create!(channel: :email, destination: "ops@example.com", min_level: :error)
    log = Log.record("boom", source: "web")

    assert_difference -> { ActionMailer::Base.deliveries.size }, 1 do
      LogNotificationJob.perform_now(log.id)
    end

    assert_equal [ "ops@example.com" ], ActionMailer::Base.deliveries.last.to
    assert log.reload.notified_at.present?
  end

  test "skips a subscription below its min level" do
    LogSubscription.create!(channel: :email, destination: "ops@example.com", min_level: :fatal)
    log = Log.record("just a warning", source: "web", level: :warn)

    LogNotificationJob.perform_now(log.id)

    assert_empty ActionMailer::Base.deliveries
    assert_nil log.reload.notified_at
  end

  test "does not notify about a resolved log" do
    LogSubscription.create!(channel: :email, destination: "ops@example.com", min_level: :error)
    log = Log.record("boom", source: "web")
    log.resolve!

    LogNotificationJob.perform_now(log.id)

    assert_empty ActionMailer::Base.deliveries
  end

  test "throttles repeat notifications for the same log" do
    LogSubscription.create!(channel: :email, destination: "ops@example.com", min_level: :error, throttle_minutes: 60)
    log = Log.record("boom", source: "web")

    LogNotificationJob.perform_now(log.id)
    assert_equal 1, ActionMailer::Base.deliveries.size

    LogNotificationJob.perform_now(log.id)
    assert_equal 1, ActionMailer::Base.deliveries.size, "second run inside the throttle window must not send"

    log.update_column(:notified_at, 2.hours.ago)
    LogNotificationJob.perform_now(log.id)
    assert_equal 2, ActionMailer::Base.deliveries.size, "outside the window it should send again"
  end

  test "a failing channel does not stop the others" do
    LogSubscription.create!(channel: :slack, destination: "https://hooks.slack.com/services/T/B/x", min_level: :error)
    LogSubscription.create!(channel: :email, destination: "ops@example.com", min_level: :error)
    log = Log.record("boom", source: "web")

    LogNotifier.stub(:deliver, ->(_log, subscription) { raise "channel down" if subscription.slack?; LogMailer.with(log: log, to: subscription.destination).log_alert.deliver_now; true }) do
      assert_nothing_raised { LogNotificationJob.perform_now(log.id) }
    end

    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test "discards quietly when the log is gone" do
    assert_nothing_raised { LogNotificationJob.perform_now(999_999) }
  end
end
