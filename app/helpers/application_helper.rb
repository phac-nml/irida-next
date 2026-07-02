# frozen_string_literal: true

# Helper for Application
module ApplicationHelper
  # Builds a hidden form and a detached submit button linked through the HTML form attribute.
  # This preserves Rails method spoofing and CSRF handling while allowing flexible layout.
  # @return [ActiveSupport::SafeBuffer] Hidden form followed by linked button markup
  def detached_button_to(label, url, method: :post, **options)
    form_id = options.delete(:form_id)
    form_class = options.delete(:form_class) || 'sr-only'
    generated_form_id = form_id || "detached_form_#{SecureRandom.hex(8)}"

    hidden_form = form_with(url:, method:, id: generated_form_id, class: form_class) { ''.html_safe }
    detached_button = button_tag(label, { type: 'submit', form: generated_form_id }.merge(options))

    safe_join([hidden_form, detached_button])
  end

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
