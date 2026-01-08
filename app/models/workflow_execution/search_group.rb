# frozen_string_literal: true

# Model to represent workflow execution search group
# Used as part of advanced search functionality for filtering workflow executions
# Contains multiple search conditions that are combined with AND logic
# Multiple groups are combined with OR logic
class WorkflowExecution::SearchGroup < AdvancedSearchGroup # rubocop:disable Style/ClassAndModuleChildren
  self.condition_class = WorkflowExecution::SearchCondition
end
