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
    sample_fields = %w[name puid created_at updated_at attachments_updated_at]
    metadata_fields = %w[age country collection_date food subject_type outbreak_code]

    render_with_template(locals: {
                           search: search,
                           sample_fields: sample_fields,
                           metadata_fields: metadata_fields
                         })
  end

  def empty
    search = Sample::Query.new
    sample_fields = %w[name puid created_at updated_at attachments_updated_at]
    metadata_fields = %w[age country collection_date food subject_type outbreak_code]

    render_with_template(template: 'advanced_search_component_preview/default', locals: {
                           search: search,
                           sample_fields: sample_fields,
                           metadata_fields: metadata_fields
                         })
  end
end
