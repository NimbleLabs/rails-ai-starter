# Allow cross-origin requests against the JSON API namespace so the mobile app
# (Expo web, RN with custom dev hosts) can reach it. Native iOS/Android don't
# enforce CORS, but Expo web and any browser-based client will.
#
# CORS_ORIGINS is a comma-separated list of allowed origins. Defaults to "*" in
# development; in production you should set it explicitly (e.g. your web app's
# origin). The Devise/HTML pages are unaffected — this only opens /api/v1/*.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      ENV.fetch("CORS_ORIGINS") { Rails.env.production? ? "" : "*" }
        .split(",")
        .map(&:strip)
        .reject(&:empty?)
    )

    resource "/api/v1/*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: %w[],
      credentials: false
  end
end
