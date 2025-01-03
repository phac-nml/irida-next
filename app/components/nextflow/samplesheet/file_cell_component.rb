module Nextflow
  module Samplesheet
    # Render a single cell of a Nextflow samplesheet for a property that requires a dropdown
    class FileCellComponent < Component
      attr_reader :name, :values, :selected, :fields, :required_properties, :data

      def initialize(sample, property, selected, index, required_properties, additional_params)
        @sample = sample
        @property = property
        @selected = selected
        @index = index
        @required_properties = required_properties
        @additional_params = additional_params
      end
    end
  end
end
