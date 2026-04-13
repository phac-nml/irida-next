# frozen_string_literal: true

# Stable versioned entrypoint for rendering the datepicker component.
class DatepickerComponent < Versioning::VersionedComponent
  IMPLEMENTATIONS = {
    v1: Datepicker::V1::Component,
    v2: Datepicker::V2::Component
  }.freeze

  VERSION_RESOLVER = lambda {
    Flipper.enabled?(:v2_datepicker, Current.user) ? :v2 : :v1
  }
end
