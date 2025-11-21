# frozen_string_literal: true

# Helper for Application
module ApplicationHelper
  include Pagy::Frontend

  # Returns the LocalTime i18n configuration for the current locale as JSON
  # @return [String] JSON string of i18n translations, or empty object for English
  def local_time_i18n_config
    return '{}' if I18n.locale == :en

    I18n.t('local_time').to_json
  end
end
