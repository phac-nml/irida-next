# frozen_string_literal: true

# Helper for Application
module ApplicationHelper
  include Pagy::Frontend

  # Returns the i18n configuration for LocalTime as a JSON string.
  # @return [String] JSON string of the i18n configuration for the current locale
  def local_time_i18n_config
    return '{}' if I18n.locale == :en

    t('local_time').to_json
  end
end
