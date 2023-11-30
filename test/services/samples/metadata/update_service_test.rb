# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    class UpdateServiceTest < ActiveSupport::TestCase
      def setup
        @user = users(:john_doe)
        @sample = samples(:sample1)
        @project = projects(:project1)
      end

      test 'update sample metadata with sample containing no existing metadata and test user in metadata provenance' do
        metadata = { 'key1' => 'value1', 'key2' => 'value2' }
        Samples::Metadata::UpdateService.new(@project, @sample, @user, {}, metadata, nil).execute

        assert_equal(@sample.metadata, { 'key1' => 'value1', 'key2' => 'value2' })
        assert_equal(@sample.metadata_provenance, { 'key1' => { 'id' => @user.id, 'source' => 'user' },
                                                    'key2' => { 'id' => @user.id, 'source' => 'user' } })
      end

      test 'update sample metadata with new metadata including key merge and analysis in metadata provenance' do
        @sample.metadata = { 'key1' => 'value1', 'key2' => 'value2' }
        @sample.metadata_provenance = { 'key1' => { 'id' => 1, 'source' => 'user' },
                                        'key2' => { 'id' => 1, 'source' => 'user' } }
        metadata = { 'key1' => 'value4', 'key3' => 'value3' }
        Samples::Metadata::UpdateService.new(@project, @sample, @user, {}, metadata, 1).execute

        assert_equal(@sample.metadata, { 'key1' => 'value4', 'key2' => 'value2', 'key3' => 'value3' })
        assert_equal(@sample.metadata_provenance, { 'key1' => { 'id' => 1, 'source' => 'analysis' },
                                                    'key2' => { 'id' => 1, 'source' => 'user' },
                                                    'key3' => { 'id' => 1, 'source' => 'analysis' } })
      end

      test 'remove metadata key' do
        @sample.metadata = { 'key1' => 'value1', 'key2' => 'value2' }
        metadata = { 'key2' => '' }
        Samples::Metadata::UpdateService.new(@project, @sample, @user, {}, metadata, 1).execute

        assert_equal(@sample.metadata, { 'key1' => 'value1' })
      end

      test 'update sample metadata without permission to update sample' do
        user = users(:ryan_doe)
        metadata = { 'key1' => 'value1', 'key2' => 'value2' }

        exception = assert_raises(ActionPolicy::Unauthorized) do
          Samples::Metadata::UpdateService.new(@project, @sample, user, {}, metadata, nil).execute
        end

        assert_equal ProjectPolicy, exception.policy
        assert_equal :update_sample?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.project.update_sample?', name: @sample.project.name),
                     exception.result.message
      end

      test 'update sample metadata with valid permission' do
        metadata = { 'key1' => 'value1', 'key2' => 'value2' }

        assert_authorized_to(:update_sample?, @sample.project, with: ProjectPolicy,
                                                               context: { user: @user }) do
          Samples::Metadata::UpdateService.new(@project, @sample, @user, {}, metadata, nil).execute
        end
      end

      test 'sample does not belong to project' do
        metadata = { 'key1' => 'value1', 'key2' => 'value2' }
        project = projects(:projectA)
        assert_no_changes -> { @sample } do
          Samples::Metadata::UpdateService.new(project, @sample, @user, {}, metadata, nil).execute
        end
        assert @sample.errors.full_messages.include?(
          I18n.t('services.samples.metadata.sample_does_not_belong_to_project', sample_name: @sample.name,
                                                                                project_name: project.name)
        )
      end

      test 'no metadata' do
        assert_no_changes -> { @sample } do
          Samples::Metadata::UpdateService.new(@project, @sample, @user, {}, nil, nil).execute
        end
        assert @sample.errors.full_messages.include?(
          I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample.name)
        )
      end
    end
  end
end
