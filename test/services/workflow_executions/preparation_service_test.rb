# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class PreparationServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @workflow_execution = workflow_executions(:irida_next_example)
    end

    test 'prepare workflow_execution with valid params' do
      WorkflowExecutions::PreparationService.new(@workflow_execution, @user, {}).execute
    end
  end
end
