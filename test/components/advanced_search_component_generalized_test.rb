# frozen_string_literal: true

require 'view_component_test_case'

# Tests for generalized AdvancedSearchComponent
class AdvancedSearchComponentGeneralizedTest < ViewComponent::TestCase
  test 'component initializes with entity_fields and jsonb_fields for WorkflowExecution' do
    query = WorkflowExecution::Query.new
    query.groups << WorkflowExecution::SearchGroup.new

    # Mock form object
    form = Object.new

    component = AdvancedSearchComponent.new(
      form: form,
      search: query,
      entity_fields: %w[id name state run_id created_at updated_at],
      jsonb_fields: %w[workflow_name workflow_version],
      field_label_namespace: 'workflow_executions.table_component',
      open: false,
      status: false
    )

    # Verify the component initializes correctly
    assert_equal form, component.instance_variable_get(:@form)
    assert_equal query, component.instance_variable_get(:@search)
    assert_equal 'workflow_executions.table_component', component.instance_variable_get(:@field_label_namespace)
    assert_equal WorkflowExecution::SearchGroup, component.instance_variable_get(:@search_group_class)
    assert_equal WorkflowExecution::SearchCondition, component.instance_variable_get(:@search_condition_class)
  end

  test 'backward compatibility with sample_fields and metadata_fields parameters' do
    query = Sample::Query.new
    query.groups << Sample::SearchGroup.new

    # Mock form object
    form = Object.new

    component = AdvancedSearchComponent.new(
      form: form,
      search: query,
      sample_fields: %w[name puid created_at updated_at],
      metadata_fields: %w[age gender],
      open: false,
      status: false
    )

    # Verify backward compatibility - should use Sample classes
    assert_equal Sample::SearchGroup, component.instance_variable_get(:@search_group_class)
    assert_equal Sample::SearchCondition, component.instance_variable_get(:@search_condition_class)
    assert_equal 'samples.table_component', component.instance_variable_get(:@field_label_namespace)
  end

  test 'entity_fields parameter takes precedence over sample_fields for backward compatibility' do
    query = Sample::Query.new
    query.groups << Sample::SearchGroup.new

    # Mock form object
    form = Object.new

    component = AdvancedSearchComponent.new(
      form: form,
      search: query,
      entity_fields: %w[name puid],
      sample_fields: %w[should_be_ignored],
      jsonb_fields: %w[age],
      metadata_fields: %w[should_also_be_ignored],
      field_label_namespace: 'samples.table_component',
      open: false,
      status: false
    )

    # Verify entity_fields are used (not sample_fields)
    entity_fields = component.instance_variable_get(:@entity_fields)
    assert_equal 2, entity_fields.length

    # Verify jsonb_fields are used (not metadata_fields)
    jsonb_fields = component.instance_variable_get(:@jsonb_fields)
    assert_equal 1, jsonb_fields.keys.length
  end

  test 'defaults field_label_namespace to samples.table_component' do
    query = Sample::Query.new
    query.groups << Sample::SearchGroup.new

    # Mock form object
    form = Object.new

    # Don't specify field_label_namespace - should default to samples.table_component
    component = AdvancedSearchComponent.new(
      form: form,
      search: query,
      entity_fields: %w[name],
      jsonb_fields: [],
      open: false,
      status: false
    )

    # Verify default namespace
    assert_equal 'samples.table_component', component.instance_variable_get(:@field_label_namespace)
  end

  test 'determines correct search model classes based on search object type' do
    # Mock form object
    form = Object.new

    # Test with Sample::Query
    sample_query = Sample::Query.new
    sample_query.groups << Sample::SearchGroup.new

    sample_component = AdvancedSearchComponent.new(
      form: form,
      search: sample_query,
      entity_fields: %w[name],
      jsonb_fields: [],
      open: false,
      status: false
    )

    # Should use Sample::SearchGroup and Sample::SearchCondition
    assert_equal Sample::SearchGroup, sample_component.instance_variable_get(:@search_group_class)
    assert_equal Sample::SearchCondition, sample_component.instance_variable_get(:@search_condition_class)

    # Test with WorkflowExecution::Query
    we_query = WorkflowExecution::Query.new
    we_query.groups << WorkflowExecution::SearchGroup.new

    we_component = AdvancedSearchComponent.new(
      form: form,
      search: we_query,
      entity_fields: %w[name],
      jsonb_fields: [],
      open: false,
      status: false
    )

    # Should use WorkflowExecution::SearchGroup and WorkflowExecution::SearchCondition
    assert_equal WorkflowExecution::SearchGroup, we_component.instance_variable_get(:@search_group_class)
    assert_equal WorkflowExecution::SearchCondition, we_component.instance_variable_get(:@search_condition_class)
  end
end
