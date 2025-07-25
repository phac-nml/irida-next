# frozen_string_literal: true

require 'test_helper'

module Groups
  module Samples
    class DestroyServiceTest < ActiveSupport::TestCase
      def setup
        @user = users(:john_doe)
        @sample1 = samples(:sample1)
        @sample32 = samples(:sample32)
        @sample34 = samples(:sample34)
        @project = projects(:project1)
        @group1 = groups(:group_one)
        @group12 = groups(:group_twelve)
        @subgroup12a = groups(:subgroup_twelve_a)
        @subgroup12b = groups(:subgroup_twelve_b)
        @subgroup12aa = groups(:subgroup_twelve_a_a)
      end

      test 'samples deleted from same group' do
        project29 = projects(:project29)

        assert_difference -> { Sample.count } => -2,
                          -> { @subgroup12b.reload.samples_count } => 0,
                          -> { project29.reload.samples.size } => -1,
                          -> { @subgroup12aa.reload.samples_count } => -1,
                          -> { @subgroup12a.reload.samples_count } => -2,
                          -> { @subgroup12b.reload.samples_count } => 0,
                          -> { @group12.reload.samples_count } => -2 do
          Groups::Samples::DestroyService.new(@group12, @user, { sample_ids: [@sample32.id, @sample34.id] }).execute
        end
      end

      test 'activities for successful group deletion' do
        assert_difference -> { Sample.count } => -2,
                          -> { PublicActivity::Activity.count } => 3 do
          Groups::Samples::DestroyService.new(@group12, @user,
                                              { sample_ids: [@sample32.id, @sample34.id] }).execute
        end

        # verify group activity
        activity = PublicActivity::Activity.where(
          key: 'group.samples.destroy'
        ).order(created_at: :desc).first

        assert_equal 'group.samples.destroy', activity.key
        assert_equal @user, activity.owner
        assert_equal 2, activity.parameters[:samples_deleted_count]
        assert_equal [
          { 'sample_name' => @sample32.name, 'sample_puid' => @sample32.puid,
            'project_name' => @sample32.project.name, 'project_puid' => @sample32.project.puid },
          { 'sample_name' => @sample34.name, 'sample_puid' => @sample34.puid,
            'project_name' => @sample34.project.name, 'project_puid' => @sample34.project.puid }
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
        assert_equal [{ 'sample_name' => @sample32.name, 'sample_puid' => @sample32.puid }],
                     activity.extended_details.details['deleted_samples_data']
        assert_equal 'sample_destroy_multiple', activity.parameters[:action]

        # verify project activity 2
        activity = PublicActivity::Activity.where(
          key: 'namespaces_project_namespace.samples.destroy_multiple'
        ).order(created_at: :desc).first

        assert_equal 'namespaces_project_namespace.samples.destroy_multiple', activity.key
        assert_equal @user, activity.owner
        assert_equal 1, activity.parameters[:samples_deleted_count]
        assert_equal [{ 'sample_name' => @sample34.name, 'sample_puid' => @sample34.puid }],
                     activity.extended_details.details['deleted_samples_data']
        assert_equal 'sample_destroy_multiple', activity.parameters[:action]
      end

      test 'only delete group samples with proper permission' do
        # group1 does not have shared owner role within project 28
        sample25 = samples(:sample25)
        sample28 = samples(:sample28)

        project25 = projects(:project25)
        project28 = projects(:project28)

        assert_difference -> { Sample.count } => -2,
                          -> { @group1.reload.samples_count } => -2,
                          -> { @project.reload.samples.size } => -1,
                          -> { project28.reload.samples_count } => 0,
                          -> { project25.reload.samples.size } => -1 do
          Groups::Samples::DestroyService.new(@group1, @user,
                                              { sample_ids: [@sample1.id, sample25.id, sample28] }).execute
        end
      end

      test 'delete shared group samples with owner shared group role' do
        group = groups(:group_sample_actions)
        user = users(:sample_actions_doe)
        sample = samples(:sample69)
        shared_group = groups(:shared_group_sample_actions_owner)
        shared_project = projects(:projectSharedGroupSampleActionsOwner)

        assert_difference -> { Sample.count } => -1,
                          -> { shared_group.reload.samples_count } => -1,
                          -> { shared_project.reload.samples.size } => -1 do
          Groups::Samples::DestroyService.new(group, user, { sample_ids: [sample.id] }).execute
        end
      end

      test 'delete shared group samples with owner shared project role' do
        project = projects(:projectSharedGroupSampleActionsOwner)
        group = groups(:subgroup_sample_actions)
        user = users(:subgroup_sample_actions_doe)
        sample = samples(:sample69)

        assert_difference -> { Sample.count } => -1,
                          -> { project.reload.samples_count } => -1 do
          Groups::Samples::DestroyService.new(group, user,
                                              { sample_ids: [sample.id] }).execute
        end
      end

      test 'user with incorrect permission deletes sample within own group' do
        user = users(:ryan_doe)

        exception = assert_raises(ActionPolicy::Unauthorized) do
          Groups::Samples::DestroyService.new(@group1, user, { sample_ids: [@sample1.id] }).execute
        end

        assert_equal GroupPolicy, exception.policy
        assert_equal :destroy_sample?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.group.destroy_sample?', name: @group1.name),
                     exception.result.message
      end

      test 'incorrect permission if user is not an owner within the group shared as owner' do
        group7 = groups(:group_seven)
        user = users(:user0)

        exception = assert_raises(ActionPolicy::Unauthorized) do
          Groups::Samples::DestroyService.new(group7, user, { sample_ids: [@sample1.id] }).execute
        end

        assert_equal GroupPolicy, exception.policy
        assert_equal :destroy_sample?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.group.destroy_sample?', name: group7.name),
                     exception.result.message
      end
    end
  end
end
