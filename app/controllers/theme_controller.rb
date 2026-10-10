# The admin Theme page (/admin/theme): config/app.yml's name and look, the
# presets in lib/themes, a live preview of any change and, in development,
# saving it. Production previews but doesn't save: the file deploys with the
# code, so a change there goes through a commit like any other. See AppConfig.
class ThemeController < ApplicationController
  skip_before_action :verify_authenticity_token, if: -> { request.headers["x-api-token"].present? }
  before_action :authenticate_user_or_token
  before_action :ensure_admin

  # GET /theme.json
  def show
    render json: page(AppConfig.current)
  end

  # POST /theme/preview.json  { config: { name:, ..., theme: { primary:, ... } } }
  def preview
    render json: preview_of(AppConfig.new(config_params))
  end

  # PUT /theme.json  { config: { ... } }
  def update
    unless saving_allowed?
      return render json: { errors: { base: [ "Saving works in development, where it writes #{AppConfig::PATH} for you to commit." ] } },
                    status: :forbidden
    end

    config = AppConfig.new(config_params)
    return render json: { errors: { base: config.errors } }, status: :unprocessable_entity unless config.valid?

    config.write
    render json: page(AppConfig.current)
  end

  private

  def saving_allowed?
    Rails.env.local?
  end

  def page(config)
    {
      config: config.to_h,
      preview: preview_of(config),
      presets: ThemePreset.all,
      fonts: AppConfig::FONTS.map { |family, font| { family: family, category: font[:category], display_only: font[:display_only] == true } },
      corners: AppConfig::CORNERS.keys,
      can_save: saving_allowed?,
      path: AppConfig::PATH
    }
  end

  # What the page needs to show a config before it's saved. Tokens only when
  # the look is valid; contrast whenever the primary is a color, so a
  # too-light primary shows how far off it is.
  def preview_of(config)
    theme = config.theme
    valid = theme.errors.empty?
    {
      errors: config.errors,
      css_variables: (theme.css_variables if valid),
      fonts_url: (theme.google_fonts_url if valid),
      contrast: (theme.contrast if theme.primary.match?(AppConfig::HEX)),
      yaml: config.to_yaml
    }
  end

  def config_params
    params.require(:config)
          .permit(:name, :short_name, :tagline, :support_email, theme: %i[display_font body_font primary secondary corners])
          .to_h
  end
end
