# frozen_string_literal: true

require 'view_component_test_case'

class HistoryComponentTest < ViewComponentTestCase
  test 'listing of versions' do
    log_data = []
    version_hash = { 'h' =>
    [{ 'c' => { 'id' => 254, 'name' => 'Project 1', 'path' => 'project-1', 'type' => 'Project', 'owner_id' => 1,
                'parent_id' => 1, 'created_at' => '2024-01-31T20:38:57.855327', 'deleted_at' => nil,
                'updated_at' => '2024-01-31T20:38:57.855327', 'description' => '', 'metadata_summary' => '{}' },
       'm' => { '_r' => 1 },
       'v' => 1,
       'ts' => 1_706_733_537_855 },
     { 'c' => { 'updated_at' => '2024-01-31 21:04:39.663407',
                'metadata_summary' => '{"key1": 1, "key2": 1}' }, 'v' => 2,
       'ts' => 1_706_735_079_663 },
     { 'c' => { 'updated_at' => '2024-01-31 21:06:02.109167',
                'metadata_summary' => '{"key1": 1, "key2": 1, "key3": 1}' },
       'v' => 3, 'ts' => 1_706_735_162_109 }],
                     'v' => 3 }

    version_hash['h'].each do |change_log|
      responsible = 'user@email.com'

      log_data << { version: change_log['v'], user: responsible,
                    updated_at: DateTime.parse(change_log['c']['updated_at']).strftime('%a %b %e %Y %H:%M') }
    end

    render_inline HistoryComponent.new(data: log_data, type: 'Project',
                                       url: '/user_at_email.com/project-1/-/history/new')

    assert_selector 'li', count: 3
    assert_selector 'h3', count: 3
    assert_selector 'p', text: 'Project created by user@email.com', count: 1
    assert_selector 'p', text: 'Project modified by user@email.com', count: 2

    assert_selector 'h3', text: 'Version 3'
    assert_selector 'a[href="/user_at_email.com/project-1/-/history/new?version=3"]', count: 1

    assert_selector 'h3', text: 'Version 2'
    assert_selector 'a[href="/user_at_email.com/project-1/-/history/new?version=2"]', count: 1

    assert_selector 'h3', text: 'Version 1'
    assert_selector 'a[href="/user_at_email.com/project-1/-/history/new?version=1"]', count: 1
  end
end
