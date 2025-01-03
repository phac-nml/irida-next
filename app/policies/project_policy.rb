# frozen_string_literal: true

# Policy for projects authorization
class ProjectPolicy < NamespacePolicy # rubocop:disable Metrics/ClassLength
  def activity?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_view?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def view_history?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_view?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def destroy?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_destroy?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def edit?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_modify?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def new?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_create?(user, record.namespace) == true

    details[:name] = record.namespace.parent.name
    false
  end

  def read?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_view?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def transfer?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_transfer?(user, record.namespace)

    details[:name] = record.name
    false
  end

  def update?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_modify?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def sample_listing?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_view?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def create_sample?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_create_sample?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def destroy_sample?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.namespace_owners_include_user?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def read_sample?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_view?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def update_sample?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_modify_sample?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def transfer_sample?
    return true if Member.can_transfer_sample?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def transfer_sample_into_project?
    return true if Member.user_has_namespace_maintainer_access?(user, record.namespace, false) &&
                   Member.can_transfer_sample_to_project?(user, record.namespace, false) == true
    return true if Member.can_transfer_sample_to_project?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def clone_sample?
    return true if Member.can_clone_sample?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def clone_sample_into_project?
    return true if Member.can_clone_sample_to_project?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def export_data?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_export_data?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def submit_workflow?
    return true if Member.can_submit_workflow?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def view_attachments?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_view_attachments?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def create_attachment?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_create_attachment?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def destroy_attachment?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_destroy_attachment?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  scope_for :relation do |relation| # rubocop:disable Metrics/BlockLength
    relation
      .with(
        personal_project_namespaces: Namespaces::ProjectNamespace.where(parent_id: user.namespace&.id),
        direct_project_namespaces: user.members.not_expired.joins(:namespace).where(
          namespace: { type: Namespaces::ProjectNamespace.sti_name }
        ).select(:namespace_id),
        group_project_namespaces: Namespaces::ProjectNamespace.where(parent_id:
          Namespace.where(id: user.members.not_expired.select(:namespace_id)).self_and_descendant_ids.where(
            type: Group.sti_name
          )).select(:id),
        group_linked_project_namespaces: Namespaces::ProjectNamespace.where(
          parent_id: Group.where(id: NamespaceGroupLink.where(group: Group.where(
            id: user.members.not_expired.joins(:namespace).select(:namespace_id)
          ).self_and_descendants).not_expired.select(:namespace_id)).self_and_descendants
        ).select(:id),
        direct_linked_project_namespaces: Namespaces::ProjectNamespace.where(id: NamespaceGroupLink.where(
          group: Group.where(id: user.members.not_expired.joins(:namespace).select(:namespace_id)).self_and_descendants
        ).not_expired.select(:namespace_id)).select(:id)
      ).where(
        Arel.sql(
          'projects.namespace_id in (select id from personal_project_namespaces)
        or projects.namespace_id in (select namespace_id from direct_project_namespaces)
        or projects.namespace_id in (select id from group_project_namespaces)
        or projects.namespace_id in (select id from group_linked_project_namespaces)
        or projects.namespace_id in (select id from direct_linked_project_namespaces)'
        )
      ).include_route
  end

  scope_for :relation, :project_samples_transferable do |relation, options|
    if Member.user_has_namespace_maintainer_access?(user, options[:project].namespace, false)
      top_level_ancestor = options[:project].parent.self_and_ancestors.find_by(type: Group.sti_name, parent: nil)
      group_and_subgroup_ids = top_level_ancestor.self_and_descendant_ids

      authorized_scope(relation, type: :relation,
                                 as: :manageable_without_shared_links)
        .where(namespace: { parent_id: group_and_subgroup_ids })

    else
      authorized_scope(relation, type: :relation, as: :manageable)
    end
  end

  scope_for :relation, :manageable_without_shared_links do |relation|
    relation.with(
      direct_project_namespaces: user.members.not_expired.joins(:namespace).where(
        access_level: Member::AccessLevel.manageable,
        namespace: { type: Namespaces::ProjectNamespace.sti_name }
      ).select(:namespace_id),
      group_project_namespaces: Namespaces::ProjectNamespace.where(parent: Namespace.where(id:
        user.members.not_expired.joins(:namespace).where(
          namespace_id: user.groups.self_and_descendants,
          access_level: Member::AccessLevel.manageable,
          namespace: { type: Group.sti_name }
        ).select(:namespace_id), type: Group.sti_name).self_and_descendant_ids).select(:id)
    ).where(
      Arel.sql(
        'projects.namespace_id in (select namespace_id from direct_project_namespaces)
        or projects.namespace_id in (select id from group_project_namespaces)'
      )
    ).include_route
  end

  scope_for :relation, :manageable do |relation| # rubocop:disable Metrics/BlockLength
    relation.with(
      personal_project_namespaces: Namespaces::ProjectNamespace.where(parent_id: user.namespace&.id),
      direct_project_namespaces: user.members.not_expired.joins(:namespace).where(
        access_level: Member::AccessLevel.manageable,
        namespace: { type: Namespaces::ProjectNamespace.sti_name }
      ).select(:namespace_id),
      group_project_namespaces: Namespaces::ProjectNamespace.where(parent: Namespace.where(
        id: user.members.not_expired.joins(:namespace).where(
          namespace_id: user.groups.self_and_descendants,
          access_level: Member::AccessLevel.manageable,
          namespace: { type: Group.sti_name }
        ).select(:namespace_id), type: Group.sti_name
      ).self_and_descendant_ids).select(:id),
      group_linked_project_namespaces: Namespaces::ProjectNamespace.where(id: NamespaceGroupLink.where(
        group: user.groups.where(id: user.members.not_expired.joins(:namespace)
        .where(access_level: Member::AccessLevel.manageable,
               namespace: { type: Group.sti_name })
                                                        .select(:namespace_id)).self_and_descendants,
        group_access_level: Member::AccessLevel.manageable
      ).not_expired.select(:namespace_id)).select(:id),
      direct_linked_project_namespaces: Namespaces::ProjectNamespace.where(
        parent_id: Group.where(id: NamespaceGroupLink.where(
          group: user.groups.where(id: user.members.not_expired.joins(:namespace)
          .where(access_level: Member::AccessLevel.manageable,
                 namespace: { type: Group.sti_name })
                                                          .select(:namespace_id)).self_and_descendants,
          group_access_level: Member::AccessLevel.manageable,
          namespace_type: Group.sti_name
        ).not_expired.select(:namespace_id)).self_and_descendant_ids
      ).select(:id)
    ).where(
      Arel.sql(
        'projects.namespace_id in (select id from personal_project_namespaces)
        or projects.namespace_id in (select namespace_id from direct_project_namespaces)
        or projects.namespace_id in (select id from group_project_namespaces)
        or projects.namespace_id in (select id from group_linked_project_namespaces)
        or projects.namespace_id in (select id from direct_linked_project_namespaces)'
      )
    ).include_route
  end

  scope_for :relation, :personal do |relation|
    relation
      .with(
        personal_project_namespaces: Namespaces::ProjectNamespace.where(parent_id: user.namespace&.id)
      )
      .where(
        Arel.sql(
          'projects.namespace_id in (select id from personal_project_namespaces)'
        )
      ).include_route
  end

  scope_for :relation, :group_projects do |relation, options|
    group = options[:group]
    minimum_access_level = if options.key?(:minimum_access_level)
                             options[:minimum_access_level]
                           else
                             Member::AccessLevel::GUEST
                           end

    next relation.none unless Member.effective_access_level(group, user) >= minimum_access_level

    relation
      .with(
        direct_group_project_namespaces: Namespaces::ProjectNamespace.where(
          parent_id: group.self_and_descendants.select(:id)
        ).select(:id),
        linked_group_project_namespaces: Namespace.where(
          id: NamespaceGroupLink
                  .not_expired
                  .where(group_id: group.self_and_descendant_ids, group_access_level: minimum_access_level..)
                  .select(:namespace_id)
        ).self_and_descendants.where(type: 'Project').select(:id)
      ).where(
        Arel.sql(
          'namespace_id in (select id from direct_group_project_namespaces)
          or namespace_id in (select id from linked_group_project_namespaces)'
        )
      )
  end
end
