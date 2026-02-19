# frozen_string_literal: true

# Validator for advanced search groups in WorkflowExecution queries.
class WorkflowExecution::AdvancedSearchGroupValidator < AdvancedSearch::GroupValidator # rubocop:disable Style/ClassAndModuleChildren
  private

  def allowed_fields
    WorkflowExecution::FieldConfiguration::SEARCHABLE_FIELDS.reject { |field| field.start_with?('metadata.') }
  end

  def date_fields
    %w[created_at updated_at]
  end
end
