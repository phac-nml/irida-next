# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  module Operators
    class ComparisonOperatorsTest < ActiveSupport::TestCase
      # Test class that includes the ComparisonOperators module
      class TestClass
        include AdvancedSearch::Operators::ComparisonOperators

        # Make private methods accessible for testing
        public :condition_less_than_or_equal, :condition_greater_than_or_equal,
               :condition_date_comparison, :condition_numeric_comparison
      end

      def setup
        @test_instance = TestClass.new
        @scope = WorkflowExecution.all
        @node = WorkflowExecution.arel_table[:name]
        @created_at_node = WorkflowExecution.arel_table[:created_at]
      end

      # condition_less_than_or_equal tests
      test 'condition_less_than_or_equal uses lteq for regular fields' do
        result = @test_instance.condition_less_than_or_equal(
          @scope, @created_at_node, '2024-01-01',
          metadata_field: false, metadata_key: nil
        )
        sql = result.to_sql
        assert_includes sql, '<='
        assert_not_includes sql, 'TO_DATE'
        assert_not_includes sql, 'CAST'
      end

      test 'condition_less_than_or_equal uses date comparison for date metadata fields' do
        result = @test_instance.condition_less_than_or_equal(
          @scope, @node, '2024-01-01',
          metadata_field: true, metadata_key: 'created_date'
        )
        sql = result.to_sql
        assert_includes sql, 'TO_DATE'
        assert_includes sql, '<='
        assert_includes sql, '~'
      end

      test 'condition_less_than_or_equal uses numeric comparison for numeric metadata fields' do
        result = @test_instance.condition_less_than_or_equal(
          @scope, @node, '100',
          metadata_field: true, metadata_key: 'count'
        )
        sql = result.to_sql
        assert_includes sql, 'CAST'
        assert_includes sql, 'DOUBLE PRECISION'
        assert_includes sql, '<='
      end

      # condition_greater_than_or_equal tests
      test 'condition_greater_than_or_equal uses gteq for regular fields' do
        result = @test_instance.condition_greater_than_or_equal(
          @scope, @created_at_node, '2024-01-01',
          metadata_field: false, metadata_key: nil
        )
        sql = result.to_sql
        assert_includes sql, '>='
        assert_not_includes sql, 'TO_DATE'
        assert_not_includes sql, 'CAST'
      end

      test 'condition_greater_than_or_equal uses date comparison for date metadata fields' do
        result = @test_instance.condition_greater_than_or_equal(
          @scope, @node, '2024-01-01',
          metadata_field: true, metadata_key: 'updated_date'
        )
        sql = result.to_sql
        assert_includes sql, 'TO_DATE'
        assert_includes sql, '>='
        assert_includes sql, '~'
      end

      test 'condition_greater_than_or_equal uses numeric comparison for numeric metadata fields' do
        result = @test_instance.condition_greater_than_or_equal(
          @scope, @node, '50',
          metadata_field: true, metadata_key: 'score'
        )
        sql = result.to_sql
        assert_includes sql, 'CAST'
        assert_includes sql, 'DOUBLE PRECISION'
        assert_includes sql, '>='
      end

      # condition_date_comparison tests
      test 'condition_date_comparison includes date regex validation' do
        result = @test_instance.condition_date_comparison(@scope, @node, '2024-01-01', :lteq)
        sql = result.to_sql
        # Regex matches YYYY, YYYY-MM, or YYYY-MM-DD formats
        assert_includes sql, '~'
        assert_includes sql, 'TO_DATE'
        assert_includes sql, 'YYYY-MM-DD'
      end

      test 'condition_date_comparison returns none for invalid date format' do
        result = @test_instance.condition_date_comparison(@scope, @node, '2024-99-40', :lteq)
        assert result.none?
      end

      test 'condition_date_comparison works with gteq' do
        result = @test_instance.condition_date_comparison(@scope, @node, '2024-06-15', :gteq)
        sql = result.to_sql
        assert_includes sql, '>='
        assert_includes sql, 'TO_DATE'
      end

      # condition_numeric_comparison tests
      test 'condition_numeric_comparison includes numeric regex validation' do
        result = @test_instance.condition_numeric_comparison(@scope, @node, '123', :lteq)
        sql = result.to_sql
        # Regex matches integers and decimals (including negatives)
        assert_includes sql, '~'
        assert_includes sql, 'CAST'
      end

      test 'condition_numeric_comparison returns none for invalid numeric format' do
        result = @test_instance.condition_numeric_comparison(@scope, @node, '12a3', :lteq)
        assert result.none?
      end

      test 'condition_numeric_comparison works with gteq' do
        result = @test_instance.condition_numeric_comparison(@scope, @node, '456.78', :gteq)
        sql = result.to_sql
        assert_includes sql, '>='
        assert_includes sql, 'CAST'
        assert_includes sql, 'DOUBLE PRECISION'
      end
    end
  end
end
