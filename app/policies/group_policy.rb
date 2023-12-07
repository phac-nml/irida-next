# frozen_string_literal: true

# Policy for groups authorization
class GroupPolicy < NamespacePolicy
  def create?
    return true if Member.can_create?(user, record) == true

    details[:name] = record.name
    false
  end

  def create_subgroup?
    return true if Member.can_create?(user, record) == true

    details[:name] = record.name
    false
  end

  def destroy?
    return true if Member.can_destroy?(user, record) == true

    details[:name] = record.name
    false
  end

  def edit?
    return true if Member.can_modify?(user, record) == true

    details[:name] = record.name
    false
  end

  def new?
    return true if Member.can_create?(user, record) == true

    details[:name] = record.name
    false
  end

  def read?
    return true if Member.can_view?(user, record) == true

    details[:name] = record.name
    false
  end

  def transfer?
    return true if Member.can_transfer?(user, record)

    details[:name] = record.name
    false
  end

  def transfer_into_namespace?
    return true if Member.can_transfer_into_namespace?(user, record) == true

    details[:name] = record.name
    false
  end

  def update?
    return true if Member.can_modify?(user, record) == true

    details[:name] = record.name
    false
  end

  def member_listing?
    return true if Member.can_view?(user, record) == true

    details[:name] = record.name
    false
  end

  def create_member?
    return true if Member.can_create?(user, record) == true

    details[:name] = record.name
    false
  end

  def destroy_member?
    return true if Member.can_modify?(user, record) == true

    details[:name] = record.name
    false
  end

  def update_member?
    return true if Member.can_modify?(user, record) == true

    details[:name] = record.name
    false
  end

  def sample_listing?
    return true if Member.can_view?(user, record) == true

    details[:name] = record.name
    false
  end

  def link_namespace_with_group?
    return true if Member.can_link_namespace_to_group?(user, record) == true

    details[:name] = record.name
    false
  end

  def unlink_namespace_with_group?
    return true if Member.can_unlink_namespace_from_group?(user, record) == true

    details[:name] = record.name
    false
  end

  def update_namespace_with_group_link?
    return true if Member.can_update_namespace_with_group_link?(user, record) == true

    details[:name] = record.name
    false
  end

  scope_for :relation do |relation|
    relation.with(
      user_groups: relation.where(id: user.members.joins(:namespace).where(namespace: { type: Group.sti_name })
      .not_expired.select(:namespace_id)).self_and_descendant_ids,
      linked_groups: NamespaceGroupLink.where(group: relation.where(id: user.members.joins(:namespace).where(namespace: { type: Group.sti_name })
      .not_expired.select(:namespace_id)).self_and_descendant_ids).select(:namespace_id)
    ).where(
      Arel.sql(
        'namespaces.id in (select * from user_groups)
        or namespaces.id in (select * from linked_groups)'
      )
    )
  end
end
