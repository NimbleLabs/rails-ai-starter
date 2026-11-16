# Product analytics = Ahoy. Every event is an Ahoy::Event row in our own
# Postgres, so web pages, the JSON API and the mobile app all land in one table
# that admin dashboards (see DashboardMetrics) can join straight against users.
# We deliberately do not run a third-party analytics SDK.
#
# Track things *server-side*, where they actually happen — a dropped request,
# an ad-blocker or a crash can't deflate the numbers, and a client can't
# inflate them. The mobile app may only report the handful of events the server
# genuinely cannot see (CLIENT_REPORTABLE); everything else it sends is dropped.
#
#   Analytics.track(Analytics::SIGN_UP, user: user, controller: self)
#   Analytics.track("article_read", user: current_user, controller: self, properties: { slug: @article.slug })
module Analytics
  SIGN_UP          = "sign_up".freeze
  SIGN_IN          = "sign_in".freeze
  APP_OPENED       = "app_opened".freeze
  PUSH_OPENED      = "push_opened".freeze

  # ahoy.js records every page load under this name. Page views already show up as visits and landing pages,
  # so the dashboard leaves them out of "What people did".
  PAGE_VIEW        = "$view".freeze

  # Events the mobile app is allowed to POST to /api/v1/events.
  CLIENT_REPORTABLE = [ APP_OPENED, PUSH_OPENED ].freeze

  # What each event means, in the words an admin reads on the dashboard. Add a line when you add an event.
  # An event missing from this list is shown as its name, tidied up ("article_read" reads "Article read").
  LABELS = {
    SIGN_UP     => "Signed up",
    SIGN_IN     => "Signed in",
    APP_OPENED  => "Opened the app",
    PUSH_OPENED => "Opened a notification",
    PAGE_VIEW   => "Viewed a page"
  }.freeze

  WEB = "web".freeze
  APP = "app".freeze

  class << self
    # Record one event. Never raises outside test. Returns true when written.
    def track(name, user: nil, properties: {}, controller: nil, request: nil, source: nil, time: nil)
      name = name.to_s
      return false if name.blank?

      props = (properties || {}).to_h.compact.transform_keys(&:to_s)
      props["source"] ||= source || default_source(controller, request)

      options = {}
      options[:time] = time if time
      tracker(user: user, controller: controller, request: request).track(name, props, options)
      true
    rescue => e
      raise e if Rails.env.test?
      Rails.logger.warn("[analytics] #{name} not recorded: #{e.class}: #{e.message}")
      false
    end

    # The plain-English name for an event, for people reading the dashboard.
    def label(name)
      name = name.to_s
      LABELS[name] || name.delete_prefix("$").tr("_.-", " ").squish.capitalize.presence || "Unnamed event"
    end

    private

    # Events must land on the *same visit* as the rest of the session. API
    # requests carry their visit in the Ahoy-Visit / Ahoy-Visitor headers (the
    # same ones ahoy.js uses); `api: true` makes ahoy read them.
    def tracker(user:, controller:, request:)
      req = request || controller.try(:request)
      return Ahoy::Tracker.new(request: req, user: user, api: true) if api_request?(controller, req)

      if controller.respond_to?(:ahoy)
        return Ahoy::Tracker.new(request: req, user: user || controller.ahoy.user, visit_token: controller.ahoy.visit_token)
      end

      Ahoy::Tracker.new(request: req, user: user)
    end

    def api_request?(controller, request)
      req = request || controller.try(:request)
      req.present? && req.path.to_s.start_with?("/api/")
    end

    def default_source(controller, request)
      api_request?(controller, request) ? APP : WEB
    end
  end
end
