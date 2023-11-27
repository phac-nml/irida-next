# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SubmissionsController < ApplicationController
    respond_to :turbo_stream
    def pipeline_selection
      respond_to do |format|
        format.turbo_stream do
          @workflows = workflows
          render status: :ok
        end
      end
    end

    private

    def workflows
      workflow = Struct.new(:name, :id, :description, :version)
      awesome_flow = workflow.new('Super Awesome Workflow', 1, 'This is a super awesome workflow', '1.0.0')
      slow_flow = workflow.new('Incredibly Slow Workflow', 2, 'This is a super slow workflow', '0.0.1')
      [awesome_flow, slow_flow]
    end
  end
end
