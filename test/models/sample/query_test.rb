# frozen_string_literal: true

require 'test_helper'

class QueryTest < ActiveSupport::TestCase
  test 'valid query' do
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: '', operator: '', value: '' } }
                      } },
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
    assert query.errors.added? :groups, :invalid
    assert query.groups[0].errors.added? :conditions, :invalid
    assert query.groups[0].conditions[1].errors.added? :field, :blank
    assert query.groups[0].conditions[1].errors.added? :operator, :blank
    assert query.groups[0].conditions[1].errors.added? :value, :blank
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
    assert query.errors.added? :groups, :invalid
    assert query.groups[0].errors.added? :conditions, :invalid
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
    assert query.errors.added? :groups, :invalid
    assert query.groups[0].errors.added? :conditions, :invalid
    assert query.groups[0].conditions[1].errors.added? :operator, :taken
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
    assert query.errors.added? :groups, :invalid
    assert query.groups[0].errors.added? :conditions, :invalid
    assert query.groups[0].conditions[1].errors.added? :operator, :taken
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
    assert query.errors.added? :groups, :invalid
    assert query.groups[0].errors.added? :conditions, :invalid
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
    assert query.errors.added? :groups, :invalid
    assert query.groups[0].errors.added? :conditions, :invalid
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
end
