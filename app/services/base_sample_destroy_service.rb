# frozen_string_literal: true

# Service used to Delete Samples
class BaseSampleDestroyService < BaseService
  attr_accessor :sample, :sample_ids, :namespace

  def initialize(namespace, user = nil, params = {})
    super(user, params)
    @namespace = namespace
    @sample = params[:sample] if params[:sample]
    @sample_ids = params[:sample_ids] if params[:sample_ids]
  end

  def execute
    authorize! (namespace.group_namespace? ? namespace : namespace.project), to: :destroy_sample?

    destroy_samples
  end

  private

  def update_metadata_summary(sample)
    sample.project.namespace.update_metadata_summary_by_sample_deletion(sample)
  end

  def update_samples_count(project_namespace, samples_deleted_count)
    project_namespace.parent.update_samples_count_by_destroy_service(samples_deleted_count)
  end

  def create_project_activity(project_namespace, deleted_samples_data)
    ext_details = ExtendedDetail.create!(details: { samples_deleted_count: deleted_samples_data.size,
                                                    deleted_samples_data: deleted_samples_data })

    activity = project_namespace.create_activity key: 'namespaces_project_namespace.samples.destroy_multiple',
                                                 owner: current_user,
                                                 parameters:
                                                 {
                                                   samples_deleted_count: deleted_samples_data.size,
                                                   action: 'sample_destroy_multiple'
                                                 }

    activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                             activity_type: 'sample_destroy_multiple')
  end
end
