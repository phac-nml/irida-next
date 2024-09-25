# frozen_string_literal: true

require 'test_helper'

module Projects
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:john_doe_project2)
    end

    test 'delete project with with correct permissions' do
      assert_difference -> { Project.count } => -1, -> { Member.count } => -5 do
        Projects::DestroyService.new(@project, @user).execute
      end
    end

    test 'delete project with incorrect permissions' do
      user = users(:joan_doe)

      assert_raises(ActionPolicy::Unauthorized) { Projects::DestroyService.new(@project, user).execute }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Projects::DestroyService.new(@project, user).execute
      end

      assert_equal ProjectPolicy, exception.policy
      assert_equal :destroy?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.destroy?', name: @project.name), exception.result.message
    end

    test 'valid authorization to destroy project' do
      assert_authorized_to(:destroy?, @project,
                           with: ProjectPolicy,
                           context: { user: @user }) do
        Projects::DestroyService.new(
          @project, @user
        ).execute
      end
    end

    test 'metadata summary updated after project deletion' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      @group12 = groups(:group_twelve)
      @subgroup12a = groups(:subgroup_twelve_a)
      @subgroup12b = groups(:subgroup_twelve_b)
      @subgroup12aa = groups(:subgroup_twelve_a_a)
      @project31 = projects(:project31)

      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @project31.namespace.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12aa.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @subgroup12a.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, @group12.metadata_summary)

      assert_no_changes -> { @subgroup12b.reload.metadata_summary } do
        Projects::DestroyService.new(@project31, @user).execute
      end

      assert(@project31.namespace.reload.deleted?)
      assert_equal({}, @subgroup12aa.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12a.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, @subgroup12b.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, @group12.reload.metadata_summary)
    end

    test 'samples count updated after project deletion' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      @group12 = groups(:group_twelve)
      @subgroup12a = groups(:subgroup_twelve_a)
      @subgroup12b = groups(:subgroup_twelve_b)
      @subgroup12aa = groups(:subgroup_twelve_a_a)
      @project31 = projects(:project31)

      assert_equal(2, @subgroup12aa.samples_count)
      assert_equal(3, @subgroup12a.samples_count)
      assert_equal(1, @subgroup12b.samples_count)
      assert_equal(4, @group12.samples_count)

      assert_no_changes -> { @subgroup12b.reload.samples_count } do
        Projects::DestroyService.new(@project31, @user).execute
      end

      assert(@project31.namespace.reload.deleted?)
      assert_equal(0, @subgroup12aa.reload.samples_count)
      assert_equal(1, @subgroup12a.samples_count)
      assert_equal(1, @subgroup12b.samples_count)
      assert_equal(2, @group12.samples_count)
    end
  end
end
