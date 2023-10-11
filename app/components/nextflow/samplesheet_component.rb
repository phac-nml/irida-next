# frozen_string_literal: true

module Nextflow
  # Render the contents of a Nextflow samplesheet to a table
  class SamplesheetComponent < Component
    def initialize(headers:, samples:)
      @headers = headers
      @samples = samples
    end
  end
end
