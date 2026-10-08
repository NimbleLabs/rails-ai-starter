# The test suite's report card for the React admin at /admin/quality.
# See QualityReport for where the numbers come from.
class QualityController < ApplicationController
  skip_before_action :verify_authenticity_token, if: -> { request.headers["x-api-token"].present? }
  before_action :authenticate_user_or_token
  before_action :ensure_admin

  # GET /quality.json
  def show
    render json: { command: QualityReport::COMMAND, path: QualityReport::PATH, report: QualityReport.current&.as_json }
  rescue QualityReport::Unreadable => e
    render json: { command: QualityReport::COMMAND, path: QualityReport::PATH, report: nil, error: e.message }
  end
end
