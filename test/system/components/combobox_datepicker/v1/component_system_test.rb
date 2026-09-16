# frozen_string_literal: true

require 'application_system_test_case'

module ComboboxDatepicker
  module V1
    class ComponentSystemTest < ApplicationSystemTestCase
      def test_basic_functionality
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('#test_id-input').click
            assert_selector '#test_id-calendar'

            # Click May 29, 2026
            find('table tbody tr:nth-child(5) td:nth-child(6)').click
            assert_no_selector '#test_id-calendar'

            assert_field 'test_input_name', with: '2026-05-29'
          end
        end
      end
    end
  end
end
