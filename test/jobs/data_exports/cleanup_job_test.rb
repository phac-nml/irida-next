# frozen_string_literal: true

require 'test_helper'
module DataExports
  class CleanupJobTest < ActiveJob::TestCase
    def setup
      @data_export = data_exports(:data_export_one)
    end

    test 'cleanup expired export' do
      assert @data_export.valid?
      assert @data_export.file.valid?
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

      assert_raises(ActiveRecord::RecordNotFound) { @data_export.reload }
    end
  end
end
