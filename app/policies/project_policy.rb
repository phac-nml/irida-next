# Policies for projects
class ProjectPolicy < ApplicationPolicy
  alias_rule :create?, :destroy?, :edit?, :update?, :transfer?, :new?, to: :allowed_to_modify_project?
  alias_rule :allowed_to_view_members?, :allowed_to_view_samples?, :show?, :activity?, to: :allowed_to_view_project?

  def allowed_to_view_project?
    return true if record.namespace.owner == user

    Member.exists?(namespace: record.namespace.self_and_ancestors, user:)
  end

  def allowed_to_modify_project?
    return true if record.namespace.owner == user

    Member.exists?(namespace: record.namespace.self_and_ancestors, user:, access_level: Member::AccessLevel::OWNER)
  end

  scope_for :relation do |relation|
    relation.include_route.where(id: Member.where(user:).select(:namespace_id))
            .or(relation.include_route.where(creator: user))
  end
end
