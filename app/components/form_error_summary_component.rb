# frozen_string_literal: true

# Renders an accessible validation summary with linked field errors.
class FormErrorSummaryComponent < Component
  def initialize(entries:, include: nil, **system_arguments)
    @entries_all = Array(entries)
    @include_attributes =
      Array(include).compact_blank.map { |a| a.to_s.delete_suffix('_id') }.uniq
    @system_arguments = system_arguments
  end

  def render?
    entries.any?
  end

  def entries
    return entries_all if include_attributes.blank?

    entries_all.select do |entry|
      include_attributes.include?(entry.attribute.to_s.delete_suffix('_id'))
    end
  end

  private

  attr_reader :entries_all, :include_attributes, :system_arguments

  def heading_id
    @heading_id ||= "form-error-summary-heading-#{object_id}"
  end

  def description_id
    @description_id ||= "form-error-summary-description-#{object_id}"
  end

  def title_text
    I18n.t('general.form.error_summary.title', count: entries.count)
  end

  def description_text
    I18n.t('general.form.error_notification')
  end

  def alert_system_arguments
    system_arguments.except(:classes).merge(
      type: :alert,
      dismissible: false,
      announce_alert: false,
      classes: class_names(
        'mb-4 outline-hidden focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-red-600',
        system_arguments[:classes]
      )
    )
  end
end
