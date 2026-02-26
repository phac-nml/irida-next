# frozen_string_literal: true

# Stable versioned entrypoint for rendering the datepicker component.
class DatepickerComponent < Component
  include Versioning::VersionedComponent

  IMPLEMENTATIONS = {
    v1: Datepicker::V1::Component
  }.freeze

  # rubocop:disable Metrics/ParameterLists
  def initialize(
    id:,
    input_name:,
    version: nil,
    label: nil,
    input_aria_label: nil,
    min_date: 1.day.from_now,
    selected_date: nil,
    autosubmit: false,
    calendar_arguments: {},
    **system_arguments
  )
    @version = version
    @id = id
    @input_name = input_name
    @label = label
    @input_aria_label = input_aria_label
    @min_date = min_date
    @selected_date = selected_date
    @autosubmit = autosubmit
    @calendar_arguments = calendar_arguments
    @system_arguments = system_arguments
  end
  # rubocop:enable Metrics/ParameterLists

  def call
    render resolved_component
  end

  private

  def resolved_component
    implementation_class.new(
      id: @id,
      input_name: @input_name,
      label: @label,
      input_aria_label: @input_aria_label,
      min_date: @min_date,
      selected_date: @selected_date,
      autosubmit: @autosubmit,
      calendar_arguments: @calendar_arguments,
      **@system_arguments
    )
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
