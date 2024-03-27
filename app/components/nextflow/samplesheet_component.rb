# frozen_string_literal: true

module Nextflow
  # Render the contents of a Nextflow samplesheet to a table
  class SamplesheetComponent < Component
    attr_reader :properties, :samples, :required_properties

    def initialize(schema:, samples:)
      @samples = samples
      @required_properties = schema['items']['required']
      extract_properties(schema)
    end

    def extract_properties(schema)
      @properties = schema['items']['properties']
      @properties.each_key do |property|
        @properties[property]['required'] = schema['items']['required'].include?(property)
      end
    end
  end
end
