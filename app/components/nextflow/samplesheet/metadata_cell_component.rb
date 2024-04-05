# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Component to render a cell with sample metadata into the sample sheet
    class MetadataCellComponent < ViewComponent::Base
      attr_reader :form, :metadata, :name

      def initialize(form:, name:, sample:, entry:)
        @form = form
        @name = name
        @metadata = sample_metadata(entry, sample)
      end

      def sample_metadata(entry, sample)
        key = entry['meta'].is_a?(Array) ? entry['meta'][0].to_s : entry['meta'].to_s
        sample.metadata.key?(key) ? sample.metadata[key] : ''
      end
    end
  end
end
