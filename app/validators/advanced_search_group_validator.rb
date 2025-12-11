# frozen_string_literal: true

# Validator for advanced search group validator
class AdvancedSearchGroupValidator < ActiveModel::Validator
  def validate(record)
    return if empty_search?(record)

    record.groups.each do |group|
      validate_fields(group)
    end

    return unless record.groups.any? { |group| group.errors.any? }

    record.errors.add :groups, :invalid
  end

  private

  def empty_search?(record)
    return true if record.groups.length == 1 && record.groups[0].empty?

    false
  end

  def validate_fields(group)
    group.conditions.each_with_index do |condition, condition_index|
      validate_key(condition)
      validate_blank_field(condition)
      validate_date_and_numeric_field(condition)

      validate_unique_condition(group, condition, condition_index)
    end

    return unless group.conditions.any? { |condition| condition.errors.any? }

    group.errors.add :conditions, :invalid
  end

  def validate_key(condition)
    return if %w[name puid created_at updated_at
                 attachments_updated_at].include?(condition.field) || /^metadata\..+$/ =~ condition.field

    condition.errors.add :field, :not_a_metadata
  end

  def validate_blank_field(condition)
    condition.errors.add :field, :blank if condition.field.blank?

    condition.errors.add :operator, :blank if condition.operator.blank?

    return unless (condition.value.is_a?(Array) && condition.value.compact_blank.blank?) ||
                  (%w[exists not_exists].exclude?(condition.operator) && condition.value.blank?)

    condition.errors.add :value, :blank
  end

  def validate_date_and_numeric_field(condition)
    if %w[created_at updated_at attachments_updated_at].include?(condition.field) || condition.field.end_with?('_date')
      validate_date_field_condition(condition)
    elsif %w[>= <=].include?(condition.operator)
      condition.errors.add :value, :not_a_number unless Float(condition.value, exception: false)
    end
  end

  def validate_date_field_condition(condition)
    if %w[contains in not_in].include?(condition.operator)
      condition.errors.add :operator, :not_a_date_operator
    elsif %w[exists not_exists].exclude?(condition.operator)
      begin
        DateTime.strptime(condition.value, '%Y-%m-%d')
      rescue StandardError
        condition.errors.add :value, :not_a_date
      end
    end
  end

  def validate_unique_condition(group, condition, condition_index)
    common_field_conditions = group.conditions[0..condition_index].find_all do |group_condition|
      group_condition.field == condition.field
    end

    case condition.operator
    when '>=', '<='
      validate_between(condition, common_field_conditions)
    else
      validate_uniqueness(condition, common_field_conditions)
    end

    return unless condition.errors.any?

    group.errors.add :conditions, :invalid
  end

  def validate_uniqueness(unique_field_condition, common_field_conditions)
    return if common_field_conditions.one?

    unique_field_condition.errors.add :operator, :taken
  end

  def validate_between(unique_field_condition, common_field_conditions)
    unless common_field_conditions.one? || (common_field_conditions.count == 2 &&
      common_field_conditions.collect(&:operator).sort == %w[>= <=].sort)
      unique_field_condition.errors.add :operator, :taken
    end
  end
end
