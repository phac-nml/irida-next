# frozen_string_literal: true

module AdvancedSearch
  # Shared logic for building advanced search conditions with Arel.
  module Operators
    extend ActiveSupport::Concern

    include AdvancedSearch::Operators::EqualityOperators
    include AdvancedSearch::Operators::SetOperators
    include AdvancedSearch::Operators::ComparisonOperators
    include AdvancedSearch::Operators::PatternOperators
    include AdvancedSearch::Operators::ExistenceOperators
    include AdvancedSearch::MetadataComparison

    included do
      class_attribute :enum_metadata_fields, instance_accessor: false, default: [].freeze
    end

    private

    # Checks if a field is an enum metadata field requiring exact matching.
    #
    # @param field_name [String] the field name to check
    # @return [Boolean] true if the field is an enum metadata field
    def enum_metadata_field?(field_name)
      self.class.enum_metadata_fields.include?(field_name)
    end

    def build_arel_node(field_name, model_class)
      field_name.to_s!
      if metadata_field?(field_name)
        metadata_key = metadata_key(field_name)
        Arel::Nodes::InfixOperation.new('->>', model_class.arel_table[:metadata], Arel::Nodes::Quoted.new(metadata_key))
      else
        model_class.arel_table[field_name]
      end
    end

    def metadata_field?(field_name)
      field_name.starts_with?('metadata.')
    end

    def metadata_key(field_name)
      return nil unless metadata_field?(field_name)

      field_name.delete_prefix('metadata.')
    end
  end
end
