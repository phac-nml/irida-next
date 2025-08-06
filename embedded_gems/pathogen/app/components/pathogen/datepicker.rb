# frozen_string_literal: true

module Pathogen
  # Datepicker Component
  # Renders the date input along with datepicker calendar
  class Datepicker < Pathogen::Component
    include LocalDatetimeHelper
    # Default HTML tag for components main elements.
    TAG_DEFAULT = :div

    # Default CSS classes for the root <div> element.
    SYSTEM_DEFAULT_CLASSES = 'relative'

    # Default CSS classes for the <div> element containing the datepicker.
    CALENDAR_DEFAULT_CLASSES = 'hidden absolute top-0 left-0 z-100 pt-2 active block select-none'

    # Initializes a new Datepicker component.
    # @param id [String] A unique identifier that is manipulated to use on multiple component items. This is required.
    # @param input_name [String] The name attribute for the date input. This is required.
    # @param label [String] A label for the input (optional).
    # @param input_aria_label [String] Aria label for the input. Necessary for accessibility if no label is passed.
    # @param min_date [String] A minimum date the user can input.
    # @param selected_date [String] The already selected date if it exists.
    # @param autosubmit [Boolean] Submits the date upon selection if true
    # @param calendar_arguments [Hash] HTML attributes for the datepicker
    # @param system_arguments [Hash] HTML attributes for the main container (<div>).
    # @raise [ArgumentError] if id is not provided.
    # @raise [ArgumentError] if input_name is not provided.

    # rubocop:disable Metrics/ParameterLists
    def initialize(id:, input_name:, label: nil, input_aria_label: nil, min_date: nil, selected_date: nil,
                   autosubmit: false, calendar_arguments: {}, **system_arguments)
      raise ArgumentError, 'id is required' if id.blank?
      raise ArgumentError, 'input_name is required' if input_name.blank?

      @label = label
      @input_name = input_name
      @input_aria_label = input_aria_label
      @selected_date = selected_date
      @autosubmit = autosubmit
      @min_date = min_date
      @system_arguments = system_arguments
      @calendar_arguments = calendar_arguments

      @months = load_months
      @days_of_the_week = load_days_of_week
      # rubocop:enable Metrics/ParameterLists

      setup_ids(id)
      setup_calendar_attributes
    end

    # min_date default must be performed in before_render since it requires a helper gem which can't be called within
    # initialize, container attributes are then setup as it requires min_date
    def before_render
      @min_date = datepicker_expiry_default_min_date if @min_date.nil?
      @min_year = calculate_min_year
      setup_container_attributes
    end

    private

    def load_months
      [I18n.t('pathogen.datepicker.months.january'),
       I18n.t('pathogen.datepicker.months.february'),
       I18n.t('pathogen.datepicker.months.march'),
       I18n.t('pathogen.datepicker.months.april'),
       I18n.t('pathogen.datepicker.months.may'),
       I18n.t('pathogen.datepicker.months.june'),
       I18n.t('pathogen.datepicker.months.july'),
       I18n.t('pathogen.datepicker.months.august'),
       I18n.t('pathogen.datepicker.months.september'),
       I18n.t('pathogen.datepicker.months.october'),
       I18n.t('pathogen.datepicker.months.november'),
       I18n.t('pathogen.datepicker.months.december')]
    end

    def load_days_of_week
      [I18n.t('pathogen.datepicker.days_of_week.sunday'),
       I18n.t('pathogen.datepicker.days_of_week.monday'),
       I18n.t('pathogen.datepicker.days_of_week.tuesday'),
       I18n.t('pathogen.datepicker.days_of_week.wednesday'),
       I18n.t('pathogen.datepicker.days_of_week.thursday'),
       I18n.t('pathogen.datepicker.days_of_week.friday'),
       I18n.t('pathogen.datepicker.days_of_week.saturday')]
    end

    def calculate_min_year
      @min_date.nil? ? '1' : @min_date.to_s.split('-')[0]
    end

    def setup_ids(id)
      @container_id = "#{id}-datepicker"
      @input_id = "#{id}-input"
      @calendar_id = "#{id}-calendar"
    end

    # Configures HTML attributes for the main <div> container.
    def setup_container_attributes # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
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
      @system_arguments[:data]['pathogen--datepicker--input-invalid-date-value'] =
        I18n.t('pathogen.datepicker.errors.invalid_date')
      @system_arguments[:data]['pathogen--datepicker--input-invalid-min-date-value'] =
        I18n.t('pathogen.datepicker.errors.min_date_error', min_date: @min_date)
      @system_arguments[:data]['pathogen--datepicker--input-calendar-id-value'] = @calendar_id
      @system_arguments[:data]['pathogen--datepicker--input-date-format-regex-value'] =
        I18n.t('pathogen.datepicker.date_format_regex')
    end

    # Configures HTML attributes for the <div> datepicker calendar.
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
  end
end
