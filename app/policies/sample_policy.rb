# frozen_string_literal: true

# Policy for samples authorization
class SamplePolicy < ApplicationPolicy
  alias_rule :create?, :destroy?, :edit?, :update?, :new?,
             to: :allowed_to_modify_samples_for_project?
  alias_rule :show, :index, to: :allowed_to_view_samples_for_project?

  def allowed_to_modify_samples_for_project?
    return true if record.project.creator == user

    can_modify?(record.project.namespace)
  end

  def allowed_to_view_samples_for_project?
    return true if record.project.creator == user

    can_view?(record.project.namespace)
  end

  scope_for :relation do |relation, project_id|
    relation.where(project_id)
  end
end
