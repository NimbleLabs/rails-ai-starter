module Api
  # NimbleHQ reads one day of traffic each night, with the NIMBLEHQ_METRICS_TOKEN
  # it shares with this app: GET /api/metrics/daily?date=YYYY-MM-DD (default
  # yesterday). Without the setting the endpoint doesn't exist.
  class MetricsController < ActionController::API
    MIN_TOKEN_LENGTH = 32

    def daily
      expected = ENV["NIMBLEHQ_METRICS_TOKEN"].to_s
      return head :not_found if expected.length < MIN_TOKEN_LENGTH

      given = request.authorization.to_s.delete_prefix("Bearer ")
      return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(given, expected)

      date = params[:date].present? ? Date.iso8601(params[:date]) : Date.yesterday
      render json: TrafficReport.new(date)
    rescue Date::Error
      render json: { error: "date must be YYYY-MM-DD" }, status: :bad_request
    end
  end
end
