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

    %i[redirect_path destroy_paths destroy_multiple_paths cancel_multiple_paths].each do |method_name|
      assert_raises(NotImplementedError) { controller.send(method_name) }
    end
  end

  test 'select keeps an empty selection when select parameter is blank' do
    controller = WorkflowExecutionActionsImplementedController.new
    controller.instance_variable_set(:@namespace, nil)
    controller.define_singleton_method(:authorize!) { |_namespace, to:| to == :view_workflow_executions? }
    controller.define_singleton_method(:params) { { select: '' } }

    controller.select

    assert_equal [], controller.instance_variable_get(:@workflow_executions)
  end

  test 'select loads ids when select parameter is present' do
    controller = WorkflowExecutionActionsImplementedController.new
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
end
