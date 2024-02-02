# frozen_string_literal: true

require 'view_component_test_case'

class HistoryVersionComponentTest < ViewComponentTestCase
  test 'display of version changes' do
    version = 3

    initial_version = { 'c' => { 'id' => 254, 'name' => 'Project 1', 'path' => 'project-1', 'type' => 'Project',
                                 'owner_id' => 1,
                                 'parent_id' => 1, 'created_at' => '2024-01-31T20:38:57.855327', 'deleted_at' => nil,
                                 'updated_at' => '2024-01-31T20:38:57.855327', 'description' => '',
                                 'puid' => 'INXT_PRJ_AYB7CITB2Q',
                                 'metadata_summary' => '{}' },
                        'm' => { '_r' => 1 },
                        'v' => 1,
                        'ts' => 1_706_733_537_855 }

    current_version = { 'c' => { 'updated_at' => '2024-01-31 21:06:02.109167',
                                 'metadata_summary' => '{"key1": 1, "key2": 1, "key3": 1}' },
                        'v' => 3, 'ts' => 1_706_735_162_109 }

    versions_after_initial = [{ 'c' => { 'updated_at' => '2024-01-31 21:04:39.663407',
                                         'metadata_summary' => '{"key1": 1, "key2": 1}' }, 'v' => 2,
                                'ts' => 1_706_735_079_663 }]

    versions_after_initial.each do |ver|
      initial_version['c'].merge!(ver['c'])
    end

    responsible = 'user@email.com'

    @log_data = { version:, user: responsible,
                  changes_from_prev_version: current_version['c'].except('id', 'created_at', 'updated_at',
                                                                         'deleted_at'),
                  previous_version: initial_version['c'].except('id', 'created_at', 'updated_at', 'deleted_at') }

    render_inline HistoryVersionComponent.new(log_data: @log_data)

    assert_selector 'dt', count: 1
    assert_selector 'dd', count: 2

    assert_selector 'dt', text: 'key3'

    assert_selector 'dd', text: ''
    assert_selector 'dd', text: '1'
  end
end
