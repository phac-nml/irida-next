# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionQueryTest < ActiveSupport::TestCase
  test 'valid query without advanced search' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: '', operator: '', value: '' } }
                      } },
                      name_or_id_cont: 'workflow',
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert_not query.advanced_query?
    assert query.valid?
  end

  test 'valid advanced query with name field' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'name', operator: '=', value: 'test workflow' } }
                      } },
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
  end

  test 'valid advanced query with workflow_name JSONB field' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'workflow_name', operator: '=', value: 'phac-nml/iridanextexample' } }
                      } },
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
  end

  test 'valid advanced query with workflow_version JSONB field' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'workflow_version', operator: '=', value: '1.0.0' } }
                      } },
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
  end

  test 'groups_attributes= parses nested parameters correctly' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes: {
                          '0': { field: 'name', operator: '=', value: 'test' },
                          '1': { field: 'state', operator: '=', value: 'completed' }
                        }
                      } },
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert_equal 1, query.groups.length
    assert_equal 2, query.groups.first.conditions.length
    assert_equal 'name', query.groups.first.conditions.first.field
    assert_equal 'state', query.groups.first.conditions.last.field
  end

  test 'results method returns paginated results' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: '', operator: '', value: '' } }
                      } },
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    pagy, results = query.results(limit: 10, page: 1)
    assert_instance_of Pagy, pagy
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'results method returns non-paginated results' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: '', operator: '', value: '' } }
                      } },
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'in operator with id field' do
    project = projects(:project1)
    we1 = workflow_executions(:irida_next_example)
    we2 = workflow_executions(:irida_next_example_completed)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'id', operator: 'in', value: [we1.id] } }
                      } },
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
    results = query.results
    assert_includes results, we1
    assert_not_includes results, we2
  end

  # WorkflowExecutionSearchGroupValidator tests
  test 'invalid advanced query with blank fields' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes: {
                          '0': { field: 'name', operator: '=', value: 'test' },
                          '1': { field: '', operator: '', value: '' }
                        }
                      } },
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert_not query.valid?
    assert query.errors.added? :groups, :invalid
    assert query.groups[0].errors.added? :conditions, :invalid
    assert query.groups[0].conditions[1].errors.added? :field, :blank
    assert query.groups[0].conditions[1].errors.added? :operator, :blank
    assert query.groups[0].conditions[1].errors.added? :value, :blank
  end

  test 'invalid advanced query with disallowed field' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'invalid_field', operator: '=', value: 'test' } }
                      } },
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert_not query.valid?
    assert query.errors.added? :groups, :invalid
    assert query.groups[0].errors.added? :conditions, :invalid
    assert query.groups[0].conditions[0].errors.added? :field, :not_allowed
  end

  test 'invalid advanced query with invalid date' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'created_at', operator: '=', value: '2024-13-17' } }
                      } },
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert_not query.valid?
    assert query.errors.added? :groups, :invalid
    assert query.groups[0].errors.added? :conditions, :invalid
    assert query.groups[0].conditions[0].errors.added? :value, :not_a_date
  end

  test 'valid advanced query with valid date' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'created_at', operator: '=', value: '2024-12-17' } }
                      } },
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
  end

  test 'invalid advanced query with contains operator on date field' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'created_at', operator: 'contains', value: '2024-12-17' } }
                      } },
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert_not query.valid?
    assert query.errors.added? :groups, :invalid
    assert query.groups[0].errors.added? :conditions, :invalid
    assert query.groups[0].conditions[0].errors.added? :operator, :not_a_date_operator
  end

  test 'invalid advanced query with non-unique fields' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes: {
                          '0': { field: 'name', operator: '=', value: 'test1' },
                          '1': { field: 'name', operator: '!=', value: 'test2' }
                        }
                      } },
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert_not query.valid?
    assert query.errors.added? :groups, :invalid
    assert query.groups[0].errors.added? :conditions, :invalid
    assert query.groups[0].conditions[1].errors.added? :operator, :taken
  end

  test 'valid advanced query with between operators (>= and <=)' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes: {
                          '0': { field: 'id', operator: '>=', value: '1' },
                          '1': { field: 'id', operator: '<=', value: '100' }
                        }
                      } },
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
  end

  test 'invalid advanced query with non-numeric value for >= operator' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'id', operator: '>=', value: 'not_a_number' } }
                      } },
                      namespace_id: project.namespace.id }
    query = WorkflowExecution::Query.new(search_params)
    assert query.advanced_query?
    assert_not query.valid?
    assert query.errors.added? :groups, :invalid
    assert query.groups[0].errors.added? :conditions, :invalid
    assert query.groups[0].conditions[0].errors.added? :value, :not_a_number
  end
end
