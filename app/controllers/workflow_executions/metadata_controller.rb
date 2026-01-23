# frozen_string_literal: true

module WorkflowExecutions
  # Controller for metadata actions within a workflow execution
  class MetadataController < ApplicationController
    respond_to :turbo_stream

    def fields
      @samples = Sample.where(id: params[:sample_ids])

      if Flipper.enabled?(:deferred_samplesheet)
        @metadata_fields = JSON.parse(params[:metadata_fields])
      else
        @header = params[:header]
        @field = params[:field]
      end
      @metadata = generate_metadata_for_samplesheet.to_json
      render status: :ok
    end

    private

    # TODO: when feature flag :deferred_samplesheet is retired, move fetch_metadata_with_feature_flag logic
    # into generate_metadata_for_samplesheet
    def generate_metadata_for_samplesheet
      Flipper.enabled?(:deferred_samplesheet) ? fetch_metadata_with_feature_flag : fetch_metadata
    end

    # generate metadata is now updated to handle multiple metadata fields at once. This is to handle metadata changes
    # while samplesheet is undergoing initial processing
    # param metadata_fields is a hash that contains key/value equal to column_name: metadata_field
    # eg: {metadata_header_4: "age", metadata_header_5: "country"}
    # this then generates:
    # metadata = {
    #   0: {metadata_header_4: "46", metadata_header_5: "canada"},
    #   1: {metadata_header_4: "10", metadata_header_5: "USA"}
    # }
    def fetch_metadata_with_feature_flag
      metadata = {}
      @samples.each_with_index do |sample, index|
        metadata[index] = {}
        @metadata_fields.each do |key, value|
          metadata[index][key] = sample.metadata.fetch(value, '')
        end
      end
      metadata
    end

    def fetch_metadata
      metadata = {}
      @samples.each_with_index do |sample, index|
        metadata[index] = sample.metadata.fetch(@field, '')
      end
      metadata
    end
  end
end
