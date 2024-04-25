# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Component to render a cell with sample metadata into the sample sheet
    class MetadataCellComponent < ViewComponent::Base
      attr_reader :form, :metadata, :name, :sample

      def initialize(form:, name:, sample:, field: nil)
        @form = form
        @name = name
        @sample = sample
        @metadata = metadata_value(field || name)
      end

      def metadata_value(name)
        sample.metadata.key?(name) ? sample.metadata[name] : ''
      end
    end
  end
end
