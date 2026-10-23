# Checks the bearer token on an MCP request against Doorkeeper's tokens. The
# transport calls it before reading the request, and hands what it returns to
# every tool as `server_context.auth_info` (see ApplicationTool#current_user).
class McpTokenVerifier < MCP::Server::OAuth::TokenVerifier
  def verify(token)
    access_token = Doorkeeper::AccessToken.by_token(token)
    unless access_token&.accessible?
      raise MCP::Server::OAuth::InvalidTokenError, "The access token is unknown, expired or revoked"
    end

    MCP::Server::OAuth::AccessToken.new(
      token: token,
      client_id: access_token.application&.uid,
      scopes: access_token.scopes.to_a,
      expires_at: access_token.expires_at&.to_i,
      subject: access_token.resource_owner_id.to_s,
      issuer: McpServer.issuer,
      resource: McpServer.resource_url
    )
  end
end
