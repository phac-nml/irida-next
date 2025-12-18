# frozen_string_literal: true

# Shared logic for building advanced search conditions with Arel
module AdvancedSearchConditions
  extend ActiveSupport::Concern

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

  def condition_equals(scope, node, value, metadata_field:, field_name:)
    if metadata_field || field_name == 'name'
      scope.where(node.matches(value))
    else
      scope.where(node.eq(value))
    end
  end

  def condition_in(scope, node, value, metadata_field:, field_name:)
    if metadata_field
      scope.where(Arel::Nodes::NamedFunction.new('LOWER', [node]).in(downcase_values(value)))
    elsif field_name == 'name'
      scope.where(node.lower.in(downcase_values(value)))
    else
      scope.where(node.in(value.compact))
    end
  end

  def condition_not_equals(scope, node, value, metadata_field:, field_name:)
    if metadata_field || field_name == 'name'
      scope.where(node.eq(nil).or(node.does_not_match(value)))
    else
      scope.where(node.not_eq(value))
    end
  end

  def condition_not_in(scope, node, value, metadata_field:, field_name:)
    if metadata_field
      condition_not_in_metadata(scope, node, value)
    elsif field_name == 'name'
      scope.where(node.lower.not_in(downcase_values(value)))
    else
      scope.where(node.not_in(value.compact))
    end
  end

  def condition_not_in_metadata(scope, node, value)
    lower_function = Arel::Nodes::NamedFunction.new('LOWER', [node])
    scope.where(node.eq(nil).or(lower_function.not_in(downcase_values(value))))
  end

  def condition_less_than_or_equal(scope, node, value, metadata_field:, metadata_key:)
    return scope.where(node.lteq(value)) unless metadata_field

    if metadata_key.end_with?('_date')
      condition_date_comparison(scope, node, value, :lteq)
    else
      condition_numeric_comparison(scope, node, value, :lteq)
    end
  end

  def condition_greater_than_or_equal(scope, node, value, metadata_field:, metadata_key:)
    return scope.where(node.gteq(value)) unless metadata_field

    if metadata_key.end_with?('_date')
      condition_date_comparison(scope, node, value, :gteq)
    else
      condition_numeric_comparison(scope, node, value, :gteq)
    end
  end

  def condition_contains(scope, node, value)
    scope.where(node.matches("%#{escape_like_wildcards(value)}%"))
  end

  def condition_not_contains(scope, node, value)
    scope.where(node.eq(nil).or(node.does_not_match("%#{escape_like_wildcards(value)}%")))
  end

  # Escapes SQL LIKE wildcard characters (%, _) to treat them as literal characters
  # @param value [String] the value to escape
  # @return [String] the escaped value
  def escape_like_wildcards(value)
    value.gsub(/[%_\\]/) { |char| "\\#{char}" }
  end

  def condition_exists(scope, node)
    scope.where(node.not_eq(nil))
  end

  def condition_not_exists(scope, node)
    scope.where(node.eq(nil))
  end

  def condition_date_comparison(scope, node, value, comparison_method)
    scope
      .where(node.matches_regexp('^\\d{4}(-\\d{2}){0,2}$'))
      .where(
        Arel::Nodes::NamedFunction.new(
          'TO_DATE', [node, Arel::Nodes::SqlLiteral.new("'YYYY-MM-DD'")]
        ).public_send(comparison_method, value)
      )
  end

  def condition_numeric_comparison(scope, node, value, comparison_method)
    scope
      .where(node.matches_regexp('^-?\\d+(\\.\\d+)?$'))
      .where(
        Arel::Nodes::NamedFunction.new(
          'CAST', [node.as(Arel::Nodes::SqlLiteral.new('DOUBLE PRECISION'))]
        ).public_send(comparison_method, value)
      )
  end

  def downcase_values(value)
    value.compact.map { |v| v.to_s.downcase }
  end
end
