module Nextflow
  module Samplesheet
    # Render a single cell of a Nextflow samplesheet for a property that requires a dropdown
    class FileCellComponent < Component
      attr_reader :name, :values, :selected, :fields, :required, :data

      def initialize(sample, namespace_id, name, values, selected, fields, required, data = {}) # rubocop:disable Metrics/ParameterLists
        @sample = sample
        @namespace_id = namespace_id
        @name = name
        @values = values
        @selected = selected
        @fields = fields
        @required = required
        @data = data
        puts 'hihihihii'
        puts @namespace
        puts @selected
        puts @selected.nil?
      end
    end
  end
end
