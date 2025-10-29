# frozen_string_literal: true

require 'test_helper'

module Samples
  class CloneJobTest < ActiveJob::TestCase
    def setup
      @john_doe = users(:john_doe)
      @project = projects(:project1)
      @new_project = projects(:project2)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
    end

    test 'cloning samples while authorized results in a broadcasted success message and log data with correct responsible id' do # rubocop:disable Layout/LineLength
      broadcast_target = SecureRandom.uuid
      sample_ids = [@sample1.id, @sample2.id]

      assert_difference -> { @new_project.reload.samples.count } => 2 do
        Samples::CloneJob.perform_now(@project.namespace, @john_doe, @new_project.id, sample_ids, broadcast_target)
      end

      turbo_streams = capture_turbo_stream_broadcasts broadcast_target

      assert_equal @john_doe.id, @new_project.samples.find_by(name: @sample1.name).reload_log_data.responsible_id
      assert_equal @john_doe.id, @new_project.samples.find_by(name: @sample2.name).reload_log_data.responsible_id
      assert_equal 1, turbo_streams.size
      assert_equal 'replace', turbo_streams.first['action']
      assert_equal 'clone_samples_dialog_content', turbo_streams.first['target']
      assert_includes turbo_streams.first.to_html, I18n.t('samples.clones.create.success')
    end
  end
end
