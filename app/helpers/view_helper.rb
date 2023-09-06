# frozen_string_literal: true

# ViewHelper for user interface components
module ViewHelper
  VIRAL_HELPERS = {
    alert: 'Viral::AlertComponent',
    avatar: 'Viral::AvatarComponent',
    breadcrumb: 'Viral::BreadcrumbComponent',
    button: 'Viral::ButtonComponent',
    card: 'Viral::CardComponent',
    dialog: 'Viral::DialogComponent',
    dropdown: 'Viral::DropdownComponent',
    flash: 'Viral::FlashComponent',
    icon: 'Viral::IconComponent',
    pageheader: 'Viral::PageHeaderComponent',
    tooltip: 'Viral::TooltipComponent',
    help_text: 'Viral::Form::HelpTextComponent'
  }.freeze

  VIRAL_HELPERS.each do |name, component|
    define_method "viral_#{name}" do |*args, **kwargs, &block|
      render component.constantize.new(*args, **kwargs), &block
    end
  end

  def viral_icon_source(name)
    path = Rails.root.join('app', 'assets', 'icons', 'heroicons', "#{name}.svg")
    file = File.read(path)
    doc = Nokogiri::HTML::DocumentFragment.parse(file)
    svg = doc.at_css 'svg'
    svg[:class] = "Viral-Icon__Svg icon-#{name}"
    svg[:focusable] = false
    svg[:'aria-hidden'] = true
    doc.to_html.html_safe # rubocop:disable Rails/OutputSafety
  end
end
