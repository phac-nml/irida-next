# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  module Operators
    class MetadataComparisonTest < ActiveSupport::TestCase
      class TestClass
        include AdvancedSearch::Operators::MetadataComparison
        include AdvancedSearch::Operators::SetOperators
      end

      def setup
        @test_instance = TestClass.new
        @scope = WorkflowExecution.all
        @node = WorkflowExecution.arel_table[:name]
      end

      # condition_date_comparison tests
      test 'condition_date_comparison includes date regex validation' do
        result = @test_instance.send(:metadata_condition_date_comparison, @scope, @node, '2024-01-01', :lteq)
        sql = result.to_sql
        # Regex matches YYYY, YYYY-MM, or YYYY-MM-DD formats
        assert_includes sql, '~'
        assert_includes sql, 'TO_DATE'
        assert_includes sql, 'YYYY-MM-DD'
      end

      test 'condition_date_comparison returns none for invalid date format' do
        result = @test_instance.send(:metadata_condition_date_comparison, @scope, @node, '2024-99-40', :lteq)
        assert result.none?
      end

      test 'condition_date_comparison works with gteq' do
        result = @test_instance.send(:metadata_condition_date_comparison, @scope, @node, '2024-06-15', :gteq)
        sql = result.to_sql
        assert_includes sql, '>='
        assert_includes sql, 'TO_DATE'
      end

      # condition_numeric_comparison tests
      test 'condition_numeric_comparison includes numeric regex validation' do
        result = @test_instance.send(:metadata_condition_numeric_comparison, @scope, @node, '123', :lteq)
        sql = result.to_sql
        # Regex matches integers and decimals (including negatives)
        assert_includes sql, '~'
        assert_includes sql, 'CAST'
      end

      test 'condition_numeric_comparison returns none for invalid numeric format' do
        result = @test_instance.send(:metadata_condition_numeric_comparison, @scope, @node, '12a3', :lteq)
        assert result.none?
      end

      test 'condition_numeric_comparison works with gteq' do
        result = @test_instance.send(:metadata_condition_numeric_comparison, @scope, @node, '456.78', :gteq)
        sql = result.to_sql
        assert_includes sql, '>='
        assert_includes sql, 'CAST'
        assert_includes sql, 'DOUBLE PRECISION'
      end

      test 'condition_in_metadata' do
        result = @test_instance.send(:condition_in_metadata,
                                     @scope, @node, %w[Test Value])
        sql = result.to_sql
        assert_includes sql, 'LOWER'
        assert_includes sql, 'IN'
      end

      test 'condition_not_in_metadata' do
        result = @test_instance.send(:condition_not_in_metadata,
                                     @scope, @node, %w[Test Value])
        sql = result.to_sql
        assert_includes sql, 'LOWER'
        assert_includes sql, 'NOT IN'
        assert_includes sql, 'IS NULL'
      end
    end
  end
end
