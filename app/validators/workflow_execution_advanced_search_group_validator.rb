# frozen_string_literal: true

# Validator for workflow execution advanced search groups
# Validates search conditions including field names, operators, and values
# Specific to WorkflowExecution attributes and metadata fields
class WorkflowExecutionAdvancedSearchGroupValidator < AdvancedSearchGroupValidatorBase
  private

  def allowed_fields
    %w[id name run_id state created_at updated_at]
  end

  def date_fields
    %w[created_at updated_at]
  end
end
