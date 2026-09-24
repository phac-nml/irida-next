# frozen_string_literal: true

# Validator for advanced search groups in Attachment queries.
class Attachment::AdvancedSearchGroupValidator < AdvancedSearch::GroupValidator # rubocop:disable Style/ClassAndModuleChildren
  private

  def allowed_fields
    Attachment::FieldConfiguration::SEARCHABLE_FIELDS.reject { |field| field.start_with?('metadata.') }
  end

  def date_fields
    %w[created_at]
  end
end
