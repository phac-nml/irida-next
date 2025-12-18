# frozen_string_literal: true

# Shared advanced search functionality for Query models
# Provides common methods for handling advanced search groups, conditions, and sorting
# Used by Sample::Query and WorkflowExecution::Query for DRY principle
module AdvancedSearchable
  extend ActiveSupport::Concern

  # Determines if advanced query is active based on non-empty groups
  # @return [Boolean] true if groups contain non-empty conditions
  def advanced_query?
    return !groups.all?(&:empty?) if groups

    false
  end

  # Parses nested form attributes into SearchGroup and SearchCondition objects
  # Handles the complex nested structure from Rails form submissions
  # @param attributes [Hash] nested hash of group and condition attributes
  def groups_attributes=(attributes)
    groups = []
    attributes.each_value do |group_attributes|
      conditions = []
      group_attributes.each_value do |conditions_attributes|
        conditions_attributes.each_value do |condition_params|
          # Use the appropriate SearchCondition class based on the including model
          condition_class = self.class.name.deconstantize.constantize::SearchCondition
          conditions.push(condition_class.new(condition_params))
        end
      end
      # Use the appropriate SearchGroup class based on the including model
      group_class = self.class.name.deconstantize.constantize::SearchGroup
      groups.push(group_class.new(conditions:))
    end
    assign_attributes(groups:)
  end
end
