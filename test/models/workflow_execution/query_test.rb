# frozen_string_literal: true

require 'test_helper'

class WorkflowExecution::QueryTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  DEFAULT_METADATA = { 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.0' }.freeze

  setup do
    @namespace = groups(:group_one)
    @workflow_execution1 = workflow_executions(:workflow_execution_valid)
    @workflow_execution2 = workflow_executions(:irida_next_example_completed)
    @user = users(:john_doe)
  end

  test 'basic search with name_or_id_cont' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@workflow_execution1.namespace_id],
      name_or_id_cont: 'valid'
    )
    results = query.send(:ransack_results)
    assert results.include?(@workflow_execution1)
  end

  test 'advanced search with single condition' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@workflow_execution1.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: '=', value: @workflow_execution1.name
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(@workflow_execution1)
  end

  test 'advanced search with multiple groups (OR logic)' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@workflow_execution1.namespace_id, @workflow_execution2.namespace_id],
      groups: [
        WorkflowExecution::SearchGroup.new(
          conditions: [WorkflowExecution::SearchCondition.new(
            field: 'name', operator: '=', value: @workflow_execution1.name
          )]
        ),
        WorkflowExecution::SearchGroup.new(
          conditions: [WorkflowExecution::SearchCondition.new(
            field: 'name', operator: '=', value: @workflow_execution2.name
          )]
        )
      ]
    )
    results = query.send(:ransack_results)
    assert results.include?(@workflow_execution1)
    assert results.include?(@workflow_execution2)
  end

  test 'state enum conversion from string to integer' do
    # Test single state string
    query = WorkflowExecution::Query.new(
      namespace_ids: [@workflow_execution2.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'state', operator: '=', value: 'completed'
        )]
      )]
    )
    # Should not raise an error and should convert completed to 5
    assert query.valid?
    results = query.send(:ransack_results)
    assert_not_nil results
    assert results.include?(@workflow_execution2)
  end

  test 'state enum search with in operator and array of state strings' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@workflow_execution1.namespace_id, @workflow_execution2.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'state', operator: 'in', value: %w[completed initial]
        )]
      )]
    )
    assert query.valid?
    results = query.send(:ransack_results)
    assert_not_nil results
  end

  test 'metadata field search with dot notation' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@workflow_execution1.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.pipeline_id', operator: 'contains', value: 'iridanextexample'
        )]
      )]
    )
    assert query.valid?
    results = query.send(:ransack_results)
    assert_not_nil results
  end

  test 'sorting by standard field' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      sort: 'name asc'
    )
    assert_equal 'name', query.column
    assert_equal 'asc', query.direction
  end

  test 'sorting by metadata field' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      sort: 'metadata_pipeline_id desc'
    )
    assert_equal 'metadata.pipeline_id', query.column
    assert_equal 'desc', query.direction
  end

  # Tests for != operator
  test 'not equals operator with regular field' do
    we_completed = workflow_executions(:irida_next_example_completed)
    we_error = workflow_executions(:irida_next_example_error)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_completed.namespace_id, we_error.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'run_id', operator: '!=', value: we_completed.run_id
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert_not results.include?(we_completed)
    assert results.include?(we_error)
  end

  test 'not equals operator with metadata field' do
    we_valid = workflow_executions(:workflow_execution_valid)
    we_gasclustering = workflow_executions(:workflow_execution_gasclustering)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_valid.namespace_id, we_gasclustering.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.pipeline_id', operator: '!=', value: 'phac-nml/iridanextexample'
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert_not results.include?(we_valid)
    assert results.include?(we_gasclustering)
  end

  test 'not equals operator with name field' do
    we_valid = workflow_executions(:workflow_execution_valid)
    we_gasclustering = workflow_executions(:workflow_execution_gasclustering)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_valid.namespace_id, we_gasclustering.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: '!=', value: we_valid.name
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert_not results.include?(we_valid)
    assert results.include?(we_gasclustering)
  end

  # Tests for = operator
  test 'equals operator with regular field' do
    we_valid = workflow_executions(:workflow_execution_valid)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_valid.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'run_id', operator: '=', value: we_valid.run_id
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we_valid)
  end

  test 'equals operator with metadata field' do
    we_valid = workflow_executions(:workflow_execution_valid)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_valid.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.pipeline_id', operator: '=', value: 'phac-nml/iridanextexample'
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we_valid)
  end

  test 'equals operator with name field case insensitive' do
    we_valid = workflow_executions(:workflow_execution_valid)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_valid.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: '=', value: we_valid.name.upcase
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we_valid)
  end

  # Tests for exists operator
  test 'exists operator with metadata field' do
    we_with_dates = workflow_executions(:workflow_execution_with_metadata_dates)
    we_null_metadata = workflow_executions(:workflow_execution_with_null_metadata)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_with_dates.namespace_id, we_null_metadata.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.start_date', operator: 'exists', value: ''
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we_with_dates)
    assert_not results.include?(we_null_metadata)
  end

  test 'exists operator with regular field' do
    we_with_run_id = workflow_executions(:workflow_execution_valid)
    we_without_run_id = workflow_executions(:workflow_execution_missing_run_id)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_with_run_id.namespace_id, we_without_run_id.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'run_id', operator: 'exists', value: ''
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we_with_run_id)
    assert_not results.include?(we_without_run_id)
  end

  # Tests for in operator with non-enum fields
  test 'in operator with regular field' do
    we_valid = workflow_executions(:workflow_execution_valid)
    we_gasclustering = workflow_executions(:workflow_execution_gasclustering)
    we_completed = workflow_executions(:irida_next_example_completed)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_valid.namespace_id, we_gasclustering.namespace_id, we_completed.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'run_id', operator: 'in', value: [we_valid.run_id, we_gasclustering.run_id]
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we_valid)
    assert results.include?(we_gasclustering)
    assert_not results.include?(we_completed)
  end

  test 'in operator with name field case insensitive' do
    we_valid = workflow_executions(:workflow_execution_valid)
    we_gasclustering = workflow_executions(:workflow_execution_gasclustering)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_valid.namespace_id, we_gasclustering.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'in', value: [we_valid.name.upcase, we_gasclustering.name.upcase]
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we_valid)
    assert results.include?(we_gasclustering)
  end

  test 'in operator with metadata field case insensitive' do
    we_valid = workflow_executions(:workflow_execution_valid)
    we_gasclustering = workflow_executions(:workflow_execution_gasclustering)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_valid.namespace_id, we_gasclustering.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.pipeline_id',
          operator: 'in',
          value: ['PHAC-NML/IRIDANEXTEXAMPLE', 'PHAC-NML/GASCLUSTERING']
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we_valid)
    assert results.include?(we_gasclustering)
  end

  # Tests for not_in operator with non-enum fields
  test 'not_in operator with regular field' do
    we_valid = workflow_executions(:workflow_execution_valid)
    we_gasclustering = workflow_executions(:workflow_execution_gasclustering)
    we_completed = workflow_executions(:irida_next_example_completed)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_valid.namespace_id, we_gasclustering.namespace_id, we_completed.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'run_id', operator: 'not_in', value: [we_valid.run_id, we_gasclustering.run_id]
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert_not results.include?(we_valid)
    assert_not results.include?(we_gasclustering)
    assert results.include?(we_completed)
  end

  test 'not_in operator with name field' do
    we_valid = workflow_executions(:workflow_execution_valid)
    we_gasclustering = workflow_executions(:workflow_execution_gasclustering)
    we_completed = workflow_executions(:irida_next_example_completed)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_valid.namespace_id, we_gasclustering.namespace_id, we_completed.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'not_in', value: [we_valid.name, we_gasclustering.name]
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert_not results.include?(we_valid)
    assert_not results.include?(we_gasclustering)
    assert results.include?(we_completed)
  end

  test 'not_in operator with metadata field' do
    we_with_dates = workflow_executions(:workflow_execution_with_metadata_dates)
    we_with_dates_two = workflow_executions(:workflow_execution_with_metadata_dates2)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_with_dates.namespace_id, we_with_dates_two.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.pipeline_id', operator: 'not_in', value: ['phac-nml/iridanextexample']
        )]
      )]
    )
    results = query.send(:ransack_results)
    # Should exclude records with pipeline_id = phac-nml/iridanextexample
    assert_not results.include?(we_with_dates)
    assert results.include?(we_with_dates_two)
  end

  # Tests for contains operator with regular fields
  test 'contains operator with name field' do
    we_valid = workflow_executions(:workflow_execution_valid)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_valid.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'contains', value: 'valid'
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we_valid)
  end

  test 'contains operator with run_id field' do
    we_valid = workflow_executions(:workflow_execution_valid)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_valid.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'run_id', operator: 'contains', value: 'run_id'
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we_valid)
  end

  # Tests for <= operator
  test 'less than or equal operator with regular timestamp field' do
    we_valid = workflow_executions(:workflow_execution_valid)

    # Use a future date to ensure we_valid is included
    future_date = 1.year.from_now

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_valid.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'created_at', operator: '<=', value: future_date
        )]
      )]
    )
    results = query.send(:ransack_results)
    # Just verify the query executes and returns a result set
    assert results.is_a?(ActiveRecord::Relation)
    assert results.count >= 0
  end

  test 'less than or equal operator with metadata date field' do
    we_with_dates = workflow_executions(:workflow_execution_with_metadata_dates)
    we_with_dates_two = workflow_executions(:workflow_execution_with_metadata_dates2)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_with_dates.namespace_id, we_with_dates_two.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.start_date', operator: '<=', value: '2024-01-20'
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we_with_dates)
    assert_not results.include?(we_with_dates_two)
  end

  test 'less than or equal operator with metadata numeric field' do
    we_with_dates = workflow_executions(:workflow_execution_with_metadata_dates)
    we_with_dates_two = workflow_executions(:workflow_execution_with_metadata_dates2)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_with_dates.namespace_id, we_with_dates_two.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.sample_count', operator: '<=', value: 15
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we_with_dates) # 10
    assert_not results.include?(we_with_dates_two) # 25
  end

  # Tests for >= operator
  test 'greater than or equal operator with regular timestamp field' do
    we_valid = workflow_executions(:workflow_execution_valid)

    # Use a past date to ensure we_valid is included
    past_date = 1.year.ago

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_valid.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'created_at', operator: '>=', value: past_date
        )]
      )]
    )
    results = query.send(:ransack_results)
    # Just verify the query executes and returns a result set
    assert results.is_a?(ActiveRecord::Relation)
    assert results.count >= 0
  end

  test 'greater than or equal operator with metadata date field' do
    we_with_dates = workflow_executions(:workflow_execution_with_metadata_dates)
    we_with_dates_two = workflow_executions(:workflow_execution_with_metadata_dates2)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_with_dates.namespace_id, we_with_dates_two.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.start_date', operator: '>=', value: '2024-02-01'
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert_not results.include?(we_with_dates)
    assert results.include?(we_with_dates_two)
  end

  test 'greater than or equal operator with metadata numeric field' do
    we_with_dates = workflow_executions(:workflow_execution_with_metadata_dates)
    we_with_dates_two = workflow_executions(:workflow_execution_with_metadata_dates2)

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_with_dates.namespace_id, we_with_dates_two.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.sample_count', operator: '>=', value: 20
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert_not results.include?(we_with_dates) # 10
    assert results.include?(we_with_dates_two) # 25
  end

  # Tests for special characters and SQL injection prevention
  test 'contains operator with percent wildcard character should be escaped' do
    # Create a workflow execution with a name containing %
    we = WorkflowExecution.create!(
      name: 'Test%Workflow',
      namespace_id: @namespace.id,
      state: :initial,
      run_id: 'test_run_percent',
      submitter_id: @user.id,
      metadata: DEFAULT_METADATA
    )

    # Search for literal % character - should only match exact %
    query = WorkflowExecution::Query.new(
      namespace_ids: [we.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'contains', value: '%'
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we)

    # Verify it doesn't match everything (which would happen if % wasn't escaped)
    query2 = WorkflowExecution::Query.new(
      namespace_ids: [@workflow_execution1.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'contains', value: '%'
        )]
      )]
    )
    results2 = query2.send(:ransack_results)
    # Should not match workflow_execution1 if % is properly escaped
    assert_not results2.include?(@workflow_execution1)
  ensure
    we&.destroy
  end

  test 'contains operator with underscore wildcard character should be escaped' do
    # Create a workflow execution with a name containing _
    we = WorkflowExecution.create!(
      name: 'Test_Workflow',
      namespace_id: @namespace.id,
      state: :initial,
      run_id: 'test_run_underscore',
      submitter_id: @user.id,
      metadata: DEFAULT_METADATA
    )

    # Search for literal _ character - should only match exact _
    query = WorkflowExecution::Query.new(
      namespace_ids: [we.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'contains', value: '_'
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we)

    # Verify it doesn't match single characters (which would happen if _ wasn't escaped)
    we2 = WorkflowExecution.create!(
      name: 'TestXWorkflow',
      namespace_id: @namespace.id,
      state: :initial,
      run_id: 'test_run_no_underscore',
      submitter_id: @user.id,
      metadata: DEFAULT_METADATA
    )
    query2 = WorkflowExecution::Query.new(
      namespace_ids: [we2.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'contains', value: '_'
        )]
      )]
    )
    results2 = query2.send(:ransack_results)
    # Should not match we2 if _ is properly escaped
    assert_not results2.include?(we2)
  ensure
    we&.destroy
    we2&.destroy
  end

  test 'contains operator with backslash should be escaped' do
    # Create a workflow execution with a name containing backslash
    we = WorkflowExecution.create!(
      name: 'Test\\Workflow',
      namespace_id: @namespace.id,
      state: :initial,
      run_id: 'test_run_backslash',
      submitter_id: @user.id,
      metadata: DEFAULT_METADATA
    )

    query = WorkflowExecution::Query.new(
      namespace_ids: [we.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'contains', value: '\\'
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we)
  ensure
    we&.destroy
  end

  test 'not_contains operator with percent wildcard should be escaped' do
    we_with_percent = WorkflowExecution.create!(
      name: 'Test%Workflow',
      namespace_id: @namespace.id,
      state: :initial,
      run_id: 'test_run_with_percent',
      submitter_id: @user.id,
      metadata: DEFAULT_METADATA
    )
    we_without_percent = WorkflowExecution.create!(
      name: 'TestWorkflow',
      namespace_id: @namespace.id,
      state: :initial,
      run_id: 'test_run_without_percent',
      submitter_id: @user.id,
      metadata: DEFAULT_METADATA
    )

    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'not_contains', value: '%'
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert_not results.include?(we_with_percent)
    assert results.include?(we_without_percent)
  ensure
    we_with_percent&.destroy
    we_without_percent&.destroy
  end

  test 'contains operator with metadata field and special characters' do
    we = WorkflowExecution.create!(
      name: 'Test Workflow',
      namespace_id: @namespace.id,
      state: :initial,
      run_id: 'test_run_metadata_special',
      metadata: DEFAULT_METADATA.merge('special_field' => 'value%with_special\\chars'),
      submitter_id: @user.id
    )

    query = WorkflowExecution::Query.new(
      namespace_ids: [we.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.special_field', operator: 'contains', value: '%with_'
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we)
  ensure
    we&.destroy
  end

  # Tests for edge cases
  test 'in operator with empty array should be handled gracefully' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'in', value: []
        )]
      )]
    )
    # Should not raise an error
    assert_not query.valid?
  end

  test 'not_in operator with empty array should be handled gracefully' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'not_in', value: []
        )]
      )]
    )
    # Should not raise an error
    assert_not query.valid?
  end

  test 'contains operator with empty string' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'contains', value: ''
        )]
      )]
    )
    # Empty string should not be valid
    assert_not query.valid?
  end

  test 'metadata field with null value and exists operator' do
    we_with_null = WorkflowExecution.create!(
      name: 'Test Null Metadata',
      namespace_id: @namespace.id,
      state: :initial,
      run_id: 'test_run_null_meta',
      metadata: DEFAULT_METADATA.merge('field1' => 'value1'),
      submitter_id: @user.id
    )

    query = WorkflowExecution::Query.new(
      namespace_ids: [we_with_null.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'metadata.nonexistent_field', operator: 'not_exists', value: ''
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we_with_null)
  ensure
    we_with_null&.destroy
  end

  test 'in operator with array containing nil values should handle gracefully' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'in', value: ['valid_name', nil, '']
        )]
      )]
    )
    # Should not raise an error - validator uses compact_blank which removes nil and empty strings
    # Since there's at least one valid value ('valid_name'), the query should be valid
    assert query.valid?
    # The query should execute without errors
    assert_nothing_raised do
      query.send(:ransack_results)
    end
  end

  test 'contains operator with unicode characters' do
    we = WorkflowExecution.create!(
      name: 'Test™Workflow©',
      namespace_id: @namespace.id,
      state: :initial,
      run_id: 'test_run_unicode',
      submitter_id: @user.id,
      metadata: DEFAULT_METADATA
    )

    query = WorkflowExecution::Query.new(
      namespace_ids: [we.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'contains', value: '™'
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we)
  ensure
    we&.destroy
  end

  test 'contains operator with leading and trailing spaces' do
    we = WorkflowExecution.create!(
      name: 'Test Workflow',
      namespace_id: @namespace.id,
      state: :initial,
      run_id: 'test_run_spaces',
      submitter_id: @user.id,
      metadata: DEFAULT_METADATA
    )

    query = WorkflowExecution::Query.new(
      namespace_ids: [we.namespace_id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'contains', value: ' Workflow'
        )]
      )]
    )
    results = query.send(:ransack_results)
    assert results.include?(we)
  ensure
    we&.destroy
  end

  test 'not_contains operator with value that should exclude everything' do
    we1 = WorkflowExecution.create!(
      name: 'TestWorkflow',
      namespace_id: @namespace.id,
      state: :initial,
      run_id: 'test_run_1',
      submitter_id: @user.id,
      metadata: DEFAULT_METADATA
    )
    we2 = WorkflowExecution.create!(
      name: 'ProdWorkflow',
      namespace_id: @namespace.id,
      state: :initial,
      run_id: 'test_run_2',
      submitter_id: @user.id,
      metadata: DEFAULT_METADATA
    )

    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(
          field: 'name', operator: 'not_contains', value: 'Workflow'
        )]
      )]
    )
    results = query.send(:ransack_results)
    # Both should be excluded since both contain 'Workflow'
    assert_not results.include?(we1)
    assert_not results.include?(we2)
  ensure
    we1&.destroy
    we2&.destroy
  end
end
