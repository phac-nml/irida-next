# frozen_string_literal: true

module Samples
  # Stable entrypoint for rendering the samples table across UI versions.
  class TableComponent < Component
    include Versioning::VersionedComponent

    IMPLEMENTATIONS = {
      v1: Samples::Table::V1::Component,
      v2: Samples::Table::V2::Component
    }.freeze

    # rubocop:disable Metrics/ParameterLists
    def initialize(
      samples,
      namespace,
      pagy,
      version: nil,
      has_samples: true,
      abilities: {},
      metadata_fields: [],
      search_params: {},
      empty: {},
      **system_arguments
    )
      @samples = samples
      @namespace = namespace
      @pagy = pagy
      @version = version
      @has_samples = has_samples
      @abilities = abilities
      @metadata_fields = metadata_fields
      @search_params = search_params
      @empty = empty
      @system_arguments = system_arguments
    end
    # rubocop:enable Metrics/ParameterLists

    def call
      render resolved_component
    end

    private

    def resolved_component
      implementation_class.new(
        @samples,
        @namespace,
        @pagy,
        has_samples: @has_samples,
        abilities: @abilities,
        metadata_fields: @metadata_fields,
        search_params: @search_params,
        empty: @empty,
        **@system_arguments
      )
    end

    def implementation_class
      IMPLEMENTATIONS.fetch(resolved_version)
    end

    def resolved_version
      resolve_version(
        version: @version,
        valid_versions: IMPLEMENTATIONS.keys,
        default_version: :v1
      ) do
        Flipper.enabled?(:data_grid_samples_table) ? :v2 : :v1
      end
    end
  end
end
