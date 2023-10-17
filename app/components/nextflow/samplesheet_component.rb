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

    def filter_files(sample, regex)
      names = sample.attachments.map { |a| a.file.filename.to_s }
      puts names
      puts regex
      names.select { |name| name.match?(/#{Regexp.new(regex)}/) }
    end
  end
end
