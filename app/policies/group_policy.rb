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

  def share_group_with_other_groups?
    return true if Member.can_share_group?(user, record) == true

    details[:name] = record.name
    false
  end

  scope_for :relation do |_relation|
    user.groups.self_and_descendants.include_route
  end
end
