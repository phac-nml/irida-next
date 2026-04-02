# frozen_string_literal: true

# Shared icon option/styling/sanitization utilities used by app and embedded Pathogen code.
class IconRenderer
  COLORS = {
    default: 'text-slate-900 dark:text-slate-100 fill-slate-900 dark:fill-slate-100',
    subdued: 'text-slate-600 dark:text-slate-300 fill-slate-600 dark:fill-slate-300',
    primary: 'text-primary-600 dark:text-primary-500 fill-primary-600 dark:fill-primary-500',
    success: 'text-green-600 dark:text-green-500 fill-green-600 dark:fill-green-500',
    warning: 'text-yellow-600 dark:text-yellow-500 fill-yellow-600 dark:fill-yellow-500',
    danger: 'text-red-600 dark:text-red-500 fill-red-600 dark:fill-red-500',
    blue: 'text-blue-600 dark:text-blue-500 fill-blue-600 dark:fill-blue-500',
    white: 'text-white fill-white'
  }.freeze

  SIZES = {
    sm: 'size-4',
    md: 'size-6',
    lg: 'size-8',
    xl: 'size-10'
  }.freeze

  class << self
    def build_options(variant, library, additional_options)
      options = additional_options.dup
      options[:variant] = variant if variant
      options[:library] = library if library
      options
    end

    def apply_styling(options, color, size, variant)
      icon_classes = combine_classes(
        COLORS[color],
        SIZES[size],
        filled_variant_class(variant)
      )
      existing_class = options[:class] || options['class']
      options[:class] = combine_classes(icon_classes, existing_class)
    end

    def append_icon_name_class(options, icon_name)
      return if icon_name.blank?

      existing_class = options[:class] || options['class']
      options[:class] = combine_classes(existing_class, "#{icon_name}-icon")
    end

    def clean_html(html)
      return html unless html.is_a?(String) || html.is_a?(ActiveSupport::SafeBuffer)

      raw_html = html.to_s
      clean_with_nokogiri(raw_html) || clean_with_regex(raw_html)
    end

    private

    def combine_classes(*classes)
      classes.compact_blank.join(' ').strip
    end

    def filled_variant_class(variant)
      variant&.to_s == 'fill' ? 'fill-current' : nil
    end

    def clean_with_nokogiri(raw_html)
      fragment = Nokogiri::HTML::DocumentFragment.parse(raw_html)
      fragment.css('svg').each do |svg|
        svg.remove_attribute('data') if svg.attribute('data')
      end
      ActiveSupport::SafeBuffer.new(fragment.to_html)
    rescue StandardError
      nil
    end

    def clean_with_regex(raw_html)
      cleaned = raw_html.gsub(/(<svg\b[^>]*?)\sdata=""/i) { Regexp.last_match(1) }
                        .gsub(/(<svg\b[^>]*?)\sdata(?=\s|>)/i) { Regexp.last_match(1) }
                        .gsub(/(<svg\b[^>]*?)\sdata="[^"]*"/i) { Regexp.last_match(1) }
      ActiveSupport::SafeBuffer.new(cleaned)
    end
  end
end
