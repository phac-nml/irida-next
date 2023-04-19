# frozen_string_literal: true

# Main application controller
class ApplicationController < ActionController::Base
  include Irida::Auth

  add_flash_types :success, :info, :warning, :danger
  before_action :authenticate_user!

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  rescue_from ActionPolicy::Unauthorized do |_exception|
    render file: Rails.public_path.join('403.html'), status: :unauthorized
  end
end
