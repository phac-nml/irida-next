# frozen_string_literal: true

require 'application_system_test_case'

module ComboboxDatepicker
  module V1
    class ComponentTest < ApplicationSystemTestCase
      # Datepicker testing requires both Timecop (sets date on backend) and
      # .with_playwright_page (sets date on frontend)

      def test_default_datepicker_rendering # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # verify May is selected and only 8 months exist (Jan-Apr options are not appended due to minDate)
            assert_selector 'select[name="month-select"] option', count: 8
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'

            assert_selector 'div[data-combobox-datepicker--v1--calendar-target="minDateMessage"]',
                            text: "#{I18n.t('components.datepicker.errors.min_date_error')}2026-05-08"

            # all grid rows and cells are 'filled out'
            assert_selector 'table tbody tr', count: 6
            assert_selector 'table tbody tr td', count: 42
            # Apr 26-30 are filled out and disabled in first week
            (26..30).each do |i|
              assert_selector 'table tbody tr:first-child td[aria-disabled="true"][data-date-within-month-position="outOfMonth"]', # rubocop:disable Layout/LineLength
                              text: i.to_s
            end
            # May 1-2 are disabled first week
            (1..2).each do |i|
              assert_selector 'table tbody tr:first-child td[aria-disabled="true"][data-date-within-month-position="inMonth"]', # rubocop:disable Layout/LineLength
                              text: i.to_s
            end
            # May 3-7 are disabled in second week
            (3..7).each do |i|
              assert_selector 'table tbody tr:nth-child(2) td[aria-disabled="true"][data-date-within-month-position="inMonth"]', # rubocop:disable Layout/LineLength
                              text: i.to_s
            end
            # 8-9 to 30th are selectable dates and are 'inMonth'
            (8..9).each do |i|
              assert_selector 'table tbody tr:nth-child(2) table tbody tr td[data-date-within-month-position="inMonth"]', # rubocop:disable Layout/LineLength
                              text: i.to_s
            end

            (10..16).each do |i|
              assert_selector 'table tbody tr:nth-child(3) table tbody tr td[data-date-within-month-position="inMonth"]', # rubocop:disable Layout/LineLength
                              text: i.to_s
            end
            (17..23).each do |i|
              assert_selector 'table tbody tr:nth-child(4) table tbody tr td[data-date-within-month-position="inMonth"]', # rubocop:disable Layout/LineLength
                              text: i.to_s
            end

            (24..30).each do |i|
              assert_selector 'table tbody tr:nth-child(5) table tbody tr td[data-date-within-month-position="inMonth"]', # rubocop:disable Layout/LineLength
                              text: i.to_s
            end

            assert_selector 'table tbody tr:last-child table tbody tr td[data-date-within-month-position="inMonth"]',
                            text: '31'

            # June 1-6 fill out last week, and are 'outOfMonth'
            (1..6).each do |i|
              assert_selector 'table tbody tr:last-child table tbody tr td[data-date-within-month-position="outOfMonth"]', # rubocop:disable Layout/LineLength
                              text: i.to_s
            end

            # May 8th is focused upon opening
            assert_selector 'td', text: '8', focused: true
          end
        end
      end

      def test_open_datepicker_by_clicking_input
        test_date = DateTime.new(2026, 5, 6, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # by clicking input, focus does not transfer into datepicker and stays on input
            find('#test_id-input').click

            assert_no_selector 'table tbody tr td[data-date="2026-05-08"]', focused: true
            assert_selector 'input#test_id-input', focused: true
          end
        end
      end

      def test_space_and_enter_on_datepicker # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # May 8th is focused upon opening
            assert_selector 'td', text: '8', focused: true

            # space to select 2026-05-08
            find('#test_id-calendar').send_keys(:space)

            # verify calendar still open and 2026-05-08 selected
            assert_selector '#test_id-calendar'
            assert_selector 'td.bg-primary-700[data-date="2026-05-08"][aria-selected="true"]'
            assert_field 'test_input_name', with: '2026-05-08'

            # go to 2026-05-09 and select via enter
            find('#test_id-calendar').send_keys(:right, :enter)

            # calendar closes
            assert_no_selector '#test_id-calendar'
            # reopen calendar and verify 8th is no longer selected and 9th is selected
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click
            assert_no_selector 'td.bg-primary-700[data-date="2026-05-08"][aria-selected="true"]'
            # May 8th is focused upon opening
            assert_selector 'td', text: '9', focused: true
            assert_selector 'td.bg-primary-700[data-date="2026-05-09"][aria-selected="true"]'
            assert_field 'test_input_name', with: '2026-05-09'
          end
        end
      end

      def test_home_and_end_with_min_date # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # May 8th is focused upon opening
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true

            # Focus May 9th (Sat)
            find('#test_id-calendar').send_keys(:end)
            assert_selector 'table tbody tr td[data-date="2026-05-09"]', text: '9', focused: true

            # Focus May 8th (Fri) as 7th and earlier is disabled
            find('#test_id-calendar').send_keys(:home)
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true

            # Go down to next week where full week is selectable/focusable
            find('#test_id-calendar').send_keys(:down)
            assert_selector 'table tbody tr td[data-date="2026-05-15"]', text: '15', focused: true

            # Focus May 16th (Sat)
            find('#test_id-calendar').send_keys(:end)
            assert_selector 'table tbody tr td[data-date="2026-05-16"]', text: '16', focused: true

            # Focus May 10th (Sun)
            find('#test_id-calendar').send_keys(:home)
            assert_selector 'table tbody tr td[data-date="2026-05-10"]', text: '10', focused: true
          end
        end
      end

      def test_home_and_end_with_max_date # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/with_min_date_and_max_date')

            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # May 8th is focused upon opening
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true

            # Navigate to May 6, 2027 (max date)
            find('#test_id-calendar').send_keys(%i[shift page_down])
            assert_selector 'table tbody tr td[data-date="2027-05-06"]', text: '6', focused: true

            # Focus May 2 (Sun)
            find('#test_id-calendar').send_keys(:home)
            assert_selector 'table tbody tr td[data-date="2027-05-02"]', text: '2', focused: true

            # Focus May 6 (Thu)
            find('#test_id-calendar').send_keys(:end)
            assert_selector 'table tbody tr td[data-date="2027-05-06"]', text: '6', focused: true
          end
        end
      end

      def test_arrow_keys_with_default_and_min_date # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # May 8th is focused upon opening
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true

            # Can't go up as 1st is disabled
            find('#test_id-calendar').send_keys(:up)
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true

            # Can't go left as 7th is disabled
            find('#test_id-calendar').send_keys(:left)
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true

            find('#test_id-calendar').send_keys(:right)
            assert_selector 'table tbody tr td[data-date="2026-05-09"]', text: '9', focused: true

            find('#test_id-calendar').send_keys(:down)
            assert_selector 'table tbody tr td[data-date="2026-05-16"]', text: '16', focused: true

            find('#test_id-calendar').send_keys(:left)
            assert_selector 'table tbody tr td[data-date="2026-05-15"]', text: '15', focused: true

            find('#test_id-calendar').send_keys(:up)
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true
          end
        end
      end

      def test_arrow_keys_with_max_date # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/with_min_date_and_max_date')

            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # May 8th is focused upon opening
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true

            # Navigate to max date
            find('#test_id-calendar').send_keys(%i[shift page_down])
            assert_selector 'table tbody tr td[data-date="2027-05-06"]', text: '6', focused: true

            # Can't go right as 7th is disabled
            find('#test_id-calendar').send_keys(:right)
            assert_selector 'table tbody tr td[data-date="2027-05-06"]', text: '6', focused: true

            # Can't go right as 13th is disabled
            find('#test_id-calendar').send_keys(:down)
            assert_selector 'table tbody tr td[data-date="2027-05-06"]', text: '6', focused: true
          end
        end
      end

      def test_page_up_and_down # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # May 8th is focused upon opening
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true

            # June 8th focused after page_down
            find('#test_id-calendar').send_keys(:page_down)
            assert_field 'month-select', with: I18n.t('components.datepicker.months.june')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-06-08"]', text: '8', focused: true

            # May 8th focused after page_up
            find('#test_id-calendar').send_keys(:page_up)
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true

            # navigate to May 31st
            find('#test_id-calendar').send_keys(:page_down, :up, :left)
            assert_selector 'table tbody tr td[data-date="2026-05-31"]', text: '31', focused: true

            # page_down into June changes focus to June 30th (rather than 31st which doesn't exist)
            find('#test_id-calendar').send_keys(:page_down)
            assert_field 'month-select', with: I18n.t('components.datepicker.months.june')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-06-30"]', text: '30', focused: true

            # navigate to July 31st
            find('#test_id-calendar').send_keys(:page_down, :right)
            assert_field 'month-select', with: I18n.t('components.datepicker.months.july')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-07-31"]', text: '31', focused: true

            # page_up focuses June 30th (rather than 31st again)
            find('#test_id-calendar').send_keys(:page_up)
            assert_field 'month-select', with: I18n.t('components.datepicker.months.june')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-06-30"]', text: '30', focused: true
          end
        end
      end

      def test_shift_page_up_and_down # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')
            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # May 8th, 2026 is focused upon opening
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true

            # May 8th, 2027 focused after shift+page_down
            find('#test_id-calendar').send_keys(%i[shift page_down])
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2027'
            assert_selector 'table tbody tr td[data-date="2027-05-08"]', text: '8', focused: true

            # May 9th, 2026 focused after navigating to May 9th, 2027 and shift+page_up
            find('#test_id-calendar').send_keys(:right, %i[shift page_up])
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-05-09"]', text: '9', focused: true

            # May 1th, 2027 focused after shift+page_down
            find('#test_id-calendar').send_keys(%i[shift page_down], :up)
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2027'
            assert_selector 'table tbody tr td[data-date="2027-05-02"]', text: '2', focused: true

            # May 8th, 2026 focused after navigating to May 2th, 2027 and shift+page_up, adjusted to min_date as
            # May 2nd, 2026 is disabled
            find('#test_id-calendar').send_keys(%i[shift page_up])
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true
          end
        end
      end

      def test_shift_page_up_and_down_on_feb_leap_year # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2027, 1, 28, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # Start on Jan 29, 2027 is focused upon opening
            assert_field 'month-select', with: I18n.t('components.datepicker.months.january')
            assert_field 'year-select', with: '2027'
            assert_selector 'table tbody tr td[data-date="2027-01-29"]', text: '29', focused: true

            # Navigate to Feb 29, 2028
            find('#test_id-calendar').send_keys(%i[shift page_down], :page_down)
            assert_field 'month-select', with: I18n.t('components.datepicker.months.february')
            assert_field 'year-select', with: '2028'
            assert_selector 'table tbody tr td[data-date="2028-02-29"]', text: '29', focused: true

            # shift+page_up to verify we land on Feb 28, 2027 (rather than non-existent Feb 29)
            find('#test_id-calendar').send_keys(%i[shift page_up])
            assert_field 'month-select', with: I18n.t('components.datepicker.months.february')
            assert_field 'year-select', with: '2027'
            assert_selector 'table tbody tr td[data-date="2027-02-28"]', text: '28', focused: true

            # Navigate back to Feb 29, 2028
            find('#test_id-calendar').send_keys(%i[shift page_down], :right)
            assert_field 'month-select', with: I18n.t('components.datepicker.months.february')
            assert_field 'year-select', with: '2028'
            assert_selector 'table tbody tr td[data-date="2028-02-29"]', text: '29', focused: true

            # shift+page_up to verify we land on Feb 28, 2029 (rather than non-existent Feb 29)
            find('#test_id-calendar').send_keys(%i[shift page_down])
            assert_field 'month-select', with: I18n.t('components.datepicker.months.february')
            assert_field 'year-select', with: '2029'
            assert_selector 'table tbody tr td[data-date="2029-02-28"]', text: '28', focused: true
          end
        end
      end

      def test_page_up_into_disabled_date # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # Start on May 8, 2026
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true

            # Navigate to June 1, 2026
            find('#test_id-calendar').send_keys(:page_down, :up)
            assert_field 'month-select', with: I18n.t('components.datepicker.months.june')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-06-01"]', text: '1', focused: true

            # page_up and end up back on May 8, 2026 as May 1, 2026 is disabled
            find('#test_id-calendar').send_keys(:page_up)
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true
          end
        end
      end

      def test_page_down_with_and_without_shift_into_disabled_date # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/with_min_date_and_max_date')

            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # Start on May 8, 2026
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true
            assert_no_selector 'button.next-btn[aria-disabled="true"]'

            # Navigate to May 6, 2027 (May 8 is disabled)
            find('#test_id-calendar').send_keys(%i[shift page_down])
            assert_selector 'table tbody tr td[data-date="2027-05-06"]', text: '6', focused: true
            assert_selector 'button.next-btn[aria-disabled="true"]'

            # Navigate back to April 13, 2027
            find('#test_id-calendar').send_keys(:page_up, :down)
            assert_selector 'table tbody tr td[data-date="2027-04-13"]', text: '13', focused: true
            assert_no_selector 'button.next-btn[aria-disabled="true"]'

            # page_down into disabled May 13th, focused forced to maxDate of May 6th
            find('#test_id-calendar').send_keys(:page_down)
            assert_selector 'table tbody tr td[data-date="2027-05-06"]', text: '6', focused: true
            assert_selector 'button.next-btn[aria-disabled="true"]'
          end
        end
      end

      def test_shift_page_up_into_disabled_date
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # Start on May 8, 2026
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true

            # Navigate to May 1, 2027
            find('#test_id-calendar').send_keys(%i[shift page_down], :up)
            assert_selector 'table tbody tr td[data-date="2027-05-01"]', text: '1', focused: true

            # shift+page_up and end up back on May 8, 2026 as May 1, 2026 is disabled
            find('#test_id-calendar').send_keys(%i[shift page_up])
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true
          end
        end
      end

      def test_open_and_closing_datepicker_with_down_and_escape # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            assert_no_selector '#test_id-calendar'
            assert_no_selector 'svg.caret-down-icon.rotate-180'
            assert_selector 'svg.caret-down-icon'

            # open by clicking arrow so date node is focused
            find('body').send_keys(:tab, :down)
            assert_selector '#test_id-calendar'
            assert_selector 'table tbody tr td[data-date="2026-05-08"]', text: '8', focused: true
            assert_selector 'svg.caret-down-icon.rotate-180'

            find('#test_id-calendar').send_keys(:escape)
            assert_no_selector '#test_id-calendar'
            assert_no_selector 'svg.caret-down-icon.rotate-180'
            assert_selector 'svg.caret-down-icon'
          end
        end
      end

      def test_clicking_selection
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('#test_id-input').click
            assert_selector '#test_id-calendar'

            find('table tbody tr td[data-date="2026-05-29"]').click
            assert_no_selector '#test_id-calendar'

            assert_field 'test_input_name', with: '2026-05-29'
          end
        end
      end

      def test_previous_month_button_disabling # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('#test_id-input').click
            assert_selector '#test_id-calendar'

            assert_selector 'button.prev-btn[aria-disabled="true"]'

            find('button.next-btn').click
            assert_field 'month-select', with: I18n.t('components.datepicker.months.june')
            assert_field 'year-select', with: '2026'
            assert_no_selector 'button.prev-btn[aria-disabled="true"]'
            assert_selector 'button.prev-btn[aria-disabled="false"]'

            find('button.prev-btn').click

            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'
            assert_no_selector 'button.prev-btn[aria-disabled="false"]'
            assert_selector 'button.prev-btn[aria-disabled="true"]'
          end
        end
      end

      def test_show_today # rubocop:disable Metrics/AbcSize
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('#test_id-input').click
            assert_selector '#test_id-calendar'

            find('button.next-btn').click
            assert_field 'month-select', with: I18n.t('components.datepicker.months.june')
            assert_field 'year-select', with: '2026'

            click_button I18n.t('components.datepicker.show_today')
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'
          end
        end
      end

      def test_clear_selection # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('#test_id-input').click
            assert_selector '#test_id-calendar'

            find('table tbody tr td[data-date="2026-05-29"]').click
            assert_no_selector '#test_id-calendar'

            assert_field 'test_input_name', with: '2026-05-29'

            find('#test_id-input').click
            click_button I18n.t('components.datepicker.clear_selection')
            assert_no_selector '#test_id-calendar'

            assert_field 'test_input_name', with: ''
          end
        end
      end

      def test_datepicker_with_already_selected_date
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/with_selected_date')

            assert_field 'test_input_name', with: '2026-05-14'
            # open by clicking arrow so date node is focused
            find('#test_id-input').click
            assert_selector '#test_id-calendar'

            assert_selector 'td.bg-primary-700[data-date="2026-05-14"][aria-selected="true"]'
          end
        end
      end

      def test_directly_entering_date # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # verify May is selected and only 8 months exist (Jan-Apr options are not appended due to minDate)
            assert_selector 'select[name="month-select"] option', count: 8
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'

            find('#test_id-input').fill_in with: '2026-07-07'

            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # verify May is selected and only 8 months exist (Jan-Apr options are not appended due to minDate)
            assert_selector 'td.bg-primary-700[data-date="2026-07-07"][aria-selected="true"]', focused: true
            assert_field 'month-select', with: I18n.t('components.datepicker.months.july')
            assert_field 'year-select', with: '2026'
          end
        end
      end

      def test_month_change # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # verify May is selected and only 8 months exist (Jan-Apr options are not appended due to minDate)
            assert_selector 'select[name="month-select"] option', count: 8
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'

            select I18n.t('components.datepicker.months.july'),
                   from: 'month-select'

            # verify calendar matches July 2026
            assert_selector 'table tbody tr', count: 5
            assert_selector 'table tbody tr td', count: 35
            (28..30).each do |i|
              assert_selector 'table tbody tr:first-child table tbody tr td[data-date-within-month-position="outOfMonth"]', # rubocop:disable Layout/LineLength
                              text: i.to_s
            end

            (1..4).each do |i|
              assert_selector 'table tbody tr:first-child table tbody tr td[data-date-within-month-position="inMonth"]',
                              text: i.to_s
            end
          end
        end
      end

      def test_year_change # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        test_date = DateTime.new(2026, 5, 7, 0, 0, 0, '-06:00')
        Timecop.travel(test_date) do
          Capybara.current_session.driver.with_playwright_page do |page|
            page.clock.set_fixed_time(test_date)
            visit('/rails/view_components/combobox_datepicker_component/default')

            # open by clicking arrow so date node is focused
            find('button[data-combobox-datepicker--v1--input-target="inputArrow"]').click

            # verify May is selected and only 8 months exist (Jan-Apr options are not appended due to minDate)
            assert_selector 'select[name="month-select"] option', count: 8
            assert_field 'month-select', with: I18n.t('components.datepicker.months.may')
            assert_field 'year-select', with: '2026'

            find('input[name="year-select"]').fill_in with: '2027'
            find('input[name="year-select"]').send_keys(:enter)
            # verify calendar matches May 20274
            assert_selector 'table tbody tr', count: 6
            assert_selector 'table tbody tr td', count: 42
            (25..30).each do |i|
              assert_selector 'table tbody tr:first-child table tbody tr td[data-date-within-month-position="outOfMonth"]', # rubocop:disable Layout/LineLength
                              text: i.to_s
            end

            assert_selector 'table tbody tr:first-child table tbody tr td[data-date-within-month-position="inMonth"]',
                            text: '1'
          end
        end
      end
    end
  end
end
