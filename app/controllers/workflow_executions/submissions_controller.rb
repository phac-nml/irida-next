# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SubmissionsController < ApplicationController
    include Metadata
    respond_to :turbo_stream
    before_action :workflows
    before_action :samples, only: %i[create]
    before_action :workflow, only: %i[create]
    before_action :allowed_to_update_samples, only: %i[create]

    def pipeline_selection
      @project_id = params[:project_id]
      render status: :ok
    end

    def create
      project = Project.find(params[:project_id])
      fields_for_namespace(
        namespace: project.namespace,
        show_fields: true
      )
      render status: :ok
    end

    private

    def workflows
      @workflows = Irida::Pipelines.available_pipelines
    end

    def workflow
      workflow_name = params[:workflow_name]
      workflow_version = params[:workflow_version]

      @workflow = Irida::Pipelines.find_pipeline_by(workflow_name, workflow_version)
    end

    def samples
      sample_ids = params[:sample_ids]
      @samples = Sample.includes(attachments: { file_attachment: :blob }).where(id: sample_ids)
    end

    def allowed_to_update_samples
      @allowed_to_update_samples = true
      projects = Project.where(id: Sample.where(id: params[:sample_ids]).select(:project_id))

      projects.each do |project|
        @allowed_to_update_samples = allowed_to?(
          :update_sample?,
          project
        )

        break unless @allowed_to_update_samples
      end
    end
  end
end
