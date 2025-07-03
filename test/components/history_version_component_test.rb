# frozen_string_literal: true

require 'view_component_test_case'

class HistoryVersionComponentTest < ViewComponentTestCase
  test 'display of project version changes' do
    version = 3

    initial_version = { 'c' => { 'id' => 254, 'name' => 'Project 1', 'path' => 'project-1', 'type' => 'Project',
                                 'owner_id' => 1,
                                 'parent_id' => 1, 'deleted_at' => nil, 'description' => '',
                                 'puid' => 'INXT_PRJ_AYB7CITB2Q' },
                        'm' => { '_r' => 1 },
                        'v' => 1,
                        'ts' => 1_706_733_537_855 }

    current_version = { 'c' => { 'description' => 'New description for Project 1' },
                        'v' => 3, 'ts' => 1_706_735_162_109 }

    versions_after_initial = [{ 'c' => { 'description' => 'Another new description for this project' }, 'v' => 2,
                                'ts' => 1_706_735_079_663 }]

    versions_after_initial.each do |ver|
      initial_version['c'].merge!(ver['c'])
    end

    responsible = 'user@email.com'

    @log_data = { version:, user: responsible,
                  changes_from_prev_version: current_version['c'].except('id'),
                  previous_version: initial_version['c'].except('id') }

    render_inline HistoryVersionComponent.new(log_data: @log_data)

    assert_selector 'span', count: 3

    assert_selector 'span', text: 'description'

    assert_selector 'span', text: 'New description for Project 1'
    assert_selector 'span', text: 'Another new description for this project'
  end

  test 'display of sample version changes' do
    version = 6

    initial_version = { 'c' =>
    { 'id' => 1421,
      'name' => 'Sample 1',
      'puid' => 'INXT_SAM_AYCQCHLKFD',
      'metadata' => '{}',
      'deleted_at' => nil,
      'project_id' => 254,
      'description' => '' },
                        'm' => { '_r' => 1 },
                        'v' => 1,
                        'ts' => 1_708_114_666_172 }

    current_version = { 'c' => { 'metadata' => '{}' }, 'm' => { '_r' => 1 }, 'v' => 6, 'ts' => 1_708_121_682_922 }

    versions_after_initial = [{ 'c' => { 'metadata' => '{"field1": "value1", "field2": "value2"}' },
                                'm' => { '_r' => 1 }, 'v' => 2,
                                'ts' => 1_708_114_680_185 },
                              { 'c' => { 'metadata' => '{"field1": "newvalue1", "field2": "newvalue2"}' },
                                'm' => { '_r' => 1 }, 'v' => 3,
                                'ts' => 1_708_114_724_089 },
                              { 'c' => { 'metadata' => '{"field1": "newvalue2", "field2": "newvalue3",
                                                                          "newfield": "newfieldvalue1"}' },
                                'm' => { '_r' => 1 },
                                'v' => 4,
                                'ts' => 1_708_114_832_929 },
                              { 'c' => { 'metadata' => '{"field1": "newvalue2", "field2": "newvalue3"}' },
                                'm' => { '_r' => 1 }, 'v' => 5,
                                'ts' => 1_708_114_947_526 }]

    versions_after_initial.each do |ver|
      initial_version['c'].merge!(ver['c'])
    end

    responsible = 'user@email.com'

    @log_data = { version:, user: responsible,
                  changes_from_prev_version: current_version['c'].except('id'),
                  previous_version: initial_version['c'].except('id') }

    render_inline HistoryVersionComponent.new(log_data: @log_data)

    assert_text I18n.t(:'components.history_version.keys_deleted')

    assert_selector 'span', count: 6

    assert_selector 'span', text: 'field1'
    assert_selector 'span', text: 'field2'

    assert_selector 'span', text: 'newvalue2'
    assert_selector 'span', text: 'newvalue3'
  end
end
