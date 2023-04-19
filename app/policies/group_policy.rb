# frozen_string_literal: true

# Policy for groups authorization
class GroupPolicy < ApplicationPolicy
  alias_rule :create?, :destroy?, :edit?, :update?, :new?, to: :allowed_to_modify_group?
  alias_rule :allowed_to_view_members?, :show?, to: :allowed_to_view_group?

  def allowed_to_view_group?
    return true if record.owner == user

    can_view?(record)
  end

  def allowed_to_modify_group?
    return true if record.owner == user

    can_modify?(record)
  end

  scope_for :relation do |relation|
    relation.include_route.where(id: Member.where(user:).select(:namespace_id))
            .or(relation.include_route.where(owner: user))
  end
end
