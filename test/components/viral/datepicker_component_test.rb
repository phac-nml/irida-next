# frozen_string_literal: true

require 'test_helper'

module Viral
  class DatepickerComponentTest < ViewComponent::TestCase
    test 'basic datepicker' do
      datepicker = Viral::DatepickerComponent.new(id: 'test_id', input_name: 'test_input_name')

      render_inline(datepicker)
      assert_selector 'div#test_id-datepicker.relative'
      assert_no_selector 'label'
      assert_selector 'input[type="text"]', count: 1
      assert_selector 'svg.calendar-dots-icon', count: 1
      assert_match(/id="test_id-calendar"/, rendered_content)
      assert_match(/class="[^"]*\bhidden\b[^"]*"/, rendered_content)
      assert_match(/data-controller="viral--datepicker--input"/, rendered_content)
      assert_match(/data-controller="viral--datepicker--calendar"/, rendered_content)
    end

    test 'datepicker with label' do
      datepicker = Viral::DatepickerComponent.new(
        id: 'test_id',
        input_name: 'test_input_name',
        label: 'this is a label'
      )
      render_inline(datepicker)
      assert_selector 'label', text: 'this is a label'
      assert_selector 'input[type="text"]', count: 1
      assert_selector 'svg.calendar-dots-icon', count: 1
    end
  end
end
