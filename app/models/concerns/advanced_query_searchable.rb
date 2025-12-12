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
module AdvancedQuerySearchable # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern
  include AdvancedQuerySearchableJsonb

  private

  # Build a LOWER() Arel node for case-insensitive comparisons
  def lower(node)
    Arel::Nodes::NamedFunction.new('LOWER', [node])
  end

  # Transform array of values to quoted, downcased Arel nodes for case-insensitive comparisons
  def quoted_downcase_values(values)
    Array(values).map { |v| Arel::Nodes.build_quoted(v.to_s.downcase) }
  end

  # Transform array of values to quoted, uppercased Arel nodes
  def quoted_upcase_values(values)
    Array(values).map { |v| Arel::Nodes.build_quoted(v.to_s.upcase) }
  end

  # Sanitize SQL wildcards in LIKE/ILIKE patterns
  def sanitize_sql_wildcards(value)
    ActiveRecord::Base.sanitize_sql_like(value.to_s)
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
      quoted = Arel::Nodes.build_quoted(condition.value.to_s.downcase)
      scope.where(lower(node).eq(quoted))
    elsif uppercase_field?(field)
      quoted = Arel::Nodes.build_quoted(condition.value.to_s.upcase)
      scope.where(node.eq(quoted))
    else
      # For regular fields, let ActiveRecord handle type conversion (e.g., enums)
      scope.where(node.eq(condition.value))
    end
  end

  # Handle IN operator for multiple values
  def handle_in(scope, condition, node, field)
    if text_match_field?(field)
      # Case-insensitive IN using LOWER(column) IN LOWER(values)
      scope.where(lower(node).in(quoted_downcase_values(condition.value)))
    elsif uppercase_field?(field)
      scope.where(node.in(quoted_upcase_values(condition.value)))
    else
      # For regular fields, let ActiveRecord handle type conversion
      scope.where(node.in(condition.value))
    end
  end

  # Handle inequality operator (!=)
  # Note: For text_match_field?, includes NULL values in results since NULL != value is NULL in SQL
  # For uppercase_field? and regular fields, NULLs are excluded (standard SQL behavior)
  def handle_not_equals(scope, condition, node, field) # rubocop:disable Metrics/AbcSize
    if text_match_field?(field)
      # Include NULLs and values whose LOWER(column) != LOWER(value)
      quoted = Arel::Nodes.build_quoted(condition.value.to_s.downcase)
      scope.where(node.eq(nil).or(lower(node).not_eq(quoted)))
    elsif uppercase_field?(field)
      quoted = Arel::Nodes.build_quoted(condition.value.to_s.upcase)
      scope.where(node.not_eq(quoted))
    else
      quoted = Arel::Nodes.build_quoted(condition.value)
      scope.where(node.not_eq(quoted))
    end
  end

  # Handle NOT IN operator
  # Note: For text_match_field?, includes NULL values in results since NULL NOT IN (values) is NULL in SQL
  def handle_not_in(scope, condition, node, field)
    if text_match_field?(field)
      # Include NULLs and values whose LOWER(column) NOT IN LOWER(values)
      scope.where(node.eq(nil).or(lower(node).not_in(quoted_downcase_values(condition.value))))
    elsif uppercase_field?(field)
      scope.where(node.not_in(quoted_upcase_values(condition.value)))
    else
      # For regular fields, let ActiveRecord handle type conversion
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
      # For regular fields, let ActiveRecord handle type conversion
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
      # For regular fields, let ActiveRecord handle type conversion
      scope.where(node.gteq(condition.value))
    end
  end

  # Handle CONTAINS operator (case-insensitive pattern matching)
  # Sanitizes SQL wildcards (% and _) to treat them as literal characters
  def handle_contains(scope, condition, node, field)
    return scope if condition.value.blank?

    # Sanitize SQL wildcards so they're treated as literal characters
    sanitized_value = sanitize_sql_wildcards(condition.value).downcase

    # UUID fields need to be cast to text before using ILIKE
    if uuid_field?(field)
      text_node = Arel::Nodes::NamedFunction.new('CAST', [node.as(Arel::Nodes::SqlLiteral.new('TEXT'))])
      scope.where(lower(text_node).matches("%#{sanitized_value}%"))
    else
      scope.where(lower(node).matches("%#{sanitized_value}%"))
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
