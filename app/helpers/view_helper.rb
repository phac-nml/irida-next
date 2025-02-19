# frozen_string_literal: true

# ViewHelper for user interface components
module ViewHelper
  VIRAL_HELPERS = {
    alert: 'Viral::AlertComponent',
    avatar: 'Viral::AvatarComponent',
    breadcrumb: 'Viral::BreadcrumbComponent',
    button: 'Viral::ButtonComponent',
    card: 'Viral::CardComponent',
    checkbox: 'Viral::Form::CheckboxComponent',
    datepicker: 'Viral::Form::DatepickerComponent',
    dialog: 'Viral::DialogComponent',
    empty: 'Viral::EmptyStateComponent',
    data_table: 'Viral::DataTableComponent',
    dropdown: 'Viral::DropdownComponent',
    file_input: 'Viral::Form::FileInputComponent',
    flash: 'Viral::FlashComponent',
    help_text: 'Viral::Form::HelpTextComponent',
    icon: 'Viral::IconComponent',
    pageheader: 'Viral::PageHeaderComponent',
    prefixed_boolean: 'Viral::Form::Prefixed::BooleanComponent',
    prefixed_select: 'Viral::Form::Prefixed::SelectComponent',
    prefixed_select2: 'Viral::Form::Prefixed::Select2Component',
    prefixed_text_input: 'Viral::Form::Prefixed::TextInputComponent',
    pill: 'Viral::PillComponent',
    progress_bar: 'Viral::ProgressBarComponent',
    select2: 'Viral::Select2Component',
    select2option: 'Viral::Select2OptionComponent',
    select: 'Viral::Form::SelectComponent',
    sortable_lists: 'Viral::SortableListsComponent',
    tabs: 'Viral::TabsComponent',
    text_input: 'Viral::Form::TextInputComponent',
    tooltip: 'Viral::TooltipComponent'
  }.freeze

  VIRAL_HELPERS.each do |name, component|
    define_method "viral_#{name}" do |*args, **kwargs, &block|
      render component.constantize.new(*args, **kwargs), &block
    end
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
    svg[:class] = "Viral-Icon__Svg icon-#{name}"
    svg[:focusable] = false
    svg[:'aria-hidden'] = true
    doc.to_html.html_safe # rubocop:disable Rails/OutputSafety
  end
end
