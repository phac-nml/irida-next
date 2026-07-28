# frozen_string_literal: true

# Recalculates persisted sample counters for projects and groups.
#
# Order is important:
# 1) reset project counters from actual sample rows
# 2) recalculate group counters from descendant projects
class ResetSamplesCountJob < ApplicationJob
  include ActiveJob::Continuable

  queue_as :default
  queue_with_priority 50

  def perform(root_group_ids: nil)
    @requested_root_group_ids = Array(root_group_ids).compact_blank
    @root_groups = @requested_root_group_ids.empty? ? nil : Group.where(id: @requested_root_group_ids).distinct

    if @root_groups&.none?
      Rails.logger.warn("ResetSamplesCountJob skipped: no active groups found for root_group_ids=#{@requested_root_group_ids.inspect}") # rubocop:disable Layout/LineLength
      return
    end

    step :reset_project_counts_step, start: 0
    step :reset_group_counts_step, start: 0
    step :log_completion
  end

  private

  def reset_project_counts_step(step)
    start_id = scoped_projects(@root_groups).order(:id).offset(step.cursor).first&.id
    return if start_id.nil?

    scoped_projects(@root_groups).find_each(start: start_id) do |project|
      Project.reset_counters(project.id, :samples)
      step.advance!
    end
  end

  def reset_group_counts_step(step)
    start_id = scoped_groups(@root_groups).order(:id).offset(step.cursor).first&.id
    return if start_id.nil?

    scoped_groups(@root_groups).find_each(start: start_id) do |group|
      descendant_project_namespace_ids =
        group.self_and_descendants_of_type(Namespaces::ProjectNamespace.sti_name).select(:id)
      group_samples_count = Project.where(namespace_id: descendant_project_namespace_ids).sum(:samples_count)

      group.update_columns(samples_count: group_samples_count) # rubocop:disable Rails/SkipsModelValidations
      step.advance!
    end
  end

  def log_completion
    mode = @root_groups.nil? ? 'global' : 'root_scoped'
    Rails.logger.info(
      "ResetSamplesCountJob complete mode=#{mode} root_group_ids=#{@requested_root_group_ids.inspect}"
    )
  end

  def scoped_projects(root_groups)
    return Project.all if root_groups.nil?

    group_ids = scoped_groups(root_groups).select(:id)

    Project.joins(:namespace).where(namespace: { parent_id: group_ids })
  end

  def scoped_groups(root_groups)
    return Group.all if root_groups.nil?

    root_groups.self_and_descendants
  end
end
