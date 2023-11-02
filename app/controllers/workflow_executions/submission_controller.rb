# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SubmissionController < ApplicationController
    def pipeline_selection
      respond_to do |format|
        format.html { redirect_to dashboard_projects_path }
        format.turbo_stream do
          render 'workflow_executions/submissions/pipeline_selection'
        end
      end
    end
  end
end
