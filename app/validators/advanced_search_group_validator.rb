# frozen_string_literal: true

# Validator for advanced search group validator
class AdvancedSearchGroupValidator < ActiveModel::Validator
  def validate(record)
    groups_valid = true
    record.groups.each_with_index do |group, group_index|
      unique_fields = group.conditions.map(&:field).uniq
      unique_fields.each do |unique_field|
        validate_unique_field(record, group, group_index, unique_field)
      end
      groups_valid = false if record.groups[group_index].errors.any?
    end
    return if groups_valid

    record.errors.add :base, 'There are group errors.'
  end

  private

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

    record.groups[group_index].errors.add :base, "'#{unique_field}' can use 'contains' only once."
  end

  def validate_equals(record, group_index, unique_field, unique_field_conditions)
    return if unique_field_conditions.all? { |condition| condition.operator == '=' }

    record.groups[group_index].errors.add :base, "'#{unique_field}' cannot use '=' with other operators."
  end

  def validate_not_equals(record, group_index, unique_field, unique_field_conditions)
    return if unique_field_conditions.all? { |condition| condition.operator == '!=' }

    record.groups[group_index].errors.add :base, "'#{unique_field}' cannot use '!=' with other operators."
  end

  def validate_less_than_equals(record, group_index, unique_field, unique_field_conditions)
    unless unique_field_conditions.count == 1 ||
           (unique_field_conditions.count == 2 && unique_field_conditions[1].operator == '>=')
      record.groups[group_index].errors.add :base, "'#{unique_field}' can use '<=' and '>=' only once."
    end
  end

  def validate_greater_than_equals(record, group_index, unique_field, unique_field_conditions)
    unless unique_field_conditions.count == 1 ||
           (unique_field_conditions.count == 2 && unique_field_conditions[1].operator == '<=')
      record.groups[group_index].errors.add :base, "'#{unique_field}' can use '<=' and '>=' only once."
    end
  end
end
