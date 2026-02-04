# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  module Operators
    class EqualityOperatorsTest < ActiveSupport::TestCase
      # Test class that includes the EqualityOperators module
      class TestClass
        include AdvancedSearch::Operators::EqualityOperators

        # Make private methods accessible for testing
        public :condition_equals, :condition_not_equals
      end

      def setup
        @test_instance = TestClass.new
        @scope = WorkflowExecution.all
        @node = WorkflowExecution.arel_table[:name]
        @state_node = WorkflowExecution.arel_table[:state]
      end

      # condition_equals tests
      test 'condition_equals uses exact match for regular fields' do
        result = @test_instance.condition_equals(@scope, @state_node, 'completed', metadata_field: false,
                                                                                   field_name: 'state')
        sql = result.to_sql
        assert_includes sql, '"workflow_executions"."state" = '
        assert_not_includes sql, 'ILIKE'
      end

      test 'condition_equals uses pattern match for metadata fields' do
        result = @test_instance.condition_equals(@scope, @node, 'test', metadata_field: true,
                                                                        field_name: 'metadata.some_field')
        sql = result.to_sql
        assert_includes sql, 'ILIKE'
      end

      test 'condition_equals uses pattern match for name field' do
        result = @test_instance.condition_equals(@scope, @node, 'test', metadata_field: false, field_name: 'name')
        sql = result.to_sql
        assert_includes sql, 'ILIKE'
      end

      test 'condition_equals uses exact match for enum metadata fields' do
        result = @test_instance.condition_equals(@scope, @node, 'phac-nml/pipeline', metadata_field: true,
                                                                                     field_name: 'metadata.pipeline_id')
        sql = result.to_sql
        assert_includes sql, '"workflow_executions"."name" = '
        assert_not_includes sql, 'ILIKE'
      end

      test 'condition_equals uses exact match for workflow_version enum field' do
        result = @test_instance.condition_equals(@scope, @node, '1.0.0', metadata_field: true,
                                                                         field_name: 'metadata.workflow_version')
        sql = result.to_sql
        assert_not_includes sql, 'ILIKE'
      end

      # condition_not_equals tests
      test 'condition_not_equals uses not_eq for regular fields' do
        result = @test_instance.condition_not_equals(@scope, @state_node, 'completed', metadata_field: false,
                                                                                       field_name: 'state')
        sql = result.to_sql
        assert_includes sql, '"workflow_executions"."state" != '
        assert_not_includes sql, 'NOT ILIKE'
      end

      test 'condition_not_equals uses NOT ILIKE with null check for metadata fields' do
        result = @test_instance.condition_not_equals(@scope, @node, 'test', metadata_field: true,
                                                                            field_name: 'metadata.some_field')
        sql = result.to_sql
        assert_includes sql, 'NOT ILIKE'
        assert_includes sql, 'IS NULL'
      end

      test 'condition_not_equals uses NOT ILIKE with null check for name field' do
        result = @test_instance.condition_not_equals(@scope, @node, 'test', metadata_field: false, field_name: 'name')
        sql = result.to_sql
        assert_includes sql, 'NOT ILIKE'
        assert_includes sql, 'IS NULL'
      end

      test 'condition_not_equals uses not_eq for enum metadata fields' do
        result = @test_instance.condition_not_equals(
          @scope, @node, 'phac-nml/pipeline',
          metadata_field: true, field_name: 'metadata.pipeline_id'
        )
        sql = result.to_sql
        assert_includes sql, '"workflow_executions"."name" != '
        assert_not_includes sql, 'NOT ILIKE'
      end

      test 'condition_not_equals uses not_eq for workflow_version enum field' do
        result = @test_instance.condition_not_equals(@scope, @node, '1.0.0', metadata_field: true,
                                                                             field_name: 'metadata.workflow_version')
        sql = result.to_sql
        assert_not_includes sql, 'NOT ILIKE'
      end
    end
  end
end
