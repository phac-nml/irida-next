# frozen_string_literal: true

require 'test_helper'

class WorkflowExecutionActionsDummyController < ApplicationController
  include WorkflowExecutionActions
end

class WorkflowExecutionActionsConcernTest < ActionDispatch::IntegrationTest
  test 'abstract path helpers raise NotImplementedError' do
    controller = WorkflowExecutionActionsDummyController.new

    %i[redirect_path destroy_paths destroy_multiple_paths cancel_multiple_paths].each do |method|
      assert_raises(NotImplementedError) { controller.send(method) }
    end
  end
end
