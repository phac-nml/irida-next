# frozen_string_literal: true

require 'test_helper'

class HistoryConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'get project logidze log data without changes' do
    sign_in users(:john_doe)
    project = projects(:project1)

    freeze_time

    project.namespace.create_logidze_snapshot!

    current_ts = DateTime.now.strftime('%Q').to_i
    updated_at = DateTime.parse(Time.zone.at(0, current_ts, :millisecond).to_s)
                         .strftime('%a %b%e %Y %H:%M')

    expected_result = [{ version: 1, user: 'System', updated_at:, restored: false,
                         deleted: false, transferred: false }]

    log_data = project.namespace.log_data_without_changes

    assert log_data.is_a?(Array)

    assert log_data.length == 1
    assert_equal expected_result, log_data
  end

  test 'get project logidze log data with changes' do
    sign_in users(:john_doe)
    project = projects(:project1)
    project.namespace.create_logidze_snapshot!

    project.namespace.name = 'Project 1 Modified'
    project.namespace.save!
    project.namespace.create_logidze_snapshot!

    assert project.namespace.reload_log_data.versions.length == 2

    version = 1
    log_data = project.namespace.log_data_with_changes(version)

    assert log_data.is_a?(Hash)

    assert_equal version, log_data[:version]
    assert_equal 'System', log_data[:user]
    assert_not_nil log_data[:changes_from_prev_version]
    assert_not_nil log_data[:previous_version]
  end

  test 'get project logidze log data with delete and restore actions' do
    sign_in users(:john_doe)
    project = projects(:project1)
    project.namespace.create_logidze_snapshot!

    project.namespace.destroy
    project.namespace.create_logidze_snapshot!

    Project.restore(project.id, recursive: true)
    project.namespace.create_logidze_snapshot!

    assert project.namespace.reload_log_data.versions.length == 4

    log_data = project.namespace.log_data_without_changes

    assert log_data.is_a?(Array)

    assert log_data[0][:version] == 1
    assert_equal 'System', log_data[0][:user]
    assert_equal false, log_data[0][:deleted]
    assert_equal false, log_data[0][:restored]

    assert log_data[1][:version] == 2
    assert_equal 'System', log_data[1][:user]
    assert_equal true, log_data[1][:deleted]
    assert_equal false, log_data[1][:restored]

    assert log_data[2][:version] == 3
    assert_equal 'System', log_data[2][:user]
    assert_equal false, log_data[2][:deleted]
    assert_equal false, log_data[2][:restored]

    assert log_data[3][:version] == 4
    assert_equal 'System', log_data[3][:user]
    assert_equal false, log_data[3][:deleted]
    assert_equal true, log_data[3][:restored]
  end

  test 'get sample logidze log data without changes' do
    sign_in users(:john_doe)

    sample = samples(:sample1)

    freeze_time

    sample.create_logidze_snapshot!

    current_ts = DateTime.now.strftime('%Q').to_i
    updated_at = DateTime.parse(Time.zone.at(0, current_ts, :millisecond).to_s)
                         .strftime('%a %b%e %Y %H:%M')

    expected_result = [{ version: 1, user: 'System', updated_at:, restored: false,
                         deleted: false, transferred: false }]

    log_data = sample.log_data_without_changes

    assert log_data.is_a?(Array)

    assert log_data.length == 1
    assert_equal expected_result, log_data
  end

  test 'get group logidze log data without changes' do
    sign_in users(:john_doe)
    group = groups(:group_one)

    freeze_time

    group.create_logidze_snapshot!

    current_ts = DateTime.now.strftime('%Q').to_i
    updated_at = DateTime.parse(Time.zone.at(0, current_ts, :millisecond).to_s)
                         .strftime('%a %b%e %Y %H:%M')

    expected_result = [{ version: 1, user: 'System', updated_at:, restored: false,
                         deleted: false, transferred: false }]

    log_data = group.log_data_without_changes

    assert log_data.is_a?(Array)

    assert log_data.length == 1
    assert_equal expected_result, log_data
  end

  test 'get sample logidze log data with changes' do
    sign_in users(:john_doe)
    sample = samples(:sample1)

    sample.create_logidze_snapshot!

    sample.name = 'Project 1 Sample 1 Modified'
    sample.save!
    sample.create_logidze_snapshot!

    assert sample.reload_log_data.versions.length == 2

    version = 1
    log_data = sample.log_data_with_changes(version)

    assert log_data.is_a?(Hash)

    assert_equal version, log_data[:version]
    assert_equal 'System', log_data[:user]
    assert_not_nil log_data[:changes_from_prev_version]
    assert_not_nil log_data[:previous_version]
  end

  test 'get group logidze log data with changes' do
    sign_in users(:john_doe)
    group = groups(:group_one)

    group.create_logidze_snapshot!

    group.name = 'Group 1 Modified'
    group.save!
    group.create_logidze_snapshot!

    assert group.reload_log_data.versions.length == 2

    version = 1
    log_data = group.log_data_with_changes(version)

    assert log_data.is_a?(Hash)

    assert_equal version, log_data[:version]
    assert_equal 'System', log_data[:user]
    assert_not_nil log_data[:changes_from_prev_version]
    assert_not_nil log_data[:previous_version]
  end

  test 'get sample logidze log data with delete and restore actions' do
    sign_in users(:john_doe)
    sample = samples(:sample1)

    sample.create_logidze_snapshot!

    sample.destroy
    sample.create_logidze_snapshot!

    Sample.restore(sample.id, recursive: true)
    sample.create_logidze_snapshot!

    assert sample.reload_log_data.versions.length == 3

    log_data = sample.log_data_without_changes

    assert log_data.is_a?(Array)

    assert log_data[0][:version] == 1
    assert_equal 'System', log_data[0][:user]
    assert_equal false, log_data[0][:deleted]
    assert_equal false, log_data[0][:restored]

    assert log_data[1][:version] == 2
    assert_equal 'System', log_data[1][:user]
    assert_equal true, log_data[1][:deleted]
    assert_equal false, log_data[1][:restored]

    assert log_data[2][:version] == 3
    assert_equal 'System', log_data[2][:user]
    assert_equal false, log_data[2][:deleted]
    assert_equal true, log_data[2][:restored]
  end

  test 'get group logidze log data with delete and restore actions' do
    sign_in users(:john_doe)
    group = groups(:group_one)

    group.create_logidze_snapshot!

    group.destroy
    group.create_logidze_snapshot!

    Group.restore(group.id, recursive: true)
    group.create_logidze_snapshot!

    assert group.reload_log_data.versions.length == 4

    log_data = group.log_data_without_changes

    assert log_data.is_a?(Array)
    assert log_data[0][:version] == 1
    assert_equal 'System', log_data[0][:user]
    assert_equal false, log_data[0][:deleted]
    assert_equal false, log_data[0][:restored]

    assert log_data[1][:version] == 2
    assert_equal 'System', log_data[1][:user]
    assert_equal true, log_data[1][:deleted]
    assert_equal false, log_data[1][:restored]

    assert log_data[2][:version] == 3
    assert_equal 'System', log_data[2][:user]
    assert_equal false, log_data[2][:deleted]
    assert_equal false, log_data[2][:restored]

    assert log_data[3][:version] == 4
    assert_equal 'System', log_data[3][:user]
    assert_equal false, log_data[3][:deleted]
    assert_equal true, log_data[3][:restored]
  end
end
