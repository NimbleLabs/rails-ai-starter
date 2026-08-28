# Formats and delivers a Log to one LogSubscription. Used by LogNotificationJob
# and by the admin "Send test" button.
class LogNotifier
  APP_NAME = ENV.fetch("APP_NAME", "Starter")

  def self.deliver(log, subscription)
    new(log, subscription).deliver
  end

  def self.deliver_test(subscription)
    log = Log.new(
      level: :error, source: "console", message: "Test notification from #{APP_NAME} — if you can read this, the channel works.",
      error_class: "LogNotifier::Test", context: { "test" => true }, occurrences: 1, last_seen_at: Time.current, fingerprint: "test", created_at: Time.current
    )
    new(log, subscription).deliver
  end

  def initialize(log, subscription)
    @log = log
    @subscription = subscription
  end

  # Returns true when delivered.
  def deliver
    case @subscription.channel
    when "email"
      LogMailer.with(log: @log, to: @subscription.destination).log_alert.deliver_now
      true
    when "slack"
      SlackService.new(@subscription.destination).post(slack_text)
    else
      false
    end
  end

  def slack_text
    lines = [
      "#{emoji} *[#{APP_NAME}] #{@log.level.upcase} in #{@log.source}*",
      "*#{@log.title.truncate(300)}*"
    ]
    lines << "Path: `#{@log.path}`" if @log.path.present?
    lines << "User: #{@log.user.email}" if @log.user
    lines << "Occurrences: #{@log.occurrences} (first seen #{@log.created_at&.strftime('%b %-d %H:%M')})" if @log.occurrences.to_i > 1
    lines << "Where: `#{@log.backtrace.to_s.lines.first.to_s.strip}`" if @log.backtrace.present?
    lines << "<#{admin_url}|Open in admin>" if @log.persisted?
    lines.join("\n")
  end

  def admin_url
    host = Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3000"
    protocol = Rails.env.production? ? "https" : "http"
    "#{protocol}://#{host}/admin/log/#{@log.id}"
  end

  private

  def emoji
    { "fatal" => ":rotating_light:", "error" => ":x:", "warn" => ":warning:", "info" => ":information_source:" }[@log.level] || ":x:"
  end
end
