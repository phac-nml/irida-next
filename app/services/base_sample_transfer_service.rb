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
    project_namespace.self_and_ancestors_of_type([Namespaces::ProjectNamespace.sti_name, Group.sti_name])
  end

  def update_metadata_summary(sample, old_namespaces, new_namespaces)
    Namespace.add_to_metadata_summary_count(new_namespaces, sample.metadata, true)
    Namespace.subtract_from_metadata_summary_count(old_namespaces, sample.metadata, true)
  end

  def update_samples_count(old_project, new_project, transferred_samples_count)
    Project.decrement_counter(:samples_count, old_project.id, by: transferred_samples_count) # rubocop:disable Rails/SkipsModelValidations
    Project.increment_counter(:samples_count, new_project.id, by: transferred_samples_count) # rubocop:disable Rails/SkipsModelValidations
    if old_project.parent.type == 'Group'
      old_project.parent.update_samples_count_by_transfer_service(new_project, transferred_samples_count)
    elsif new_project.parent.type == 'Group'
      new_project.parent.update_samples_count_by_addition_services(transferred_samples_count)
    end
  end

  def update_metadata_summary_counts(transferred_project_sample_ids, new_project) # rubocop:disable Metrics/AbcSize
    transferred_project_sample_ids.each do |old_project_id, sample_ids|
      old_project = Project.find(old_project_id)

      # Build metadata summary payload for transferred samples
      metadata_payload = {}
      Sample.select(
        Arel::Nodes::NamedFunction.new('JSONB_OBJECT_KEYS', [Sample.arel_table[:metadata]]).as('key'),
        Arel.star.count
      ).where(id: sample_ids).group(Arel::Nodes::SqlLiteral.new('key')).each do |sample|
        metadata_payload[sample.key] = sample.count
      end

      old_namespaces = namespaces_for_transfer(old_project.namespace)
      new_namespaces = namespaces_for_transfer(new_project.namespace)

      old_project.namespace.update_metadata_summary_by_sample_transfer(metadata_payload, old_namespaces, new_namespaces)
    end
  end

  def transfer(new_project, sample_ids, broadcast_target) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    transferrable_samples = filter_sample_ids(sample_ids, 'transfer')
    project_sample_ids_to_transfer = {}
    transferrable_samples.pluck(:id, :project_id).each do |id, project_id|
      project_sample_ids_to_transfer[project_id] ||= []
      project_sample_ids_to_transfer[project_id] << id
    end

    update_progress_bar(5, 100, broadcast_target)

    conflicting_samples = Arel::Table.new(Sample.table_name, as: 'conflicting_samples')

    Sample.transaction do
      lock_id = Zlib.crc32("project_#{new_project.puid}_samples_lock").to_i
      Sample.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")

      project_sample_ids_to_transfer.each do |project_id, sample_ids|
        # Transfer samples that do not have name conflicts in the target project
        Sample.where(id: sample_ids, project_id: project_id).where.not(
          id: Sample.joins(Sample.arel_table.create_join(conflicting_samples,
                                                         Arel::Nodes::On.new(
                                                           conflicting_samples[:name].eq(Sample.arel_table[:name])
                                                         ), Arel::Nodes::OuterJoin))
                    .where(
                      conflicting_samples[:project_id].eq(new_project.id).and(conflicting_samples[:deleted_at].eq(nil))
                    )
                    .where(id: sample_ids).select(:id)
        ).update_all(project_id: new_project.id, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    update_progress_bar(95, 100, broadcast_target)

    # Retrieve ids of transferred samples and build transferred samples data for activity
    transferred_project_sample_ids = {}
    transferred_samples_data = {}
    project_sample_ids_to_transfer.each do |project_id, sample_ids|
      transferred_project_sample_ids[project_id] = Sample.where(id: sample_ids, project_id: new_project.id)
                                                         .where.not(id: transferrable_samples.pluck(:id)).pluck(:id)
      retrieve_sample_transfer_activity_data(project_id, new_project, transferred_project_sample_ids[project_id],
                                             transferred_samples_data)
    end

    # Add errors for samples that could not be transferred due to name conflicts
    transferrable_samples.pluck(:name, :puid, :project_id).each do |name, puid, project_id|
      if project_id == new_project.id
        @namespace.errors.add(:samples,
                              I18n.t('services.samples.transfer.target_project_duplicate', sample_name: name))
      else
        @namespace.errors.add(:samples,
                              I18n.t('services.samples.transfer.sample_exists', sample_name: name, sample_puid: puid))
      end
    end

    # If no samples were transferred, return an empty array
    return [] if transferred_project_sample_ids.empty? || transferred_project_sample_ids.values.all?(&:empty?)

    update_metadata_summary_counts(transferred_project_sample_ids, new_project)

    update_samples_count_and_create_activities(transferred_samples_data, new_project)

    update_progress_bar(100, 100, broadcast_target)

    transferred_project_sample_ids.values.flatten
  end

  def retrieve_sample_transfer_activity_data
    raise NotImplementedError
  end

  def update_samples_count_and_create_activities(transferred_samples_data, new_project) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    transferred_samples_data.each do |old_project_id, data|
      next if data.empty?

      old_project = Project.find(old_project_id)

      update_samples_count(old_project, new_project, data.size)

      ext_details = ExtendedDetail.create!(details: { transferred_samples_count: data.size,
                                                      transferred_samples_data: data })

      params = {
        target_project_puid: data[0][:target_project_puid],
        target_project: data[0][:target_project_id],
        transferred_samples_count: data.size,
        action: 'sample_transfer'
      }

      create_project_activity(old_project.namespace, ext_details.id, 'namespaces_project_namespace.samples.transfer',
                              params)

      params = {
        source_project_puid: data[0][:source_project_puid],
        source_project: data[0][:source_project_id],
        transferred_samples_count: data.size,
        action: 'sample_transfer'
      }

      create_project_activity(new_project.namespace, ext_details.id,
                              'namespaces_project_namespace.samples.transferred_from', params)

      Turbo::StreamsChannel.broadcast_refresh_later_to old_project, :samples
      namespaces_for_transfer(old_project.namespace).each do |old_namespace|
        Turbo::StreamsChannel.broadcast_refresh_later_to old_namespace, :samples
      end
    end

    Turbo::StreamsChannel.broadcast_refresh_later_to new_project, :samples
    namespaces_for_transfer(new_project.namespace).each do |new_namespace|
      Turbo::StreamsChannel.broadcast_refresh_later_to new_namespace, :samples
    end

    create_group_activity(transferred_samples_data) if @namespace.group_namespace?
  end

  def create_group_activity
    raise NotImplementedError
  end
end
