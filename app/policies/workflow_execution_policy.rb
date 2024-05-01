# frozen_string_literal: true

# Policy for workflow execution authorization
class WorkflowExecutionPolicy < ApplicationPolicy
  def export_workflow_execution_data?
    return true if record.submitter.id == user.id

    details[:id] = record.id
    false
  end

  def destroy? # rubocop:disable Metrics/AbcSize
    return true if record.submitter.id == user.id
    if (record.namespace.type == Namespaces::ProjectNamespace.sti_name) &&
       (record.submitter.id == record.namespace.automation_bot.id) &&
       (Member.can_view?(record.namespace.automation_bot, record.namespace) == true)
      return true
    end

    details[:name] = record.namespace.name
    details[:namespace_type] = record.namespace.type
    false
  end

  def read? # rubocop:disable Metrics/AbcSize
    return true if record.submitter.id == user.id
    if (record.namespace.type == Namespaces::ProjectNamespace.sti_name) &&
       (record.submitter.id == record.namespace.automation_bot.id) &&
       (Member.can_view?(record.namespace.automation_bot, record.namespace) == true)
      return true
    end

    details[:id] = record.id
    false
  end

  def create?
    return true if Member.can_submit_workflow?(user, record.namespace)

    details[:name] = record.namespace.name
    details[:namespace_type] = record.namespace.type
    false
  end

  def cancel? # rubocop:disable Metrics/AbcSize
    return true if record.submitter.id == user.id
    if (record.namespace.type == Namespaces::ProjectNamespace.sti_name) &&
       (record.submitter.id == record.namespace.automation_bot.id) &&
       (Member.can_view?(record.namespace.automation_bot, record.namespace) == true)
      return true
    end

    details[:name] = record.namespace.name
    details[:namespace_type] = record.namespace.type
    false
  end

  scope_for :relation, :namespace do |relation, options|
    project = options[:project]

    relation.where(namespace: project.namespace)
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
