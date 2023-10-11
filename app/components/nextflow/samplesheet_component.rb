# frozen_string_literal: true

module Nextflow
  class SamplesheetComponent < Component
    def initialize(headers:, samples:)
      @headers = headers
      @samples = samples
    end
  end
end
