require "test_helper"

class OauthHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "a website client is named by its host" do
    assert_equal "claude.ai", oauth_redirect_destination("https://claude.ai/api/mcp/auth_callback")
  end

  test "a local client is an app on this computer" do
    %w[http://localhost:54321/callback http://127.0.0.1:8080/cb http://[::1]:9000/cb].each do |uri|
      assert_equal "an app on this computer", oauth_redirect_destination(uri)
    end
  end

  test "a native client is named by its URI scheme" do
    assert_equal "the cursor app", oauth_redirect_destination("cursor://anysphere.cursor-retrieval/oauth/callback")
  end

  test "an unparseable URI is shown as it is" do
    assert_equal "not a uri", oauth_redirect_destination("not a uri")
  end

  test "each OAuth error gets a plain sentence" do
    assert_equal "The app that sent you here isn't registered with #{app_config.name}.", oauth_error_message(:invalid_client)
    assert_equal "The app asked to send you somewhere it never registered.", oauth_error_message("invalid_redirect_uri")
    assert_equal "The app asked for access #{app_config.name} doesn't offer.", oauth_error_message(:invalid_scope)
    assert_equal "The app's request was missing something or wasn't valid.", oauth_error_message(:invalid_request)
  end
end
