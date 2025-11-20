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

  test 'simple query completes within acceptable time' do
    project = projects(:project1)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: '', operator: '', value: '' } }
                      } },
                      name_or_id_cont: 'workflow',
                      namespace_id: project.namespace.id }

    query = WorkflowExecution::Query.new(search_params)

    start_time = Time.current
    _pagy, _results = query.results(limit: 20, page: 1)
    duration = Time.current - start_time

    assert duration < 2.seconds, "Simple query took #{duration}s, expected < 2s"
  end

  test 'complex multi-group query completes within acceptable time' do
    project = projects(:project1)
    # Build a complex query with multiple groups and conditions
    search_params = { sort: 'updated_at desc',
                      groups_attributes: {
                        '0': {
                          conditions_attributes: {
                            '0': { field: 'state', operator: '=', value: 'completed' },
                            '1': { field: 'workflow_name', operator: 'contains', value: 'example' }
                          }
                        },
                        '1': {
                          conditions_attributes: {
                            '0': { field: 'state', operator: '=', value: 'error' }
                          }
                        },
                        '2': {
                          conditions_attributes: {
                            '0': { field: 'name', operator: 'contains', value: 'test' },
                            '1': { field: 'created_at', operator: '>=', value: 1.month.ago.to_date.to_s }
                          }
                        }
                      },
                      namespace_id: project.namespace.id }

    query = WorkflowExecution::Query.new(search_params)

    start_time = Time.current
    _pagy, _results = query.results(limit: 20, page: 1)
    duration = Time.current - start_time

    assert duration < 3.seconds, "Complex query took #{duration}s, expected < 3s"
  end

  # Workflow name conversion tests
  test 'workflow_name equals operator converts name to pipeline_id' do
    project = projects(:project1)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'workflow_name', operator: '=', value: 'phac-nml/iridanextexample' }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'workflow_name in operator converts multiple names to pipeline_ids' do
    project = projects(:project1)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'workflow_name', operator: 'in',
                   value: ['phac-nml/iridanextexample', 'phac-nml/another'] }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'workflow_name not_equals operator converts name to pipeline_id' do
    project = projects(:project1)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'workflow_name', operator: '!=', value: 'phac-nml/iridanextexample' }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'workflow_name not_in operator converts multiple names to pipeline_ids' do
    project = projects(:project1)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'workflow_name', operator: 'not_in',
                   value: ['phac-nml/iridanextexample'] }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'workflow_name contains operator searches pipeline names' do
    project = projects(:project1)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'workflow_name', operator: 'contains', value: 'example' }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'workflow_name with blank value returns scope unchanged' do
    project = projects(:project1)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'workflow_name', operator: '=', value: '' }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'workflow_name contains with blank value returns scope unchanged' do
    project = projects(:project1)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'workflow_name', operator: 'contains', value: '' }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'workflow_name in operator with empty array returns scope unchanged' do
    project = projects(:project1)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'workflow_name', operator: 'in', value: [] }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Sorting tests
  test 'sort by metadata field' do
    project = projects(:project1)
    search_params = {
      sort: 'metadata_workflow_name asc',
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    assert_equal 'metadata.workflow_name', query.column
    assert_equal 'asc', query.direction
  end

  test 'sort defaults to updated_at desc when blank' do
    project = projects(:project1)
    search_params = {
      sort: '',
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    assert_equal 'updated_at', query.column
    assert_equal 'desc', query.direction
  end

  test 'sort with only direction defaults column to updated_at' do
    project = projects(:project1)
    search_params = {
      sort: 'asc',
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    assert_equal 'updated_at', query.column
    assert_equal 'asc', query.direction
  end

  test 'sort handles metadata fields with spaces' do
    project = projects(:project1)
    search_params = {
      sort: 'metadata_field with spaces desc',
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    assert_equal 'metadata.field with spaces', query.column
    assert_equal 'desc', query.direction
  end

  # Operator tests - exists and not_exists
  test 'exists operator filters for non-null values' do
    project = projects(:project1)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'name', operator: 'exists', value: '' }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert(results.all? { |we| we.name.present? })
  end

  test 'not_exists operator filters for null values' do
    project = projects(:project1)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'tags', operator: 'not_exists', value: '' }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # Text matching tests
  test 'name field uses text matching for equals' do
    project = projects(:project1)
    we = workflow_executions(:irida_next_example)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'name', operator: '=', value: we.name }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we
  end

  test 'name field equals is case-insensitive' do
    project = projects(:project1)
    we = workflow_executions(:irida_next_example)
    mixed_case = we.name.swapcase
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'name', operator: '=', value: mixed_case }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we
  end

  test 'name field uses text matching for in operator' do
    project = projects(:project1)
    we1 = workflow_executions(:irida_next_example)
    we2 = workflow_executions(:irida_next_example_completed)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'name', operator: 'in', value: [we1.name, we2.name] }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we1
    assert_includes results, we2
  end

  test 'name field IN is case-insensitive' do
    project = projects(:project1)
    we1 = workflow_executions(:irida_next_example)
    we2 = workflow_executions(:irida_next_example_completed)
    values = [we1.name.upcase, we2.name.downcase]
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'name', operator: 'in', value: values }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we1
    assert_includes results, we2
  end

  test 'name field uses text matching for not_equals' do
    project = projects(:project1)
    we = workflow_executions(:irida_next_example)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'name', operator: '!=', value: we.name }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_not_includes results, we
  end

  test 'name field NOT EQUALS is case-insensitive' do
    project = projects(:project1)
    we = workflow_executions(:irida_next_example)
    value = we.name.swapcase
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'name', operator: '!=', value: value }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_not_includes results, we
  end

  test 'name field uses text matching for not_in operator' do
    project = projects(:project1)
    we = workflow_executions(:irida_next_example)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'name', operator: 'not_in', value: [we.name] }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_not_includes results, we
  end

  test 'name field NOT IN is case-insensitive' do
    project = projects(:project1)
    we = workflow_executions(:irida_next_example)
    values = [we.name.upcase]
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'name', operator: 'not_in', value: values }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_not_includes results, we
  end

  test 'name field CONTAINS is case-insensitive' do
    project = projects(:project1)
    we = workflow_executions(:irida_next_example)
    fragment = we.name[0..3].swapcase
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'name', operator: 'contains', value: fragment }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we
  end

  test 'advanced query results are ANDed with base scope' do
    # Build a base scope limited to projectA namespace
    project_a_ns = Namespace.find(ActiveRecord::FixtureSet.identify(:projectA_namespace, :uuid))
    base_scope = WorkflowExecution.where(namespace_id: project_a_ns.id)

    # Groups would normally match completed or error across all namespaces
    search_params = {
      sort: 'workflow_executions.id asc',
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'state', operator: '=', value: 'completed' }
          }
        },
        '1': {
          conditions_attributes: {
            '0': { field: 'state', operator: '=', value: 'error' }
          }
        }
      }
    }
    query = WorkflowExecution::Query.new(search_params.merge(base_scope:))
    results = query.results
    # Ensure all results are within the base scope namespace
    assert results.pluck(:namespace_id).uniq == [project_a_ns.id]
  end

  # UUID field contains test
  test 'id field with contains operator casts to text' do
    project = projects(:project1)
    we = workflow_executions(:irida_next_example)
    id_fragment = we.id[0..7]
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'id', operator: 'contains', value: id_fragment }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    assert_includes results, we
  end

  # Multiple groups OR logic test
  test 'multiple groups are combined with OR logic' do
    project = projects(:project1)
    we1 = workflow_executions(:irida_next_example)
    we2 = workflow_executions(:irida_next_example_completed)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'state', operator: '=', value: we1.state }
          }
        },
        '1': {
          conditions_attributes: {
            '0': { field: 'state', operator: '=', value: we2.state }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    results = query.results
    # Should include workflow executions with either state
    assert results.count >= 2
  end

  # Base scope test
  test 'accepts custom base_scope parameter' do
    projects(:project1)
    we = workflow_executions(:irida_next_example)
    custom_scope = WorkflowExecution.where(id: we.id)
    query = WorkflowExecution::Query.new(base_scope: custom_scope)
    results = query.results
    assert_equal 1, results.count
    assert_includes results, we
  end

  # Invalid query returns none
  test 'invalid query returns empty relation' do
    project = projects(:project1)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'invalid_field', operator: '=', value: 'test' }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    assert_not query.valid?
    results = query.results
    assert_equal 0, results.count
  end

  # Empty condition field handling
  test 'empty field in condition is skipped' do
    project = projects(:project1)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: '', operator: '=', value: 'test' }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    # Should not raise error, just skip the condition
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  # JSONB numeric comparison tests
  test 'workflow_version field with >= operator' do
    project = projects(:project1)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'workflow_version', operator: '>=', value: '1.0' }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    assert query.valid?
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end

  test 'workflow_version field with <= operator' do
    project = projects(:project1)
    search_params = {
      groups_attributes: {
        '0': {
          conditions_attributes: {
            '0': { field: 'workflow_version', operator: '<=', value: '2.0' }
          }
        }
      },
      namespace_id: project.namespace.id
    }
    query = WorkflowExecution::Query.new(search_params)
    assert query.valid?
    results = query.results
    assert results.is_a?(ActiveRecord::Relation)
  end
end
