# frozen_string_literal: true

class AdvancedSearchComponentPreview < ViewComponent::Preview
  def default # rubocop:disable Metrics/MethodLength
    search = Sample::Search.new(
      groups: [
        Sample::Group.new(
          conditions: [
            Sample::Condition.new(field: 'metadata.country', operator: '=', value: 'Canada'),
            Sample::Condition.new(field: 'metadata.collection_date', operator: '>=', value: '2024-01-01'),
            Sample::Condition.new(field: 'metadata.collection_date', operator: '<=', value: '2024-12-01')
          ]
        ),
        Sample::Group.new(
          conditions: [
            Sample::Condition.new(field: 'metadata.outbreak_code', operator: '=', value: '2406MLGX6-1')
          ]
        )
      ]
    )
    fields = %w[name puid created_at updated_at attachments_updated_at metadata.age metadata.country
                metadata.collection_date metadata.food metadata.subject_type metadata.outbreak_code]
    operations = %w[= != <= >= contains]

    render_with_template(locals: {
                           search: search,
                           fields: fields,
                           operations: operations
                         })
  end
end
