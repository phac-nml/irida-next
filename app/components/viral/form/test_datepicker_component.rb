# frozen_string_literal: true

module Viral
  module Form
    # Form text input component (numbers, email, text, etc.)
    class TestDatepickerComponent < Viral::Component
      attr_reader :input_id, :input_name, :id, :min_date, :selected_date, :months, :min_year, :autosubmit

      def initialize(input_id: nil, input_name: '', id: 'datepicker', min_date: nil, selected_date: nil,
                     autosubmit: false)
        @input_id = input_id
        @input_name = input_name
        @id = id
        @min_date = min_date
        @selected_date = selected_date
        @autosubmit = autosubmit
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
                   I18n.t('viral.form.test_datepicker_component.months.december')].to_json

        @min_year = min_date.nil? ? '1' : min_date.to_s.split('-')[0]
      end
    end
  end
end
