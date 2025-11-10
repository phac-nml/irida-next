# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionSearchGroupValidatorTest < ActiveSupport::TestCase
  test 'valid workflow execution query' do
    namespace = groups(:group_one)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: '', operator: '', value: '' } }
                      } },
                      name_or_id_cont: 'test',
                      namespace_id: namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert_not query.advanced_query?
    assert query.valid?
  end

  test 'valid advanced query with allowed workflow execution field' do
    namespace = groups(:group_one)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'name', operator: '=', value: 'Test Workflow' } }
                      } },
                      namespace_id: namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
  end

  test 'valid advanced query with workflow_name JSONB field' do
    namespace = groups(:group_one)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'workflow_name', operator: '=', value: 'phac-nml/iridanextexample' } }
                      } },
                      namespace_id: namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
  end

  test 'valid advanced query with workflow_version JSONB field' do
    namespace = groups(:group_one)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'workflow_version', operator: '=', value: '1.0.0' } }
                      } },
                      namespace_id: namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
  end

  test 'invalid advanced query with contains operator on date field' do
    namespace = groups(:group_one)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes: {
                          '0': { field: 'created_at', operator: 'contains', value: '2024-12-17' }
                        }
                      } },
                      namespace_id: namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert_not query.valid?
    assert query.errors.added? :groups, :invalid
    assert query.groups[0].errors.added? :conditions, :invalid
    assert query.groups[0].conditions[0].errors.added? :operator, :not_a_date_operator
  end

  test 'invalid advanced query with non-numeric value for numeric operator' do
    namespace = groups(:group_one)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes: {
                          '0': { field: 'id', operator: '>=', value: 'not-a-number' }
                        }
                      } },
                      namespace_id: namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert_not query.valid?
    assert query.errors.added? :groups, :invalid
    assert query.groups[0].errors.added? :conditions, :invalid
    assert query.groups[0].conditions[0].errors.added? :value, :not_a_number
  end

  test 'valid advanced query with between operator on same field' do
    namespace = groups(:group_one)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes: {
                          '0': { field: 'created_at', operator: '>=', value: '2024-01-01' },
                          '1': { field: 'created_at', operator: '<=', value: '2024-12-31' }
                        }
                      } },
                      namespace_id: namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
  end

  test 'invalid advanced query with duplicate field conditions' do
    namespace = groups(:group_one)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes: {
                          '0': { field: 'name', operator: '=', value: 'Test 1' },
                          '1': { field: 'name', operator: '!=', value: 'Test 2' }
                        }
                      } },
                      namespace_id: namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert_not query.valid?
    assert query.errors.added? :groups, :invalid
    assert query.groups[0].errors.added? :conditions, :invalid
    assert query.groups[0].conditions[1].errors.added? :operator, :taken
  end
end
