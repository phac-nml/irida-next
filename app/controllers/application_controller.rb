# frozen_string_literal: true

# Main application controller
class ApplicationController < ActionController::Base
  include PublicActivity::StoreController
  include Irida::Auth
  include Pagy::Backend
  include RouteHelper

  add_flash_types :success, :info, :warning, :danger
  before_action :authenticate_user!
  before_action :pipelines_enabled?
  around_action :set_current_user
  around_action :use_logidze_responsible, only: %i[create destroy update transfer] # rubocop:disable Rails/LexicallyScopedActionFilter
  around_action :switch_locale

  helper_method :error_message

  def set_current_user
    Current.user = current_user
    yield
  end

  def switch_locale(&)
    locale = params[:locale] || current_user.try(:locale) || I18n.default_locale
    I18n.with_locale(locale, &)
  end

  def use_logidze_responsible(&)
    Logidze.with_responsible(current_user&.id, transactional: false, &)
  end

  def not_found(err_msg = 'Resource not found')
    @title = I18n.t('layouts.application.browser_page_titles.page_not_found')
    if defined?(err_msg.message)
      match_data = err_msg.message.match(/Couldn't find (\w+) with 'id'=(\d+)/)
      if match_data
        err_msg = I18n.t("activerecord.exceptions.#{match_data[1].underscore}.not_found",
                         token_id: match_data[2])
      end
    end
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

  rescue_from ActionPolicy::Unauthorized do |exception|
    @title = I18n.t('layouts.application.browser_page_titles.unauthorized')
    render 'shared/error/not_authorized', status: :unauthorized, layout: 'application', locals: {
      authorization_message: exception.result.message
    }
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    not_found(exception)
  end

  def pipelines_enabled?
    @pipelines_enabled = Irida::Pipelines.instance.available_pipelines.any?
  end

  def error_message(object)
    object.errors.full_messages.to_sentence
  end

  private

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(_resource_or_scope)
    params = { locale: I18n.locale } if I18n.locale != I18n.default_locale
    new_user_session_path(params)
  end
end
