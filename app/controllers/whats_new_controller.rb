class WhatsNewController < ApplicationController
  # The feed arrives newest first; keep its order so same-day entries stay as published.
  def show
    raise ActionController::RoutingError, "Not Found" unless WhatsNewFeed.enabled?
    @app_name = ENV.fetch("APP_NAME", "Starter")
    @entries = WhatsNewFeed.entries
  end
end
