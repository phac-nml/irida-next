# frozen_string_literal: true

require 'test_helper'

module Samples
  class MetadataImportJobTest < ActiveJob::TestCase
    def setup
      @john_doe = users(:john_doe)
      @project = projects(:project1)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
    end

    test 'import sample metadata via csv file using sample names for project namespace' do
      broadcast_target = 'blah'
      file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/valid.csv'))
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      params = { sample_id_column: 'sample_name', metadata_columns: %w[metadatafield1 metadatafield2 metadatafield3] }
      Samples::MetadataImportJob.perform_now(@project.namespace, @john_doe, broadcast_target, blob.id, params)
      @sample1.reload
      @sample2.reload

      assert_equal @john_doe.id, @sample1.reload_log_data.responsible_id
      assert_equal @john_doe.id, @sample2.reload_log_data.responsible_id
      assert_equal({ 'metadatafield1' => '10', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                   @sample1.metadata)
      assert_equal({ 'metadatafield1' => '15', 'metadatafield2' => '25', 'metadatafield3' => '35' },
                   @sample2.metadata)
    end

    test 'import sample metadata via csv file using sample puids for project namespace' do
      broadcast_target = 'blah'
      file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/valid_with_puid.csv'))
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      params = { sample_id_column: 'sample_puid', metadata_columns: %w[metadatafield1 metadatafield2 metadatafield3] }
      Samples::MetadataImportJob.perform_now(@project.namespace, @john_doe, broadcast_target, blob.id, params)
      @sample1.reload
      @sample2.reload

      assert_equal @john_doe.id, @sample1.reload_log_data.responsible_id
      assert_equal @john_doe.id, @sample2.reload_log_data.responsible_id
      assert_equal({ 'metadatafield1' => '10', 'metadatafield2' => '20', 'metadatafield3' => '30' },
                   @sample1.metadata)
      assert_equal({ 'metadatafield1' => '15', 'metadatafield2' => '25', 'metadatafield3' => '35' },
                   @sample2.metadata)
    end
  end
end
