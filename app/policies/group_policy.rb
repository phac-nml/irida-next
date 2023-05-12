# frozen_string_literal: true

# Policy for groups authorization
class GroupPolicy < NamespacePolicy
  alias_rule :create?, :edit?, :update?, :new?, to: :allowed_to_modify_group?
  alias_rule :show?, :index?, to: :allowed_to_view_group?
  alias_rule :destroy?, to: :allowed_to_destroy?

  def allowed_to_view_group?
    can_view?(record)
  end

  def allowed_to_modify_group?
    can_modify?(record)
  end

  def allowed_to_destroy?
    can_destroy?(record)
  end

  def transfer_to_namespace?
    can_transfer?(record)
  end

  scope_for :relation do |_relation|
    user.groups.self_and_descendants.include_route
  end
end
