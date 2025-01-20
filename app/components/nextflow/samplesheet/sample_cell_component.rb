# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Render a single cell of a Nextflow samplesheet for a given sample
    class SampleCellComponent < Component
      erb_template <<~ERB
              <div class="p-2.5 sticky left-0">
          <%= @sample_identifier %>
        </div>
      ERB

      def initialize(sample_identifier:)
        @sample_identifier = sample_identifier
      end
    end
  end
end
