require "test_helper"
require_relative "../support/mcp_helpers"

# The journey an MCP client like Claude makes, end to end: discover the
# authorization server, register, send the user to sign in and approve, trade
# the code for a token, and call a tool.
class McpOauthFlowTest < ActionDispatch::IntegrationTest
  include McpHelpers

  setup do
    @verifier, @challenge = pkce_pair
    @user = users(:two)
  end

  test "a client discovers the server, gets the user's consent and calls hello" do
    post "/mcp", params: initialize_rpc, headers: mcp_headers
    assert_response :unauthorized
    metadata_url = response.headers["WWW-Authenticate"][/resource_metadata="([^"]+)"/, 1]

    get URI(metadata_url).path
    assert_equal [ McpServer.issuer ], response.parsed_body["authorization_servers"]

    get "/.well-known/oauth-authorization-server"
    endpoints = response.parsed_body
    assert_equal "#{McpServer.origin}/oauth/register", endpoints["registration_endpoint"]

    client_id = register_client(token_endpoint_auth_method: "none").fetch("client_id")

    # Signed out: sign in first, then land back on the consent page.
    get "/oauth/authorize", params: authorize_params(client_id)
    assert_redirected_to new_user_session_path
    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
    return_to = URI(response.location)
    assert_equal "/oauth/authorize", return_to.path
    assert_equal authorize_params(client_id).stringify_keys, Rack::Utils.parse_query(return_to.query)
    follow_redirect!

    assert_response :success
    assert_select "h1", text: "Connect Claude to #{AppConfig.current.name}?"
    assert_select "p", text: /Signed in as\s+#{Regexp.escape(@user.email)}/
    assert_select "span", text: "claude.ai"
    assert_select "li", text: /Use #{Regexp.escape(AppConfig.current.name)} as you/
    assert_select "form[data-turbo=false]", count: 2

    post "/oauth/authorize", params: authorize_params(client_id)
    callback = URI(response.location)
    assert_equal CLIENT_REDIRECT_URI, "#{callback.scheme}://#{callback.host}#{callback.path}"
    query = Rack::Utils.parse_query(callback.query)
    assert_equal "client-state", query["state"]

    post "/oauth/token", params: {
      grant_type: "authorization_code", code: query["code"], redirect_uri: CLIENT_REDIRECT_URI,
      client_id: client_id, code_verifier: @verifier, resource: McpServer.resource_url
    }
    assert_response :success
    tokens = response.parsed_body
    assert_equal "Bearer", tokens["token_type"]
    assert_equal "mcp", tokens["scope"]
    assert tokens["refresh_token"].present?

    post "/mcp", params: call_tool_rpc("hello"), headers: mcp_headers(tokens["access_token"])
    assert_response :success
    assert_equal "Hello, Regular User! You're connected to #{AppConfig.current.name} as #{@user.email}.",
                 response.parsed_body.dig("result", "content", 0, "text")
  end

  test "a confidential client trades the code using its secret" do
    client = register_client(token_endpoint_auth_method: "client_secret_post")
    sign_in @user

    post "/oauth/authorize", params: authorize_params(client["client_id"])
    code = Rack::Utils.parse_query(URI(response.location).query)["code"]

    post "/oauth/token", params: {
      grant_type: "authorization_code", code: code, redirect_uri: CLIENT_REDIRECT_URI, code_verifier: @verifier,
      client_id: client["client_id"], client_secret: "wrong"
    }
    assert_response :unauthorized

    post "/oauth/token", params: {
      grant_type: "authorization_code", code: code, redirect_uri: CLIENT_REDIRECT_URI, code_verifier: @verifier,
      client_id: client["client_id"], client_secret: client["client_secret"]
    }
    assert_response :success
  end

  test "the code is useless without the PKCE verifier" do
    client_id = register_client(token_endpoint_auth_method: "none").fetch("client_id")
    sign_in @user
    post "/oauth/authorize", params: authorize_params(client_id)
    code = Rack::Utils.parse_query(URI(response.location).query)["code"]

    post "/oauth/token", params: {
      grant_type: "authorization_code", code: code, redirect_uri: CLIENT_REDIRECT_URI,
      client_id: client_id, code_verifier: pkce_pair.first
    }

    assert_response :bad_request
    assert_equal "invalid_grant", response.parsed_body["error"]
  end

  test "an authorization request without PKCE shows the error page" do
    client_id = register_client(token_endpoint_auth_method: "none").fetch("client_id")
    sign_in @user

    get "/oauth/authorize", params: authorize_params(client_id).except(:code_challenge, :code_challenge_method)

    assert_response :bad_request
    assert_select "h1", text: "We couldn't connect that app"
  end

  test "a redirect URI the client never registered is never followed" do
    client_id = register_client(token_endpoint_auth_method: "none").fetch("client_id")
    sign_in @user

    get "/oauth/authorize", params: authorize_params(client_id).merge(redirect_uri: "https://evil.example/steal")

    assert_response :bad_request
    assert_select "h1", text: "We couldn't connect that app"
    assert_select "[role=alert]", text: "The app asked to send you somewhere it never registered."
  end

  test "cancelling sends the user back to the client with access_denied" do
    client_id = register_client(token_endpoint_auth_method: "none").fetch("client_id")
    sign_in @user

    delete "/oauth/authorize", params: authorize_params(client_id)

    query = Rack::Utils.parse_query(URI(response.location).query)
    assert_equal "access_denied", query["error"]
    assert_equal "client-state", query["state"]
    assert_equal 0, Doorkeeper::AccessGrant.count
  end

  test "a refresh token gets a new access token that works" do
    client_id = register_client(token_endpoint_auth_method: "none").fetch("client_id")
    sign_in @user
    post "/oauth/authorize", params: authorize_params(client_id)
    code = Rack::Utils.parse_query(URI(response.location).query)["code"]
    post "/oauth/token", params: {
      grant_type: "authorization_code", code: code, redirect_uri: CLIENT_REDIRECT_URI,
      client_id: client_id, code_verifier: @verifier
    }
    first = response.parsed_body

    post "/oauth/token", params: { grant_type: "refresh_token", refresh_token: first["refresh_token"], client_id: client_id }
    assert_response :success
    second = response.parsed_body
    assert_not_equal first["access_token"], second["access_token"]

    post "/mcp", params: call_tool_rpc("hello"), headers: mcp_headers(second["access_token"])
    assert_response :success
  end

  test "deleting a user deletes the access they granted" do
    user = User.create!(name: "Leaving User", email: "leaving@example.com", password: "password123")
    token = mcp_token_for(user)

    user.destroy!

    assert_nil Doorkeeper::AccessToken.by_token(token)
  end

  private

  def register_client(metadata)
    post "/oauth/register", params: { client_name: "Claude", redirect_uris: [ CLIENT_REDIRECT_URI ] }.merge(metadata).to_json,
                            headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :created
    response.parsed_body
  end

  def authorize_params(client_id)
    {
      client_id: client_id, redirect_uri: CLIENT_REDIRECT_URI, response_type: "code", scope: "mcp",
      state: "client-state", code_challenge: @challenge, code_challenge_method: "S256",
      # RFC 8707: real clients name the server they want a token for.
      resource: McpServer.resource_url
    }
  end
end
