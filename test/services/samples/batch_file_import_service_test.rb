# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    class BatchFileImportServiceTest < ActiveSupport::TestCase
      def setup # rubocop:disable Metrics/MethodLength
        @john_doe = users(:john_doe)
        @jane_doe = users(:jane_doe)
        @group = groups(:group_one)
        @group2 = groups(:group_two)
        @project = projects(:project1)
        @project2 = projects(:project2)

        file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/valid_batch_sample_import.csv'))
        @blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type
        )
        @default_params = {
          sample_name_column: 'sample_name',
          project_puid_column: 'project_puid',
          sample_description_column: 'description'
        }
      end

      test 'import samples with permission for project namespace' do
        assert_equal 3, @project.samples.count

        assert_authorized_to(:update_sample_metadata?, @project.namespace,
                             with: Namespaces::ProjectNamespacePolicy,
                             context: { user: @john_doe }) do
          Samples::BatchFileImportService.new(@project.namespace, @john_doe, @blob.id, @default_params).execute
        end

        assert_equal 5, @project.samples.count
        assert_equal 1, @project.samples.where(name: 'my new sample').count
        assert_equal 1, @project.samples.where(name: 'my new sample 2').count
      end

      test 'import samples with permission for group' do
        assert_equal 3, @project.samples.count

        assert_authorized_to(:update_sample_metadata?, @group,
                             with: GroupPolicy,
                             context: { user: @john_doe }) do
          Samples::BatchFileImportService.new(@group, @john_doe, @blob.id, @default_params).execute
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
        assert_equal :update_sample_metadata?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.update_sample_metadata?',
                            name: @project.name), exception.result.message

        assert_equal 3, @project.samples.count
      end

      test 'import samples without permission for group' do
        assert_equal 3, @project.samples.count

        exception = assert_raises(ActionPolicy::Unauthorized) do
          Samples::BatchFileImportService.new(@group, @jane_doe, @blob.id, @default_params).execute
        end
        assert_equal GroupPolicy, exception.policy
        assert_equal :update_sample_metadata?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.group.update_sample_metadata?',
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

        Samples::BatchFileImportService.new(@project.namespace, @john_doe, blob.id, @default_params).execute
        assert_equal(@project.namespace.errors.full_messages_for(:base).first,
                     I18n.t('services.spreadsheet_import.missing_header', header_title: 'sample_name'))
      end

      test 'import samples into a project that does not belong to project namespace' do
        assert_equal 3, @project.samples.count
        assert_equal 20, @project2.samples.count

        response = Samples::BatchFileImportService.new(@project2.namespace, @john_doe, @blob.id,
                                                       @default_params).execute

        assert_equal 3, @project.samples.count
        assert_equal 20, @project2.samples.count

        assert_equal I18n.t('services.samples.batch_import.project_puid_not_in_namespace',
                            project_puid: @project.puid,
                            namespace: @project2.namespace.full_path),
                     response['my new sample'][:message]
        assert_equal I18n.t('services.samples.batch_import.project_puid_not_in_namespace',
                            project_puid: @project.puid,
                            namespace: @project2.namespace.full_path),
                     response['my new sample'][:message]
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
                     response['my new sample'][:message]
        assert_equal I18n.t('services.samples.batch_import.project_puid_not_in_namespace',
                            project_puid: @project.puid,
                            namespace: @group2.full_path),
                     response['my new sample'][:message]
      end
    end
  end
end
