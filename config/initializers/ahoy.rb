# Ahoy is THE analytics tool for this app — visits + events in our own Postgres,
# no third-party SDK. See app/services/analytics.rb for the tracking helper and
# CLAUDE.md → "Analytics (Ahoy)".
class Ahoy::Store < Ahoy::DatabaseStore
  # Ahoy's bot detection would discard native-app traffic (iOS CFNetwork,
  # Android okhttp user agents). API requests are never bots we care about.
  def exclude?
    return false if native_client_request?
    super
  end

  def track_visit(data)
    data[:user_id] ||= current_user_id
    super(data)
  end

  def track_event(data)
    data[:user_id] ||= current_user_id
    super(data)
  end

  private

  def native_client_request?
    request.present? && request.path.to_s.start_with?("/api/")
  end

  def current_user_id
    controller.current_user.id if controller.respond_to?(:current_user) && controller.current_user
  rescue
    nil
  end
end

# Enable the JS/API endpoints (/ahoy/visits, /ahoy/events) used by ahoy.js on
# the web and by Ahoy::Tracker(api: true) for mobile requests.
Ahoy.api = true

# Match the mobile client's visit TTL (mobile-app-starter/src/lib/visit.ts).
Ahoy.visit_duration = 30.minutes

# set to true for geocoding (and add the geocoder gem to your Gemfile)
Ahoy.geocode = false

Ahoy.cookie_options = { same_site: :lax, httponly: true }
