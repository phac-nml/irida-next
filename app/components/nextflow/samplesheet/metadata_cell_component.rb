# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Component to render a cell with sample metadata into the sample sheet
    class MetadataCellComponent < ViewComponent::Base
      attr_reader :form, :metadata

      def initialize(form:, sample:, entry:)
        @form = form
        @metadata = if entry['meta'].is_a?(Array)
                      entry['meta'].map { |meta| sample.metadata[meta].to_s }.join(', ')
                    else
                      sample.metadata[entry['meta']].to_s
                    end
      end
    end
  end
end
