# frozen_string_literal: true

require 'securerandom'
require 'test_helper'

module Samples
  class BatchSampleImportJobTest < ActiveJob::TestCase
    def setup
      @john_doe = users(:john_doe)
      @project = projects(:project1)
    end

    test 'import samples via csv files to project namespace' do
      broadcast_target = SecureRandom.uuid
      file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/batch_sample_import/project/valid.csv'))
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )
      params = { sample_name_column: 'sample_name',
                 sample_description_column: 'description',
                 metadata_fields: %w[metadata1 metadata2] }

      assert_difference -> { @project.reload.samples.count } => 2 do
        Samples::BatchSampleImportJob.perform_now(@project.namespace, @john_doe, broadcast_target, blob.id, params)
      end

      turbo_streams = capture_turbo_stream_broadcasts broadcast_target

      assert_equal @john_doe.id, @project.samples.find_by(name: 'my new sample 1').reload_log_data.responsible_id
      assert_equal @john_doe.id, @project.samples.find_by(name: 'my new sample 2').reload_log_data.responsible_id
      assert_equal 3, turbo_streams.size
      # first 2 turbo streams are for progress bar updates
      turbo_streams.take(2).each do |ts|
        assert_equal 'replace', ts['action']
        assert_equal "#{broadcast_target}-progress-bar", ts['target']
      end
      # last turbo stream is the success message
      assert_equal 'replace', turbo_streams.last['action']
      assert_equal 'import_spreadsheet_dialog_content', turbo_streams.last['target']
      assert_includes turbo_streams.last.to_html, I18n.t('shared.samples.spreadsheet_imports.success.description')
    end
  end
end
