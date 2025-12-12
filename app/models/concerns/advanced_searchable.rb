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
    groups ||= []
    attributes.each_value do |group_attributes|
      conditions ||= []
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

  # Parses sort parameter and extracts column and direction
  # Converts metadata_ prefix to metadata. dot notation for JSONB field access
  # Uses rpartition to handle field names containing spaces
  # @param value [String] sort string in format "column direction" (e.g., "name asc", "metadata_custom_field desc")
  def sort=(value)
    super
    # use rpartition to split on the first space encountered from the right side
    # this allows us to sort by metadata fields which contain spaces
    column, _space, direction = sort.rpartition(' ')
    column = column.gsub('metadata_', 'metadata.') if column.match?(/metadata_/)
    assign_attributes(column:, direction:)
  end
end
