class ApplicationMailer < ActionMailer::Base
  # The sender for every email the app sends, Devise's included (see
  # config/initializers/devise.rb). SendGrid refuses mail from any address it
  # hasn't verified, so the default is one it has; MAIL_FROM overrides it.
  DEFAULT_FROM = "Harris Reynolds <harris@nimblelabs.com>".freeze

  def self.from_address = ENV["MAIL_FROM"].presence || DEFAULT_FROM

  default from: -> { ApplicationMailer.from_address }
  layout "mailer"
  # app_config: the app's name and colors for templates (see AppConfig).
  helper :application
end
