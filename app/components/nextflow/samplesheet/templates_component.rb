# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Accepts samples and the samplesheet properties and processes the sample properties for samplesheet/workflow
    # submission, then forwards data to javascript/nextflow/samplesheet_controller.js
    class TemplatesComponent < Component
      attr_reader :properties, :samples

      def initialize(namespace_id:)
        @namespace_id = namespace_id
      end
    end
  end
end
