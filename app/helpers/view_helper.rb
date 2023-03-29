# frozen_string_literal: true

# ViewHelper for user interface components
module ViewHelper
  # Append classes to the class list ensure only unique classes are present
  def class_names(*args)
    classes = []
    args.each do |class_name|
      classes << class_name if class_name.is_a?(String) && class_name.present?
      classes += class_names(*class_name) if class_name.is_a?(Array)
      classes += class_names_from_hash(class_name) if class_name.is_a?(Hash)
    end
    classes.compact.uniq.join(' ')
  end

  # Get the svg file for a heroicon by name, and add the applicable classes
  def heroicons_source(icon_name, classes)
    path = Rails.root.join('app', 'assets', 'icons', 'heroicons', "#{icon_name}.svg")
    file = File.read(path)
    doc = Nokogiri::HTML::DocumentFragment.parse(file)
    svg = doc.at_css 'svg'
    svg[:class] = classes
    svg[:focusable] = false
    svg[:'aria-hidden'] = true
    doc.to_html.html_safe # rubocop:disable Rails/OutputSafety
  end

  private

  def class_names_from_hash(hash)
    classes = []
    hash.each do |class_name, value|
      classes << class_name.to_s if value
    end
    classes
  end
end
