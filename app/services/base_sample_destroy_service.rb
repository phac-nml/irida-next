# frozen_string_literal: true

# Service used to Delete Samples
class BaseSampleDestroyService < BaseService
  class DestroyError < StandardError; end

  attr_accessor :sample, :sample_ids, :namespace

  def initialize(namespace, user = nil, params = {})
    super(user, params)
    @namespace = namespace
    @sample = params[:sample] if params[:sample]
    @sample_ids = params[:sample_ids] if params[:sample_ids]
  end

  def execute
    authorize! (namespace.group_namespace? ? namespace : namespace.project), to: :destroy_sample?

    if Flipper.enabled?(:prevent_sample_deletions_and_transfers_with_active_workflows)
      sample_ids = @sample_ids || [@sample.id]
      validate_no_active_workflow_executions(sample_ids)
    end

    destroy_samples
  rescue BaseSampleDestroyService::DestroyError => e
    namespace.errors.add(:base, e.message)
    0
  end

  private

  # Validate that samples do not have active workflow executions.
  #
  # Prevents transferring samples that are currently being used in a workflow execution.
  # Active workflow states are: initial, prepared, submitted, running.
  #
  # @param sample_ids [Array<Integer>] IDs of samples to check
  # @raise [DestroyError] if any samples have active workflow executions
  def validate_no_active_workflow_executions(sample_ids)
    active_workflow_sample_puids = active_workflow_execution_sample_puids(sample_ids)

    return if active_workflow_sample_puids.empty?

    raise DestroyError,
          I18n.t('services.samples.destroy.active_workflow_executions',
                 sample_puids: active_workflow_sample_puids.join(', '))
  end

  def update_metadata_summary(sample)
    sample.project.namespace.update_metadata_summary_by_sample_deletion(sample)
  end

  def create_project_activity(project_namespace, deleted_samples_data) # rubocop:disable Metrics/MethodLength
    details = {
      samples_deleted_count: deleted_samples_data.size,
      deleted_samples_data: deleted_samples_data
    }
    activity_params = { samples_deleted_count: deleted_samples_data.size, action: 'sample_destroy_multiple' }
    ext_details = ExtendedDetail.create!(details: details)
    key = if params[:reason].present?
            activity_params[:reason] = params[:reason]
            'namespaces_project_namespace.samples.destroy_multiple_with_reason'
          else
            'namespaces_project_namespace.samples.destroy_multiple'
          end

    activity = project_namespace.create_activity key: key,
                                                 owner: current_user,
                                                 parameters: activity_params
    activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                             activity_type: 'sample_destroy_multiple')
  end

  def destroy_samples
    raise NotImplementedError
  end
end
