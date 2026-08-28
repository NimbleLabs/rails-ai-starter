# Handles the return leg of "Sign in with Google".
#
# All the trust decisions live in `User.from_omniauth`; this controller only
# translates its outcome into a redirect. A nil result is deliberately vague to
# the user — it can mean an unverified Google email or an identity collision,
# and spelling out which would tell an attacker whether an address has an
# account here.
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # The request phase is a POST guarded by omniauth-rails_csrf_protection; the
  # callback comes back from Google as a GET and carries no CSRF token.
  skip_before_action :verify_authenticity_token, only: %i[google_oauth2 failure]

  def google_oauth2
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)

    if user&.persisted?
      Analytics.track(Analytics::SIGN_IN, user: user, controller: self, properties: { provider: "google_oauth2" })
      sign_in_and_redirect user, event: :authentication
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
    else
      # A genuine bug (Google unreachable mid-flow, a DB failure) is worth an
      # admin's attention; a rejected identity is not. Only report the former.
      Log.warn(
        "Google sign-in did not produce a user",
        source: "web",
        context: { uid_present: auth&.uid.present?, email_present: auth&.info&.email.present? }
      ) if auth.present?

      redirect_to new_user_session_path,
                  alert: "We couldn't sign you in with Google. Try again, or sign in with your email and password."
    end
  end

  # OmniAuth routes strategy errors here (user cancelled, bad credentials,
  # provider not configured).
  def failure
    redirect_to new_user_session_path,
                alert: "Google sign-in was cancelled or failed. Please try again."
  end
end
