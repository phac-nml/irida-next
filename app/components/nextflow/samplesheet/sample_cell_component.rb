# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Render a single cell of a Nextflow samplesheet for a given sample
    class SampleCellComponent < Component
      def initialize(sample_identifier:)
        @sample_identifier = sample_identifier
      end
    end
  end
end
