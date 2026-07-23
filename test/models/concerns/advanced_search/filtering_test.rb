# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  class FilteringTest < ActiveSupport::TestCase
    class TestClass
      include AdvancedSearch::Filtering

      include AdvancedSearch::Operators::EqualityOperators
      include AdvancedSearch::Operators::SetOperators
      include AdvancedSearch::Operators::ComparisonOperators
      include AdvancedSearch::Operators::PatternOperators
      include AdvancedSearch::Operators::ExistenceOperators
      include AdvancedSearch::Operators::BetweenOperators
      include AdvancedSearch::MetadataComparison
      include AdvancedSearch::Operators

      extend ActiveSupport::Concern

      def model_class
        WorkflowExecution
      end

      def enum_metadata_field?(field_name)
        WorkflowExecution::FieldConfiguration::ENUM_METADATA_FIELDS.include?(field_name)
      end
    end

    def setup
      @test_instance = TestClass.new
      @scope = WorkflowExecution.all
    end

    # comparison operators
    test 'operator <=' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: '<=', value: '20')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      assert_includes result.to_sql, '<='
    end

    test 'operator >=' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: '>=', value: '20')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      assert_includes result.to_sql, '>='
    end

    test 'operator numeric_less_than_equals' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field',
                                                         operator: 'numeric_less_than_equals', value: '20.1')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, "CAST(\"workflow_executions\".\"metadata\" ->> 'test_field' AS DOUBLE PRECISION) <= 20.1"
    end

    test 'operator numeric_greater_than_equals' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field',
                                                         operator: 'numeric_greater_than_equals', value: '20.0')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, "CAST(\"workflow_executions\".\"metadata\" ->> 'test_field' AS DOUBLE PRECISION) >= 20.0"
    end

    test 'operator date_less_than_equals' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field',
                                                         operator: 'date_less_than_equals', value: '2026-01-01')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, 'TO_DATE'
      assert_includes sql, '<='
      assert_includes sql, '~'
    end

    test 'operator date_greater_than_equals' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field',
                                                         operator: 'date_greater_than_equals', value: '2026-01-01')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, 'TO_DATE'
      assert_includes sql, '>='
      assert_includes sql, '~'
    end

    # equality operators

    test 'operator =' do
      condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: '=',
                                                         value: 'completed')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, '"workflow_executions"."state" = '
      assert_not_includes sql, 'ILIKE'
    end

    test 'operator !=' do
      condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: '!=',
                                                         value: 'completed')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, '"workflow_executions"."state" != '
      assert_not_includes sql, 'NOT ILIKE'
    end

    test 'operator numeric_equals' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: 'numeric_equals',
                                                         value: '20')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, "CAST(\"workflow_executions\".\"metadata\" ->> 'test_field' AS DOUBLE PRECISION) = 20.0"
    end

    test 'operator numeric_not_equals' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: 'numeric_not_equals',
                                                         value: '20')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, "CAST(\"workflow_executions\".\"metadata\" ->> 'test_field' AS DOUBLE PRECISION) != 20.0"
    end

    test 'operator date_equals' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: 'date_equals',
                                                         value: '2026-01-01')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, 'ILIKE'
    end

    test 'operator date_not_equals' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: 'date_not_equals',
                                                         value: '2026-01-01')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, 'NOT ILIKE'
      assert_includes sql, 'IS NULL'
    end

    test 'operator text_equals' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: 'text_equals',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, 'ILIKE'
    end

    test 'operator text_not_equals' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: 'text_not_equals',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, 'NOT ILIKE'
      assert_includes sql, 'IS NULL'
    end

    # pattern operators
    test 'operator contains' do
      condition = WorkflowExecution::SearchCondition.new(field: 'name', operator: 'contains',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, "ILIKE '%string%'"
    end

    test 'operator not_contains' do
      condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: 'not_contains',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, 'NOT ILIKE'
      assert_includes sql, 'IS NULL'
    end

    test 'operator text_contains' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: 'text_contains',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, "ILIKE '%string%'"
    end

    test 'operator text_not_contains' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: 'text_not_contains',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, 'NOT ILIKE'
      assert_includes sql, 'IS NULL'
    end

    # set operators
    test 'operator in' do
      condition = WorkflowExecution::SearchCondition.new(field: 'name', operator: 'in',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, 'LOWER'
      assert_includes sql, 'IN'
    end

    test 'operator not_in' do
      condition = WorkflowExecution::SearchCondition.new(field: 'name', operator: 'not_in',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, 'LOWER'
      assert_includes sql, 'NOT IN'
    end

    test 'operator text_in' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: 'text_in',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, 'LOWER'
      assert_includes sql, 'IN'
    end

    test 'operator text_not_in' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: 'text_not_in',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, 'LOWER'
      assert_includes sql, 'NOT IN'
    end

    # existence operators

    test 'operator exists' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: 'exists',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, 'IS NOT NULL'
    end

    test 'operator not_exists' do
      condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: 'not_exists',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, 'IS NULL'
    end

    test 'operator between' do
      condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: 'between',
                                                         value: %w[a z])
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, "LOWER(\"workflow_executions\".\"state\") BETWEEN 'a' AND 'z'"
    end

    test 'operator date_between' do
      condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: 'date_between',
                                                         value: %w[2026-01-01 2026-12-31])
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, "AND TO_DATE(\"workflow_executions\".\"state\", 'YYYY-MM-DD') BETWEEN '2026-01-01' AND '2026-12-31'" # rubocop:disable Layout/LineLength
    end

    test 'operator numeric_between' do
      condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: 'numeric_between',
                                                         value: ['0', '99.9'])
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, 'AND CAST("workflow_executions"."state" AS DOUBLE PRECISION) BETWEEN 0.0 AND 99.9'
    end

    test 'operator text_between' do
      condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: 'text_between',
                                                         value: %w[ABC XYZ])
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, "LOWER(\"workflow_executions\".\"state\") BETWEEN 'abc' AND 'xyz'"
    end
  end
end
