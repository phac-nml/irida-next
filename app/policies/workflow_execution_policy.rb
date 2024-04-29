# frozen_string_literal: true

# Policy for workflow execution authorization
class WorkflowExecutionPolicy < ApplicationPolicy
  def export_workflow_execution_data?
    return true if record.submitter.id == user.id

    details[:id] = record.id
    false
  end

  def destroy?
    return true if record.submitter.id == user.id
    return true if Member.can_modify?(user, record.namespace) == true

    details[:name] = record.namespace.name
    details[:namespace_type] = record.namespace.type
    false
  end

  def read?
    return true if record.submitter.id == user.id
    return true if Member.can_view?(user, record.namespace) == true

    details[:id] = record.id
    false
  end

  def create?
    return true if Member.can_submit_workflow?(user, record.namespace)

    details[:name] = record.namespace.name
    details[:namespace_type] = record.namespace.type
    false
  end

  def cancel?
    return true if record.submitter.id == user.id
    return true if Member.can_modify?(user, record.namespace) == true

    details[:name] = record.namespace.name
    details[:namespace_type] = record.namespace.type
    false
  end
end
