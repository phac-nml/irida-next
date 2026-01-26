# frozen_string_literal: true

require 'view_component_test_case'

class AdvancedSearchComponentUnitTest < ViewComponentTestCase
  def setup
    @entity_fields = %w[id name state created_at updated_at]
    @enum_fields = {
      'state' => {
        values: %w[initial running completed error],
        labels: nil,
        translation_key: 'workflow_executions.state'
      }
    }
  end

  test 'search_class_map returns correct class for Sample::Query via convention' do
    component = build_component(Sample::Query.new, sample_fields: %w[name])

    assert_equal Sample::SearchGroup, component.send(:search_class_map, 'Sample::Query', :group)
    assert_equal Sample::SearchCondition, component.send(:search_class_map, 'Sample::Query', :condition)
  end

  test 'search_class_map returns correct class for WorkflowExecution::Query via convention' do
    component = build_component(WorkflowExecution::Query.new, entity_fields: @entity_fields)

    assert_equal WorkflowExecution::SearchGroup,
                 component.send(:search_class_map, 'WorkflowExecution::Query', :group)
    assert_equal WorkflowExecution::SearchCondition,
                 component.send(:search_class_map, 'WorkflowExecution::Query', :condition)
  end

  test 'search_class_map falls back to Sample classes for unknown query' do
    component = build_component(Sample::Query.new, sample_fields: %w[name])

    assert_equal Sample::SearchGroup, component.send(:search_class_map, 'Unknown::Query', :group)
    assert_equal Sample::SearchCondition, component.send(:search_class_map, 'Unknown::Query', :condition)
  end

  test 'translated_field_label returns translated label for known field' do
    component = build_component(
      WorkflowExecution::Query.new,
      entity_fields: @entity_fields,
      field_label_namespace: 'workflow_executions.table_component'
    )

    label = component.send(:translated_field_label, 'state')
    assert_kind_of String, label
    assert label.present?
  end

  test 'translated_field_label handles array fields by returning first element' do
    component = build_component(WorkflowExecution::Query.new, entity_fields: @entity_fields)

    label = component.send(:translated_field_label, ['Custom Label', 'field_name'])
    assert_equal 'Custom Label', label
  end

  test 'translated_field_label humanizes unknown field names' do
    component = build_component(
      WorkflowExecution::Query.new,
      entity_fields: @entity_fields,
      field_label_namespace: 'nonexistent.namespace'
    )

    label = component.send(:translated_field_label, 'some_unknown_field')
    assert_equal 'Some unknown field', label
  end

  test 'entity_field_options converts fields to select options' do
    component = build_component(
      WorkflowExecution::Query.new,
      entity_fields: @entity_fields,
      field_label_namespace: 'workflow_executions.table_component'
    )

    options = component.send(:entity_field_options, @entity_fields)

    assert_equal @entity_fields.length, options.length
    assert(options.all? { |opt| opt.is_a?(Array) && opt.length == 2 })
  end

  test 'jsonb_field_options groups fields under metadata header' do
    component = build_component(Sample::Query.new, sample_fields: %w[name])

    jsonb_fields = %w[age species]
    options = component.send(:jsonb_field_options, jsonb_fields)

    assert_kind_of Hash, options
    # Should have one key (the translated metadata group header)
    assert_equal 1, options.keys.length

    # Values should be prefixed with 'metadata.'
    values = options.values.first
    assert_equal 2, values.length
    assert(values.all? { |opt| opt[1].start_with?('metadata.') })
  end

  test 'operation_options returns hash of translated operators' do
    component = build_component(Sample::Query.new, sample_fields: %w[name])

    options = component.send(:operation_options)

    assert_kind_of Hash, options
    assert_equal AdvancedSearchComponent::STANDARD_OPERATION_KEYS.length, options.length
  end

  test 'enum_operation_options returns subset of operators for enum fields' do
    component = build_component(Sample::Query.new, sample_fields: %w[name])

    options = component.send(:enum_operation_options)

    assert_kind_of Hash, options
    assert_equal AdvancedSearchComponent::ENUM_OPERATION_KEYS.length, options.length
  end

  private

  def build_component(query, **options)
    defaults = { sample_fields: [], entity_fields: [], metadata_fields: [], jsonb_fields: [],
                 enum_fields: {}, field_label_namespace: 'samples.table_component' }

    AdvancedSearchComponent.new(form: build_form_builder(query), search: query, **defaults.merge(options))
  end

  def build_form_builder(query)
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    form_builder = nil
    view.form_with(model: query, scope: :q, url: '/test') do |f|
      form_builder = f
    end
    form_builder
  end
end
