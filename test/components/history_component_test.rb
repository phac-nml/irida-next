# frozen_string_literal: true

require 'view_component_test_case'

class HistoryComponentTest < ViewComponentTestCase
  test 'listing of project change log versions' do
    log_data = []
    version_hash = { 'h' =>
    [{ 'c' => { 'id' => 254, 'name' => 'Project 1', 'path' => 'project-1', 'type' => 'Project', 'owner_id' => 1,
                'parent_id' => 1, 'deleted_at' => nil,
                'description' => '', 'puid' => 'INXT_PRJ_AYB7CITB2Q' },
       'm' => { '_r' => 1 },
       'v' => 1,
       'ts' => 1_706_733_537_855 },
     { 'c' => { 'description' => 'New description for Project 1' }, 'v' => 2,
       'ts' => 1_706_735_079_663 },
     { 'c' => { 'description' => 'Another new description for this project' },
       'v' => 3, 'ts' => 1_706_735_162_109 }],
                     'v' => 3 }

    version_hash['h'].each do |change_log|
      responsible = 'user@email.com'

      log_data << { version: change_log['v'], user: responsible,
                    updated_at: DateTime.parse(Time.zone.at(0, change_log['ts'], :millisecond).to_s)
                                        .strftime('%a %b%e %Y %H:%M') }
    end

    render_inline HistoryComponent.new(data: log_data, type: 'Project',
                                       url: '/user_at_email.com/project-1/-/history/new')

    assert_selector 'li', count: 3
    assert_selector 'span', count: 3
    assert_selector 'p', text: 'Project created by user@email.com', count: 1
    assert_selector 'p', text: 'Project modified by user@email.com', count: 2

    assert_selector 'button[action="/user_at_email.com/project-1/-/history/new"]', count: 3
    assert_selector 'button', text: 'Version 3'
    assert_selector 'button', text: 'Version 2'
    assert_selector 'button', text: 'Version 1'
  end

  test 'listing of sample change log versions' do
    log_data = []
    version_hash = { 'h' =>
    [{ 'c' =>
       { 'id' => 1421,
         'name' => 'Sample 1',
         'puid' => 'INXT_SAM_AYCQCHLKFD',
         'metadata' => '{}',
         'deleted_at' => nil,
         'project_id' => 254,
         'description' => '' },
       'm' => { '_r' => 1 },
       'v' => 1,
       'ts' => 1_708_114_666_172 },
     { 'c' => { 'metadata' => '{"field1": "value1", "field2": "value2"}' }, 'm' => { '_r' => 1 }, 'v' => 2,
       'ts' => 1_708_114_680_185 },
     { 'c' => { 'metadata' => '{"field1": "newvalue1", "field2": "newvalue2"}' }, 'm' => { '_r' => 1 }, 'v' => 3,
       'ts' => 1_708_114_724_089 },
     { 'c' => { 'metadata' => '{"field1": "newvalue2", "field2": "newvalue3", "newfield": "newfieldvalue1"}' },
       'm' => { '_r' => 1 },
       'v' => 4,
       'ts' => 1_708_114_832_929 },
     { 'c' => { 'metadata' => '{"field1": "newvalue2", "field2": "newvalue3"}' }, 'm' => { '_r' => 1 }, 'v' => 5,
       'ts' => 1_708_114_947_526 },
     { 'c' => { 'metadata' => '{}' }, 'm' => { '_r' => 1 }, 'v' => 6, 'ts' => 1_708_121_682_922 }],
                     'v' => 6 }

    version_hash['h'].each do |change_log|
      responsible = 'user@email.com'

      log_data << { version: change_log['v'], user: responsible,
                    updated_at: DateTime.parse(Time.zone.at(0, change_log['ts'], :millisecond).to_s)
                                        .strftime('%a %b%e %Y %H:%M') }

      render_inline HistoryComponent.new(data: log_data, type: 'Sample',
                                         url: '/user_at_email.com/project-1/-/samples/1421/view_history_version')
    end

    assert_selector 'li', count: 6
    assert_selector 'span', count: 6
    assert_selector 'p', text: 'Sample created by user@email.com', count: 1
    assert_selector 'p', text: 'Sample modified by user@email.com', count: 5

    assert_selector 'form[action="/user_at_email.com/project-1/-/samples/1421/view_history_version"]', count: 6
    assert_selector 'button', text: 'Version 6'
    assert_selector 'button', text: 'Version 5'
    assert_selector 'button', text: 'Version 4'
    assert_selector 'button', text: 'Version 3'
    assert_selector 'button', text: 'Version 2'
    assert_selector 'button', text: 'Version 1'
  end
end
