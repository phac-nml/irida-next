# frozen_string_literal: true

require 'test_helper'

class HistoryConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'get project logidze log data without changes' do
    sign_in users(:john_doe)
    project = projects(:project1)
    Timecop.freeze do
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
end
