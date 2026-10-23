# Shared by the MCP and OAuth tests: registered clients, access tokens, PKCE
# pairs and JSON-RPC bodies.
module McpHelpers
  CLIENT_REDIRECT_URI = "https://claude.ai/api/mcp/auth_callback".freeze

  def create_oauth_client(name: "Claude", redirect_uri: CLIENT_REDIRECT_URI, confidential: false)
    Doorkeeper::Application.create!(name: name, redirect_uri: redirect_uri, scopes: McpServer::SCOPE, confidential: confidential)
  end

  # The raw token a client would send; the database only keeps its digest.
  def mcp_token_for(user, scopes: McpServer::SCOPE, **attributes)
    Doorkeeper::AccessToken.create!(
      application: create_oauth_client, resource_owner_id: user.id, scopes: scopes, expires_in: 1.hour, **attributes
    ).plaintext_token
  end

  def pkce_pair
    verifier = SecureRandom.urlsafe_base64(48)
    [ verifier, Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false) ]
  end

  def mcp_headers(token = nil)
    headers = { "CONTENT_TYPE" => "application/json", "Accept" => "application/json, text/event-stream" }
    headers["Authorization"] = "Bearer #{token}" if token
    headers
  end

  def rpc(method, params = nil, id: 1)
    { jsonrpc: "2.0", id: id, method: method, params: params }.compact.to_json
  end

  def initialize_rpc
    rpc("initialize", { protocolVersion: "2025-11-25", capabilities: {}, clientInfo: { name: "test", version: "1.0" } })
  end

  def call_tool_rpc(name, arguments = {})
    rpc("tools/call", { name: name, arguments: arguments })
  end
end
