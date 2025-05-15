# frozen_string_literal: true

require 'test_helper'

module Samples
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @sample30 = samples(:sample30)
      @project = projects(:project1)

      @group12 = groups(:group_twelve)
      @subgroup12a = groups(:subgroup_twelve_a)
      @subgroup12b = groups(:subgroup_twelve_b)
      @subgroup12aa = groups(:subgroup_twelve_a_a)
      @project31 = projects(:project31)
      @sample34 = samples(:sample34)
    end

    test 'destroy sample with correct permissions' do
      assert_difference -> { Sample.count } => -1 do
        Samples::DestroyService.new(@project.namespace, @user, { sample: @sample1 }).execute
      end
    end

    test 'destroy sample with incorrect permissions' do
      @user = users(:joan_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::DestroyService.new(@project.namespace, @user, { sample: @sample1 }).execute
      end

      assert_equal ProjectPolicy, exception.policy
      assert_equal :destroy_sample?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.destroy_sample?', name: @project.name),
                   exception.result.message
    end

    test 'valid authorization to destroy sample' do
      assert_authorized_to(:destroy_sample?, @sample1.project, with: ProjectPolicy,
                                                               context: { user: @user }) do
        Samples::DestroyService.new(@project.namespace, @user, { sample: @sample1 }).execute
      end
    end

    test 'metadata summary updated after single sample deletion' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

      assert_no_changes -> { @subgroup12b.reload.metadata_summary } do
        Samples::DestroyService.new(@project31.namespace, @user, { sample: @sample34 }).execute
      end

      assert_equal({}, @project31.namespace.reload.metadata_summary)
      assert_equal({}, @subgroup12aa.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12a.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @group12.reload.metadata_summary)
    end

    test 'multiple destroy with multiple samples and correct permissions' do
      assert_difference -> { Sample.count } => -3 do
        Samples::DestroyService.new(@project.namespace, @user,
                                    { sample_ids: [@sample1.id, @sample2.id, @sample30.id] }).execute
      end
    end

    test 'destroy samples with incorrect permissions' do
      user = users(:joan_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::DestroyService.new(@project.namespace, user,
                                    { sample_ids: [@sample1.id, @sample2.id, @sample30.id] }).execute
      end

      assert_equal ProjectPolicy, exception.policy
      assert_equal :destroy_sample?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.destroy_sample?', name: @project.name),
                   exception.result.message
    end

    test 'metadata summary updated after multiple sample deletion' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      project30 = projects(:project30)
      sample33 = samples(:sample33)

      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

      Projects::Samples::TransferService.new(project30.namespace, @user).execute(@project31.id, [sample33.id])

      assert_equal(
        { 'metadatafield1' => 2, 'metadatafield2' => 2 }, @project31.reload.namespace.metadata_summary
      )

      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12aa.reload.metadata_summary)

      assert_no_changes -> { @subgroup12b.reload.metadata_summary } do
        Samples::DestroyService.new(@project31.namespace, @user, { sample_ids: [sample33.id, @sample34.id] }).execute
      end

      assert_equal({}, @project31.namespace.reload.metadata_summary)
      assert_equal({}, @subgroup12aa.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12a.reload.metadata_summary)
      assert_equal({}, @subgroup12b.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @group12.reload.metadata_summary)
    end

    test 'samples count updated after single sample deletion' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_difference -> { @subgroup12b.reload.samples_count } => 0,
                        -> { @project31.reload.samples.size } => -1,
                        -> { @subgroup12aa.reload.samples_count } => -1,
                        -> { @subgroup12a.reload.samples_count } => -1,
                        -> { @subgroup12b.reload.samples_count } => 0,
                        -> { @group12.reload.samples_count } => -1 do
        Samples::DestroyService.new(@project31.namespace, @user, { sample: @sample34 }).execute
      end
    end

    test 'samples count updated after multiple sample deletion' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      sample35 = samples(:sample35)

      assert_difference -> { @subgroup12b.reload.samples_count } => 0,
                        -> { @project31.reload.samples.size } => -2,
                        -> { @subgroup12aa.reload.samples_count } => -2,
                        -> { @subgroup12a.reload.samples_count } => -2,
                        -> { @subgroup12b.reload.samples_count } => 0,
                        -> { @group12.reload.samples_count } => -2 do
        Samples::DestroyService.new(@project31.namespace, @user, { sample_ids: [@sample34.id, sample35.id] }).execute
      end
    end

    test 'samples deleted from same group' do
      sample32 = samples(:sample32)
      project29 = projects(:project29)

      assert_difference -> { Sample.count } => -2,
                        -> { @subgroup12b.reload.samples_count } => 0,
                        -> { project29.reload.samples.size } => -1,
                        -> { @subgroup12aa.reload.samples_count } => -1,
                        -> { @subgroup12a.reload.samples_count } => -2,
                        -> { @subgroup12b.reload.samples_count } => 0,
                        -> { @group12.reload.samples_count } => -2 do
        Samples::DestroyService.new(@group12, @user, { sample_ids: [sample32.id, @sample34.id] }).execute
      end
    end

    test 'activities for successful group deletion' do
      sample32 = samples(:sample32)

      assert_difference -> { Sample.count } => -2,
                        -> { PublicActivity::Activity.count } => 3 do
        Samples::DestroyService.new(@group12, @user, { sample_ids: [sample32.id, @sample34.id] }).execute
      end

      # verify group activity
      activity = PublicActivity::Activity.where(
        key: 'group.samples.destroy'
      ).order(created_at: :desc).first

      assert_equal 'group.samples.destroy', activity.key
      assert_equal @user, activity.owner
      assert_equal 2, activity.parameters[:samples_deleted_count]
      assert_equal [
        { 'sample_name' => sample32.name, 'sample_puid' => sample32.puid,
          'project_puid' => sample32.project.puid },
        { 'sample_name' => @sample34.name, 'sample_puid' => @sample34.puid,
          'project_puid' => @sample34.project.puid }
      ],
                   activity.extended_details.details['deleted_samples_data']
      assert_equal 'group_samples_destroy', activity.parameters[:action]

      # verify project activity 1
      activity = PublicActivity::Activity.where(
        key: 'namespaces_project_namespace.samples.destroy_multiple'
      ).order(created_at: :desc).second

      assert_equal 'namespaces_project_namespace.samples.destroy_multiple', activity.key
      assert_equal @user, activity.owner
      assert_equal 1, activity.parameters[:samples_deleted_count]
      assert_equal [{ 'sample_name' => sample32.name, 'sample_puid' => sample32.puid }],
                   activity.extended_details.details['deleted_samples_data']
      assert_equal 'project_sample_destroy_multiple', activity.parameters[:action]

      # verify project activity 2
      activity = PublicActivity::Activity.where(
        key: 'namespaces_project_namespace.samples.destroy_multiple'
      ).order(created_at: :desc).first

      assert_equal 'namespaces_project_namespace.samples.destroy_multiple', activity.key
      assert_equal @user, activity.owner
      assert_equal 1, activity.parameters[:samples_deleted_count]
      assert_equal [{ 'sample_name' => @sample34.name, 'sample_puid' => @sample34.puid }],
                   activity.extended_details.details['deleted_samples_data']
      assert_equal 'project_sample_destroy_multiple', activity.parameters[:action]
    end

    test 'only delete group samples with proper permission' do
      # group1 does not have shared owner role within project 28
      group1 = groups(:group_one)
      sample25 = samples(:sample25)
      sample28 = samples(:sample28)

      project25 = projects(:project25)
      project28 = projects(:project28)

      assert_difference -> { Sample.count } => -2,
                        -> { group1.reload.samples_count } => -2,
                        -> { @project.reload.samples.size } => -1,
                        -> { project28.reload.samples_count } => 0,
                        -> { project25.reload.samples.size } => -1 do
        Samples::DestroyService.new(group1, @user, { sample_ids: [@sample1.id, sample25.id, sample28] }).execute
      end
    end

    test 'delete shared group samples with owner shared group role' do
      group_hotel = groups(:group_hotel)
      project_hotel = projects(:projectHotel)
      group = groups(:user30_group_one)
      sample36 = samples(:sample36)
      user = users(:steve_doe)

      assert_difference -> { Sample.count } => -1,
                        -> { group_hotel.reload.samples_count } => -1,
                        -> { project_hotel.reload.samples.size } => -1 do
        Samples::DestroyService.new(group, user, { sample_ids: [sample36.id] }).execute
      end
    end

    test 'delete shared group samples with owner shared project role' do
      project_alpha = projects(:projectAlpha)
      group = groups(:user30_group_one)
      sample_alpha = samples(:sampleAlpha)
      user = users(:steve_doe)

      assert_difference -> { Sample.count } => -1,
                        -> { project_alpha.reload.samples_count } => -1 do
        Samples::DestroyService.new(group, user, { sample_ids: [sample_alpha.id] }).execute
      end
    end

    test 'user with incorrect permission deletes sample within own group' do
      group1 = groups(:group_one)
      user = users(:ryan_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::DestroyService.new(group1, user, { sample_ids: [@sample1.id] }).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :destroy_sample?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.destroy_sample?', name: group1.name),
                   exception.result.message
    end

    test 'incorrect permission if user is not an owner within the group shared as owner' do
      group7 = groups(:group_seven)
      user = users(:user0)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::DestroyService.new(group7, user, { sample_ids: [@sample1.id] }).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :destroy_sample?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.destroy_sample?', name: group7.name),
                   exception.result.message
    end
  end
end
