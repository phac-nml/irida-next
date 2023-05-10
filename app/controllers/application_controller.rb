# frozen_string_literal: true

# Main application controller
class ApplicationController < ActionController::Base
  include Irida::Auth
  include Pagy::Backend

  add_flash_types :success, :info, :warning, :danger
  before_action :authenticate_user!

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  def not_found(err_msg = 'Resource not found')
    respond_to do |format|
      format.html { render 'shared/error/not_found', status: :not_found, layout: 'application' }
      format.turbo_stream do
        render 'shared/error/not_found', status: :not_found, locals: { type: 'alert', message: err_msg }
      end
    end
  end

  def route_not_found
    not_found
  end

  rescue_from ActionPolicy::Unauthorized do |_exception|
    render 'shared/error/not_authorized', status: :unauthorized, layout: 'application'
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    not_found(exception)
  end
end
