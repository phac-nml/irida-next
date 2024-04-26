# frozen_string_literal: true

# Policy for workflow execution authorization
class WorkflowExecutionPolicy < ApplicationPolicy
  def export_workflow_execution_data?
    return true if record.submitter.id == user.id

    details[:id] = record.id
    false
  end

  def index?
    return true if Member.can_view?(user, record.namespace) == true

    details[:id] = record.id
    false
  end

  def destroy?
    return true if record.submitter.id == user.id
    return true if Member.can_modify?(user, record.namespace) == true

    details[:id] = record.id
    false
  end

  def new?
    return true if record.submitter.automation_bot? == true
    return true if Member.can_submit_workflow?(user, record.namespace)

    details[:id] = record.id
    false
  end

  def show?
    return true if record.submitter.id == user.id
    return true if Member.can_view?(user, record.namespace) == true

    details[:id] = record.id
    false
  end

  def create?
    return true if record.submitter.automation_bot? == true
    return true if Member.can_submit_workflow?(user, record.namespace)

    details[:id] = record.id
    false
  end

  def cancel?
    return true if record.submitter.id == user.id
    return true if record.submitter.automation_bot? == true
    return true if Member.can_modify?(user, record.namespace) == true

    details[:id] = record.id
    false
  end

  def create_automated_workflow_executions?
    return true if Member.can_modify?(user, record.namespace) == true

    details[:id] = record.id
    false
  end

  def destroy_automated_workflow_executions?
    return true if Member.can_modify?(user, record.namespace) == true

    details[:id] = record.id
    false
  end

  def update_automated_workflow_executions?
    return true if Member.can_modify?(user, record.namespace) == true

    details[:id] = record.id
    false
  end

  def view_automated_workflow_executions?
    return true if Member.can_view?(user, record.namespace) == true

    details[:id] = record.id
    false
  end
end
