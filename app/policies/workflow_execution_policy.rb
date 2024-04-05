# frozen_string_literal: true

# Policy for workflow execution authorization
class DataExportPolicy < ApplicationPolicy
  def export_workflow_execution_data?
    true if record.submitter.id == user.id
  end

end
