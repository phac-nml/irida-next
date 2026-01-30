# frozen_string_literal: true

require 'test_helper'

module Samples
  class ProjectBatchSampleImportServiceTest < ActiveSupport::TestCase
    def count_broadcasts_for
      broadcast_calls = []
      original_method = Project.instance_method(:broadcast_refresh_later_to)

      Project.class_eval do
        define_method(:broadcast_refresh_later_to) do |streamable, stream_name|
          broadcast_calls << [streamable, stream_name]
          nil # Don't actually broadcast in tests
        end
      end

      yield
      broadcast_calls
    ensure
      # Restore original method
      Project.class_eval do
        define_method(:broadcast_refresh_later_to, original_method)
      end
    end

    def count_progress_bar_updates_for
      calls = []
      original_method = Turbo::StreamsChannel.singleton_class.instance_method(:broadcast_replace_to)

      Turbo::StreamsChannel.singleton_class.class_eval do
        define_method(:broadcast_replace_to) do |*args|
          calls << args
          nil
        end
      end

      yield
      calls
    ensure
      Turbo::StreamsChannel.singleton_class.class_eval do
        define_method(:broadcast_replace_to, original_method)
      end
    end

    def setup # rubocop:disable Metrics/MethodLength
      @john_doe = users(:john_doe)
      @jane_doe = users(:jane_doe)
      @group = groups(:group_one)
      @group2 = groups(:group_two)
      @project = projects(:project1)
      @project2 = projects(:project2)

      file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/batch_sample_import/project/valid.csv'))
      @blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )
      @default_params = {
        sample_name_column: 'sample_name',
        sample_description_column: 'description',
        metadata_fields: %w[metadata1 metadata2]
      }
      Flipper.enable(:samples_refresh_notice)
    end

    def teardown
      Flipper.disable(:samples_refresh_notice)
    end

    test 'import samples with permission for project namespace' do
      assert_equal 3, @project.samples.count

      assert_authorized_to(:import_samples_and_metadata?, @project.namespace,
                           with: Namespaces::ProjectNamespacePolicy,
                           context: { user: @john_doe }) do
        Samples::BatchFileImportService.new(@project.namespace, @john_doe, @blob.id, @default_params).execute
      end

      assert_equal 5, @project.samples.count
      assert_equal 1, @project.samples.where(name: 'my new sample 1').count
      assert_equal 1, @project.samples.where(name: 'my new sample 2').count
    end

    test 'import samples without permission for project namespace' do
      assert_equal 3, @project.samples.count

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::BatchFileImportService.new(@project.namespace, @jane_doe, @blob.id, @default_params).execute
      end
      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :import_samples_and_metadata?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.import_samples_and_metadata?',
                          name: @project.name), exception.result.message

      assert_equal 3, @project.samples.count
    end

    test 'import samples with empty file' do
      file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/empty.csv'))
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      Samples::BatchFileImportService.new(@project.namespace, @john_doe, blob.id, @default_params).execute
      assert_equal(I18n.t('services.spreadsheet_import.missing_header',
                          header_title: 'sample_name'),
                   @project.namespace.errors.full_messages.to_sentence)
    end

    test 'import with bad data blank line' do
      assert_equal 3, @project.samples.count

      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/project/invalid_blank_line.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@project.namespace, @john_doe, blob.id,
                                                     @default_params).execute

      assert_equal 5, @project.samples.count

      assert_equal I18n.t('services.spreadsheet_import.missing_field',
                          index: 2),
                   response['index 2'][0][:message]
    end

    test 'import with bad data duplicate header' do
      assert_equal 3, @project.samples.count

      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/project/invalid_duplicate_header.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      Samples::BatchFileImportService.new(@project.namespace, @john_doe, blob.id,
                                          @default_params).execute

      assert_equal 3, @project.samples.count

      assert_equal I18n.t('services.spreadsheet_import.duplicate_column_names'),
                   @project.namespace.errors.errors[0].type
    end

    test 'import with bad data short sample name' do
      assert_equal 3, @project.samples.count

      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/project/invalid_short_sample_name.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@project.namespace, @john_doe, blob.id,
                                                     @default_params).execute

      assert_equal 4, @project.samples.count

      assert_equal ['sample', 'name'], response['m'][0][:path] # rubocop:disable Style/WordArray
      assert_equal 'is too short (minimum is 3 characters)', response['m'][0][:message]
    end

    test 'import with bad data sample already exists' do
      assert_equal 3, @project.samples.count

      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/project/invalid_sample_exists.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@project.namespace, @john_doe, blob.id,
                                                     @default_params).execute

      assert_equal 4, @project.samples.count

      assert_equal ['sample', 'name'], response['Project 1 Sample 1'][0][:path] # rubocop:disable Style/WordArray
      assert_equal 'has already been taken', response['Project 1 Sample 1'][0][:message]
    end

    test 'import with bad data invalid duplicate sample name in file' do
      assert_equal 3, @project.samples.count

      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/project/invalid_sample_dup_in_file.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@project.namespace, @john_doe, blob.id,
                                                     @default_params).execute

      assert_equal 4, @project.samples.count

      assert_equal I18n.t('services.samples.batch_import.duplicate_sample_name',
                          index: 2),
                   response['index 2'][0][:message]
    end

    test 'import samples with metadata' do
      assert_equal 3, @project.samples.count

      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/project/with_metadata_valid.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@project.namespace, @john_doe, blob.id, @default_params).execute

      assert_equal 5, @project.samples.count

      m1 = { 'metadata1' => 'a', 'metadata2' => 'b' }
      m2 = { 'metadata1' => 'c', 'metadata2' => 'd' }

      assert_equal m1, response['my new sample 1'].metadata
      assert_equal m1, @project.samples.where(name: 'my new sample 1')[0].metadata
      assert_equal m2, response['my new sample 2'].metadata
      assert_equal m2, @project.samples.where(name: 'my new sample 2')[0].metadata

      assert_equal 'user', @project.samples.where(name: 'my new sample 1')[0].metadata_provenance['metadata1']['source']
      assert_equal 'user', @project.samples.where(name: 'my new sample 1')[0].metadata_provenance['metadata2']['source']
      assert_equal 'user', @project.samples.where(name: 'my new sample 2')[0].metadata_provenance['metadata1']['source']
      assert_equal 'user', @project.samples.where(name: 'my new sample 2')[0].metadata_provenance['metadata2']['source']
    end

    test 'import samples with metadata with empty value' do
      assert_equal 3, @project.samples.count

      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/project/with_metadata_with_empty.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@project.namespace, @john_doe, blob.id, @default_params).execute

      assert_equal 5, @project.samples.count

      m1 = { 'metadata1' => 'a', 'metadata2' => 'b' }
      m2 = { 'metadata2' => 'd' }

      assert_equal m1, response['my new sample 1'].metadata
      assert_equal m1, @project.samples.where(name: 'my new sample 1')[0].metadata
      assert_equal m2, response['my new sample 2'].metadata
      assert_equal m2, @project.samples.where(name: 'my new sample 2')[0].metadata

      assert_equal 'user', @project.samples.where(name: 'my new sample 1')[0].metadata_provenance['metadata1']['source']
      assert_equal 'user', @project.samples.where(name: 'my new sample 1')[0].metadata_provenance['metadata2']['source']
      assert_equal 'user', @project.samples.where(name: 'my new sample 2')[0].metadata_provenance['metadata2']['source']
    end

    test 'import samples with partial metadata' do
      assert_equal 3, @project.samples.count
      @default_params[:metadata_fields].delete('metadata2')
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/project/with_metadata_valid.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@project.namespace, @john_doe, blob.id, @default_params).execute

      assert_equal 5, @project.samples.count

      m1 = { 'metadata1' => 'a' }
      m2 = { 'metadata1' => 'c' }

      assert_equal m1, response['my new sample 1'].metadata
      assert_equal m1, @project.samples.where(name: 'my new sample 1')[0].metadata
      assert_equal m2, response['my new sample 2'].metadata
      assert_equal m2, @project.samples.where(name: 'my new sample 2')[0].metadata

      assert_equal 'user', @project.samples.where(name: 'my new sample 1')[0].metadata_provenance['metadata1']['source']
      assert_equal 'user', @project.samples.where(name: 'my new sample 2')[0].metadata_provenance['metadata1']['source']
    end

    test 'should create activity for sample import' do
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/project/with_metadata_valid.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )
      assert_difference -> { Sample.count } => 2,
                        -> { PublicActivity::Activity.count } => 1 do
                          Samples::BatchFileImportService.new(@project.namespace, @john_doe, blob.id,
                                                              @default_params).execute
                        end
      activity = PublicActivity::Activity.where(
        key: 'namespaces_project_namespace.import_samples.create'
      ).order(created_at: :desc).first

      assert_equal 'namespaces_project_namespace.import_samples.create', activity.key
      assert_equal @john_doe, activity.owner
      assert_equal 2, activity.parameters[:imported_samples_count]
      first_sample = Sample.find_by(name: 'my new sample 1')
      second_sample = Sample.find_by(name: 'my new sample 2')
      assert_includes activity.extended_details.details['imported_samples_data'],
                      { 'sample_name' => first_sample.name, 'sample_puid' => first_sample.puid }
      assert_includes activity.extended_details.details['imported_samples_data'],
                      { 'sample_name' => second_sample.name, 'sample_puid' => second_sample.puid }
      assert_equal 2, activity.extended_details.details['imported_samples_data'].count
      assert_equal 'project_import_samples', activity.parameters[:action]
    end

    test 'does not broadcast per sample during import - broadcasts once per project' do
      assert_equal 3, @project.samples.count
      ancestors = @project.namespace.parent.self_and_ancestors

      # Capture project broadcast calls
      broadcast_calls = count_broadcasts_for do
        Samples::BatchFileImportService.new(@project.namespace, @john_doe, @blob.id, @default_params).execute
      end

      # Expect a single project broadcast with its ancestors only (not per sample)
      assert_equal 1 + ancestors.count, broadcast_calls.count
    end

    test 'progress bar updates only every ~1% for samples <= 20' do
      # create a large CSV with 100 rows to make 5% increments obvious
      file = Tempfile.new(['bulk_progress_test', '.csv'])
      begin
        file.puts 'sample_name,description,metadata1,metadata2'
        (1..19).each do |i|
          file.puts "bulk sample #{i},desc,a,b"
        end
        file.rewind

        blob = ActiveStorage::Blob.create_and_upload!(io: file,
                                                      filename: 'bulk_progress_test.csv',
                                                      content_type: 'text/csv')

        # Capture progress bar broadcast calls
        progress_calls = count_progress_bar_updates_for do
          Samples::BatchFileImportService.new(@project.namespace, @john_doe, blob.id,
                                              @default_params).execute('dummy_target')
        end

        # For 19 total samples we expect approx 19 updates including the final update
        assert_equal 19, progress_calls.count
      ensure
        file.close
        file.unlink
      end
    end

    test 'progress bar updates only every ~5% for samples >= 20' do
      # create a large CSV with 100 rows to make 5% increments obvious
      file = Tempfile.new(['bulk_progress_test', '.csv'])
      begin
        file.puts 'sample_name,description,metadata1,metadata2'
        (1..100).each do |i|
          file.puts "bulk sample #{i},desc,a,b"
        end
        file.rewind

        blob = ActiveStorage::Blob.create_and_upload!(io: file,
                                                      filename: 'bulk_progress_test.csv',
                                                      content_type: 'text/csv')

        # Capture progress bar broadcast calls
        progress_calls = count_progress_bar_updates_for do
          Samples::BatchFileImportService.new(@project.namespace, @john_doe, blob.id,
                                              @default_params).execute('dummy_target')
        end

        # For 100 total samples we expect approx 100 * 0.05 = 5, so 20 updates (every 5%) including the final update
        assert_equal 20, progress_calls.count
      ensure
        file.close
        file.unlink
      end
    end

    test 'import samples with whitespaces' do
      assert_equal 3, @project.samples.count

      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/project/valid_with_whitespaces.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      default_params = {
        sample_name_column: 'sample_name',
        sample_description_column: 'description',
        metadata_fields: ['metadata     field 1', 'metadata field 2', 'metadata field 3']
      }

      response = Samples::BatchFileImportService.new(@project.namespace, @john_doe, blob.id, default_params).execute

      assert_equal 5, @project.samples.count
      m1 = { 'metadata field 1' => 'value 1', 'metadata field 2' => 'value2', 'metadata field 3' => 'value3' }
      m2 = { 'metadata field 1' => 'value 4', 'metadata field 2' => 'value 5', 'metadata field 3' => 'value6' }

      assert_equal m1, response['my new sample 1'].metadata
      assert_equal m1, @project.samples.where(name: 'my new sample 1')[0].metadata
      assert_equal m2, response['my new sample 2'].metadata
      assert_equal m2, @project.samples.where(name: 'my new sample 2')[0].metadata

      assert_equal 'user',
                   @project.samples.where(name: 'my new sample 1')[0].metadata_provenance['metadata field 1']['source']
      assert_equal 'user',
                   @project.samples.where(name: 'my new sample 1')[0].metadata_provenance['metadata field 2']['source']
      assert_equal 'user',
                   @project.samples.where(name: 'my new sample 1')[0].metadata_provenance['metadata field 3']['source']
      assert_equal 'user',
                   @project.samples.where(name: 'my new sample 2')[0].metadata_provenance['metadata field 1']['source']
      assert_equal 'user',
                   @project.samples.where(name: 'my new sample 2')[0].metadata_provenance['metadata field 2']['source']
      assert_equal 'user',
                   @project.samples.where(name: 'my new sample 2')[0].metadata_provenance['metadata field 3']['source']
    end
  end
end
