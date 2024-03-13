# frozen_string_literal: true

require 'test_helper'

class DataExportCreateJobTest < ActiveJob::TestCase
  def setup
    @data_export = data_exports(:data_export_two)
  end

  test 'creating export and updating data_export status and expiry' do
    assert @data_export.status = 'processing'
    assert_nil @data_export.expires_at
    assert_not @data_export.file.valid?

    assert_difference -> { ActiveStorage::Attachment.count } => +1 do
      DataExports::CreateJob.perform_now(@data_export)
    end
    assert @data_export.status = 'ready'
    if Date.current.monday? || Date.current.tuesday?
      assert_equal Date.current + 4.days, @data_export.expires_at
    else
      assert_equal Date.current + 6.days, @data_export.expires_at
    end

    assert @data_export.file.valid?
    assert_equal "#{@data_export.id}.zip", @data_export.file.filename.to_s
  end
end
