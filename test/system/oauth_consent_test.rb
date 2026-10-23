require "application_system_test_case"
require_relative "../support/mcp_helpers"

# The OAuth consent page in a real browser, at phone size: what a person sees
# when they connect Claude (or any MCP client) to their account.
class OauthConsentTest < ApplicationSystemTestCase
  include McpHelpers

  IPHONE  = [ 390, 844 ].freeze
  DESKTOP = [ 1400, 1400 ].freeze

  setup do
    page.driver.browser.manage.window.resize_to(*IPHONE)
    login_as users(:two), scope: :user
    # A local client, so the browser can actually follow the redirect back.
    @callback_url = "#{page.server.base_url}/oauth-test-callback"
    @client = create_oauth_client(name: "Claude Code", redirect_uri: @callback_url)
    _verifier, @challenge = pkce_pair
  end

  teardown do
    page.driver.browser.manage.window.resize_to(*DESKTOP)
  end

  test "allowing access sends the user back to the client with a code" do
    visit_consent_page

    assert_selector "h1", text: "Connect Claude Code to #{AppConfig.current.name}?"
    assert_text "Signed in as user@example.com"
    assert_text "an app on this computer"
    assert_not page.evaluate_script("document.documentElement.scrollWidth > document.documentElement.clientWidth + 1"),
               "the consent page scrolls sideways on a phone"
    [ "Allow", "Cancel" ].each do |label|
      assert_operator find_button(label).native.size.height, :>=, 40, "#{label} is too small to tap"
    end

    click_on "Allow"

    assert_current_path "/oauth-test-callback", ignore_query: true
    query = Rack::Utils.parse_query(URI(page.current_url).query)
    assert query["code"].present?
    assert_equal "browser-state", query["state"]
  end

  test "cancelling sends the user back with access_denied" do
    visit_consent_page

    click_on "Cancel"

    assert_current_path "/oauth-test-callback", ignore_query: true
    assert_equal "access_denied", Rack::Utils.parse_query(URI(page.current_url).query)["error"]
  end

  private

  def visit_consent_page
    visit "/oauth/authorize?" + {
      client_id: @client.uid, redirect_uri: @callback_url, response_type: "code", scope: "mcp",
      state: "browser-state", code_challenge: @challenge, code_challenge_method: "S256"
    }.to_query
  end
end
