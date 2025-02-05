# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Renders a header in the sample sheet table
    class HeaderComponent < Component
      attr_reader :namespace_id, :header, :property, :samples, :metadata_fields, :required_properties, :workflow_params

      # rubocop:disable Metrics/ParameterLists
      def initialize(namespace_id:, header:, property:, samples:, metadata_fields:, required_properties:,
                     workflow_params:)
        @namespace_id = namespace_id
        @header = header
        @property = property
        @samples = samples
        @metadata_fields = metadata_fields
        @required_properties = required_properties
        @workflow_params = workflow_params
      end

      # rubocop:enable Metrics/ParameterLists

      private

      def metadata_fields_for_field(field)
        options = @metadata_fields.include?(field) ? @metadata_fields : @metadata_fields.unshift(field)
        label = t('.default', label: field)
        options.map { |f| [f.eql?(field) ? label : f, f] }
      end
    end
  end
end
