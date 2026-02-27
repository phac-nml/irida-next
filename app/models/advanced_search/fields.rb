# frozen_string_literal: true

module AdvancedSearch
  # Builds field option payloads for advanced-search UI rendering.
  class Fields
    WORKFLOW_FIELD_LABELS = {
      'id' => 'workflow_executions.table_component.id',
      'name' => 'activerecord.attributes.workflow_execution.name',
      'run_id' => 'workflow_executions.table_component.run_id',
      'state' => 'workflow_executions.table_component.state',
      'created_at' => 'workflow_executions.table_component.created_at',
      'updated_at' => 'workflow_executions.table_component.updated_at',
      'metadata.pipeline_id' => 'workflow_executions.table_component.workflow_name',
      'metadata.workflow_version' => 'workflow_executions.table_component.workflow_version'
    }.freeze

    class << self
      def build(options:, groups: {})
        {
          options: Array(options),
          groups: groups || {}
        }
      end

      def for_samples(sample_fields:, metadata_fields:)
        options = Array(sample_fields).map do |field|
          [I18n.t("samples.table_component.#{field}", default: field.to_s.humanize), field]
        end

        metadata_options = Array(metadata_fields).map do |field|
          [field, "metadata.#{field}"]
        end

        build(options:, groups: metadata_group(metadata_options))
      end

      def for_workflow_executions(field_configuration: WorkflowExecution::FieldConfiguration.new)
        metadata_fields = field_configuration.fields.select { |field| field.start_with?('metadata.') }
        base_fields = field_configuration.fields - metadata_fields

        options = base_fields.map { |field| [workflow_field_label(field), field] }
        metadata_options = metadata_fields.map { |field| [workflow_field_label(field), field] }

        build(options:, groups: metadata_group(metadata_options))
      end

      private

      def metadata_group(metadata_options)
        return {} if metadata_options.empty?

        { I18n.t('components.advanced_search_component.operation.metadata_fields') => metadata_options }
      end

      def workflow_field_label(field)
        I18n.t(WORKFLOW_FIELD_LABELS[field], default: field.to_s.humanize)
      end
    end
  end
end
