# reCAPTCHA Enterprise.
#
# Configured entirely from the environment so nothing secret lives in the repo:
#
#   RECAPTCHA_SITE_KEY              public key rendered into the page
#   RECAPTCHA_ENTERPRISE_API_KEY    Google Cloud API key used to create assessments
#   RECAPTCHA_ENTERPRISE_PROJECT_ID Google Cloud project the key belongs to
#
# Leave them unset and reCAPTCHA turns itself off — the widget is not rendered
# and verification is skipped — so a fresh clone can sign up and submit the
# contact form without anyone provisioning Google Cloud first. See
# `RecaptchaProtection` for the guard, and CLAUDE.md → "Bot protection".
Recaptcha.configure do |config|
  config.site_key = ENV["RECAPTCHA_SITE_KEY"]

  # Enterprise uses an API key + project id and a different verification
  # endpoint (recaptchaenterprise.googleapis.com) than classic reCAPTCHA.
  config.enterprise = ENV["RECAPTCHA_ENTERPRISE_API_KEY"].present? &&
                      ENV["RECAPTCHA_ENTERPRISE_PROJECT_ID"].present?
  config.enterprise_api_key = ENV["RECAPTCHA_ENTERPRISE_API_KEY"]
  config.enterprise_project_id = ENV["RECAPTCHA_ENTERPRISE_PROJECT_ID"]

  # Never call out to Google from the test suite.
  config.skip_verify_env = %w[test cucumber]

  # A network blip talking to Google should not take down sign-up.
  config.handle_timeouts_gracefully = true
end
