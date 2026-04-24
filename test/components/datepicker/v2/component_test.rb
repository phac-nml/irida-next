# frozen_string_literal: true

require 'test_helper'

module Datepicker
  module V2
    class ComponentTest < ViewComponent::TestCase
      test 'basic datepicker' do
        datepicker = Datepicker::V2::Component.new(id: 'test_id', input_name: 'test_input_name')

        render_inline(datepicker)
        assert_selector 'div#test_id-datepicker.relative'
        assert_no_selector 'label'
        assert_selector 'input[type="text"]', count: 1
        assert_selector 'svg.calendar-dots-icon', count: 1
        assert_match(/id="test_id-calendar"/, rendered_content)
        assert_selector('template[data-datepicker--v2--input-target="calendarTemplate"]', visible: :all)
        assert_match(/data-controller="datepicker--v2--input"/, rendered_content)
        assert_match(/data-controller="datepicker--v2--calendar"/, rendered_content)
      end

      test 'datepicker with label' do
        datepicker = Datepicker::V2::Component.new(
          id: 'test_id',
          input_name: 'test_input_name',
          label: 'this is a label'
        )
        render_inline(datepicker)
        assert_selector 'label', text: 'this is a label'
        assert_selector 'input[type="text"]', count: 1
        assert_selector 'svg.calendar-dots-icon', count: 1
      end

      test 'datepicker with required' do
        datepicker = Datepicker::V2::Component.new(
          id: 'test_id',
          input_name: 'test_input_name',
          label: 'this is a label',
          required: true
        )
        render_inline(datepicker)
        assert_selector 'abbr', text: '*'
      end
    end
  end
end
