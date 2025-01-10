# frozen_string_literal: true

# Validator for advanced search group validator
class AdvancedSearchGroupValidator < ActiveModel::Validator
  def validate(record)
    groups_valid = true
    record.groups.each_with_index do |group, group_index|
      validate_blank_fields(record, group, group_index)
      validate_unique_fields(record, group, group_index)
      groups_valid = false if record.groups[group_index].errors.any?
    end
    return if groups_valid

    record.errors.add :base, I18n.t('validators.advanced_search_group_validator.base_error')
  end

  private

  def validate_blank_fields(record, group, group_index)
    if group.conditions.count == 1
      validate_blank_fields_for_condition(record, group, group_index)
    elsif group.conditions.any? do |condition|
      condition.field.blank? || condition.operator.blank? || condition.value.blank?
    end
      record.groups[group_index].errors.add :base, I18n.t('validators.advanced_search_group_validator.blank_error')
    end
  end

  def validate_blank_fields_for_condition(record, group, group_index)
    condition = group.conditions.first
    unless (condition.field.blank? && condition.operator.blank? && condition.value.blank?) ||
           (condition.field.present? && condition.operator.present? && condition.value.present?)
      record.groups[group_index].errors.add :base, I18n.t('validators.advanced_search_group_validator.blank_error')
    end
  end

  def validate_unique_fields(record, group, group_index)
    unique_fields = group.conditions.map(&:field).uniq
    unique_fields.each do |unique_field|
      validate_unique_field(record, group, group_index, unique_field)
    end
  end

  def validate_unique_field(record, group, group_index, unique_field)
    unique_field_conditions = group.conditions.find_all { |condition| condition.field == unique_field }
    unique_field_condition = unique_field_conditions.first

    case unique_field_condition.operator
    when 'contains'
      validate_contains(record, group_index, unique_field, unique_field_conditions)
    when '='
      validate_equals(record, group_index, unique_field, unique_field_conditions)
    when '!='
      validate_not_equals(record, group_index, unique_field, unique_field_conditions)
    when '<='
      validate_less_than_equals(record, group_index, unique_field, unique_field_conditions)
    when '>='
      validate_greater_than_equals(record, group_index, unique_field, unique_field_conditions)
    end
  end

  def validate_contains(record, group_index, unique_field, unique_field_conditions)
    return if unique_field_conditions.count == 1

    record.groups[group_index].errors.add :base,
                                          I18n.t('validators.advanced_search_group_validator.contains_error',
                                                 unique_field:)
  end

  def validate_equals(record, group_index, unique_field, unique_field_conditions)
    return if unique_field_conditions.all? { |condition| condition.operator == '=' }

    record.groups[group_index].errors.add :base, I18n.t('validators.advanced_search_group_validator.equals_error',
                                                        unique_field:)
  end

  def validate_not_equals(record, group_index, unique_field, unique_field_conditions)
    return if unique_field_conditions.all? { |condition| condition.operator == '!=' }

    record.groups[group_index].errors.add :base, I18n.t('validators.advanced_search_group_validator.not_equals_error',
                                                        unique_field:)
  end

  def validate_less_than_equals(record, group_index, unique_field, unique_field_conditions)
    unless unique_field_conditions.count == 1 ||
           (unique_field_conditions.count == 2 && unique_field_conditions[1].operator == '>=')
      record.groups[group_index].errors.add :base,
                                            I18n.t('validators.advanced_search_group_validator.between_error',
                                                   unique_field:)
    end
  end

  def validate_greater_than_equals(record, group_index, unique_field, unique_field_conditions)
    unless unique_field_conditions.count == 1 ||
           (unique_field_conditions.count == 2 && unique_field_conditions[1].operator == '<=')
      record.groups[group_index].errors.add :base,
                                            I18n.t('validators.advanced_search_group_validator.between_error',
                                                   unique_field:)
    end
  end
end
