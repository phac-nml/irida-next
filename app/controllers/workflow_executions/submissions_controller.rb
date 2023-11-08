# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SubmissionsController < ApplicationController
    respond_to :turbo_stream
    def pipeline_selection
      respond_to do |format|
        format.turbo_stream do
          render status: :ok
        end
      end
    end
  end
end
