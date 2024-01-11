# frozen_string_literal: true

# Policy samples authorization
class SamplePolicy < ApplicationPolicy
  def destroy_attachment? # rubocop:disable Metrics/AbcSize
    return true if record.project.namespace.parent.user_namespace? && record.project.namespace.parent.owner == user
    return true if Member.namespace_owners_include_user?(user, record.project.namespace) == true

    details[:name] = record.name
    false
  end

  scope_for :relation, :group_samples do |relation, options|
    group = options[:group]

    next relation.none unless Member.can_view?(user, group)

    relation
      .with(
        direct_group_projects_samples: relation.joins(project: [:namespace])
                              .where(namespace: { parent_id: group.self_and_descendant_ids }).includes(:project)
                              .select(:id),
        linked_group_projects_samples: relation.joins(project: [:namespace]).where(project: { namespace: Namespace
        .where(
          id: NamespaceGroupLink
                  .where(group: group.self_and_descendants).not_expired
                  .select(:namespace_id)
        ).self_and_descendants })
        .select(:id)
      ).where(
        Arel.sql(
          'samples.id in (select * from direct_group_projects_samples)
          or samples.id in (select * from linked_group_projects_samples)'
        )
      )
  end
end
