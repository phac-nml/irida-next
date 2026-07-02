# frozen_string_literal: true

# Helper for Application
module ApplicationHelper
  # Renders detached button markup for all button_to-style calls.
  # The hidden form carries method spoofing and hidden params while the button
  # references the form with the HTML `form` attribute.
  # @return [ActiveSupport::SafeBuffer]
  def button_to(name = nil, options = nil, html_options = nil, &)
    detached_button_to(name, options, html_options, &)
  end

  # Builds detached button markup and supports the same call patterns as button_to.
  # @return [ActiveSupport::SafeBuffer] Hidden form followed by linked button markup
  def detached_button_to(name = nil, options = nil, html_options = nil, &)
    normalized_options = normalize_html_options(html_options)
    form_class = requested_form_class(normalized_options)
    markup = ActionView::Helpers::UrlHelper.instance_method(:button_to).bind_call(self, name, options,
                                                                                  normalized_options, &)

    detach_button_markup(markup, form_class:)
  end

  private

  def requested_form_class(html_options)
    return if html_options.blank?

    options = html_options.to_h.with_indifferent_access
    options[:form_class].presence || options.dig(:form, :class).presence
  end

  def normalize_html_options(html_options)
    return html_options if html_options.blank?

    options = html_options.to_h.deep_dup.with_indifferent_access
    form_id = options.delete(:form_id)
    return options if form_id.blank?

    options[:form] ||= {}
    options[:form][:id] = form_id
    options
  end

  def detach_button_markup(markup, form_class: nil)
    fragment = Nokogiri::HTML::DocumentFragment.parse(markup)
    form = fragment.at_css('form')
    control = form&.at_css('button, input[type="submit"]')
    return markup if form.nil? || control.nil?

    form_id = ensure_form_id!(form)
    form['class'] = form_class || 'sr-only'
    control['form'] = form_id
    control.remove

    # rubocop:disable Rails/OutputSafety
    safe_join([form.to_html.html_safe, control.to_html.html_safe])
    # rubocop:enable Rails/OutputSafety
  end

  def ensure_form_id!(form)
    return form['id'] if form['id'].present?

    generated_id = "detached_form_#{SecureRandom.hex(8)}"
    form['id'] = generated_id
    generated_id
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
