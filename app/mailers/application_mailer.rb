class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "from@example.com")
  layout "mailer"
  # app_config: the app's name and colors for templates (see AppConfig).
  helper :application
end
