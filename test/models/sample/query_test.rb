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
end
