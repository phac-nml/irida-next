# frozen_string_literal: true

class AdvancedSearchComponentPreview < ViewComponent::Preview
  def with_group_condition_buttons # rubocop:disable Metrics/MethodLength
    search = Sample::Search.new(
      groups: [
        Sample::Group.new(
          conditions: [
            Sample::Condition.new(field: 'puid', operator: '!=', value: 'test me'),
            Sample::Condition.new(field: 'name', operator: '=', value: 'test me again')
          ]
        ),
        Sample::Group.new(
          conditions: [
            Sample::Condition.new(field: 'puid', operator: '!=', value: 'test me'),
            Sample::Condition.new(field: 'name', operator: '=', value: 'test me again')
          ]
        )
      ]
    )
    fields = %w[name puid created_at updated_at attachments_updated_at metadata.country metadata.collection_date
                metadata.subject_type metadata.outbreak_code]
    operations = %w[= != <= >= < > contains]

    render_with_template(locals: {
                           search: search,
                           fields: fields,
                           operations: operations
                         })
  end

  def with_or_and_buttons # rubocop:disable Metrics/MethodLength
    search = Sample::Search.new(
      groups: [
        Sample::Group.new(
          conditions: [
            Sample::Condition.new(field: 'puid', operator: '!=', value: 'test me'),
            Sample::Condition.new(field: 'name', operator: '=', value: 'test me again')
          ]
        ),
        Sample::Group.new(
          conditions: [
            Sample::Condition.new(field: 'puid', operator: '!=', value: 'test me'),
            Sample::Condition.new(field: 'name', operator: '=', value: 'test me again')
          ]
        )
      ]
    )
    fields = %w[name puid created_at updated_at attachments_updated_at metadata.country metadata.collection_date
                metadata.subject_type metadata.outbreak_code]
    operations = %w[= != <= >= < > contains]

    render_with_template(locals: {
                           search: search,
                           fields: fields,
                           operations: operations
                         })
  end

  def with_no_remove_or_button # rubocop:disable Metrics/MethodLength
    search = Sample::Search.new(
      groups: [
        Sample::Group.new(
          conditions: [
            Sample::Condition.new(field: 'puid', operator: '!=', value: 'test me'),
            Sample::Condition.new(field: 'name', operator: '=', value: 'test me again')
          ]
        ),
        Sample::Group.new(
          conditions: [
            Sample::Condition.new(field: 'puid', operator: '!=', value: 'test me'),
            Sample::Condition.new(field: 'name', operator: '=', value: 'test me again')
          ]
        )
      ]
    )
    fields = %w[name puid created_at updated_at attachments_updated_at metadata.country metadata.collection_date
                metadata.subject_type metadata.outbreak_code]
    operations = %w[= != <= >= < > contains]

    render_with_template(locals: {
                           search: search,
                           fields: fields,
                           operations: operations
                         })
  end
end
