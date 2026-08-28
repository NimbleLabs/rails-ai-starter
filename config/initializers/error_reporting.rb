# Internal error logging — replaces Rollbar. See app/models/log.rb and
# app/services/log_error_subscriber.rb. Re-subscribed on each code reload in
# development so the subscriber never points at a stale class.
Rails.application.config.to_prepare do
  Rails.error.unsubscribe(LogErrorSubscriber)
  Rails.error.subscribe(LogErrorSubscriber.new)
end
