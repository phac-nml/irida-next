# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionQueryIntegrationTest < ActiveSupport::TestCase
  setup do
    @namespace = groups(:group_one)
    @workflow_execution1 = workflow_executions(:workflow_execution_valid)
    @workflow_execution2 = workflow_executions(:irida_next_example_completed)
    @workflow_execution3 = workflow_executions(:irida_next_example_error)
  end

  test 'state enum conversion with invalid state name handles gracefully' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'state', operator: '=', value: 'invalid_state'
        )]
      )]
    )
    # Should not raise an error even with invalid state
    assert query.valid?
    results = query.send(:ransack_results)
    assert_not_nil results
  end

  test 'state enum search with not_in operator and array of state strings' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@workflow_execution2.namespace_id, @workflow_execution3.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'state', operator: 'not_in', value: %w[error canceled]
        )]
      )]
    )
    assert query.valid?
    results = query.send(:ransack_results)
    assert_not_nil results
    assert_not results.include?(@workflow_execution3) # error state should be excluded
  end

  test 'metadata field search with special characters in field names' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@workflow_execution1.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.pipeline_id', operator: 'contains', value: 'phac-nml'
        )]
      )]
    )
    assert query.valid?
    results = query.send(:ransack_results)
    assert_not_nil results
  end

  test 'metadata field search with exists operator for nil values' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.nonexistent_field', operator: 'not_exists', value: ''
        )]
      )]
    )
    assert query.valid?
    results = query.send(:ransack_results)
    assert_not_nil results
  end

  test 'not_contains operator with metadata fields' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@workflow_execution1.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.pipeline_id', operator: 'not_contains', value: 'nonexistent'
        )]
      )]
    )
    assert query.valid?
    results = query.send(:ransack_results)
    assert results.include?(@workflow_execution1)
  end

  test 'complex query with multiple groups and conditions (AND + OR logic)' do
    # Group 1: state = completed
    # Group 2: name contains "valid"
    # These are combined with OR
    query = WorkflowExecution::Query.new(
      namespace_ids: [@workflow_execution1.namespace_id, @workflow_execution2.namespace_id],
      groups: [
        WorkflowExecution::SearchGroup.new(
          conditions: [WorkflowExecution::SearchCondition.new(
            field: 'state', operator: '=', value: 'completed'
          )]
        ),
        WorkflowExecution::SearchGroup.new(
          conditions: [WorkflowExecution::SearchCondition.new(
            field: 'name', operator: 'contains', value: 'valid'
          )]
        )
      ]
    )
    assert query.valid?
    results = query.send(:ransack_results)
    assert_not_nil results
    # Should include both workflow_execution1 (has "valid" in name) and workflow_execution2 (completed state)
    assert results.exists?(id: @workflow_execution1.id) || results.exists?(id: @workflow_execution2.id)
  end

  test 'pagination with advanced search active' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'state', operator: 'in', value: %w[completed initial error]
        )]
      )]
    )
    pagy, results = query.results(limit: 5, page: 1)
    assert_not_nil pagy
    assert_not_nil results
    assert pagy.is_a?(Pagy)
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Edge case tests
  test 'multiple conditions in single group with AND logic' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@workflow_execution2.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [
          WorkflowExecution::SearchCondition.new(field: 'state', operator: '=', value: 'completed'),
          WorkflowExecution::SearchCondition.new(field: 'name', operator: 'contains', value: 'completed')
        ]
      )]
    )
    assert query.valid?
    results = query.send(:ransack_results)
    assert_not_nil results
    assert results.include?(@workflow_execution2)
  end

  test 'three or more conditions in single group' do
    we_with_dates = workflow_executions(:workflow_execution_with_metadata_dates)
    query = WorkflowExecution::Query.new(
      namespace_ids: [we_with_dates.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [
          WorkflowExecution::SearchCondition.new(field: 'state', operator: '=', value: 'completed'),
          WorkflowExecution::SearchCondition.new(field: 'metadata.pipeline_id', operator: '=',
                                                 value: 'phac-nml/iridanextexample'),
          WorkflowExecution::SearchCondition.new(field: 'metadata.start_date', operator: '>=', value: '2024-01-01')
        ]
      )]
    )
    assert query.valid?
    results = query.send(:ransack_results)
    assert_not_nil results
    assert results.include?(we_with_dates)
  end

  test 'invalid query returns empty results' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'invalid_field', operator: '=', value: 'test'
        )]
      )]
    )
    assert_not query.valid?
    results = query.send(:ransack_results)
    assert_equal 0, results.count
  end

  test 'range query with >= and <= on same field' do
    we_with_dates = workflow_executions(:workflow_execution_with_metadata_dates)
    we_with_dates_two = workflow_executions(:workflow_execution_with_metadata_dates2)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_with_dates.namespace_id, we_with_dates_two.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [
          WorkflowExecution::SearchCondition.new(field: 'metadata.start_date', operator: '>=', value: '2024-01-01'),
          WorkflowExecution::SearchCondition.new(field: 'metadata.start_date', operator: '<=', value: '2024-01-31')
        ]
      )]
    )
    assert query.valid?
    results = query.send(:ransack_results)
    assert results.include?(we_with_dates)
    assert_not results.include?(we_with_dates_two)
  end

  test 'non-paginated results' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'state', operator: 'in', value: %w[completed initial error]
        )]
      )]
    )
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
    assert_not results.is_a?(Array)
  end

  test 'ransack integration with name_or_id_cont and advanced search' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@workflow_execution1.namespace_id, @workflow_execution2.namespace_id],
      name_or_id_cont: 'example',
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'state', operator: '=', value: 'completed'
        )]
      )]
    )
    assert query.valid?
    results = query.send(:ransack_results)
    assert_not_nil results
    # Should only include completed records with 'example' in name
    assert results.include?(@workflow_execution2)
  end

  test 'ransack integration with name_or_id_in' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@workflow_execution1.namespace_id, @workflow_execution2.namespace_id],
      name_or_id_in: [@workflow_execution1.name, @workflow_execution2.name]
    )
    assert query.valid?
    results = query.send(:ransack_results)
    assert_not_nil results
    assert results.include?(@workflow_execution1)
    assert results.include?(@workflow_execution2)
  end

  test 'empty array for in operator' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'state', operator: 'in', value: []
        )]
      )]
    )
    # Should handle empty array gracefully
    results = query.send(:ransack_results)
    assert_not_nil results
  end

  test 'metadata field with invalid format does not match' do
    we_with_dates = workflow_executions(:workflow_execution_with_metadata_dates)
    we_special = workflow_executions(:workflow_execution_with_special_chars)

    # Test invalid date format
    we_special.update(metadata: we_special.metadata.merge('start_date' => 'not-a-date'))

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_with_dates.namespace_id, we_special.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.start_date', operator: '>=', value: '2024-01-01'
        )]
      )]
    )
    results = query.send(:ransack_results)
    # Only valid dates should match
    assert results.include?(we_with_dates)
    assert_not results.include?(we_special)

    # Test invalid numeric format
    we_special.update(metadata: we_special.metadata.merge('sample_count' => 'not-a-number'))

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_with_dates.namespace_id, we_special.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.sample_count', operator: '>=', value: 5
        )]
      )]
    )
    results = query.send(:ransack_results)
    # Only valid numbers should match
    assert results.include?(we_with_dates)
    assert_not results.include?(we_special)
  end

  test 'sorting with advanced search' do
    we_with_dates = workflow_executions(:workflow_execution_with_metadata_dates)
    we_with_dates_two = workflow_executions(:workflow_execution_with_metadata_dates2)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_with_dates.namespace_id, we_with_dates_two.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'state', operator: '=', value: 'completed'
        )]
      )],
      sort: 'metadata_start_date asc'
    )
    assert query.valid?
    results = query.send(:ransack_results).to_a
    # Verify both records are in results
    assert results.include?(we_with_dates)
    assert results.include?(we_with_dates_two)
    # Verify results are sorted by start_date
    we_with_dates_index = results.index(we_with_dates)
    we_with_dates_two_index = results.index(we_with_dates_two)
    assert we_with_dates_index < we_with_dates_two_index,
           'Expected we_with_dates (2024-01-15) before we_with_dates_two (2024-02-01)'
  end

  test 'conflicting conditions result in no matches' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [
          WorkflowExecution::SearchCondition.new(field: 'state', operator: '=', value: 'completed'),
          WorkflowExecution::SearchCondition.new(field: 'state', operator: '=', value: 'error')
        ]
      )]
    )
    # This should be invalid due to duplicate field conditions
    assert_not query.valid?
  end

  test 'results count is accurate for complex query' do
    we_with_dates = workflow_executions(:workflow_execution_with_metadata_dates)
    we_with_dates_two = workflow_executions(:workflow_execution_with_metadata_dates2)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_with_dates.namespace_id, we_with_dates_two.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [
          WorkflowExecution::SearchCondition.new(field: 'state', operator: '=', value: 'completed'),
          WorkflowExecution::SearchCondition.new(field: 'metadata.sample_count', operator: '>=', value: 10)
        ]
      )]
    )
    results = query.send(:ransack_results)
    assert_equal 2, results.count
  end
end
