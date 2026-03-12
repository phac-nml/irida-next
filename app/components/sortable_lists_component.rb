# frozen_string_literal: true

# Stable entrypoint for rendering sortable lists across UI versions.
class SortableListsComponent < Versioning::VersionedComponent
  IMPLEMENTATIONS = {
    v1: SortableLists::V1::Component
  }.freeze

  VERSION_RESOLVER = -> { :v1 }
end
