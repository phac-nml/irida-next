# frozen_string_literal: true

require 'test_helper'
module DataExports
  class CleanupJobTest < ActiveJob::TestCase
    test 'cleanup expired export' do
      travel 3.days
      assert_no_difference -> { ActiveStorage::Attachment.count },
                           -> { DataExport.count } do
        DataExports::CleanupJob.perform_now
      end

      travel 1.day
      # Destroys data_export_1
      assert_difference -> { ActiveStorage::Attachment.count } => -1,
                        -> { DataExport.count } => -1 do
        DataExports::CleanupJob.perform_now
      end
    end
  end
end
