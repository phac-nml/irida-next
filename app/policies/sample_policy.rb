# frozen_string_literal: true

# Policy for samples authorization
class SamplePolicy < ApplicationPolicy
  alias_rule :create?, :edit?, :update?, :new?,
             to: :allowed_to_modify_samples_for_project?
  alias_rule :show?, :index?, to: :allowed_to_view_samples_for_project?
  alias_rule :destroy?, to: :allowed_to_destroy_sample

  def allowed_to_modify_samples_for_project?
    return true if record.namespace.parent.owner == user

    can_modify?(record.project.namespace)
  end

  def allowed_to_view_samples_for_project?
    return true if record.namespace.parent.owner == user

    can_view?(record.project.namespace)
  end

  def allowed_to_destroy_sample?
    return true if record.namespace.parent.owner == user

    can_destroy?(record.project.namespace)
  end

  scope_for :relation do |relation, scope_options|
    relation.where(project_id: scope_options[:project_id])
  end
end
