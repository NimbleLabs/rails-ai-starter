Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      ENV.fetch("CORS_ORIGINS") { Rails.env.production? ? "" : "*" }
        .split(",").map(&:strip).reject(&:empty?)
    )
    resource "/api/v1/*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: %w[], credentials: false
    # ahoy.js visit/event endpoints for the Expo web build
    resource "/ahoy/*",
      headers: :any,
      methods: %i[post options],
      expose: %w[], credentials: false
  end

  # MCP and its OAuth endpoints, open to any origin so browser-based MCP
  # clients (the MCP Inspector, web apps) can connect. That is safe because
  # these requests carry a bearer token or client credentials, never cookies.
  # WWW-Authenticate is exposed because it tells a client where to sign in.
  allow do
    origins "*"
    resource "/mcp", headers: :any, methods: %i[get post delete options],
      expose: %w[WWW-Authenticate], credentials: false
    resource "/.well-known/oauth-*", headers: :any, methods: %i[get options], credentials: false
    %w[/oauth/token /oauth/revoke /oauth/register].each do |path|
      resource path, headers: :any, methods: %i[post options], credentials: false
    end
  end
end
