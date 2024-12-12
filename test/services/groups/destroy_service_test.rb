# frozen_string_literal: true

require 'test_helper'

module Groups
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @group = groups(:group_two)

      @group12 = groups(:group_twelve)
      @subgroup12a = groups(:subgroup_twelve_a)
      @subgroup12b = groups(:subgroup_twelve_b)
      @subgroup12aa = groups(:subgroup_twelve_a_a)
    end

    test 'delete group with correct permissions' do
      assert_difference -> { Group.count } => -1 do
        Groups::DestroyService.new(@group, @user).execute
      end
    end

    test 'delete group with incorrect permissions' do
      user = users(:joan_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Groups::DestroyService.new(@group, user).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :destroy?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.destroy?', name: @group.name), exception.result.message
    end

    test 'valid authorization to destroy group' do
      assert_authorized_to(:destroy?, @group,
                           with: GroupPolicy,
                           context: { user: @user }) do
        Groups::DestroyService.new(@group, @user).execute
      end
    end

    test 'metadata summary updated after group deletion' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_difference -> { @subgroup12a.reload.metadata_summary['metadatafield1'] } => -1,
                        -> { @subgroup12a.reload.metadata_summary['metadatafield2'] } => -1,
                        -> { @group12.reload.metadata_summary['metadatafield1'] } => -1,
                        -> { @group12.reload.metadata_summary['metadatafield2'] } => -1 do
        Groups::DestroyService.new(@subgroup12aa, @user).execute
      end

      assert @subgroup12aa.reload.deleted?
    end

    test 'samples count updated after group deletion' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      assert_difference -> { @subgroup12a.reload.samples_count } => -2,
                        -> { @group12.reload.samples_count } => -2,
                        -> { @subgroup12b.reload.samples_count } => 0 do
        Groups::DestroyService.new(@subgroup12aa, @user).execute
      end

      assert @subgroup12aa.reload.deleted?
    end
  end
end
