# The MCP endpoint, Streamable HTTP in stateless mode. McpServer builds the
# server and transport, and the transport answers the request: it refuses one
# without a valid OAuth token (401, pointing the client at
# /.well-known/oauth-protected-resource/mcp), then runs the JSON-RPC call.
class McpController < ActionController::API
  def handle
    status, headers, body = McpServer.transport.handle_request(request)

    self.status = status
    response.headers.merge!(headers)
    self.response_body = body
  end
end
