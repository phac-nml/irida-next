# frozen_string_literal: true

module AdvancedSearch
  # Shared logic for building advanced search conditions with Arel.
  module Operators
    extend ActiveSupport::Concern

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
