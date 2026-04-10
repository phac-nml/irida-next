# frozen_string_literal: true

module AdvancedSearch
  module V2
    # Defines allowed fields and operator constraints for V2 advanced search.
    # Standalone class — does NOT inherit from AdvancedSearch::Fields.
    class FieldConfiguration
      CORE_FIELDS = {
        'name' => [:string],
        'puid' => [:string],
        'created_at' => [:date],
        'updated_at' => [:date],
        'attachments_updated_at' => [:date]
      }.freeze

      STRING_OPERATORS = %w[= != contains not_contains in not_in exists not_exists].freeze
      DATE_OPERATORS = %w[= != <= >= exists not_exists].freeze
      METADATA_OPERATORS = %w[= != contains not_contains in not_in exists not_exists].freeze
      LEGACY_OPERATOR_ALIASES = {
        'equals' => '=',
        'not_equals' => '!=',
        'does_not_contain' => 'not_contains',
        'greater_than' => '>=',
        'less_than' => '<='
      }.freeze

      class << self
        def allowed_fields
          CORE_FIELDS.keys
        end

        def valid_field?(field)
          return false unless field.is_a?(String)
          return false if field.blank?

          CORE_FIELDS.key?(field) || field.start_with?('metadata.')
        end

        def operators_for(field)
          return [] unless field.is_a?(String)

          if field.start_with?('metadata.')
            METADATA_OPERATORS
          elsif CORE_FIELDS[field]&.include?(:date)
            DATE_OPERATORS
          else
            STRING_OPERATORS
          end
        end

        def normalize_operator(operator)
          LEGACY_OPERATOR_ALIASES.fetch(operator, operator)
        end

        def valid_operator?(field, operator)
          operators_for(field).include?(normalize_operator(operator))
        end
      end
    end
  end
end
