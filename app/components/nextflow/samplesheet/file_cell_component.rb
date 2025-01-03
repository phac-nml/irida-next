# frozen_string_literal: true

module Nextflow
  module Samplesheet
    # Render a single cell of a Nextflow samplesheet for a property that requires a dropdown
    class FileCellComponent < Component
      attr_reader :name, :values, :selected, :fields, :required, :data

      def initialize(name, values, selected, fields, required, data) # rubocop:disable Metrics/ParameterLists
        @name = name
        @values = values
        @selected = test(selected)
        # if selected.present?
        #   selected_index = @values.find_index(selected)
        #   if @values[selected_index].length == 3
        #     @values[selected_index][2] = @values[selected_index][2].merge({ selected: true })
        #   else
        #     @values[selected_index] << { selected: true }
        #   end
        # end
        @fields = fields
        @required = required
        @data = data
      end

      def test(selected)
        puts selected
        puts 'hihiihi'
        selected || {}
      end
    end
  end
end
