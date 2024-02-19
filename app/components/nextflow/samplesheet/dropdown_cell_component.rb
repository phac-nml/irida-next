# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Render a single cell of a Nextflow samplesheet for a property that requires a dropdown
    class DropdownCellComponent < Component
      attr_reader :name, :values, :fields, :required

      def initialize(name, values, fields, required)
        @name = name
        @values = values
        @fields = fields
        @required = required
      end
    end
  end
end
