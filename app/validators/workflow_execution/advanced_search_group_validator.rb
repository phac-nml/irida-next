# frozen_string_literal: true

# Validator for advanced search groups in WorkflowExecution queries.
class WorkflowExecution::AdvancedSearchGroupValidator < AdvancedSearch::GroupValidator # rubocop:disable Style/ClassAndModuleChildren
  private

  def allowed_fields
    %w[id name run_id state created_at updated_at]
  end

  def date_fields
    %w[created_at updated_at]
  end
end
