# frozen_string_literal: true

# Shared advanced search functionality for Query models
# Provides common methods for handling advanced search groups, conditions, and sorting
# Used by Sample::Query and WorkflowExecution::Query for DRY principle
module AdvancedSearchable
  extend ActiveSupport::Concern

  # Determines if advanced query is active based on non-empty groups
  # @return [Boolean] true if groups contain non-empty conditions
  def advanced_query?
    groups.present? && groups.any? { |group| !group.empty? }
  end

  # Parses nested form attributes into SearchGroup and SearchCondition objects
  # Handles the complex nested structure from Rails form submissions
  # @param attributes [Hash] nested hash of group and condition attributes
  def groups_attributes=(attributes)
    new_groups = attributes.each_value.map do |group_attributes|
      group_class = search_group_class
      conditions = build_group_conditions(group_class, group_attributes)
      group_class.new(conditions:)
    end

    assign_attributes(groups: new_groups)
  end

  private

  def search_group_class
    self.class.name.deconstantize.constantize::SearchGroup
  end

  def search_condition_class(group_class)
    return group_class.condition_class if group_class.respond_to?(:condition_class)

    self.class.name.deconstantize.constantize::SearchCondition
  end

  def build_group_conditions(group_class, group_attributes)
    condition_class = search_condition_class(group_class)

    group_attributes.values.flat_map do |conditions_attributes|
      conditions_attributes.values.map { |condition_params| condition_class.new(condition_params) }
    end
  end
end
