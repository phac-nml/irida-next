# frozen_string_literal: true

module Pathogen
  # 🎯 TabsPanel Component
  # Renders a navigation panel with tabs, typically used for section navigation within a page.
  # Utilizes Turbo Drive for seamless navigation between sections.
  class Datepicker < Pathogen::Component
    # 🔧 Default HTML tag for the component's root element.
    TAG_DEFAULT = :div

    # 💅 Default CSS classes for the root <nav> element.
    SYSTEM_DEFAULT_CLASSES = 'relative'
    # 🔧 Default HTML tag for the list element containing the tabs.
    # 💅 Default CSS classes for the <ul> element containing the tabs.
    CALENDAR_DEFAULT_CLASSES = 'hidden absolute top-0 left-0 z-10000 pt-2 active block'

    # 📝 Defines and renders individual navigation tabs.
    # Each tab is an instance of `Pathogen::TabsPanel::Tab`.
    # @param options [Hash] Configuration options for the tab.
    # @option options [Boolean] :selected (false) Whether the tab is currently selected.
    # @option options [String] :href The URL the tab links to.
    # @return [Pathogen::TabsPanel::Tab] A new tab instance.
    # renders_many :tabs, lambda { |options = {}|
    #   Pathogen::TabsPanel::Tab.new(
    #     options.merge(
    #       selected: options[:selected] || false,
    #       tab_type: 'underline', # Assumes Tab component handles its specific underline style
    #       href: options[:href]
    #     )
    #   )
    # }

    # 🎨 Renders optional content aligned to the right of the tabs.
    # renders_one :right_content

    # 🚀 Initializes a new TabsPanel component.
    # @param id [String] A unique identifier for the tabs panel. This is required.
    # @param label [String] An accessible label for the navigation (aria-label).
    # @param body_arguments [Hash] HTML attributes for the list container (<ul>).
    # @param system_arguments [Hash] HTML attributes for the main container (<nav>).
    # @raise [ArgumentError] if id is not provided.
    def initialize(id:, input_name:, label: nil, min_date: nil, selected_date: nil, autosubmit: false,
                   calendar_arguments: {}, **system_arguments)
      raise ArgumentError, 'id is required' if id.blank?
      raise ArgumentError, 'input_name is required' if input_name.blank?

      @label = label
      @input_name = input_name
      @min_date = min_date.to_s
      @selected_date = selected_date
      @autosubmit = autosubmit

      @system_arguments = system_arguments
      @calendar_arguments = calendar_arguments

      @months = [I18n.t('viral.form.test_datepicker_component.months.january'),
                 I18n.t('viral.form.test_datepicker_component.months.february'),
                 I18n.t('viral.form.test_datepicker_component.months.march'),
                 I18n.t('viral.form.test_datepicker_component.months.april'),
                 I18n.t('viral.form.test_datepicker_component.months.may'),
                 I18n.t('viral.form.test_datepicker_component.months.june'),
                 I18n.t('viral.form.test_datepicker_component.months.july'),
                 I18n.t('viral.form.test_datepicker_component.months.august'),
                 I18n.t('viral.form.test_datepicker_component.months.september'),
                 I18n.t('viral.form.test_datepicker_component.months.october'),
                 I18n.t('viral.form.test_datepicker_component.months.november'),
                 I18n.t('viral.form.test_datepicker_component.months.december')]

      @min_year = @min_date.nil? ? '1' : @min_date.to_s.split('-')[0]

      setup_ids(id)
      setup_container_attributes
      setup_calendar_attributes
    end

    private

    def setup_ids(id)
      @container_id = "#{id}-datepicker"
      @input_id = "#{id}-input"
      @calendar_id = "#{id}-calendar"
    end

    # 🏗️ Configures HTML attributes for the main <div> container.
    def setup_container_attributes
      @system_arguments[:id] = @container_id
      @system_arguments[:tag] = TAG_DEFAULT

      @system_arguments[:class] = class_names(
        SYSTEM_DEFAULT_CLASSES,
        @system_arguments[:class]
      )
      @system_arguments[:data] ||= {}
      @system_arguments[:data][:controller] = 'pathogen--datepicker--input'
      @system_arguments[:data]['pathogen--datepicker--input-pathogen--datepicker--calendar-outlet'] = "##{@calendar_id}"
      @system_arguments[:data]['pathogen--datepicker--input-min-date-value'] = @min_date
      @system_arguments[:data]['pathogen--datepicker--input-autosubmit-value'] = @autosubmit
      @system_arguments[:data]['pathogen--datepicker--input-invalid-date-format-value'] =
        I18n.t('pathogen.datepicker.errors.invalid_date_format')
      @system_arguments[:data]['pathogen--datepicker--input-invalid-min-date-value'] =
        I18n.t('pathogen.datepicker.errors.min_date_error', min_date: @min_date)
    end

    def setup_calendar_attributes
      @calendar_arguments[:id] = @calendar_id
      @calendar_arguments[:tag] = TAG_DEFAULT
      @calendar_arguments[:class] = class_names(
        CALENDAR_DEFAULT_CLASSES,
        @calendar_arguments[:class]
      )

      @calendar_arguments[:data] ||= {}
      @calendar_arguments[:data][:controller] = 'pathogen--datepicker--calendar'
      @calendar_arguments[:data]['pathogen--datepicker--calendar-pathogen--datepicker--input-outlet'] =
        "##{@container_id}"
      @calendar_arguments[:data]['pathogen--datepicker--calendar-months-value'] = @months
    end

    # # 🏗️ Configures HTML attributes for the <ul> list container.
    # def setup_list_attributes
    #   @body_arguments[:tag] = @body_arguments[:tag] || BODY_TAG_DEFAULT

    #   # Apply default classes unless custom classes are provided.
    #   custom_classes_provided = @body_arguments[:classes].present?
    #   @body_arguments[:classes] = custom_classes_provided ? @body_arguments[:classes] : BODY_DEFAULT_CLASSES

    #   @body_arguments[:id] = "#{@system_arguments[:id]}-list"
    #   # Merge data attributes, preserving existing ones.
    #   @body_arguments[:data] = {
    #     # Ensure this still works as expected, @system_arguments[:id] is now directly set
    #     tabs_list_id_value: @system_arguments[:id]
    #   }.merge(@body_arguments[:data] || {})
    # end
  end
end
