# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Component to render a cell with sample metadata into the sample sheet
    class MetadataCellComponent < ViewComponent::Base
      attr_reader :form, :metadata, :name, :sample

      def initialize(form:, name:, sample:, entry:)
        @form = form
        @name = name
        @sample = sample
        @metadata = metadata_value(sample, entry)
      end

      def metadata_value(sample, entry)
        sample.metadata.key?(entry['meta']) ? sample.metadata[entry['meta']] : ''
      end
    end
  end
end
