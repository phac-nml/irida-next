# frozen_string_literal: true

# Policy for projects authorization
class ProjectPolicy < NamespacePolicy
  alias_rule :edit?, :update?, to: :manage?
  alias_rule :index?, :show?, :activity?, to: :view?
  alias_rule :new?, to: :create?

  def view?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if can_view?(record.namespace) == true

    details[:name] = record.name
    false
  end

  def create?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if can_modify?(record.namespace) == true

    details[:name] = record.name
    false
  end

  def manage?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if can_modify?(record.namespace) == true

    details[:name] = record.name
    false
  end

  def destroy?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if can_destroy?(record.namespace) == true

    details[:name] = record.name
    false
  end

  def transfer?
    return true if record.namespace.parent.user_namespace? && record.namespace.parent.owner == user
    return true if can_transfer?(record.namespace)

    details[:name] = record.name
    false
  end

  scope_for :relation do |relation|
    relation.where(namespace: { parent: user.groups.self_and_descendant_ids })
            .include_route.order(updated_at: :desc).or(relation.where(namespace: { parent: user.namespace })
            .include_route.order(updated_at: :desc))
  end
end
