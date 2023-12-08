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

      test 'update sample metadata with sample containing no existing metadata and user in metadata provenance' do
        params = { 'metadata' => { 'key1' => 'value1', 'key2' => 'value2' } }
        Samples::Metadata::UpdateService.new(@project, @sample, @user, params).execute

        assert_equal(@sample.metadata, { 'key1' => 'value1', 'key2' => 'value2' })
        assert_equal(@sample.metadata_provenance, { 'key1' => { 'id' => @user.id, 'source' => 'user' },
                                                    'key2' => { 'id' => @user.id, 'source' => 'user' } })
      end

      test 'update sample metadata with sample containing no existing metadata and analysis in metadata provenance' do
        params = { 'metadata' => { 'key1' => 'value1', 'key2' => 'value2' }, 'analysis_id' => 2 }
        Samples::Metadata::UpdateService.new(@project, @sample, @user, params).execute

        assert_equal(@sample.metadata, { 'key1' => 'value1', 'key2' => 'value2' })
        assert_equal(@sample.metadata_provenance, { 'key1' => { 'id' => 2, 'source' => 'analysis' },
                                                    'key2' => { 'id' => 2, 'source' => 'analysis' } })
      end

      test 'update sample metadata merge with new metadata and analysis overwritting user' do
        @sample.metadata = { 'key1' => 'value1', 'key2' => 'value2' }
        @sample.metadata_provenance = { 'key1' => { 'id' => 1, 'source' => 'user' },
                                        'key2' => { 'id' => 1, 'source' => 'user' } }
        params = { 'metadata' => { 'key1' => 'value4', 'key3' => 'value3' }, 'analysis_id' => 10 }
        Samples::Metadata::UpdateService.new(@project, @sample, @user, params).execute

        assert_equal(@sample.metadata, { 'key1' => 'value4', 'key2' => 'value2', 'key3' => 'value3' })
        assert_equal(@sample.metadata_provenance, { 'key1' => { 'id' => 10, 'source' => 'analysis' },
                                                    'key2' => { 'id' => 1, 'source' => 'user' },
                                                    'key3' => { 'id' => 10, 'source' => 'analysis' } })
      end

      test 'update sample metadata merge with new metadata and user overwritting user' do
        @sample.metadata = { 'key1' => 'value1', 'key2' => 'value2' }
        @sample.metadata_provenance = { 'key1' => { 'id' => 1, 'source' => 'user' },
                                        'key2' => { 'id' => 1, 'source' => 'user' } }
        params = { 'metadata' => { 'key1' => 'value4', 'key3' => 'value3' } }
        Samples::Metadata::UpdateService.new(@project, @sample, @user, params).execute

        assert_equal(@sample.metadata, { 'key1' => 'value4', 'key2' => 'value2', 'key3' => 'value3' })
        assert_equal(@sample.metadata_provenance, { 'key1' => { 'id' => @user.id, 'source' => 'user' },
                                                    'key2' => { 'id' => 1, 'source' => 'user' },
                                                    'key3' => { 'id' => @user.id, 'source' => 'user' } })
      end

      test 'update sample metadata merge with new metadata and user unable to overwrite analysis' do
        @sample.metadata = { 'key1' => 'value1', 'key2' => 'value2' }
        @sample.metadata_provenance = { 'key1' => { 'id' => 1, 'source' => 'analysis' },
                                        'key2' => { 'id' => 1, 'source' => 'analysis' } }
        params = { 'metadata' => { 'key1' => 'value4', 'key3' => 'value3' } }
        Samples::Metadata::UpdateService.new(@project, @sample, @user, params).execute

        assert_equal(@sample.metadata, { 'key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3' })
        assert_equal(@sample.metadata_provenance, { 'key1' => { 'id' => 1, 'source' => 'analysis' },
                                                    'key2' => { 'id' => 1, 'source' => 'analysis' },
                                                    'key3' => { 'id' => @user.id, 'source' => 'user' } })
        assert @sample.errors.full_messages.include?(
          I18n.t('services.samples.metadata.user_cannot_update_metadata',
                 sample_name: @sample.name,
                 metadata_fields: 'key1')
        )
      end

      test 'remove metadata key with user' do
        @sample.metadata = { 'key1' => 'value1', 'key2' => 'value2' }
        @sample.metadata_provenance = { 'key1' => { 'id' => 1, 'source' => 'analysis' },
                                        'key2' => { 'id' => 1, 'source' => 'analysis' } }
        params = { 'metadata' => { 'key2' => '' } }
        Samples::Metadata::UpdateService.new(@project, @sample, @user, params).execute

        assert_equal(@sample.metadata, { 'key1' => 'value1' })
        assert_equal(@sample.metadata_provenance, { 'key1' => { 'id' => 1, 'source' => 'analysis' } })
      end

      test 'remove metadata key with analysis' do
        @sample.metadata = { 'key1' => 'value1', 'key2' => 'value2' }
        @sample.metadata_provenance = { 'key1' => { 'id' => 1, 'source' => 'user' },
                                        'key2' => { 'id' => 1, 'source' => 'user' } }
        params = { 'metadata' => { 'key2' => '' }, 'analysis_id' => 1 }
        Samples::Metadata::UpdateService.new(@project, @sample, @user, params).execute

        assert_equal(@sample.metadata, { 'key1' => 'value1' })
        assert_equal(@sample.metadata_provenance, { 'key1' => { 'id' => 1, 'source' => 'user' } })
      end

      test 'update sample metadata with valid permission' do
        params = { 'metadata' => { 'key1' => 'value1', 'key2' => 'value2' } }

        assert_authorized_to(:update_sample?, @sample.project, with: ProjectPolicy,
                                                               context: { user: @user }) do
          Samples::Metadata::UpdateService.new(@project, @sample, @user, params).execute
        end
      end

      test 'update sample metadata without permission to update sample' do
        user = users(:ryan_doe)
        params = { 'metadata' => { 'key1' => 'value1', 'key2' => 'value2' } }

        exception = assert_raises(ActionPolicy::Unauthorized) do
          Samples::Metadata::UpdateService.new(@project, @sample, user, params).execute
        end

        assert_equal ProjectPolicy, exception.policy
        assert_equal :update_sample?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.project.update_sample?', name: @sample.project.name),
                     exception.result.message
      end

      test 'sample does not belong to project' do
        params = { 'metadata' => { 'key1' => 'value1', 'key2' => 'value2' } }
        project = projects(:projectA)
        assert_no_changes -> { @sample } do
          Samples::Metadata::UpdateService.new(project, @sample, @user, params).execute
        end
        assert @sample.errors.full_messages.include?(
          I18n.t('services.samples.metadata.sample_does_not_belong_to_project', sample_name: @sample.name,
                                                                                project_name: project.name)
        )
      end

      test 'metadata is nil' do
        assert_no_changes -> { @sample } do
          Samples::Metadata::UpdateService.new(@project, @sample, @user, {}).execute
        end
        assert @sample.errors.full_messages.include?(
          I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample.name)
        )
      end

      test 'metadata is empty hash' do
        params = { 'metadata' => {} }
        assert_no_changes -> { @sample } do
          Samples::Metadata::UpdateService.new(@project, @sample, @user, params).execute
        end
        assert @sample.errors.full_messages.include?(
          I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample.name)
        )
      end
    end
  end
end
