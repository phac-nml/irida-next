# frozen_string_literal: true

# Builds one linked summary entry per invalid form attribute.
class FormErrorSummaryEntryBuilder
  Entry = Data.define(:attribute, :message, :target_id) do
    def href
      "##{target_id}"
    end
  end

  def initialize(builder:, errors: builder.object&.errors, target_overrides: {})
    @builder = builder
    @errors = errors
    @target_overrides = target_overrides.to_h.transform_keys(&:to_s)
  end

  def call
    return [] unless errors&.any?

    errors.attribute_names.uniq.filter_map do |attribute|
      next if attribute == :base

      message = errors.full_messages_for(attribute).to_sentence
      target_id = target_id_for(attribute)
      next if message.blank? || target_id.blank?

      Entry.new(attribute:, message:, target_id:)
    end
  end

  private

  attr_reader :builder, :errors, :target_overrides

  def target_id_for(attribute)
    target_overrides.fetch(attribute.to_s) do
      builder.field_id(attribute)
    end
  end
end
