# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionAdvancedSearchGroupValidatorTest < ActiveSupport::TestCase
  setup do
    @namespace = groups(:group_one)
  end

  test 'validates valid WorkflowExecution fields' do
    query = create_query_with_condition('name', '=', 'test')
    assert query.valid?

    query = create_query_with_condition('run_id', '=', 'test123')
    assert query.valid?

    query = create_query_with_condition('state', '=', 'completed')
    assert query.valid?
  end

  test 'validates metadata field pattern' do
    query = create_query_with_condition('metadata.workflow_name', '=', 'assembly')
    assert query.valid?

    query = create_query_with_condition('metadata.custom_field', 'contains', 'value')
    assert query.valid?
  end

  test 'rejects invalid field names' do
    query = create_query_with_condition('invalid_field', '=', 'value')
    assert_not query.valid?
    assert query.groups[0].conditions[0].errors[:field].any?
  end

  test 'restricts operators for date fields' do
    # created_at should not allow contains operator
    query = create_query_with_condition('created_at', 'contains', 'value')
    assert_not query.valid?

    # metadata date fields should not allow in operator
    query = create_query_with_condition('metadata.start_date', 'in', ['2024-01-01'])
    assert_not query.valid?

    # should allow = operator for dates
    query = create_query_with_condition('created_at', '=', '2024-01-01')
    assert query.valid?
  end

  test 'validates date format for date fields' do
    query = create_query_with_condition('created_at', '=', 'invalid-date')
    assert_not query.valid?
    assert query.groups[0].conditions[0].errors[:value].any?

    query = create_query_with_condition('created_at', '=', '2024-01-01')
    assert query.valid?
  end

  test 'validates numeric values for comparison operators' do
    query = create_query_with_condition('metadata.sample_count', '>=', 'not-a-number')
    assert_not query.valid?
    assert query.groups[0].conditions[0].errors[:value].any?

    query = create_query_with_condition('metadata.sample_count', '>=', '10')
    assert query.valid?
  end

  test 'allows empty search with single empty group' do
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(field: '', operator: '', value: '')]
      )]
    )
    assert query.valid?
  end

  test 'validates unique conditions per field except for range queries' do
    # Duplicate conditions should fail
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [
          WorkflowExecution::SearchCondition.new(field: 'name', operator: '=', value: 'test1'),
          WorkflowExecution::SearchCondition.new(field: 'name', operator: '=', value: 'test2')
        ]
      )]
    )
    assert_not query.valid?

    # >= and <= pair should be allowed for range queries
    query = WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [
          WorkflowExecution::SearchCondition.new(field: 'created_at', operator: '>=', value: '2024-01-01'),
          WorkflowExecution::SearchCondition.new(field: 'created_at', operator: '<=', value: '2024-12-31')
        ]
      )]
    )
    assert query.valid?
  end

  private

  def create_query_with_condition(field, operator, value)
    WorkflowExecution::Query.new(
      namespace_ids: [@namespace.id],
      groups: [WorkflowExecution::SearchGroup.new(
        conditions: [WorkflowExecution::SearchCondition.new(field:, operator:, value:)]
      )]
    )
  end
end
