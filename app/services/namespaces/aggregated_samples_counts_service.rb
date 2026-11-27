# frozen_string_literal: true

module Namespaces
  # Loads shared and direct sample totals for a batch of groups in one query.
  #
  # Used anywhere a list of groups is rendered (e.g. the groups dashboard, a
  # group's subgroups/shared-namespaces tabs) to avoid one
  # `aggregated_samples_count` query per row.
  #
  # Each group's shared-samples relation is built entirely from the same
  # scopes `Group#aggregated_samples_count` already uses (`self_and_descendant_ids`,
  # `NamespaceGroupLink.not_expired.with_access`, `self_and_descendants_of_type`),
  # so the two implementations stay in sync. The individual per-group
  # relations are then combined with `UNION ALL` so the whole batch resolves
  # in a single round trip instead of one query per group.
  class AggregatedSamplesCountsService
    def initialize(groups:)
      @groups = groups
    end

    def execute
      return {} if @groups.empty?

      shared_counts = shared_samples_counts_by_group

      @groups.to_h { |group| [group.id, group.samples_count + shared_counts.fetch(group.id, 0)] }
    end

    private

    def shared_samples_counts_by_group
      sql = @groups.map { |group| "(#{shared_samples_relation(group).to_sql})" }.join(' UNION ALL ')

      Project.connection.select_all(sql).to_h do |row|
        [row['dashboard_group_id'], row['shared_samples_count'].to_i]
      end
    end

    # Mirrors Group#aggregated_samples_count: namespaces shared with the group (or any of
    # its descendants) via an active NamespaceGroupLink, restricted to project namespaces,
    # excluding project namespaces already owned by the group itself.
    def shared_samples_relation(group)
      quoted_group_id = Project.connection.quote(group.id)

      Project.where(namespace_id: shared_project_namespace_ids(group))
             .select(
               Arel.sql("#{quoted_group_id} AS dashboard_group_id"),
               Arel.sql('COALESCE(SUM(projects.samples_count), 0) AS shared_samples_count')
             )
    end

    def shared_project_namespace_ids(group)
      shared_namespace_ids = NamespaceGroupLink.not_expired.with_access
                                               .where(group_id: group.self_and_descendant_ids)
                                               .select(:namespace_id)
      own_project_namespace_ids = group.self_and_descendants_of_type(
        Namespaces::ProjectNamespace.sti_name
      ).select(:id)

      Namespace.where(id: shared_namespace_ids)
               .self_and_descendants
               .where(type: Namespaces::ProjectNamespace.sti_name)
               .where.not(id: own_project_namespace_ids)
               .select(:id)
    end
  end
end
