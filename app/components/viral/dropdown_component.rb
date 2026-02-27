# frozen_string_literal: true

module Viral
  # Stable entrypoint for rendering a drop down across UI versions.
  class DropdownComponent < Versioning::VersionedComponent
    IMPLEMENTATIONS = {
      v1: Viral::Dropdown::V1::Component,
      v2: Viral::Dropdown::V2::Component
    }.freeze

    VERSION_RESOLVER = lambda {
      Flipper.enabled?(:beta_dropdown) ? :v2 : :v1
    }
  end
end
