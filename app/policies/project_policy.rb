# frozen_string_literal: true

# Policy for projects authorization
class ProjectPolicy < ApplicationPolicy
  alias_rule :create?, :edit?, :update?, :transfer?, :new?, :allowed_to_modify_samples?,
             to: :allowed_to_modify_project?
  alias_rule :allowed_to_view_samples?, :show?, :activity?, to: :allowed_to_view_project?
  alias_rule :destroy?, to: :allowed_to_destroy?

  def allowed_to_view_project?
    return true if record.namespace.parent.owner == user

    can_view?(record.namespace)
  end

  def allowed_to_modify_project?
    return true if record.namespace.parent.owner == user

    can_modify?(record.namespace)
  end

  def allowed_to_destroy?
    return true if record.namespace.parent.owner == user

    can_destroy?(record.namespace)
  end

  scope_for :relation do |relation|
    relation.where(namespace: { parent: user.groups.self_and_descendant_ids })
            .include_route.order(updated_at: :desc).or(relation.where(namespace: { parent: user.namespace })
            .include_route.order(updated_at: :desc))
  end
end
