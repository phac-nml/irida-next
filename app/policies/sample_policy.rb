# frozen_string_literal: true

# Policy samples authorization
class SamplePolicy < ApplicationPolicy
  scope_for :relation do |relation, options|
    group = options[:group]

    relation
      .with(
        direct_group_projects_samples: relation.joins(project: [:namespace])
                              .where(namespace: { parent_id: group.self_and_descendant_ids }).includes(:project)
                              .select(:id),
        linked_group_projects_samples: relation.where(project: Project.joins(:namespace).where(namespace:
        {
          parent: Namespace.where(parent: NamespaceGroupLink
          .where(group: group.self_and_descendants).not_expired.select(:namespace_id))
        })).includes(:project)
        .select(:id)
      ).where(
        Arel.sql(
          'samples.id in (select * from direct_group_projects_samples)
          or samples.id in (select * from linked_group_projects_samples)'
        )
      )
  end
end
