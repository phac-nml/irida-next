# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SubmissionsController < ApplicationController
    include Metadata

    respond_to :turbo_stream
    before_action :workflows
    before_action :sample_count, only: %i[create]
    before_action :workflow, only: %i[create]
    before_action :namespace_id, only: %i[create pipeline_selection]
    before_action :samplesheet_params, only: %i[samplesheet]

    def pipeline_selection
      render status: :ok
    end

    def create
      @namespace = Namespace.find_by(id: @namespace_id)
      fields_for_namespace_or_template(
        namespace: @namespace,
        template: 'all'
      )
      render status: :ok
    end

    def samplesheet
      render status: :ok
    end

    private

    def workflows
      @workflows = Irida::Pipelines.instance.pipelines('executable').sort_by { |_key, pipeline| pipeline }
    end

    def workflow
      pipeline_id = params[:pipeline_id]
      workflow_version = params[:workflow_version]

      @workflow = Irida::Pipelines.instance.find_pipeline_by(pipeline_id, workflow_version)
    end

    def sample_count
      @sample_count = params[:sample_count]
    end

    def namespace_id
      @namespace_id = params[:namespace_id]
    end

    def samplesheet_params
      @properties = JSON.parse(params[:properties])
      @samples = Sample.includes(attachments: { file_attachment: :blob }).where(id: params[:sample_ids])

      allowed_to_update_samples
    end

    def allowed_to_update_samples
      projects = Project.where(id: @samples.select(:project_id))

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
