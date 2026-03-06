# frozen_string_literal: true

# Stable entrypoint for rendering a combobox across UI versions.
class ComboboxComponent < Versioning::VersionedComponent
  IMPLEMENTATIONS = {
    v1: Combobox::V1::Component,
    v2: Combobox::V2::Component
  }.freeze

  VERSION_RESOLVER = lambda {
    Flipper.enabled?(:v2_combobox) ? :v2 : :v1
  }
end
