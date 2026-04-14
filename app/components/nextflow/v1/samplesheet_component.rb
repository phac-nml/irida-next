# frozen_string_literal: true

module Nextflow
  module V1
    # Render the contents of a Nextflow samplesheet to a table
    class SamplesheetComponent < Component
      attr_reader :properties, :samples, :required_properties, :metadata_fields, :namespace_id, :workflow_params,
                  :sample_attributes

      def initialize(schema:, samples:, fields:, namespace_id:, workflow_params:)
        @samples = samples
        @namespace_id = namespace_id
        @metadata_fields = fields
        @workflow_params = workflow_params

        samplesheet_properties = ::Irida::Nextflow::Samplesheet::Properties.new(schema)
        @properties = samplesheet_properties.properties
        @required_properties = samplesheet_properties.required_properties
        @sample_attributes = ::Irida::Nextflow::Samplesheet::SampleAttributes.new(samples: samples,
                                                                                  properties: @properties)
      end

      def samples_workflow_executions_attributes
        sample_attributes.samples_workflow_executions_attributes.values.each_with_index.to_h do |attributes, index|
          [index, adapt_v1_samplesheet_attributes(attributes)]
        end
      end

      private

      def adapt_v1_samplesheet_attributes(attributes)
        {
          'sample_id' => attributes['sample_id'],
          'samplesheet_params' => adapt_v1_samplesheet_params(attributes['samplesheet_params'], attributes['sample_id'])
        }
      end

      def adapt_v1_samplesheet_params(raw_params, sample_id)
        raw_params.to_h do |name, value|
          if file_column?(name)
            [name, adapt_v1_file_value(sample_id, name, value)]
          else
            [name, { form_value: value }]
          end
        end
      end

      def file_column?(name)
        %w[file_cell fastq_cell].include?(@properties[name]['cell_type'])
      end

      def adapt_v1_file_value(sample_id, name, value)
        file_data = sample_attributes.file_attributes.dig(sample_id, name) || {}

        {
          form_value: value,
          filename:
            file_data[:filename] || I18n.t('components.nextflow.samplesheet.file_cell_component.no_selected_file'),
          attachment_id: file_data[:attachment_id] || ''
        }
      end
    end
  end
end
