# frozen_string_literal: true

# Main application controller
class ApplicationController < ActionController::Base
  include Irida::Auth

  add_flash_types :success, :info, :warning, :danger
  before_action :authenticate_user!

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  def not_found
    render 'shared/error/not_found', status: :not_found
  end

  def route_not_found
    not_found
  end

  rescue_from ActionPolicy::Unauthorized do |_exception|
    render 'shared/error/not_authorized', status: :unauthorized
  end

  rescue_from ActiveRecord::RecordNotFound do |_exception|
    not_found
  end
end
