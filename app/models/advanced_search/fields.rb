# frozen_string_literal: true

module AdvancedSearch
  ENUM_OPERATOR_VALUES = AdvancedSearch::OperatorCatalog.enum_operator_values

  # Operators allowed for fields that only accept numeric values (e.g. byte_size).
  NUMERIC_OPERATOR_VALUES = AdvancedSearch::OperatorCatalog.numeric_operator_values

  # Operators allowed for non-metadata date fields (e.g. created_at, updated_at).
  DATE_OPERATOR_VALUES = AdvancedSearch::OperatorCatalog.date_operator_values

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
      def build(options:, groups: {}, enum_fields: {}, numeric_fields: [], date_fields: [])
        {
          options: Array(options),
          groups: groups || {},
          enum_fields:,
          numeric_fields: Array(numeric_fields),
          date_fields: Array(date_fields)
        }
      end

      def for_attachments(field_configuration: Attachment::FieldConfiguration)
        metadata_fields = field_configuration::SEARCHABLE_FIELDS.select { |field| field.start_with?('metadata.') }
        base_fields = field_configuration::SEARCHABLE_FIELDS - metadata_fields

        options = Array(base_fields).map do |field|
          [I18n.t("components.attachments.table_component.#{field}", default: field.to_s.humanize), field]
        end

        metadata_options = Array(metadata_fields).map do |field|
          field_name = field.delete_prefix('metadata.')
          [I18n.t("components.attachments.table_component.#{field_name}", default: field_name.humanize), field]
        end

        build(options:, groups: metadata_group(metadata_options), numeric_fields: field_configuration::NUMERIC_FIELDS,
              date_fields: date_fields_for(base_fields))
      end

      def for_samples(sample_fields:, metadata_fields:)
        options = Array(sample_fields).map do |field|
          [I18n.t("samples.table_component.#{field}", default: field.to_s.humanize), field]
        end

        metadata_options = Array(metadata_fields).map do |field|
          [field, "metadata.#{field}"]
        end

        build(options:, groups: metadata_group(metadata_options), date_fields: date_fields_for(sample_fields))
      end

      def for_workflow_executions(field_configuration: WorkflowExecution::FieldConfiguration.new)
        metadata_fields = field_configuration.fields.select { |field| field.start_with?('metadata.') }
        base_fields = field_configuration.fields - metadata_fields

        options = base_fields.map { |field| [workflow_field_label(field), field] }
        metadata_options = metadata_fields.map { |field| [workflow_field_label(field), field] }

        build(options:, groups: metadata_group(metadata_options),
              enum_fields: normalized_enum_fields(field_configuration), date_fields: date_fields_for(base_fields))
      end

      private

      # Fields follow the convention of ending in `_at` for timestamp columns (e.g. created_at, updated_at).
      def date_fields_for(fields)
        Array(fields).select { |field| field.to_s.end_with?('_at') }
      end

      def normalized_enum_fields(field_configuration)
        return {} unless field_configuration.respond_to?(:enum_fields)

        field_configuration.enum_fields.to_h
      end

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
