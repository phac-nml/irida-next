# frozen_string_literal: true

# Stable versioned entrypoint for rendering the advanced search component.
class AdvancedSearchComponent < Versioning::VersionedComponent
  IMPLEMENTATIONS = {
    v1: AdvancedSearch::V1::Component
  }.freeze

  VERSION_RESOLVER = -> {}
end
