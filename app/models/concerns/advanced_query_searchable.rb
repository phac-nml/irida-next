# frozen_string_literal: true

# Shared concern for advanced query search functionality across different models.
# This concern provides common operator handling and query building logic that can be
# customized by including classes through configuration and hook methods.

# Mapping of operator symbols to handler method names (kept separate to reduce
# Metrics/ModuleLength noise in the main concern while remaining easy to reference).
module AdvancedQuerySearchableOperators
  HANDLERS = {
    '=' => :handle_equals,
    'in' => :handle_in,
    '!=' => :handle_not_equals,
    'not_in' => :handle_not_in,
    '<=' => :handle_less_than_equal,
    '>=' => :handle_greater_than_equal,
    'contains' => :handle_contains,
    'exists' => :handle_exists,
    'not_exists' => :handle_not_exists
  }.freeze
end

# JSONB helpers extracted to keep concern concise and under RuboCop length limits.
module AdvancedQuerySearchableJsonb
  private

  # Helper method for JSONB numeric comparison
  def handle_jsonb_numeric_comparison(scope, node, value, operator)
    scope
      .where(node.matches_regexp('^-?\d+(\.\d+)?$'))
      .where(
        Arel::Nodes::NamedFunction.new(
          'CAST', [node.as(Arel::Nodes::SqlLiteral.new('DOUBLE PRECISION'))]
        ).send(operator, value)
      )
  end

  # Helper method for JSONB date comparison
  def handle_jsonb_date_comparison(scope, node, value, operator)
    scope
      .where(node.matches_regexp('^\d{4}(-\d{2}){0,2}$'))
      .where(
        Arel::Nodes::NamedFunction.new(
          'TO_DATE', [node, Arel::Nodes::SqlLiteral.new("'YYYY-MM-DD'")]
        ).send(operator, value)
      )
  end
end

# Concern adding reusable operator-based advanced filtering to AR models.
# Includes predicate hooks (e.g., text_match_field?) for customizing behavior
# in including classes and delegates JSONB/date parsing to helpers above.
module AdvancedQuerySearchable
  extend ActiveSupport::Concern
  include AdvancedQuerySearchableJsonb

  private

  # Build a LOWER() Arel node for case-insensitive comparisons
  def lower(node)
    Arel::Nodes::NamedFunction.new('LOWER', [node])
  end

  # Apply the appropriate operator handler for the given condition
  def apply_operator(scope, condition, node, field)
    handler_method = AdvancedQuerySearchableOperators::HANDLERS[condition.operator]
    return scope unless handler_method

    send(handler_method, scope, condition, node, field)
  end

  # Handle equality operator (=)
  # Subclasses should override text_match_fields and uppercase_fields for custom behavior
  def handle_equals(scope, condition, node, field)
    if text_match_field?(field)
      # Case-insensitive exact match using LOWER(column) = LOWER(value)
      scope.where(lower(node).eq(condition.value.to_s.downcase))
    elsif uppercase_field?(field)
      scope.where(node.eq(condition.value.upcase))
    else
      scope.where(node.eq(condition.value))
    end
  end

  # Handle IN operator for multiple values
  def handle_in(scope, condition, node, field)
    if text_match_field?(field)
      # Case-insensitive IN using LOWER(column) IN LOWER(values)
      values = Array(condition.value).map { |v| v.to_s.downcase }
      scope.where(lower(node).in(values))
    elsif uppercase_field?(field)
      scope.where(node.in(condition.value.map(&:upcase)))
    else
      scope.where(node.in(condition.value))
    end
  end

  # Handle inequality operator (!=)
  def handle_not_equals(scope, condition, node, field)
    if text_match_field?(field)
      # Include NULLs and values whose LOWER(column) != LOWER(value)
      scope.where(node.eq(nil).or(lower(node).not_eq(condition.value.to_s.downcase)))
    elsif uppercase_field?(field)
      scope.where(node.not_eq(condition.value.upcase))
    else
      scope.where(node.not_eq(condition.value))
    end
  end

  # Handle NOT IN operator
  def handle_not_in(scope, condition, node, field)
    if text_match_field?(field)
      # Include NULLs and values whose LOWER(column) NOT IN LOWER(values)
      values = Array(condition.value).map { |v| v.to_s.downcase }
      scope.where(node.eq(nil).or(lower(node).not_in(values)))
    elsif uppercase_field?(field)
      scope.where(node.not_in(condition.value.map(&:upcase)))
    else
      scope.where(node.not_in(condition.value))
    end
  end

  # Handle less than or equal operator (<=)
  # Subclasses can override for custom numeric/date handling
  def handle_less_than_equal(scope, condition, node, field)
    if jsonb_field?(field) && date_field?(field)
      handle_jsonb_date_comparison(scope, node, condition.value, :lteq)
    elsif jsonb_field?(field)
      handle_jsonb_numeric_comparison(scope, node, condition.value, :lteq)
    else
      scope.where(node.lteq(condition.value))
    end
  end

  # Handle greater than or equal operator (>=)
  def handle_greater_than_equal(scope, condition, node, field)
    if jsonb_field?(field) && date_field?(field)
      handle_jsonb_date_comparison(scope, node, condition.value, :gteq)
    elsif jsonb_field?(field)
      handle_jsonb_numeric_comparison(scope, node, condition.value, :gteq)
    else
      scope.where(node.gteq(condition.value))
    end
  end

  # Handle CONTAINS operator (case-insensitive pattern matching)
  def handle_contains(scope, condition, node, field)
    return scope if condition.value.blank?

    # UUID fields need to be cast to text before using ILIKE
    if uuid_field?(field)
      text_node = Arel::Nodes::NamedFunction.new('CAST', [node.as(Arel::Nodes::SqlLiteral.new('TEXT'))])
      scope.where(lower(text_node).matches("%#{condition.value.to_s.downcase}%"))
    else
      scope.where(lower(node).matches("%#{condition.value.to_s.downcase}%"))
    end
  end

  # Handle EXISTS operator (field is not null)
  def handle_exists(scope, _condition, node, _field)
    scope.where(node.not_eq(nil))
  end

  # Handle NOT EXISTS operator (field is null)
  def handle_not_exists(scope, _condition, node, _field)
    scope.where(node.eq(nil))
  end

  # Helper method for JSONB numeric comparison
  # (moved to AdvancedQuerySearchableJsonb)

  # Hook methods to be overridden by including classes

  # Returns true if the field should use text matching (ILIKE) instead of exact matching
  def text_match_field?(_field)
    false
  end

  # Returns true if the field values should be uppercased before comparison
  def uppercase_field?(_field)
    false
  end

  # Returns true if the field is a JSONB field
  def jsonb_field?(_field)
    false
  end

  # Returns true if the field is a date field (for special date handling)
  def date_field?(_field)
    false
  end

  # Returns true if the field is a UUID field (needs text casting for ILIKE)
  def uuid_field?(_field)
    false
  end
end
