# frozen_string_literal: true

# Stable versioned entrypoint for rendering the datepicker component.
class DatepickerComponent < Versioning::VersionedComponent
  IMPLEMENTATIONS = {
    v1: Datepicker::V1::Component
  }.freeze

  VERSION_RESOLVER = -> {}
end
