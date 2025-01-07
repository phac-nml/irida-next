# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Render a single cell of a Nextflow samplesheet for a property that requires a file
    class FileCellComponent < Component
      attr_reader :attachable, :property, :selected, :index, :required_properties, :file_type, :file_selector_arguments

      # rubocop: disable Metrics/ParameterLists
      def initialize(attachable, property, selected, index, required_properties, file_type, **file_selector_arguments)
        @attachable = attachable
        @property = property
        @selected = selected
        @index = index
        @required_properties = required_properties
        @file_type = file_type
        @file_selector_arguments = file_selector_arguments
      end
      # rubocop: enable Metrics/ParameterLists
    end
  end
end
