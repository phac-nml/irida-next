# frozen_string_literal: true

# Stable versioned entrypoint for rendering the datepicker component.
class ComboboxDatepickerComponent < Versioning::VersionedComponent
  IMPLEMENTATIONS = {
    v1: ComboboxDatepicker::V1::Component
  }.freeze

  VERSION_RESOLVER = -> { :v1 }
end
