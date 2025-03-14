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

  def destroy? # rubocop:disable Metrics/AbcSize
    return true if record.submitter.id == user.id

    # submitted by automation bot and user has managable access
    if (record.namespace.type == Namespaces::ProjectNamespace.sti_name) &&
       (record.submitter.id == record.namespace.automation_bot.id) &&
       Member::AccessLevel.manageable.include?(effective_access_level)
      return true
    end

    details[:name] = record.namespace.name
    details[:namespace_type] = record.namespace.type
    false
  end

  def read? # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    return true if record.submitter.id == user.id

    # submitted by automation bot and user has access
    if (record.namespace.type == Namespaces::ProjectNamespace.sti_name) &&
       record.namespace.automation_bot && (record.submitter.id == record.namespace.automation_bot.id) &&
       (effective_access_level > Member::AccessLevel::NO_ACCESS)
      return true
    end

    # shared by submitter to namespace
    return true if record.shared_with_namespace && (effective_access_level > Member::AccessLevel::NO_ACCESS)

    details[:id] = record.id
    false
  end

  def create?
    return true if effective_access_level >= Member::AccessLevel::ANALYST

    details[:name] = record.namespace.name
    details[:namespace_type] = record.namespace.type
    false
  end

  def cancel? # rubocop:disable Metrics/AbcSize
    return true if record.submitter.id == user.id

    # submitted by automation bot and user has managable access
    if (record.namespace.type == Namespaces::ProjectNamespace.sti_name) &&
       record.namespace.automation_bot && (record.submitter.id == record.namespace.automation_bot.id) &&
       Member::AccessLevel.manageable.include?(effective_access_level)
      return true
    end

    details[:name] = record.namespace.name
    details[:namespace_type] = record.namespace.type
    false
  end

  def edit? # rubocop:disable Metrics/AbcSize
    return true if record.submitter.id == user.id

    # submitted by automation bot and user is analyst or higher
    if (record.namespace.type == Namespaces::ProjectNamespace.sti_name) &&
       record.namespace.automation_bot && (record.submitter.id == record.namespace.automation_bot.id) &&
       (effective_access_level >= Member::AccessLevel::ANALYST)
      return true
    end

    details[:id] = record.id
    false
  end

  def update? # rubocop:disable Metrics/AbcSize
    return true if record.submitter.id == user.id

    # submitted by automation bot and user is analyst or higher
    if (record.namespace.type == Namespaces::ProjectNamespace.sti_name) &&
       record.namespace.automation_bot && (record.submitter.id == record.namespace.automation_bot.id) &&
       (effective_access_level >= Member::AccessLevel::ANALYST)
      return true
    end

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

  scope_for :relation, :automated_and_shared do |relation, options|
    project = options[:project]

    relation.where(submitter: project.namespace.automation_bot)
            .or(relation.where(namespace_id: project.namespace.id, shared_with_namespace: true))
  end

  scope_for :relation, :group_shared do |relation, options|
    group = options[:group]

    relation.where(namespace_id: group.id, shared_with_namespace: true)
  end
end
