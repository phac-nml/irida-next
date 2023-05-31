# frozen_string_literal: true

# Policy for projects authorization
class ProjectPolicy < NamespacePolicy
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
    return true if Member.can_transfer?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  def transfer_sample_into_project?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if Member.can_transfer_into_namespace?(user, record.namespace) == true

    details[:name] = record.name
    false
  end

  scope_for :relation do |relation|
    relation.where(namespace: { parent: user.groups.self_and_descendant_ids })
            .include_route.order(updated_at: :desc).or(relation.where(namespace: { parent: user.namespace })
            .include_route.order(updated_at: :desc))
  end
end
