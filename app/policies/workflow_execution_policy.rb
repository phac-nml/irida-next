# frozen_string_literal: true

# Policy for workflow execution authorization
class WorkflowExecutionPolicy < ApplicationPolicy
  def effective_access_level(current_user = user)
    return unless record.instance_of?(WorkflowExecution)

    @access_level ||= {}

    user_type = if project_automation_bot?(current_user)
                  :project_automation_bot
                else
                  :human_user
                end

    @access_level[user_type] ||= Member.effective_access_level(record.namespace, current_user)
    @access_level[user_type]
  end

  def project_automation_bot?(user)
    User.user_types[user.user_type] == User.user_types[:project_automation_bot]
  end

  def destroy? # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    unless project_automation_bot?(user)
      return true if record.submitter.id == user.id
      return true if Member::AccessLevel.manageable.include?(effective_access_level)
    end

    if (record.namespace.type == Namespaces::ProjectNamespace.sti_name) &&
       (record.submitter.id == record.namespace.automation_bot.id) &&
       (record.namespace.automation_bot.id == user.id) &&
       Member::AccessLevel.manageable.include?(effective_access_level(record.namespace.automation_bot))
      return true
    end

    details[:name] = record.namespace.name
    details[:namespace_type] = record.namespace.type
    false
  end

  def read? # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    unless project_automation_bot?(user)
      return true if record.submitter.id == user.id
      return true if effective_access_level(user) > Member::AccessLevel::NO_ACCESS
    end

    if (record.namespace.type == Namespaces::ProjectNamespace.sti_name) &&
       (record.submitter.id == record.namespace.automation_bot.id) &&
       (record.namespace.automation_bot.id == user.id) &&
       (effective_access_level(record.namespace.automation_bot) > Member::AccessLevel::NO_ACCESS)
      return true
    end

    details[:id] = record.id
    false
  end

  def create?
    return true if effective_access_level >= Member::AccessLevel::ANALYST

    details[:name] = record.namespace.name
    details[:namespace_type] = record.namespace.type
    false
  end

  def cancel? # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    unless project_automation_bot?(user)
      return true if record.submitter.id == user.id
      return true if Member::AccessLevel.manageable.include?(effective_access_level)
    end

    if (record.namespace.type == Namespaces::ProjectNamespace.sti_name) &&
       (record.submitter.id == record.namespace.automation_bot.id) &&
       (record.namespace.automation_bot.id == user.id) &&
       Member::AccessLevel.manageable.include?(effective_access_level(record.namespace.automation_bot))
      return true
    end

    details[:name] = record.namespace.name
    details[:namespace_type] = record.namespace.type
    false
  end

  def update?
    return true if record.submitter.id == user.id
    return true if effective_access_level >= Member::AccessLevel::ANALYST

    details[:id] = record.id
    false
  end

  scope_for :relation, :automated do |relation, options|
    project = options[:project]

    relation.where(submitter: project.namespace.automation_bot)
  end

  scope_for :relation, :user do |relation, options|
    user = options[:user]

    relation.where(submitter_id: user.id)
  end
end
