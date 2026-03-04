# frozen_string_literal: true

module DataExports
  # Stable entrypoint for rendering the linelist export dialog across UI versions.
  class LinelistExportDialogComponent < ::Versioning::VersionedComponent
    IMPLEMENTATIONS = {
      v1: LinelistExportDialog::V1::Component,
      v2: LinelistExportDialog::V2::Component
    }.freeze

    VERSION_RESOLVER = lambda {
      :v2 if Flipper.enabled?(:client_linelist_exports_v1)
    }
  end
end
