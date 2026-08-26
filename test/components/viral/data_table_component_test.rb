# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class DataTableComponentTest < ViewComponentTestCase
    test 'default' do
      travel_to Time.zone.local(2024, 6, 1, 12, 0, 0) do
        render_preview(:default)
        assert_selector 'div#preview_table'

        assert_selector 'thead'
        assert_selector 'thead tr:first-child th:first-child', text: 'id'
        assert_selector 'thead tr:first-child th:nth-child(2)', text: 'name'
        assert_selector 'thead tr:first-child th:nth-child(3)', text: 'pill with conditional'
        assert_selector 'thead tr:first-child th:nth-child(4)', text: 'date'
        assert_selector 'thead tr:first-child th:nth-child(5)', text: 'time ago'
        assert_selector 'thead tr:first-child th:nth-child(6)',
                        text: I18n.t('workflow_executions.table_component.actions')

        assert_selector 'tbody'
        assert_selector 'tbody tr', count: 2
        assert_selector 'tbody tr:first-child th:first-child', text: '1'
        assert_selector 'tbody tr:first-child td:nth-child(2)', text: 'data one'
        assert_selector 'tbody tr:first-child td:nth-child(3)', text: 'this pill is green'
        assert_selector 'tbody tr:first-child td:nth-child(4)',
                        text: I18n.l(DateTime.new(2024, 1, 1).to_date, format: :long)
        assert_selector "tbody tr:first-child td:nth-child(5) time[data-local='time-ago']"
        assert_selector 'tbody tr:first-child td:nth-child(5) ' \
                        "time[datetime='#{(DateTime.now - (1 / 1440.0)).utc.iso8601}']"
        assert_selector 'tbody tr:first-child td:nth-child(6) a', text: 'data one Action1'
        assert_selector 'tbody tr:first-child td:nth-child(6) a', text: 'data one Action2'

        assert_selector 'tbody tr:nth-child(2) th:first-child', text: '2'
        assert_selector 'tbody tr:nth-child(2) td:nth-child(2)', text: 'data two'
        assert_selector 'tbody tr:nth-child(2) td:nth-child(3)', text: 'this pill is blue'
        assert_selector 'tbody tr:nth-child(2) td:nth-child(4)',
                        text: I18n.l(DateTime.new(2022, 7, 15).to_date, format: :long)
        assert_selector 'tbody tr:nth-child(2) td:nth-child(5) ' \
                        "time[data-local='time-ago'][datetime='#{(DateTime.now - (1 / 24.0)).utc.iso8601}']"

        assert_selector 'tbody tr:nth-child(2) td:nth-child(6) a', text: 'data two Action1'
        assert_selector 'tbody tr:nth-child(2) td:nth-child(6) a', text: 'data two Action2'

        assert_selector 'tbody tr:first-child td:nth-child(3) ' \
                        '.bg-green-100.text-green-800.text-xs.font-medium.rounded-full'

        assert_selector 'tbody tr:nth-child(2) td:nth-child(3)' do
          assert_selector '.bg-blue-100.text-blue-800.text-xs.font-medium.rounded-full'
        end
      end
    end

    test 'overflow_x' do
      render_preview(:overflow_x)
      assert_selector 'div#preview_table'

      assert_selector 'tbody tr:first-child td:nth-child(2)',
                      text: 'data one with a very very very very very ' \
                            'very very very very very very very very very very very very very long name'

      assert_selector 'thead' do
        assert_selector 'th.right-0', text: I18n.t('workflow_executions.table_component.actions')
      end

      assert_selector 'tbody' do
        assert_selector 'td.right-0',
                        count: 2
      end
    end
  end
end
