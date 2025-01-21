# frozen_string_literal: true

require 'test_helper'

class QueryTest < ActiveSupport::TestCase
  def setup
    search_params = { sort: 'updated_at desc',
                      groups_attributes: { '0': {
                        conditions_attributes:
                       { '0': { field: '', operator: '', value: '' } }
                      } },
                      name_or_puid_cont: 'Project 1 Sample 1',
                      project_ids: ['15438e41-f27c-5010-b021-fe991c68bb04'] }
    @query = Sample::Query.new(search_params)
  end

  test 'valid query' do
    assert_not @query.advanced_query?
    assert @query.valid?
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
    assert query.errors.added? :base, I18n.t('validators.advanced_search_group_validator.group_error')
    assert query.groups[0].errors.added? :base, I18n.t('validators.advanced_search_group_validator.condition_error')
    assert query.groups[0].conditions[1].errors.added? :field,
                                                       I18n.t('validators.advanced_search_group_validator.blank_error')
    assert query.groups[0].conditions[1].errors.added? :operator,
                                                       I18n.t('validators.advanced_search_group_validator.blank_error')
    assert query.groups[0].conditions[1].errors.added? :value,
                                                       I18n.t('validators.advanced_search_group_validator.blank_error')
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
    assert query.errors.added? :base, I18n.t('validators.advanced_search_group_validator.group_error')
    assert query.groups[0].errors.added? :base, I18n.t('validators.advanced_search_group_validator.condition_error')
    assert query.groups[0].conditions[0].errors.added? :value,
                                                       I18n.t('validators.advanced_search_group_validator.date_format_error') # rubocop:disable Layout/LineLength
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
    assert query.errors.added? :base, I18n.t('validators.advanced_search_group_validator.group_error')
    assert query.groups[0].errors.added? :base, I18n.t('validators.advanced_search_group_validator.condition_error')
    assert query.groups[0].conditions[0].errors.added? :field,
                                                       I18n.t('validators.advanced_search_group_validator.uniqueness_error') # rubocop:disable Layout/LineLength
    assert query.groups[0].conditions[1].errors.added? :field,
                                                       I18n.t('validators.advanced_search_group_validator.uniqueness_error') # rubocop:disable Layout/LineLength
  end

  test 'invalid advanced query non unique fields using between operator' do
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
    assert query.errors.added? :base, I18n.t('validators.advanced_search_group_validator.group_error')
    assert query.groups[0].errors.added? :base, I18n.t('validators.advanced_search_group_validator.condition_error')
    assert query.groups[0].conditions[0].errors.added? :field,
                                                       I18n.t('validators.advanced_search_group_validator.between_error') # rubocop:disable Layout/LineLength
    assert query.groups[0].conditions[1].errors.added? :field,
                                                       I18n.t('validators.advanced_search_group_validator.uniqueness_error') # rubocop:disable Layout/LineLength
  end

  test 'valid advanced query non unique fields using between operator' do
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
end
