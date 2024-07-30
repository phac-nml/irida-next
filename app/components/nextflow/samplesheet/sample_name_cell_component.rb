# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Component to render a cell with the sample name into the sample sheet
    class SampleNameCellComponent < Component
      attr_reader :sample, :fields

      def initialize(sample:, fields:)
        @sample = sample
        @fields = fields
      end
    end
  end
end
