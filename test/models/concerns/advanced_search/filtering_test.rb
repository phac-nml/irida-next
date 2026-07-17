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

    test 'operator starts_with' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: 'starts_with',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, "ILIKE 'string%'"
    end

    test 'operator ends_with' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: 'ends_with',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, "ILIKE '%string'"
    end

    test 'operator text_starts_with' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: 'text_starts_with',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, "ILIKE 'string%'"
    end

    test 'operator text_ends_with' do
      condition = WorkflowExecution::SearchCondition.new(field: 'metadata.test_field', operator: 'text_ends_with',
                                                         value: 'string')
      result = @test_instance.send(:add_condition,
                                   @test_instance.model_class, condition)

      sql = result.to_sql
      assert_includes sql, "ILIKE '%string'"
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
  end
end
