# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    class BulkUpdateServiceTest < ActiveSupport::TestCase
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

      test 'add metadata to samples within a single project' do
        freeze_time
        payload = { @sample34.name => { 'metadatafield3' => 'value3', 'metadatafield4' => 'value4' },
                    @sample35.id => { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' } }
        metadata_fields = %w[metadatafield1 metadatafield2 metadatafield3 metadatafield4]

        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

        Samples::Metadata::BulkUpdateService.new(@project31.namespace, payload, metadata_fields, @user).execute
        assert_equal(
          { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2', 'metadatafield3' => 'value3',
            'metadatafield4' => 'value4' }, @sample34.reload.metadata
        )
        assert_equal({ 'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                             'updated_at' => DateTime.new(2000, 1, 1) },
                       'metadatafield2' => { 'id' => 1, 'source' => 'analysis',
                                             'updated_at' => DateTime.new(2000, 1, 1) },
                       'metadatafield3' => { 'id' => @user.id, 'source' => 'user',
                                             'updated_at' => Time.current },
                       'metadatafield4' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
                     @sample34.reload.metadata_provenance)

        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, @sample35.reload.metadata)
        assert_equal({ 'metadatafield1' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current },
                       'metadatafield2' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
                     @sample35.reload.metadata_provenance)

        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadatafield3' => 1, 'metadatafield4' => 1 },
                     @project31.namespace.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadatafield3' => 1, 'metadatafield4' => 1  },
                     @subgroup12aa.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3, 'metadatafield3' => 1, 'metadatafield4' => 1  },
                     @subgroup12a.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 4, 'metadatafield2' => 4, 'metadatafield3' => 1, 'metadatafield4' => 1  },
                     @group12.reload.metadata_summary)
      end

      test 'add metadata to samples to multiple projects within a group' do
        freeze_time
        payload = { @sample33.puid => { 'metadatafield3' => 'value3', 'metadatafield4' => 'value4' },
                    @sample35.name => { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' } }
        metadata_fields = %w[metadatafield1 metadatafield2 metadatafield3 metadatafield4]

        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project30.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

        Samples::Metadata::BulkUpdateService.new(@group12, payload, metadata_fields, @user).execute
        assert_equal(
          { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2', 'metadatafield3' => 'value3',
            'metadatafield4' => 'value4' }, @sample33.reload.metadata
        )
        assert_equal({ 'metadatafield1' => { 'id' => @user.id, 'source' => 'user',
                                             'updated_at' => DateTime.new(2000, 1, 1) },
                       'metadatafield2' => { 'id' => @user.id, 'source' => 'user',
                                             'updated_at' => DateTime.new(2000, 1, 1) },
                       'metadatafield3' => { 'id' => @user.id, 'source' => 'user',
                                             'updated_at' => Time.current },
                       'metadatafield4' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
                     @sample33.reload.metadata_provenance)

        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, @sample35.reload.metadata)
        assert_equal({ 'metadatafield1' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current },
                       'metadatafield2' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
                     @sample35.reload.metadata_provenance)

        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield3' => 1, 'metadatafield4' => 1 },
                     @project30.namespace.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 },
                     @project31.namespace.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 },
                     @subgroup12aa.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 },
                     @subgroup12a.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield3' => 1, 'metadatafield4' => 1 },
                     @subgroup12b.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 4, 'metadatafield2' => 4, 'metadatafield3' => 1, 'metadatafield4' => 1 },
                     @group12.reload.metadata_summary)
      end

      test 'metadata does not overwrite analysis metadata' do
        freeze_time
        payload = { @sample34.name => { 'metadatafield1' => 'newvalue1', 'metadatafield2' => 'newvalue2' },
                    @sample35.id => { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' } }
        metadata_fields = %w[metadatafield1 metadatafield2 metadatafield3 metadatafield4]

        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

        Samples::Metadata::BulkUpdateService.new(@project31.namespace, payload, metadata_fields, @user).execute
        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, @sample34.reload.metadata)
        assert_equal({ 'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                             'updated_at' => DateTime.new(2000, 1, 1) },
                       'metadatafield2' => { 'id' => 1, 'source' => 'analysis',
                                             'updated_at' => DateTime.new(2000, 1, 1) } },
                     @sample34.reload.metadata_provenance)

        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, @sample35.reload.metadata)
        assert_equal({ 'metadatafield1' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current },
                       'metadatafield2' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
                     @sample35.reload.metadata_provenance)

        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 },
                     @project31.namespace.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 },
                     @subgroup12aa.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 },
                     @subgroup12a.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 4, 'metadatafield2' => 4 },
                     @group12.reload.metadata_summary)
      end

      test 'add and remove metadata on multiple samples' do
        freeze_time
        payload = { @sample33.name => { 'metadatafield1' => '', 'metadatafield3' => 'sample33value3' },
                    @sample34.puid => { 'metadatafield3' => 'sample34value3', 'metadatafield2' => '' } }
        metadata_fields = %w[metadatafield1 metadatafield2 metadatafield3]

        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project30.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

        Samples::Metadata::BulkUpdateService.new(@group12, payload, metadata_fields, @user).execute

        assert_equal({ 'metadatafield2' => 'value2', 'metadatafield3' => 'sample33value3' }, @sample33.reload.metadata)
        assert_equal({ 'metadatafield2' => { 'id' => @user.id, 'source' => 'user',
                                             'updated_at' => DateTime.new(2000, 1, 1) },
                       'metadatafield3' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
                     @sample33.reload.metadata_provenance)

        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield3' => 'sample34value3' }, @sample34.reload.metadata)
        assert_equal({ 'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                             'updated_at' => DateTime.new(2000, 1, 1) },
                       'metadatafield3' => { 'id' => @user.id, 'source' => 'user',
                                             'updated_at' => Time.current } },
                     @sample34.reload.metadata_provenance)

        assert_equal({ 'metadatafield2' => 1, 'metadatafield3' => 1 }, @project30.namespace.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield3' => 1 },
                     @project31.namespace.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield3' => 1 },
                     @subgroup12aa.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 1, 'metadatafield3' => 1 },
                     @subgroup12a.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadatafield3' => 2 },
                     @group12.reload.metadata_summary)
      end

      test 'sample not within group namespace scope will not be updated' do
        freeze_time
        payload = { @sample33.name => { 'metadatafield3' => 'sample33value3', 'metadatafield4' => 'sample33value4' },
                    @sample34.puid => { 'metadatafield3' => 'sample34value3', 'metadatafield4' => 'sample34value4' } }
        metadata_fields = %w[metadatafield3 metadatafield4]
        sample33_metadata = @sample33.metadata
        sample33_metadata_provenance = @sample33.metadata_provenance
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project30.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

        Samples::Metadata::BulkUpdateService.new(@subgroup12aa, payload, metadata_fields, @user).execute

        assert_equal(sample33_metadata, @sample33.reload.metadata)
        assert_equal(sample33_metadata_provenance,
                     @sample33.reload.metadata_provenance)

        assert_equal(
          { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2', 'metadatafield3' => 'sample34value3',
            'metadatafield4' => 'sample34value4' }, @sample34.reload.metadata
        )
        assert_equal({ 'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                             'updated_at' => DateTime.new(2000, 1, 1) },
                       'metadatafield2' => { 'id' => 1, 'source' => 'analysis',
                                             'updated_at' => DateTime.new(2000, 1, 1) },
                       'metadatafield3' => { 'id' => @user.id, 'source' => 'user',
                                             'updated_at' => Time.current },
                       'metadatafield4' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
                     @sample34.reload.metadata_provenance)

        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 },
                     @project30.namespace.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield3' => 1, 'metadatafield4' => 1 },
                     @project31.namespace.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield3' => 1, 'metadatafield4' => 1 },
                     @subgroup12aa.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadatafield3' => 1, 'metadatafield4' => 1 },
                     @subgroup12a.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 },
                     @subgroup12b.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3, 'metadatafield3' => 1, 'metadatafield4' => 1 },
                     @group12.reload.metadata_summary)
      end

      test 'update sample metadata with valid permission for group namespace' do
        payload = { @sample33.name => { 'metadatafield3' => 'sample33value3', 'metadatafield4' => 'sample33value4' },
                    @sample34.puid => { 'metadatafield3' => 'sample34value3', 'metadatafield4' => 'sample34value4' } }
        metadata_fields = %w[metadatafield3 metadatafield4]

        assert_authorized_to(:update_sample_metadata?, @subgroup12aa, with: GroupPolicy,
                                                                      context: { user: @user }) do
          Samples::Metadata::BulkUpdateService.new(@subgroup12aa, payload, metadata_fields, @user).execute
        end
      end

      test 'update sample metadata without valid permission for group namespace' do
        user = users(:ryan_doe)
        payload = { @sample33.name => { 'metadatafield3' => 'sample33value3', 'metadatafield4' => 'sample33value4' },
                    @sample34.puid => { 'metadatafield3' => 'sample34value3', 'metadatafield4' => 'sample34value4' } }
        metadata_fields = %w[metadatafield3 metadatafield4]

        exception = assert_raises(ActionPolicy::Unauthorized) do
          Samples::Metadata::BulkUpdateService.new(@subgroup12aa, payload, metadata_fields, user).execute
        end

        assert_equal GroupPolicy, exception.policy
        assert_equal :update_sample_metadata?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.group.update_sample_metadata?', name: @subgroup12aa.name),
                     exception.result.message
      end

      test 'update sample metadata with valid permission for project namespace' do
        project_namespace = @project30.namespace
        payload = { @sample33.name => { 'metadatafield3' => 'value3', 'metadatafield4' => 'value4' } }
        metadata_fields = %w[metadatafield3 metadatafield4]

        assert_authorized_to(:update_sample_metadata?, project_namespace, with: Namespaces::ProjectNamespacePolicy,
                                                                          context: { user: @user }) do
          Samples::Metadata::BulkUpdateService.new(project_namespace, payload, metadata_fields, @user).execute
        end
      end

      test 'update sample metadata without valid permission for project namespace' do
        project_namespace = @project30.namespace
        user = users(:ryan_doe)
        payload = { @sample33.name => { 'metadatafield3' => 'value3', 'metadatafield4' => 'value4' } }
        metadata_fields = %w[metadatafield3 metadatafield4]

        exception = assert_raises(ActionPolicy::Unauthorized) do
          Samples::Metadata::BulkUpdateService.new(project_namespace, payload, metadata_fields, user).execute
        end

        assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
        assert_equal :update_sample_metadata?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.update_sample_metadata?',
                            name: project_namespace.name),
                     exception.result.message
      end

      test 'metadata update with sanitized whitespaces' do
        freeze_time
        payload = { @sample34.name => { ' metadata   field       3  ' => '   value3   ',
                                        '  metadata field4   ' => 'value   4' },
                    @sample35.id => { '  metadatafield1   ' => '   value1   ',
                                      'metadatafield2     ' => '   value   2   ' } }
        metadata_fields = ['metadatafield1', 'metadatafield2', 'metadata field 3', 'metadata field4']
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
        assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

        Samples::Metadata::BulkUpdateService.new(@project31.namespace, payload, metadata_fields, @user).execute
        assert_equal(
          { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2', 'metadata field 3' => 'value3',
            'metadata field4' => 'value 4' }, @sample34.reload.metadata
        )
        assert_equal({ 'metadatafield1' => { 'id' => 1, 'source' => 'analysis',
                                             'updated_at' => DateTime.new(2000, 1, 1) },
                       'metadatafield2' => { 'id' => 1, 'source' => 'analysis',
                                             'updated_at' => DateTime.new(2000, 1, 1) },
                       'metadata field 3' => { 'id' => @user.id, 'source' => 'user',
                                               'updated_at' => Time.current },
                       'metadata field4' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
                     @sample34.reload.metadata_provenance)

        assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value 2' }, @sample35.reload.metadata)
        assert_equal({ 'metadatafield1' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current },
                       'metadatafield2' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
                     @sample35.reload.metadata_provenance)

        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadata field4' => 1, 'metadata field 3' => 1 },
                     @project31.namespace.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadata field4' => 1, 'metadata field 3' => 1 },
                     @subgroup12aa.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3, 'metadata field4' => 1, 'metadata field 3' => 1 },
                     @subgroup12a.reload.metadata_summary)
        assert_equal({ 'metadatafield1' => 4, 'metadatafield2' => 4, 'metadata field4' => 1, 'metadata field 3' => 1 },
                     @group12.reload.metadata_summary)
      end

      ####################

      # test 'sample does not belong to project' do
      #   params = { 'metadata' => { 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' } }
      #   project = projects(:projectA)
      #   metadata_changes = Samples::Metadata::UpdateService.new(project, @sample33, @user, params).execute

      #   assert_equal(
      #     { added: [], updated: [], deleted: [], not_updated: %w[metadatafield1 metadatafield2],
      #       unchanged: [] }, metadata_changes
      #   )
      #   assert @sample33.errors.full_messages.include?(
      #     I18n.t('services.samples.metadata.sample_does_not_belong_to_project', sample_name: @sample33.name,
      #                                                                           project_name: project.name)
      #   )
      # end

      # test 'metadata is nil' do
      #   metadata_changes = Samples::Metadata::UpdateService.new(@project30, @sample33, @user, {}).execute

      #   assert_equal({ added: [], updated: [], deleted: [], not_updated: [], unchanged: [] }, metadata_changes)
      #   assert @sample33.errors.full_messages.include?(
      #     I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample33.name)
      #   )
      # end

      # test 'metadata is empty hash' do
      #   params = { 'metadata' => {} }
      #   metadata_changes = Samples::Metadata::UpdateService.new(@project30, @sample33, @user, params).execute

      #   assert_equal({ added: [], updated: [], deleted: [], not_updated: [], unchanged: [] }, metadata_changes)
      #   assert @sample33.errors.full_messages.include?(
      #     I18n.t('services.samples.metadata.empty_metadata', sample_name: @sample33.name)
      #   )
      # end

      # test 'metadata summary updates parents but not projects/groups of same level on different branch' do
      #   # Reference group/projects descendants tree:
      #   # group12 < subgroup12b (project30 > sample 33)
      #   #    |
      #   #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)

      #   params1 = { 'metadata' => { 'metadatafield4' => 'value4' } }

      #   assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

      #   Samples::Metadata::UpdateService.new(@project31, @sample34, @user, params1).execute

      #   assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield4' => 1 },
      #                @project31.namespace.reload.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.reload.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield4' => 1 },
      #                @subgroup12aa.reload.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadatafield4' => 1 },
      #                @subgroup12a.reload.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3, 'metadatafield4' => 1 },
      #                @group12.reload.metadata_summary)

      #   params2 = { 'metadata' => { 'metadatafield5' => 'value5' } }

      #   Samples::Metadata::UpdateService.new(@project30, @sample33, @user, params2).execute

      #   assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield5' => 1 },
      #                @project30.namespace.reload.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield5' => 1 },
      #                @subgroup12b.reload.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield4' => 1 },
      #                @subgroup12aa.reload.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadatafield4' => 1 },
      #                @subgroup12a.reload.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3, 'metadatafield4' => 1, 'metadatafield5' => 1 },
      #                @group12.reload.metadata_summary)

      #   params3 = { 'metadata' => { 'metadatafield2' => '' } }

      #   Samples::Metadata::UpdateService.new(@project29, @sample32, @user, params3).execute

      #   assert_equal({ 'metadatafield1' => 1 }, @project29.namespace.reload.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield5' => 1 },
      #                @subgroup12b.reload.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield4' => 1 },
      #                @subgroup12aa.reload.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 1, 'metadatafield4' => 1 },
      #                @subgroup12a.reload.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 2, 'metadatafield4' => 1, 'metadatafield5' => 1 },
      #                @group12.reload.metadata_summary)
      # end

      # test 'user namespace metadata summary does not update' do
      #   freeze_time
      #   params = { 'metadata' => { 'metadatafield4' => 'value4' } }
      #   project = projects(:john_doe_project2)
      #   sample = samples(:sample24)
      #   namespace = namespaces_user_namespaces(:john_doe_namespace)

      #   Samples::Metadata::UpdateService.new(project, sample, @user, params).execute

      #   assert_equal({}, namespace.reload.metadata_summary)
      #   assert_equal({ 'metadatafield4' => 'value4' }, sample.metadata)
      #   assert_equal({ 'metadatafield4' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
      #                sample.metadata_provenance)
      #   assert_equal({ 'metadatafield4' => 1 }, project.namespace.reload.metadata_summary)
      # end

      # test 'metadata with whitespaces are sanitized' do
      #   freeze_time
      #   params = { 'metadata' => { ' metadata   field   1 ' => ' value 1 ', ' metadata field2 ' => ' value   2 ' } }

      #   assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
      #   assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

      #   metadata_changes = Samples::Metadata::UpdateService.new(@project31, @sample35, @user, params).execute
      #   assert_equal({ 'metadata field 1' => 'value 1', 'metadata field2' => 'value 2' }, @sample35.metadata)
      #   assert_equal({ 'metadata field 1' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current },
      #                  'metadata field2' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
      #                @sample35.metadata_provenance)
      #   assert_equal({ added: ['metadata field 1', 'metadata field2'], updated: [], deleted: [],
      #                  not_updated: [], unchanged: [] }, metadata_changes)

      #   assert_equal(
      #     { 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadata field 1' => 1,
      #       'metadata field2' => 1 }, @project31.namespace.reload.metadata_summary
      #   )
      #   assert_equal(
      #     { 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadata field 1' => 1,
      #       'metadata field2' => 1 }, @subgroup12aa.reload.metadata_summary
      #   )
      #   assert_equal(
      #     { 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadata field 1' => 1,
      #       'metadata field2' => 1 }, @subgroup12a.reload.metadata_summary
      #   )
      #   assert_equal(
      #     { 'metadatafield1' => 3, 'metadatafield2' => 3, 'metadata field 1' => 1,
      #       'metadata field2' => 1 }, @group12.reload.metadata_summary
      #   )
      # end
    end
  end
end
