class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_login, unless: -> { Rails.env.test? }
  helper_method :current_user

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id].present?
  end

  def require_login
    return if current_user.present?

    redirect_to login_path, alert: "Please sign in to continue."
  end

  def require_permission(permission_code)
    return if current_user&.has_permission?(permission_code)

    redirect_to root_path, alert: "You do not have permission to perform this action.", status: :forbidden
  end
end
