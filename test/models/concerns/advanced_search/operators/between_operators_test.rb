# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  module Operators
    class BetweenOperatorsTest < ActiveSupport::TestCase
      # Test class that includes the BetweenOperators module
      class TestClass
        include AdvancedSearch::Operators::BetweenOperators
        include AdvancedSearch::MetadataComparison
      end

      def setup
        @test_instance = TestClass.new
        @scope = WorkflowExecution.all
        @node = WorkflowExecution.arel_table[:name]
        @created_at_node = WorkflowExecution.arel_table[:created_at]
      end

      test 'condition_numeric_between' do
        result = @test_instance.send(:condition_numeric_between,
                                     @scope, @node, ['0', '99.9'])
        sql = result.to_sql
        assert_includes sql, 'AND CAST("workflow_executions"."name" AS DOUBLE PRECISION) BETWEEN 0.0 AND 99.9'
      end

      test 'condition_date_between' do
        result = @test_instance.send(:condition_date_between,
                                     @scope, @created_at_node, %w[2026-01-01 2026-12-31])
        sql = result.to_sql
        assert_includes sql, "DATE(\"workflow_executions\".\"created_at\") BETWEEN '2026-01-01' AND '2026-12-31'"
      end

      test 'condition_text_between' do
        result = @test_instance.send(:condition_text_between,
                                     @scope, @node, %w[a z])
        sql = result.to_sql
        assert_includes sql, "LOWER(\"workflow_executions\".\"name\") BETWEEN 'a' AND 'z'"
      end

      test 'condition_between casts dates when it receives dates' do
        result = @test_instance.send(:condition_between,
                                     @scope, @created_at_node, %w[2026-01-01 2026-12-31])
        sql = result.to_sql
        assert_includes sql, "DATE(\"workflow_executions\".\"created_at\") BETWEEN '2026-01-01' AND '2026-12-31'"
      end

      test 'condition_between casts numeric when it receives numbers' do
        result = @test_instance.send(:condition_between,
                                     @scope, @node, ['0', '99.9'])
        sql = result.to_sql
        assert_includes sql, 'AND CAST("workflow_executions"."name" AS DOUBLE PRECISION) BETWEEN 0.0 AND 99.9'
      end

      test 'condition_between casts text when it does not receive both numbers or dates' do
        result = @test_instance.send(:condition_between,
                                     @scope, @node, %w[0 2026-12-31])
        sql = result.to_sql
        assert_includes sql, "LOWER(\"workflow_executions\".\"name\") BETWEEN '0' AND '2026-12-31'"
      end
    end
  end
end
