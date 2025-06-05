# frozen_string_literal: true

# Policy samples authorization
class SamplePolicy < ApplicationPolicy
  def effective_access_level # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
    return unless record.instance_of?(Sample)

    if record.project&.namespace&.parent&.user_namespace? && record.project&.namespace&.parent&.owner == user
      @access_level = Member::AccessLevel::OWNER
    end

    @access_level ||= Member.effective_access_level(record.project.namespace, user)
    @access_level
  end

  def destroy_attachment?
    return true if effective_access_level == Member::AccessLevel::OWNER

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
      relation.where(project_id: namespace.project.id)
    elsif namespace.type == Group.sti_name
      relation
        .with(
          direct_group_projects: Project.joins(:namespace)
                                .where(namespace: { parent_id: namespace.self_and_descendant_ids }).select(:id),
          linked_group_projects: Project.where(namespace_id: Namespace
            .where(
              id: NamespaceGroupLink
                      .not_expired
                      .where(group_id: namespace.self_and_descendant_ids, group_access_level: minimum_access_level..)
                      .select(:namespace_id)
            ).self_and_descendant_ids)
          .select(:id)
        ).where(
          Arel.sql(
            'samples.project_id in (select id from direct_group_projects)
          or samples.project_id in (select id from linked_group_projects)'
          )
        )
    end
  end
end
