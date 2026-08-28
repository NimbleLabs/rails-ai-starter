require "net/http"
require "json"

# Minimal Slack incoming-webhook client. No gem. Never raises.
#
#   SlackService.system_alert_service.post("Something happened")   # uses ENV["SLACK_WEBHOOK_URL"]
#   SlackService.new(webhook_url).post("text")
#
# Deliberately does NOT call Rails.error.report on failure — this service is
# one of the Log notification channels, so a failing webhook must not create a
# Log that tries to notify Slack again.
class SlackService
  attr_reader :webhook_url

  def initialize(webhook_url)
    @webhook_url = webhook_url.to_s
  end

  def enabled? = webhook_url.start_with?("https://hooks.slack.com/")

  # Returns true when delivered, false otherwise.
  def post(text, blocks: nil)
    return false unless enabled?
    return false if Rails.env.test? && !self.class.deliver_in_test

    payload = { text: text.to_s }
    payload[:blocks] = blocks if blocks
    self.class.deliver(webhook_url, payload)
  rescue => e
    Rails.logger.error("[SlackService] failed to post: #{e.class}: #{e.message}")
    false
  end

  # ---- Event helpers used around the app --------------------------------

  def system_message(title, lines = [])
    post(([ title ] + Array(lines)).join("\n"))
  end

  def contact_form_event(contact)
    system_message("New contact form submission :mailbox_with_mail:", [
      "Name: #{contact.name}", "Email: #{contact.email}", "Company: #{contact.company}", "Message: #{contact.message.to_s.truncate(300)}"
    ])
  end

  def new_customer_event(user, credit_card = nil)
    lines = [ "User: #{user&.name}", "Email: #{user&.email}" ]
    lines << "Card: #{credit_card.brand} •••• #{credit_card.last4}" if credit_card.respond_to?(:last4)
    system_message("New customer! :tada:", lines)
  end

  def email_sent_event(subject, sent_count, already_sent_count, error_count)
    system_message("Email campaign sent :envelope:", [
      "Subject: #{subject}", "Sent: #{sent_count}", "Skipped (already sent): #{already_sent_count}", "Errors: #{error_count}"
    ])
  end

  class << self
    # Test hook: set to true (and stub `deliver`) to exercise posting in tests.
    attr_accessor :deliver_in_test

    def system_alert_service
      new(ENV["SLACK_WEBHOOK_URL"])
    end

    def deliver(url, payload)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 5
      response = http.post(uri.request_uri, payload.to_json, { "Content-Type" => "application/json" })
      ok = response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("[SlackService] webhook returned #{response.code}: #{response.body.to_s.truncate(200)}") unless ok
      ok
    end
  end
end
