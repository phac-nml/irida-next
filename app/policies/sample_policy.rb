# frozen_string_literal: true

# Policy samples authorization
class SamplePolicy < ApplicationPolicy
  def destroy_attachment? # rubocop:disable Metrics/AbcSize
    return true if record.project.namespace.parent.user_namespace? && record.project.namespace.parent.owner == user
    return true if Member.namespace_owners_include_user?(user, record.project.namespace) == true

    details[:name] = record.name
    false
  end

  scope_for :relation, :namespace_samples do |relation, options| # rubocop:disable Metrics/BlockLength
    namespace = options[:namespace]
    minimum_access_level = if options.key?(:minimum_access_level)
                             options[:minimum_access_level]
                           else
                             Member::AccessLevel::GUEST
                           end

    next relation.none unless Member.effective_access_level(namespace, user) >= minimum_access_level

    if namespace.type == Namespaces::ProjectNamespace.sti_name
      relation.where(project_id: namespace.project.id).select(:id)
    elsif namespace.type == Group.sti_name
      relation
        .with(
          direct_group_projects_samples: relation.joins(project: [:namespace])
                                .where(namespace: { parent_id: namespace.self_and_descendant_ids }).includes(:project)
                                .select(:id),
          linked_group_projects_samples: relation.joins(project: [:namespace]).where(project: { namespace: Namespace
            .where(
              id: NamespaceGroupLink
                      .where(group: namespace.self_and_descendants).not_expired
                      .where(group_access_level: minimum_access_level..)
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
end
