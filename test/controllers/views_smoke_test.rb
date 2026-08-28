require "test_helper"

# Renders every public-facing page so a broken template or a missing helper in
# the ERB fails here rather than in front of a user.
class ViewsSmokeTest < ActionDispatch::IntegrationTest
  test "devise pages render" do
    [ new_user_session_url, new_user_registration_url, new_user_password_url ].each do |url|
      get url
      assert_response :success, "#{url} did not render"
    end
  end

  test "account settings render for a signed-in user" do
    sign_in users(:two)
    get edit_user_registration_url
    assert_response :success
  end

  test "marketing pages render" do
    [ root_url, about_url, privacy_url, terms_url, simple_url, dark_theme_url ].each do |url|
      get url
      assert_response :success, "#{url} did not render"
    end
  end

  test "public article and contact pages render" do
    get articles_url
    assert_response :success

    get new_contact_url
    assert_response :success
  end

  test "admin-only html index pages render for an admin" do
    sign_in users(:one)
    [ contacts_url, email_templates_url ].each do |url|
      get url
      assert_response :success, "#{url} did not render"
    end
  end

  test "features is a json-only resource for the vue admin" do
    sign_in users(:one)
    get features_url(format: :json)
    assert_response :success
  end
end
