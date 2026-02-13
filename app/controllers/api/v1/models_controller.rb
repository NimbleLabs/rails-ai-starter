class Api::V1::ModelsController < ApplicationController
  before_action :authenticate_user_or_token

  FEATURED_MODELS = %w[
    gpt-5-mini
    gpt-5
    gpt-5.2
  ].freeze

  def index
    models = Model.where(provider: "openai", model_id: FEATURED_MODELS)
    # Preserve the curated order
    ordered = FEATURED_MODELS.filter_map { |mid| models.find { |m| m.model_id == mid } }

    render json: ordered.map { |m|
      {
        id: m.id,
        model_id: m.model_id,
        name: m.name,
        provider: m.provider,
        context_window: m.context_window
      }
    }
  end
end
