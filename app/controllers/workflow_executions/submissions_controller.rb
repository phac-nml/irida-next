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
      @namespace = Namespace.find_by(id: @namespace_id)
      fields_for_namespace_or_template(
        namespace: @namespace,
        template: 'all'
      )
      render status: :ok
    end

    private

    def workflows
      @workflows = Irida::Pipelines.instance.pipelines('executable')
      # @workflows = @workflows.sort_by do |_key, pipeline|
      #   [pipeline.name, -Gem::Version.new(pipeline.version)]
      # end.to_h
      # @workflows = @workflows.sort_by { |pipeline| pipeline[1] }
      @workflows = @workflows.sort_by { |_key, pipeline| pipeline }
      # @workflows = @workflows.sort { |a, b| a[1] <=> b[1] }
    end

    def workflow
      pipeline_id = params[:pipeline_id]
      workflow_version = params[:workflow_version]

      @workflow = Irida::Pipelines.instance.find_pipeline_by(pipeline_id, workflow_version)
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
