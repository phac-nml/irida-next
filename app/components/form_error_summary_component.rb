# frozen_string_literal: true

# Renders an accessible validation summary with linked field errors.
class FormErrorSummaryComponent < Component
  attr_reader :entries

  def initialize(entries:, **system_arguments)
    @entries = Array(entries)
    @system_arguments = system_arguments
  end

  def render?
    entries.any?
  end

  private

  attr_reader :system_arguments

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

  def announcement_text
    I18n.t('general.form.error_summary.announcement', count: entries.count)
  end

  def alert_system_arguments
    {
      type: :alert,
      dismissible: false,
      announce_alert: false,
      classes: class_names('mb-4', system_arguments[:classes])
    }
  end
end
