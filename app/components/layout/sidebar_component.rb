# frozen_string_literal: true

module Layout
  # Stable entrypoint for rendering a language selection menu across UI versions.
  class SidebarComponent < Versioning::VersionedComponent
    IMPLEMENTATIONS = {
      v1: Layout::Sidebar::V1::Component,
      v2: Layout::Sidebar::V2::Component
    }.freeze

    VERSION_RESOLVER = lambda {
      Flipper.enabled?(:v2_sidebar, Current.user) ? :v2 : :v1
    }
  end
end
