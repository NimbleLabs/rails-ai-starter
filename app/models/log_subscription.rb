# Who gets told when something lands in the Log, and how. Managed from the
# admin (Logs → Notifications). Email uses LogMailer; Slack uses an incoming
# webhook URL stored as the destination.
class LogSubscription < ApplicationRecord
  CHANNELS = { email: 0, slack: 1 }.freeze

  enum :channel, CHANNELS, validate: true
  enum :min_level, Log::LEVELS, prefix: :min, validate: true

  validates :destination, presence: true
  validates :throttle_minutes, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10_080 }
  validate :destination_matches_channel

  scope :active, -> { where(active: true) }

  def matches?(log)
    active? && log.level_value >= Log::LEVELS.fetch(min_level.to_sym)
  end

  def display_name
    name.presence || "#{channel.humanize} → #{destination.truncate(40)}"
  end

  private

  def destination_matches_channel
    return if destination.blank?
    if email?
      errors.add(:destination, "must be a valid email address") unless destination.match?(URI::MailTo::EMAIL_REGEXP)
    elsif slack?
      errors.add(:destination, "must be a Slack incoming-webhook URL (https://hooks.slack.com/...)") unless destination.start_with?("https://hooks.slack.com/")
    end
  end
end
