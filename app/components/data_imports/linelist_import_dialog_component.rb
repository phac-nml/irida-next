# frozen_string_literal: true

module DataImports
  # Stable entrypoint for rendering the linelist import dialog across UI versions.
  class LinelistImportDialogComponent < ::Versioning::VersionedComponent
    IMPLEMENTATIONS = {
      v1: LinelistImportDialog::V1::Component,
      v2: LinelistImportDialog::V2::Component
    }.freeze

    VERSION_RESOLVER = lambda {
      :v2 if Flipper.enabled?(:client_linelist_imports_v1, Current.user)
    }
  end
end
