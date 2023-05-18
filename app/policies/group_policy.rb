# frozen_string_literal: true

# Policy for groups authorization
class GroupPolicy < NamespacePolicy
  alias_rule :create?, :edit?, :update?, :new?, to: :manage?
  alias_rule :show?, :index?, to: :view?

  def view?
    return true if can_view?(record) == true

    details[:name] = record.name
    false
  end

  def manage?
    return true if can_modify?(record) == true

    details[:name] = record.name
    false
  end

  def destroy?
    return true if can_destroy?(record) == true

    details[:name] = record.name
    false
  end

  def transfer_to_namespace?
    return true if can_transfer?(record) == true

    details[:name] = record.name
    false
  end

  scope_for :relation do |_relation|
    user.groups.self_and_descendants.include_route
  end
end
