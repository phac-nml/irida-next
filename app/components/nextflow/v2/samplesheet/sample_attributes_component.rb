# frozen_string_literal: true

module Nextflow
  module V2
    module Samplesheet
      # Accepts samples and the samplesheet properties and processes the sample properties for samplesheet/workflow
      # submission, then forwards data to javascript/nextflow/samplesheet_controller.js
      class SampleAttributesComponent < Component
        attr_reader :properties, :samples, :sample_attributes

        def initialize(samples:, properties:, allowed_to_update_samples: true)
          @samples = samples
          @properties = properties
          @allowed_to_update_samples = allowed_to_update_samples
          @sample_attributes = Irida::Nextflow::Samplesheet::SampleAttributes.new(
            samples: samples,
            properties: properties
          )
        end

        delegate :samples_workflow_executions_attributes, to: :sample_attributes

        delegate :file_attributes, to: :sample_attributes
      end
    end
  end
end
