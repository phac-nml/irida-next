# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  module Operators
    class ComparisonOperatorsTest < ActiveSupport::TestCase
      # Test class that includes the ComparisonOperators module
      class TestClass
        include AdvancedSearch::Operators::ComparisonOperators
        include AdvancedSearch::MetadataComparison
      end

      def setup
        @test_instance = TestClass.new
        @scope = WorkflowExecution.all
        @node = WorkflowExecution.arel_table[:name]
        @created_at_node = WorkflowExecution.arel_table[:created_at]
      end

      # condition_less_than_or_equal tests
      test 'condition_less_than_or_equal uses lteq for regular fields' do
        result = @test_instance.send(:condition_less_than_or_equal,
                                     @scope, @created_at_node, '2024-01-01', nil)
        sql = result.to_sql
        assert_includes sql, '<='
        assert_not_includes sql, 'TO_DATE'
        assert_not_includes sql, 'CAST'
      end

      test 'condition_less_than_or_equal uses lteq for regular fields with FF and metadata_field is false' do
        result = @test_instance.send(:condition_less_than_or_equal,
                                     @scope, @created_at_node, '2024-01-01', nil)
        sql = result.to_sql
        assert_includes sql, '<='
        assert_not_includes sql, 'TO_DATE'
        assert_not_includes sql, 'CAST'
      end

      test 'condition_less_than_or_equal uses date comparison for date metadata fields' do
        result = @test_instance.send(:condition_less_than_or_equal,
                                     @scope, @node, '2024-01-01', 'created_date')
        sql = result.to_sql
        assert_includes sql, 'TO_DATE'
        assert_includes sql, '<='
        assert_includes sql, '~'
      end
      test 'condition_less_than_or_equal uses numeric comparison for numeric metadata fields' do
        result = @test_instance.send(:condition_less_than_or_equal,
                                     @scope, @node, '100', 'count')
        sql = result.to_sql
        assert_includes sql, 'CAST'
        assert_includes sql, 'DOUBLE PRECISION'
        assert_includes sql, '<='
      end
      # condition_greater_than_or_equal tests
      test 'condition_greater_than_or_equal uses gteq for regular fields' do
        result = @test_instance.send(:condition_greater_than_or_equal,
                                     @scope, @created_at_node, '2024-01-01',  nil)
        sql = result.to_sql
        assert_includes sql, '>='
        assert_not_includes sql, 'TO_DATE'
        assert_not_includes sql, 'CAST'
      end

      test 'condition_greater_than_or_equal uses gteq for regular fields with FF and metadata_field is false' do
        result = @test_instance.send(:condition_greater_than_or_equal,
                                     @scope, @created_at_node, '2024-01-01',  nil)
        sql = result.to_sql
        assert_includes sql, '>='
        assert_not_includes sql, 'TO_DATE'
        assert_not_includes sql, 'CAST'
      end

      test 'condition_greater_than_or_equal uses date comparison for date metadata fields' do
        result = @test_instance.send(:condition_greater_than_or_equal,
                                     @scope, @node, '2024-01-01', 'updated_date')
        sql = result.to_sql
        assert_includes sql, 'TO_DATE'
        assert_includes sql, '>='
        assert_includes sql, '~'
      end

      test 'condition_greater_than_or_equal uses numeric comparison for numeric metadata fields' do
        result = @test_instance.send(:condition_greater_than_or_equal,
                                     @scope, @node, '50', 'score')
        sql = result.to_sql
        assert_includes sql, 'CAST'
        assert_includes sql, 'DOUBLE PRECISION'
        assert_includes sql, '>='
      end
    end
  end
end
