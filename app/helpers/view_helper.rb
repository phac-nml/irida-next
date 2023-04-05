# frozen_string_literal: true

# ViewHelper for user interface components
module ViewHelper
  VIRAL_HELPERS = {
    icon: 'Viral::IconComponent'
  }.freeze

  VIRAL_HELPERS.each do |name, component|
    define_method "viral_#{name}" do |*args, **kwargs, &block|
      render component.constantize.new(*args, **kwargs), &block
    end
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

  def viral_icon_source(name)
    path = Rails.root.join('app', 'assets', 'icons', 'heroicons', "#{name}.svg")
    file = File.read(path)
    doc = Nokogiri::HTML::DocumentFragment.parse(file)
    svg = doc.at_css 'svg'
    svg[:class] = 'Viral-Icon__Svg'
    svg[:focusable] = false
    svg[:'aria-hidden'] = true
    doc.to_html.html_safe
  end
end
