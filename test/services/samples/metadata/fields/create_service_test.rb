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

        test 'add metadata' do
          freeze_time
          params = { 'metadatafield3' => 'value3' }

          assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, @sample32.metadata)
          assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project29.namespace.metadata_summary)
          assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
          assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

          create_metadata_fields = Samples::Metadata::Fields::CreateService.new(@project29, @sample32, @user,
                                                                                params).execute

          assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2', 'metadatafield3' => 'value3' },
                       @sample32.metadata)
          assert_equal({ 'metadatafield1' => { 'id' => @user.id, 'source' => 'user',
                                               'updated_at' => '2000-01-01T00:00:00.000+00:00' },
                         'metadatafield2' => { 'id' => @user.id, 'source' => 'user',
                                               'updated_at' => '2000-01-01T00:00:00.000+00:00' },
                         'metadatafield3' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
                       @sample32.metadata_provenance)
          assert_equal({ added_keys: %w[metadatafield3], existing_keys: [] }, create_metadata_fields)
          assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield3' => 1 },
                       @project29.namespace.reload.metadata_summary)
          assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadatafield3' => 1 },
                       @subgroup12a.reload.metadata_summary)
          assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3, 'metadatafield3' => 1 },
                       @group12.reload.metadata_summary)
        end

        test 'add metadata with existing key' do
          freeze_time
          params = { 'metadatafield1' => 'value3' }

          assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, @sample32.metadata)
          assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project29.namespace.metadata_summary)
          assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
          assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

          assert_no_changes -> { @sample32.metadata } do
            assert_no_changes -> { @sample32.metadata_provenance } do
              assert_no_changes -> { @project29.namespace.reload.metadata_summary } do
                assert_no_changes -> { @subgroup12a.reload.metadata_summary } do
                  assert_no_changes -> { @group12.reload.metadata_summary } do
                    Samples::Metadata::Fields::CreateService.new(@project29, @sample32, @user, params).execute
                  end
                end
              end
            end
          end
        end

        test 'add metadata with both new and existing keys' do
          freeze_time
          params = { 'metadatafield1' => 'newvalue1', 'metadatafield2' => 'newvalue2', 'metadatafield3' => 'value3',
                     'metadatafield4' => 'value4' }

          assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, @sample32.metadata)
          assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project29.namespace.metadata_summary)
          assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
          assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

          create_metadata_fields = Samples::Metadata::Fields::CreateService.new(@project29, @sample32, @user,
                                                                                params).execute

          assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2', 'metadatafield3' => 'value3',
                         'metadatafield4' => 'value4' },
                       @sample32.metadata)
          assert_equal({ 'metadatafield1' => { 'id' => @user.id, 'source' => 'user',
                                               'updated_at' => '2000-01-01T00:00:00.000+00:00' },
                         'metadatafield2' => { 'id' => @user.id, 'source' => 'user',
                                               'updated_at' => '2000-01-01T00:00:00.000+00:00' },
                         'metadatafield3' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current },
                         'metadatafield4' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
                       @sample32.metadata_provenance)
          assert_equal({ added_keys: %w[metadatafield3 metadatafield4],
                         existing_keys: %w[metadatafield1 metadatafield2] }, create_metadata_fields)
          assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadatafield3' => 1, 'metadatafield4' => 1 },
                       @project29.namespace.reload.metadata_summary)
          assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadatafield3' => 1, 'metadatafield4' => 1 },
                       @subgroup12a.reload.metadata_summary)
          assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3, 'metadatafield3' => 1, 'metadatafield4' => 1 },
                       @group12.reload.metadata_summary)
        end

        test 'add metadata with valid permission' do
          params = { 'metadatafield3' => 'value3' }

          assert_authorized_to(:update_sample?, @sample32.project, with: ProjectPolicy,
                                                                   context: { user: @user }) do
            Samples::Metadata::Fields::CreateService.new(@project29, @sample32, @user, params).execute
          end
        end

        test 'add metadata without permission to update sample' do
          user = users(:ryan_doe)
          params = { 'metadatafield3' => 'value3' }

          exception = assert_raises(ActionPolicy::Unauthorized) do
            Samples::Metadata::Fields::CreateService.new(@project29, @sample32, user, params).execute
          end

          assert_equal ProjectPolicy, exception.policy
          assert_equal :update_sample?, exception.rule
          assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
          assert_equal I18n.t(:'action_policy.policy.project.update_sample?', name: @sample32.project.name),
                       exception.result.message
        end

        test 'sample does not belong to project' do
          params = { 'metadatafield3' => 'value3' }

          Samples::Metadata::Fields::CreateService.new(@project30, @sample32, @user, params).execute

          assert @sample32.errors.full_messages.include?(
            I18n.t('services.samples.metadata.fields.sample_does_not_belong_to_project', sample_name: @sample32.name,
                                                                                         project_name: @project30.name)
          )
        end

        test 'add metadata with whitespaces' do
          freeze_time
          params = { 'metadatafield1    ' => 'newvalue1',
                     '     metadatafield2' => 'newvalue2',
                     '   metadata    field3   ' => 'value   3',
                     ' metadata field 4 ' => '    value    4   ' }

          assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2' }, @sample32.metadata)
          assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project29.namespace.metadata_summary)
          assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
          assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

          create_metadata_fields = Samples::Metadata::Fields::CreateService.new(@project29, @sample32, @user,
                                                                                params).execute

          assert_equal({ 'metadatafield1' => 'value1', 'metadatafield2' => 'value2', 'metadata field3' => 'value 3',
                         'metadata field 4' => 'value 4' },
                       @sample32.metadata)
          assert_equal({ 'metadatafield1' => { 'id' => @user.id, 'source' => 'user',
                                               'updated_at' => '2000-01-01T00:00:00.000+00:00' },
                         'metadatafield2' => { 'id' => @user.id, 'source' => 'user',
                                               'updated_at' => '2000-01-01T00:00:00.000+00:00' },
                         'metadata field3' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current },
                         'metadata field 4' => { 'id' => @user.id, 'source' => 'user', 'updated_at' => Time.current } },
                       @sample32.metadata_provenance)
          assert_equal({ added_keys: ['metadata field3', 'metadata field 4'],
                         existing_keys: %w[metadatafield1 metadatafield2] }, create_metadata_fields)
          assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1, 'metadata field3' => 1,
                         'metadata field 4' => 1 },
                       @project29.namespace.reload.metadata_summary)
          assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2, 'metadata field3' => 1,
                         'metadata field 4' => 1 },
                       @subgroup12a.reload.metadata_summary)
          assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3, 'metadata field3' => 1,
                         'metadata field 4' => 1 },
                       @group12.reload.metadata_summary)
        end
      end
    end
  end
end
