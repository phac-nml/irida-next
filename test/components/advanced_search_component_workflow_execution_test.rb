# frozen_string_literal: true

require 'view_component_test_case'

class AdvancedSearchComponentWorkflowExecutionTest < ViewComponentTestCase
  setup do
    @query = WorkflowExecution::Query.new
    @query.groups << WorkflowExecution::SearchGroup.new
    # Create a proper form builder for testing
    template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    @form = ActionView::Helpers::FormBuilder.new(
      'q',
      @query,
      template,
      {}
    )
  end

  test 'component initializes with workflow execution fields' do
    component = AdvancedSearchComponent.new(
      form: @form,
      search: @query,
      entity_fields: %w[id name state run_id created_at updated_at],
      jsonb_fields: %w[workflow_name workflow_version],
      field_label_namespace: 'workflow_executions.table_component',
      open: false,
      status: false
    )

    # Test initialization without rendering
    assert_equal @form, component.instance_variable_get(:@form)
    assert_equal @query, component.instance_variable_get(:@search)
    assert_equal 'workflow_executions.table_component', component.instance_variable_get(:@field_label_namespace)
  end

  test 'component initializes with correct workflow execution search classes' do
    component = AdvancedSearchComponent.new(
      form: @form,
      search: @query,
      entity_fields: %w[id name state],
      jsonb_fields: %w[workflow_name],
      field_label_namespace: 'workflow_executions.table_component',
      open: false,
      status: false
    )

    assert_equal WorkflowExecution::SearchGroup, component.instance_variable_get(:@search_group_class)
    assert_equal WorkflowExecution::SearchCondition, component.instance_variable_get(:@search_condition_class)
  end

  test 'component initializes with all workflow execution entity fields' do
    component = AdvancedSearchComponent.new(
      form: @form,
      search: @query,
      entity_fields: %w[id name state run_id created_at updated_at],
      jsonb_fields: [],
      field_label_namespace: 'workflow_executions.table_component',
      open: false,
      status: false
    )

    # Test initialization without rendering (to avoid form builder HTML issues)
    assert_equal @form, component.instance_variable_get(:@form)
    assert_equal @query, component.instance_variable_get(:@search)
    entity_fields = component.instance_variable_get(:@entity_fields)
    assert_equal 6, entity_fields.length
  end

  test 'component initializes with workflow execution JSONB fields' do
    component = AdvancedSearchComponent.new(
      form: @form,
      search: @query,
      entity_fields: [],
      jsonb_fields: %w[workflow_name workflow_version],
      field_label_namespace: 'workflow_executions.table_component',
      open: false,
      status: false
    )

    # Test initialization - JSONB fields are stored WITH metadata. prefix for form submission
    # The Query model strips this prefix in normalized_field() method
    jsonb_fields = component.instance_variable_get(:@jsonb_fields)
    assert_equal 1, jsonb_fields.keys.length
    jsonb_options = jsonb_fields.values.first
    assert(jsonb_options.any? { |f| f[1] == 'metadata.workflow_name' })
    assert(jsonb_options.any? { |f| f[1] == 'metadata.workflow_version' })
  end

  test 'component initializes with workflow execution field labels' do
    component = AdvancedSearchComponent.new(
      form: @form,
      search: @query,
      entity_fields: %w[id name state],
      jsonb_fields: [],
      field_label_namespace: 'workflow_executions.table_component',
      open: false,
      status: false
    )

    # Verify field labels are set correctly
    entity_fields = component.instance_variable_get(:@entity_fields)
    assert_equal 3, entity_fields.length
    assert(entity_fields.any? { |f| f[0] == I18n.t('workflow_executions.table_component.id') })
    assert(entity_fields.any? { |f| f[0] == I18n.t('workflow_executions.table_component.name') })
    assert(entity_fields.any? { |f| f[0] == I18n.t('workflow_executions.table_component.state') })
  end

  test 'component initializes with advanced query status' do
    @query.groups.first.conditions << WorkflowExecution::SearchCondition.new(
      field: 'state',
      operator: '=',
      value: 'completed'
    )

    component = AdvancedSearchComponent.new(
      form: @form,
      search: @query,
      entity_fields: %w[id name state],
      jsonb_fields: [],
      field_label_namespace: 'workflow_executions.table_component',
      open: false,
      status: @query.advanced_query?
    )

    # Test that component initializes correctly with advanced query status
    assert @query.advanced_query?
    assert_equal @query.advanced_query?, component.instance_variable_get(:@status)
  end

  test 'component initializes with validation errors state' do
    @query.groups.first.conditions << WorkflowExecution::SearchCondition.new(
      field: 'invalid_field',
      operator: '=',
      value: 'test'
    )
    @query.valid? # Trigger validation

    component = AdvancedSearchComponent.new(
      form: @form,
      search: @query,
      entity_fields: %w[id name state],
      jsonb_fields: [],
      field_label_namespace: 'workflow_executions.table_component',
      open: @query.errors.any?,
      status: false
    )

    # Test that component initializes correctly with errors
    assert_equal @query.errors.any?, component.instance_variable_get(:@open)
  end

  test 'component initializes with multiple groups' do
    # Create a fresh query for this test
    # Note: WorkflowExecution::Query.new initializes with one default group
    fresh_query = WorkflowExecution::Query.new
    # Add one more group
    fresh_query.groups << WorkflowExecution::SearchGroup.new(
      conditions: [
        WorkflowExecution::SearchCondition.new(field: 'state', operator: '=', value: 'completed')
      ]
    )

    component = AdvancedSearchComponent.new(
      form: @form,
      search: fresh_query,
      entity_fields: %w[id name state],
      jsonb_fields: [],
      field_label_namespace: 'workflow_executions.table_component',
      open: false,
      status: true
    )

    # Test initialization with multiple groups (default + one added = 2 total)
    assert_equal 2, fresh_query.groups.length
    assert component.instance_variable_get(:@status)
  end

  test 'component initializes with workflow execution operators' do
    component = AdvancedSearchComponent.new(
      form: @form,
      search: @query,
      entity_fields: %w[id name state],
      jsonb_fields: [],
      field_label_namespace: 'workflow_executions.table_component',
      open: false,
      status: false
    )

    # Verify operators are set correctly
    operations = component.instance_variable_get(:@operations)
    assert operations.is_a?(Hash)
    assert operations.key?(I18n.t('components.advanced_search_component.operation.equals'))
    assert operations.key?(I18n.t('components.advanced_search_component.operation.contains'))
    assert operations.key?(I18n.t('components.advanced_search_component.operation.in'))
  end
end
