# Admin JSON API for the internal error log (Vue admin → /admin/logs).
class LogsController < ApplicationController
  skip_before_action :verify_authenticity_token, if: -> { request.headers["x-api-token"].present? }
  before_action :authenticate_user_or_token
  before_action :ensure_admin
  before_action :set_log, only: %i[show update destroy]

  PER_PAGE_MAX = 100

  # GET /logs.json?status=unresolved|resolved|all&level=error&source=web&q=...&page=1&per_page=25
  def index
    scope = Log.recent
    scope = case params[:status].presence || "unresolved"
    when "resolved" then scope.resolved
    when "all"      then scope
    else scope.unresolved
    end
    scope = scope.at_or_above(params[:level]) if params[:level].present? && Log::LEVELS.key?(params[:level].to_sym)
    scope = scope.from_source(params[:source]) if params[:source].present?
    scope = scope.search(params[:q]) if params[:q].present?

    @page     = [ params[:page].to_i, 1 ].max
    @per_page = params[:per_page].to_i.clamp(1, PER_PAGE_MAX)
    @per_page = 25 if params[:per_page].blank?
    @total    = scope.count
    @logs     = scope.includes(:user).offset((@page - 1) * @per_page).limit(@per_page)
    @counts   = {
      unresolved: Log.unresolved.count,
      errors_24h: Log.unresolved.at_or_above(:error).where("last_seen_at > ?", 24.hours.ago).count,
      subscriptions: LogSubscription.active.count
    }
  end

  def show; end

  # PATCH /logs/:id.json  { log: { resolved: true|false } }
  def update
    resolved = ActiveModel::Type::Boolean.new.cast(params.dig(:log, :resolved))
    resolved ? @log.resolve!(by: current_user) : @log.unresolve!
    render :show, status: :ok
  end

  def destroy
    @log.destroy!
    head :no_content
  end

  # PATCH /logs/resolve_all.json  (optionally ?level=&source=&q= to narrow)
  def resolve_all
    scope = Log.unresolved
    scope = scope.at_or_above(params[:level]) if params[:level].present? && Log::LEVELS.key?(params[:level].to_sym)
    scope = scope.from_source(params[:source]) if params[:source].present?
    scope = scope.search(params[:q]) if params[:q].present?
    count = scope.update_all(resolved_at: Time.current, updated_at: Time.current)
    render json: { ok: true, resolved: count }
  end

  # DELETE /logs/destroy_resolved.json
  def destroy_resolved
    count = Log.resolved.delete_all
    render json: { ok: true, deleted: count }
  end

  private

  def set_log
    @log = Log.find(params.expect(:id))
  end
end
