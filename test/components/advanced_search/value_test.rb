# frozen_string_literal: true

require 'view_component_test_case'

module AdvancedSearch
  class ValueTest < ViewComponentTestCase
    setup do
      @condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: '=', value: 'completed')
    end

    test 'enum_options returns translated state values' do
      enum_fields = {
        'state' => {
          values: WorkflowExecution.states.keys,
          translation_key: 'workflow_executions.state'
        }
      }

      component = AdvancedSearch::Value.new(
        conditions_form: nil,
        group_index: 0,
        condition: @condition,
        condition_index: 0,
        enum_fields: enum_fields
      )

      options = component.send(:enum_options)

      assert_equal WorkflowExecution.states.keys.length, options.length
      assert_includes options.map(&:first), I18n.t('workflow_executions.state.initial')
      assert_includes options.map(&:first), I18n.t('workflow_executions.state.completed')
      assert_includes options.map(&:last), 'initial'
      assert_includes options.map(&:last), 'completed'
    end

    test 'enum_options uses labels when provided instead of translation' do
      @condition.field = 'metadata.workflow_name'
      workflow_names = ['IRIDA NEXT EXAMPLE', 'Another Workflow']
      enum_fields = {
        'metadata.workflow_name' => {
          values: workflow_names,
          translation_key: 'pipelines.name',
          labels: workflow_names.index_with { |name| name }
        }
      }

      component = AdvancedSearch::Value.new(
        conditions_form: nil,
        group_index: 0,
        condition: @condition,
        condition_index: 0,
        enum_fields: enum_fields
      )

      options = component.send(:enum_options)

      assert_equal workflow_names.length, options.length
      assert_includes options.map(&:first), 'IRIDA NEXT EXAMPLE'
      assert_includes options.map(&:first), 'Another Workflow'
      assert_includes options.map(&:last), 'IRIDA NEXT EXAMPLE'
      assert_includes options.map(&:last), 'Another Workflow'
    end

    test 'enum_field? returns true for configured enum field' do
      enum_fields = {
        'state' => {
          values: WorkflowExecution.states.keys,
          translation_key: 'workflow_executions.state'
        }
      }

      component = AdvancedSearch::Value.new(
        conditions_form: nil,
        group_index: 0,
        condition: @condition,
        condition_index: 0,
        enum_fields: enum_fields
      )

      assert component.send(:enum_field?)
    end

    test 'enum_field? returns false for non-enum field' do
      @condition.field = 'name'

      component = AdvancedSearch::Value.new(
        conditions_form: nil,
        group_index: 0,
        condition: @condition,
        condition_index: 0,
        enum_fields: {}
      )

      assert_not component.send(:enum_field?)
    end

    test 'render_enum_select? returns true for enum field with equals operator' do
      enum_fields = {
        'state' => {
          values: WorkflowExecution.states.keys,
          translation_key: 'workflow_executions.state'
        }
      }

      component = AdvancedSearch::Value.new(
        conditions_form: nil,
        group_index: 0,
        condition: @condition,
        condition_index: 0,
        enum_fields: enum_fields
      )

      assert component.send(:render_enum_select?)
    end

    test 'render_enum_multiselect? returns true for enum field with in operator' do
      @condition.operator = 'in'
      enum_fields = {
        'state' => {
          values: WorkflowExecution.states.keys,
          translation_key: 'workflow_executions.state'
        }
      }

      component = AdvancedSearch::Value.new(
        conditions_form: nil,
        group_index: 0,
        condition: @condition,
        condition_index: 0,
        enum_fields: enum_fields
      )

      assert component.send(:render_enum_multiselect?)
    end

    test 'list_operator? returns true for in and not_in operators' do
      @condition.operator = 'in'
      component = AdvancedSearch::Value.new(
        conditions_form: nil,
        group_index: 0,
        condition: @condition,
        condition_index: 0,
        enum_fields: {}
      )

      assert component.send(:list_operator?)

      @condition.operator = 'not_in'
      component = AdvancedSearch::Value.new(
        conditions_form: nil,
        group_index: 0,
        condition: @condition,
        condition_index: 0,
        enum_fields: {}
      )

      assert component.send(:list_operator?)
    end

    test 'list_operator? returns false for other operators' do
      @condition.operator = '='
      component = AdvancedSearch::Value.new(
        conditions_form: nil,
        group_index: 0,
        condition: @condition,
        condition_index: 0,
        enum_fields: {}
      )

      assert_not component.send(:list_operator?)
    end
  end
end
