# frozen_string_literal: true

# Base Service used to Transfer Samples
class BaseSampleTransferService < BaseSampleService
  TransferError = Class.new(StandardError)

  def execute(new_project_id, sample_ids, broadcast_target = nil)
    # Authorize if user can transfer samples from the current project
    if @namespace.group_namespace?
      authorize! @namespace, to: :transfer_sample?
    else
      authorize! @namespace.project, to: :transfer_sample?
    end

    validate(sample_ids, 'transfer', new_project_id)

    authorize_new_project(new_project_id, :transfer_sample_into_project?)

    if Member.effective_access_level(@namespace, current_user) == Member::AccessLevel::MAINTAINER
      validate_maintainer_sample_transfer
    end

    transfer(@new_project, sample_ids, broadcast_target)
  rescue BaseSampleService::BaseError, BaseSampleTransferService::TransferError => e
    @namespace.errors.add(:base, e.message)
    []
  end

  def validate_maintainer_sample_transfer
    project_parent_and_ancestors = if @namespace.group_namespace?
                                     @namespace.self_and_ancestor_ids
                                   else
                                     @namespace.parent.self_and_ancestor_ids
                                   end

    new_project_parent_and_ancestors = @new_project.namespace.parent.self_and_ancestor_ids

    return if project_parent_and_ancestors.intersect?(new_project_parent_and_ancestors)

    raise TransferError,
          I18n.t('services.samples.transfer.maintainer_transfer_not_allowed')
  end

  def create_project_activity(namespace, ext_details_id, key, params)
    activity = namespace.create_activity key: key,
                                         owner: current_user,
                                         parameters: params

    activity.create_activity_extended_detail(extended_detail_id: ext_details_id,
                                             activity_type: 'sample_transfer')
  end

  def namespaces_for_transfer(project_namespace)
    [project_namespace] +
      project_namespace.parent.self_and_ancestors.where.not(type: Namespaces::UserNamespace.sti_name)
  end

  def update_metadata_summary(sample, old_project, old_namespaces, new_namespaces)
    old_project.namespace.update_metadata_summary_by_sample_transfer(sample.id,
                                                                     old_namespaces, new_namespaces)
  end

  def update_samples_count(old_project, new_project, transferred_samples_count)
    if old_project.parent.type == 'Group'
      old_project.parent.update_samples_count_by_transfer_service(new_project, transferred_samples_count)
    elsif new_project.parent.type == 'Group'
      new_project.parent.update_samples_count_by_addition_services(transferred_samples_count)
    end
  end

  def transfer
    raise NotImplementedError
  end

  def add_transfer_sample_to_activity_data
    raise NotImplementedError
  end
end
