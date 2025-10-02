class ApplicationController < ActionController::Base
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # ActiveAdmin authentication
  def authenticate_admin!
    unless user_signed_in? && current_user.admin_user_type?
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end
end
