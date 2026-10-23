require "test_helper"

class WellKnownControllerTest < ActionDispatch::IntegrationTest
  test "the protected resource document names /mcp and its authorization server" do
    %w[/.well-known/oauth-protected-resource/mcp /.well-known/oauth-protected-resource].each do |path|
      get path

      assert_response :success
      body = response.parsed_body
      assert_equal "#{McpServer.origin}/mcp", body["resource"]
      assert_equal [ McpServer.origin ], body["authorization_servers"]
      assert_equal [ "mcp" ], body["scopes_supported"]
      assert_equal [ "header" ], body["bearer_methods_supported"]
      assert_equal AppConfig.current.name, body["resource_name"]
      assert_includes response.headers["Cache-Control"], "public"
    end
  end

  test "the authorization server document lists its endpoints and requires PKCE" do
    get "/.well-known/oauth-authorization-server"

    assert_response :success
    body = response.parsed_body
    origin = McpServer.origin
    assert_equal origin, body["issuer"]
    assert_equal "#{origin}/oauth/authorize", body["authorization_endpoint"]
    assert_equal "#{origin}/oauth/token", body["token_endpoint"]
    assert_equal "#{origin}/oauth/register", body["registration_endpoint"]
    assert_equal "#{origin}/oauth/revoke", body["revocation_endpoint"]
    assert_equal [ "S256" ], body["code_challenge_methods_supported"]
    assert_equal [ "code" ], body["response_types_supported"]
    assert_includes body["token_endpoint_auth_methods_supported"], "none"
  end

  test "every endpoint the document lists is a real route" do
    get "/.well-known/oauth-authorization-server"
    endpoints = response.parsed_body.slice("authorization_endpoint", "token_endpoint", "registration_endpoint", "revocation_endpoint")

    endpoints.each_value do |url|
      path = URI(url).path
      assert Rails.application.routes.recognize_path(path, method: path == "/oauth/authorize" ? :get : :post),
             "#{path} is not routed"
    end
  end

  test "browser-based clients can read the documents" do
    get "/.well-known/oauth-authorization-server", headers: { "Origin" => "http://localhost:6274" }

    assert_equal "*", response.headers["Access-Control-Allow-Origin"]
  end
end
