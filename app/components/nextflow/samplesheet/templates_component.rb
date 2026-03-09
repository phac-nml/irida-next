# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # renders all the nextflow templates so they're all in one centralized location rather than spread throughout
    # the DOM trying to keep templates in scope of stimulus controllers after splitting samplesheet controller logic
    class TemplatesComponent < Component
      attr_reader :namespace_id

      def initialize(namespace_id:)
        @namespace_id = namespace_id
      end
    end
  end
end
