# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  module Operators
    class PatternOperatorsTest < ActiveSupport::TestCase
      # Test class that includes the PatternOperators module
      class TestClass
        include AdvancedSearch::Operators::PatternOperators

        # Make private methods accessible for testing
        public :condition_contains, :condition_not_contains, :condition_exists, :condition_not_exists,
               :cast_to_text_if_uuid, :uuid_column?, :escape_like_wildcards
      end

      def setup
        @test_instance = TestClass.new
        @scope = WorkflowExecution.all
        @node = WorkflowExecution.arel_table[:name]
        @uuid_node = WorkflowExecution.arel_table[:id]
      end

      # escape_like_wildcards tests
      test 'escape_like_wildcards escapes percent sign' do
        assert_equal '\\%test', @test_instance.escape_like_wildcards('%test')
      end

      test 'escape_like_wildcards escapes underscore' do
        assert_equal '\\_test', @test_instance.escape_like_wildcards('_test')
      end

      test 'escape_like_wildcards escapes backslash' do
        assert_equal '\\\\test', @test_instance.escape_like_wildcards('\\test')
      end

      test 'escape_like_wildcards escapes multiple special characters' do
        assert_equal '\\%\\_\\\\', @test_instance.escape_like_wildcards('%_\\')
      end

      test 'escape_like_wildcards returns string unchanged if no special characters' do
        # NOTE: underscore IS a special character in SQL LIKE, so it gets escaped
        assert_equal 'normalstring', @test_instance.escape_like_wildcards('normalstring')
      end

      # uuid_column? tests
      test 'uuid_column? returns true for uuid column' do
        assert @test_instance.uuid_column?(WorkflowExecution, 'id')
      end

      test 'uuid_column? returns false for non-uuid column' do
        assert_not @test_instance.uuid_column?(WorkflowExecution, 'name')
      end

      test 'uuid_column? returns false for non-existent column' do
        assert_not @test_instance.uuid_column?(WorkflowExecution, 'nonexistent')
      end

      # cast_to_text_if_uuid tests
      test 'cast_to_text_if_uuid returns original node for non-uuid column' do
        result = @test_instance.cast_to_text_if_uuid(@node, WorkflowExecution, 'name')
        assert_equal @node, result
      end

      test 'cast_to_text_if_uuid returns cast function for uuid column' do
        result = @test_instance.cast_to_text_if_uuid(@uuid_node, WorkflowExecution, 'id')
        assert_instance_of Arel::Nodes::NamedFunction, result
        assert_equal 'CAST', result.name
      end

      # condition_contains tests
      test 'condition_contains creates ILIKE query with wildcards' do
        result = @test_instance.condition_contains(@scope, @node, 'test')
        sql = result.to_sql
        assert_includes sql, "ILIKE '%test%'"
      end

      test 'condition_contains escapes special characters in value' do
        result = @test_instance.condition_contains(@scope, @node, '%test%')
        sql = result.to_sql
        assert_includes sql, "ILIKE '%\\%test\\%%'"
      end

      test 'condition_contains casts uuid column to text' do
        result = @test_instance.condition_contains(@scope, @uuid_node, 'abc', model_class: WorkflowExecution,
                                                                              field_name: 'id')
        sql = result.to_sql
        assert_includes sql, 'CAST'
        assert_includes sql, 'TEXT'
      end

      # condition_not_contains tests
      test 'condition_not_contains creates NOT ILIKE query with null check' do
        result = @test_instance.condition_not_contains(@scope, @node, 'test')
        sql = result.to_sql
        assert_includes sql, 'NOT ILIKE'
        assert_includes sql, 'IS NULL'
      end

      test 'condition_not_contains escapes special characters in value' do
        result = @test_instance.condition_not_contains(@scope, @node, '%test%')
        sql = result.to_sql
        assert_includes sql, "NOT ILIKE '%\\%test\\%%'"
      end

      # condition_exists tests
      test 'condition_exists creates IS NOT NULL query' do
        result = @test_instance.condition_exists(@scope, @node)
        sql = result.to_sql
        assert_includes sql, 'IS NOT NULL'
      end

      # condition_not_exists tests
      test 'condition_not_exists creates IS NULL query' do
        result = @test_instance.condition_not_exists(@scope, @node)
        sql = result.to_sql
        assert_includes sql, 'IS NULL'
      end
    end
  end
end
