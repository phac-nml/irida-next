# frozen_string_literal: true

module Nextflow
  # Render the contents of a Nextflow samplesheet to a table
  class SamplesheetComponent < Component
    attr_reader :properties, :required, :samples

    def initialize(schema:, samples:)
      @samples = samples
      extract_properties(schema)
    end

    def extract_properties(schema)
      @properties = schema['items']['properties']
      @required = schema['items']['required']
    end

    def filter_files(sample, properties)
      names = sample.attachments.map { |a| a.file.filename.to_s }
      pattern = properties['pattern']
      pattern = properties['anyOf'].find { |p| p['pattern'].present? }['pattern'] if pattern.nil?
      names.grep(/#{Regexp.new(pattern.to_s)}/)
    end
  end
end
