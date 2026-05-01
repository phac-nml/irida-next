# frozen_string_literal: true

# Helper for rendering a reusable, linked validation summary at the top of model-backed forms.
module FormErrorSummaryHelper
  # Place this near the top of a model-backed form.
  # When migrating an existing form, remove invalid-only autofocus from the target fields so the
  # summary remains the first focus target after a failed submit.
  def form_error_summary(builder, target_overrides: {}, attribute_overrides: {}, **system_arguments)
    entries = FormErrorSummaryEntryBuilder.new(
      builder:,
      target_overrides:,
      attribute_overrides:
    ).call
    return if entries.blank?

    render FormErrorSummaryComponent.new(entries:, **system_arguments)
  end
end
