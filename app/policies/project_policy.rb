# frozen_string_literal: true

# Policy for projects authorization
class ProjectPolicy < NamespacePolicy # rubocop:disable Metrics/ClassLength
  def activity?
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
    return true if Member.can_create?(user, record.namespace) == true

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
    return true if Member.can_modify?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def transfer_sample?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_transfer_sample?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def transfer_sample_into_project?
    return true if Member.can_transfer_sample_to_project?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  scope_for :relation do |relation|
    relation
      .with(
        personal_projects: relation.where(namespace: user.namespace.project_namespaces).select(:id),
        direct_projects: relation.where(
          namespace: user.members.joins(:namespace).where(
            namespace: { type: Namespaces::ProjectNamespace.sti_name }
          ).select(:namespace_id)
        ).select(:id),
        group_projects: relation.joins(:namespace).where(namespace: { parent_id: user.groups.self_and_descendant_ids })
        .select(:id),
        linked_projects: relation.joins(:namespace).where(namespace: { parent_id:
        Group.where(id: NamespaceGroupLink
          .where(group: user.groups.self_and_descendants).not_expired.select(:namespace_id)) }).select(:id)
      ).where(
        Arel.sql(
          'projects.id in (select * from personal_projects)
          or projects.id in (select * from group_projects)
          or projects.id in (select * from direct_projects)
          or projects.id in (select * from linked_projects)'
        )
      ).include_route
  end

  scope_for :relation, :manageable do |relation|
    relation
      .where(namespace_id: Namespace.where(
        id: Member.where(
          user:,
          access_level: [
            Member::AccessLevel::MAINTAINER,
            Member::AccessLevel::OWNER
          ]
        ).select(:namespace_id)
      ).self_and_descendants.where(type: Namespaces::ProjectNamespace.sti_name).select(:id))
      .include_route
      .or(relation.where(namespace: { parent: user.namespace }))
      .include_route
  end

  scope_for :relation, :personal do |relation|
    relation
      .with(
        personal_projects: relation.where(namespace: user.namespace.project_namespaces).select(:id)
      )
      .where(
        Arel.sql(
          'projects.id in (select * from personal_projects)'
        )
      ).include_route
  end
end
