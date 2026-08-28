# Ahoy analytics ingestion for the mobile app (mobile-app-starter/src/lib/analytics.ts).
#
# POST /api/v1/events
#   headers: Ahoy-Visitor, Ahoy-Visit (UUIDs minted by the client), x-api-token (optional)
#   body:    { events: [{ name:, properties: {}, time: }], platform:, app_version:, os_version: }
#   200:     { ok: true, tracked: n, received: n }
#
# Auth is optional on purpose: the top of the funnel is exactly what we want to
# measure. Identity comes from the visit; it stitches to the user at sign-in.
# Only Analytics::CLIENT_REPORTABLE event names are written — everything else
# is already recorded server-side and would double count.
class Api::V1::EventsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_if_token_present

  MAX_EVENTS_PER_REQUEST = 50

  def create
    events = params[:events]
    return render json: { error: "events must be an array" }, status: :bad_request unless events.is_a?(Array)
    return render json: { error: "Too many events (max #{MAX_EVENTS_PER_REQUEST})" }, status: :unprocessable_entity if events.size > MAX_EVENTS_PER_REQUEST

    tracked = events.count { |event| track(event) }
    render json: { ok: true, tracked: tracked, received: events.size }
  end

  private

  def track(event)
    event = event.respond_to?(:to_unsafe_h) ? event.to_unsafe_h : event
    return false unless event.is_a?(Hash)

    name = event["name"].to_s
    return false unless Analytics::CLIENT_REPORTABLE.include?(name)

    properties = event["properties"]
    properties = {} unless properties.is_a?(Hash)

    Analytics.track(name, user: @current_user, properties: properties, request: request, source: Analytics::APP, time: parse_time(event["time"]))
  end

  def parse_time(value)
    return nil if value.blank?
    Time.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end

  def authenticate_if_token_present
    authenticate_with_token if request.headers["x-api-token"].present?
  end
end
