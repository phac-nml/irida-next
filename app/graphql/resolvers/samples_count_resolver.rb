# frozen_string_literal: true

module Resolvers
  # Samples Count Resolver
  class SamplesCountResolver < BaseResolver
    def resolve # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      if object.is_a?(Project)
        object.samples_count
      elsif object.group_namespace?
        namespace = object

        Sample
          .with(
            direct_group_projects: Project.joins(:namespace)
                                  .where(namespace: { parent_id: namespace.self_and_descendant_ids }).select(:id),
            linked_group_projects: Project.where(namespace_id: Namespace
              .where(
                id: NamespaceGroupLink
                        .where(group_id: namespace.self_and_descendant_ids)
                        .select(:namespace_id)
              ).self_and_descendant_ids)
            .select(:id)
          ).where(
            Arel.sql(
              'samples.project_id in (select id from direct_group_projects)
          or samples.project_id in (select id from linked_group_projects)'
            )
          ).count
      end
    end
  end
end
