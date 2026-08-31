# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionActionsDummyController < ApplicationController
  include WorkflowExecutionActions
end

class WorkflowExecutionActionsImplementedController < ApplicationController
  include WorkflowExecutionActions

  def redirect_path
    '/'
  end

  def destroy_paths; end

  def destroy_multiple_paths; end

  def cancel_multiple_paths; end
end

class WorkflowExecutionActionsConcernTest < ActiveSupport::TestCase
  test 'abstract path helpers raise NotImplementedError' do
    controller = WorkflowExecutionActionsDummyController.new

    %i[redirect_path destroy_paths destroy_multiple_paths cancel_multiple_paths].each do |method|
      assert_raises(NotImplementedError) { controller.send(method) }
    end
  end

  test 'format_samplesheet_params returns early when workflow is not executable' do
    controller = implemented_controller
    workflow_execution = workflow_executions(:irida_next_example_non_executable)
    controller.instance_variable_set(:@workflow_execution, workflow_execution)

    controller.send(:format_samplesheet_params)

    assert_nil controller.instance_variable_get(:@samplesheet_headers)
    assert_nil controller.instance_variable_get(:@samplesheet_rows)
  end

  test 'advanced search groups attributes accepts a plain hash' do
    controller = implemented_controller
    groups = { '0' => { 'conditions_attributes' => { '0' => { 'field' => 'name' } } } }
    params_hash = { q: { groups_attributes: groups } }
    controller.define_singleton_method(:params) { params_hash }

    assert_equal groups, controller.send(:workflow_advanced_search_groups_attributes)
  end

  test 'results messages cover empty pagy and all count branches' do
    controller = implemented_controller
    query = Object.new
    def query.advanced_query? = true
    def query.name_or_id_cont = 'term'
    controller.instance_variable_set(:@query, query)
    pagy = Object.new
    pagy.define_singleton_method(:count) { @count }
    pagy.define_singleton_method(:count=) { |value| @count = value }

    controller.instance_variable_set(:@pagy, nil)
    assert_kind_of String, controller.send(:results_message)

    controller.instance_variable_set(:@pagy, pagy)
    assert_kind_of String, controller.send(:advanced_search_results_message)

    pagy.count = 0
    assert_equal I18n.t('components.search.advanced.results_message.zero'),
                 controller.send(:advanced_search_results_message)

    pagy.count = 1
    assert_equal I18n.t('components.search.advanced.results_message.singular'),
                 controller.send(:advanced_search_results_message)

    pagy.count = 4
    assert_equal I18n.t('components.search.advanced.results_message.plural', total_count: 4),
                 controller.send(:advanced_search_results_message)

    def query.advanced_query? = false
    controller.instance_variable_set(:@pagy, nil)
    assert_kind_of String, controller.send(:results_message)

    pagy.count = nil
    controller.instance_variable_set(:@pagy, pagy)
    assert_kind_of String, controller.send(:quick_search_results_message)

    pagy.count = 0
    assert_equal I18n.t('components.search.results_message.zero', search_term: 'term'),
                 controller.send(:quick_search_results_message)

    pagy.count = 1
    assert_equal I18n.t('components.search.results_message.singular', search_term: 'term'),
                 controller.send(:quick_search_results_message)

    pagy.count = 4
    assert_equal I18n.t('components.search.results_message.plural', total_count: 4, search_term: 'term'),
                 controller.send(:quick_search_results_message)
  end

  test 'show skips namespace authorization and ignores unknown tabs' do
    controller = implemented_controller
    controller.instance_variable_set(:@workflow_execution, workflow_executions(:irida_next_example_completed))
    controller.instance_variable_set(:@namespace, nil)
    controller.instance_variable_set(:@tab, 'unknown')

    controller.show

    assert_nil controller.instance_variable_get(:@namespace_path)
    assert_nil controller.instance_variable_get(:@workflow)
    assert_nil controller.instance_variable_get(:@samplesheet_headers)
  end

  test 'select keeps an empty selection when select parameter is blank' do
    controller = implemented_controller
    controller.instance_variable_set(:@namespace, nil)
    controller.define_singleton_method(:authorize!) { |_namespace, to:| to == :view_workflow_executions? }
    controller.define_singleton_method(:params) { { select: '' } }

    controller.select

    assert_equal [], controller.instance_variable_get(:@workflow_executions)
  end

  test 'select loads ids when select parameter is present' do
    controller = implemented_controller
    controller.instance_variable_set(:@namespace, nil)
    controller.define_singleton_method(:authorize!) { |_namespace, to:| to == :view_workflow_executions? }
    controller.define_singleton_method(:params) { { select: 'on' } }

    selected_workflow = Struct.new(:id).new(123)
    query_results = Object.new
    query_results.define_singleton_method(:select) { |_field| [selected_workflow] }

    query = Object.new
    query.define_singleton_method(:results) { query_results }

    controller.define_singleton_method(:workflow_execution_query) { query }

    controller.select

    workflow_executions = controller.instance_variable_get(:@workflow_executions)
    assert_equal 1, workflow_executions.size
    assert_equal 123, workflow_executions.first.id
  end

  private

  def implemented_controller
    WorkflowExecutionActionsImplementedController.new
  end
end
