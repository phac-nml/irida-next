# frozen_string_literal: true

# Policy for projects authorization
class ProjectPolicy < ApplicationPolicy
  alias_rule :create?, :destroy?, :edit?, :update?, :transfer?, :new?, :allowed_to_modify_samples?,
             to: :allowed_to_modify_project?
  alias_rule :allowed_to_view_samples?, :show?, :activity?, to: :allowed_to_view_project?

  def allowed_to_view_project?
    return true if record.namespace.owner == user

    can_view?(record.namespace)
  end

  def allowed_to_modify_project?
    return true if record.namespace.owner == user

    can_modify?(record.namespace)
  end

  scope_for :relation do |relation|
    relation.include_route.where(id: Member.where(user:).select(:namespace_id))
            .or(relation.include_route.where(creator: user))
  end
end
