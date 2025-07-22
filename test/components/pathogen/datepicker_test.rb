# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class DatepickerTest < ViewComponent::TestCase
    test 'basic datepicker' do
      datepicker = Pathogen::Datepicker.new(id: 'test_id', input_name: 'test_input_name')

      render_inline(datepicker)
      assert_no_selector 'label'
      assert_selector 'input[type="text"]', count: 1
      assert_selector 'svg.calendar-dots-icon', count: 1
    end

    test 'datepicker with label' do
      datepicker = Pathogen::Datepicker.new(id: 'test_id', input_name: 'test_input_name', label: 'this is a label')
      render_inline(datepicker)
      assert_selector 'label', text: 'this is a label'
      assert_selector 'input[type="text"]', count: 1
      assert_selector 'svg.calendar-dots-icon', count: 1
    end
  end
end
