# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  module Operators
    class SetOperatorsTest < ActiveSupport::TestCase
      # Test class that includes the SetOperators module
      class TestClass
        include AdvancedSearch::Operators::SetOperators

        # Helper method from parent Operators module
        def enum_metadata_field?(field_name)
          WorkflowExecution::FieldConfiguration::ENUM_METADATA_FIELDS.include?(field_name)
        end
      end

      def setup
        @test_instance = TestClass.new
        @scope = WorkflowExecution.all
        @node = WorkflowExecution.arel_table[:name]
        @state_node = WorkflowExecution.arel_table[:state]
      end

      # downcase_values tests
      test 'downcase_values downcases all string values' do
        result = @test_instance.send(:downcase_values, %w[Test VALUE Mixed])
        assert_equal %w[test value mixed], result
      end

      test 'downcase_values removes nil values' do
        result = @test_instance.send(:downcase_values, ['Test', nil, 'Value'])
        assert_equal %w[test value], result
      end

      test 'downcase_values converts non-strings to downcased strings' do
        result = @test_instance.send(:downcase_values, [123, :Symbol])
        assert_equal %w[123 symbol], result
      end

      test 'downcase_values handles scalar values' do
        result = @test_instance.send(:downcase_values, 'TeSt')
        assert_equal ['test'], result
      end

      # condition_in tests
      test 'condition_in uses exact match IN for regular fields' do
        result = @test_instance.send(:condition_in,
                                     @scope, @state_node, %w[completed running],
                                     metadata_field: false, field_name: 'state')
        sql = result.to_sql
        assert_includes sql, '"workflow_executions"."state" IN'
        assert_not_includes sql, 'LOWER'
      end

      test 'condition_in uses case-insensitive IN for metadata fields' do
        result = @test_instance.send(:condition_in,
                                     @scope, @node, %w[Test Value],
                                     metadata_field: true, field_name: 'metadata.some_field')
        sql = result.to_sql
        assert_includes sql, 'LOWER'
        assert_includes sql, 'IN'
      end

      test 'condition_in uses case-insensitive IN for name field' do
        result = @test_instance.send(:condition_in,
                                     @scope, @node, %w[Test Value],
                                     metadata_field: false, field_name: 'name')
        sql = result.to_sql
        assert_includes sql, 'LOWER'
        assert_includes sql, 'IN'
      end

      test 'condition_in uses case-insensitive IN for enum metadata fields' do
        result = @test_instance.send(:condition_in,
                                     @scope, @node, %w[phac-nml/pipeline1 phac-nml/pipeline2],
                                     metadata_field: true, field_name: 'metadata.pipeline_id')
        sql = result.to_sql
        assert_includes sql, 'IN'
        assert_includes sql, 'LOWER'
      end

      test 'condition_in uses case-insensitive IN for workflow_version enum field' do
        result = @test_instance.send(:condition_in,
                                     @scope, @node, %w[1.0.0 2.0.0],
                                     metadata_field: true, field_name: 'metadata.workflow_version')
        sql = result.to_sql
        assert_includes sql, 'IN'
        assert_includes sql, 'LOWER'
      end

      test 'condition_in handles scalar value for regular fields' do
        result = @test_instance.send(:condition_in,
                                     @scope, @state_node, 'completed',
                                     metadata_field: false, field_name: 'state')
        sql = result.to_sql
        assert_includes sql, '"workflow_executions"."state" IN'
      end

      # condition_not_in tests
      test 'condition_not_in uses exact match NOT IN for regular fields' do
        result = @test_instance.send(:condition_not_in,
                                     @scope, @state_node, %w[completed running],
                                     metadata_field: false, field_name: 'state')
        sql = result.to_sql
        assert_includes sql, '"workflow_executions"."state" NOT IN'
        assert_not_includes sql, 'LOWER'
      end

      test 'condition_not_in uses case-insensitive NOT IN with null check for metadata fields' do
        result = @test_instance.send(:condition_not_in,
                                     @scope, @node, %w[Test Value],
                                     metadata_field: true, field_name: 'metadata.some_field')
        sql = result.to_sql
        assert_includes sql, 'LOWER'
        assert_includes sql, 'NOT IN'
        assert_includes sql, 'IS NULL'
      end

      test 'condition_not_in uses case-insensitive NOT IN for name field' do
        result = @test_instance.send(:condition_not_in,
                                     @scope, @node, %w[Test Value],
                                     metadata_field: false, field_name: 'name')
        sql = result.to_sql
        assert_includes sql, 'LOWER'
        assert_includes sql, 'NOT IN'
      end

      test 'condition_not_in uses case-insensitive NOT IN for enum metadata fields' do
        result = @test_instance.send(:condition_not_in,
                                     @scope, @node, %w[phac-nml/pipeline1 phac-nml/pipeline2],
                                     metadata_field: true, field_name: 'metadata.pipeline_id')
        sql = result.to_sql
        assert_includes sql, 'NOT IN'
        assert_includes sql, 'LOWER'
      end

      test 'condition_not_in uses case-insensitive NOT IN for workflow_version enum field' do
        result = @test_instance.send(:condition_not_in,
                                     @scope, @node, %w[1.0.0 2.0.0],
                                     metadata_field: true, field_name: 'metadata.workflow_version')
        sql = result.to_sql
        assert_includes sql, 'NOT IN'
        assert_includes sql, 'LOWER'
      end

      test 'condition_not_in handles scalar value for regular fields' do
        result = @test_instance.send(:condition_not_in,
                                     @scope, @state_node, 'completed',
                                     metadata_field: false, field_name: 'state')
        sql = result.to_sql
        assert_includes sql, '"workflow_executions"."state" NOT IN'
      end
    end
  end
end
