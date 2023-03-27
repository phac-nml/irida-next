# frozen_string_literal: true

module ViewHelper
  def heroicons_source(icon_name)
    path = Rails.root.join('app', 'assets', 'icons', 'heroicons', "#{icon_name}.svg")
    file = File.read(path)
    doc = Nokogiri::HTML::DocumentFragment.parse(file)
    svg = doc.at_css 'svg'
    svg[:class] = 'w-5 h-5'
    svg[:focusable] = false
    svg[:'aria-hidden'] = true
    doc.to_html.html_safe # rubocop:disable Rails/OutputSafety
  end
end
