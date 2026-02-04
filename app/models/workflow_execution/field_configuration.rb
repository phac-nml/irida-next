# frozen_string_literal: true

class WorkflowExecution
  # Configuration class for workflow execution advanced search fields.
  #
  # Encapsulates the logic for determining which fields are searchable,
  # which fields are enum types, and how to label enum values.
  #
  # @example Basic usage
  #   config = WorkflowExecution::FieldConfiguration.new
  #   config.fields        # => ['id', 'name', 'run_id', ...]
  #   config.enum_fields   # => { 'state' => { values: [...], ... }, ... }
  class FieldConfiguration
    # List of searchable fields for workflow executions.
    SEARCHABLE_FIELDS = %w[
      id
      name
      run_id
      state
      created_at
      updated_at
      metadata.pipeline_id
      metadata.workflow_version
    ].freeze

    # Initializes the field configuration.
    #
    # @param pipelines [Array<Pipeline>] optional list of available pipelines
    #   If not provided, fetches from Irida::Pipelines.instance
    def initialize(pipelines: nil)
      @pipelines = pipelines || fetch_available_pipelines
    end

    # Returns the list of searchable field names.
    #
    # @return [Array<String>] field names
    def fields
      SEARCHABLE_FIELDS.dup
    end

    # Returns enum field configurations for select dropdowns.
    #
    # @return [Hash{String => Hash}] configuration for each enum field
    #   - :values [Array<String>] valid values for the enum
    #   - :labels [Hash, nil] optional mapping of values to display labels
    #   - :translation_key [String, nil] I18n key prefix for translating values
    def enum_fields
      {
        'state' => state_config,
        'metadata.pipeline_id' => pipeline_id_config,
        'metadata.workflow_version' => workflow_version_config
      }
    end

    private

    # Fetches available pipelines from the Irida::Pipelines singleton.
    #
    # @return [Array<Pipeline>] list of available pipelines
    def fetch_available_pipelines
      Irida::Pipelines.instance.pipelines('available').values
    end

    # Configuration for the state enum field.
    #
    # @return [Hash] enum configuration
    def state_config
      {
        values: WorkflowExecution.states.keys,
        labels: nil,
        translation_key: 'workflow_executions.state'
      }
    end

    # Configuration for the pipeline_id (workflow name) enum field.
    #
    # @return [Hash] enum configuration with pipeline labels
    def pipeline_id_config
      labels = build_pipeline_labels
      {
        values: labels.keys.uniq,
        labels: labels,
        translation_key: nil
      }
    end

    # Configuration for the workflow_version enum field.
    #
    # @return [Hash] enum configuration with version labels
    def workflow_version_config
      labels = build_version_labels
      {
        values: labels.keys.uniq,
        labels: labels,
        translation_key: nil
      }
    end

    # Builds a hash mapping pipeline IDs to display names.
    #
    # @return [Hash{String => String}] pipeline_id => display_name
    def build_pipeline_labels
      @pipelines.each_with_object({}) do |pipeline, hash|
        next if pipeline.pipeline_id.blank?

        hash[pipeline.pipeline_id] = pipeline.name.presence || pipeline.pipeline_id
      end
    end

    # Builds a hash mapping version strings to display labels.
    #
    # @return [Hash{String => String}] version => display_label
    def build_version_labels
      @pipelines.each_with_object({}) do |pipeline, hash|
        next if pipeline.version.blank?

        hash[pipeline.version] = pipeline.version
      end
    end
  end
end
