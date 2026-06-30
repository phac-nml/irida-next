# frozen_string_literal: true

require 'test_helper'

class QueryTest < ActiveSupport::TestCase
  test 'valid query' do
    search_params = { sort: 'updated_at desc',
                      groups_attributes: {},
                      name_or_puid_cont: 'Project 1 Sample 1',
                      project_ids: ['15438e41-f27c-5010-b021-fe991c68bb04'] }
    query = Sample::Query.new(search_params)
    assert_not query.advanced_query?
    assert query.valid?
  end

  test 'valid advanced query' do
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'name', operator: '=', value: 'Project 1 Sample 1' } }
                      } },
                      project_ids: ['15438e41-f27c-5010-b021-fe991c68bb04'] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
  end

  test 'invalid advanced query with blanks' do
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes: {
                          '0': { field: 'name', operator: '=', value: 'Project 1 Sample 1' },
                          '1': { field: '', operator: '', value: '' }
                        }
                      } },
                      project_ids: ['15438e41-f27c-5010-b021-fe991c68bb04'] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert_not query.valid?
    assert query.errors.added? :base, :invalid
    assert query.groups[0].errors.added? :base, :invalid
    assert query.groups[0].conditions[1].errors.added? :field, :blank
  end

  test 'invalid advanced query with invalid date' do
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'created_at', operator: '=', value: '2024-13-17' } }
                      } },
                      project_ids: ['15438e41-f27c-5010-b021-fe991c68bb04'] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert_not query.valid?
    assert query.errors.added? :base, :invalid
    assert query.groups[0].errors.added? :base, :invalid
    assert query.groups[0].conditions[0].errors.added? :value, :not_a_date
  end

  test 'valid advanced query with date' do
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'created_at', operator: '=', value: '2024-12-17' } }
                      } },
                      project_ids: ['15438e41-f27c-5010-b021-fe991c68bb04'] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
  end

  test 'valid advanced query with date exists and not_exists operators' do
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       {
                         '0': { field: 'created_at', operator: 'exists' },
                         '1': { field: 'attachments_updated_at', operator: 'not_exists' }
                       }
                      } },
                      project_ids: ['15438e41-f27c-5010-b021-fe991c68bb04'] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
  end

  test 'invalid advanced query with non unique fields' do
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes: {
                          '0': { field: 'name', operator: '=', value: 'Project 1 Sample 1' },
                          '1': { field: 'name', operator: '!=', value: 'Project 1 Sample 2' }
                        }
                      } },
                      project_ids: ['15438e41-f27c-5010-b021-fe991c68bb04'] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert_not query.valid?
    assert query.errors.added? :base, :invalid
    assert query.groups[0].errors.added? :base, :invalid
    assert query.groups[0].conditions[1].errors.added? :field, :taken
  end

  test 'invalid advanced query with non unique fields using between operator' do
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes: {
                          '0': { field: 'metadata.age', operator: '>=', value: '50' },
                          '1': { field: 'metadata.age', operator: '=', value: '100' }
                        }
                      } },
                      project_ids: ['15438e41-f27c-5010-b021-fe991c68bb04'] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert_not query.valid?
    assert query.errors.added? :base, :invalid
    assert query.groups[0].errors.added? :base, :invalid
    assert query.groups[0].conditions[1].errors.added? :field, :taken
  end

  test 'valid advanced query with non unique fields using between operator' do
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes: {
                          '0': { field: 'metadata.age', operator: '>=', value: '50' },
                          '1': { field: 'metadata.age', operator: '<=', value: '100' }
                        }
                      } },
                      project_ids: ['15438e41-f27c-5010-b021-fe991c68bb04'] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
  end

  test 'invalid advanced query with non numeric using between operator' do
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes: {
                          '0': { field: 'metadata.age', operator: '>=', value: 'test' }
                        }
                      } },
                      project_ids: ['15438e41-f27c-5010-b021-fe991c68bb04'] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert_not query.valid?
    assert query.errors.added? :base, :invalid
    assert query.groups[0].errors.added? :base, :invalid
    assert query.groups[0].conditions[0].errors.added? :value, :not_a_number
  end

  test 'invalid advanced query using invalid operator on date' do
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes: {
                          '0': { field: 'created_at', operator: 'contains', value: '2024-12-17' }
                        }
                      } },
                      project_ids: ['15438e41-f27c-5010-b021-fe991c68bb04'] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert_not query.valid?
    assert query.errors.added? :base, :invalid
    assert query.groups[0].errors.added? :base, :invalid
    assert query.groups[0].conditions[0].errors.added? :operator, :not_a_date_operator
  end

  test 'in operator with puid field' do
    project = projects(:project1)
    sample1 = samples(:sample1)
    sample2 = samples(:sample2)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'puid', operator: 'in', value: [sample1.puid] } }
                      } },
                      project_ids: [project.id] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
    results = query.results
    assert_includes results, sample1
    assert_not_includes results, sample2
  end

  test 'not_in operator with puid field' do
    project = projects(:project1)
    sample1 = samples(:sample1)
    sample2 = samples(:sample2)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'puid', operator: 'not_in', value: [sample1.puid] } }
                      } },
                      project_ids: [project.id] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
    results = query.results
    assert_not_includes results, sample1
    assert_includes results, sample2
  end

  test 'applies a default sort of updated_at desc' do
    search_params = { sort: 'updated_at desc',
                      project_ids: ['15438e41-f27c-5010-b021-fe991c68bb04'] }
    query = Sample::Query.new(search_params)
    assert query.valid?
    assert_equal 'updated_at desc', query.sort
  end

  test 'applies a tie breaker sort on id by same direction of provided sort if not sorting on id column' do
    search_params = { sort: 'updated_at desc',
                      project_ids: ['15438e41-f27c-5010-b021-fe991c68bb04'] }
    query = Sample::Query.new(search_params)
    assert query.valid?
    assert_equal 'updated_at desc', query.sort

    order_values = query.results.order_values

    assert_equal 2, order_values.length

    tie_breaker_sort = order_values.last
    assert_equal 'id', tie_breaker_sort.expr.name
    assert_equal :desc, tie_breaker_sort.direction
  end

  test 'not_contains operator with name field' do
    project = projects(:project1)
    sample1 = samples(:sample1)
    sample2 = samples(:sample2)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'name', operator: 'not_contains', value: 'Sample 1' } }
                      } },
                      project_ids: [project.id] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
    results = query.results
    assert_not_includes results, sample1
    assert_includes results, sample2
  end

  test 'not_contains operator with puid field' do
    project = projects(:project1)
    sample1 = samples(:sample1)
    samples(:sample2)
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'puid', operator: 'not_contains', value: sample1.puid[0..5] } }
                      } },
                      project_ids: [project.id] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
    results = query.results
    assert_not_includes results, sample1
  end

  test 'not_contains operator with metadata field' do
    project = projects(:project1)
    sample = samples(:sample1)
    sample.update(metadata: { 'custom_field' => 'test_value' })

    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'metadata.custom_field', operator: 'not_contains', value: 'test' } }
                      } },
                      project_ids: [project.id] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
    results = query.results
    assert_not_includes results, sample
  end

  test 'not_contains operator with nil metadata field should include record' do
    project = projects(:project1)
    sample_with_field = samples(:sample1)
    sample_without_field = samples(:sample2)

    sample_with_field.update(metadata: { 'custom_field' => 'contains_value' })
    sample_without_field.update(metadata: {})

    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'metadata.custom_field', operator: 'not_contains', value: 'value' } }
                      } },
                      project_ids: [project.id] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
    results = query.results
    # Should exclude record with the value
    assert_not_includes results, sample_with_field
    # Should include record without the field (nil metadata field)
    assert_includes results, sample_without_field
  end

  test 'not_contains operator with SQL wildcard characters should be escaped' do
    project = projects(:project1)
    sample = samples(:sample1)
    sample.update(name: 'Test%Sample')

    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: 'name', operator: 'not_contains', value: '%' } }
                      } },
                      project_ids: [project.id] }
    query = Sample::Query.new(search_params)
    assert query.advanced_query?
    assert query.valid?
    results = query.results
    # Should exclude sample with % in name
    assert_not_includes results, sample
  end

  test 'metadata numeric operators with comparing integers and floats' do
    project = projects(:project1)
    sample1 = samples(:sample1)
    sample2 = samples(:sample2)
    sample1.update(metadata: { 'float_field' => '10.0', 'int_field' => '10' })
    sample2.update(metadata: { 'float_field' => '100.0', 'int_field' => '100' })

    search_params1 = { sort: 'updated_at desc',
                       groups_attributes: { '0': {
                         conditions_attributes:
                       { '0': { field: 'metadata.float_field', operator: 'numeric_greater_than_equals', value: '12' } }
                       } },
                       project_ids: [project.id] }
    query1 = Sample::Query.new(search_params1)
    assert query1.advanced_query?
    assert query1.valid?
    results1 = query1.results

    assert_not_includes results1, sample1
    assert_includes results1, sample2

    search_params2 = { sort: 'updated_at desc',
                       groups_attributes: { '0': {
                         conditions_attributes:
                       { '0': { field: 'metadata.int_field', operator: 'numeric_less_than_equals', value: '101.00' } }
                       } },
                       project_ids: [project.id] }
    query2 = Sample::Query.new(search_params2)
    assert query2.advanced_query?
    assert query2.valid?
    results2 = query2.results

    assert_includes results2, sample1
    assert_includes results2, sample2

    search_params3 = { sort: 'updated_at desc',
                       groups_attributes: { '0': {
                         conditions_attributes:
                      { '0': { field: 'metadata.int_field', operator: 'numeric_equals', value: '100.00' } }
                       } },
                       project_ids: [project.id] }
    query3 = Sample::Query.new(search_params3)
    assert query3.advanced_query?
    assert query3.valid?
    results3 = query3.results

    assert_not_includes results3, sample1
    assert_includes results3, sample2

    search_params4 = { sort: 'updated_at desc',
                       groups_attributes: { '0': {
                         conditions_attributes:
                      { '0': { field: 'metadata.float_field', operator: 'numeric_not_equals', value: '10' } }
                       } },
                       project_ids: [project.id] }
    query4 = Sample::Query.new(search_params4)
    assert query4.advanced_query?
    assert query4.valid?
    results4 = query4.results

    assert_not_includes results4, sample1
    assert_includes results4, sample2
  end

  test 'metadata date operators' do
    project = projects(:project1)
    sample1 = samples(:sample1)
    sample2 = samples(:sample2)
    sample1.update(metadata: { 'date_field' => '2026-01-01' })
    sample2.update(metadata: { 'date_field' => '2026-12-31' })

    search_params1 = { sort: 'updated_at desc',
                       groups_attributes: { '0': {
                         conditions_attributes:
                       { '0': { field: 'metadata.date_field', operator: 'date_greater_than_equals',
                                value: '2025-12-31' } }
                       } },
                       project_ids: [project.id] }
    query1 = Sample::Query.new(search_params1)
    assert query1.advanced_query?
    assert query1.valid?
    results1 = query1.results

    assert_includes results1, sample1
    assert_includes results1, sample2

    search_params2 = { sort: 'updated_at desc',
                       groups_attributes: { '0': {
                         conditions_attributes:
                       { '0': { field: 'metadata.date_field', operator: 'date_less_than_equals', value: '2026-01-01' } }
                       } },
                       project_ids: [project.id] }
    query2 = Sample::Query.new(search_params2)
    assert query2.advanced_query?
    assert query2.valid?
    results2 = query2.results

    assert_includes results2, sample1
    assert_not_includes results2, sample2

    search_params3 = { sort: 'updated_at desc',
                       groups_attributes: { '0': {
                         conditions_attributes:
                      { '0': { field: 'metadata.date_field', operator: 'date_equals', value: '2026-01-01' } }
                       } },
                       project_ids: [project.id] }
    query3 = Sample::Query.new(search_params3)
    assert query3.advanced_query?
    assert query3.valid?
    results3 = query3.results

    assert_includes results3, sample1
    assert_not_includes results3, sample2

    search_params4 = { sort: 'updated_at desc',
                       groups_attributes: { '0': {
                         conditions_attributes:
                      { '0': { field: 'metadata.date_field', operator: 'date_not_equals', value: '2026-01-01' } }
                       } },
                       project_ids: [project.id] }
    query4 = Sample::Query.new(search_params4)
    assert query4.advanced_query?
    assert query4.valid?
    results4 = query4.results

    assert_not_includes results4, sample1
    assert_includes results4, sample2
  end

  test 'metadata text operators' do
    project = projects(:project1)
    sample1 = samples(:sample1)
    sample2 = samples(:sample2)
    sample1.update(metadata: { 'text_field' => 'abc' })
    sample2.update(metadata: { 'text_field' => 'xyz' })

    search_params1 = { sort: 'updated_at desc',
                       groups_attributes: { '0': {
                         conditions_attributes:
                       { '0': { field: 'metadata.text_field', operator: 'text_in', value: %w[abc xyz] } }
                       } },
                       project_ids: [project.id] }
    query1 = Sample::Query.new(search_params1)
    assert query1.advanced_query?
    assert query1.valid?
    results1 = query1.results

    assert_includes results1, sample1
    assert_includes results1, sample2

    search_params2 = { sort: 'updated_at desc',
                       groups_attributes: { '0': {
                         conditions_attributes:
                       { '0': { field: 'metadata.text_field', operator: 'text_not_in', value: ['xyz'] } }
                       } },
                       project_ids: [project.id] }
    query2 = Sample::Query.new(search_params2)
    assert query2.advanced_query?
    assert query2.valid?
    results2 = query2.results

    assert_includes results2, sample1
    assert_not_includes results2, sample2

    search_params3 = { sort: 'updated_at desc',
                       groups_attributes: { '0': {
                         conditions_attributes:
                      { '0': { field: 'metadata.text_field', operator: 'text_contains', value: 'a' } }
                       } },
                       project_ids: [project.id] }
    query3 = Sample::Query.new(search_params3)
    assert query3.advanced_query?
    assert query3.valid?
    results3 = query3.results

    assert_includes results3, sample1
    assert_not_includes results3, sample2

    search_params4 = { sort: 'updated_at desc',
                       groups_attributes: { '0': {
                         conditions_attributes:
                      { '0': { field: 'metadata.text_field', operator: 'text_not_contains', value: 'z' } }
                       } },
                       project_ids: [project.id] }
    query4 = Sample::Query.new(search_params4)
    assert query4.advanced_query?
    assert query4.valid?
    results4 = query4.results

    assert_includes results4, sample1
    assert_not_includes results4, sample2

    search_params5 = { sort: 'updated_at desc',
                       groups_attributes: { '0': {
                         conditions_attributes:
                      { '0': { field: 'metadata.text_field', operator: 'text_equals', value: 'xyz' } }
                       } },
                       project_ids: [project.id] }
    query5 = Sample::Query.new(search_params5)
    assert query5.advanced_query?
    assert query5.valid?
    results5 = query5.results

    assert_not_includes results5, sample1
    assert_includes results5, sample2

    search_params6 = { sort: 'updated_at desc',
                       groups_attributes: { '0': {
                         conditions_attributes:
                      { '0': { field: 'metadata.text_field', operator: 'text_not_equals', value: 'xyz' } }
                       } },
                       project_ids: [project.id] }
    query6 = Sample::Query.new(search_params6)
    assert query6.advanced_query?
    assert query6.valid?
    results6 = query6.results

    assert_includes results6, sample1
    assert_not_includes results6, sample2
  end
end
