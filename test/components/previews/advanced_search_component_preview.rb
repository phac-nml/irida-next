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
    fields = %w[name puid created_at updated_at attachments_updated_at metadata.age metadata.country
                metadata.collection_date metadata.food metadata.subject_type metadata.outbreak_code]
    operations = %w[= != <= >= contains exists not_exists in not_in]

    render_with_template(locals: {
                           search: search,
                           fields: fields,
                           operations: operations
                         })
  end

  def empty
    search = Sample::Query.new
    fields = %w[name puid created_at updated_at attachments_updated_at metadata.age metadata.country
                metadata.collection_date metadata.food metadata.subject_type metadata.outbreak_code]
    operations = %w[= != <= >= contains exists not_exists in not_in]

    render_with_template(template: 'advanced_search_component_preview/default', locals: {
                           search: search,
                           fields: fields,
                           operations: operations
                         })
  end
end
