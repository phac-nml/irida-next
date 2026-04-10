# frozen_string_literal: true

# Stable entrypoint for rendering a searchable drop down across UI versions.
class Select2Component < Versioning::VersionedComponent
  IMPLEMENTATIONS = {
    v1: Select2::V1::Component,
    v2: Select2::V2::Component
  }.freeze

  VERSION_RESOLVER = lambda {
    Flipper.enabled?(:v2_select2, Current.user) ? :v2 : :v1
  }
end
