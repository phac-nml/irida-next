# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  class FormTest < ActiveSupport::TestCase
    # Test implementation using Sample::Query since it includes the concern
    setup do
      @project = projects(:project1)
    end

    test 'advanced_query? returns false when groups are empty' do
      query = Sample::Query.new(
        project_ids: [@project.id],
        groups: [Sample::SearchGroup.new(conditions: [Sample::SearchCondition.new(field: '', operator: '', value: '')])]
      )
      assert_not query.advanced_query?
    end

    test 'advanced_query? returns true when groups have non-empty conditions' do
      query = Sample::Query.new(
        project_ids: [@project.id],
        groups: [Sample::SearchGroup.new(conditions: [Sample::SearchCondition.new(field: 'name', operator: '=',
                                                                                  value: 'test')])]
      )
      assert query.advanced_query?
    end

    test 'groups_attributes= parses nested attributes into SearchGroup and SearchCondition objects' do
      query = Sample::Query.new(project_ids: [@project.id])
      nested_attributes = {
        '0' => {
          'conditions_attributes' => {
            '0' => { 'field' => 'name', 'operator' => '=', 'value' => 'sample1' },
            '1' => { 'field' => 'puid', 'operator' => 'contains', 'value' => 'test' }
          }
        },
        '1' => {
          'conditions_attributes' => {
            '0' => { 'field' => 'created_at', 'operator' => '>=', 'value' => '2024-01-01' }
          }
        }
      }

      query.groups_attributes = nested_attributes

      assert_equal 2, query.groups.length
      assert_equal 2, query.groups[0].conditions.length
      assert_equal 'name', query.groups[0].conditions[0].field
      assert_equal '=', query.groups[0].conditions[0].operator
      assert_equal 'sample1', query.groups[0].conditions[0].value
      assert_equal 1, query.groups[1].conditions.length
      assert_equal 'created_at', query.groups[1].conditions[0].field
    end

    test 'sort= parses column and direction correctly' do
      query = Sample::Query.new(project_ids: [@project.id], sort: 'name asc')
      assert_equal 'name', query.column
      assert_equal 'asc', query.direction
    end

    test 'sort= converts metadata_ prefix to metadata. dot notation' do
      query = Sample::Query.new(project_ids: [@project.id], sort: 'metadata_custom_field desc')
      assert_equal 'metadata.custom_field', query.column
      assert_equal 'desc', query.direction
    end

    test 'sort= handles space-containing field names using rpartition' do
      query = Sample::Query.new(project_ids: [@project.id], sort: 'metadata_field with spaces asc')
      assert_equal 'metadata.field with spaces', query.column
      assert_equal 'asc', query.direction
    end
  end
end
