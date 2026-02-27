# frozen_string_literal: true

module Samples
  # Stable entrypoint for rendering the samples table across UI versions.
  class TableComponent < ::Versioning::VersionedComponent
    IMPLEMENTATIONS = {
      v1: Samples::Table::V1::Component,
      v2: Samples::Table::V2::Component
    }.freeze

    VERSION_RESOLVER = lambda {
      :v2 if Flipper.enabled?(:data_grid_samples_table)
    }
  end
end
