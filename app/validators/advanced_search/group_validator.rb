# frozen_string_literal: true

module AdvancedSearch
  # Shared validator for "advanced search" group/condition forms.
  #
  # Subclasses must implement:
  # - allowed_fields
  # - date_fields
  class GroupValidator < ActiveModel::Validator # rubocop:disable Metrics/ClassLength
    METADATA_FIELD_PATTERN = /^metadata\..+$/
    DATE_OPERATOR_DISALLOWED = %w[contains not_contains in not_in].freeze
    ALL_BETWEEN_OPERATORS = %w[>= <= date_greater_than_equals date_less_than_equals numeric_greater_than_equals
                               numeric_less_than_equals].freeze
    STANDARD_BETWEEN_OPERATORS = %w[>= <=].freeze
    DATE_BETWEEN_OPERATORS = %w[date_greater_than_equals date_less_than_equals].freeze
    NUMERIC_BETWEEN_OPERATORS = %w[numeric_greater_than_equals numeric_less_than_equals].freeze
    EXISTS_OPERATORS = %w[exists not_exists].freeze
    GROUP_CONDITION_ERROR_ATTRIBUTE_FORMAT =
      'groups_attributes[%<group_index>d].conditions_attributes[%<condition_index>d].%<attribute>s'
    METADATA_DATE_OPERATORS = %w[date_equals date_greater_than_equals date_less_than_equals date_not_equals].freeze
    METADATA_NUMERIC_OPERATORS = %w[numeric_equals numeric_greater_than_equals numeric_less_than_equals
                                    numeric_not_equals].freeze
    def validate(record) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      return if empty_search?(record)

      if structurally_empty_search?(record)
        record.errors.add :base, :invalid
        return
      end

      record.groups.each do |group|
        validate_fields(group)
      end

      return unless record.groups.any? { |group| group.errors.any? }

      record.groups.each_with_index do |group, group_index|
        next unless group.errors.any?

        group.conditions.each_with_index do |condition, condition_index|
          next unless condition.errors.any?

          condition.errors.each do |error|
            next if error.attribute.eql? :base

            record.errors.add format(
              GROUP_CONDITION_ERROR_ATTRIBUTE_FORMAT,
              group_index: group_index,
              condition_index: condition_index,
              attribute: error.attribute
            ).to_sym,
                              error.message
          end
        end
      end

      record.errors.add :base, :invalid
    end

    private

    def allowed_fields
      raise NotImplementedError
    end

    def date_fields
      raise NotImplementedError
    end

    def empty_search?(record)
      return true if record.groups.empty?

      false
    end

    def structurally_empty_search?(record)
      groups = record.groups
      return false unless groups.respond_to?(:all?)
      return true if groups.empty?

      groups.all? { |group| Array(group.conditions).empty? }
    end

    def validate_fields(group)
      group.conditions.each_with_index do |condition, condition_index|
        validate_blank_field(condition)
        validate_field(condition) if condition.field.present?
        validate_date_and_numeric_field(condition)

        validate_unique_condition(group, condition, condition_index)

        next unless condition.errors.any?
      end

      return unless group.conditions.any? { |condition| condition.errors.any? }

      group.errors.add :base, :invalid
    end

    def validate_blank_field(condition) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
      if condition.field.blank?
        condition.errors.add :field, :blank
        return
      end

      condition.errors.add :operator, :blank if condition.operator.blank?

      return unless condition.operator.present? && (
        (condition.value.is_a?(Array) && condition.value.compact_blank.blank?) ||
                    (EXISTS_OPERATORS.exclude?(condition.operator) && condition.value.blank?)
      )

      condition.errors.add :value, :blank
    end

    def validate_field(condition)
      return if allowed_fields.include?(condition.field) || METADATA_FIELD_PATTERN.match?(condition.field)

      condition.errors.add :field, :not_a_metadata
    end

    def validate_date_and_numeric_field(condition)
      if Flipper.enabled?(:advanced_search_metadata_operators)
        validate_metadata_date_and_numeric_fields(condition)
      else
        validate_standard_date_and_numeric_fields(condition)
      end
    end

    def validate_metadata_date_and_numeric_fields(condition)
      return unless METADATA_DATE_OPERATORS.include?(condition.operator) ||
                    METADATA_NUMERIC_OPERATORS.include?(condition.operator)

      if METADATA_DATE_OPERATORS.include?(condition.operator)
        validate_date(condition)
      else
        validate_numeric(condition)
      end
    end

    def validate_standard_date_and_numeric_fields(condition)
      if date_field?(condition.field)
        validate_date_field_condition(condition)
      elsif STANDARD_BETWEEN_OPERATORS.include?(condition.operator)
        validate_numeric(condition)
      end
    end

    def date_field?(field)
      date_fields.include?(field) || field.end_with?('_date')
    end

    def validate_date_field_condition(condition)
      if DATE_OPERATOR_DISALLOWED.include?(condition.operator)
        condition.errors.add :operator, :not_a_date_operator
      elsif EXISTS_OPERATORS.exclude?(condition.operator)
        validate_date(condition)
      end
    end

    def validate_numeric(condition)
      condition.errors.add :value, :not_a_number unless Float(condition.value, exception: false)
    end

    def validate_date(condition)
      DateTime.strptime(condition.value, '%Y-%m-%d')
    rescue StandardError
      condition.errors.add :value, :not_a_date
    end

    def validate_unique_condition(group, condition, condition_index)
      common_field_conditions = group.conditions[0..condition_index].find_all do |group_condition|
        group_condition.field == condition.field
      end

      if ALL_BETWEEN_OPERATORS.include?(condition.operator)
        validate_between(condition, common_field_conditions)
      elsif condition.field.present?
        validate_uniqueness(condition, common_field_conditions)
      end
    end

    def validate_uniqueness(unique_field_condition, common_field_conditions)
      return if common_field_conditions.one?

      unique_field_condition.errors.add :field, :taken
    end

    def validate_between(unique_field_condition, common_field_conditions)
      return if common_field_conditions.one?

      if common_field_conditions.count == 2
        operators =  common_field_conditions.collect(&:operator).sort

        if operators == STANDARD_BETWEEN_OPERATORS.sort ||
           operators == DATE_BETWEEN_OPERATORS.sort ||
           operators == NUMERIC_BETWEEN_OPERATORS.sort
          return
        end
      end
      unique_field_condition.errors.add :field, :taken
    end
  end
end
