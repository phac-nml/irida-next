# frozen_string_literal: true

class AdvancedSearchComponentPreview < ViewComponent::Preview
  def with_group_condition_buttons
    fields = %w[name puid created_at updated_at attachments_updated_at metadata.country metadata.collection_date
                metadata.subject_type metadata.outbreak_code]
    operations = %w[= != <= >= < > contains]

    render_with_template(locals: {
                           fields: fields,
                           operations: operations
                         })
  end

  def with_or_and_buttons
    fields = %w[name puid created_at updated_at attachments_updated_at metadata.country metadata.collection_date
                metadata.subject_type metadata.outbreak_code]
    operations = %w[= != <= >= < > contains]

    render_with_template(locals: {
                           fields: fields,
                           operations: operations
                         })
  end

  def with_no_remove_or_button
    fields = %w[name puid created_at updated_at attachments_updated_at metadata.country metadata.collection_date
                metadata.subject_type metadata.outbreak_code]
    operations = %w[= != <= >= < > contains]

    render_with_template(locals: {
                           fields: fields,
                           operations: operations
                         })
  end
end
