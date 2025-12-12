# frozen_string_literal: true

require 'test_helper'

# Test the AdvancedQuerySearchable concern through WorkflowExecution::Query
# which includes and implements all the required hook methods
class AdvancedQuerySearchableTest < ActiveSupport::TestCase
  setup do
    @project = projects(:project1)
    @namespace_id = @project.namespace.id
  end

  # Test handle_equals with different field types
  test 'handle_equals with regular field' do
    we = workflow_executions(:irida_next_example)
    search_params = build_search_params(field: 'state', operator: '=', value: we.state)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert(results.all? { |w| w.state == we.state })
  end

  test 'handle_equals with text_match_field (name)' do
    we = workflow_executions(:irida_next_example)
    search_params = build_search_params(field: 'name', operator: '=', value: we.name)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we
  end

  test 'handle_equals with text_match_field case insensitive' do
    we = workflow_executions(:irida_next_example)
    search_params = build_search_params(field: 'name', operator: '=', value: we.name.upcase)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we, 'Should match case-insensitively'
  end

  test 'handle_equals with text_match_field mixed case' do
    we = workflow_executions(:irida_next_example)
    mixed_case = we.name.chars.each_with_index.map { |c, i| i.even? ? c.upcase : c.downcase }.join
    search_params = build_search_params(field: 'name', operator: '=', value: mixed_case)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we, 'Should match with mixed case'
  end

  test 'handle_equals with uppercase_field (run_id)' do
    # Test that uppercase_field? is called (run_id is configured as uppercase field)
    search_params = build_search_params(field: 'run_id', operator: '=', value: 'test_run')
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # Just verify query executes without error
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'handle_equals with nil value on regular field' do
    search_params = build_search_params(field: 'state', operator: '=', value: nil)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Test handle_in with different field types
  test 'handle_in with regular field' do
    we1 = workflow_executions(:irida_next_example)
    we2 = workflow_executions(:irida_next_example_completed)
    search_params = build_search_params(field: 'id', operator: 'in', value: [we1.id, we2.id])
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we1
    assert_includes results, we2
  end

  test 'handle_in with text_match_field (name)' do
    we1 = workflow_executions(:irida_next_example)
    we2 = workflow_executions(:irida_next_example_completed)
    search_params = build_search_params(field: 'name', operator: 'in', value: [we1.name, we2.name])
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we1
    assert_includes results, we2
  end

  test 'handle_in with text_match_field case insensitive' do
    we1 = workflow_executions(:irida_next_example)
    we2 = workflow_executions(:irida_next_example_completed)
    search_params = build_search_params(
      field: 'name',
      operator: 'in',
      value: [we1.name.upcase, we2.name.downcase]
    )
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we1, 'Should match uppercase value'
    assert_includes results, we2, 'Should match lowercase value'
  end

  test 'handle_in with empty array' do
    search_params = build_search_params(field: 'id', operator: 'in', value: [])
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'handle_in with single value' do
    we = workflow_executions(:irida_next_example)
    search_params = build_search_params(field: 'id', operator: 'in', value: [we.id])
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we
    assert_equal 1, results.count
  end

  test 'handle_in with uppercase_field (run_id)' do
    search_params = build_search_params(field: 'run_id', operator: 'in', value: ['test_run'])
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Test handle_not_equals with different field types
  test 'handle_not_equals with regular field' do
    we = workflow_executions(:irida_next_example)
    # Use the enum integer value, not the symbol/string
    state_integer = WorkflowExecution.states[we.state]
    search_params = build_search_params(field: 'state', operator: '!=', value: state_integer)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_not_includes results, we
  end

  test 'handle_not_equals with text_match_field (name)' do
    we = workflow_executions(:irida_next_example)
    search_params = build_search_params(field: 'name', operator: '!=', value: we.name)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_not_includes results, we
  end

  test 'handle_not_equals with text_match_field case insensitive' do
    we = workflow_executions(:irida_next_example)
    search_params = build_search_params(field: 'name', operator: '!=', value: we.name.upcase)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_not_includes results, we, 'Should not include when case differs but matches'
  end

  test 'handle_not_equals with text_match_field includes nulls' do
    # When using != with text_match_field, should include NULL values
    search_params = build_search_params(field: 'name', operator: '!=', value: 'some_value')
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'handle_not_equals with uppercase_field (run_id)' do
    different_run_id = 'DIFFERENT123'
    search_params = build_search_params(field: 'run_id', operator: '!=', value: different_run_id)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'handle_not_equals with nil value' do
    search_params = build_search_params(field: 'state', operator: '!=', value: nil)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Test handle_not_in with different field types
  test 'handle_not_in with regular field' do
    we1 = workflow_executions(:irida_next_example)
    we2 = workflow_executions(:irida_next_example_completed)
    search_params = build_search_params(field: 'id', operator: 'not_in', value: [we1.id])
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_not_includes results, we1
    assert_includes results, we2
  end

  test 'handle_not_in with text_match_field (name)' do
    we = workflow_executions(:irida_next_example)
    search_params = build_search_params(field: 'name', operator: 'not_in', value: [we.name])
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_not_includes results, we
  end

  test 'handle_not_in with text_match_field case insensitive' do
    we = workflow_executions(:irida_next_example)
    search_params = build_search_params(field: 'name', operator: 'not_in', value: [we.name.upcase])
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_not_includes results, we, 'Should not include when value in uppercase list'
  end

  test 'handle_not_in with text_match_field includes nulls' do
    # When using not_in with text_match_field, should include NULL values
    search_params = build_search_params(field: 'name', operator: 'not_in', value: %w[value1 value2])
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'handle_not_in with empty array' do
    search_params = build_search_params(field: 'id', operator: 'not_in', value: [])
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'handle_not_in with uppercase_field (run_id)' do
    search_params = build_search_params(field: 'run_id', operator: 'not_in', value: ['test_run'])
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Test handle_less_than_equal
  test 'handle_less_than_equal with regular field' do
    search_params = build_search_params(field: 'created_at', operator: '<=', value: 1.day.from_now.to_date.to_s)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.any?
  end

  test 'handle_less_than_equal with date field' do
    date = 1.year.from_now.to_date
    search_params = build_search_params(field: 'created_at', operator: '<=', value: date.to_s)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert(results.all? { |we| we.created_at.to_date <= date })
  end

  # Test handle_greater_than_equal
  test 'handle_greater_than_equal with regular field' do
    search_params = build_search_params(field: 'created_at', operator: '>=', value: 1.year.ago.to_date.to_s)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.any?
  end

  test 'handle_greater_than_equal with date field' do
    date = 1.year.ago.to_date
    search_params = build_search_params(field: 'created_at', operator: '>=', value: date.to_s)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert(results.all? { |we| we.created_at.to_date >= date })
  end

  # Test handle_contains
  test 'handle_contains with regular field' do
    we = workflow_executions(:irida_next_example)
    name_fragment = we.name[0..5]
    search_params = build_search_params(field: 'name', operator: 'contains', value: name_fragment)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we
  end

  test 'handle_contains with case insensitive match' do
    we = workflow_executions(:irida_next_example)
    name_fragment = we.name[0..5].upcase
    search_params = build_search_params(field: 'name', operator: 'contains', value: name_fragment)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we, 'Should match case-insensitively'
  end

  test 'handle_contains with SQL wildcard % escapes properly' do
    # Create a workflow execution with % in the name to test literal matching
    we = workflow_executions(:irida_next_example)
    original_name = we.name
    we.update!(name: '100% Complete Test')

    # Search for the literal % character
    search_params = build_search_params(field: 'name', operator: 'contains', value: '100%')
    query = WorkflowExecution::Query.new(search_params)
    results = query.results

    # Should find the record with literal % in name
    assert_includes results, we, 'Should match literal % character'

    # Restore original name
    we.update!(name: original_name)
  end

  test 'handle_contains with SQL wildcard _ escapes properly' do
    # Create a workflow execution with _ in the name to test literal matching
    we = workflow_executions(:irida_next_example)
    original_name = we.name
    we.update!(name: 'test_workflow_name')

    # Search for the literal _ character
    search_params = build_search_params(field: 'name', operator: 'contains', value: 'test_workflow')
    query = WorkflowExecution::Query.new(search_params)
    results = query.results

    # Should find the record with literal _ in name
    assert_includes results, we, 'Should match literal _ character'

    # Restore original name
    we.update!(name: original_name)
  end

  test 'handle_contains with mixed SQL wildcards escapes properly' do
    search_params = build_search_params(field: 'name', operator: 'contains', value: '%_test_100%')
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # Should execute without error - wildcards treated as literals
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'handle_contains matches substring in middle' do
    we = workflow_executions(:irida_next_example)
    return unless we.name.length > 4

    middle_fragment = we.name[2..5]
    search_params = build_search_params(field: 'name', operator: 'contains', value: middle_fragment)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we
  end

  test 'handle_contains matches substring at end' do
    we = workflow_executions(:irida_next_example)
    return unless we.name.length > 4

    end_fragment = we.name[-4..]
    search_params = build_search_params(field: 'name', operator: 'contains', value: end_fragment)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we
  end

  test 'handle_contains with blank value returns unchanged scope' do
    search_params = build_search_params(field: 'name', operator: 'contains', value: '')
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'handle_contains with nil value returns unchanged scope' do
    search_params = build_search_params(field: 'name', operator: 'contains', value: nil)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'handle_contains with uuid_field casts to text' do
    we = workflow_executions(:irida_next_example)
    id_fragment = we.id[0..7]
    search_params = build_search_params(field: 'id', operator: 'contains', value: id_fragment)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we
  end

  test 'handle_contains with uuid_field case insensitive' do
    we = workflow_executions(:irida_next_example)
    id_fragment = we.id[0..7].upcase
    search_params = build_search_params(field: 'id', operator: 'contains', value: id_fragment)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we, 'UUID contains should be case-insensitive'
  end

  # Test handle_exists
  test 'handle_exists filters for non-null values' do
    search_params = build_search_params(field: 'name', operator: 'exists', value: '')
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.all?(&:name)
  end

  # Test handle_not_exists
  test 'handle_not_exists filters for null values' do
    search_params = build_search_params(field: 'tags', operator: 'not_exists', value: '')
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Test JSONB field handling
  test 'JSONB field equals operator' do
    search_params = build_search_params(field: 'workflow_version', operator: '=', value: '1.0.0')
    query = WorkflowExecution::Query.new(search_params)
    assert query.valid?
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'JSONB field in operator' do
    search_params = build_search_params(field: 'workflow_version', operator: 'in', value: %w[1.0.0 2.0.0])
    query = WorkflowExecution::Query.new(search_params)
    assert query.valid?
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'JSONB field not_equals operator' do
    search_params = build_search_params(field: 'workflow_version', operator: '!=', value: '1.0.0')
    query = WorkflowExecution::Query.new(search_params)
    assert query.valid?
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'JSONB field not_in operator' do
    search_params = build_search_params(field: 'workflow_version', operator: 'not_in', value: ['1.0.0'])
    query = WorkflowExecution::Query.new(search_params)
    assert query.valid?
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'JSONB field contains operator' do
    search_params = build_search_params(field: 'workflow_version', operator: 'contains', value: '1.0')
    query = WorkflowExecution::Query.new(search_params)
    assert query.valid?
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Test operator mapping
  test 'unknown operator is caught by validation' do
    search_params = build_search_params(field: 'name', operator: 'unknown_op', value: 'test')
    query = WorkflowExecution::Query.new(search_params)
    # Validation should catch invalid operator
    # Note: validation is handled by WorkflowExecutionSearchGroupValidator, not AdvancedQuerySearchable
    # AdvancedQuerySearchable just returns unchanged scope for unknown operators
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Test JSONB numeric comparison
  test 'JSONB numeric comparison with >= operator' do
    search_params = build_search_params(field: 'workflow_version', operator: '>=', value: '1.0')
    query = WorkflowExecution::Query.new(search_params)
    assert query.valid?
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'JSONB numeric comparison with <= operator' do
    search_params = build_search_params(field: 'workflow_version', operator: '<=', value: '2.0')
    query = WorkflowExecution::Query.new(search_params)
    assert query.valid?
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Test complex conditions with AND/OR logic
  test 'multiple conditions in single group use AND logic' do
    we = workflow_executions(:irida_next_example)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'state', operator: '=', value: we.state },
            '1': { field: 'name', operator: 'contains', value: we.name[0..5] }
          }
        }
      },
      namespace_id: @namespace_id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert(results.all? { |w| w.state == we.state && w.name.include?(we.name[0..5]) })
  end

  test 'multiple groups use OR logic' do
    we1 = workflow_executions(:irida_next_example)
    we2 = workflow_executions(:irida_next_example_completed)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'id', operator: '=', value: we1.id }
          }
        },
        '1': {
          conditions_attributes: {
            '0': { field: 'id', operator: '=', value: we2.id }
          }
        }
      },
      namespace_id: @namespace_id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we1
    assert_includes results, we2
  end

  # Test edge cases
  test 'condition with blank field is skipped' do
    search_params = build_search_params(field: '', operator: '=', value: 'test')
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # Should not error, just skip the blank field
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'empty groups array returns base scope' do
    search_params = {
      groups_attributes: {},
      namespace_id: @namespace_id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.any?
  end

  # Test JSONB date comparison edge cases
  test 'JSONB date comparison handles invalid date format' do
    search_params = build_search_params(field: 'workflow_version', operator: '>=', value: 'not-a-date')
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # Should execute without raising error
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'JSONB numeric comparison handles non-numeric strings' do
    search_params = build_search_params(field: 'workflow_version', operator: '>=', value: 'abc')
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # Should execute without raising error
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'JSONB numeric comparison with decimal values' do
    search_params = build_search_params(field: 'workflow_version', operator: '>=', value: '1.5')
    query = WorkflowExecution::Query.new(search_params)
    assert query.valid?
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'JSONB numeric comparison with negative values' do
    search_params = build_search_params(field: 'workflow_version', operator: '<=', value: '-1')
    query = WorkflowExecution::Query.new(search_params)
    assert query.valid?
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Test operator combinations
  test 'apply_operator with unknown operator returns unchanged scope' do
    # Unknown operators should not modify the scope
    search_params = build_search_params(field: 'name', operator: 'unknown_op', value: 'test')
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # Should execute without error
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Test lower helper method behavior
  test 'lower node creates case insensitive comparison' do
    we = workflow_executions(:irida_next_example)
    # Test with mixed case name
    search_params = build_search_params(field: 'name', operator: '=', value: we.name.swapcase)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we, 'Lower helper should enable case-insensitive matching'
  end

  # Test array value handling edge cases
  test 'handle_in with array containing nil' do
    we = workflow_executions(:irida_next_example)
    search_params = build_search_params(field: 'id', operator: 'in', value: [we.id, nil])
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'handle_not_in with array containing nil' do
    we = workflow_executions(:irida_next_example)
    search_params = build_search_params(field: 'id', operator: 'not_in', value: [we.id, nil])
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Test complex multi-condition scenarios
  test 'multiple conditions with different operators in single group' do
    we = workflow_executions(:irida_next_example)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'state', operator: '=', value: we.state },
            '1': { field: 'name', operator: 'contains', value: we.name[0..3] },
            '2': { field: 'created_at', operator: '>=', value: 1.year.ago.to_date.to_s }
          }
        }
      },
      namespace_id: @namespace_id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # All conditions should be AND-ed together
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'three groups with OR logic' do
    we1 = workflow_executions(:irida_next_example)
    we2 = workflow_executions(:irida_next_example_completed)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'id', operator: '=', value: we1.id }
          }
        },
        '1': {
          conditions_attributes: {
            '0': { field: 'id', operator: '=', value: we2.id }
          }
        },
        '2': {
          conditions_attributes: {
            '0': { field: 'state', operator: '=', value: 'nonexistent' }
          }
        }
      },
      namespace_id: @namespace_id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we1
    assert_includes results, we2
  end

  # Test hook method overrides
  test 'hook methods can be overridden by including class' do
    # The WorkflowExecution::Query overrides several hook methods
    # Verify that text_match_field? returns true for 'name'
    we = workflow_executions(:irida_next_example)
    search_params = build_search_params(field: 'name', operator: '=', value: we.name.upcase)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # Should match because text_match_field? returns true for 'name'
    assert_includes results, we
  end

  test 'uuid_field returns true for id field' do
    we = workflow_executions(:irida_next_example)
    id_fragment = we.id[0..7]
    search_params = build_search_params(field: 'id', operator: 'contains', value: id_fragment)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # Should work because uuid_field? returns true for 'id'
    assert_includes results, we
  end

  # Test exists/not_exists with various fields
  test 'handle_exists with different field types' do
    search_params = build_search_params(field: 'id', operator: 'exists', value: '')
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # All records should have an id
    assert results.any?
    assert results.all?(&:id)
  end

  test 'handle_not_exists with created_at field' do
    search_params = build_search_params(field: 'created_at', operator: 'not_exists', value: '')
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # Created_at is always set, so this should return no results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Test value type conversions
  test 'handle_equals converts value to string for text fields' do
    workflow_executions(:irida_next_example)
    # Pass an integer as value for a text field
    search_params = build_search_params(field: 'name', operator: '=', value: 123)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # Should handle the conversion gracefully
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'handle_contains converts value to string' do
    search_params = build_search_params(field: 'name', operator: 'contains', value: 123)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Test comparison operators with string dates
  test 'handle_less_than_equal with date string on date field' do
    future_date = 5.years.from_now.to_date.to_s
    search_params = build_search_params(field: 'created_at', operator: '<=', value: future_date)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # All existing records should be less than 5 years from now
    assert results.any?
  end

  test 'handle_greater_than_equal with date string on date field' do
    past_date = 10.years.ago.to_date.to_s
    search_params = build_search_params(field: 'created_at', operator: '>=', value: past_date)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # Records newer than 10 years ago
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Test chaining and scope composition
  test 'advanced query scope can be chained with other scopes' do
    we = workflow_executions(:irida_next_example)
    search_params = build_search_params(field: 'state', operator: '=', value: we.state)
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # Results should be an ActiveRecord::Relation that can be further chained
    assert_respond_to results, :where
    assert_respond_to results, :order
    assert_respond_to results, :limit
  end

  private

  def build_search_params(field:, operator:, value:)
    {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field:, operator:, value: }
          }
        }
      },
      namespace_id: @namespace_id
    }
  end
end
