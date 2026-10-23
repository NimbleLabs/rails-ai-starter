# The documents an MCP client reads before it connects: which authorization
# server protects /mcp (RFC 9728), and where that server's endpoints are
# (RFC 8414). Both come from McpServer.
class WellKnownController < ActionController::API
  def oauth_protected_resource
    expires_in 1.hour, public: true
    render json: McpServer.resource_metadata
  end

  def oauth_authorization_server
    expires_in 1.hour, public: true
    render json: McpServer.authorization_server_metadata
  end
end
