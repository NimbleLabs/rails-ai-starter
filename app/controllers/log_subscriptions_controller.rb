# Admin JSON API for managing who gets notified about Logs (email / Slack).
class LogSubscriptionsController < ApplicationController
  skip_before_action :verify_authenticity_token, if: -> { request.headers["x-api-token"].present? }
  before_action :authenticate_user_or_token
  before_action :ensure_admin
  before_action :set_subscription, only: %i[update destroy test]

  def index
    @log_subscriptions = LogSubscription.order(created_at: :asc)
  end

  def create
    @log_subscription = LogSubscription.new(subscription_params)
    if @log_subscription.save
      render :show, status: :created
    else
      render json: { errors: @log_subscription.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @log_subscription.update(subscription_params)
      render :show, status: :ok
    else
      render json: { errors: @log_subscription.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @log_subscription.destroy!
    head :no_content
  end

  # POST /log-subscriptions/:id/test.json — send a test notification right now.
  def test
    if LogNotifier.deliver_test(@log_subscription)
      render json: { ok: true, message: "Test notification sent to #{@log_subscription.destination}" }
    else
      render json: { ok: false, error: "Delivery failed — check the destination and server logs." }, status: :unprocessable_entity
    end
  rescue => e
    render json: { ok: false, error: "#{e.class}: #{e.message}" }, status: :unprocessable_entity
  end

  private

  def set_subscription
    @log_subscription = LogSubscription.find(params.expect(:id))
  end

  def subscription_params
    params.expect(log_subscription: [ :name, :channel, :destination, :min_level, :active, :throttle_minutes ])
  end
end
