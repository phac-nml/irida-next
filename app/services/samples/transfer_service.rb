# frozen_string_literal: true

module Samples
  # Service to transfer samples between projects, handling authorization, validation,
  # conflict resolution, and metadata/activity updates.
  #
  # Responsibilities:
  # - Authorize users to transfer samples from source to target project
  # - Validate sample IDs and target project
  # - Detect and handle name conflicts in target project
  # - Update sample counts and metadata summaries
  # - Create audit trail activities for transferred samples
  # - Handle group-level activity aggregation when applicable
  #
  # @example Transfer samples to a new project
  #   service = Samples::TransferService.new(namespace, user)
  #   transferred_ids = service.execute(new_project_id, sample_ids, broadcast_target)
  class TransferService < BaseSampleService # rubocop:disable Metrics/ClassLength
    class TransferError < StandardError
    end

    LATEST_META = "log_data -> 'h' -> -1 -> 'm'"

    def authorize_transfer(new_project, sample_ids)
      # Authorize if user can transfer samples from the current project
      if @namespace.group_namespace?
        authorize! @namespace, to: :transfer_sample?
      else
        authorize! @namespace.project, to: :transfer_sample?
      end

      validate(sample_ids, 'transfer', new_project.id)

      authorize_new_project(new_project, :transfer_sample_into_project?)

      if Member.effective_access_level(@namespace, current_user) == Member::AccessLevel::MAINTAINER # rubocop:disable Style/GuardClause
        validate_maintainer_sample_transfer(new_project)
      end
    end

    # Validate that a maintainer can transfer samples between projects.
    #
    # Ensures the source and target projects share a common ancestor in the
    # namespace hierarchy. Maintainers cannot transfer samples to projects outside
    # their allowed scope to prevent privilege escalation.
    #
    # @raise [TransferError] if source and target projects have no common ancestor
    def validate_maintainer_sample_transfer(new_project)
      project_parent_and_ancestors = if @namespace.group_namespace?
                                       @namespace.self_and_ancestor_ids
                                     else
                                       @namespace.parent.self_and_ancestor_ids
                                     end

      new_project_parent_and_ancestors = new_project.namespace.parent.self_and_ancestor_ids

      return if project_parent_and_ancestors.intersect?(new_project_parent_and_ancestors)

      raise TransferError, I18n.t('services.samples.transfer.maintainer_transfer_not_allowed')
    end

    # Collect the project namespace and its ancestors.
    #
    # Returns both project and group namespaces in the ancestor chain, used to
    # determine scope for metadata updates and activity creation.
    #
    # @param project_namespace [Namespace] the namespace to traverse
    # @return [ActiveRecord::Relation] namespaces from the given namespace up to root
    def namespaces_for_transfer(project_namespace)
      project_namespace.self_and_ancestors_of_type([Namespaces::ProjectNamespace.sti_name, Group.sti_name])
    end

    # Update sample counts on projects after transfer.
    #
    # Decrements the source project's count and increments the target project's count.
    # If either project belongs to a group, also updates the group's metadata summary.
    #
    # @param old_project [Project] the source project
    # @param new_project [Project] the target project
    # @param transferred_samples_count [Integer] number of samples transferred
    def update_samples_count(old_project, new_project, transferred_samples_count)
      Project.decrement_counter(:samples_count, old_project.id, by: transferred_samples_count) # rubocop:disable Rails/SkipsModelValidations
      Project.increment_counter(:samples_count, new_project.id, by: transferred_samples_count) # rubocop:disable Rails/SkipsModelValidations
      if old_project.parent.type == 'Group'
        old_project.parent.update_samples_count_by_transfer_service(new_project, transferred_samples_count)
      elsif new_project.parent.type == 'Group'
        new_project.parent.update_samples_count_by_addition_services(transferred_samples_count)
      end
    end

    # Update metadata summaries for all namespaces affected by the transfer.
    #
    # For source project, collects the metadata keys and counts from samples
    # being transferred, then updates both the source and target namespace hierarchies
    # to reflect the transfer.
    #
    # @param sample_ids [Array<Integer>] IDs of samples that were transferred
    # @param old_project [Project] the source project
    # @param new_project [Project] the target project
    def update_metadata_summary_counts(sample_ids, old_project, new_project)
      # Build metadata summary payload for transferred samples
      metadata_payload = build_metadata_payload_from_samples(sample_ids)

      old_namespaces = namespaces_for_transfer(old_project.namespace)
      new_namespaces = namespaces_for_transfer(new_project.namespace)

      ActiveRecord::Base.transaction do
        old_project.namespace.update_metadata_summary_by_sample_transfer(
          metadata_payload, old_namespaces, new_namespaces
        )
      end
    end

    # Extract metadata keys and counts from a set of samples.
    #
    # @param sample_ids [Array<Integer>] IDs of samples to analyze
    # @return [Hash{String => Integer}] mapping from metadata key to count of samples with that key
    def build_metadata_payload_from_samples(sample_ids)
      metadata_payload = {}
      Sample.select(
        Arel::Nodes::NamedFunction.new('JSONB_OBJECT_KEYS', [Sample.arel_table[:metadata]]).as('key'),
        Arel.star.count
      ).where(id: sample_ids).group(Arel::Nodes::SqlLiteral.new('key')).each do |sample|
        metadata_payload[sample.key] = sample.count
      end
      metadata_payload
    end

    # Organize samples by their source project.
    #
    # Groups sample IDs by project to allow processing samples from multiple
    # source projects in a single transfer operation.
    #
    # @param transferrable_samples [ActiveRecord::Relation] samples to organize
    # @return [Hash{Integer => Array<Integer>}] mapping from project ID to sample IDs
    def organize_samples_by_project(transferrable_samples)
      project_sample_ids_to_transfer = {}
      transferrable_samples.pluck(:id, :project_id).each do |id, project_id|
        project_sample_ids_to_transfer[project_id] ||= []
        project_sample_ids_to_transfer[project_id] << id
      end
      project_sample_ids_to_transfer
    end

    # Perform the actual sample transfer with database-level locking.
    #
    # Uses PostgreSQL advisory locks to prevent concurrent modifications and
    # an outer join to detect name conflicts. Samples with conflicts are skipped.
    #
    # @param new_project [Project] the target project
    # @param project_sample_ids_to_transfer [Hash{Integer => Array<Integer>}] samples to transfer
    def perform_transfer_with_lock(new_project, project_sample_ids_to_transfer, transfer_job_id) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      conflicting_samples = Arel::Table.new(Sample.table_name, as: 'conflicting_samples')

      # Logidze.with_meta({ transfer_job_id: }) do
      Sample.transaction do
        lock_id = Zlib.crc32("project_#{new_project.puid}_samples_lock").to_i
        Sample.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")

        project_sample_ids_to_transfer.each do |project_id, sample_ids|
          # Transfer samples that do not have name conflicts in the target project

          Logidze.with_meta({ transfer_job_id:, previous_project_id: project_id }) do
            Sample.where(id: sample_ids, project_id: project_id).where.not(
              id: Sample.joins(Sample.arel_table.create_join(conflicting_samples,
                                                             Arel::Nodes::On.new(
                                                               conflicting_samples[:name].eq(Sample.arel_table[:name])
                                                             ), Arel::Nodes::OuterJoin))
                        .where(conflicting_samples[:project_id].eq(new_project.id).and(
                                 conflicting_samples[:deleted_at].eq(nil)
                               ))
                        .where(id: sample_ids).select(:id)
            ).update_all(project_id: new_project.id, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
          end
        end
      end
    end

    def find_transferred_samples_with_log_data(sample_ids, new_project_id, transfer_job_id)
      Sample.with_log_data.where(
        id: sample_ids, project_id: new_project_id
      ).where(
        "#{LATEST_META} ->> 'transfer_job_id' = ?", transfer_job_id
      )
    end

    def find_transferred_samples_with_log_data_group_by_project(sample_ids, new_project_id, transfer_job_id)
      transferred_samples = Sample.with_log_data.select(
        "samples.*, #{LATEST_META} ->> 'previous_project_id' AS previous_project_id"
      ).where(
        id: sample_ids, project_id: new_project_id
      ).where(
        "#{LATEST_META} ->> 'transfer_job_id' = ?", transfer_job_id
      )

      return [] if transferred_samples.empty?

      transferred_samples.group_by(&:previous_project_id)
    end

    # Inspect samples that were attempted for transfer and record any errors
    # on the service namespace for samples that could not be moved.
    #
    # This method examines the set of sample ids provided for each source
    # project and compares them to the ids that were actually transferred
    # (as returned by `perform_transfer_with_lock`). For each sample that was
    # not transferred it determines one of three outcomes:
    # - the sample already existed in the target project: add
    #   `target_project_duplicate` error
    # - the sample could not be transferred because a sample with the same
    #   name already exists in the target project: add `sample_exists` error
    #
    # The errors are added to `@namespace.errors` so callers can surface them
    # to the user.
    #
    # @param sample_ids [Array<Integer>] the IDs of samples that were attempted for transfer
    # @param new_project_id [Integer] the target project receiving samples
    # @param transfer_job_id [Integer] the ID of the transfer job
    #
    # @return [void] side-effects by adding messages to `@namespace.errors`
    def add_transfer_errors(sample_ids, new_project_id, transfer_job_id) # rubocop:disable Metrics/MethodLength
      transferred_sample_ids = find_transferred_samples_with_log_data(
        sample_ids, new_project_id, transfer_job_id
      ).pluck(:id)

      untransferred_sample_ids = sample_ids - transferred_sample_ids
      return if untransferred_sample_ids.empty?

      filtered_samples = filter_sample_ids(untransferred_sample_ids, 'transfer', true)
      # filtered_sample_ids are samples that should have transferred based on authorization / sample id validity.
      # All that is left in this list are transfer conflict errors
      return if filtered_samples.empty?

      filtered_samples.each do |sample|
        if sample.project_id == new_project_id
          # The attempted transfer targeted the same project the sample
          # already lives in: report as a target-project duplicate.
          @namespace.errors.add(
            :samples, I18n.t('services.samples.transfer.target_project_duplicate', sample_name: sample.name)
          )
        else
          # Generic conflict: a sample with the same name exists in the
          # target project and prevented the transfer.
          @namespace.errors.add(
            :samples, I18n.t('services.samples.transfer.sample_exists', sample_name: sample.name,
                                                                        sample_puid: sample.puid)
          )
        end
      end
    end

    # Update sample counts and create audit trail activities for the transfer.
    #
    # Orchestrates updates to project/group sample counts and creates activities
    # documenting the transfer for both source and target projects. Aggregates
    # group-level activities when applicable.
    #
    # @param sample_ids [Array<Integer>] IDs of samples that were transferred
    # @param old_project [Project] the source project
    # @param new_project [Project] the target project
    def update_samples_count_and_create_activities(sample_ids, old_project, new_project)
      return if sample_ids.empty?

      group_activity_data = []

      data = fetch_transferred_sample_data(sample_ids) # TODO: can this be optimized

      update_samples_count(old_project, new_project, sample_ids.size)

      process_project_transfer_activity(old_project, new_project, data, group_activity_data)

      # Broadcast refreshes to old project and parent namespaces
      old_project.broadcast_refresh_later_to_samples_table

      new_project.broadcast_refresh_later_to_samples_table

      create_group_activity(group_activity_data) if @namespace.group_namespace? && group_activity_data.any?
    end

    # Fetch name and puid data for transferred samples.
    #
    # @param sample_ids [Array<Integer>] IDs of samples to fetch
    # @return [Array<Hash>] array of hashes with :sample_name and :sample_puid keys
    def fetch_transferred_sample_data(sample_ids)
      Sample.where(id: sample_ids).pluck(:name, :puid).map do |name, puid|
        { sample_name: name, sample_puid: puid }
      end
    end

    # Create activities and update group aggregation for a project transfer.
    #
    # Records transfer events in both source and target project namespaces,
    # and aggregates data for group-level activity when applicable.
    #
    # @param old_project [Project] the source project
    # @param new_project [Project] the target project
    # @param data [Array<Hash>] transferred sample data with :sample_name, :sample_puid
    # @param group_activity_data [Array] accumulator for group-level activities
    def process_project_transfer_activity(old_project, new_project, data, group_activity_data) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      ext_details = ExtendedDetail.create!(details: { transferred_samples_count: data.size,
                                                      transferred_samples_data: data })

      create_project_activity(old_project.namespace, ext_details.id,
                              'namespaces_project_namespace.samples.transfer',
                              {
                                target_project_puid: new_project.puid,
                                target_project: new_project.id,
                                transferred_samples_count: data.size,
                                action: 'sample_transfer'
                              })

      create_project_activity(new_project.namespace, ext_details.id,
                              'namespaces_project_namespace.samples.transferred_from',
                              {
                                source_project_puid: old_project.puid,
                                source_project: old_project.id,
                                transferred_samples_count: data.size,
                                action: 'sample_transfer'
                              })

      return unless @namespace.group_namespace?

      group_activity_data.concat(data.map do |entry|
        entry.merge({ source_project_name: old_project.name,
                      source_project_id: old_project.id,
                      source_project_puid: old_project.puid,
                      target_project_name: new_project.name,
                      target_project_id: new_project.id,
                      target_project_puid: new_project.puid })
      end)
    end

    # Create an activity record for a project's namespace.
    #
    # Records the transfer action with extended details and associates it
    # with the namespace's activity stream.
    #
    # @param namespace [Namespace] the namespace recording the activity
    # @param ext_details_id [Integer] ID of the extended details record
    # @param key [String] the i18n key for the activity type
    # @param params [Hash] activity parameters
    def create_project_activity(namespace, ext_details_id, key, params)
      activity = namespace.create_activity key: key,
                                           owner: current_user,
                                           parameters: params

      activity.create_activity_extended_detail(extended_detail_id: ext_details_id,
                                               activity_type: 'sample_transfer')
    end

    # Create an aggregate activity record for a group namespace.
    #
    # Records sample transfers at the group level, consolidating data from
    # all source and target projects involved in the transfer batch.
    #
    # @param group_activity_data [Array<Hash>] consolidated transfer data across projects
    def create_group_activity(group_activity_data)
      ext_details = ExtendedDetail.create!(details: { transferred_samples_count: group_activity_data.size,
                                                      transferred_samples_data: group_activity_data })

      activity = @namespace.create_activity key: 'group.samples.transfer',
                                            owner: current_user,
                                            parameters:
                                         {
                                           transferred_samples_count: group_activity_data.size,
                                           action: 'group_sample_transfer'
                                         }

      activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                               activity_type: 'group_sample_transfer')
    end
  end
end
