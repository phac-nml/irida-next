module Nextflow
  module Samplesheet
    # Render a single cell of a Nextflow samplesheet for a property that requires a dropdown
    class FileCellComponent < Component
      attr_reader :name, :values, :selected, :fields, :required, :data

      def initialize(sample, name, selected, index, required)
        @sample = sample
        @name = name
        @selected = selected
        @index = index
        @required = required
      end
    end
  end
end
