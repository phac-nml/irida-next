# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  class OperatorCatalogTest < ActiveSupport::TestCase
    # The operator string keys are persisted in saved searches and are the
    # GraphQL/form wire values. They must never change.
    EXPECTED_KEYS = %w[
      = != <= >= contains not_contains exists not_exists in not_in starts_with ends_with between
      text_equals text_not_equals text_contains text_not_contains text_in text_not_in
      text_starts_with text_ends_with text_between
      numeric_equals numeric_not_equals numeric_less_than_equals numeric_greater_than_equals
      numeric_exists numeric_not_exists numeric_between
      date_equals date_not_equals date_less_than_equals date_greater_than_equals
      date_exists date_not_exists date_between
    ].freeze

    test 'declares exactly the known operator keys' do
      assert_equal EXPECTED_KEYS.sort, OperatorCatalog.keys.sort
    end

    test 'find returns the operator for a key and nil for unknown keys' do
      assert_equal '=', OperatorCatalog.find('=').key
      assert_nil OperatorCatalog.find('nope')
    end

    test 'available excludes metadata operators when the flag is disabled' do
      available = OperatorCatalog.available(metadata_operators_enabled: false).map(&:key)

      assert_includes available, '='
      assert_includes available, 'exists'
      assert_not_includes available, 'text_equals'
      assert_not_includes available, 'numeric_between'
      assert_not_includes available, 'date_exists'
    end

    test 'available includes every operator when the flag is enabled' do
      assert_equal OperatorCatalog.keys.sort,
                   OperatorCatalog.available(metadata_operators_enabled: true).map(&:key).sort
    end

    # --- Parity with the legacy AdvancedSearch::GroupValidator constants ---

    test 'exists_operators matches the legacy set' do
      assert_equal %w[exists not_exists date_exists date_not_exists numeric_exists numeric_not_exists].sort,
                   OperatorCatalog.exists_operators.sort
    end

    test 'between_operators matches the legacy set' do
      assert_equal %w[between date_between numeric_between text_between].sort,
                   OperatorCatalog.between_operators.sort
    end

    test 'metadata_date_operators matches the legacy set' do
      assert_equal %w[date_equals date_greater_than_equals date_less_than_equals date_not_equals date_between].sort,
                   OperatorCatalog.metadata_date_operators.sort
    end

    test 'metadata_numeric_operators matches the legacy set' do
      assert_equal %w[numeric_equals numeric_greater_than_equals numeric_less_than_equals
                      numeric_not_equals numeric_between].sort,
                   OperatorCatalog.metadata_numeric_operators.sort
    end

    test 'non_metadata_operators matches the legacy set' do
      assert_equal %w[= != <= >= contains not_contains in not_in between].sort,
                   OperatorCatalog.non_metadata_operators.sort
    end

    test 'non_metadata_numeric_operators matches the legacy set' do
      assert_equal %w[= != <= >= in not_in between].sort,
                   OperatorCatalog.non_metadata_numeric_operators.sort
    end

    test 'date_operator_disallowed matches the legacy set' do
      assert_equal %w[contains not_contains in not_in starts_with ends_with].sort,
                   OperatorCatalog.date_operator_disallowed.sort
    end

    test 'combinable_operators matches the legacy pairs' do
      expected = {
        gleqt: %w[>= <=],
        start_ends_with: %w[ends_with starts_with],
        metadata_date_gleqt: %w[date_greater_than_equals date_less_than_equals],
        metadata_numeric_gleqt: %w[numeric_greater_than_equals numeric_less_than_equals],
        text_starts_ends_with: %w[text_ends_with text_starts_with]
      }
      actual = OperatorCatalog.combinable_operators

      assert_equal expected.keys.sort, actual.keys.sort
      expected.each do |group, operators|
        assert_equal operators.sort, actual[group].sort, "combinable group #{group} differs"
      end
    end

    # --- Parity with the legacy AdvancedSearch::Fields constants ---

    test 'enum_operator_values matches the legacy set' do
      assert_equal %w[text_equals text_not_equals text_in text_not_in].sort,
                   OperatorCatalog.enum_operator_values['metadata'].sort
      assert_equal %w[= != in not_in].sort,
                   OperatorCatalog.enum_operator_values['standard'].sort
    end

    test 'numeric_operator_values matches the legacy set' do
      assert_equal %w[= != <= >= in not_in between].sort,
                   OperatorCatalog.numeric_operator_values.sort
    end

    test 'date_operator_values matches the legacy set' do
      assert_equal %w[= != <= >= exists not_exists between].sort,
                   OperatorCatalog.date_operator_values.sort
    end

    # The standard comparison operators must forward field_name so that
    # non-metadata date fields (e.g. created_at) route to date-aware comparison.
    test 'standard comparison operators forward field_name to their handler' do
      assert_equal %i[value metadata_key field_name], OperatorCatalog.find('>=').arel_args
      assert_equal %i[value metadata_key field_name], OperatorCatalog.find('<=').arel_args
    end

    # --- Parity with the legacy GraphQL enum maps ---

    test 'graphql_standard_operators matches the legacy enum map' do
      expected = {
        'EQUALS' => '=', 'NOT_EQUALS' => '!=', 'LESS_THAN_EQUALS' => '<=',
        'GREATER_THAN_EQUALS' => '>=', 'CONTAINS' => 'contains', 'NOT_CONTAINS' => 'not_contains',
        'EXISTS' => 'exists', 'NOT_EXISTS' => 'not_exists', 'IN' => 'in', 'NOT_IN' => 'not_in'
      }
      assert_equal expected, OperatorCatalog.graphql_standard_operators
    end

    test 'graphql_metadata_operators matches the legacy enum map' do
      expected = {
        'DATE_GREATER_THAN_EQUALS' => 'date_greater_than_equals',
        'DATE_LESS_THAN_EQUALS' => 'date_less_than_equals',
        'DATE_EQUALS' => 'date_equals', 'DATE_NOT_EQUALS' => 'date_not_equals',
        'DATE_EXISTS' => 'date_exists', 'DATE_NOT_EXISTS' => 'date_not_exists',
        'NUMERIC_GREATER_THAN_EQUALS' => 'numeric_greater_than_equals',
        'NUMERIC_LESS_THAN_EQUALS' => 'numeric_less_than_equals',
        'NUMERIC_EQUALS' => 'numeric_equals', 'NUMERIC_NOT_EQUALS' => 'numeric_not_equals',
        'NUMERIC_EXISTS' => 'numeric_exists', 'NUMERIC_NOT_EXISTS' => 'numeric_not_exists',
        'TEXT_EQUALS' => 'text_equals', 'TEXT_NOT_EQUALS' => 'text_not_equals',
        'TEXT_IN' => 'text_in', 'TEXT_NOT_IN' => 'text_not_in',
        'TEXT_CONTAINS' => 'text_contains', 'TEXT_NOT_CONTAINS' => 'text_not_contains'
      }
      assert_equal expected, OperatorCatalog.graphql_metadata_operators
    end

    test 'every operator maps to a handler on AdvancedSearch::Operators' do
      handler_owner = Class.new do
        include AdvancedSearch::Operators
      end

      operators = OperatorCatalog.all
      operators.each do |operator|
        assert handler_owner.private_method_defined?(operator.arel_handler),
               "missing handler #{operator.arel_handler} for operator #{operator.key}"
      end
    end
  end
end
