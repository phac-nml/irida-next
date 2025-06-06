# frozen_string_literal: true

# Base sample service root class for sample service related classes, scoped by namespace
class BaseSampleCloneService < BaseSampleService
  CloneError = Class.new(StandardError)

  def execute(new_project_id, sample_ids, broadcast_target = nil)
    authorize! (@namespace.group_namespace? ? @namespace : @namespace.project), to: :clone_sample?

    validate(sample_ids, 'clone', new_project_id)

    @new_project = Project.find_by(id: new_project_id)

    authorize_new_project(new_project_id, :clone_sample_into_project?)

    clone_samples(sample_ids, broadcast_target)
  rescue Samples::CloneService::CloneError => e
    @namespace.errors.add(:base, e.message)
    {}
  end

  private

  def clone_sample(sample)
    clone = sample.dup
    clone.project_id = @new_project.id
    clone.generate_puid
    clone.save!

    # update new project metadata summary and then clone attachments to the sample
    @new_project.namespace.update_metadata_summary_by_sample_addition(sample)
    clone_attachments(sample, clone)

    clone
  rescue ActiveRecord::RecordInvalid
    @project.errors.add(:samples, I18n.t('services.samples.clone.sample_exists', sample_name: sample.name,
                                                                                 sample_puid: sample.puid))
    nil
  end

  def clone_attachments(sample, clone)
    files = sample.attachments.map { |attachment| attachment.file.blob }
    ::Attachments::CreateService.new(current_user, clone, { files:, include_activity: false }).execute
  end

  def update_samples_count(cloned_samples_count)
    @new_project.parent.update_samples_count_by_addition_services(cloned_samples_count)
  end

  def create_project_level_activity(cloned_samples_data, old_project_namespace) # rubocop:disable Metrics/MethodLength
    cloned_samples_count = cloned_samples_data.count
    ext_details = ExtendedDetail.create!(details: { cloned_samples_count: cloned_samples_count,
                                                    cloned_samples_data: cloned_samples_data })

    activity = old_project_namespace.namespace.create_activity key: 'namespaces_project_namespace.samples.clone',
                                                               owner: current_user,
                                                               parameters:
                                                  {
                                                    target_project_puid: @new_project.puid,
                                                    target_project: @new_project.id,
                                                    cloned_samples_count: cloned_samples_count,
                                                    action: 'sample_clone'
                                                  }

    activity.create_activity_extended_detail(extended_detail_id: ext_details.id, activity_type: 'sample_clone')

    activity = @new_project.namespace.create_activity key: 'namespaces_project_namespace.samples.cloned_from',
                                                      owner: current_user,
                                                      parameters:
                                                      {
                                                        source_project_puid: @project.puid,
                                                        source_project: @project.id,
                                                        cloned_samples_count: cloned_samples_count,
                                                        action: 'sample_clone'
                                                      }

    activity.create_activity_extended_detail(extended_detail_id: ext_details.id, activity_type: 'sample_clone')
  end
end
