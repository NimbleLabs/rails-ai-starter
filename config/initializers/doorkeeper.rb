# Doorkeeper is the OAuth 2.1 authorization server that MCP clients (Claude,
# ChatGPT, Cursor, ...) use to act for a signed-in user at /mcp. See "MCP server"
# in CLAUDE.md. Clients register themselves (OauthClientRegistrationsController),
# send the user to /oauth/authorize, and trade the code for a token at
# /oauth/token. Every option not set here is Doorkeeper's default.
Doorkeeper.configure do
  orm :active_record

  # Signed out? Devise's failure app remembers this URL, sends the user to sign
  # in (or Google, or sign up), and brings them back to the consent page.
  resource_owner_authenticator do
    current_user || warden.authenticate!(scope: :user)
  end

  # So the consent page gets the app's helpers (app_config, brand_mark) and layout.
  base_controller "ApplicationController"

  # The authorization code flow with PKCE, which is all MCP uses. Clients
  # refresh their own tokens, so a short-lived access token costs nothing.
  grant_flows %w[authorization_code]
  force_pkce
  pkce_code_challenge_methods %w[S256]
  access_token_expires_in 1.hour
  use_refresh_token

  # Store only digests, so a database leak hands out no working credentials.
  hash_token_secrets
  hash_application_secrets

  default_scopes "mcp" # McpServer::SCOPE (app code can't be loaded from an initializer)
  enforce_configured_scopes

  # Tokens only ever arrive in the Authorization header, never in a URL.
  access_token_methods :from_bearer_authorization

  # Native clients like Claude Code listen on http://localhost or 127.0.0.1.
  # Everything else must use https (Doorkeeper already refuses javascript:,
  # data: and vbscript: URIs).
  force_ssl_in_redirect_uri do |uri|
    !(uri.host == "localhost" || Doorkeeper::OAuth::Helpers::URIChecker.loopback_uri?(uri))
  end
end

Rails.application.config.to_prepare do
  # Doorkeeper ships its own bare layout; the consent page uses the app's.
  Doorkeeper::AuthorizationsController.layout "application"
end
