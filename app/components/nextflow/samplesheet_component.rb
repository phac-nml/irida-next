# frozen_string_literal: true

module Nextflow
  class SamplesheetComponent < Component
    def initialize(samplesheet:)
      @samplesheet = samplesheet
    end
  end
end
