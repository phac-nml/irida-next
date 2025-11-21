# frozen_string_literal: true

# Helper for Application
module ApplicationHelper
  include Pagy::Frontend

  # Returns the i18n configuration for LocalTime as a JSON string.
  # Handles missing translations gracefully by returning empty JSON.
  # @return [String] JSON string of the i18n configuration for the current locale
  def local_time_i18n_config
    return '{}' if I18n.locale == :en

    t('local_time', raise: true).to_json
  rescue I18n::MissingTranslationData => e
    Rails.logger.warn "Missing local_time translation for #{I18n.locale}: #{e.message}"
    '{}'
  end
end
