# frozen_string_literal: true

class AdvancedSearchComponentPreview < ViewComponent::Preview
  def default # rubocop:disable Metrics/MethodLength
    search = Sample::Query.new(
      groups: [
        Sample::SearchGroup.new(
          conditions: [
            Sample::SearchCondition.new(field: 'metadata.country', operator: '=', value: 'Canada'),
            Sample::SearchCondition.new(field: 'metadata.collection_date', operator: '>=', value: '2024-01-01'),
            Sample::SearchCondition.new(field: 'metadata.collection_date', operator: '<=', value: '2024-12-01')
          ]
        ),
        Sample::SearchGroup.new(
          conditions: [
            Sample::SearchCondition.new(field: 'metadata.outbreak_code', operator: '=', value: '2406MLGX6-1')
          ]
        )
      ]
    )
    fields = AdvancedSearch::Fields.for_samples(
      sample_fields: %w[name puid created_at updated_at attachments_updated_at],
      metadata_fields: %w[age country collection_date food subject_type outbreak_code].sort
    )

    render_with_template(locals: {
                           search: search,
                           advanced_search_fields: fields
                         })
  end

  def empty
    search = Sample::Query.new
    fields = AdvancedSearch::Fields.for_samples(
      sample_fields: %w[name puid created_at updated_at attachments_updated_at],
      metadata_fields: %w[age country collection_date food subject_type outbreak_code].sort
    )

    render_with_template(template: 'advanced_search_component_preview/default', locals: {
                           search: search,
                           advanced_search_fields: fields
                         })
  end

  def workflow
    render_with_template(template: 'advanced_search_component_preview/default', locals: {
                           search: workflow_search,
                           advanced_search_fields: workflow_fields
                         })
  end

  private

  def workflow_search
    WorkflowExecution::Query.new(
      groups: [
        WorkflowExecution::SearchGroup.new(
          conditions: [
            WorkflowExecution::SearchCondition.new(field: 'state', operator: '=', value: 'completed'),
            WorkflowExecution::SearchCondition.new(field: 'metadata.pipeline_id', operator: '=', value: 'assembly')
          ]
        )
      ]
    )
  end

  def workflow_fields
    field_configuration = Struct.new(:fields).new(WorkflowExecution::FieldConfiguration::SEARCHABLE_FIELDS)
    AdvancedSearch::Fields.for_workflow_executions(field_configuration:)
  end
end
