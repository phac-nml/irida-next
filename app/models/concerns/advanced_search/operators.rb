# frozen_string_literal: true

module AdvancedSearch
  # Shared logic for building advanced search conditions with Arel.
  module Operators
    extend ActiveSupport::Concern

    # Metadata fields that should use exact matching instead of pattern/case-insensitive matching.
    # These fields have enumerated values (e.g., from dropdowns) and require precise comparisons.
    ENUM_METADATA_FIELDS = %w[metadata.pipeline_id metadata.workflow_version].freeze

    include AdvancedSearch::Operators::EqualityOperators
    include AdvancedSearch::Operators::SetOperators
    include AdvancedSearch::Operators::ComparisonOperators
    include AdvancedSearch::Operators::PatternOperators

    private

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
