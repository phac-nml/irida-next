# frozen_string_literal: true

module Nextflow
  module Samplesheet
    class MetadataCellComponent < ViewComponent::Base
      attr_reader :metadata

      def initialize(sample:, entry:)
        @metadata = if entry['meta'].is_a?(Array)
                      entry['meta'].map { |meta| sample.metadata[meta].to_s }.join(', ')
                    else
                      sample.metadata[entry['meta']].to_s
                    end
      end
    end
  end
end
