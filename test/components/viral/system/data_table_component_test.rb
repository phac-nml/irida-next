# frozen_string_literal: true

require 'application_system_test_case'

module System
  class DataTableComponentTest < ApplicationSystemTestCase
    test 'default' do
      freeze_time
      visit('rails/view_components/viral_data_table_component/default')
      assert_selector 'div#preview_table'

      within('thead') do
        assert_selector 'tr:first-child th:first-child', text: 'ID'
        assert_selector 'tr:first-child th:nth-child(2)', text: 'NAME'
        assert_selector 'tr:first-child th:nth-child(3)', text: 'PILL WITH CONDITIONAL'
        assert_selector 'tr:first-child th:nth-child(4)', text: 'DATE'
        assert_selector 'tr:first-child th:nth-child(5)', text: 'TIME AGO'
        assert_selector 'tr:first-child th:nth-child(6)',
                        text: I18n.t('viral.data_table_component.header.action').upcase
      end

      within('tbody') do
        assert_selector 'tr', count: 2
        assert_selector 'tr:first-child th:first-child', text: '1'
        assert_selector 'tr:first-child td:nth-child(2)', text: 'data one'
        assert_selector 'tr:first-child td:nth-child(3)', text: 'this pill is green'
        assert_selector 'tr:first-child td:nth-child(4)',
                        text: I18n.l(DateTime.new(2024, 1, 1).localtime, format: :full_date)
        assert_selector 'tr:first-child td:nth-child(5)', text: 'a minute ago'
        assert_selector 'tr:first-child td:nth-child(6)', text: 'data one Action1 data one Action2'

        assert_selector 'tr:nth-child(2) th:first-child', text: '2'
        assert_selector 'tr:nth-child(2) td:nth-child(2)', text: 'data two'
        assert_selector 'tr:nth-child(2) td:nth-child(3)', text: 'this pill is blue'
        assert_selector 'tr:nth-child(2) td:nth-child(4)',
                        text: I18n.l(DateTime.new(2022, 7, 15).localtime, format: :full_date)
        assert_selector 'tr:nth-child(2) td:nth-child(5)', text: 'an hour ago'
        assert_selector 'tr:nth-child(2) td:nth-child(6)', text: 'data two Action1 data two Action2'

        within('tr:first-child td:nth-child(3)') do
          assert_selector '.bg-green-100.text-green-800.text-xs.font-medium.rounded-full'
        end

        within('tr:nth-child(2) td:nth-child(3)') do
          assert_selector '.bg-blue-100.text-blue-800.text-xs.font-medium.rounded-full'
        end
      end
    end

    test 'overflow_x' do
      visit('rails/view_components/viral_data_table_component/overflow_x')
      assert_selector 'div#preview_table'

      assert_selector 'tbody tr:first-child td:nth-child(2)',
                      text: 'data one with a very very very very very ' \
                            'very very very very very very very very very very very very very long name'

      within('thead') do
        assert_selector 'th[class="bg-slate-50 dark:bg-slate-700 px-3 py-3 right-0 sticky z-10"]',
                        text: I18n.t('viral.data_table_component.header.action').upcase
      end

      within('tbody') do
        assert_selector 'td[class="bg-white dark:bg-slate-800 px-3 py-3 right-0 space-x-2 sticky z-10"]',
                        count: 2
      end
    end
  end
end
