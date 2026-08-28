# Error ingestion for the mobile app (mobile-app-starter/src/lib/logger.ts).
#
# POST /api/v1/logs
#   headers: x-api-token (optional — crashes before sign-in still matter)
#   body:    { log: { level: "error", message:, error_class:, backtrace:, source: "mobile", context: {} } }
#   201:     { ok: true, id: 123 }
#
# The client is expected to be surgical (unhandled errors + deliberate reports
# only) and to dedupe locally; the server rolls repeats up by fingerprint.
class Api::V1::LogsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_if_token_present

  CLIENT_SOURCES = %w[mobile web].freeze
  MAX_BODY_BYTES = 64_000

  def create
    if request.raw_post.bytesize > MAX_BODY_BYTES
      return render json: { error: "Payload too large" }, status: :content_too_large
    end

    attrs = params.require(:log).permit(:level, :message, :error_class, :backtrace, :source)
    return render json: { error: "message is required" }, status: :unprocessable_entity if attrs[:message].blank?

    source  = CLIENT_SOURCES.include?(attrs[:source]) ? attrs[:source] : "mobile"
    context = raw_context.merge(
      "ip" => request.remote_ip,
      "user_agent" => request.user_agent.to_s.first(255),
      "request_id" => request.request_id
    )

    log = Log.record(
      attrs[:message],
      level:       attrs[:level].presence || :error,
      source:      source,
      error_class: attrs[:error_class].presence,
      backtrace:   attrs[:backtrace].to_s.split("\n").presence,
      context:     context,
      user:        @current_user
    )

    if log
      render json: { ok: true, id: log.id }, status: :created
    else
      render json: { ok: false, error: "Could not record log" }, status: :unprocessable_entity
    end
  end

  private

  def raw_context
    ctx = params.dig(:log, :context)
    ctx.respond_to?(:to_unsafe_h) ? ctx.to_unsafe_h : {}
  end

  def authenticate_if_token_present
    authenticate_with_token if request.headers["x-api-token"].present?
  end
end
