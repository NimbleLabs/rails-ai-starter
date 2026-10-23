# The MCP server at /mcp: what it is called, which tools it offers, and the
# OAuth details clients discover before they connect. McpController serves it,
# WellKnownController publishes the discovery documents, and Doorkeeper
# (config/initializers/doorkeeper.rb) issues the tokens. See "MCP server" in
# CLAUDE.md.
module McpServer
  # The one OAuth scope. A token without it is refused.
  SCOPE = "mcp".freeze
  VERSION = "1.0.0".freeze

  # Every tool the server offers. Add yours here.
  TOOLS = [ HelloTool ].freeze

  module_function

  # The public origin. It comes from APP_HOST, never from the request: the
  # discovery documents tell clients which issuer and resource to trust, so a
  # forged Host header must not be able to change them.
  def origin
    host = ENV["APP_HOST"].presence
    host ? "https://#{host}" : "http://localhost:#{ENV.fetch("PORT", 3000)}"
  end

  def issuer = origin
  def resource_url = "#{origin}/mcp"

  # A fresh server and transport per request, the SDK's pattern for a Rails
  # controller. Stateless, so any web process can answer any request. The
  # transport checks the bearer token before it reads the body.
  def transport
    server = MCP::Server.new(
      name: AppConfig.current.name.parameterize,
      title: AppConfig.current.name,
      version: VERSION,
      tools: TOOLS
    )
    MCP::Server::Transports::StreamableHTTPTransport.new(
      server,
      stateless: true,
      enable_json_response: true,
      serve_subscriptions_listen: false,
      # DNS rebinding tricks a browser into sending its cookies to a local
      # server. Every request here carries an OAuth token instead, and the
      # check would turn away browser-based clients like the MCP Inspector.
      dns_rebinding_protection: false,
      token_verifier: McpTokenVerifier.new,
      required_scopes: [ SCOPE ],
      resource_metadata: resource_metadata
    )
  end

  # RFC 9728: which authorization server protects /mcp.
  def resource_metadata
    MCP::Server::OAuth::ProtectedResourceMetadata.new(
      resource: resource_url,
      authorization_servers: [ issuer ],
      scopes_supported: [ SCOPE ],
      resource_name: AppConfig.current.name
    )
  end

  # RFC 8414: where that authorization server's endpoints are.
  def authorization_server_metadata
    {
      issuer: issuer,
      authorization_endpoint: "#{origin}/oauth/authorize",
      token_endpoint: "#{origin}/oauth/token",
      registration_endpoint: "#{origin}/oauth/register",
      revocation_endpoint: "#{origin}/oauth/revoke",
      scopes_supported: [ SCOPE ],
      response_types_supported: %w[code],
      grant_types_supported: %w[authorization_code refresh_token],
      token_endpoint_auth_methods_supported: OauthClientRegistrationsController::AUTH_METHODS,
      code_challenge_methods_supported: %w[S256]
    }
  end

  # The SDK answers a tool that raises with a JSON-RPC error instead of
  # letting it escape, so without this a broken tool would never reach
  # /admin/logs. A client's own mistakes (an unknown tool, bad arguments, a
  # missing scope) are expected outcomes, not incidents, and are not reported.
  # Wired up in config/initializers/mcp.rb.
  def report_exception(error, context)
    return if error.is_a?(MCP::Server::OAuth::Error)
    return if error.is_a?(MCP::Server::RequestHandlerError) && error.error_type != :internal_error

    request = rpc_request(context)
    params = request[:params].is_a?(Hash) ? request[:params] : {}
    Rails.error.report(error, handled: true, source: "mcp", context: {
      source: "web", mcp_method: request[:method], mcp_tool: params[:name]
    }.compact)
  end

  # The JSON-RPC request the SDK passes along with an error, as a Hash or as
  # the raw body.
  def rpc_request(context)
    request = context[:request] if context.is_a?(Hash)
    request = JSON.parse(request) if request.is_a?(String)
    request.is_a?(Hash) ? request.deep_symbolize_keys : {}
  rescue JSON::ParserError
    {}
  end
end
