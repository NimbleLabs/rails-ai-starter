class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def ensure_admin
    return true if user_signed_in? && current_user.admin?
    redirect_to root_path, flash: { alert: "You don't have enough permissions to proceed" }
    false
  end
end
