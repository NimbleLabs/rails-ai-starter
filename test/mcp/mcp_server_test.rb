require "test_helper"

class McpServerTest < ActiveSupport::TestCase
  test "the origin is APP_HOST over https" do
    with_env("APP_HOST" => "app.example.com") do
      assert_equal "https://app.example.com", McpServer.origin
      assert_equal "https://app.example.com/mcp", McpServer.resource_url
      assert_equal "https://app.example.com/.well-known/oauth-protected-resource/mcp",
                   McpServer.resource_metadata.well_known_url
    end
  end

  test "without APP_HOST the origin is the local server" do
    with_env("APP_HOST" => nil, "PORT" => nil) do
      assert_equal "http://localhost:3000", McpServer.origin
    end
    with_env("APP_HOST" => "", "PORT" => "4000") do
      assert_equal "http://localhost:4000", McpServer.origin
    end
  end

  test "a tool's crash is reported with the method and tool it came from" do
    assert_difference -> { Log.count }, 1 do
      McpServer.report_exception(RuntimeError.new("tool exploded"), request: {
        "jsonrpc" => "2.0", "id" => 1, "method" => "tools/call", "params" => { "name" => "hello" }
      })
    end

    log = Log.last
    assert_equal "tool exploded", log.message
    assert_equal "web", log.source
    assert_equal "tools/call", log.context["mcp_method"]
    assert_equal "hello", log.context["mcp_tool"]
  end

  test "a crash is still reported when the request can't be read" do
    [ nil, {}, { request: "{not json" }, { request: { params: [ 1, 2 ] } }, "context" ].each do |context|
      assert_difference -> { Log.count }, 1 do
        McpServer.report_exception(RuntimeError.new("unreadable #{context.inspect}"), context)
      end
    end
  end

  test "a client's own mistakes are not reported" do
    assert_no_difference -> { Log.count } do
      McpServer.report_exception(
        MCP::Server::RequestHandlerError.new("Tool not found: nope", {}, error_type: :invalid_params), {}
      )
      McpServer.report_exception(MCP::Server::OAuth::InsufficientScopeError.new, {})
      McpServer.report_exception(MCP::Server::OAuth::InvalidTokenError.new, {})
    end
  end

  test "an internal error inside the SDK is reported" do
    assert_difference -> { Log.count }, 1 do
      McpServer.report_exception(MCP::Server::RequestHandlerError.new("Internal failure", {}), {})
    end
  end

  private

  def with_env(values)
    saved = values.keys.to_h { |key| [ key, ENV[key] ] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    saved.each { |key, value| ENV[key] = value }
  end
end
