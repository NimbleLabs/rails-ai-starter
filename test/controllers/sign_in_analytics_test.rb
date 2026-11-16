require "test_helper"

# Sign-ups and sign-ins are recorded where they happen, so the admin dashboard's "What people did" card has
# something real in it. Web requests need a browser User-Agent or Ahoy discards them as bots.
class SignInAnalyticsTest < ActionDispatch::IntegrationTest
  BROWSER = { "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
                                   "(KHTML, like Gecko) Chrome/120.0 Safari/537.36" }.freeze

  setup do
    Ahoy::Event.delete_all
    Ahoy::Visit.delete_all
  end

  def recorded(name) = Ahoy::Event.where(name: name)

  # --- web ---------------------------------------------------------------

  test "signing up on the web records a sign_up for the new account" do
    post user_registration_path, headers: BROWSER, params: {
      user: { name: "New Person", email: "new-person@example.com", password: "password123", password_confirmation: "password123" }
    }

    assert_response :redirect
    event = recorded(Analytics::SIGN_UP).sole
    assert_equal User.find_by!(email: "new-person@example.com").id, event.user_id
    assert_equal "email", event.properties["provider"]
    assert_equal "web", event.properties["source"]
  end

  test "a rejected web sign-up records nothing" do
    assert_no_difference -> { Ahoy::Event.count } do
      post user_registration_path, headers: BROWSER, params: {
        user: { name: "Taken", email: users(:two).email, password: "password123", password_confirmation: "password123" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "signing in on the web records a sign_in and still signs the person in" do
    post user_session_path, headers: BROWSER, params: { user: { email: users(:two).email, password: "password123" } }

    assert_redirected_to root_path
    event = recorded(Analytics::SIGN_IN).sole
    assert_equal users(:two).id, event.user_id
    assert_equal "email", event.properties["provider"]
  end

  test "a wrong password on the web records nothing" do
    assert_no_difference -> { Ahoy::Event.count } do
      post user_session_path, headers: BROWSER, params: { user: { email: users(:two).email, password: "wrong-password" } }
    end

    assert_response :unprocessable_entity
  end

  # --- API (the mobile app) ----------------------------------------------

  test "signing up through the API records a sign_up from the app" do
    post api_v1_registrations_url, as: :json, params: { email: "Mobile@Example.com", password: "password123", name: "Mobile" }

    assert_response :created
    assert_equal "mobile@example.com", response.parsed_body.dig("user", "email")
    assert response.parsed_body["token"].present?

    event = recorded(Analytics::SIGN_UP).sole
    assert_equal response.parsed_body.dig("user", "id"), event.user_id
    assert_equal "app", event.properties["source"]
  end

  test "a rejected API sign-up records nothing" do
    assert_no_difference -> { Ahoy::Event.count } do
      post api_v1_registrations_url, as: :json, params: { email: users(:two).email, password: "password123" }
    end

    assert_response :unprocessable_entity
    assert response.parsed_body.dig("errors", "email").present?
  end

  test "signing in through the API records a sign_in from the app" do
    post api_v1_sessions_url, as: :json, params: { email: users(:two).email, password: "password123" }

    assert_response :success
    assert_equal users(:two).auth_token, response.parsed_body["token"]

    event = recorded(Analytics::SIGN_IN).sole
    assert_equal users(:two).id, event.user_id
    assert_equal "app", event.properties["source"]
  end

  test "a wrong password through the API records nothing" do
    assert_no_difference -> { Ahoy::Event.count } do
      post api_v1_sessions_url, as: :json, params: { email: users(:two).email, password: "wrong-password" }
    end

    assert_response :unauthorized
  end
end
