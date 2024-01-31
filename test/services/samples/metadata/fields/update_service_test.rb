# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    module Fields
      class UpdateServiceTest < ActiveSupport::TestCase
        def setup
          @user = users(:john_doe)
          @sample32 = samples(:sample32)
          @project29 = projects(:project29)
          @project30 = projects(:project30)
          @group12 = groups(:group_twelve)
          @subgroup12a = groups(:subgroup_twelve_a)
        end

        test 'edit metadata key' do
          freeze_time
          params = { 'edit_field' => { 'key' => { 'metadatafield1' => 'metadatafield3' },
                                       'value' => { 'value1' => 'value1' } } }

          assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, @sample32.metadata)
          assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project29.namespace.metadata_summary)
          assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
          assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

          metadata_changes = Samples::Metadata::Fields::UpdateService.new(@project29, @sample32, @user, params).execute

          assert_equal({ 'metadatafield2' => 'value2', 'metadatafield3' => 'value1' }, @sample32.metadata)
          assert_equal({ 'metadatafield2' => { 'id' => @user.id, 'source' => 'user',
                                               'updated_at' => '2000-01-01T00:00:00.000+00:00' },
                         'metadatafield3' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
                       @sample32.metadata_provenance)
          assert_equal({ added: %w[metadatafield3], updated: [], deleted: %w[metadatafield1],
                         not_updated: [] }, metadata_changes)
          assert_equal({ 'metadatafield2' => 1, 'metadatafield3' => 1 },
                       @project29.namespace.reload.metadata_summary)
          assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 2, 'metadatafield3' => 1 },
                       @subgroup12a.reload.metadata_summary)
          assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 3, 'metadatafield3' => 1 },
                       @group12.reload.metadata_summary)
        end

        test 'edit metadata value' do
          freeze_time
          params = { 'edit_field' => { 'key' => { 'metadatafield1' => 'metadatafield1' },
                                       'value' => { 'value1' => 'newvalue1' } } }

          assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, @sample32.metadata)
          assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project29.namespace.metadata_summary)
          assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
          assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

          metadata_changes = Samples::Metadata::Fields::UpdateService.new(@project29, @sample32, @user, params).execute

          assert_equal({ 'metadatafield1' => 'newvalue1', 'metadatafield2' => 'value2' }, @sample32.metadata)
          assert_equal({ 'metadatafield1' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current },
                         'metadatafield2' => { 'id' => @user.id, 'source' => 'user',
                                               'updated_at' => '2000-01-01T00:00:00.000+00:00' } },
                       @sample32.metadata_provenance)
          assert_equal({ added: [], updated: %w[metadatafield1], deleted: [], not_updated: [] }, metadata_changes)
          assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project29.namespace.metadata_summary)
          assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
          assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)
        end

        test 'edit metadata key and value' do
          freeze_time
          params = { 'edit_field' => { 'key' => { 'metadatafield1' => 'metadatafield3' },
                                       'value' => { 'value1' => 'newvalue1' } } }

          assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, @sample32.metadata)
          assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project29.namespace.metadata_summary)
          assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
          assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

          metadata_changes = Samples::Metadata::Fields::UpdateService.new(@project29, @sample32, @user, params).execute

          assert_equal({ 'metadatafield2' => 'value2', 'metadatafield3' => 'newvalue1' }, @sample32.metadata)
          assert_equal({ 'metadatafield2' => { 'id' => @user.id, 'source' => 'user',
                                               'updated_at' => '2000-01-01T00:00:00.000+00:00' },
                         'metadatafield3' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
                       @sample32.metadata_provenance)
          assert_equal({ added: %w[metadatafield3], updated: [], deleted: %w[metadatafield1],
                         not_updated: [] }, metadata_changes)
          assert_equal({ 'metadatafield2' => 1, 'metadatafield3' => 1 },
                       @project29.namespace.reload.metadata_summary)
          assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 2, 'metadatafield3' => 1 },
                       @subgroup12a.reload.metadata_summary)
          assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 3, 'metadatafield3' => 1 },
                       @group12.reload.metadata_summary)
        end

        test 'update sample metadata with valid permission' do
          params = { 'edit_field' => { 'key' => { 'metadatafield1' => 'metadatafield3' },
                                       'value' => { 'value1' => 'value1' } } }

          assert_authorized_to(:update_sample?, @sample32.project, with: ProjectPolicy,
                                                                   context: { user: @user }) do
            Samples::Metadata::Fields::UpdateService.new(@project29, @sample32, @user, params).execute
          end
        end

        test 'update sample metadata without permission to update sample' do
          user = users(:ryan_doe)
          params = { 'edit_field' => { 'key' => { 'metadatafield1' => 'metadatafield3' },
                                       'value' => { 'value1' => 'value1' } } }

          exception = assert_raises(ActionPolicy::Unauthorized) do
            Samples::Metadata::Fields::UpdateService.new(@project29, @sample32, user, params).execute
          end

          assert_equal ProjectPolicy, exception.policy
          assert_equal :update_sample?, exception.rule
          assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
          assert_equal I18n.t(:'action_policy.policy.project.update_sample?', name: @sample32.project.name),
                       exception.result.message
        end

        test 'sample does not belong to project' do
          params = { 'edit_field' => { 'key' => { 'metadatafield1' => 'metadatafield3' },
                                       'value' => { 'value1' => 'value1' } } }

          Samples::Metadata::Fields::UpdateService.new(@project30, @sample32, @user, params).execute

          assert @sample32.errors.full_messages.include?(
            I18n.t('services.samples.metadata.fields.sample_does_not_belong_to_project', sample_name: @sample32.name,
                                                                                         project_name: @project30.name)
          )
        end

        test 'metadata was not changed' do
          params = { 'edit_field' => { 'key' => { 'metadatafield1' => 'metadatafield1' },
                                       'value' => { 'value1' => 'value1' } } }

          Samples::Metadata::Fields::UpdateService.new(@project29, @sample32, @user, params).execute

          assert @sample32.errors.full_messages.include?(
            I18n.t('services.samples.metadata.edit_fields.metadata_was_not_changed')
          )
        end

        test 'edit metadata key to key that already exists' do
          params = { 'edit_field' => { 'key' => { 'metadatafield1' => 'metadatafield2' },
                                       'value' => { 'value1' => 'value1' } } }

          Samples::Metadata::Fields::UpdateService.new(@project29, @sample32, @user, params).execute

          assert @sample32.errors.full_messages.include?(
            I18n.t('services.samples.metadata.edit_fields.key_exists', key: 'metadatafield2')
          )
        end
      end
    end
  end
end
