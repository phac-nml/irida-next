# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  module Operators
    class ComparisonOperatorsTest < ActiveSupport::TestCase
      # Test class that includes the ComparisonOperators module
      class TestClass
        include AdvancedSearch::Operators::ComparisonOperators
        include AdvancedSearch::Operators::EqualityOperators
        include AdvancedSearch::MetadataComparison
        include AdvancedSearch::Operators
      end

      def setup
        @test_instance = TestClass.new
        @scope = WorkflowExecution.all
        @node = WorkflowExecution.arel_table[:name]
        @created_at_node = WorkflowExecution.arel_table[:created_at]
        @namespace = groups(:group_one)
        @user = users(:john_doe)
      end

      def create_workflow_execution(created_at:)
        WorkflowExecution.create!(
          name: "Test Workflow #{SecureRandom.hex(4)}",
          namespace_id: @namespace.id,
          state: :initial,
          run_id: "test_run_#{SecureRandom.hex(4)}",
          submitter_id: @user.id,
          metadata: { 'pipeline_id' => 'phac-nml/iridanextexample', 'workflow_version' => '1.0.0' },
          created_at: created_at
        )
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
        Flipper.enable(:advanced_search_metadata_operators)
        result = @test_instance.send(:condition_less_than_or_equal,
                                     @scope, @created_at_node, '2024-01-01', nil)
        sql = result.to_sql
        assert_includes sql, '<='
        assert_not_includes sql, 'TO_DATE'
        assert_not_includes sql, 'CAST'
      ensure
        Flipper.disable(:advanced_search_metadata_operators)
      end

      test 'condition_less_than_or_equal uses lteq for regular fields without FF and metadata_field is false' do
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
                                     @scope, @created_at_node, '2024-01-01', nil)
        sql = result.to_sql
        assert_includes sql, '>='
        assert_not_includes sql, 'TO_DATE'
        assert_not_includes sql, 'CAST'
      end

      test 'condition_greater_than_or_equal uses gteq for regular fields with FF and metadata_field is false' do
        Flipper.enable(:advanced_search_metadata_operators)
        result = @test_instance.send(:condition_greater_than_or_equal,
                                     @scope, @created_at_node, '2024-01-01', nil)
        sql = result.to_sql
        assert_includes sql, '>='
        assert_not_includes sql, 'TO_DATE'
        assert_not_includes sql, 'CAST'
      ensure
        Flipper.disable(:advanced_search_metadata_operators)
      end

      test 'condition_greater_than_or_equal uses gteq for regular fields without FF and metadata_field is false' do
        result = @test_instance.send(:condition_greater_than_or_equal,
                                     @scope, @created_at_node, '2024-01-01', nil)
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

      # standard _at field day-boundary normalization tests
      test 'condition_less_than_or_equal normalizes to start of next day for standard _at fields' do
        result = @test_instance.send(:condition_less_than_or_equal,
                                     @scope, @created_at_node, '2024-01-01', nil, 'created_at')
        sql = result.to_sql
        assert_includes sql, '<'
        assert_not_includes sql, '<='
      end

      test 'condition_less_than_or_equal includes records created later in the end day' do
        afternoon = Time.zone.parse('2024-01-01 15:00:00')
        workflow_execution = create_workflow_execution(created_at: afternoon)

        result = @test_instance.send(:condition_less_than_or_equal,
                                     @scope, @created_at_node, '2024-01-01', nil, 'created_at')

        assert_includes result, workflow_execution
      end

      test 'condition_greater_than_or_equal normalizes to start of day for standard _at fields' do
        result = @test_instance.send(:condition_greater_than_or_equal,
                                     @scope, @created_at_node, '2024-01-01', nil, 'created_at')
        sql = result.to_sql
        assert_includes sql, '>='
      end

      test 'condition_greater_than_or_equal excludes records created before the start day' do
        before_start_day = Time.zone.parse('2023-12-31 23:00:00')
        workflow_execution = create_workflow_execution(created_at: before_start_day)

        result = @test_instance.send(:condition_greater_than_or_equal,
                                     @scope, @created_at_node, '2024-01-01', nil, 'created_at')

        assert_not_includes result, workflow_execution
      end
    end
  end
end
