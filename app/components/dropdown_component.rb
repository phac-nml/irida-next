# frozen_string_literal: true

# Stable entrypoint for rendering a drop down across UI versions.
class DropdownComponent < Versioning::VersionedComponent
  IMPLEMENTATIONS = {
    v1: Dropdown::V1::Component,
    v2: Dropdown::V2::Component
  }.freeze

  VERSION_RESOLVER = lambda {
    Flipper.enabled?(:v2_dropdown, Current.user) ? :v2 : :v1
  }
end
