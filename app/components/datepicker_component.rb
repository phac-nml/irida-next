# frozen_string_literal: true

# Stable versioned entrypoint for rendering the datepicker component.
class DatepickerComponent < Component
  include Versioning::VersionedComponent

  IMPLEMENTATIONS = {
    v1: Datepicker::V1::Component
  }.freeze

  def initialize(version: nil, **args)
    @version = version
    @args = args
  end

  def call
    render resolved_component
  end

  private

  def resolved_component
    implementation_class.new(**@args)
  end

  def implementation_class
    IMPLEMENTATIONS.fetch(resolved_version)
  end

  def resolved_version
    resolve_version(
      version: @version,
      valid_versions: IMPLEMENTATIONS.keys,
      default_version: :v1
    ) { :v1 }
  end
end
