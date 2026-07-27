# frozen_string_literal: true

require 'active_job/continuation/test_helper'
require 'test_helper'

class ResetSamplesCountJobTest < ActiveJob::TestCase
  include ActiveJob::Continuation::TestHelper

  test 'resets project and group counters globally' do
    project = projects(:project1)
    group = groups(:group_one)

    project.update_columns(samples_count: 999) # rubocop:disable Rails/SkipsModelValidations
    group.update_columns(samples_count: 999) # rubocop:disable Rails/SkipsModelValidations

    ResetSamplesCountJob.perform_now

    assert_equal project.samples.count, project.reload.samples_count
    assert_equal expected_group_samples_count(group), group.reload.samples_count
  end

  test 'resets only descendants when root_group_ids are provided' do
    root_group = groups(:group_twelve)
    in_scope_project = projects(:project29)
    out_of_scope_project = projects(:project1)
    in_scope_group = groups(:subgroup_twelve_a)
    out_of_scope_group = groups(:group_one)

    in_scope_project.update_columns(samples_count: 900) # rubocop:disable Rails/SkipsModelValidations
    out_of_scope_project.update_columns(samples_count: 800) # rubocop:disable Rails/SkipsModelValidations
    in_scope_group.update_columns(samples_count: 700) # rubocop:disable Rails/SkipsModelValidations
    out_of_scope_group.update_columns(samples_count: 600) # rubocop:disable Rails/SkipsModelValidations

    ResetSamplesCountJob.perform_now(root_group_ids: [root_group.id])

    assert_equal in_scope_project.samples.count, in_scope_project.reload.samples_count
    assert_equal expected_group_samples_count(in_scope_group), in_scope_group.reload.samples_count

    assert_equal 800, out_of_scope_project.reload.samples_count
    assert_equal 600, out_of_scope_group.reload.samples_count
  end

  test 'is idempotent in global mode' do
    project = projects(:project4)
    group = groups(:group_three)

    project.update_columns(samples_count: 500) # rubocop:disable Rails/SkipsModelValidations
    group.update_columns(samples_count: 500) # rubocop:disable Rails/SkipsModelValidations

    ResetSamplesCountJob.perform_now

    assert_no_changes -> { project.reload.samples_count } do
      assert_no_changes -> { group.reload.samples_count } do
        ResetSamplesCountJob.perform_now
      end
    end
  end

  test 'job resumes from correct step after interruption' do
    project = projects(:project1)
    group = groups(:group_one)

    project.update_columns(samples_count: 999) # rubocop:disable Rails/SkipsModelValidations
    group.update_columns(samples_count: 999) # rubocop:disable Rails/SkipsModelValidations

    ResetSamplesCountJob.perform_later

    # Interrupt after project counts are reset but before group counts
    interrupt_job_after_step(ResetSamplesCountJob, :reset_project_counts_step) do
      perform_enqueued_jobs(only: ResetSamplesCountJob)
    end

    project.reload
    group.reload

    # Project counts should be reset
    assert_equal project.samples.count, project.samples_count

    # Group counts should still be incorrect (not reset yet)
    assert_equal 999, group.samples_count

    # Resume the job
    perform_enqueued_jobs(only: ResetSamplesCountJob)

    project.reload
    group.reload

    # Both should now be correct
    assert_equal project.samples.count, project.samples_count
    assert_equal expected_group_samples_count(group), group.samples_count
  end

  test 'does not reprocess records after cursor on resumption' do
    # Use a specific root group to have a known, limited set of projects
    root_group = groups(:group_twelve)
    projects_to_reset = root_group.self_and_descendants_of_type(Namespaces::ProjectNamespace.sti_name)
                                  .map(&:project)
                                  .compact
                                  .sort_by(&:id)
    skip 'Need at least 3 projects in test group for this test' if projects_to_reset.count < 3

    projects_to_reset.each do |project|
      project.update_columns(samples_count: 999) # rubocop:disable Rails/SkipsModelValidations
    end

    first_project = projects_to_reset.first
    first_project_sample_count = first_project.samples.count

    # Interrupt after the first project (cursor position 1 means skip first record)
    interrupt_job_during_step(ResetSamplesCountJob, :reset_project_counts_step, cursor: 1) do
      ResetSamplesCountJob.perform_later(root_group_ids: [root_group.id])
      perform_enqueued_jobs(only: ResetSamplesCountJob)
    end

    first_project.reload

    # First project should have been reset to correct count
    assert_equal first_project_sample_count, first_project.samples_count,
                 'First project should have been reset during first execution'

    # Now manually set the first project back to an incorrect count to verify it won't be reset again
    first_project.update_columns(samples_count: 888) # rubocop:disable Rails/SkipsModelValidations

    # Resume the job - should only process remaining projects, not the first one again
    perform_enqueued_jobs(only: ResetSamplesCountJob)

    first_project.reload

    # First project count should still be 888 (not reset again), proving the cursor worked
    assert_equal 888, first_project.samples_count,
                 'First project should NOT have been reprocessed (cursor should skip it)'

    # Verify remaining projects were processed correctly
    projects_to_reset[1..].each do |project|
      assert_equal project.samples.count, project.reload.samples_count
    end
  end

  test 'does not reprocess groups after cursor on resumption' do
    # Use a specific root group to have a known, limited set of groups
    root_group = groups(:group_twelve)
    groups_to_reset = root_group.self_and_descendants_of_type(Group.sti_name).sort_by(&:id)
    skip 'Need at least 3 groups in test hierarchy for this test' if groups_to_reset.count < 3

    groups_to_reset.each do |group|
      group.update_columns(samples_count: 999) # rubocop:disable Rails/SkipsModelValidations
    end

    first_group = groups_to_reset.first
    first_group_expected_sample_count = expected_group_samples_count(first_group)

    # Interrupt after the first group (cursor position 1 means skip first record)
    interrupt_job_during_step(ResetSamplesCountJob, :reset_group_counts_step, cursor: 1) do
      ResetSamplesCountJob.perform_later(root_group_ids: [root_group.id])
      perform_enqueued_jobs(only: ResetSamplesCountJob)
    end

    first_group.reload

    # First group should have been reset to correct count
    assert_equal first_group_expected_sample_count, first_group.samples_count,
                 'First group should have been reset during first execution'

    # Now manually set the first group back to an incorrect count to verify it won't be reset again
    first_group.update_columns(samples_count: 777) # rubocop:disable Rails/SkipsModelValidations

    # Resume the job - should only process remaining groups, not the first one again
    perform_enqueued_jobs(only: ResetSamplesCountJob)

    first_group.reload

    # First group count should still be 777 (not reset again), proving the cursor worked
    assert_equal 777, first_group.samples_count,
                 'First group should NOT have been reprocessed (cursor should skip it)'

    # Verify remaining groups were processed correctly
    groups_to_reset[1..].each do |group|
      assert_equal expected_group_samples_count(group), group.reload.samples_count
    end
  end

  test 'resets projects before groups' do
    ResetSamplesCountJob.perform_later

    interrupt_job_after_step(ResetSamplesCountJob, :reset_project_counts_step) do
      perform_enqueued_jobs(only: ResetSamplesCountJob)
    end

    # After interrupting after project step, should still have job enqueued
    assert_enqueued_jobs(1, only: ResetSamplesCountJob)

    # After completing, should move to group step
    perform_enqueued_jobs(only: ResetSamplesCountJob)

    assert_performed_jobs(2, only: ResetSamplesCountJob)
  end

  private

  def expected_group_samples_count(group)
    descendant_project_namespace_ids = group.self_and_descendants_of_type(Namespaces::ProjectNamespace.sti_name).select(:id)
    Project.where(namespace_id: descendant_project_namespace_ids).sum { |project| project.samples.count }
  end
end
