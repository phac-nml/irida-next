# frozen_string_literal: true

require 'view_component_test_case'

module AdvancedSearch
  class ValueComponentTest < ViewComponentTestCase
    def setup
      @condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: '=', value: 'running')
      @enum_fields = {
        'state' => {
          values: %w[initial running completed error],
          labels: nil,
          translation_key: 'workflow_executions.state'
        },
        'metadata.pipeline_id' => {
          values: %w[pipeline_1 pipeline_2],
          labels: { 'pipeline_1' => 'Pipeline One', 'pipeline_2' => 'Pipeline Two' },
          translation_key: nil
        }
      }
    end

    test 'renders text input for non-enum field' do
      condition = WorkflowExecution::SearchCondition.new(field: 'name', operator: '=', value: 'test')

      form_with_component(condition, {}) do |component|
        render_inline(component)
        assert_selector "input[type='text'][name$='[value]']"
        assert_no_selector 'select'
      end
    end

    test 'renders select for enum field with equals operator' do
      form_with_component(@condition, @enum_fields) do |component|
        render_inline(component)
        assert_selector "select[name$='[value]']"
        assert_no_selector 'select[multiple]'
      end
    end

    test 'renders multiselect for enum field with in operator' do
      condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: 'in', value: [])

      form_with_component(condition, @enum_fields) do |component|
        render_inline(component)
        assert_selector 'select[multiple]'
      end
    end

    test 'renders multiselect for enum field with not_in operator' do
      condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: 'not_in', value: [])

      form_with_component(condition, @enum_fields) do |component|
        render_inline(component)
        assert_selector 'select[multiple]'
      end
    end

    test 'enum_options uses translation_key when labels not provided' do
      component = build_component(@condition, @enum_fields)

      options = component.send(:enum_options)

      assert_equal 4, options.length
      # Labels should be translated using the translation_key
      options.each do |label, value|
        assert_equal I18n.t("workflow_executions.state.#{value}"), label
      end
    end

    test 'enum_options uses labels hash when provided' do
      condition = WorkflowExecution::SearchCondition.new(
        field: 'metadata.pipeline_id',
        operator: '=',
        value: 'pipeline_1'
      )
      component = build_component(condition, @enum_fields)

      options = component.send(:enum_options)

      assert_equal 2, options.length
      assert_includes options, ['Pipeline One', 'pipeline_1']
      assert_includes options, ['Pipeline Two', 'pipeline_2']
    end

    test 'enum_field? returns true for enum fields' do
      component = build_component(@condition, @enum_fields)
      assert component.send(:enum_field?)
    end

    test 'enum_field? returns false for non-enum fields' do
      condition = WorkflowExecution::SearchCondition.new(field: 'name', operator: '=', value: '')
      component = build_component(condition, @enum_fields)
      assert_not component.send(:enum_field?)
    end

    test 'list_operator? returns true for in operator' do
      condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: 'in', value: [])
      component = build_component(condition, @enum_fields)
      assert component.send(:list_operator?)
    end

    test 'list_operator? returns true for not_in operator' do
      condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: 'not_in', value: [])
      component = build_component(condition, @enum_fields)
      assert component.send(:list_operator?)
    end

    test 'list_operator? returns false for equals operator' do
      component = build_component(@condition, @enum_fields)
      assert_not component.send(:list_operator?)
    end

    test 'render_enum_select? returns true for enum field with non-list operator' do
      component = build_component(@condition, @enum_fields)
      assert component.send(:render_enum_select?)
    end

    test 'render_enum_select? returns false for enum field with list operator' do
      condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: 'in', value: [])
      component = build_component(condition, @enum_fields)
      assert_not component.send(:render_enum_select?)
    end

    test 'render_enum_multiselect? returns true for enum field with list operator' do
      condition = WorkflowExecution::SearchCondition.new(field: 'state', operator: 'in', value: [])
      component = build_component(condition, @enum_fields)
      assert component.send(:render_enum_multiselect?)
    end

    test 'render_enum_multiselect? returns false for enum field with non-list operator' do
      component = build_component(@condition, @enum_fields)
      assert_not component.send(:render_enum_multiselect?)
    end

    private

    def build_component(condition, enum_fields)
      form_builder = build_conditions_form(condition)
      create_value_component(form_builder, condition, enum_fields)
    end

    def form_with_component(condition, enum_fields)
      with_request_url('/test') do
        render_inline_with_form(WorkflowExecution::Query.new, scope: :q, url: '/test') do |f|
          build_nested_fields(f, condition) { |cf| yield create_value_component(cf, condition, enum_fields) }
        end
      end
    end

    def build_conditions_form(condition)
      form_builder = nil
      ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil).tap do |view|
        view.form_with(model: WorkflowExecution::Query.new, scope: :q, url: '/test') do |f|
          build_nested_fields(f, condition) { |cf| form_builder = cf }
        end
      end
      form_builder
    end

    def build_nested_fields(form, condition, &block)
      form.fields_for(:groups, WorkflowExecution::SearchGroup.new, child_index: 0) do |gf|
        gf.fields_for(:conditions, condition, child_index: 0, &block)
      end
    end

    def create_value_component(form_builder, condition, enum_fields)
      AdvancedSearch::Value.new(
        conditions_form: form_builder, group_index: 0, condition: condition,
        condition_index: 0, enum_fields: enum_fields
      )
    end

    def render_inline_with_form(model, scope:, url:, &)
      view_context = vc_test_controller.view_context
      form_html = view_context.form_with(model: model, scope: scope, url: url, &)
      # NOTE: form_with returns the full form HTML when a block is given
      @rendered_content = form_html
    end
  end
end
