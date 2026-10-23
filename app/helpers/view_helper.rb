# frozen_string_literal: true

# ViewHelper for user interface components
module ViewHelper
  def combobox_datepicker(*, **, &)
    render(ComboboxDatepickerComponent.new(*, **), &)
  end

  def viral_icon_source(name)
    path = if Rails.configuration.auth_config[name]
             Rails.root.join(
               'config', 'authentication', 'icons', Rails.configuration.auth_config[name]
             ) # Auth Icon Overrides
           else
             Rails.root.join('app', 'assets', 'icons', 'heroicons', "#{name}.svg")
           end
    file = File.read(path)
    doc = Nokogiri::HTML::DocumentFragment.parse(file)
    svg = doc.at_css 'svg'
    svg[:class] = "viral-icon__Svg icon-#{name}"
    svg[:focusable] = false
    svg[:'aria-hidden'] = true
    doc.to_html.html_safe # rubocop:disable Rails/OutputSafety
  end
end
