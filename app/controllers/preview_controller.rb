# frozen_string_literal: true

# lookbook preview controller
class PreviewController < ActionController::Base
  layout 'lookbook'

  before_action :set_locale

  def set_locale
    I18n.locale = params[:lookbook][:display][:lang] || I18n.default_locale
  end
end
