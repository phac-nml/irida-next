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
      @metadata = generate_metadata_for_samplesheet.to_json
      render status: :ok
    end

    private

    def generate_metadata_for_samplesheet
      metadata = {}
      @samples.each_with_index do |sample, index|
        metadata[index] = sample.metadata.fetch(@field, '')
      end
      metadata
    end
  end
end
