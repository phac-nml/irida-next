# frozen_string_literal: true

module ComboboxDatepicker
  module V1
    # Datepicker Component
    # Renders the date input along with datepicker calendar
    class Component < ::Component
      # Default HTML tag for components main elements.
      TAG_DEFAULT = :div

      # Default CSS classes for the root <div> element.
      SYSTEM_DEFAULT_CLASSES = 'relative'

      # Default CSS classes for the <div> element containing the datepicker.
      CALENDAR_DEFAULT_CLASSES = 'z-100 active select-none'

      # Initializes a new Datepicker component.
      # @param id [String] A unique identifier that is manipulated to use on multiple component items. This is required.
      # @param input_name [String] The name attribute for the date input. This is required.
      # @param label [String] A label for the input (optional).
      # @param input_aria_label [String] Aria label for the input. Necessary for accessibility if no label is passed.
      # @param min_date [String] A minimum date the user can input.
      # @param selected_date [String] The already selected date if it exists.
      # @param autosubmit [Boolean] Submits the date upon selection if true
      # @param required [Boolean] Sets aria-required="true" on input_field_component if true
      # @param errored [Boolean] Initializes the datepicker in an error state if true (determined by backend validation)
      # @param calendar_arguments [Hash] HTML attributes for the datepicker
      # @param system_arguments [Hash] HTML attributes for the main container (<div>).
      # @raise [ArgumentError] if id is not provided.
      # @raise [ArgumentError] if input_name is not provided.

      # rubocop:disable Metrics/ParameterLists
      def initialize(id:, input_name:, label: nil, input_aria_label: nil, min_date: 1.day.from_now, # rubocop:disable Metrics/MethodLength
                     selected_date: nil, autosubmit: false, required: false, errored: false,
                     calendar_arguments: {},  **system_arguments)
        raise ArgumentError, 'id is required' if id.blank?
        raise ArgumentError, 'input_name is required' if input_name.blank?

        @label = label
        @input_name = input_name
        @input_aria_label = input_aria_label
        @selected_date = selected_date
        @autosubmit = autosubmit
        @required = required
        @errored = errored
        @min_date = min_date
        @system_arguments = system_arguments
        @calendar_arguments = calendar_arguments
        @months = load_months
        @days_of_the_week = load_days_of_week
        # rubocop:enable Metrics/ParameterLists

        setup_ids(id)
        setup_container_attributes
        setup_calendar_attributes
      end

      private

      def load_months
        [I18n.t('components.datepicker.months.january'),
         I18n.t('components.datepicker.months.february'),
         I18n.t('components.datepicker.months.march'),
         I18n.t('components.datepicker.months.april'),
         I18n.t('components.datepicker.months.may'),
         I18n.t('components.datepicker.months.june'),
         I18n.t('components.datepicker.months.july'),
         I18n.t('components.datepicker.months.august'),
         I18n.t('components.datepicker.months.september'),
         I18n.t('components.datepicker.months.october'),
         I18n.t('components.datepicker.months.november'),
         I18n.t('components.datepicker.months.december')]
      end

      def load_days_of_week
        [I18n.t('components.datepicker.days_of_week.sunday'),
         I18n.t('components.datepicker.days_of_week.monday'),
         I18n.t('components.datepicker.days_of_week.tuesday'),
         I18n.t('components.datepicker.days_of_week.wednesday'),
         I18n.t('components.datepicker.days_of_week.thursday'),
         I18n.t('components.datepicker.days_of_week.friday'),
         I18n.t('components.datepicker.days_of_week.saturday')]
      end

      def setup_ids(id)
        @container_id = "#{id}-datepicker"
        @input_id = "#{id}-input"
        @calendar_id = "#{id}-calendar"
        @error_id = "#{id}_error"
      end

      # Configures HTML attributes for the main <div> container.
      def setup_container_attributes # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        @system_arguments[:id] = @container_id
        @system_arguments[:tag] = TAG_DEFAULT

        @system_arguments[:classes] = class_names(
          SYSTEM_DEFAULT_CLASSES,
          @system_arguments.delete(:class),
          @system_arguments.delete(:classes)
        )

        @system_arguments[:data] ||= {}
        @system_arguments[:data][:controller] = 'combobox-datepicker--v1--input'
        @system_arguments[:data]['combobox-datepicker--v1--input-combobox-datepicker--v1--calendar-outlet'] =
          "##{@calendar_id}"
        @system_arguments[:data]['combobox-datepicker--v1--input-autosubmit-value'] = @autosubmit
        @system_arguments[:data]['combobox-datepicker--v1--input-invalid-date-value'] =
          I18n.t('components.datepicker.errors.invalid_date')
        @system_arguments[:data]['combobox-datepicker--v1--input-invalid-min-date-value'] =
          I18n.t('components.datepicker.errors.min_date_error')
        @system_arguments[:data]['combobox-datepicker--v1--input-calendar-id-value'] = @calendar_id
        @system_arguments[:data]['combobox-datepicker--v1--input-date-format-regex-value'] =
          I18n.t('components.datepicker.date_format_regex')
        return unless @autosubmit

        # require the error container DOM ID to point aria-describedby when autosubmit is true for front-end
        # validation
        @system_arguments[:data]['combobox-datepicker--v1--input-error-message-id-value'] = @error_id
      end

      # Configures HTML attributes for the <div> datepicker calendar.
      def setup_calendar_attributes # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        @calendar_arguments[:id] = @calendar_id
        @calendar_arguments[:tag] = TAG_DEFAULT
        @calendar_arguments[:hidden] = true
        @calendar_arguments[:classes] = class_names(
          CALENDAR_DEFAULT_CLASSES,
          @calendar_arguments.delete(:class),
          @calendar_arguments.delete(:classes)
        )

        @calendar_arguments[:role] = 'dialog'
        @calendar_arguments[:aria] =
          { modal: 'true', label: I18n.t('components.datepicker.aria_label.dialog') }

        @calendar_arguments[:data] ||= {}
        @calendar_arguments[:data][:controller] = 'combobox-datepicker--v1--calendar'
        @calendar_arguments[:data]['combobox-datepicker--v1--calendar-combobox-datepicker--v1--input-outlet'] =
          "##{@container_id}"
        @calendar_arguments[:data]['combobox-datepicker--v1--calendar-months-value'] = @months
        @calendar_arguments[:data]['combobox-datepicker--v1--calendar-locale-value'] = I18n.locale
      end
    end
  end
end
