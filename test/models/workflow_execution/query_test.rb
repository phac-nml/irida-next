# frozen_string_literal: true

require 'test_helper'

module WorkflowExecution
  class QueryTest < ActiveSupport::TestCase
    setup do
      @namespace = groups(:group_one)
      @workflow_execution1 = workflow_executions(:workflow_execution_valid)
      @workflow_execution2 = workflow_executions(:irida_next_example_completed)
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
  end
end
