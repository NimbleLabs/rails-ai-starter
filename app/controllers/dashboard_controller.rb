# Admin dashboard metrics (Ahoy) for the React admin at /admin.
class DashboardController < ApplicationController
  skip_before_action :verify_authenticity_token, if: -> { request.headers["x-api-token"].present? }
  before_action :authenticate_user_or_token
  before_action :ensure_admin

  # GET /dashboard/metrics.json?days=30
  def metrics
    render json: DashboardMetrics.new(days: params.fetch(:days, DashboardMetrics::DEFAULT_DAYS)).as_json
  end
end
