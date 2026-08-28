require "test_helper"

# reCAPTCHA is configured from ENV and is OFF unless all three keys are set.
# These tests pin both halves of that: the starter must work with no keys, and
# the guard must actually be consulted once they exist.
class RecaptchaProtectionTest < ActionDispatch::IntegrationTest
  setup do
    @config = Recaptcha.configuration
    @original = {
      site_key: @config.site_key,
      enterprise: @config.enterprise,
      api_key: @config.enterprise_api_key,
      project: @config.enterprise_project_id,
      skip: @config.skip_verify_env
    }
  end

  teardown do
    @config.site_key = @original[:site_key]
    @config.enterprise = @original[:enterprise]
    @config.enterprise_api_key = @original[:api_key]
    @config.enterprise_project_id = @original[:project]
    @config.skip_verify_env = @original[:skip]
  end

  def configure_recaptcha!
    @config.site_key = "test-site-key"
    @config.enterprise = true
    @config.enterprise_api_key = "test-api-key"
    @config.enterprise_project_id = "test-project"
  end

  # --- disabled (the default) -------------------------------------------

  test "sign-up works with no reCAPTCHA configured" do
    assert_difference -> { User.count }, 1 do
      post user_registration_path, params: {
        user: { email: "nokeys@example.com", password: "password123", password_confirmation: "password123", name: "No Keys" }
      }
    end
    assert_response :redirect
  end

  test "the contact form works with no reCAPTCHA configured" do
    assert_difference -> { Contact.count }, 1 do
      post contacts_path, params: { contact: { name: "Nobody", email: "nobody@example.com", message: "Hello" } }
    end
  end

  test "the widget is not rendered when unconfigured" do
    get new_user_registration_path
    assert_response :success
    assert_no_match(/g-recaptcha-response/, response.body)
    assert_no_match(/Protected by reCAPTCHA/, response.body)
  end

  # --- enabled -----------------------------------------------------------

  test "the widget and its disclosure render once configured" do
    configure_recaptcha!

    get new_user_registration_path
    assert_response :success
    assert_match(/g-recaptcha-response/, response.body)
    assert_match(/Protected by reCAPTCHA/, response.body)
  end

  test "loads the Enterprise script, not the free one" do
    configure_recaptcha!
    # The gem deliberately omits Google's <script> in a skipped env so the test
    # suite never loads it; clear that to see what a real request would render.
    @config.skip_verify_env = []

    get new_user_registration_path
    assert_response :success
    assert_match(/test-site-key/, response.body)
    assert_match(%r{recaptcha/enterprise\.js}, response.body,
                 "Enterprise must not fall back to the free api.js")
  end

  test "the contact form renders the widget with its own action" do
    configure_recaptcha!

    get new_contact_path
    assert_response :success
    assert_match(/g-recaptcha-response-data\[contact\]/, response.body)
  end

  test "sign-up is rejected when verification fails" do
    configure_recaptcha!
    # skip_verify_env normally short-circuits verification in the test env;
    # clearing it makes the real code path run, and an absent token fails.
    @config.skip_verify_env = []

    assert_no_difference -> { User.count } do
      post user_registration_path, params: {
        user: { email: "bot@example.com", password: "password123", password_confirmation: "password123", name: "Bot" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "the contact form is rejected when verification fails" do
    configure_recaptcha!
    @config.skip_verify_env = []

    assert_no_difference -> { Contact.count } do
      post contacts_path, params: { contact: { name: "Bot", email: "bot@example.com", message: "spam" } }
    end
    assert_response :unprocessable_entity
  end

  test "a failed sign-up re-renders the form with the error, not a blank page" do
    configure_recaptcha!
    @config.skip_verify_env = []

    post user_registration_path, params: {
      user: { email: "bot@example.com", password: "password123", password_confirmation: "password123", name: "Bot" }
    }
    assert_response :unprocessable_entity
    assert_match(/sign ?up/i, response.body, "should re-render the sign-up form")
  end
end
