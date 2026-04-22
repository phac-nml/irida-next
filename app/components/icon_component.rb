# frozen_string_literal: true

# App-owned wrapper around rails_icons with IRIDA styling and fallbacks.
class IconComponent < Component
  NATIVE_ICON_HELPER = RailsIcons::Helpers::IconHelper.instance_method(:icon)
  FALLBACK_ICONS = %w[question-mark-circle warning].freeze
  ICON_SUGGESTIONS = {
    /check/ => %w[check check-circle check-badge],
    /arrow/ => %w[arrow-up arrow-down arrow-left arrow-right],
    /user/ => %w[user user-circle users],
    /plus/ => %w[plus plus-circle plus-square],
    /minus/ => %w[minus minus-circle minus-square],
    /x/ => %w[x x-circle x-mark],
    /eye/ => %w[eye eye-slash],
    /heart/ => %w[heart heart-fill]
  }.freeze
  attr_reader :icon_name, :color, :size, :variant, :rails_icons_options

  # rubocop:disable Metrics/ParameterLists
  def initialize(icon_name, color: :default, size: :md, variant: nil, library: nil, **options)
    @icon_name = normalize_icon_name(icon_name)
    @color = validate_color(color)
    @size = validate_size(size)
    @variant = variant
    @rails_icons_options = build_rails_icons_options(variant, library, options)
    apply_styling
  end
  # rubocop:enable Metrics/ParameterLists

  def call
    IconRenderer.clean_html(native_rails_icon(icon_name, **rails_icons_options))
  rescue StandardError => e
    handle_error(e)
  end

  private

  def build_rails_icons_options(variant, library, additional_options)
    options = IconRenderer.build_options(variant, library, additional_options)
    normalize_class_alias!(options)
    options
  end

  def normalize_class_alias!(options)
    return unless options.key?(:classes) && !options.key?(:class)

    options[:class] = options.delete(:classes)
  end

  def apply_styling
    IconRenderer.apply_styling(rails_icons_options, color, size, variant)
    IconRenderer.append_icon_name_class(rails_icons_options, icon_name) unless Rails.env.production?
  end

  def validate_color(value)
    return nil if value.nil?
    return value if IconRenderer::COLORS.key?(value)

    :default
  end

  def validate_size(value)
    return nil if value.nil?
    return value if IconRenderer::SIZES.key?(value)

    :md
  end

  def normalize_icon_name(name)
    raise ArgumentError, 'Icon name cannot be nil or blank' if name.blank?

    normalized = name.is_a?(String) ? name : name.to_s.tr('_', '-')
    normalized.downcase
  end

  def native_rails_icon(...)
    NATIVE_ICON_HELPER.bind_call(helpers, ...)
  end

  def handle_error(error)
    fallback_icon = attempt_fallback_icon
    return fallback_icon if fallback_icon
    return development_error_indicator(error) if Rails.env.local?

    nil
  end

  def attempt_fallback_icon
    fallback_options = rails_icons_options.except(:variant, :library)

    FALLBACK_ICONS.each do |fallback_name|
      return IconRenderer.clean_html(native_rails_icon(fallback_name, **fallback_options))
    rescue StandardError
      next
    end

    nil
  end

  def development_error_indicator(error)
    suggestions = ICON_SUGGESTIONS.find { |pattern, _| icon_name.match?(pattern) }&.last || []
    suggestion_text = suggestions.any? ? " (Suggestions: #{suggestions.join(', ')})" : ''

    helpers.content_tag(
      :span,
      "Icon '#{icon_name}' not found#{suggestion_text}",
      class: 'text-red-500 text-xs font-mono border border-red-300 rounded px-2 py-1 bg-red-50',
      title: "Icon rendering error: #{error.message}"
    )
  end
end
