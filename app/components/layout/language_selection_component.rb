# frozen_string_literal: true

module Layout
  # Stable entrypoint for rendering a language selection menu across UI versions.
  class LanguageSelectionComponent < Versioning::VersionedComponent
    IMPLEMENTATIONS = {
      v1: Layout::LanguageSelection::V1::Component
    }.freeze

    VERSION_RESOLVER = -> { :v1 }
  end
end
