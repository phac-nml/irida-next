# frozen_string_literal: true

module Nextflow
  module Samplesheet
    class DropdownCellComponent < Component
      attr_reader :name, :values, :fields, :prompt, :required

      def initialize(name, values, fields:, prompt: nil, required: false)
        @name = name
        @values = values
        @fields = fields
        @prompt = prompt
        @required = required
      end
    end
  end
end
