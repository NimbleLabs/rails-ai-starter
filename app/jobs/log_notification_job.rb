# Fans one Log out to every matching, active LogSubscription — respecting each
# subscription's throttle so a recurring error re-notifies at most once per
# `throttle_minutes`. Runs on Solid Queue; failures here are logged to
# Rails.logger only (never re-reported) so a broken channel can't loop.
class LogNotificationJob < ApplicationJob
  queue_as :default
  discard_on ActiveRecord::RecordNotFound

  def perform(log_id)
    log = Log.find(log_id)
    return if log.resolved?

    subscriptions = LogSubscription.active.select { |s| s.matches?(log) }
    return if subscriptions.empty?

    delivered = false
    subscriptions.each do |subscription|
      next if log.notified_recently?(subscription.throttle_minutes)

      if LogNotifier.deliver(log, subscription)
        delivered = true
        subscription.update_column(:last_notified_at, Time.current)
      end
    rescue => e
      Rails.logger.error("[LogNotificationJob] #{subscription.channel} → #{subscription.destination} failed: #{e.class}: #{e.message}")
    end

    log.update_column(:notified_at, Time.current) if delivered
  end
end
