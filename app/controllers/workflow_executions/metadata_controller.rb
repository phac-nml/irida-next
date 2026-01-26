# frozen_string_literal: true

module WorkflowExecutions
  # Controller for metadata actions within a workflow execution
  class MetadataController < ApplicationController
    respond_to :turbo_stream

    def fields
      @sample_ids = params[:sample_ids].split(',')
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
      fields_to_query = [:id]

      @metadata_fields.each_value do |metadata_field|
        fields_to_query.append(Arel::Nodes::InfixOperation.new('->>', Sample.arel_table[:metadata], Arel::Nodes::Quoted.new(metadata_field)))
      end

      Sample.where(id: @sample_ids).pluck(fields_to_query).map do |results|
        { "#{results[0]}": { sample_id: results[0], samplesheet_params: retrieve_metadata(results) } }
      end
    end

    def fetch_metadata
      node = Arel::Nodes::InfixOperation.new('->>', Sample.arel_table[:metadata], Arel::Nodes::Quoted.new(@field))
      query = Sample.where(id: @sample_ids).pluck(:id, node).map do |results|
        { "#{results[0]}": { sample_id: results[0], samplesheet_params: { "#{@header}": results[1] } } }
      end
      # query is an array of hashes, and we'll merge them into an empty has to create a nested hash that can be merged
      # in samplesheet_controller.js
      {}.merge(*query)
    end

    # TODO: potential logic for when this controller can receive multiple headers in PR1338
    def retrieve_metadata(pluck_results)
      metadata_values = {}
      @metadata_fields.each.with_index(1) do |(header, _metadata_field), index|
        metadata_values[header] = pluck_results[index]
      end
    end
  end
end
