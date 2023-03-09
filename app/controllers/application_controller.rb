# frozen_string_literal: true

# Main application controller
class ApplicationController < ActionController::Base
  add_flash_types :success, :info, :warning, :danger
  before_action :authenticate_user!
  before_action :set_theme

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  def set_theme
    return if params[:theme].blank?

    theme = params[:theme].to_sym
    cookies[:theme] = theme
    redirect_to(request.referer || root_path)
  end
end
