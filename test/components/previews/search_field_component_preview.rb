# frozen_string_literal: true

class SearchFieldComponentPreview < ViewComponent::Preview
  def default
    render_with_template(locals: {
                           label: 'Search by email',
                           placeholder: 'Enter email address',
                           field_name: :user_email_cont,
                           value: nil
                         })
  end

  def with_value
    render_with_template(locals: {
                           label: 'Search by email',
                           placeholder: 'Enter email address',
                           field_name: :user_email_cont,
                           value: 'test@example.com'
                         })
  end

  def with_empty_value
    render_with_template(locals: {
                           label: 'Search by email',
                           placeholder: 'Enter email address',
                           field_name: :user_email_cont,
                           value: ''
                         })
  end

  def different_field
    render_with_template(locals: {
                           label: 'Search by name',
                           placeholder: 'Enter name',
                           field_name: :name_cont,
                           value: 'John Doe'
                         })
  end
end
