require "test_helper"

class OauthClientRegistrationsControllerTest < ActionDispatch::IntegrationTest
  REDIRECT_URI = "https://claude.ai/api/mcp/auth_callback".freeze

  test "a public client gets a client_id and no secret" do
    register client_name: "Claude", redirect_uris: [ REDIRECT_URI ], token_endpoint_auth_method: "none"

    assert_response :created
    body = response.parsed_body
    assert_nil body["client_secret"]
    assert_equal "none", body["token_endpoint_auth_method"]
    assert_equal [ REDIRECT_URI ], body["redirect_uris"]
    assert_equal %w[authorization_code refresh_token], body["grant_types"]
    assert_equal "mcp", body["scope"]

    application = Doorkeeper::Application.find_by!(uid: body["client_id"])
    assert_equal "Claude", application.name
    assert_not application.confidential?
    assert_equal "mcp", application.scopes.to_s
  end

  test "a client that names no auth method is confidential and gets a secret, stored only as a digest" do
    register redirect_uris: [ REDIRECT_URI ]

    assert_response :created
    body = response.parsed_body
    assert_equal "client_secret_basic", body["token_endpoint_auth_method"]
    assert body["client_secret"].present?
    assert_equal 0, body["client_secret_expires_at"]
    application = Doorkeeper::Application.find_by!(uid: body["client_id"])
    assert application.confidential?
    assert_not_equal body["client_secret"], application.secret
    assert application.secret_matches?(body["client_secret"])
  end

  test "a client with no name gets a generic one" do
    register client_name: "   ", redirect_uris: [ REDIRECT_URI ]

    assert_equal OauthClientRegistrationsController::DEFAULT_NAME, response.parsed_body["client_name"]
  end

  test "a long client name is cut to the limit" do
    register client_name: "x" * 500, redirect_uris: [ REDIRECT_URI ]

    assert_equal OauthClientRegistrationsController::MAX_NAME_LENGTH, response.parsed_body["client_name"].length
  end

  test "several redirect URIs are kept, up to the limit" do
    uris = (1..OauthClientRegistrationsController::MAX_REDIRECT_URIS).map { |i| "https://client.example/callback/#{i}" }

    register redirect_uris: uris

    assert_response :created
    assert_equal uris, Doorkeeper::Application.find_by!(uid: response.parsed_body["client_id"]).redirect_uri.split
  end

  test "one redirect URI over the limit is refused" do
    uris = (0..OauthClientRegistrationsController::MAX_REDIRECT_URIS).map { |i| "https://client.example/callback/#{i}" }

    assert_no_registration { register redirect_uris: uris }
    assert_error "invalid_redirect_uri"
  end

  test "local clients may use http on localhost and 127.0.0.1" do
    register redirect_uris: [ "http://localhost:54321/callback", "http://127.0.0.1:54321/callback" ]

    assert_response :created
  end

  test "a native app may use its own URI scheme" do
    register redirect_uris: [ "cursor://anysphere.cursor-retrieval/oauth/user-mcp/callback" ]

    assert_response :created
  end

  test "redirect URIs that are missing, unsafe or malformed are refused" do
    [
      nil,
      [],
      REDIRECT_URI,
      [ 42 ],
      [ "" ],
      [ "http://client.example/callback" ],
      [ "javascript:alert(1)" ],
      [ "urn:ietf:wg:oauth:2.0:oob" ],
      [ "https://client.example/one https://evil.example/two" ],
      [ "https://client.example/callback#fragment" ],
      [ "/relative/callback" ]
    ].each do |redirect_uris|
      assert_no_registration { register redirect_uris: redirect_uris }
      assert_error "invalid_redirect_uri", "#{redirect_uris.inspect} was accepted"
    end
  end

  test "unsupported auth methods, grant types and response types are refused" do
    [
      { token_endpoint_auth_method: "private_key_jwt" },
      { grant_types: %w[client_credentials] },
      { grant_types: "authorization_code" },
      { response_types: %w[token] }
    ].each do |metadata|
      assert_no_registration { register(redirect_uris: [ REDIRECT_URI ], **metadata) }
      assert_error "invalid_client_metadata", "#{metadata.inspect} was accepted"
    end
  end

  test "a body that isn't a JSON object is refused" do
    [ "{not json", "[1, 2]", "" ].each do |body|
      post "/oauth/register", params: body, headers: { "CONTENT_TYPE" => "application/json" }
      assert_error "invalid_client_metadata"
    end
  end

  test "a client registering in a loop is slowed down" do
    OauthClientRegistrationsController.cache_store.stub(:increment, 31) do
      register redirect_uris: [ REDIRECT_URI ]
    end

    assert_response :too_many_requests
  end

  private

  def register(**metadata)
    post "/oauth/register", params: metadata.to_json, headers: { "CONTENT_TYPE" => "application/json" }
  end

  def assert_no_registration(&block)
    assert_no_difference(-> { Doorkeeper::Application.count }, &block)
  end

  def assert_error(error, message = nil)
    assert_response :bad_request, message
    assert_equal error, response.parsed_body["error"], message
    assert response.parsed_body["error_description"].present?
  end
end
