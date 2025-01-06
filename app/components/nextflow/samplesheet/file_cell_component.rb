module Nextflow
  module Samplesheet
    # Render a single cell of a Nextflow samplesheet for a property that requires a dropdown
    class FileCellComponent < Component
      attr_reader :name, :values, :selected, :fields, :required_properties, :data

      def initialize(sample, property, selected, index, required_properties, file_type, **file_selector_arguments)
        @sample = sample
        @property = property
        @selected = selected
        @index = index
        @required_properties = required_properties
        @file_type = file_type
        @file_selector_arguments = file_selector_arguments
      end
    end
  end
end
