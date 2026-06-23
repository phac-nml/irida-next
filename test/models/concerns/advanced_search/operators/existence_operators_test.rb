# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  module Operators
    class ExistenceOperatorsTest < ActiveSupport::TestCase
      # Test class that includes the ExistenceOperators module
      class TestClass
        include AdvancedSearch::Operators::ExistenceOperators
      end

      def setup
        @test_instance = TestClass.new
        @scope = WorkflowExecution.all
        @node = WorkflowExecution.arel_table[:name]
        @uuid_node = WorkflowExecution.arel_table[:id]
      end

      # condition_exists tests
      test 'condition_exists creates IS NOT NULL query' do
        result = @test_instance.send(:condition_exists, @scope, @node)
        sql = result.to_sql
        assert_includes sql, 'IS NOT NULL'
      end

      # condition_not_exists tests
      test 'condition_not_exists creates IS NULL query' do
        result = @test_instance.send(:condition_not_exists, @scope, @node)
        sql = result.to_sql
        assert_includes sql, 'IS NULL'
      end
    end
  end
end
