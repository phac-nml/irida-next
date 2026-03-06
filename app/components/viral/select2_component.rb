# frozen_string_literal: true

module Viral
  # Stable entrypoint for rendering a searchable drop down across UI versions.
  class Select2Component < Versioning::VersionedComponent
    IMPLEMENTATIONS = {
      v1: Viral::Select2::V1::Component
    }.freeze

    VERSION_RESOLVER = -> {}
  end
end
