# frozen_string_literal: true

# Stable entrypoint for rendering a combobox across UI versions.
class ComboboxComponent < Versioning::VersionedComponent
  IMPLEMENTATIONS = {
    v1: Combobox::V1::Component
  }.freeze

  VERSION_RESOLVER = -> {}
end
