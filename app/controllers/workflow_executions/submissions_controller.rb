# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SubmissionsController < ApplicationController
    include Metadata
    respond_to :turbo_stream
    before_action :workflows
    before_action :samples, only: %i[create]
    before_action :workflow, only: %i[create]
    before_action :namespace_id, only: %i[create pipeline_selection]
    before_action :allowed_to_update_samples, only: %i[create]

    def pipeline_selection
      render status: :ok
    end

    def create
      fields_for_namespace(
        namespace: Namespace.find_by(id: @namespace_id),
        show_fields: true
      )
      render status: :ok
    end

    private

    def workflows
      @workflows = Irida::Pipelines.instance.executable_pipelines
    end

    def workflow
      workflow_name = params[:workflow_name]
      workflow_version = params[:workflow_version]

      @workflow = Irida::Pipelines.instance.find_pipeline_by(workflow_name, workflow_version)
    end

    def samples
      sample_ids = params[:sample_ids]
      @samples = Sample.includes(attachments: { file_attachment: :blob }).where(id: sample_ids)
    end

    def namespace_id
      @namespace_id = params[:namespace_id]
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
