# The favicon and the link-preview picture, drawn from config/app.yml by BrandArtwork.
class BrandingController < ApplicationController
  # GET /favicon.svg
  def favicon
    expires_in 1.hour, public: true
    render plain: BrandArtwork.new.favicon_svg, content_type: "image/svg+xml"
  end

  # GET /og-image.png — the picture Slack, iMessage, LinkedIn and X show beside a shared link.
  def og_image
    expires_in 1.hour, public: true
    send_data BrandArtwork.new.share_card_png, type: "image/png", disposition: "inline"
  end
end
