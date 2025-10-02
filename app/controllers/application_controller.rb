class ApplicationController < ActionController::Base
  include Pagy::Backend

  # Protect from CSRF attacks
  protect_from_forgery with: :exception

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # ActiveAdmin authentication with audit logging
  def authenticate_admin!
    unless user_signed_in? && current_user.admin_user_type?
      # Log unauthorized admin access attempt
      Rails.logger.warn "[Security] Unauthorized admin access attempt from IP: #{request.remote_ip}, User: #{current_user&.email || 'anonymous'}, Path: #{request.path}"

      redirect_to root_path, alert: "You are not authorized to access this page."
    else
      # Log successful admin access for audit trail
      Rails.logger.info "[Audit] Admin access: User: #{current_user.email}, IP: #{request.remote_ip}, Path: #{request.path}"
    end
  end

  # Additional helper for sensitive actions audit logging
  def log_sensitive_action(action, details = {})
    Rails.logger.info "[Audit] Sensitive action '#{action}' by User: #{current_user&.email}, IP: #{request.remote_ip}, Details: #{details.to_json}"
  end
end
