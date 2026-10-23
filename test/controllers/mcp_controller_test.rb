require "test_helper"
require_relative "../support/mcp_helpers"

class McpControllerTest < ActionDispatch::IntegrationTest
  include McpHelpers

  setup { @user = users(:two) }

  test "a request without a token is told where to find the authorization server" do
    post "/mcp", params: initialize_rpc, headers: mcp_headers

    assert_response :unauthorized
    challenge = response.headers["WWW-Authenticate"]
    assert_match(/\ABearer /, challenge)
    assert_includes challenge, %(resource_metadata="#{McpServer.origin}/.well-known/oauth-protected-resource/mcp")
    assert_includes challenge, %(scope="mcp")
  end

  test "an unknown token is rejected as invalid" do
    post "/mcp", params: initialize_rpc, headers: mcp_headers("not-a-real-token")

    assert_response :unauthorized
    assert_includes response.headers["WWW-Authenticate"], %(error="invalid_token")
  end

  test "an expired token is rejected" do
    token = mcp_token_for(@user)
    travel 61.minutes do
      post "/mcp", params: initialize_rpc, headers: mcp_headers(token)
    end

    assert_response :unauthorized
    assert_includes response.headers["WWW-Authenticate"], %(error="invalid_token")
  end

  test "a revoked token is rejected" do
    token = mcp_token_for(@user)
    Doorkeeper::AccessToken.by_token(token).revoke

    post "/mcp", params: initialize_rpc, headers: mcp_headers(token)

    assert_response :unauthorized
  end

  test "a token without the mcp scope is refused with a step-up challenge" do
    token = mcp_token_for(@user, scopes: "")

    post "/mcp", params: initialize_rpc, headers: mcp_headers(token)

    assert_response :forbidden
    assert_includes response.headers["WWW-Authenticate"], %(error="insufficient_scope")
  end

  test "a token in the URL is ignored" do
    token = mcp_token_for(@user)

    post "/mcp?access_token=#{token}", params: initialize_rpc, headers: mcp_headers

    assert_response :unauthorized
  end

  test "initialize names the server and offers tools" do
    post "/mcp", params: initialize_rpc, headers: mcp_headers(mcp_token_for(@user))

    assert_response :success
    assert_equal "application/json", response.media_type
    result = response.parsed_body.fetch("result")
    assert_equal AppConfig.current.name, result.dig("serverInfo", "title")
    assert_equal McpServer::VERSION, result.dig("serverInfo", "version")
    assert result.dig("capabilities", "tools")
    assert_nil response.headers["Mcp-Session-Id"], "a stateless server issues no session"
  end

  test "tools/list describes hello" do
    post "/mcp", params: rpc("tools/list"), headers: mcp_headers(mcp_token_for(@user))

    assert_response :success
    tools = response.parsed_body.dig("result", "tools")
    assert_equal [ "hello" ], tools.map { |tool| tool["name"] }
    assert_equal "string", tools.first.dig("inputSchema", "properties", "name", "type")
    assert_equal true, tools.first.dig("annotations", "readOnlyHint")
  end

  test "hello greets the name it is given, as the token's user" do
    post "/mcp", params: call_tool_rpc("hello", name: "Ada"), headers: mcp_headers(mcp_token_for(@user))

    assert_response :success
    result = response.parsed_body.fetch("result")
    assert_not result["isError"]
    assert_equal "Hello, Ada! You're connected to #{AppConfig.current.name} as user@example.com.",
                 result.dig("content", 0, "text")
  end

  test "hello turns away a name over the length limit" do
    long_name = "a" * (HelloTool::MAX_NAME_LENGTH + 1)

    post "/mcp", params: call_tool_rpc("hello", name: long_name), headers: mcp_headers(mcp_token_for(@user))

    assert_response :success
    assert_equal true, response.parsed_body.dig("result", "isError")
  end

  test "an unknown tool is a client error and is not logged" do
    assert_no_difference -> { Log.count } do
      post "/mcp", params: call_tool_rpc("nope"), headers: mcp_headers(mcp_token_for(@user))
    end

    assert_equal(-32602, response.parsed_body.dig("error", "code"))
  end

  test "a tool that crashes is answered with an error and logged once" do
    token = mcp_token_for(@user)

    HelloTool.stub(:call, ->(**) { raise "hello broke" }) do
      assert_difference -> { Log.count }, 1 do
        post "/mcp", params: call_tool_rpc("hello"), headers: mcp_headers(token)
      end
    end

    error = response.parsed_body.fetch("error")
    assert_equal(-32603, error["code"])
    assert_not_includes error.to_json, "hello broke", "internals never reach the client"
    log = Log.last
    assert_equal "hello broke", log.message
    assert_equal "hello", log.context["mcp_tool"]
  end

  test "a notification is accepted with no body" do
    post "/mcp", params: { jsonrpc: "2.0", method: "notifications/initialized" }.to_json,
                 headers: mcp_headers(mcp_token_for(@user))

    assert_response :accepted
    assert_empty response.body
  end

  test "malformed JSON is a parse error" do
    post "/mcp", params: "{not json", headers: mcp_headers(mcp_token_for(@user))

    assert_response :bad_request
    assert_equal(-32700, response.parsed_body.dig("error", "code"))
  end

  test "there is no server-sent event stream to open" do
    get "/mcp", headers: mcp_headers(mcp_token_for(@user)).merge("Accept" => "text/event-stream")

    assert_response :method_not_allowed
  end

  test "browser-based clients may call it from any origin" do
    process :options, "/mcp", headers: {
      "Origin" => "http://localhost:6274",
      "Access-Control-Request-Method" => "POST",
      "Access-Control-Request-Headers" => "authorization, content-type"
    }

    assert_equal "*", response.headers["Access-Control-Allow-Origin"]
    assert_includes response.headers["Access-Control-Allow-Methods"], "POST"
  end
end
