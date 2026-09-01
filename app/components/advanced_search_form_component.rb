# frozen_string_literal: true

# Stable versioned entrypoint for rendering the advanced search form component.
class AdvancedSearchFormComponent < Versioning::VersionedComponent
  IMPLEMENTATIONS = {
    v1: AdvancedSearchForm::V1::Component
  }.freeze

  VERSION_RESOLVER = lambda {
    :v1
  }
end
