# frozen_string_literal: true

module Layout
  # Stable entrypoint for rendering a sidebar across UI versions.
  class SidebarComponent < Versioning::VersionedComponent
    IMPLEMENTATIONS = {
      v1: Layout::Sidebar::V1::Component
    }.freeze

    VERSION_RESOLVER = -> { :v1 }
  end
end
