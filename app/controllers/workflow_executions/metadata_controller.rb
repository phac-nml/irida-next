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
        metadata_samplesheet[index] = sample.metadata.fetch(@field, '')
      end
      metadata_samplesheet
    end
  end
end
