class FeaturesController < ApplicationController
  skip_before_action :verify_authenticity_token, if: -> { request.headers['x-api-token'].present? }
  before_action :authenticate_user_or_token
  before_action :ensure_admin
  before_action :set_feature, only: %i[ show update destroy ]

  # GET /features
  # GET /features.json
  def index
    @features = Feature.all.order(position: :asc, created_at: :desc)
  end

  # GET /features/1
  # GET /features/1.json
  def show
  end

  # POST /features
  # POST /features.json
  def create
    @feature = Feature.new(feature_params)
    @feature.user = current_user

    if @feature.save
      render :show, status: :created, location: @feature
    else
      render json: @feature.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /features/1
  # PATCH/PUT /features/1.json
  def update
    if @feature.update(feature_params)
      render :show, status: :ok, location: @feature
    else
      render json: @feature.errors, status: :unprocessable_entity
    end
  end

  # DELETE /features/1
  # DELETE /features/1.json
  def destroy
    @feature.destroy!
    head :no_content
  end

  # PATCH /features/reorder
  def reorder
    positions = params.require(:positions)

    Feature.transaction do
      positions.each do |entry|
        Feature.where(id: entry[:id]).update_all(position: entry[:position])
      end
    end

    head :no_content
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_feature
      @feature = Feature.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def feature_params
      params.expect(feature: [ :title, :description, :status, :priority, :area, :plan, :implementation_notes, :acceptance_criteria, :started_at, :completed_at, :position ])
    end
end
