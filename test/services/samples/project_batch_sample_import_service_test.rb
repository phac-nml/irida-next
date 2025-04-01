# frozen_string_literal: true

require 'test_helper'

module Samples
  class ProjectBatchSampleImportServiceTest < ActiveSupport::TestCase
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
        sample_description_column: 'description'
      }
    end

    test 'import samples with permission for project namespace' do
      assert_equal 3, @project.samples.count

      assert_authorized_to(:import_samples_and_metadata?, @project.namespace,
                           with: Namespaces::ProjectNamespacePolicy,
                           context: { user: @john_doe }) do
        Samples::BatchFileImportService.new(@project.namespace, @john_doe, @blob.id, @default_params).execute
      end

      assert_equal 5, @project.samples.count
      assert_equal 1, @project.samples.where(name: 'my new sample').count
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

      assert_equal m1, response['my new sample'].metadata
      assert_equal m1, @project.samples.where(name: 'my new sample')[0].metadata
      assert_equal m2, response['my new sample 2'].metadata
      assert_equal m2, @project.samples.where(name: 'my new sample 2')[0].metadata

      assert_equal 'user', @project.samples.where(name: 'my new sample')[0].metadata_provenance['metadata1']['source']
      assert_equal 'user', @project.samples.where(name: 'my new sample')[0].metadata_provenance['metadata2']['source']
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

      assert_equal m1, response['my new sample'].metadata
      assert_equal m1, @project.samples.where(name: 'my new sample')[0].metadata
      assert_equal m2, response['my new sample 2'].metadata
      assert_equal m2, @project.samples.where(name: 'my new sample 2')[0].metadata

      assert_equal 'user', @project.samples.where(name: 'my new sample')[0].metadata_provenance['metadata1']['source']
      assert_equal 'user', @project.samples.where(name: 'my new sample')[0].metadata_provenance['metadata2']['source']
      assert_equal 'user', @project.samples.where(name: 'my new sample 2')[0].metadata_provenance['metadata2']['source']
    end
  end
end
