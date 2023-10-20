# frozen_string_literal: true

module Nextflow
  module Samplesheet
    class TextCellComponent < ViewComponent::Base
      attr_reader :name, :fields, :required

      def initialize(name, fields:, required: false)
        @name = name
        @fields = fields
        @required = required
      end
    end
  end
end
