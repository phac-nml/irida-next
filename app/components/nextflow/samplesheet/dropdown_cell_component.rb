# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Render a single cell of a Nextflow samplesheet for a property that requires a dropdown
    class DropdownCellComponent < Component
      attr_reader :name, :values, :fields, :prompt, :primary

      def initialize(name, values, fields, prompt, primary)
        @name = name
        @values = values
        @fields = fields
        @prompt = prompt
        @primary = primary
      end
    end
  end
end
