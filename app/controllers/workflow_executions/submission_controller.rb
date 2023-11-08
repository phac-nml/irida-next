# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SubmissionController < ApplicationController
    respond_to :turbo_stream
    def pipeline_selection
      respond_to do |format|
        format.turbo_stream do
          render 'workflow_executions/submissions/pipeline_selection'
        end
      end
    end
  end
end
