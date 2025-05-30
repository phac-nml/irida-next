# frozen_string_literal: true

require 'test_helper'

module Samples
  class GroupBatchSampleImportServiceTest < ActiveSupport::TestCase
    def setup # rubocop:disable Metrics/MethodLength
      @john_doe = users(:john_doe)
      @jane_doe = users(:jane_doe)
      @group = groups(:group_one)
      @group2 = groups(:group_two)
      @project = projects(:project1)
      @project2 = projects(:project2)

      file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/batch_sample_import/group/valid.csv'))
      @blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )
      @default_params = {
        sample_name_column: 'sample_name',
        project_puid_column: 'project_puid',
        sample_description_column: 'description',
        metadata_fields: %w[metadata1 metadata2]
      }
    end

    test 'import samples with permission for group' do
      assert_equal 3, @project.samples.count

      assert_authorized_to(:import_samples_and_metadata?, @group,
                           with: GroupPolicy,
                           context: { user: @john_doe }) do
        Samples::BatchFileImportService.new(@group, @john_doe, @blob.id, @default_params).execute
      end

      assert_equal 5, @project.samples.count
      assert_equal 1, @project.samples.where(name: 'my new sample 1').count
      assert_equal 1, @project.samples.where(name: 'my new sample 2').count
    end

    test 'import samples without permission for group' do
      assert_equal 3, @project.samples.count

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::BatchFileImportService.new(@group, @jane_doe, @blob.id, @default_params).execute
      end
      assert_equal GroupPolicy, exception.policy
      assert_equal :import_samples_and_metadata?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.import_samples_and_metadata?',
                          name: @group.name), exception.result.message
      assert_equal 3, @project.samples.count
    end

    test 'import samples with empty file' do
      file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/metadata/empty.csv'))
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      Samples::BatchFileImportService.new(@group, @john_doe, blob.id, @default_params).execute
      assert_equal(I18n.t('services.spreadsheet_import.missing_header',
                          header_title: 'sample_name,project_puid'),
                   @group.errors.full_messages.to_sentence)
    end

    test 'import samples into a project that does not belong to group namespace' do
      assert_equal 3, @project.samples.count
      assert_equal 20, @project2.samples.count

      response = Samples::BatchFileImportService.new(@group2, @john_doe, @blob.id, @default_params).execute

      assert_equal 3, @project.samples.count
      assert_equal 20, @project2.samples.count

      assert_equal I18n.t('services.samples.batch_import.project_puid_not_in_namespace',
                          project_puid: @project.puid,
                          namespace: @group2.full_path),
                   response['my new sample 1'][0][:message]
      assert_equal I18n.t('services.samples.batch_import.project_puid_not_in_namespace',
                          project_puid: @project.puid,
                          namespace: @group2.full_path),
                   response['my new sample 2'][0][:message]
    end

    test 'import with bad data invalid project' do
      assert_equal 3, @project.samples.count

      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/group/invalid_project.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@group, @john_doe, blob.id,
                                                     @default_params).execute

      assert_equal 4, @project.samples.count

      assert_equal I18n.t('services.samples.batch_import.project_puid_not_found',
                          project_puid: 'invalid_puid'),
                   response['my new sample 2'][0][:message]
    end

    test 'import with bad data missing puid and missing static_project_id' do
      assert_equal 3, @project.samples.count

      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/group/missing_puid.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@group, @john_doe, blob.id,
                                                     @default_params).execute

      assert_equal 4, @project.samples.count
      assert_equal I18n.t('services.spreadsheet_import.missing_field',
                          index: 2),
                   response['index 2'][0][:message]
    end

    test 'valid import with missing puid but with static_project_id' do
      assert_equal 3, @project.samples.count
      assert_equal 20, @project2.samples.count
      @default_params[:static_project_id] = @project2.id

      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/group/missing_puid.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      Samples::BatchFileImportService.new(@group, @john_doe, blob.id,
                                          @default_params).execute

      assert_equal 4, @project.samples.count
      assert_equal 21, @project2.samples.count
    end

    test 'import with bad data blank line' do
      assert_equal 3, @project.samples.count

      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/group/invalid_blank_line.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@group, @john_doe, blob.id,
                                                     @default_params).execute

      assert_equal 5, @project.samples.count

      assert_equal I18n.t('services.spreadsheet_import.missing_field',
                          index: 2),
                   response['index 2'][0][:message]
    end

    test 'import with bad data short sample name' do
      assert_equal 3, @project.samples.count

      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/group/invalid_short_sample_name.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@group, @john_doe, blob.id,
                                                     @default_params).execute

      assert_equal 4, @project.samples.count

      assert_equal ['sample', 'name'], response['m'][0][:path] # rubocop:disable Style/WordArray
      assert_equal 'is too short (minimum is 3 characters)', response['m'][0][:message]
    end

    test 'import with bad data sample already exists' do
      assert_equal 3, @project.samples.count

      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/group/invalid_sample_exists.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@group, @john_doe, blob.id,
                                                     @default_params).execute

      assert_equal 4, @project.samples.count

      assert_equal ['sample', 'name'], response['Project 1 Sample 1'][0][:path] # rubocop:disable Style/WordArray
      assert_equal 'has already been taken', response['Project 1 Sample 1'][0][:message]
    end

    test 'import with bad data invalid duplicate sample name in file' do
      assert_equal 3, @project.samples.count

      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/group/invalid_sample_dup_in_file.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@group, @john_doe, blob.id,
                                                     @default_params).execute

      assert_equal 4, @project.samples.count

      assert_equal I18n.t('services.samples.batch_import.duplicate_sample_name',
                          index: 2),
                   response['index 2'][0][:message]
    end

    test 'import samples with metadata' do
      assert_equal 3, @project.samples.count
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/group/with_metadata_valid.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@group, @john_doe, blob.id, @default_params).execute

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
        Rails.root.join('test/fixtures/files/batch_sample_import/group/with_metadata_with_empty.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@group, @john_doe, blob.id, @default_params).execute

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
        Rails.root.join('test/fixtures/files/batch_sample_import/group/with_metadata_valid.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      response = Samples::BatchFileImportService.new(@group, @john_doe, blob.id, @default_params).execute

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

    test 'should create activities for sample import' do
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('test/fixtures/files/batch_sample_import/group/valid_with_multiple_project_puids.csv')
      )
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )
      # 3 activities created, 1 at the group level, and 1 for each of 2 projects
      assert_difference -> { Sample.count } => 2,
                        -> { PublicActivity::Activity.count } => 3 do
                          Samples::BatchFileImportService.new(@group, @john_doe, blob.id,
                                                              @default_params).execute
                        end
      # verify group activity
      activity = PublicActivity::Activity.where(
        key: 'group.import_samples.create'
      ).order(created_at: :desc).first

      assert_equal 'group.import_samples.create', activity.key
      assert_equal @john_doe, activity.owner
      assert_equal 2, activity.parameters[:imported_samples_count]
      first_sample = Sample.find_by(name: 'my new sample 1')
      second_sample = Sample.find_by(name: 'my new sample 2')
      assert_equal [
        { 'sample_name' => first_sample.name, 'sample_puid' => first_sample.puid,
          'project_puid' => 'INXT_PRJ_AAAAAAAAAA' },
        { 'sample_name' => second_sample.name, 'sample_puid' => second_sample.puid,
          'project_puid' => 'INXT_PRJ_AAAAAAAAAB' }
      ],
                   activity.extended_details.details['imported_samples_data']
      assert_equal 'group_import_samples', activity.parameters[:action]

      # verify project activity 1
      activity = PublicActivity::Activity.where(
        key: 'namespaces_project_namespace.import_samples.create'
      ).order(created_at: :desc).first

      assert_equal 'namespaces_project_namespace.import_samples.create', activity.key
      assert_equal @john_doe, activity.owner
      assert_equal 1, activity.parameters[:imported_samples_count]
      sample2 = Sample.find_by(name: 'my new sample 2')
      assert_equal [{ 'sample_name' => sample2.name, 'sample_puid' => sample2.puid }],
                   activity.extended_details.details['imported_samples_data']
      assert_equal 'project_import_samples', activity.parameters[:action]

      # verify project activity 2
      activity = PublicActivity::Activity.where(
        key: 'namespaces_project_namespace.import_samples.create'
      ).order(created_at: :desc).second

      assert_equal 'namespaces_project_namespace.import_samples.create', activity.key
      assert_equal @john_doe, activity.owner
      assert_equal 1, activity.parameters[:imported_samples_count]
      sample1 = Sample.find_by(name: 'my new sample 1')
      assert_equal [{ 'sample_name' => sample1.name, 'sample_puid' => sample1.puid }],
                   activity.extended_details.details['imported_samples_data']
      assert_equal 'project_import_samples', activity.parameters[:action]
    end
  end
end
