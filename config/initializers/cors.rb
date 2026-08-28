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
end
