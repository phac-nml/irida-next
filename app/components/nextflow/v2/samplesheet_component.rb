# frozen_string_literal: true

module Nextflow
  module V2
    # Render the contents of a Nextflow samplesheet to a table for feature flag :v2_samplesheet
    class SamplesheetComponent < Component
      attr_reader :properties, :required_properties, :metadata_fields, :namespace_id, :workflow_params, :sample_count

      def initialize(schema:, fields:, sample_count:, namespace_id:, workflow_params:)
        @namespace_id = namespace_id
        @sample_count = sample_count
        @metadata_fields = fields
        @workflow_params = workflow_params

        samplesheet_properties = Irida::Nextflow::Samplesheet::Properties.new(schema)
        @properties = samplesheet_properties.properties
        @required_properties = samplesheet_properties.required_properties
      end
    end
  end
end
