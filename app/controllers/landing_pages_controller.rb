class LandingPagesController < ApplicationController
  before_action :set_funnel
  layout "landing"

  def lead_page
    track_funnel_event("lead_page")
  end

  def book_call_page
    track_funnel_event("book_call_page")
  end

  def order_page
    track_funnel_event("order_page")
  end

  def order_completed_page
    track_funnel_event("order_completed_page")
  end

  private

  def set_funnel
    @funnel = Funnel.find(params[:funnel_slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Funnel not found"
  end

  def track_funnel_event(page_type)
    ahoy.track("funnel_page_view", {
      funnel_id: @funnel.id,
      funnel_slug: @funnel.slug,
      funnel_name: @funnel.name,
      page_type: page_type,
      referrer: request.referrer,
      utm_source: params[:utm_source],
      utm_medium: params[:utm_medium],
      utm_campaign: params[:utm_campaign]
    })
  end
end
