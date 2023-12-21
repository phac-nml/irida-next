# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    class UpdateServiceTest < ActiveSupport::TestCase
      def setup
        @user = users(:john_doe)
        @sample32 = samples(:sample32)
        @sample33 = samples(:sample33)
        @sample34 = samples(:sample34)
        @sample35 = samples(:sample35)
        @project29 = projects(:project29)
        @project30 = projects(:project30)
        @project31 = projects(:project31)
        @group12 = groups(:group_twelve)
        @subgroup12a = groups(:subgroup_twelve_a)
        @subgroup12b = groups(:subgroup_twelve_b)
        @subgroup12aa = groups(:subgroup_twelve_a_a)
      end

      test 'update sample metadata with sample containing no existing metadata and user in metadata provenanc' do
        params = { 'metadata' => { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' } }
        metadata_fields_update_status = Samples::Metadata::UpdateService.new(@project29, @sample32, @user,
                                                                             params).execute
        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, @sample32.metadata)
        assert_equal({ 'metadatafield1' => { 'id' => @user.id, 'source' => 'user' },
                       'metadatafield2' => { 'id' => @user.id, 'source' => 'user' } },
                     @sample32.metadata_provenance)
        assert_equal({ updated: %w[metadatafield1 metadatafield2], not_updated: [] }, metadata_fields_update_status)

        @project29.reload
        @subgroup12a.reload
        @group12.reload
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project29.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)
      end

      test 'update sample metadata with sample containing no existing metadata and analysis in metadata provenance' do
        params = { 'metadata' => { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, 'analysis_id' => 2 }
        metadata_fields_update_status = Samples::Metadata::UpdateService.new(@project31, @sample35, @user,
                                                                             params).execute

        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, @sample35.metadata)
        assert_equal({ 'metadatafield1' => { 'id' => 2, 'source' => 'analysis' },
                       'metadatafield2' => { 'id' => 2, 'source' => 'analysis' } },
                     @sample35.metadata_provenance)
        assert_equal({ updated: %w[metadatafield1 metadatafield2], not_updated: [] }, metadata_fields_update_status)

        @project31.reload
        @subgroup12aa.reload
        @subgroup12a.reload
        @group12.reload
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @project31.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @subgroup12aa.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @subgroup12a.metadata_summary)
        assert_equal({ 'metadatafield1' => 4, 'metadatafield2' => 4 }, @group12.metadata_summary)
      end

      test 'update sample metadata merge with new metadata and analysis overwritting user' do
        params = { 'metadata' => { 'metadatafield1' => 'value4', 'metadatafield3' => 'value3' }, 'analysis_id' => 10 }
        metadata_fields_update_status = Samples::Metadata::UpdateService.new(@project30, @sample33, @user,
                                                                             params).execute

        assert_equal({ 'metadatafield1' => 'value4', 'metadatafield2' => 'value2', 'metadatafield3' => 'value3' },
                     @sample33.metadata)
        assert_equal({ 'metadatafield1' => { 'id' => 10, 'source' => 'analysis' },
                       'metadatafield2' => { 'id' => 1, 'source' => 'user' },
                       'metadatafield3' => { 'id' => 10, 'source' => 'analysis' } },
                     @sample33.metadata_provenance)
        assert_equal({ updated: %w[metadatafield1 metadatafield3], not_updated: [] }, metadata_fields_update_status)

        @project30.reload
        @subgroup12b.reload
        @group12.reload
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield3' => 1 },
                     @project30.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield3' => 1 },
                     @subgroup12b.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3, 'metadatafield3' => 1 },
                     @group12.metadata_summary)
      end

      test 'update sample metadata merge with new metadata and user overwritting user' do
        params = { 'metadata' => { 'metadatafield1' => 'value4', 'metadatafield3' => 'value3' } }
        metadata_fields_update_status = Samples::Metadata::UpdateService.new(@project30, @sample33, @user,
                                                                             params).execute

        assert_equal({ 'metadatafield1' => 'value4', 'metadatafield2' => 'value2', 'metadatafield3' => 'value3' },
                     @sample33.metadata)
        assert_equal({ 'metadatafield1' => { 'id' => @user.id, 'source' => 'user' },
                       'metadatafield2' => { 'id' => 1, 'source' => 'user' },
                       'metadatafield3' => { 'id' => @user.id, 'source' => 'user' } },
                     @sample33.metadata_provenance)
        assert_equal({ updated: %w[metadatafield1 metadatafield3], not_updated: [] }, metadata_fields_update_status)

        @project30.reload
        @subgroup12b.reload
        @group12.reload
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield3' => 1 },
                     @project30.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield3' => 1 },
                     @subgroup12b.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3, 'metadatafield3' => 1 },
                     @group12.metadata_summary)
      end

      test 'update sample metadata merge with new metadata and user unable to overwrite analysis' do
        params = { 'metadata' => { 'metadatafield1' => 'value4', 'metadatafield3' => 'value3' } }
        metadata_fields_update_status = Samples::Metadata::UpdateService.new(@project31, @sample34, @user,
                                                                             params).execute

        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2', 'metadatafield3' => 'value3' },
                     @sample34.metadata)
        assert_equal({ 'metadatafield1' => { 'id' => 1, 'source' => 'analysis' },
                       'metadatafield2' => { 'id' => 1, 'source' => 'analysis' },
                       'metadatafield3' => { 'id' => @user.id, 'source' => 'user' } },
                     @sample34.metadata_provenance)
        assert_equal({ updated: %w[metadatafield3], not_updated: %w[metadatafield1] }, metadata_fields_update_status)
        assert @sample34.errors.full_messages.include?(
          I18n.t('services.samples.metadata.user_cannot_update_metadata',
                 sample_name: @sample34.name,
                 metadata_fields: 'metadatafield1')
        )

        @project31.reload
        @subgroup12aa.reload
        @subgroup12a.reload
        @group12.reload
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield3' => 1 },
                     @project31.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadatafield3' => 1 },
                     @subgroup12aa.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadatafield3' => 1 },
                     @subgroup12a.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3, 'metadatafield3' => 1 },
                     @group12.metadata_summary)
      end

      test 'remove metadata key with user' do
        params = { 'metadata' => { 'metadatafield2' => '' } }
        metadata_fields_update_status = Samples::Metadata::UpdateService.new(@project31, @sample34, @user,
                                                                             params).execute

        assert_equal({ 'metadatafield1' => 'value1' }, @sample34.metadata)
        assert_equal({ 'metadatafield1' => { 'id' => 1, 'source' => 'analysis' } }, @sample34.metadata_provenance)
        assert_equal({ updated: %w[metadatafield2], not_updated: [] }, metadata_fields_update_status)

        @project31.reload
        @subgroup12aa.reload
        @subgroup12a.reload
        @group12.reload
        assert_equal({ 'metadatafield1' => 1 },
                     @project31.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 1 },
                     @subgroup12aa.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 1 },
                     @subgroup12a.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 2 },
                     @group12.metadata_summary)
      end

      test 'remove metadata key with analysis' do
        params = { 'metadata' => { 'metadatafield1' => '' }, 'analysis_id' => 1 }
        metadata_fields_update_status = Samples::Metadata::UpdateService.new(@project30, @sample33, @user,
                                                                             params).execute

        assert_equal({ 'metadatafield2' => 'value2' }, @sample33.metadata)
        assert_equal({ 'metadatafield2' => { 'id' => 1, 'source' => 'user' } }, @sample33.metadata_provenance)
        assert_equal({ updated: %w[metadatafield1], not_updated: [] }, metadata_fields_update_status)

        @project30.reload
        @subgroup12b.reload
        @group12.reload
        assert_equal({ 'metadatafield2' => 1 },
                     @project30.namespace.metadata_summary)
        assert_equal({ 'metadatafield2' => 1 },
                     @subgroup12b.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 3 },
                     @group12.metadata_summary)
      end

      test 'update sample metadata with valid permission' do
        params = { 'metadata' => { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' } }

        assert_authorized_to(:update_sample?, @sample33.project, with: ProjectPolicy,
                                                                 context: { user: @user }) do
          Samples::Metadata::UpdateService.new(@project30, @sample33, @user, params).execute
        end
      end

      test 'update sample metadata without permission to update sample' do
        user = users(:ryan_doe)
        params = { 'metadata' => { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' } }

        exception = assert_raises(ActionPolicy::Unauthorized) do
          assert_empty Samples::Metadata::UpdateService.new(@project30, @sample33, user, params).execute
        end

        assert_equal ProjectPolicy, exception.policy
        assert_equal :update_sample?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.project.update_sample?', name: @sample33.project.name),
                     exception.result.message
      end

      test 'sample does not belong to project' do
        params = { 'metadata' => { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' } }
        project = projects(:projectA)
        assert_no_changes -> { @sample33 } do
          assert_nil Samples::Metadata::UpdateService.new(project, @sample33, @user, params).execute
        end
        assert @sample33.errors.full_messages.include?(
          I18n.t('services.samples.metadata.sample_does_not_belong_to_project', sample_name: @sample33.name,
                                                                                project_name: project.name)
        )
      end

      test 'metadata is nil' do
        assert_no_changes -> { @sample } do
          assert_nil Samples::Metadata::UpdateService.new(@project30, @sample33, @user, {}).execute
        end
        assert @sample33.errors.full_messages.include?(
          I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample33.name)
        )
      end

      test 'metadata is empty hash' do
        params = { 'metadata' => {} }
        assert_no_changes -> { @sample } do
          assert_nil Samples::Metadata::UpdateService.new(@project30, @sample33, @user, params).execute
        end
        assert @sample33.errors.full_messages.include?(
          I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample33.name)
        )
      end

      test 'metadata summary updates parents but not projects/groups of same level on different branch' do
        params1 = { 'metadata' => { 'metadatafield4' => 'value4' } }
        assert_no_changes @subgroup12b.metadata_summary do
          Samples::Metadata::UpdateService.new(@project31, @sample34, @user, params1).execute
        end

        @project31.reload
        @subgroup12b.reload
        @subgroup12aa.reload
        @subgroup12a.reload
        @group12.reload
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield4' => 1 },
                     @project31.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadatafield4' => 1 },
                     @subgroup12aa.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadatafield4' => 1 },
                     @subgroup12a.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3, 'metadatafield4' => 1 },
                     @group12.metadata_summary)

        params2 = { 'metadata' => { 'metadatafield5' => 'value5' } }

        assert_no_changes -> { @subgroup12a.metadata_summary } do
          assert_no_changes -> { @subgroup12aa.metadata_summary } do
            Samples::Metadata::UpdateService.new(@project30, @sample33, @user, params2).execute
          end
        end

        @project31.reload
        @subgroup12b.reload
        @subgroup12aa.reload
        @subgroup12a.reload
        @group12.reload
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield5' => 1 },
                     @project30.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield5' => 1 },
                     @subgroup12b.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3, 'metadatafield4' => 1, 'metadatafield5' => 1 },
                     @group12.metadata_summary)

        params3 = { 'metadata' => { 'metadatafield2' => '' } }

        assert_no_changes -> { @subgroup12b.metadata_summary } do
          assert_no_changes -> { @subgroup12aa.metadata_summary } do
            Samples::Metadata::UpdateService.new(@project29, @sample32, @user, params3).execute
          end
        end

        @project31.reload
        @subgroup12b.reload
        @subgroup12aa.reload
        @subgroup12a.reload
        @group12.reload

        assert_equal({ 'metadatafield1' => 1 },
                     @project29.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 1, 'metadatafield4' => 1 },
                     @subgroup12a.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 2, 'metadatafield4' => 1, 'metadatafield5' => 1 },
                     @group12.metadata_summary)
      end

      test 'user namespace metadata summary does not update' do
        params = { 'metadata' => { 'metadatafield4' => 'value4' } }
        project = projects(:john_doe_project2)
        sample = samples(:sample24)
        namespace = namespaces_user_namespaces(:john_doe_namespace)

        assert_no_changes namespace.metadata_summary do
          Samples::Metadata::UpdateService.new(project, sample, @user, params).execute
        end

        assert_equal({ 'metadatafield4' => 'value4' }, sample.metadata)
        assert_equal({ 'metadatafield4' => { 'id' => @user.id, 'source' => 'user' } }, sample.metadata_provenance)
        assert_equal({ 'metadatafield4' => 1 }, project.namespace.metadata_summary)
      end
    end
  end
end
