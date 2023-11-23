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

      test 'update sample metadata with sample containing no existing metadata' do
        metadata = { 'key1' => 'value1', 'key2' => 'value2' }

        assert_changes -> { @sample.metadata }, to: { 'key1' => 'value1', 'key2' => 'value2' } do
          Samples::Metadata::UpdateService.new(@project, @sample, @user, {}, metadata, nil).execute
        end
      end

      test 'update sample existing metadata with new metadata including key merge' do
        @sample.metadata = { 'key1' => 'value1', 'key2' => 'value2' }
        metadata = { 'key1' => 'value4', 'key3' => 'value3' }

        assert_changes lambda {
                         @sample.metadata
                       }, to: { 'key1' => 'value4', 'key2' => 'value2', 'key3' => 'value3' } do
          Samples::Metadata::UpdateService.new(@project, @sample, @user, {}, metadata, nil).execute
        end
      end

      test 'remove metadata key' do
        @sample.metadata = { 'key1' => 'value1', 'key2' => 'value2' }

        Samples::Metadata::UpdateService.new(@project, @sample, @user, {}, nil, 'key2').execute

        assert_equal(@sample.metadata, { 'key1' => 'value1' })
      end

      test 'remove metadata key that does not exist' do
        @sample.metadata = { 'key1' => 'value1', 'key2' => 'value2' }

        assert_no_changes -> { @sample } do
          Samples::Metadata::UpdateService.new(@project, @sample, @user, {}, nil, 'key3').execute
        end
        assert @sample.errors.full_messages.include?(
          I18n.t('services.samples.metadata.key_does_not_exist', sample_name: @sample.name, key: 'key3')
        )
      end

      test 'update sample metadata and remove key in single service execution' do
        metadata = { 'key1' => 'value1', 'key2' => 'value2' }

        assert_changes -> { @sample.metadata }, to: { 'key1' => 'value1' } do
          Samples::Metadata::UpdateService.new(@project, @sample, @user, {}, metadata, 'key2').execute
        end
      end

      test 'update sample metadata and try to remove metadata key that does not exist' do
        metadata = { 'key1' => 'value1', 'key2' => 'value2' }

        assert_changes -> { @sample.metadata }, to: { 'key1' => 'value1', 'key2' => 'value2' } do
          Samples::Metadata::UpdateService.new(@project, @sample, @user, {}, metadata, 'key3').execute
        end
        assert @sample.errors.full_messages.include?(
          I18n.t('services.samples.metadata.key_does_not_exist', sample_name: @sample.name, key: 'key3')
        )
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
    end
  end
end
