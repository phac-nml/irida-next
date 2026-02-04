# frozen_string_literal: true

module AdvancedSearch
  # Shared logic for building advanced search conditions with Arel.
  module Operators
    extend ActiveSupport::Concern

    # Metadata fields that should use exact matching instead of pattern/case-insensitive matching.
    # These fields have enumerated values (e.g., from dropdowns) and require precise comparisons.
    #
    # NOTE: This is a behaviour change from previous versions where all metadata fields used
    # case-insensitive pattern matching. Enum fields now require exact value matches since
    # users select from predefined options rather than entering free-form text.
    ENUM_METADATA_FIELDS = %w[metadata.pipeline_id metadata.workflow_version].freeze

    include AdvancedSearch::Operators::EqualityOperators
    include AdvancedSearch::Operators::SetOperators
    include AdvancedSearch::Operators::ComparisonOperators
    include AdvancedSearch::Operators::PatternOperators

    private

    # Checks if a field is an enum metadata field requiring exact matching.
    #
    # @param field_name [String] the field name to check
    # @return [Boolean] true if the field is an enum metadata field
    def enum_metadata_field?(field_name)
      ENUM_METADATA_FIELDS.include?(field_name)
    end

    def build_arel_node(condition, model_class)
      metadata_field = condition.field.starts_with?('metadata.')

      if metadata_field
        metadata_key = condition.field.delete_prefix('metadata.')
        Arel::Nodes::InfixOperation.new('->>', model_class.arel_table[:metadata], Arel::Nodes::Quoted.new(metadata_key))
      else
        model_class.arel_table[condition.field]
      end
    end
  end
end
