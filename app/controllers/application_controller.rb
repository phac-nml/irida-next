# frozen_string_literal: true

# Main application controller
class ApplicationController < ActionController::Base
  include Pagy::Backend
  add_flash_types :success, :info, :warning, :danger
  before_action :authenticate_user!, except: [:route_not_found]

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  def not_found
    render_404
  end

  def route_not_found
    if current_user
      not_found
    else
      store_location_for(:user, request.fullpath) unless request.xhr?

      redirect_to new_user_session_path, alert: I18n.t('devise.failure.unauthenticated')
    end
  end

  def render_404 # rubocop:disable Naming/VariableNumber
    respond_to do |format|
      format.html { render template: 'errors/not_found', formats: :html, layout: 'errors', status: :not_found }
      # Prevent the Rails CSRF protector from thinking a missing .js file is a JavaScript file
      format.js { render json: '', status: :not_found, content_type: 'application/json' }
      format.any { head :not_found }
    end
  end
end
