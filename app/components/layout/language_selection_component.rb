# frozen_string_literal: true

module Layout
  # Stable entrypoint for rendering a language selection menu across UI versions.
  class LanguageSelectionComponent < Versioning::VersionedComponent
    IMPLEMENTATIONS = {
      v1: Layout::LanguageSelection::V1::Component,
      v2: Layout::LanguageSelection::V2::Component
    }.freeze

    VERSION_RESOLVER = lambda {
      Flipper.enabled?(:v2_language_selection, Current.user) ? :v2 : :v1
    }
  end
end
