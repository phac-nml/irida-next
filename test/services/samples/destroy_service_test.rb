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
    end

    test 'destroy sample with correct permissions' do
      assert_difference -> { Sample.count } => -1 do
        Samples::DestroyService.new(@project, @sample1.id, @user).execute
      end
    end

    test 'destroy sample with incorrect permissions' do
      @user = users(:joan_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::DestroyService.new(@project, @sample1.id, @user).execute
      end

      assert_equal ProjectPolicy, exception.policy
      assert_equal :destroy_sample?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.destroy_sample?', name: @sample.project.name),
                   exception.result.message
    end

    test 'valid authorization to destroy sample' do
      assert_authorized_to(:destroy_sample?, @sample1.project, with: ProjectPolicy,
                                                               context: { user: @user }) do
        Samples::DestroyService.new(@project, @sample1.id,
                                    @user).execute
      end
    end

    test 'metadata summary updated after single sample deletion' do
      # Reference group/projects descendants tree:
      # group12 < subgroup12b (project30 > sample 33)
      #    |
      #    ---- < subgroup12a (project29 > sample 32) < subgroup12aa (project31 > sample34 + 35)
      group12 = groups(:group_twelve)
      subgroup12a = groups(:subgroup_twelve_a)
      subgroup12b = groups(:subgroup_twelve_b)
      subgroup12aa = groups(:subgroup_twelve_a_a)
      project31 = projects(:project31)
      sample34 = samples(:sample34)

      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, project31.namespace.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, subgroup12aa.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, subgroup12a.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, subgroup12b.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, group12.metadata_summary)

      assert_no_changes -> { subgroup12b.reload.metadata_summary } do
        Samples::DestroyService.new(project31, sample34.id, @user).execute
      end

      assert_equal({}, project31.namespace.reload.metadata_summary)
      assert_equal({}, subgroup12aa.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, subgroup12a.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, subgroup12b.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, group12.reload.metadata_summary)
    end

    test 'multiple destroy with multiple samples and correct permissions' do
      assert_difference -> { Sample.count } => -3 do
        Samples::DestroyService.new(@project, [@sample1.id, @sample2.id, @sample30.id], @user).execute
      end
    end

    test 'destroy samples with incorrect permissions' do
      user = users(:joan_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::DestroyService.new(@project, [@sample1.id, @sample2.id, @sample30.id], user).execute
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
      group12 = groups(:group_twelve)
      subgroup12a = groups(:subgroup_twelve_a)
      subgroup12b = groups(:subgroup_twelve_b)
      subgroup12aa = groups(:subgroup_twelve_a_a)
      project30 = projects(:project30)
      project31 = projects(:project31)
      sample33 = samples(:sample33)
      sample34 = samples(:sample34)

      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, project31.namespace.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, subgroup12aa.metadata_summary)
      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, subgroup12a.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, subgroup12b.metadata_summary)
      assert_equal({ 'metadatafield1' => 3, 'metadatafield2' => 3 }, group12.metadata_summary)

      Samples::TransferService.new(project30, @user).execute(project31.id, [sample33.id])

      assert_equal(
        { 'metadatafield1' => 2, 'metadatafield2' => 2 }, project31.reload.namespace.metadata_summary
      )

      assert_equal({ 'metadatafield1' => 2, 'metadatafield2' => 2 }, subgroup12aa.reload.metadata_summary)

      assert_no_changes -> { subgroup12b.reload.metadata_summary } do
        Samples::DestroyService.new(project31, [sample33.id, sample34.id], @user).execute
      end

      assert_equal({}, project31.namespace.reload.metadata_summary)
      assert_equal({}, subgroup12aa.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, subgroup12a.reload.metadata_summary)
      assert_equal({}, subgroup12b.reload.metadata_summary)
      assert_equal({ 'metadatafield1' => 1, 'metadatafield2' => 1 }, group12.reload.metadata_summary)
    end
  end
end
