require "test_helper"

class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
    OmniAuth.config.logger = Logger.new(File::NULL)
    Rails.application.env_config["devise.mapping"] = Devise.mappings[:user]
    Log.delete_all
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
    Rails.application.env_config.delete("omniauth.auth")
  end

  def stub_auth(email: "google-person@example.com", uid: "g-1", verified: true, name: "Google Person")
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: { email: email, name: name },
      extra: { raw_info: { email_verified: verified } }
    )
    OmniAuth.config.mock_auth[:google_oauth2] = auth
    Rails.application.env_config["omniauth.auth"] = auth
  end

  test "a verified Google identity signs in and creates an account" do
    stub_auth

    assert_difference -> { User.count }, 1 do
      get user_google_oauth2_omniauth_callback_path
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "an unverified Google email is rejected without creating an account" do
    stub_auth(verified: false)

    assert_no_difference -> { User.count } do
      get user_google_oauth2_omniauth_callback_path
    end

    assert_redirected_to new_user_session_path
    assert_match(/couldn't sign you in/i, flash[:alert])
  end

  test "signing in twice reuses the same account" do
    stub_auth
    get user_google_oauth2_omniauth_callback_path

    assert_no_difference -> { User.count } do
      get user_google_oauth2_omniauth_callback_path
    end
  end

  test "a rejected identity is logged as a warning, not an error" do
    stub_auth(verified: false)
    get user_google_oauth2_omniauth_callback_path

    log = Log.last
    assert log.present?, "a failed Google sign-in should leave a trace for an admin"
    assert_equal "warn", log.level, "a rejected identity is not an error-level incident"
  end

  test "the failure action redirects with a message rather than raising" do
    # OmniAuth routes strategy failures to this action through middleware
    # (OmniAuth.config.on_failure), not through a Rails route, so call it directly.
    controller = Users::OmniauthCallbacksController.new
    controller.set_request!(ActionDispatch::TestRequest.create)
    controller.set_response!(ActionDispatch::TestResponse.new)

    controller.failure

    assert_equal 302, controller.response.status
    assert_match(/sign-in was cancelled or failed/i, controller.flash[:alert])
  end

  test "records a sign_in analytics event" do
    stub_auth

    # Ahoy discards requests with no User-Agent as bots, so this has to look
    # like a browser or nothing is written.
    browser = { "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36" }

    assert_difference -> { Ahoy::Event.where(name: Analytics::SIGN_IN).count }, 1 do
      get user_google_oauth2_omniauth_callback_path, headers: browser
    end
  end
end
