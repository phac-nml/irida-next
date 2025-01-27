# frozen_string_literal: true

module WorkflowExecutions
  # Controller for metadata actions within a workflow execution
  class MetadataController < ApplicationController
    respond_to :turbo_stream

    def fields
      @samples = Sample.where(id: params[:sample_ids])
      @header = params[:header]
      @name_format = params[:name_format]
      @field = params[:field]
      @metadata_samplesheet = generate_metadata_for_samplesheet.to_json
      render status: :ok
    end

    private

    def generate_metadata_for_samplesheet
      metadata_samplesheet = {}
      @samples.each_with_index do |sample, index|
        form_name = "workflow_execution[samples_workflow_executions_attributes][#{index}][samplesheet_params][#{@header}]"
        metadata_samplesheet[form_name] = sample.metadata.fetch(@field, '')
      end
      metadata_samplesheet
    end
  end
end
