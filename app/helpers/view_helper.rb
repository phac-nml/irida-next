# frozen_string_literal: true

# ViewHelper for user interface components
module ViewHelper
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
end
