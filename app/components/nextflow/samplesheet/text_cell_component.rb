# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Render a single cell of a Nextflow samplesheet for a property that requires a text input
    class TextCellComponent < ViewComponent::Base
      attr_reader :name, :fields

      def initialize(name, fields:)
        @name = name
        @fields = fields
      end
    end
  end
end
