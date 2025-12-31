# frozen_string_literal: true

module WorkflowExecutions
  # Controller for metadata actions within a workflow execution
  class MetadataController < ApplicationController
    respond_to :turbo_stream

    def fields
      @header = params[:header]
      @field = params[:field]
      @metadata = generate_metadata_for_samplesheet.to_json
      render status: :ok
    end

    private

    def generate_metadata_for_samplesheet
      sample_ids = params[:sample_ids].split(',')
      node = Arel::Nodes::InfixOperation.new('->>', Sample.arel_table[:metadata], Arel::Nodes::Quoted.new(@field))
      query = Sample.where(id: sample_ids).pluck(:id, node).map do |results|
        { "#{results[0]}": { sample_id: results[0], samplesheet_params: { "#{@header}": results[1] } } }
      end

      # query is an array of hashes, and we'll merge them into an empty has to create a nested hash that can be merged
      # in samplesheet_controller.js
      {}.merge(*query)

      # TODO: potential logic for when this controller can receive multiple headers in PR1338
      # fields_to_query = [:id]

      # @metadata_fields.each_value do |metadata_field|
      #   fields_to_query.append(Arel::Nodes::InfixOperation.new('->>', Sample.arel_table[:metadata], Arel::Nodes::Quoted.new(metadata_field)))
      # end

      # Sample.where(id: params[:sample_ids]).pluck(fields_to_query).map do |results|
      #   { "#{results[0]}": { sample_id: results[0], samplesheet_params: retrieve_metadata(results) } }
      # end
      #
    end

    # TODO: potential logic for when this controller can receive multiple headers in PR1338
    # def retrieve_metadata(pluck_results)
    #   metadata_values = {}
    #   @metadata_fields.each.with_index(1) do |(header, _metadata_field), index|
    #     metadata_values[header] = pluck_results[index]
    #   end
    # end
  end
end
