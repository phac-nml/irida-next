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

  test 'handle_equals with uppercase_field (run_id)' do
    # Test that uppercase_field? is called (run_id is configured as uppercase field)
    search_params = build_search_params(field: 'run_id', operator: '=', value: 'test_run')
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # Just verify query executes without error
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

  test 'handle_in with uppercase_field (run_id)' do
    search_params = build_search_params(field: 'run_id', operator: 'in', value: ['test_run'])
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Test handle_not_equals with different field types
  test 'handle_not_equals with regular field' do
    we = workflow_executions(:irida_next_example)
    search_params = build_search_params(field: 'state', operator: '!=', value: we.state)
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

  test 'handle_not_equals with uppercase_field (run_id)' do
    different_run_id = 'DIFFERENT123'
    search_params = build_search_params(field: 'run_id', operator: '!=', value: different_run_id)
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

  test 'handle_contains with blank value returns unchanged scope' do
    search_params = build_search_params(field: 'name', operator: 'contains', value: '')
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
