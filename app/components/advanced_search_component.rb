# frozen_string_literal: true

# Stable versioned entrypoint for rendering the advanced search component.
class AdvancedSearchComponent < Versioning::VersionedComponent
  IMPLEMENTATIONS = {
    v1: AdvancedSearch::V1::Component,
    v2: AdvancedSearch::V2::DialogComponent
  }.freeze

  VERSION_RESOLVER = lambda {
    Flipper.enabled?(:advanced_search_v2, Current.user) ? :v2 : :v1
  }
end
