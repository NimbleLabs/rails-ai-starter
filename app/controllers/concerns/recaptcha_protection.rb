# Bot protection for public forms, using reCAPTCHA Enterprise.
#
# Two rules shape this:
#
#   1. It is entirely optional. With no keys configured the widget is not
#      rendered and verification is skipped, so the starter works on a fresh
#      clone. `recaptcha_enabled?` is the single source of truth and is exposed
#      to views, so the form and the controller can never disagree about
#      whether a token should be present.
#   2. It fails open on infrastructure problems, not on bad scores. If Google
#      is unreachable the gem's `handle_timeouts_gracefully` lets the request
#      through — an outage at Google must not stop people signing up — but a
#      real low score or a missing token is still a rejection.
module RecaptchaProtection
  extend ActiveSupport::Concern

  # Enterprise returns a risk score from 0.0 (almost certainly a bot) to 1.0.
  # 0.5 is Google's documented starting point; tune per action with real data.
  DEFAULT_MINIMUM_SCORE = 0.5

  included do
    helper_method :recaptcha_enabled?
  end

  # True only when every piece needed to render *and* verify is present.
  def recaptcha_enabled?
    config = Recaptcha.configuration
    config.site_key.present? &&
      config.enterprise &&
      config.enterprise_api_key.present? &&
      config.enterprise_project_id.present?
  end

  # Verify the token for `action`, or return true when reCAPTCHA is switched off.
  #
  #   return unless check_recaptcha(action: "signup", model: resource)
  #
  # `action` must match the action name the form rendered with, otherwise
  # Enterprise treats the assessment as invalid — that is what stops a token
  # minted on a cheap form being replayed against an expensive one.
  def check_recaptcha(action:, model: nil, minimum_score: DEFAULT_MINIMUM_SCORE)
    return true unless recaptcha_enabled?

    verify_recaptcha(action: action, model: model, minimum_score: minimum_score)
  end
end
