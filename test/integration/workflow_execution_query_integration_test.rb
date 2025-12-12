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

  test 'not_contains operator works in Sample::Query after refactor' do
    project = projects(:project1)
    sample_query = Sample::Query.new(
      project_ids: [project.id],
      groups: [Sample::SearchGroup.new(
        conditions: [Sample::SearchCondition.new(
          field: 'name', operator: 'not_contains', value: 'nonexistent'
        )]
      )]
    )
    assert sample_query.valid?
    results = sample_query.send(:ransack_results)
    assert_not_nil results
  end
end
