# frozen_string_literal: true

require 'test_helper'

module Groups
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @group = groups(:group_two)
    end

    test 'delete group with correct permissions' do
      assert_difference -> { Group.count } => -1 do
        Groups::DestroyService.new(@group, @user).execute
      end
      assert @group.errors.empty?
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
      @group12 = groups(:group_twelve)
      @subgroup12a = groups(:subgroup_twelve_a)
      @subgroup12b = groups(:subgroup_twelve_b)
      @subgroup12aa = groups(:subgroup_twelve_a_a)

      @project31 = projects(:project31)
      Project.reset_counters(@project31.id, :samples_count)
      @project31.reload.samples_count

      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

      assert_no_changes -> { @subgroup12b.reload.metadata_summary } do
        Groups::DestroyService.new(@subgroup12aa, @user).execute
      end

      assert(@subgroup12aa.reload.deleted?)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12a.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @group12.reload.metadata_summary)
    end

    test 'samples count updated after group deletion' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      @group12 = groups(:group_twelve)
      @subgroup12a = groups(:subgroup_twelve_a)
      @subgroup12b = groups(:subgroup_twelve_b)
      @subgroup12aa = groups(:subgroup_twelve_a_a)

      @project31 = projects(:project31)
      Project.reset_counters(@project31.id, :samples_count)
      @project31.reload.samples_count

      assert_equal(2, @subgroup12aa.samples_count)
      assert_equal(3, @subgroup12a.samples_count)
      assert_equal(1, @subgroup12b.samples_count)
      assert_equal(4, @group12.samples_count)

      assert_no_changes -> { @subgroup12b.reload.samples_count } do
        Groups::DestroyService.new(@subgroup12aa, @user).execute
      end

      assert(@subgroup12aa.reload.deleted?)
      assert_equal(1, @subgroup12a.reload.samples_count)
      assert_equal(2, @group12.reload.samples_count)
    end
  end
end
