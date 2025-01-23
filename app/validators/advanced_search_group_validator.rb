# frozen_string_literal: true

# Validator for advanced search group validator
class AdvancedSearchGroupValidator < ActiveModel::Validator
  def validate(record)
    return if empty_search?(record)

    record.groups.each do |group|
      validate_fields(group)
      validate_unique_fields(group)
    end

    return unless record.groups.any? { |group| group.errors.any? }

    record.errors.add :base, I18n.t('validators.advanced_search_group_validator.group_error')
  end

  private

  def empty_search?(record) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    if record.groups.length == 1 && record.groups[0].conditions.length == 1 &&
       record.groups[0].conditions[0].field.blank? && record.groups[0].conditions[0].operator.blank? &&
       ((record.groups[0].conditions[0].value.is_a?(Array) &&
       record.groups[0].conditions[0].value.compact_blank.blank?) || record.groups[0].conditions[0].value.blank?)
      return true
    end

    false
  end

  def validate_fields(group)
    group.conditions.each do |condition|
      validate_blank_field(condition)
      validate_date_and_numeric_field(condition)
    end

    return unless group.conditions.any? { |condition| condition.errors.any? }

    group.errors.add :base, I18n.t('validators.advanced_search_group_validator.condition_error')
  end

  def validate_blank_field(condition) # rubocop:disable Metrics/AbcSize
    if condition.field.blank?
      condition.errors.add :field,
                           I18n.t('validators.advanced_search_group_validator.blank_error')
    end

    if condition.operator.blank?
      condition.errors.add :operator,
                           I18n.t('validators.advanced_search_group_validator.blank_error')
    end

    return unless (condition.value.is_a?(Array) && condition.value.compact_blank.blank?) || condition.value.blank?

    condition.errors.add :value, I18n.t('validators.advanced_search_group_validator.blank_error')
  end

  def validate_date_and_numeric_field(condition)
    if %w[created_at updated_at attachments_updated_at].include?(condition.field) || condition.field.end_with?('_date')
      validate_date_field(condition)
    elsif %w[>= <=].include?(condition.operator)
      unless Float(condition.value, exception: false)
        condition.errors.add :operator, I18n.t('validators.advanced_search_group_validator.numeric_operator_error')
      end
    end
  end

  def validate_date_field(condition)
    if %w[contains in not_not].include?(condition.operator)
      condition.errors.add :operator, I18n.t('validators.advanced_search_group_validator.date_operator_error')
    else
      begin
        DateTime.strptime(condition.value, '%Y-%m-%d')
      rescue StandardError
        condition.errors.add :value, I18n.t('validators.advanced_search_group_validator.date_format_error')
      end
    end
  end

  def validate_unique_fields(group)
    unique_fields = group.conditions.map(&:field).uniq
    unique_fields.each do |unique_field|
      validate_unique_field(group, unique_field)
    end
  end

  def validate_unique_field(group, unique_field)
    unique_field_conditions = group.conditions.find_all { |condition| condition.field == unique_field }

    unique_field_conditions.each do |unique_field_condition|
      case unique_field_condition.operator
      when '>=', '<='
        validate_between(unique_field_condition, unique_field_conditions)
      else
        validate_uniqueness(unique_field_condition, unique_field_conditions)
      end
    end

    return unless unique_field_conditions.any? { |condition| condition.errors.any? }

    group.errors.add :base, I18n.t('validators.advanced_search_group_validator.condition_error')
  end

  def validate_uniqueness(unique_field_condition, unique_field_conditions)
    return if unique_field_conditions.count == 1

    unique_field_condition.errors.add :field, I18n.t('validators.advanced_search_group_validator.uniqueness_error')
  end

  def validate_between(unique_field_condition, unique_field_conditions)
    unless unique_field_conditions.count == 1 || (unique_field_conditions.count == 2 &&
      unique_field_conditions.collect(&:operator).sort == %w[>= <=].sort)
      unique_field_condition.errors.add :field, I18n.t('validators.advanced_search_group_validator.between_error')
    end
  end
end
