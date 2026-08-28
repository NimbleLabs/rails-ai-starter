class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :google_oauth_enabled?

  before_action :set_error_context

  # Attach request/user info to anything reported through Rails.error during
  # this request (see LogErrorSubscriber). Cleared automatically per request.
  def set_error_context
    Rails.error.set_context(
      request_id: request.request_id,
      path: request.fullpath.to_s.first(255),
      http_method: request.method,
      ip: request.remote_ip,
      user_id: (current_user&.id rescue nil)
    )
  end

  # "Sign in with Google" is only offered when both credentials are configured
  # (see config/initializers/devise.rb). Without them the OmniAuth strategy is
  # never registered, so the button would lead to a 404.
  def google_oauth_enabled?
    ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  end

  def ensure_admin
    return true if user_signed_in? && current_user.admin?

    if request.format.json?
      render status: :forbidden, json: { error: "Admin access required" }
    else
      redirect_to root_path, flash: { alert: "You don't have enough permissions to proceed" }
    end
    false
  end

  # Authenticate user via API token passed in x-api-token header
  # Use as before_action in API controllers that need token-only auth
  # Sets @current_user and signs in the user for the request
  def authenticate_with_token
    token = request.headers["x-api-token"] || request.headers["X-Api-Token"]
    @current_user = User.find_by_auth_token(token)

    unless @current_user
      render status: :unauthorized, json: { error: "Invalid or missing API token" }
      return false
    end

    # Sign in user without creating a session (for stateless API auth)
    sign_in(@current_user, store: false) if respond_to?(:sign_in)
    true
  end

  # Authenticate user via API token OR Devise session
  # Tries token auth first, falls back to Devise if no token present
  # Use as before_action in API controllers that support both auth methods
  def authenticate_user_or_token
    token = request.headers["x-api-token"] || request.headers["X-Api-Token"]

    if token.present?
      # Token provided - authenticate with token
      @current_user = User.find_by_auth_token(token)
      unless @current_user
        render status: :unauthorized, json: { error: "Invalid API token" }
        return false
      end
      sign_in(@current_user, store: false) if respond_to?(:sign_in)
      true
    elsif user_signed_in?
      # No token but user is signed in via Devise
      true
    else
      # No token and not signed in
      render status: :unauthorized, json: { error: "Authentication required" }
      false
    end
  end

  # Allow controllers to use current_user for token-authenticated requests
  def current_user
    @current_user || super
  end
end
