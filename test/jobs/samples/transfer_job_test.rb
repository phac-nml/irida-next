# frozen_string_literal: true

require 'test_helper'

module Samples
  class TransferJobTest < ActiveJob::TestCase
    def setup
      @john_doe = users(:john_doe)
      @group = groups(:group_one)
      @project = projects(:project1)
      @new_project = projects(:project2)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
    end

    test 'cloning samples while authorized results in a broadcasted success message and log data with correct responsible id' do # rubocop:disable Layout/LineLength
      broadcast_target = SecureRandom.uuid
      sample_ids = [@sample1.id, @sample2.id]

      assert_difference -> { @new_project.reload.samples.count } => 2 do
        Samples::TransferJob.perform_now(@project.namespace, @john_doe, @new_project.id, sample_ids, broadcast_target)
      end

      turbo_streams = capture_turbo_stream_broadcasts broadcast_target

      assert_equal @john_doe.id, @new_project.samples.find_by(name: @sample1.name).reload_log_data.responsible_id
      assert_equal @john_doe.id, @new_project.samples.find_by(name: @sample2.name).reload_log_data.responsible_id
      assert_equal 4, turbo_streams.size
      # first 3 turbo streams are for progress bar updates
      turbo_streams.take(3).each do |ts|
        assert_equal 'replace', ts['action']
        assert_equal "#{broadcast_target}-progress-bar", ts['target']
      end
      # last turbo stream is the success message
      assert_equal 'replace', turbo_streams.last['action']
      assert_equal 'transfer_samples_dialog_content', turbo_streams.last['target']
      assert_includes turbo_streams.last.to_html, I18n.t('samples.transfers.create.success')
    end
  end
end
