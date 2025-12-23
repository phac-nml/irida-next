# frozen_string_literal: true

module WorkflowExecutions
  # Controller for metadata actions within a workflow execution
  class MetadataController < ApplicationController
    respond_to :turbo_stream

    def fields
      @samples = Sample.where(id: params[:sample_ids])
      @header = params[:header]
      @field = params[:field]
      @metadata = generate_metadata_for_samplesheet.to_json
      render status: :ok
    end

    private

    def generate_metadata_for_samplesheet
      metadata = {}
      @samples.each do |sample|
        metadata[sample.id] = {
          sample_id: sample.id,
          samplesheet_params: {
            "#{@header}": sample.metadata.fetch(@field, '')
          }
        }
      end
      metadata
    end
  end
end
