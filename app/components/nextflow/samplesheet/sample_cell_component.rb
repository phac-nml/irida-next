# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Render a single cell of a Nextflow samplesheet for a given sample
    class SampleCellComponent < Component
      attr_reader :sample, :fields

      def initialize(sample:, fields:)
        @sample = sample
        @fields = fields
      end
    end
  end
end
