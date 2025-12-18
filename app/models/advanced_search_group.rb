# frozen_string_literal: true

# Shared advanced search functionality for SearchGroup form objects.
#
# A SearchGroup contains multiple conditions combined with AND logic.
# Query objects typically combine multiple groups with OR logic.
class AdvancedSearchGroup
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :conditions, default: -> { [] }

  class << self
    # @return [Class] the SearchCondition class used to build conditions
    def condition_class
      @condition_class || raise(NotImplementedError, "#{name} must set .condition_class")
    end

    # @param klass [Class] the SearchCondition class used to build conditions
    attr_writer :condition_class
  end

  # Parses nested attributes from form submissions.
  # Converts hash of condition parameters into SearchCondition objects.
  # @param attributes [Hash] nested hash of condition attributes
  def conditions_attributes=(attributes)
    new_conditions = Array(conditions).dup

    attributes.each_value do |condition_params|
      new_conditions << self.class.condition_class.new(condition_params)
    end

    self.conditions = new_conditions
  end

  # Checks if all conditions in the group are empty.
  # @return [Boolean] true if all conditions are empty
  def empty?
    conditions.all?(&:empty?)
  end
end
