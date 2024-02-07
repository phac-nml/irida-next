# frozen_string_literal: true

require 'view_component_test_case'

class HistoryComponentTest < ViewComponentTestCase
  test 'listing of versions' do
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
    assert_selector 'h2', count: 3
    assert_selector 'p', text: 'Project created by user@email.com', count: 1
    assert_selector 'p', text: 'Project modified by user@email.com', count: 2

    assert_selector 'h2', text: 'Version 3'
    assert_selector 'a[href="/user_at_email.com/project-1/-/history/new?version=3"]', count: 1

    assert_selector 'h2', text: 'Version 2'
    assert_selector 'a[href="/user_at_email.com/project-1/-/history/new?version=2"]', count: 1

    assert_selector 'h2', text: 'Version 1'
    assert_selector 'a[href="/user_at_email.com/project-1/-/history/new?version=1"]', count: 1
  end
end
